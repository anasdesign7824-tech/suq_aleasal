begin;

-- Pricing basis approved by the owner:
-- standard monthly 35 SAR; Bronze/Gold preserve the previous proportional tiers.
-- Annual plans are priced at ten monthly months (two months free).
update public.subscription_plans
set price_amount = case
  when code = 'standard' and billing_interval = 'month' then 35.00
  when code = 'standard' and billing_interval = 'year' then 350.00
  when code = 'bronze_professional' and billing_interval = 'month' then 70.71
  when code = 'bronze_professional' and billing_interval = 'year' then 707.10
  when code = 'gold' and billing_interval = 'month' then 142.14
  when code = 'gold' and billing_interval = 'year' then 1421.40
  else price_amount
end,
updated_at = timezone('utc', now())
where code in ('standard', 'bronze_professional', 'gold');

alter table public.subscription_campaigns
  add column if not exists discount_by_plan_code jsonb not null default '{}'::jsonb;

update public.subscription_campaigns
set discount_percent = 10,
    discount_by_plan_code = '{"basic":0,"standard":10,"bronze_professional":15,"gold":15,"verification":10}'::jsonb,
    applies_to = array['subscription', 'verification']::text[],
    updated_at = timezone('utc', now())
where code = 'app_launch_2026';

-- Card fields are metadata only. No PAN, CVV, PIN, or raw card token is stored here.
alter table public.payment_requests
  drop constraint if exists payment_requests_payment_method_check;
alter table public.payment_requests
  add constraint payment_requests_payment_method_check check (payment_method in ('bank_transfer', 'card'));
alter table public.payment_requests add column if not exists payment_provider_code text;
alter table public.payment_requests add column if not exists provider_transaction_id text;
alter table public.payment_requests add column if not exists provider_event_id text;
alter table public.payment_requests add column if not exists provider_status text;
alter table public.payment_requests add column if not exists provider_metadata jsonb not null default '{}'::jsonb;
alter table public.payment_requests add column if not exists last_webhook_at timestamptz;
create unique index if not exists payment_requests_provider_event_idx
  on public.payment_requests(payment_provider_code, provider_event_id)
  where payment_provider_code is not null and provider_event_id is not null;

create table if not exists public.payment_provider_settings (
  id uuid primary key default gen_random_uuid(),
  code text not null unique default 'primary',
  provider_code text,
  display_name_ar text,
  environment text not null default 'test' check (environment in ('test', 'live')),
  is_enabled boolean not null default false,
  webhook_url text,
  allowed_ip_ranges text[] not null default '{}'::text[],
  secret_configured boolean not null default false,
  supported_currencies text[] not null default array['SAR']::text[],
  updated_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

insert into public.payment_provider_settings (code, display_name_ar, environment, is_enabled, secret_configured)
values ('primary', 'بوابة البطاقة الائتمانية', 'test', false, false)
on conflict (code) do nothing;

create index if not exists payment_requests_provider_status_idx
  on public.payment_requests(payment_method, provider_status, created_at desc);

create or replace function private.subscription_discount_for_plan(
  p_campaign_id uuid,
  p_plan_code text
)
returns numeric
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select least(100::numeric, greatest(0::numeric,
    coalesce((c.discount_by_plan_code ->> p_plan_code)::numeric, c.discount_percent)
  ))
  from public.subscription_campaigns c
  where c.id = p_campaign_id
  limit 1;
$$;

create or replace function public.merchant_create_subscription_payment_request(
  p_plan_id uuid,
  p_campaign_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_merchant_id uuid := auth.uid();
  v_plan public.subscription_plans%rowtype;
  v_campaign public.subscription_campaigns%rowtype;
  v_request public.payment_requests%rowtype;
  v_discount numeric(5,2) := 0;
  v_final numeric(12,2);
begin
  if v_merchant_id is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  select * into v_plan from public.subscription_plans where id = p_plan_id and is_active;
  if not found then raise exception 'plan_not_found'; end if;
  if v_plan.price_amount = 0 then raise exception 'free_plan_does_not_require_payment'; end if;
  if exists (select 1 from public.merchant_subscriptions ms where ms.merchant_id = v_merchant_id and ms.status = 'active' and (ms.ends_at is null or ms.ends_at > timezone('utc', now()))) then
    raise exception 'active_subscription_exists';
  end if;
  select * into v_campaign from public.subscription_campaigns c
  where c.is_active
    and (c.starts_at is null or c.starts_at <= timezone('utc', now()))
    and (c.ends_at is null or c.ends_at > timezone('utc', now()))
    and 'subscription' = any(c.applies_to)
    and (p_campaign_id is null or c.id = p_campaign_id)
  order by c.created_at desc limit 1;
  if found then v_discount := private.subscription_discount_for_plan(v_campaign.id, v_plan.code); end if;
  v_final := round(v_plan.price_amount * (1 - v_discount / 100), 2);
  insert into public.payment_requests (merchant_id, plan_id, payment_type, payment_method, status, base_amount, discount_percent, final_amount, currency, campaign_id)
  values (v_merchant_id, v_plan.id, 'subscription', 'bank_transfer', 'not_started', v_plan.price_amount, v_discount, v_final, v_plan.currency, v_campaign.id)
  returning * into v_request;
  return to_jsonb(v_request);
end;
$$;

revoke all on function public.merchant_create_subscription_payment_request(uuid, uuid) from public, anon;
grant execute on function public.merchant_create_subscription_payment_request(uuid, uuid) to authenticated;

-- Frozen card entry point. It remains disabled until a vetted provider is configured
-- on the local Admin server and an explicit activation migration is approved.
create or replace function public.merchant_start_card_payment_request(
  p_plan_id uuid,
  p_campaign_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_settings public.payment_provider_settings%rowtype;
begin
  select * into v_settings from public.payment_provider_settings where code = 'primary' and is_enabled and secret_configured;
  if not found then raise exception 'card_payment_disabled'; end if;
  raise exception 'card_payment_provider_not_activated';
end;
$$;

revoke all on function public.merchant_start_card_payment_request(uuid, uuid) from public, anon;
grant execute on function public.merchant_start_card_payment_request(uuid, uuid) to authenticated;

-- Provider webhook confirmation is reserved for a future provider-specific migration.
-- It must run only through service_role after signature, timestamp, idempotency,
-- and allowed-IP checks have passed in the local Admin backend.
create or replace function public.system_confirm_card_payment(
  p_payment_request_id uuid,
  p_provider_code text,
  p_provider_transaction_id text,
  p_provider_event_id text,
  p_provider_status text,
  p_provider_metadata jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
begin
  if auth.role() <> 'service_role' then raise exception 'provider_webhook_forbidden'; end if;
  raise exception 'card_payment_provider_not_activated';
end;
$$;

revoke all on function public.system_confirm_card_payment(uuid, text, text, text, text, jsonb) from public, anon, authenticated;
grant execute on function public.system_confirm_card_payment(uuid, text, text, text, text, jsonb) to service_role;

drop trigger if exists payment_provider_settings_updated_at on public.payment_provider_settings;
create trigger payment_provider_settings_updated_at before update on public.payment_provider_settings for each row execute function private.set_updated_at();

alter table public.payment_provider_settings enable row level security;
drop policy if exists payment_provider_settings_admin_read on public.payment_provider_settings;
create policy payment_provider_settings_admin_read on public.payment_provider_settings for select using (private.has_admin_permission('payments.read'));
drop policy if exists payment_provider_settings_admin_write on public.payment_provider_settings;
create policy payment_provider_settings_admin_write on public.payment_provider_settings for update using (private.has_admin_permission('payments.manage')) with check (private.has_admin_permission('payments.manage'));

commit;
