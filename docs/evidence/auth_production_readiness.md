# Auth Production Readiness Evidence

## Scope

This evidence covers the first real Auth integration slice for Customer and local Admin. Firebase is not used. The client uses Supabase Auth with Email/Password, Google OAuth, and Facebook OAuth. The Flutter bootstrap supports Demo and Production explicitly; Production requires `ASSALKOM_MODE=production`, `ASSALKOM_SUPABASE_URL`, and `ASSALKOM_SUPABASE_PUBLISHABLE_KEY` and no longer silently falls back to Demo.

## Provider and redirect baseline

The live Supabase project is `gvalqfgxrkibuydoiuiz`, and the API audit confirmed Email, Google, and Facebook providers are enabled. The Google Web OAuth client callback is the Supabase callback endpoint. Android returns through `com.assalkom.assalkom://login-callback/`, with an Android intent filter in the APK manifest. Client secrets are not stored in Flutter, Git, or this evidence file.

## Code boundary

`SupabaseAuthGateway` owns provider calls and maps Supabase errors to Arabic typed `AssalAuthFailure` values. `SupabaseQueryGateway` owns PostgREST reads/writes. `ProductionRepository` hydrates `AssalSession` from Auth plus `profiles` and checks `admin_users`; Demo remains offline and explicitly disables Google/Facebook with a reason. `AssalApp` shows a configuration error for an incomplete Production environment instead of presenting Demo data.

## Admin bootstrap

A real Supabase Auth user was created for local Admin operation. The credential handoff is stored outside Git in `/home/ubuntu/assalkom_admin_local_credentials.txt` with filesystem mode `0600`; the password is intentionally absent from this evidence. The user was linked to the existing `super_admin` role in `public.admin_users`. `private.admin_user_ids` is a view over `public.admin_users`, so inserting the public row is the correct bootstrap path.

| Check | Result |
|---|---|
| Auth user created | PASS |
| `public.admin_users` role | `super_admin` |
| `private.admin_user_ids` reflection | PASS |
| Password login through Supabase Auth | HTTP 200 PASS |
| Returned user ID matches bootstrap ID | PASS |
| Admin role row readable using the user session | HTTP 200, 1 row PASS |
| Password/client secrets committed to Git | NO |

## Current limitation

This proves the Auth boundary and Admin identity, not the final Admin UI or full RLS matrix. The next task is a security migration/audit for anonymous, customer, merchant, and Admin actions, followed by real Storage and Admin CRUD tests.
