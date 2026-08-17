# Email-only release external requirements and implementation notes

## Supabase native email behavior

Supabase email/password authentication uses the project's Auth service. With email confirmations enabled, a successful sign-up may return no active session until the user confirms the email; the client must present a confirmation message and support password reset through `resetPasswordForEmail`. The project was observed with `mailer_autoconfirm=false`, so production SMTP and confirmation testing remain required.

Source: https://supabase.com/docs/guides/auth/passwords

## Supabase client security

Supabase's Dart reference states that client applications should use the publishable key, while database access still requires Data API grants and RLS policies. The Email-only refactor keeps the publishable key in the APK and does not introduce a service-role key.

Source: https://supabase.com/docs/reference/dart/auth-signinwithidtoken

## Google Play account deletion

Because the app permits account creation, Google Play requires both an in-app account deletion path and an external web resource for account-deletion requests, with associated user data actually deleted rather than merely disabled.

Source: https://support.google.com/googleplay/android-developer/answer/13327111?hl=en

## Current implementation decision

The current Android release removes Google and Facebook UI/actions and removes the `google_sign_in` dependency. The later provider rollout can be added without changing the `auth.users.id`-based data model, provided future account linking reuses the existing account rather than creating a duplicate user.
