
# Auth OTP Findings — 2026-08-19

## Confirmed behavior in this project

The new-account path calls `SupabaseAuthGateway.signUp()` and verifies with `verifyOTP(type: OtpType.signup)`. The existing-account login path calls `signInWithOtp(email, shouldCreateUser: false)` and verifies with `verifyOTP(type: OtpType.email)`. These are separate Supabase Auth flows.

Production evidence for `anasdesign7824@gmail.com`: the identity exists in `auth.users`, has a non-null `email_confirmed_at`, and has a recent `last_sign_in_at`. A direct request to `POST https://gvalqfgxrkibuydoiuiz.supabase.co/auth/v1/otp` with `create_user=false` returned HTTP 422, `error_code: otp_disabled`, and `msg: Signups not allowed for otp`. This explains why signup confirmation can work while existing-account passwordless OTP fails.

## Official references

Supabase’s passwordless email guide states that email OTP and magic-link flows share the Auth implementation, that `shouldCreateUser: false` prevents automatic signup, and that verification of an email OTP uses `type: email`:

- https://supabase.com/docs/guides/auth/auth-email-passwordless
- https://supabase.com/docs/reference/dart/auth-signinwithotp
- https://supabase.com/docs/reference/dart/auth-signup
- https://supabase.com/docs/reference/dart/auth-verifyotp

The code-side diagnostic fix now maps `otp_disabled` and related signup-disabled codes to an explicit Arabic message. This does not enable the Supabase project setting; that setting must be enabled in the project Auth configuration or the existing-account flow must be changed to a different supported login contract.

## Supabase dashboard state observed after user confirmation

The Production Auth page shows Email provider Enabled, Allow new users to sign up enabled, and Confirm email enabled. The page does not expose a separate visible `OTP` switch in the current viewport; Email provider configuration and email templates must be inspected next. This is consistent with the direct `/auth/v1/otp` response requiring provider/template configuration rather than a Flutter button route failure.

## Final contract and applied fixes

The accepted contract is: new registration requires name, email, password, and password confirmation; after `signUp()` the user confirms the email with `verifyOTP(type: signup)`. Existing-account login requires email only; it calls `signInWithOtp(... shouldCreateUser: false)` and verifies with `verifyOTP(type: email)`.

The filter failure was fixed in `customer_discovery.dart`: when Production has no products, `dataMaxPrice` is null. The former expression used `dataMaxPrice!` after a condition that could still be true with the fallback value `1`, causing `Null check operator used on a null value` before `showModalBottomSheet`. The replacement uses a non-null `observedMaxPrice`.

The Auth gateway now handles `otp_disabled` in the `shouldCreateUser: false` request context as an unregistered email when the backend returns the misleading `Signups not allowed for otp` response. It no longer changes the successful signup flow.

Windows verification after these changes: Flutter analyzer PASS, all 13 Flutter tests PASS, and the Production build gate PASS. New APK SHA-256: `03b3ae24ee674fcc4eddc9c6c81deda7ee3b6dd9c87d617901110cf613fa9b67`.

A direct Production OTP request for the existing identity returned HTTP 200 after the Auth settings were reviewed. A second immediate request with `create_user=true` was rate-limited, confirming the endpoint was active and the rate limiter—not a UI route failure—controlled the second request.
