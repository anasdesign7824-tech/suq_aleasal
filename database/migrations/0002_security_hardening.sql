-- Souq Al Assal / عسلكم — security hardening after advisor review

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create or replace view private.admin_user_ids as
select user_id from public.admin_users;

revoke all on private.admin_user_ids from public;
grant select on private.admin_user_ids to authenticated;

create or replace function public.is_admin()
returns boolean
language sql
stable
security invoker
set search_path = private, public
as $$
  select exists (select 1 from admin_user_ids where user_id = auth.uid());
$$;

grant execute on function public.is_admin() to anon, authenticated;

create or replace function private.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id) values (new.id) on conflict (id) do nothing;
  insert into public.profiles (user_id, display_name) values (new.id, coalesce(new.raw_user_meta_data->>'name', 'مستخدم عسلكم')) on conflict (user_id) do nothing;
  return new;
end;
$$;

create or replace function private.prevent_profile_role_escalation()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if new.role is distinct from old.role and not public.is_admin() then
    raise exception 'Only an admin may change profile roles';
  end if;
  return new;
end;
$$;

create or replace function private.prevent_merchant_verification_changes()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if (new.verification_status is distinct from old.verification_status or new.verified_at is distinct from old.verified_at) and not public.is_admin() then
    raise exception 'Only an admin may change merchant verification';
  end if;
  return new;
end;
$$;

create or replace function private.prevent_store_moderation_changes()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if (new.status is distinct from old.status or new.is_verified is distinct from old.is_verified) and not public.is_admin() then
    raise exception 'Only an admin may change store moderation fields';
  end if;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure private.handle_new_user();

drop trigger if exists profiles_role_guard on public.profiles;
create trigger profiles_role_guard before update on public.profiles for each row execute procedure private.prevent_profile_role_escalation();

drop trigger if exists merchant_verification_guard on public.merchant_profiles;
create trigger merchant_verification_guard before update on public.merchant_profiles for each row execute procedure private.prevent_merchant_verification_changes();

drop trigger if exists store_moderation_guard on public.stores;
create trigger store_moderation_guard before update on public.stores for each row execute procedure private.prevent_store_moderation_changes();

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at before update on public.profiles for each row execute procedure private.set_updated_at();
drop trigger if exists merchant_profiles_updated_at on public.merchant_profiles;
create trigger merchant_profiles_updated_at before update on public.merchant_profiles for each row execute procedure private.set_updated_at();
drop trigger if exists categories_updated_at on public.categories;
create trigger categories_updated_at before update on public.categories for each row execute procedure private.set_updated_at();
drop trigger if exists honey_taxonomy_updated_at on public.honey_taxonomy;
create trigger honey_taxonomy_updated_at before update on public.honey_taxonomy for each row execute procedure private.set_updated_at();
drop trigger if exists stores_updated_at on public.stores;
create trigger stores_updated_at before update on public.stores for each row execute procedure private.set_updated_at();
drop trigger if exists products_updated_at on public.products;
create trigger products_updated_at before update on public.products for each row execute procedure private.set_updated_at();
drop trigger if exists reviews_updated_at on public.reviews;
create trigger reviews_updated_at before update on public.reviews for each row execute procedure private.set_updated_at();
drop trigger if exists comments_updated_at on public.comments;
create trigger comments_updated_at before update on public.comments for each row execute procedure private.set_updated_at();
drop trigger if exists requests_updated_at on public.requests;
create trigger requests_updated_at before update on public.requests for each row execute procedure private.set_updated_at();
drop trigger if exists banners_updated_at on public.banners;
create trigger banners_updated_at before update on public.banners for each row execute procedure private.set_updated_at();
drop trigger if exists pickup_locations_updated_at on public.merchant_pickup_locations;
create trigger pickup_locations_updated_at before update on public.merchant_pickup_locations for each row execute procedure private.set_updated_at();

drop function if exists public.handle_new_user();
drop function if exists public.prevent_profile_role_escalation();
drop function if exists public.prevent_merchant_verification_changes();
drop function if exists public.prevent_store_moderation_changes();
drop function if exists public.set_updated_at();
