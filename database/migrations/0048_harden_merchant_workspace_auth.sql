-- 0048_harden_merchant_workspace_auth.sql
-- TASK 012: merchant_open_workspace is an authenticated merchant workspace RPC.
-- Production ACL drift exposed EXECUTE to anon; revoke only anon and preserve
-- authenticated/service_role access. The function remains SECURITY INVOKER and
-- keeps its auth.uid() guard and owner/admin RLS checks.

revoke execute on function public.merchant_open_workspace(
  text, text, uuid, text, text, text
) from anon;

grant execute on function public.merchant_open_workspace(
  text, text, uuid, text, text, text
) to authenticated, service_role;
