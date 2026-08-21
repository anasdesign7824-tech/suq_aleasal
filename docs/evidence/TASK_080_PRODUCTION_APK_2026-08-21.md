# TASK 080 — Production APK ABI Artifacts

**التاريخ:** 2026-08-21

**الحالة:** PASS — Production artifacts verified

## نطاق التحقق

تم فحص مسار بناء Android ومصدر runtime configuration وسكربت البناء. ملف `assalkom.production.defines.json` يحدد `ASSALKOM_MODE=production`، وعنوان Supabase هو مشروع Production الصحيح، بينما لم يُسجل المفتاح العام في هذا الدليل. استُخدم ملف defines نفسه عبر `--dart-define-from-file`، ولم تُخترع قيم أو تُستخدم قيم بديلة.

أظهر الفحص الأول أن سكربت البناء كان يمرر `--target-platform android-arm64` رغم طلب split-per-ABI، ولذلك كان ينتج arm64 فقط. تم تصحيح السكربت تصحيحًا محافظًا بإزالة القيد الوحيد على arm64، وإضافة تحقق إلزامي من وجود `app-arm64-v8a-release.apk` و`app-armeabi-v7a-release.apk` و`app-x86_64-release.apk` عند البناء المقسم.

كما أظهر فحص مسار التشغيل أن `AssalApp` كان يستورد `DemoRepository` ويستخدمه كـ fallback عند غياب repository. هذا لا يُستخدم عندما يمرر `main.dart` `ProductionRepository`، لكنه كان يسمح بدخول مسار catalog تجريبي ضمن التطبيق. أزيل هذا fallback وأصبح غياب مصدر البيانات يعرض شاشة خطأ صريحة بدل تحميل بيانات تجريبية. لم يتغير مسار Production المتصل بـ Supabase.

## أوامر بوابة البناء والاختبار

```powershell
Set-Location 'D:\suq_aleasa'
& '.\tool\build-production.ps1' -Flutter 'D:\DevTools\Flutter\bin\flutter.bat'
```

وتضمن السكربت استخدام `build apk --release --dart-define-from-file=assalkom.production.defines.json --split-per-abi`، ثم يتحقق من artifacts الثلاثة ويحسب SHA-256 لكل واحد.

بعد تعديل الفصل بين Demo وProduction:

```text
flutter analyze --no-pub
No issues found! (ran in 81.6s)

flutter test --no-pub
00:34 +54: All tests passed!
```

## سجل artifacts

| ABI | الملف | الحجم بالبايت | SHA-256 |
|---|---|---:|---|
| arm64-v8a | `app-arm64-v8a-release.apk` | 22,768,389 | `00a18e3b66da966456384b5534c70ac03b1b5ea34c1762af7d31650081d426de` |
| armeabi-v7a | `app-armeabi-v7a-release.apk` | 20,590,611 | `99e936b472ffde58d493d6bebd0bdc568ed418c2181ed1f9112571ba49f04b39` |
| x86_64 | `app-x86_64-release.apk` | 24,242,592 | `40353aaf460c832447397fa1bcca9b4252819842f38da03de3c1824004b12dbc` |

المسار المحلي لجميع الملفات هو:

```text
D:\suq_aleasa\apps\mobile_flutter\build\app\outputs\flutter-apk\
```

## تحقق ABI وDemo catalog

تم تشغيل `tool\verify-production-apks.ps1` بعد إعادة البناء الأخيرة. لكل artifact كانت النتيجة `ExpectedAbiPresent=True` و`OtherTargetAbiPresent=False`. عدد Zip entries لكل APK هو 393. بعد إزالة fallback التجريبي كانت نتيجة `DemoLikeRawMatches=NONE` لكل الملفات، وخرج التدقيق النهائي:

```text
VERIFY_PRODUCTION_APKS=PASS
```

هذا الفحص لا يعتبر كلمة `demo` العامة في runtime config دليلًا على catalog؛ بل يبحث عن مؤشرات catalog التجريبي الفعلية مثل `demo-conversation` و`demo-store` و`demo-product` و`InMemoryDemoCatalogLoader` و`Demo Mode`.

## الملفات المعدلة أو المضافة

| الملف | التغيير |
|---|---|
| `tool/build-production.ps1` | إزالة القيد الثابت `android-arm64` والتحقق من ABI الثلاثة وحساب hashes لها. |
| `apps/mobile_flutter/lib/app/assal_app.dart` | إزالة استيراد وfallback `DemoRepository`؛ repository Production أصبح مطلوبًا عند عرض Home. |
| `tool/verify-production-apks.ps1` | إضافة تدقيق ABI ومحتوى APK وعدم وجود مؤشرات catalog تجريبي فعلية. |
| `docs/evidence/task080_apk_hashes.txt` | سجل خام للأسماء والأحجام وSHA-256 الناتجة من PowerShell. |
| `docs/evidence/TASK_080_PRODUCTION_APK_2026-08-21.md` | هذا الدليل القابل للمراجعة. |

## الحكم

**TASK 080 مغلقة PASS.** تم إنتاج APK Release منفصل لكل ABI المطلوب، وكل نسخة مبنية بوضع Production مع defines Supabase الموثقة، ونجحت اختبارات Flutter، ونجح تحقق ABI وSHA-256 وعدم وجود catalog تجريبي فعلي. لا يعني ذلك تنفيذ اختبار OTP على جهاز حقيقي داخل هذه المهمة؛ ذلك يبقى ضمن اختبارات التكامل والقبول اللاحقة في المصفوفة.
