-- 0045_foreign_key_indexes.sql
-- Cover foreign keys used by admin queues, payment reconciliation,
-- verification review, and merchant workspace reads.

begin;

create index if not exists design_requests_assigned_admin_id_idx
  on public.design_requests(assigned_admin_id);
create index if not exists design_requests_store_id_idx
  on public.design_requests(store_id);
create index if not exists design_requests_subscription_id_idx
  on public.design_requests(subscription_id);
create index if not exists local_transfer_settings_updated_by_idx
  on public.local_transfer_settings(updated_by);
create index if not exists merchant_subscriptions_activated_by_idx
  on public.merchant_subscriptions(activated_by);
create index if not exists merchant_subscriptions_plan_id_idx
  on public.merchant_subscriptions(plan_id);
create index if not exists payment_events_actor_user_id_idx
  on public.payment_events(actor_user_id);
create index if not exists payment_provider_settings_updated_by_idx
  on public.payment_provider_settings(updated_by);
create index if not exists payment_requests_campaign_id_idx
  on public.payment_requests(campaign_id);
create index if not exists payment_requests_plan_id_idx
  on public.payment_requests(plan_id);
create index if not exists payment_requests_reviewed_by_idx
  on public.payment_requests(reviewed_by);
create index if not exists payment_requests_store_id_idx
  on public.payment_requests(store_id);
create index if not exists payment_requests_verification_request_id_idx
  on public.payment_requests(verification_request_id);
create index if not exists product_revisions_reviewed_by_idx
  on public.product_revisions(reviewed_by);
create index if not exists store_badges_request_id_idx
  on public.store_badges(request_id);
create index if not exists store_verification_documents_merchant_id_idx
  on public.store_verification_documents(merchant_id);
create index if not exists store_verification_documents_store_id_idx
  on public.store_verification_documents(store_id);
create index if not exists store_verification_events_actor_user_id_idx
  on public.store_verification_events(actor_user_id);
create index if not exists store_verification_requests_reviewed_by_idx
  on public.store_verification_requests(reviewed_by);
create index if not exists subscription_campaigns_created_by_idx
  on public.subscription_campaigns(created_by);
create index if not exists subscription_campaigns_updated_by_idx
  on public.subscription_campaigns(updated_by);

commit;
