begin;

alter table public.admin_users
  add column if not exists is_active boolean not null default true,
  add column if not exists scope jsonb not null default '{}'::jsonb,
  add column if not exists created_by uuid references public.users(id) on delete set null,
  add column if not exists updated_at timestamptz not null default timezone('utc', now());

create table if not exists public.admin_bootstrap_state (
  id boolean primary key default true check (id = true),
  admin_user_id uuid not null references public.admin_users(user_id) on delete restrict,
  bootstrapped_at timestamptz not null default timezone('utc', now()),
  bootstrapped_by uuid references public.users(id) on delete set null
);

alter table public.admin_bootstrap_state enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.admin_users au
    where au.user_id = auth.uid()
      and au.is_active = true
  );
$$;

create or replace function public.is_super_admin()
returns boolean
language sql
security definer
set search_path = public
stable
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

create or replace function public.has_admin_permission(permission_code text)
returns boolean
language sql
security definer
set search_path = public
stable
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

drop policy if exists admin_users_admin_write on public.admin_users;
create policy admin_users_super_admin_write
on public.admin_users for all
using (public.is_super_admin())
with check (public.is_super_admin());

drop policy if exists admin_roles_admin_read on public.admin_roles;
create policy admin_roles_admin_read
on public.admin_roles for select
using (public.is_admin());

drop policy if exists audit_logs_admin_read on public.audit_logs;
create policy audit_logs_admin_read
on public.audit_logs for select
using (public.has_admin_permission('audit.read'));

drop policy if exists audit_logs_admin_insert on public.audit_logs;
create policy audit_logs_admin_insert
on public.audit_logs for insert
with check (actor_user_id = auth.uid() or public.is_super_admin());

create or replace function public.set_admin_users_updated_at()
returns trigger
language plpgsql
security invoker
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists admin_users_updated_at on public.admin_users;
create trigger admin_users_updated_at
before update on public.admin_users
for each row execute procedure public.set_admin_users_updated_at();

insert into public.admin_roles (code, name_ar, permissions)
values
  ('super_admin', 'مدير عام', '{"all": true}'::jsonb),
  ('admin', 'مدير تشغيل', '{"user.read": true, "store.read": true, "store.review": true, "product.read": true, "product.write": true, "banner.read": true, "banner.write": true, "taxonomy.read": true, "request.read": true, "audit.read": true}'::jsonb),
  ('moderator', 'مشرف محتوى', '{"product.read": true, "review.read": true, "review.moderate": true, "request.read": true}'::jsonb)
on conflict (code) do update set
  name_ar = excluded.name_ar,
  permissions = excluded.permissions;

commit;
