begin;

create or replace function private.enforce_merchant_store_limit()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_user_id uuid := auth.uid();
  v_limit integer := 1;
  v_count integer := 0;
begin
  if auth.role() = 'service_role' then return new; end if;
  if v_user_id is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  if new.merchant_id is distinct from v_user_id then raise exception 'store_owner_invalid'; end if;
  select coalesce(sp.store_limit, 1)
    into v_limit
  from public.merchant_subscriptions ms
  join public.subscription_plans sp on sp.id = ms.plan_id and sp.is_active
  where ms.merchant_id = v_user_id
    and ms.status = 'active'
    and (ms.ends_at is null or ms.ends_at > timezone('utc', now()))
  order by ms.ends_at desc nulls last
  limit 1;
  select count(*)::integer into v_count from public.stores where merchant_id = v_user_id;
  if v_count >= v_limit then raise exception 'plan_store_limit_reached'; end if;
  return new;
end;
$$;

create or replace function private.enforce_merchant_product_limit()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_user_id uuid := auth.uid();
  v_merchant_id uuid;
  v_limit integer := 25;
  v_count integer := 0;
begin
  if auth.role() = 'service_role' then return new; end if;
  if v_user_id is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  select merchant_id into v_merchant_id from public.stores where id = new.store_id;
  if v_merchant_id is null or v_merchant_id is distinct from v_user_id then raise exception 'product_store_owner_invalid'; end if;
  select coalesce(sp.product_limit, 25)
    into v_limit
  from public.merchant_subscriptions ms
  join public.subscription_plans sp on sp.id = ms.plan_id and sp.is_active
  where ms.merchant_id = v_user_id
    and ms.status = 'active'
    and (ms.ends_at is null or ms.ends_at > timezone('utc', now()))
  order by ms.ends_at desc nulls last
  limit 1;
  select count(*)::integer into v_count from public.products where store_id = new.store_id;
  if v_count >= v_limit then raise exception 'plan_product_limit_reached'; end if;
  return new;
end;
$$;

drop trigger if exists enforce_merchant_store_limit on public.stores;
create trigger enforce_merchant_store_limit
before insert on public.stores
for each row execute function private.enforce_merchant_store_limit();

drop trigger if exists enforce_merchant_product_limit on public.products;
create trigger enforce_merchant_product_limit
before insert on public.products
for each row execute function private.enforce_merchant_product_limit();

commit;
