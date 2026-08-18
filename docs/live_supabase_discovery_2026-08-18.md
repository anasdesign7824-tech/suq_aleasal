# Live Supabase Discovery — 2026-08-18

## Project

- Project ID/ref: `gvalqfgxrkibuydoiuiz`
- Name: `سوق العسل`
- Region: `ap-northeast-2`
- Status: `ACTIVE_HEALTHY`
- Database engine: PostgreSQL 17.6.1.155

## Live row counts observed from list_tables

- `public.users`: 1 row
- `public.profiles`: 1 row
- `public.merchant_profiles`: 0 rows
- `public.regions`: 357 rows
- `public.categories`: 9 rows
- `public.honey_taxonomy`: 39 rows
- `public.stores`: 0 rows
- `public.store_followers`: 0 rows
- `public.store_gallery`: 0 rows
- `public.store_statistics`: 0 rows
- Additional tables were present in the verbose schema result and must be queried in bounded, column-specific reads before any write.

## Live schema/security observations

The live database confirms RLS is enabled on the observed public tables. `public.users` references `auth.users`; `profiles` references `users`; `merchant_profiles` references `users`; `stores` references `merchant_profiles` and `regions`; `products` references `stores`, `honey_taxonomy`, categories, and images. `regions` contains `parent_region_id`, `region_level`, stable `code`, and normalized names, supporting governorate/district cascading selectors. `categories` contains `parent_id`, `slug`, `category_kind`, `sort_order`, and `is_active`. `honey_taxonomy` contains canonical `code`, names, metadata, and active state.

The live data confirms the current Production database is effectively empty for merchants/stores/products while reference regions/categories/taxonomy exist. This explains why a correctly configured Production UI may show empty states while Demo shows a complete catalog. No Demo data should be inserted into Production as a shortcut.

## Safety status

No DDL, INSERT, UPDATE, DELETE, Bootstrap, Auth mutation, Storage mutation, or RLS change was executed during this discovery read. The next live queries must be read-only, bounded, column-specific, and explicitly limited. Any DDL must wait for the approved GAP/Migration plan and Gate 2.
