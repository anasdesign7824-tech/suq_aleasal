-- 0056_harden_private_function_execute.sql
-- Keep RLS authorization helpers callable by API roles, but remove direct
-- EXECUTE from trigger-only/private helpers. Normalize SECURITY DEFINER paths.

begin;

revoke execute on function private.enforce_merchant_product_limit() from public;
revoke execute on function private.enforce_merchant_store_limit() from public;
revoke execute on function private.handle_new_user() from public;
revoke execute on function private.prevent_merchant_verification_changes() from public;
revoke execute on function private.prevent_profile_role_escalation() from public;
revoke execute on function private.prevent_store_moderation_changes() from public;
revoke execute on function private.sync_product_social_counts(uuid) from public;
revoke execute on function private.sync_store_follower_count(uuid) from public;
revoke execute on function private.trg_sync_product_social_counts() from public;
revoke execute on function private.trg_sync_store_follower_count() from public;
revoke execute on function private.subscription_discount_for_plan(uuid, text) from public;

revoke execute on function private.is_admin() from public;
revoke execute on function private.is_super_admin() from public;
revoke execute on function private.has_admin_permission(text) from public;
grant execute on function private.is_admin() to anon, authenticated, service_role;
grant execute on function private.is_super_admin() to anon, authenticated, service_role;
grant execute on function private.has_admin_permission(text) to anon, authenticated, service_role;
grant execute on function private.subscription_discount_for_plan(uuid, text) to authenticated, service_role;

alter function private.handle_new_user()
  set search_path = pg_catalog, public, private, auth;
alter function public.admin_review_merchant_application(uuid, text, text, uuid)
  set search_path = pg_catalog, public, private, auth;

commit;
