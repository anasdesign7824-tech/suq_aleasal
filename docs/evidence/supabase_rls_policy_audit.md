# Supabase RLS Policy Audit

**Project:** `gvalqfgxrkibuydoiuiz`.

**Source:** read-only query of `pg_policies` on `public`.

## Important interpretation

The `roles` field is `{public}` on the existing policies, but the policy expressions are not uniformly public-readable. Many policies call `is_admin()` or compare ownership to `auth.uid()`. Therefore the first observation was a valid security signal but not enough to conclude that every table is openly writable. The actual release decision must be based on the full `qual`/`with_check` expressions and negative tests with anonymous, Customer, Merchant, and Admin sessions.

## Observed policy families

| Family | Observed predicates | Initial assessment |
|---|---|---|
| Admin roles/users | `is_admin()` for mutations; self/admin select for admin_users | Requires testing with anonymous and ordinary user; role bootstrap must be safe |
| Audit logs | actor self or `is_admin()` insert; admin-only select | Must prevent ordinary users from forging arbitrary actor IDs and deleting logs; verify no delete policy |
| Banners/categories/taxonomy/regions/delivery | public select constrained by active/admin; mutations `is_admin()` | Correct intent if `is_admin()` cannot be escalated; verify function security and role source |
| Profiles/users | self/admin access | Verify public store/user cards do not require private profile access |
| Merchant profiles/stores | owner/admin writes; active/owner/admin reads | Verify merchant ownership and `merchant_id` cannot be spoofed on insert |
| Products/images/categories/certifications | merchant ownership through store/product joins or admin | Verify all joins reject IDOR and draft/private product exposure |
| Favorites/followers | self ownership for writes/select | Verify cross-user reads/writes are denied |
| Requests/items/messages | requester/merchant participant/admin predicates | Verify participant-only access and sender spoofing prevention |
| Notifications | user-owned select/update | Need admin insert path and no cross-user update |
| Store gallery/delivery/pickup/handoff/social | store merchant/admin predicates; active public read | Verify inactive/private store data is not exposed to Guest |

## Critical functions to inspect

`is_admin()` is a security boundary and must be inspected for SQL security mode, search path, role source, null/anonymous behavior, and resistance to profile-role self-escalation. It must not trust a client-supplied role or an unrestricted `profiles.role` update.

## Required positive tests

1. Active public banner/category/taxonomy/product/store reads work anonymously where intended.
2. Authenticated Customer can read and mutate only their own profile/favorites/follows/requests/messages/notifications.
3. Merchant can mutate only their own store, products, gallery, delivery, pickup, handoff, and social links.
4. Admin Auth user with verified admin role can manage the intended admin surfaces.

## Required negative tests

1. Anonymous cannot insert/update/delete admin_roles/admin_users/banners/products/stores/notifications.
2. Customer A cannot read or mutate Customer B private data.
3. Merchant A cannot read or mutate Merchant B store/product/media/requests.
4. A non-admin cannot change role/profile fields to become admin.
5. A requester or merchant cannot read messages/requests outside participation.
6. A user cannot forge `actor_user_id` in audit logs or delete/update audit history.
7. Private verification objects are not accessible through public Storage URLs.

## Gate

No Admin account creation, production CRUD, or real upload is accepted until `is_admin()` and the relevant policies are tested with isolated accounts and fixtures. No policy is changed in this audit; the next step is controlled function/policy inspection followed by an additive migration only if a proven gap remains.


## `is_admin()` implementation result

The public wrapper `public.is_admin()` is a stable SQL function with `search_path=public, private` that delegates to `private.is_admin()`. The private function is `SECURITY DEFINER`, stable, and sets `search_path=private, public`; it returns true only when `auth.uid()` exists in `private.admin_user_ids(user_id uuid)`. This is a materially safer role source than trusting a client-editable profile role, but the bootstrap path still needs to be tested: the Admin Auth user must be inserted into the controlled admin source without exposing a public self-service path.

The private role source has only the expected `user_id uuid` column in the schema inspection. No Admin user was created during this audit. The next safe step is to use the server-side connector for a controlled idempotent bootstrap only after the user identity and generated credential handoff are recorded outside Git, then verify anonymous/customer denial and Admin allow paths.
