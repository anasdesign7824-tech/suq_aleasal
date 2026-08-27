# Assalkom Release Manifest — 2026-08-27

## Canonical production candidate

| Field | Value |
|---|---|
| Artifact | `apps/mobile_flutter/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` |
| Build gate | `tool/build-production.ps1` |
| Mode | `production` |
| Supabase project | `gvalqfgxrkibuydoiuiz.supabase.co` |
| SHA-256 | `67DD0ED2E8DE8599B9B816D45B863FD44E06D4619BF18612F1B7A4FEA86B2B31` |
| Status | `PRODUCTION_CANDIDATE — pending full regression, device smoke, and public distribution URL` |

## Artifact policy

`artifacts/assalkom-production-connected-arm64-release.apk` remains the previously documented production-connected artifact. `artifacts/assalkom-production-arm64-release.apk` is retained only as a quarantined historical artifact because the release contract records that it was built without the required dart-defines. UX/reference and Demo APKs are not production candidates and must not be linked from the public Landing.

The canonical artifact is not copied into Git or public Landing until the complete release gate passes. No Service Role key is included in the client artifact; the client receives only the publishable configuration required by the documented production build.

## Required gates before public download

The candidate still requires full Flutter regression remediation, device install/runtime smoke, confirmation of the release package identity, a public download location, and an approved Cloudflare Pages deployment. Until these gates pass, Landing copy must not claim that a public APK download is available.
