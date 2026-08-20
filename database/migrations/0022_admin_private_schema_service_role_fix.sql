-- Admin Backend uses service_role, while merchant moderation triggers call private.* helpers.
-- Keep the helpers non-public but make the service_role execution path explicit.

grant usage on schema private to service_role;
grant select on private.admin_user_ids to service_role;
grant execute on function private.is_admin() to service_role;
grant execute on function private.prevent_profile_role_escalation() to service_role;
grant execute on function private.prevent_merchant_verification_changes() to service_role;
grant execute on function private.prevent_store_moderation_changes() to service_role;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private, auth
as $$
  select exists (
    select 1
    from public.admin_users
    where user_id = (select auth.uid())
      and is_active = true
  );
$$;

grant execute on function private.is_admin() to service_role;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private, auth
as $$
  select private.is_admin();
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated, service_role;

create or replace function private.prevent_profile_role_escalation()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
begin
  if new.role is distinct from old.role
     and not public.is_admin()
     and coalesce(auth.role(), '') <> 'service_role'
     and coalesce(current_setting('app.admin_action', true), '') <> 'true' then
    raise exception 'Only an admin may change profile roles';
  end if;
  return new;
end;
$$;

create or replace function private.prevent_merchant_verification_changes()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
begin
  if (new.verification_status is distinct from old.verification_status
      or new.verified_at is distinct from old.verified_at)
     and not public.is_admin()
     and coalesce(auth.role(), '') <> 'service_role'
     and coalesce(current_setting('app.admin_action', true), '') <> 'true' then
    raise exception 'Only an admin may change merchant verification';
  end if;
  return new;
end;
$$;

create or replace function private.prevent_store_moderation_changes()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
begin
  if (new.status is distinct from old.status
      or new.is_verified is distinct from old.is_verified)
     and not public.is_admin()
     and coalesce(auth.role(), '') <> 'service_role'
     and coalesce(current_setting('app.admin_action', true), '') <> 'true' then
    raise exception 'Only an admin may change store moderation fields';
  end if;
  return new;
end;
$$;

grant execute on function private.prevent_profile_role_escalation() to service_role;
grant execute on function private.prevent_merchant_verification_changes() to service_role;
grant execute on function private.prevent_store_moderation_changes() to service_role;
