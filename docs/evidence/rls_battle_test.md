# RLS Battle-Test Evidence

## Test method

The matrix used the official legacy `anon` publishable key returned by the Supabase project connector, not the opaque environment placeholder. It created two isolated confirmed Auth users, one merchant profile, one active store, and one active product through the server-side connector. It then ran Anonymous, Customer A, and existing Admin session requests through REST. All fixtures were deleted in `finally` cleanup, including Auth users, merchant profile, store, product, admin rows, and any accidental favorite.

## Results

| Scenario | Expected | Result |
|---|---|---|
| Anonymous active banner read | HTTP 200 | PASS |
| Anonymous admin_users read | HTTP 200 with zero rows | PASS |
| Anonymous admin_users insert | HTTP 401/403 | PASS — HTTP 401 |
| Customer A reads Customer B profile | zero rows | PASS |
| Customer A reads admin_users | zero rows | PASS |
| Customer A inserts favorite for Customer B | HTTP 401/403 | PASS — HTTP 403, `42501` |
| Existing Admin reads admin_users role | one matching super_admin row | PASS |
| Fixture cleanup | no retained test data | PASS by cleanup path |

## Interpretation

The initial failed matrix run used the configured opaque `SUPABASE_KEY` and did not represent a valid legacy anonymous JWT for this project. The corrected run used the connector-provided legacy `anon` key. The final matrix passed all checks. The `admin_users` policies and `favorites` ownership policy therefore behaved as intended for the tested paths; no broad policy rewrite was applied to production. The private `admin_user_ids` object is a view over `public.admin_users`, so Admin bootstrap correctly writes the public table and reads the private role gate through the view.

## Remaining RLS work

The matrix is not a claim that every table is fully covered. Merchant ownership, requests/messages, private verification media, audit-log forgery, and Storage object policies remain separate tasks and must be tested as each feature is connected. Any future DDL must be an additive migration with a post-migration re-run of this matrix.
