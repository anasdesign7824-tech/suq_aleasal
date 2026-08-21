-- 0055_reconcile_store_merchant_uniqueness.sql
-- Preserve the one-store-per-merchant invariant required by merchant_open_workspace.
-- Production already passed the duplicate-row probe and the rollback test.

begin;

create unique index if not exists stores_one_per_merchant_idx
  on public.stores(merchant_id);

commit;
