-- Security hardening for the local Admin Console.
-- No user data is changed. Admin actions remain server-side through service_role.

begin;

-- RLS policy expressions need to call the non-exposed helper. Grant only the
-- execution needed for policy evaluation; the private schema is not exposed
-- through the public REST API.
grant usage on schema private to anon, authenticated, service_role;
grant execute on function private.is_admin() to anon, authenticated, service_role;

-- Existing policies were created by earlier migrations with public.is_admin()
-- (or an unqualified is_admin()). Rewrite only those policy expressions to
-- use private.is_admin(), without recreating tables or changing their data.
do $$
declare
  policy_row record;
  rewritten_using text;
  rewritten_check text;
  using_sql text;
  check_sql text;
begin
  for policy_row in
    select schemaname, tablename, policyname, qual, with_check
    from pg_policies
    where schemaname = 'public'
      and (
        coalesce(qual, '') like '%is_admin()%' or
        coalesce(with_check, '') like '%is_admin()%'
      )
  loop
    rewritten_using := policy_row.qual;
    rewritten_check := policy_row.with_check;

    if rewritten_using is not null then
      if position('public.is_admin()' in rewritten_using) > 0 then
        rewritten_using := replace(rewritten_using, 'public.is_admin()', 'private.is_admin()');
      elsif position('private.is_admin()' in rewritten_using) = 0 then
        rewritten_using := replace(rewritten_using, 'is_admin()', 'private.is_admin()');
      end if;
    end if;

    if rewritten_check is not null then
      if position('public.is_admin()' in rewritten_check) > 0 then
        rewritten_check := replace(rewritten_check, 'public.is_admin()', 'private.is_admin()');
      elsif position('private.is_admin()' in rewritten_check) = 0 then
        rewritten_check := replace(rewritten_check, 'is_admin()', 'private.is_admin()');
      end if;
    end if;

    using_sql := case
      when rewritten_using is null then ''
      else format(' using (%s)', rewritten_using)
    end;
    check_sql := case
      when rewritten_check is null then ''
      else format(' with check (%s)', rewritten_check)
    end;

    execute format(
      'alter policy %I on %I.%I%s%s',
      policy_row.policyname,
      policy_row.schemaname,
      policy_row.tablename,
      using_sql,
      check_sql
    );
  end loop;
end;
$$;

-- Trigger guards must use the private helper as well; otherwise a normal
-- owner update could fail merely because the guard calls the revoked wrapper.
create or replace function private.prevent_profile_role_escalation()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
begin
  if new.role is distinct from old.role
     and not private.is_admin()
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
     and not private.is_admin()
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
     and not private.is_admin()
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

-- These functions must not be callable through the public client roles.
revoke all on function public.is_admin() from public, anon, authenticated;
grant execute on function public.is_admin() to service_role;

revoke all on function public.admin_moderate_store(uuid, text, uuid)
  from public, anon, authenticated;
grant execute on function public.admin_moderate_store(uuid, text, uuid)
  to service_role;

-- The bootstrap state is an administrative control record, never a public
-- client resource. Explicit policy removes the advisor warning while keeping
-- it inaccessible to non-admin users.
drop policy if exists admin_bootstrap_state_super_admin
  on public.admin_bootstrap_state;
create policy admin_bootstrap_state_super_admin
  on public.admin_bootstrap_state
  for all
  using (private.is_admin())
  with check (private.is_admin());

commit;

comment on function public.admin_moderate_store(uuid, text, uuid)
is 'Local Admin Backend only; public client roles cannot execute this function.';

comment on function public.is_admin()
is 'Compatibility wrapper retained for server-side triggers; direct client execution is revoked.';
