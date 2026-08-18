begin;

create or replace function private.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private, auth
as $$
  select exists (
    select 1
    from public.admin_users au
    join public.admin_roles ar on ar.id = au.role_id
    where au.user_id = auth.uid()
      and au.is_active = true
      and ar.code = 'super_admin'
  );
$$;

create or replace function private.has_admin_permission(permission_code text)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private, auth
as $$
  select exists (
    select 1
    from public.admin_users au
    join public.admin_roles ar on ar.id = au.role_id
    where au.user_id = auth.uid()
      and au.is_active = true
      and (
        ar.code = 'super_admin'
        or coalesce((ar.permissions ->> 'all')::boolean, false)
        or coalesce((ar.permissions ->> permission_code)::boolean, false)
      )
  );
$$;

revoke all on function private.is_super_admin() from public;
revoke all on function private.has_admin_permission(text) from public;
grant execute on function private.is_super_admin() to anon, authenticated;
grant execute on function private.has_admin_permission(text) to anon, authenticated;

create or replace function public.is_admin()
returns boolean
language sql
stable
security invoker
set search_path = pg_catalog, public, private, auth
as $$
  select private.is_admin();
$$;

create or replace function public.is_super_admin()
returns boolean
language sql
stable
security invoker
set search_path = pg_catalog, public, private, auth
as $$
  select private.is_super_admin();
$$;

create or replace function public.has_admin_permission(permission_code text)
returns boolean
language sql
stable
security invoker
set search_path = pg_catalog, public, private, auth
as $$
  select private.has_admin_permission(permission_code);
$$;

revoke all on function public.is_admin() from public;
revoke all on function public.is_super_admin() from public;
revoke all on function public.has_admin_permission(text) from public;
grant execute on function public.is_admin() to anon, authenticated;
grant execute on function public.is_super_admin() to anon, authenticated;
grant execute on function public.has_admin_permission(text) to anon, authenticated;

commit;
