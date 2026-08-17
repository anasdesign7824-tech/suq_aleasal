# Shared Build Matrix Gate — 2026-08-17

## الغرض

تم بناء النسخ من نفس الجذر المشترك بعد تحسينات UX/UI. الاختلاف الوحيد المقصود هو مصدر البيانات وتهيئة Production، وليس مكونات التصميم أو منطق التنقل.

## النتائج

| النسخة | الوضع | ABI/الحزمة | الحجم بالبايت | الحجم التقريبي |
|---|---|---|---:|---:|
| `app-debug-demo.apk` | Demo | Debug APK | 184,317,600 | 175.78 MiB |
| `app-release-demo-arm64.apk` | Demo | ARM64 Release | 20,673,094 | 19.72 MiB |
| `app-release-demo-x86_64.apk` | Demo | x86_64 Release | 22,173,205 | 21.14 MiB |
| `app-release-demo.aab` | Demo | Android App Bundle | 56,227,627 | 53.60 MiB |
| `app-release-production-arm64.apk` | Production | ARM64 Release | 21,262,918 | 20.28 MiB |
| `app-release-production.aab` | Production | Android App Bundle | 57,860,297 | 55.18 MiB |

## التحقق

- `flutter analyze`: **PASS — No issues found**.
- `flutter test`: **PASS — 11 tests passed**.
- `git diff --check`: **PASS**.
- SHA-256 hashes محفوظة في `build_matrix_2026-08-17/SHA256SUMS.txt`.
- Demo/Debug/Release/AAB تستخدم نفس ملفات `lib/core`, `lib/app`, و`lib/features`; Production يبدّل Repository/Auth عبر `ASSALKOM_MODE` وSupabase dart-defines فقط.

## تفسير الحجم

Debug أكبر بكثير لأنه يتضمن أدوات التصحيح وFlutter debug runtime. ARM64 وx86_64 Release منفصلان لأن كل APK يحتوي native libraries لمعمارية واحدة. AAB أكبر من APK الخاص بمعمارية واحدة لأنه يحمل حزم توزيع متعددة، ثم يختار Google Play ما يلزم للجهاز.

## البوابة

**PASS — shared-source build matrix.**

Visual QA على Mimo سيستخدم `app-release-demo-arm64.apk` و`app-release-production-arm64.apk` على التوالي، مع الاحتفاظ بالـhash لتحديد النسخة التي تم اختبارها فعليًا.
