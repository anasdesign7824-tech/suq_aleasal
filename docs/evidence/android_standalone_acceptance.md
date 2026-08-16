# Android Standalone Acceptance Evidence

## Scope

This evidence records the Android-first delivery gate for Souq Al Assal after separating the APK authentication path from the deferred Web path. The Android build uses native Google account authentication on Android through `google_sign_in` and Supabase `signInWithIdToken`. The Android manifest no longer declares the `com.assalkom.assalkom://login-callback/` deep-link intent filter.

## Source and delivery commit

The source is clean on branch `main` at commit `3129b64`, following the implementation commit `a0920a2` (`feat: make Android auth native and redirect-free`) and the dependency lock commit `3129b64` (`chore: lock Flutter production dependencies`). The repository is synchronized with `origin/main`.

## Automated gates

| Gate | Result | Evidence |
|---|---:|---|
| Flutter dependency resolution | PASS | Flutter 3.47.0 / Dart 3.13.0 resolved `google_sign_in 7.2.0` and Supabase dependencies. |
| `flutter analyze --no-pub` | PASS | `No issues found!` |
| `flutter test --no-pub` | PASS | `+8: All tests passed!` |
| Flutter Web release compile | PASS | `Built build/web`; Web remains a separate deferred path. |
| Android release APK build | PASS | `Built build/app/outputs/flutter-apk/app-release.apk (83.1MB)`. |
| APK package inspection | PASS | Package `com.assalkom.assalkom`, compile/target SDK 36, min SDK 24, launcher `MainActivity`. |
| Redirect manifest scan | PASS | No `login-callback`, `BROWSABLE`, or `android.intent.action.VIEW` markers were found in the APK manifest. |
| APK Google plugin inspection | PASS | APK contains Google Identity/Google Sign-In Android plugin classes and `googleid.properties`. |

## Artifact

The self-built artifact is `assalkom_android_standalone.apk`. SHA-256:

`a95e1a84405576b8333f7e2483b37c231b1fd48a7b929f2482464e84a2409541`

## Supabase check

The Supabase project `gvalqfgxrkibuydoiuiz` is `ACTIVE_HEALTHY`, with Postgres 17.6.1. The security advisor returned one warning: leaked password protection is disabled. This does not block Google native sign-in, but it is a production security hardening item that should be enabled in Supabase Auth before broad public launch.

## Runtime gate

A local Android 36 Google APIs AVD was created. The sandbox does not expose `/dev/kvm`; x86_64 Android Emulator therefore failed the hardware-acceleration requirement. A software-acceleration attempt started the emulator process but did not reach `sys.boot_completed=1` within the test window and was stopped. Consequently, this environment proves source analysis, automated customer journeys, Web compile, APK packaging, manifest isolation, and plugin inclusion, but it does not prove an interactive Google account chooser session or a real Supabase sign-in on a booted Android runtime.

The previously connected Mimo runtime is the appropriate remaining gate for installation and interactive account-chooser verification. No claim of 100% interactive Google acceptance is made until that runtime test is completed.
