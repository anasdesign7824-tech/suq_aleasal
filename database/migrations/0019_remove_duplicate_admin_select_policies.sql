-- Keep the permission-aware policies from the admin identity lifecycle.
-- The older broad SELECT policies are duplicates after 0007.
drop policy if exists admin_users_select on public.admin_users;
drop policy if exists audit_logs_select on public.audit_logs;
