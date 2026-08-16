# Release Manifest — Customer App

## Source

| Item | Value |
|---|---|
| Repository | `anasdesign7824-tech/suq_aleasal` |
| Branch | `main` |
| Final source commit | `50053d109095a5fc38b327b6d939f3c197630208` |
| Desktop checkout | `D:\suq_aleasal_audit2` |
| Desktop working tree | Clean and synchronized with `origin/main` |

## Artifacts

| Artifact | Build command | Size / SHA-256 |
|---|---|---|
| Android release APK | `flutter build apk --release` | 75.5 MB; `5f54aa7d5fd11a78be0f44da5b1f25cce5bc95175e31d96b7c4ff9364af71640` |
| Android debug APK | `flutter build apk --debug` | SHA-256 `6d573d74422e502b8964ee069b585221cabc4ebded510cbf6b773705f98b8092` |
| Web `index.html` | `flutter build web --release` | 1,550 bytes |
| Web `main.dart.js` | `flutter build web --release` | 3,578,494 bytes |

## Verification record

The final release APK was installed on Mimo with `adb install -r` and returned `Success`. After launch, `com.assalkom.assalkom/.MainActivity` was the foreground activity and the inspected logcat window contained no `FATAL` line. The Web artifact was served with a static Node server; both `/` and `/main.dart.js` returned HTTP 200. The final source was pulled to the connected desktop and the working tree remained clean.

The latest automated gate remains `flutter analyze --no-pub` with `No issues found!` and `flutter test` with 6 passing tests. This manifest does not override the GO memo: production launch remains conditional on Backend/Auth/RLS, production signing, and manual browser/accessibility acceptance.
