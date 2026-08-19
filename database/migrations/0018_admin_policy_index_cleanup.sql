-- Remove legacy duplicate policies left by the admin identity lifecycle
-- migrations. Keep the stricter super-admin write boundary and the initplan-safe
-- policies from 0003/0007.
drop policy if exists admin_roles_select on public.admin_roles;
drop policy if exists admin_users_admin_read on public.admin_users;
drop policy if exists admin_users_insert on public.admin_users;
drop policy if exists admin_users_update on public.admin_users;
drop policy if exists admin_users_delete on public.admin_users;
drop policy if exists audit_logs_admin_insert on public.audit_logs;

-- Cover the foreign keys reported by Supabase Performance Advisor.
create index if not exists admin_bootstrap_state_admin_user_id_idx
  on public.admin_bootstrap_state(admin_user_id);
create index if not exists admin_bootstrap_state_bootstrapped_by_idx
  on public.admin_bootstrap_state(bootstrapped_by);
create index if not exists admin_users_created_by_idx
  on public.admin_users(created_by);
create index if not exists conversations_created_by_idx
  on public.conversations(created_by);
create index if not exists merchant_application_drafts_region_id_idx
  on public.merchant_application_drafts(region_id);
create index if not exists merchant_applications_region_id_idx
  on public.merchant_applications(region_id);
create index if not exists merchant_applications_reviewed_by_idx
  on public.merchant_applications(reviewed_by);
create index if not exists messages_sender_id_idx
  on public.messages(sender_id);
