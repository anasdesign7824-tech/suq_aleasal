# External launch requirements gathered for Souq Al Assal

## Google Play target API

Source: https://support.google.com/googleplay/android-developer/answer/11926878?hl=en

Google Play states that starting August 31, 2026, new apps and app updates must target Android 16 / API 36 or higher. The current artifact was inspected as compile/target SDK 36, so it meets this stated target requirement. The same page states that new personal developer accounts created after November 13, 2023 must complete the closed-testing workflow described on the testing requirements page before production access.

## Play App Signing

Source: https://developer.android.com/studio/publish/app-signing

Google requires Android artifacts to be digitally signed. For Google Play, the recommended flow is an upload key plus Play App Signing. The current repository still uses `signingConfigs.getByName("debug")`; the locally built APK reports certificate DN `Android Debug`, so it is not a Play release artifact. A production upload key/keystore and Play App Signing setup are required. Google states that the app-signing and upload certificate fingerprints can be obtained from Play Console and registered with API providers such as Google Sign-In.

## Data safety and privacy

Sources:
- https://support.google.com/googleplay/android-developer/answer/10787469?hl=en-GB
- https://support.google.com/googleplay/android-developer/answer/10144311?hl=en

Google Play requires a complete and accurate Data safety declaration, including data handled by third-party SDKs. It also requires a publicly accessible privacy-policy URL and in-app access to the policy. The declaration must match actual collection, sharing, security, retention, and deletion behavior.

## Account deletion

Source: https://support.google.com/googleplay/android-developer/answer/13327111?hl=en

Because the app allows account creation, Google Play requires a discoverable in-app account-deletion path and an external web resource for account-deletion requests. Associated user data must actually be deleted, not merely disabled or frozen.

## Play review credentials and testing

Sources:
- https://support.google.com/googleplay/android-developer/answer/15748846?hl=en
- https://support.google.com/googleplay/android-developer/answer/14151465?hl=en

Review credentials must remain reusable, accessible, valid from any location, and supplied in English. If a review flow uses Google or another provider, Play asks for all necessary account information and clear instructions. For new personal developer accounts created after November 13, 2023, Google requires a closed test with at least 12 continuously opted-in testers for at least 14 days before applying for production access.

## Supabase native Google

Sources:
- https://supabase.com/docs/guides/auth/social-login/auth-google
- https://supabase.com/docs/reference/dart/auth-signinwithidtoken

Supabase documents native Flutter Google sign-in by obtaining the Google ID token and passing it to `auth.signInWithIdToken`. For Android, the Android OAuth client must include the SHA-1 fingerprint of the certificate used to sign the app. Local/testing and production/Play signing certificates have different fingerprints and the relevant client IDs must be registered in the Supabase Google provider. Supabase also documents that publishable keys are appropriate for client-side apps and that database access still requires Data API grants plus RLS policies.

## Supabase native Facebook

Source: https://supabase.com/docs/guides/auth/social-login/auth-facebook

Supabase documents two options: hosted OAuth through a redirect, or native Facebook SDK plus `signInWithIdToken`. Native Facebook requires the `flutter_facebook_auth` SDK and Facebook app configuration, including `public_profile` and `email` permissions. The current APK intentionally hides Facebook on Android until that native SDK and its app credentials are configured; the current source does not claim native Facebook readiness.
