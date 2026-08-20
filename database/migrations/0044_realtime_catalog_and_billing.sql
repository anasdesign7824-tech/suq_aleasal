-- 0044_realtime_catalog_and_billing.sql
-- Keep catalog and billing status synchronized for authorized clients.
-- Realtime still evaluates each table's RLS policies before delivering rows.

begin;

alter publication supabase_realtime add table public.products;
alter publication supabase_realtime add table public.stores;
alter publication supabase_realtime add table public.merchant_subscriptions;
alter publication supabase_realtime add table public.payment_requests;

commit;
