-- TASK 004: make the intentionally frozen card-payment RPC reject
-- unauthenticated callers explicitly before inspecting provider settings.
-- This does not enable card payments or change provider configuration.

begin;

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
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  select *
    into v_settings
    from public.payment_provider_settings
   where code = 'primary'
     and is_enabled
     and secret_configured;

  if not found then
    raise exception 'card_payment_disabled';
  end if;

  raise exception 'card_payment_provider_not_activated';
end;
$$;

commit;
