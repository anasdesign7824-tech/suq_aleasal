# عقد بناء نسخة Production

## المشكلة التي أُغلقت

كانت نسخة APK المسماة `assalkom-production-arm64-release.apk` قد بُنيت بأمر Flutter لا يحتوي على `--dart-define-from-file=assalkom.production.defines.json`. وبما أن `AssalRuntimeConfig` كان يستخدم `demo` كقيمة افتراضية، دخلت النسخة إلى `DemoRepository` ولم تهيئ `Supabase.initialize` أصلًا. لذلك ظهرت البيانات المحلية ولم يعمل إرسال OTP؛ لم يكن الخلل في بريد Supabase، بل في أن APK لم يكن Production متصلًا من الأساس.

## القاعدة الجديدة

لا يسمح Runtime Config بالرجوع الصامت إلى Demo. وضع Demo لا يعمل إلا عند تمرير `ASSALKOM_MODE=demo` صراحة. عند غياب التعريفات، يكون الوضع `unconfigured` وتظهر شاشة خطأ تشغيل بدل فتح التطبيق ببيانات وهمية. وضع Production لا يعتبر مهيأً إلا إذا كان عنوان Supabase صالحًا ويبدأ المفتاح العام بـ`sb_publishable_`.

## أمر البناء الإلزامي

من جذر المستودع على Windows:

```powershell
.\tool\build-production.ps1
```

تتحقق البوابة من الملف `assalkom.production.defines.json` ثم تستدعي:

```powershell
flutter build apk --release --target-platform android-arm64 --split-per-abi --dart-define-from-file=assalkom.production.defines.json
```

لا يجوز تسمية ناتج أمر Flutter مباشر بلا هذه التعريفات باسم Production. نسخة Demo لها مسار منفصل وصريح، ولا تمثل نسخة Production.

## التحقق المنفذ

| الفحص | النتيجة |
|---|---|
| `flutter analyze --no-pub` | PASS |
| `flutter test --no-pub` | PASS — 13 اختبارًا |
| بوابة `build-production.ps1` | PASS — mode=production |
| اتصال REST إلى Supabase `regions` | HTTP 200 |
| اتصال Supabase Auth `settings` | HTTP 200 |
| عنوان Supabase داخل AOT للـAPK الجديد | موجود |
| عنوان Supabase داخل AOT للـAPK القديم 20.30 MB | غير موجود |

## النسخة المصححة

الملف المصحح هو `assalkom-production-connected-arm64-release.apk`، حجمه **21,872,688 بايت**، وبصمته SHA-256 هي:

```text
f94b69ef058443c0b33f143547cbf1c0620d01b1a8ff4aaa1414b0a43065001d
```

هذه البصمة تخص build مرّ عبر بوابة Production ويحتوي على عنوان مشروع Supabase الصحيح. يجب اختبار تسجيل الدخول بهذا الملف، وليس بالملف القديم ذي 20.30 MB.
