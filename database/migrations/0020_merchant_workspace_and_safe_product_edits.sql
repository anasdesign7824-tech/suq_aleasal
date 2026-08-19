-- Assalkom / عسلكم — merchant workspace and safe post-publish editing foundation.
-- This migration deliberately separates owner editing from public publishing.

alter table public.profiles
  add column if not exists cover_url text,
  add column if not exists location_label text,
  add column if not exists latitude numeric(9,6),
  add column if not exists longitude numeric(9,6);

alter table public.profiles
  drop constraint if exists profiles_latitude_check;
alter table public.profiles
  add constraint profiles_latitude_check
  check (latitude is null or latitude between -90 and 90);

alter table public.profiles
  drop constraint if exists profiles_longitude_check;
alter table public.profiles
  add constraint profiles_longitude_check
  check (longitude is null or longitude between -180 and 180);

create table if not exists public.product_revisions (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  editor_user_id uuid not null references public.users(id) on delete cascade,
  base_updated_at timestamptz,
  status text not null default 'draft'
    check (status in ('draft', 'pending_review', 'approved', 'rejected', 'applied')),
  payload jsonb not null default '{}'::jsonb,
  review_note text,
  reviewed_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  reviewed_at timestamptz
);

alter table public.product_revisions enable row level security;

create index if not exists product_revisions_product_idx
  on public.product_revisions(product_id, created_at desc);
create index if not exists product_revisions_store_status_idx
  on public.product_revisions(store_id, status, created_at desc);
create index if not exists product_revisions_editor_idx
  on public.product_revisions(editor_user_id, created_at desc);

create policy product_revisions_select on public.product_revisions
  for select using (editor_user_id = (select auth.uid()) or (select public.is_admin()));
create policy product_revisions_insert on public.product_revisions
  for insert with check (
    editor_user_id = (select auth.uid())
    and exists (
      select 1 from public.stores s
      where s.id = store_id and s.merchant_id = (select auth.uid())
    )
    or (select public.is_admin())
  );
create policy product_revisions_update on public.product_revisions
  for update using (editor_user_id = (select auth.uid()) or (select public.is_admin()))
  with check (editor_user_id = (select auth.uid()) or (select public.is_admin()));
create policy product_revisions_delete on public.product_revisions
  for delete using (editor_user_id = (select auth.uid()) or (select public.is_admin()));

create or replace function public.merchant_open_workspace(
  p_business_name text,
  p_description text default null,
  p_region_id uuid default null,
  p_phone text default null,
  p_logo_url text default null,
  p_cover_url text default null
)
returns jsonb
language plpgsql
security invoker
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_user_id uuid := auth.uid();
  v_name text := nullif(trim(coalesce(p_business_name, '')), '');
  v_store public.stores%rowtype;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;
  if v_name is null or char_length(v_name) < 2 then
    raise exception 'Business name is required';
  end if;

  insert into public.merchant_profiles (
    user_id, business_name, description, verification_status
  ) values (
    v_user_id, v_name, nullif(trim(coalesce(p_description, '')), ''), 'pending'
  )
  on conflict (user_id) do update set
    business_name = excluded.business_name,
    description = coalesce(excluded.description, public.merchant_profiles.description),
    updated_at = timezone('utc', now());

  insert into public.stores (
    merchant_id, region_id, name_ar, slug, description, phone,
    logo_url, cover_url, status, is_verified
  ) values (
    v_user_id,
    p_region_id,
    v_name,
    'merchant-' || substring(v_user_id::text from 1 for 8),
    nullif(trim(coalesce(p_description, '')), ''),
    nullif(trim(coalesce(p_phone, '')), ''),
    nullif(trim(coalesce(p_logo_url, '')), ''),
    nullif(trim(coalesce(p_cover_url, '')), ''),
    'pending',
    false
  )
  on conflict (merchant_id) do update set
    region_id = coalesce(excluded.region_id, public.stores.region_id),
    name_ar = excluded.name_ar,
    description = coalesce(excluded.description, public.stores.description),
    phone = coalesce(excluded.phone, public.stores.phone),
    logo_url = coalesce(excluded.logo_url, public.stores.logo_url),
    cover_url = coalesce(excluded.cover_url, public.stores.cover_url),
    updated_at = timezone('utc', now());

  select * into v_store from public.stores where merchant_id = v_user_id;
  return jsonb_build_object(
    'store', to_jsonb(v_store),
    'verification_status', 'pending',
    'public_status', v_store.status,
    'can_edit', true,
    'can_publish', v_store.status = 'active'
  );
end;
$$;

revoke all on function public.merchant_open_workspace(text, text, uuid, text, text, text) from public;
grant execute on function public.merchant_open_workspace(text, text, uuid, text, text, text) to authenticated;

create or replace function private.publish_pending_products_when_store_activated()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, public, private, auth
as $$
begin
  if new.status = 'active' and old.status is distinct from new.status then
    update public.products
    set status = 'active', updated_at = timezone('utc', now())
    where store_id = new.id and status = 'pending';
  end if;
  return new;
end;
$$;

drop trigger if exists publish_pending_products_after_store_activation on public.stores;
create trigger publish_pending_products_after_store_activation
after update of status on public.stores
for each row execute function private.publish_pending_products_when_store_activated();

-- Keep the existing owner/admin policies while explicitly documenting the
-- pending workspace behavior through the existing ownership checks.
