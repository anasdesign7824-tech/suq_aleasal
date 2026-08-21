-- 0057_restore_public_is_admin_execute.sql
-- Storage policies resolve is_admin() to public.is_admin(). Keep the helper
-- callable by API roles while preserving its SECURITY DEFINER implementation.

begin;

grant execute on function public.is_admin() to anon, authenticated, service_role;

commit;
