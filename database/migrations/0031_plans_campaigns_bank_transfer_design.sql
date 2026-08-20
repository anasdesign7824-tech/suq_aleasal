-- Launch plans, configurable opening campaign, local bank-transfer proof,
-- subscription entitlements, and merchant design requests.
-- Card payments remain intentionally disabled in this migration.

begin;

create table if not exists public.subscription_plans (
  id uuid primary key default gen_random_uuid(),
  code text not null check (code in ('basic', 'standard', 'bronze_professional', 'gold')),
  name_ar text not null,
  billing_interval text not null check (billing_interval in ('month', 'year')),
  price_amount numeric(12,2) not null check (price_amount >= 0),
  currency text not null default 'SAR' check (char_length(currency) between 3 and 8),
  store_limit integer not null check (store_limit >= 1),
  product_limit integer not null check (product_limit >= 0),
  entitlements jsonb not null default '{}'::jsonb,
  verification_included integer not null default 0 check (verification_included >= 0),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (code, billing_interval)
);

create table if not exists public.plan_entitlements (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.subscription_plans(id) on delete cascade,
  entitlement_code text not null,
  value_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (plan_id, entitlement_code)
);

create table if not exists public.subscription_campaigns (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name_ar text not null,
  discount_percent numeric(5,2) not null check (discount_percent >= 0 and discount_percent <= 100),
  starts_at timestamptz,
  ends_at timestamptz,
  applies_to text[] not null default array['subscription']::text[],
  is_active boolean not null default false,
  created_by uuid references public.users(id) on delete set null,
  updated_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (ends_at is null or starts_at is null or ends_at > starts_at)
);

create unique index if not exists subscription_campaigns_one_active_idx
  on public.subscription_campaigns (code)
  where is_active = true;

create table if not exists public.local_transfer_settings (
  id uuid primary key default gen_random_uuid(),
  code text not null unique default 'primary',
  bank_name text,
  beneficiary_name text,
  account_number text,
  iban text,
  phone text,
  instructions_ar text,
  logo_url text,
  is_active boolean not null default false,
  updated_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.payment_requests (
  id uuid primary key default gen_random_uuid(),
  merchant_id uuid not null references public.users(id) on delete cascade,
  store_id uuid references public.stores(id) on delete cascade,
  plan_id uuid references public.subscription_plans(id) on delete set null,
  verification_request_id uuid references public.store_verification_requests(id) on delete set null,
  payment_type text not null check (payment_type in ('subscription', 'verification', 'design_service')),
  payment_method text not null default 'bank_transfer' check (payment_method in ('bank_transfer', 'card')),
  status text not null default 'not_started' check (status in ('not_started', 'proof_uploaded', 'under_review', 'confirmed', 'failed', 'refunded', 'waived')),
  base_amount numeric(12,2) not null check (base_amount >= 0),
  discount_percent numeric(5,2) not null default 0 check (discount_percent >= 0 and discount_percent <= 100),
  final_amount numeric(12,2) not null check (final_amount >= 0),
  currency text not null default 'SAR',
  campaign_id uuid references public.subscription_campaigns(id) on delete set null,
  payment_reference text,
  proof_path text,
  proof_file_name text,
  proof_mime_type text,
  proof_byte_size bigint check (proof_byte_size is null or proof_byte_size > 0),
  transfer_date date,
  submitted_amount numeric(12,2) check (submitted_amount is null or submitted_amount >= 0),
  sender_name text,
  sender_phone text,
  merchant_note text,
  reviewer_note text,
  reviewed_by uuid references public.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (payment_method = 'bank_transfer'),
  check (payment_type = 'subscription' or verification_request_id is not null or payment_type = 'design_service')
);

create index if not exists payment_requests_merchant_idx
  on public.payment_requests(merchant_id, created_at desc);
create index if not exists payment_requests_admin_queue_idx
  on public.payment_requests(status, payment_type, created_at desc);
create unique index if not exists payment_requests_one_open_subscription_idx
  on public.payment_requests(merchant_id)
  where payment_type = 'subscription' and status in ('not_started', 'proof_uploaded', 'under_review');

create table if not exists public.merchant_subscriptions (
  id uuid primary key default gen_random_uuid(),
  merchant_id uuid not null references public.users(id) on delete cascade,
  plan_id uuid not null references public.subscription_plans(id) on delete restrict,
  payment_request_id uuid unique references public.payment_requests(id) on delete set null,
  status text not null default 'pending' check (status in ('pending', 'active', 'expired', 'cancelled', 'suspended')),
  starts_at timestamptz,
  ends_at timestamptz,
  activated_by uuid references public.users(id) on delete set null,
  cancelled_at timestamptz,
  cancellation_note text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (ends_at is null or starts_at is null or ends_at > starts_at)
);

create index if not exists merchant_subscriptions_merchant_idx
  on public.merchant_subscriptions(merchant_id, status, ends_at desc);
create unique index if not exists merchant_subscriptions_one_active_idx
  on public.merchant_subscriptions(merchant_id)
  where status = 'active';

create table if not exists public.payment_events (
  id uuid primary key default gen_random_uuid(),
  payment_request_id uuid not null references public.payment_requests(id) on delete cascade,
  actor_user_id uuid references public.users(id) on delete set null,
  from_status text,
  to_status text not null,
  note text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists payment_events_request_idx
  on public.payment_events(payment_request_id, created_at desc);

create table if not exists public.design_requests (
  id uuid primary key default gen_random_uuid(),
  merchant_id uuid not null references public.users(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  subscription_id uuid references public.merchant_subscriptions(id) on delete set null,
  request_type text not null default 'brand_and_product_design',
  status text not null default 'draft' check (status in ('draft', 'submitted', 'needs_more_info', 'in_progress', 'ready_for_review', 'completed', 'cancelled')),
  title text not null,
  description text not null,
  brand_name text,
  brand_colors jsonb not null default '[]'::jsonb,
  product_scope jsonb not null default '{}'::jsonb,
  reference_paths jsonb not null default '[]'::jsonb,
  assigned_admin_id uuid references public.users(id) on delete set null,
  admin_note text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  completed_at timestamptz
);

create index if not exists design_requests_merchant_idx
  on public.design_requests(merchant_id, created_at desc);
create index if not exists design_requests_admin_queue_idx
  on public.design_requests(status, created_at desc);

insert into public.subscription_plans (code, name_ar, billing_interval, price_amount, currency, store_limit, product_limit, entitlements, verification_included, sort_order, is_active)
values
  ('basic', 'أساسية', 'month', 0, 'SAR', 1, 25, '{"analytics":"basic","priority":"standard","design_requests_per_cycle":0}'::jsonb, 0, 1, true),
  ('basic', 'أساسية', 'year', 0, 'SAR', 1, 25, '{"analytics":"basic","priority":"standard","design_requests_per_cycle":0}'::jsonb, 0, 2, true),
  ('standard', 'عادية', 'month', 49, 'SAR', 2, 100, '{"analytics":"basic","priority":"standard","design_requests_per_cycle":0}'::jsonb, 0, 3, true),
  ('standard', 'عادية', 'year', 490, 'SAR', 2, 100, '{"analytics":"basic","priority":"standard","design_requests_per_cycle":0}'::jsonb, 0, 4, true),
  ('bronze_professional', 'Bronze Professional البرونزية الاحترافية', 'month', 99, 'SAR', 5, 300, '{"analytics":"advanced","priority":"enhanced","design_requests_per_cycle":1}'::jsonb, 1, 5, true),
  ('bronze_professional', 'Bronze Professional البرونزية الاحترافية', 'year', 990, 'SAR', 5, 300, '{"analytics":"advanced","priority":"enhanced","design_requests_per_cycle":1}'::jsonb, 1, 6, true),
  ('gold', 'Gold الذهبية', 'month', 199, 'SAR', 10, 1000, '{"analytics":"advanced","priority":"priority","design_requests_per_cycle":3}'::jsonb, 3, 7, true),
  ('gold', 'Gold الذهبية', 'year', 1990, 'SAR', 10, 1000, '{"analytics":"advanced","priority":"priority","design_requests_per_cycle":3}'::jsonb, 3, 8, true)
on conflict (code, billing_interval) do update set
  name_ar = excluded.name_ar,
  price_amount = excluded.price_amount,
  currency = excluded.currency,
  store_limit = excluded.store_limit,
  product_limit = excluded.product_limit,
  entitlements = excluded.entitlements,
  verification_included = excluded.verification_included,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active,
  updated_at = timezone('utc', now());

insert into public.subscription_campaigns (code, name_ar, discount_percent, starts_at, ends_at, applies_to, is_active)
values ('app_launch_2026', 'افتتاح تطبيق عسلكم', 15, timezone('utc', now()), null, array['subscription', 'verification']::text[], true)
on conflict (code) do update set
  name_ar = excluded.name_ar,
  discount_percent = excluded.discount_percent,
  applies_to = excluded.applies_to,
  updated_at = timezone('utc', now());

insert into public.local_transfer_settings (code, is_active)
values ('primary', false)
on conflict (code) do nothing;

create or replace function public.get_current_subscription_campaign()
returns public.subscription_campaigns
language sql
stable
security invoker
set search_path = pg_catalog, public
as $$
  select c.*
  from public.subscription_campaigns c
  where c.is_active
    and (c.starts_at is null or c.starts_at <= timezone('utc', now()))
    and (c.ends_at is null or c.ends_at > timezone('utc', now()))
  order by c.created_at desc
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
  if exists (select 1 from public.merchant_subscriptions ms where ms.merchant_id = v_merchant_id and ms.status = 'active' and ms.ends_at > timezone('utc', now())) then
    raise exception 'active_subscription_exists';
  end if;
  select * into v_campaign from public.subscription_campaigns c
  where c.is_active
    and (c.starts_at is null or c.starts_at <= timezone('utc', now()))
    and (c.ends_at is null or c.ends_at > timezone('utc', now()))
    and 'subscription' = any(c.applies_to)
    and (p_campaign_id is null or c.id = p_campaign_id)
  order by c.created_at desc limit 1;
  if found then v_discount := v_campaign.discount_percent; end if;
  v_final := round(v_plan.price_amount * (1 - v_discount / 100), 2);
  insert into public.payment_requests (merchant_id, plan_id, payment_type, payment_method, status, base_amount, discount_percent, final_amount, currency, campaign_id)
  values (v_merchant_id, v_plan.id, 'subscription', 'bank_transfer', 'not_started', v_plan.price_amount, v_discount, v_final, v_plan.currency, v_campaign.id)
  returning * into v_request;
  return to_jsonb(v_request);
end;
$$;

revoke all on function public.merchant_create_subscription_payment_request(uuid, uuid) from public;
grant execute on function public.merchant_create_subscription_payment_request(uuid, uuid) to authenticated;

create or replace function public.merchant_submit_payment_proof(
  p_payment_request_id uuid,
  p_payment_reference text,
  p_proof_path text,
  p_proof_file_name text,
  p_proof_mime_type text,
  p_proof_byte_size bigint,
  p_transfer_date date,
  p_submitted_amount numeric,
  p_sender_name text,
  p_sender_phone text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_request public.payment_requests%rowtype;
  v_path_prefix text := auth.uid()::text || '/payment-proofs/';
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  if p_proof_path is null or left(p_proof_path, char_length(v_path_prefix)) <> v_path_prefix then raise exception 'payment_proof_path_invalid'; end if;
  if p_proof_mime_type not in ('application/pdf', 'image/jpeg', 'image/png') then raise exception 'payment_proof_type_invalid'; end if;
  if p_proof_byte_size is null or p_proof_byte_size <= 0 or p_proof_byte_size > 10485760 then raise exception 'payment_proof_size_invalid'; end if;
  if nullif(trim(coalesce(p_payment_reference, '')), '') is null then raise exception 'payment_reference_required'; end if;
  select * into v_request from public.payment_requests where id = p_payment_request_id and merchant_id = auth.uid() for update;
  if not found then raise exception 'payment_request_not_found'; end if;
  if v_request.status not in ('not_started', 'failed') then raise exception 'payment_proof_not_allowed'; end if;
  update public.payment_requests set status = 'proof_uploaded', payment_reference = nullif(trim(p_payment_reference), ''), proof_path = p_proof_path, proof_file_name = left(nullif(trim(p_proof_file_name), ''), 180), proof_mime_type = p_proof_mime_type, proof_byte_size = p_proof_byte_size, transfer_date = p_transfer_date, submitted_amount = p_submitted_amount, sender_name = left(nullif(trim(p_sender_name), ''), 180), sender_phone = left(nullif(trim(p_sender_phone), ''), 40), updated_at = timezone('utc', now()) where id = p_payment_request_id;
  insert into public.payment_events (payment_request_id, actor_user_id, from_status, to_status, note, metadata) values (p_payment_request_id, auth.uid(), v_request.status, 'proof_uploaded', 'رفع التاجر مستند الحوالة.', jsonb_build_object('payment_method', 'bank_transfer'));
  return (select to_jsonb(p) from public.payment_requests p where p.id = p_payment_request_id);
end;
$$;

revoke all on function public.merchant_submit_payment_proof(uuid, text, text, text, text, bigint, date, numeric, text, text) from public;
grant execute on function public.merchant_submit_payment_proof(uuid, text, text, text, text, bigint, date, numeric, text, text) to authenticated;

create or replace function public.admin_reconcile_payment_request(
  p_payment_request_id uuid,
  p_status text,
  p_note text default null,
  p_reviewer_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_request public.payment_requests%rowtype;
  v_reviewer_id uuid := coalesce(p_reviewer_id, auth.uid());
  v_subscription public.merchant_subscriptions%rowtype;
  v_plan public.subscription_plans%rowtype;
  v_starts timestamptz := timezone('utc', now());
  v_ends timestamptz;
begin
  if auth.role() <> 'service_role' and not private.has_admin_permission('payments.manage') then raise exception 'payment_admin_forbidden'; end if;
  if p_status not in ('confirmed', 'failed', 'refunded', 'waived', 'under_review') then raise exception 'payment_status_invalid'; end if;
  select * into v_request from public.payment_requests where id = p_payment_request_id for update;
  if not found then raise exception 'payment_request_not_found'; end if;
  if p_status = 'confirmed' and v_request.payment_method <> 'bank_transfer' then raise exception 'card_payment_disabled'; end if;
  update public.payment_requests set status = p_status, reviewer_note = nullif(trim(coalesce(p_note, '')), ''), reviewed_by = v_reviewer_id, reviewed_at = timezone('utc', now()), updated_at = timezone('utc', now()) where id = p_payment_request_id;
  insert into public.payment_events (payment_request_id, actor_user_id, from_status, to_status, note, metadata) values (p_payment_request_id, v_reviewer_id, v_request.status, p_status, nullif(trim(coalesce(p_note, '')), ''), jsonb_build_object('admin_reconciled', true));
  if p_status in ('confirmed', 'waived') and v_request.payment_type = 'subscription' then
    select * into v_plan from public.subscription_plans where id = v_request.plan_id;
    if not found then raise exception 'subscription_plan_not_found'; end if;
    v_ends := case when v_plan.billing_interval = 'year' then v_starts + interval '1 year' else v_starts + interval '1 month' end;
    update public.merchant_subscriptions set status = 'expired', updated_at = timezone('utc', now()) where merchant_id = v_request.merchant_id and status = 'active';
    insert into public.merchant_subscriptions (merchant_id, plan_id, payment_request_id, status, starts_at, ends_at, activated_by) values (v_request.merchant_id, v_plan.id, v_request.id, 'active', v_starts, v_ends, v_reviewer_id) returning * into v_subscription;
    insert into public.notifications (user_id, notification_type, title_ar, body_ar, payload) values (v_request.merchant_id, 'subscription_activated', 'تم تفعيل خطتك', 'تم تأكيد الحوالة وتفعيل مزايا الخطة في حسابك.', jsonb_build_object('subscription_id', v_subscription.id, 'plan_id', v_plan.id, 'plan_code', v_plan.code, 'ends_at', v_ends));
  end if;
  if p_status in ('failed', 'refunded') then
    insert into public.notifications (user_id, notification_type, title_ar, body_ar, payload) values (v_request.merchant_id, 'payment_update', 'تحديث طلب الدفع', coalesce(nullif(trim(coalesce(p_note, '')), ''), 'لم يتم تأكيد الحوالة. راجع الملاحظة وأعد الإرسال عند الحاجة.'), jsonb_build_object('payment_request_id', p_payment_request_id, 'status', p_status));
  end if;
  return (select to_jsonb(p) from public.payment_requests p where p.id = p_payment_request_id);
end;
$$;

revoke all on function public.admin_reconcile_payment_request(uuid, text, text, uuid) from public, anon, authenticated;
grant execute on function public.admin_reconcile_payment_request(uuid, text, text, uuid) to service_role;

create or replace function public.merchant_create_design_request(
  p_store_id uuid,
  p_title text,
  p_description text,
  p_brand_name text default null,
  p_brand_colors jsonb default '[]'::jsonb,
  p_product_scope jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_merchant_id uuid := auth.uid();
  v_subscription public.merchant_subscriptions%rowtype;
  v_plan public.subscription_plans%rowtype;
  v_limit integer;
  v_used integer;
  v_request public.design_requests%rowtype;
begin
  if v_merchant_id is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  select ms.* into v_subscription
  from public.merchant_subscriptions ms
  where ms.merchant_id = v_merchant_id and ms.status = 'active' and ms.ends_at > timezone('utc', now()) and ms.plan_id is not null order by ms.ends_at desc limit 1;
  if not found then raise exception 'active_plan_required'; end if;
  select sp.* into v_plan from public.subscription_plans sp where sp.id = v_subscription.plan_id and sp.is_active;
  if not found then raise exception 'subscription_plan_not_found'; end if;
  if not exists (select 1 from public.stores s where s.id = p_store_id and s.merchant_id = v_merchant_id) then raise exception 'store_not_owned'; end if;
  v_limit := coalesce((v_plan.entitlements ->> 'design_requests_per_cycle')::integer, 0);
  select count(*)::integer into v_used from public.design_requests dr where dr.subscription_id = v_subscription.id and dr.created_at >= v_subscription.starts_at and dr.status <> 'cancelled';
  if v_used >= v_limit then raise exception 'design_request_limit_reached'; end if;
  insert into public.design_requests (merchant_id, store_id, subscription_id, status, title, description, brand_name, brand_colors, product_scope) values (v_merchant_id, p_store_id, v_subscription.id, 'submitted', left(trim(p_title), 180), left(trim(p_description), 5000), nullif(trim(p_brand_name), ''), coalesce(p_brand_colors, '[]'::jsonb), coalesce(p_product_scope, '{}'::jsonb)) returning * into v_request;
  return to_jsonb(v_request);
end;
$$;

revoke all on function public.merchant_create_design_request(uuid, text, text, text, jsonb, jsonb) from public;
grant execute on function public.merchant_create_design_request(uuid, text, text, text, jsonb, jsonb) to authenticated;

create or replace function public.admin_set_subscription_status(
  p_subscription_id uuid,
  p_status text,
  p_note text default null,
  p_reviewer_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_reviewer_id uuid := coalesce(p_reviewer_id, auth.uid());
  v_subscription public.merchant_subscriptions%rowtype;
begin
  if auth.role() <> 'service_role' and not private.has_admin_permission('plans.manage') then raise exception 'plan_admin_forbidden'; end if;
  if p_status not in ('active', 'expired', 'cancelled', 'suspended') then raise exception 'subscription_status_invalid'; end if;
  select * into v_subscription from public.merchant_subscriptions where id = p_subscription_id for update;
  if not found then raise exception 'subscription_not_found'; end if;
  update public.merchant_subscriptions set status = p_status, activated_by = case when p_status = 'active' then v_reviewer_id else activated_by end, cancelled_at = case when p_status in ('cancelled', 'suspended') then timezone('utc', now()) else cancelled_at end, cancellation_note = case when p_status in ('cancelled', 'suspended') then nullif(trim(coalesce(p_note, '')), '') else cancellation_note end, updated_at = timezone('utc', now()) where id = p_subscription_id;
  insert into public.notifications (user_id, notification_type, title_ar, body_ar, payload) values (v_subscription.merchant_id, 'subscription_update', case when p_status = 'active' then 'تم تفعيل خطتك' else 'تحديث حالة خطتك' end, coalesce(nullif(trim(coalesce(p_note, '')), ''), case when p_status = 'active' then 'أصبحت مزايا الخطة متاحة في التطبيق.' else 'تغيرت حالة خطتك. راجع لوحة التاجر.' end), jsonb_build_object('subscription_id', p_subscription_id, 'status', p_status));
  return (select to_jsonb(ms) from public.merchant_subscriptions ms where ms.id = p_subscription_id);
end;
$$;

revoke all on function public.admin_set_subscription_status(uuid, text, text, uuid) from public, anon, authenticated;
grant execute on function public.admin_set_subscription_status(uuid, text, text, uuid) to service_role;

alter table public.subscription_plans enable row level security;
alter table public.plan_entitlements enable row level security;
alter table public.subscription_campaigns enable row level security;
alter table public.local_transfer_settings enable row level security;
alter table public.payment_requests enable row level security;
alter table public.merchant_subscriptions enable row level security;
alter table public.payment_events enable row level security;
alter table public.design_requests enable row level security;

drop policy if exists subscription_plans_public_read on public.subscription_plans;
create policy subscription_plans_public_read on public.subscription_plans for select using (is_active);
drop policy if exists plan_entitlements_public_read on public.plan_entitlements;
create policy plan_entitlements_public_read on public.plan_entitlements for select using (exists (select 1 from public.subscription_plans sp where sp.id = plan_id and sp.is_active));
drop policy if exists campaigns_public_read on public.subscription_campaigns;
create policy campaigns_public_read on public.subscription_campaigns for select using (is_active and (starts_at is null or starts_at <= timezone('utc', now())) and (ends_at is null or ends_at > timezone('utc', now())));
drop policy if exists transfer_settings_authenticated_read on public.local_transfer_settings;
create policy transfer_settings_authenticated_read on public.local_transfer_settings for select to authenticated using (is_active);

drop policy if exists payment_requests_owner_read on public.payment_requests;
create policy payment_requests_owner_read on public.payment_requests for select using (merchant_id = (select auth.uid()) or private.has_admin_permission('payments.read'));
drop policy if exists payment_requests_owner_insert on public.payment_requests;
create policy payment_requests_owner_insert on public.payment_requests for insert with check (false);
drop policy if exists payment_requests_admin_write on public.payment_requests;
create policy payment_requests_admin_write on public.payment_requests for update using (private.has_admin_permission('payments.manage')) with check (private.has_admin_permission('payments.manage'));

drop policy if exists subscriptions_owner_read on public.merchant_subscriptions;
create policy subscriptions_owner_read on public.merchant_subscriptions for select using (merchant_id = (select auth.uid()) or private.has_admin_permission('plans.read'));
drop policy if exists subscription_admin_write on public.merchant_subscriptions;
create policy subscription_admin_write on public.merchant_subscriptions for update using (private.has_admin_permission('plans.manage')) with check (private.has_admin_permission('plans.manage'));

drop policy if exists payment_events_owner_read on public.payment_events;
create policy payment_events_owner_read on public.payment_events for select using (exists (select 1 from public.payment_requests pr where pr.id = payment_request_id and (pr.merchant_id = (select auth.uid()) or private.has_admin_permission('payments.read'))));

drop policy if exists design_requests_owner_read on public.design_requests;
create policy design_requests_owner_read on public.design_requests for select using (merchant_id = (select auth.uid()) or private.has_admin_permission('design.read'));
drop policy if exists design_requests_owner_insert on public.design_requests;
create policy design_requests_owner_insert on public.design_requests for insert with check (false);
drop policy if exists design_requests_admin_write on public.design_requests;
create policy design_requests_admin_write on public.design_requests for update using (private.has_admin_permission('design.manage')) with check (private.has_admin_permission('design.manage'));

drop trigger if exists subscription_plans_updated_at on public.subscription_plans;
create trigger subscription_plans_updated_at before update on public.subscription_plans for each row execute procedure private.set_updated_at();
drop trigger if exists plan_entitlements_updated_at on public.plan_entitlements;
create trigger plan_entitlements_updated_at before update on public.plan_entitlements for each row execute procedure private.set_updated_at();
drop trigger if exists subscription_campaigns_updated_at on public.subscription_campaigns;
create trigger subscription_campaigns_updated_at before update on public.subscription_campaigns for each row execute procedure private.set_updated_at();
drop trigger if exists local_transfer_settings_updated_at on public.local_transfer_settings;
create trigger local_transfer_settings_updated_at before update on public.local_transfer_settings for each row execute procedure private.set_updated_at();
drop trigger if exists payment_requests_updated_at on public.payment_requests;
create trigger payment_requests_updated_at before update on public.payment_requests for each row execute procedure private.set_updated_at();
drop trigger if exists merchant_subscriptions_updated_at on public.merchant_subscriptions;
create trigger merchant_subscriptions_updated_at before update on public.merchant_subscriptions for each row execute procedure private.set_updated_at();
drop trigger if exists design_requests_updated_at on public.design_requests;
create trigger design_requests_updated_at before update on public.design_requests for each row execute procedure private.set_updated_at();

update public.admin_roles
set permissions = permissions || '{"plans.read":true,"plans.manage":true,"payments.read":true,"payments.manage":true,"campaigns.manage":true,"design.read":true,"design.manage":true}'::jsonb
where code = 'admin';

commit;
