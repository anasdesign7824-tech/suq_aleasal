# Supabase Connector Audit

**Project:** سوق العسل / `gvalqfgxrkibuydoiuiz`

**Audit date:** 2026-08-16.

## Connector identity

The user-provided editable API connector is named `gvalqfgxrkibuydoiuiz`, UID `d3fddab8-ecbd-458e-ba4f-e42ff8e54551`, enabled, and configured with an encrypted `service_role` environment value. The secret value is intentionally not copied into this repository or this report.

## Read-only health check

A read-only GET request to the Supabase REST root using the connector-injected secret returned HTTP `200` and a PostgREST OpenAPI document of 123,736 bytes. The response identified the project title as `Souq Al Assal / سوق العسل` and schema version `14.15`. This proves that the new connector reaches the intended project with the expected privileged server credential.

## Auth settings health check

A read-only GET request to `/auth/v1/settings` returned HTTP `200`. The response exposed the provider configuration keys for `email`, `google`, and `facebook`, and reported `disable_signup=false` and `mailer_autoconfirm=false`. This proves that the providers are present in the Auth configuration surface; it does not, by itself, prove a completed end-to-end login for each provider. Provider callback, email delivery/confirmation, Web session restore, and Android deep-link remain runtime tests.

## Database schema health check

The project is `ACTIVE_HEALTHY`, uses Postgres 17, and has public tables with RLS enabled according to the schema inspection. Existing tables include users/profiles/merchant_profiles, regions, categories/honey_taxonomy, stores/store_gallery/store_statistics, products/product_images, reviews/comments/favorites, requests/request_items/request_messages, notifications, banners, delivery/pickup options, admin_roles/admin_users, and audit_logs.

## Critical finding: RLS policy posture

The read-only `pg_policies` inspection returned policies on many tables with `roles={public}` for broad SELECT/INSERT/UPDATE/DELETE commands. This includes sensitive or operational tables such as `admin_roles`, `admin_users`, `audit_logs`, `banners`, `categories`, `honey_taxonomy`, `products`, `stores`, `notifications`, and social/request tables. The security advisor returned no lints, but the policy listing is still a release blocker because absence of an advisor warning is not proof of ownership correctness.

**Impact:** Admin creation, real uploads, production CRUD, and production acceptance must remain blocked until RLS policies are rewritten or verified with backend-enforced ownership/admin-role predicates. Public write must not be used as a shortcut.

**Required next action:** inspect the full `qual` and `with_check` expressions, compare them with intended actors, create an additive security migration, execute negative/positive RLS tests with isolated fixtures, then re-run security advisors and the Battle-Test matrix.

## Performance finding

The performance advisor reported informational unused-index lints for existing indexes, including indexes on banners, stores, products, reviews, comments, requests, notifications, admin_users, audit_logs, regions, and related tables. These are not a release blocker alone because the project has not yet carried production-like traffic, but they must be re-evaluated after real query paths and Admin/Customer load tests. No indexes are removed during this audit based solely on the advisory output.

## Current gate decision

| Gate | Result |
|---|---|
| Connector reaches intended project | PASS |
| Auth provider keys are present | PASS — configuration surface only |
| End-to-end Email/Google/Facebook login | NOT YET PROVEN |
| RLS safe for production Admin/Customer/Merchant | NO-GO until policy expressions are audited/fixed |
| Safe to create Admin user | BLOCKED until role/RLS policy remediation |
| Safe to perform real upload/CRUD | BLOCKED until Storage/RLS audit |

No data mutation was performed by this audit.


## Connector comparison update

The configured Supabase API environment (`SUPABASE_URL` + public `SUPABASE_KEY`) also reached the same project REST endpoint and returned HTTP `200` with the same project title and OpenAPI byte size. The Supabase MCP connector previously listed the same project as `ACTIVE_HEALTHY` and returned the same schema surface. The three access paths are therefore aligned for read access:

| Connector path | Read-only verification | Result |
|---|---|---|
| Supabase MCP | `list_projects`, `list_tables`, advisors, SQL metadata | PASS |
| Supabase API | REST `/rest/v1/` with public key | HTTP 200 PASS |
| Custom project API | REST `/rest/v1/` and `/auth/v1/settings` with encrypted service role | HTTP 200 PASS |

The custom connector is stronger for controlled server-side operations, but its privilege must not be copied to browser/client code. No mutation was performed through any connector.
