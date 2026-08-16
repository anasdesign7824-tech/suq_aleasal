# Customer Auth / Production Build Battle-Test

## نطاق الاختبار

يوثق هذا الملف الاختبارات الفعلية لنسخة العميل بعد إضافة Supabase Production Auth وOAuth session polling، مع فصل واضح بين ما نجح وما بقي محجوزًا بسبب اتصال المحاكي.

| الاختبار | النتيجة | الدليل التشغيلي |
|---|---:|---|
| Flutter Web Production build | PASS | `√ Built build\\web` بعد نجاح Wasm dry-run وعدم ظهور compile error |
| Flutter Android Release build | PASS | `√ Built build\\app\\outputs\\flutter-apk\\app-release.apk (78.0MB)` |
| APK installation on Mimo | PASS | `Success: streamed 81831283 bytes` ثم `Success` |
| Android process startup | PASS | `ActivityTaskManager: Displayed com.assalkom.assalkom/.MainActivity` و`Fully drawn` |
| Startup crash scan | PASS | لا توجد `FATAL EXCEPTION` أو `AndroidRuntime` fatal في logcat الملتقط بعد الإقلاع |
| OAuth callback intent routing | PASS | `am start -W` للعنوان `com.assalkom.assalkom://login-callback/` أعاد `Status: ok` و`Activity: com.assalkom.assalkom/.MainActivity` |
| Email/Google/Facebook interactive completion | BLOCKED | Mimo أصبح offline بعد إعادة تشغيل MuMu تلقائيًا؛ المنفذ القديم `127.0.0.1:5555` رفض الاتصال، والمنافذ الجديدة ظهرت offline (`23571`, `24576`). يلزم إعادة اتصال المحاكي قبل إدخال بيانات Auth أو إكمال OAuth مع مزود خارجي. |

## ملاحظات الإصدار

تم بناء النسختين باستخدام Supabase URL وpublishable key العامين و`ASSALKOM_MODE=production`، من خلال المسار `X:` لتجاوز فحص Android Gradle للـ Unicode في مسار Windows. تم تثبيت Gradle wrapper 9.1.0، وتشغيل Kotlin compiler in-process وتعطيل incremental caches بعد كشف فشل `LazyStorage/FilePageCache` أثناء أول APK battle-test.

أضيف في واجهة Auth polling لمدة تصل إلى 60 ثانية بعد نتيجة `oauth_started`، بحيث يعاد فحص `repository.getSession()` بعد الرجوع من Google/Facebook بدل بقاء الشاشة على حالة قديمة. أزيل زر استعادة كلمة المرور غير المنفذ، وصححت رسالة تسجيل الخروج لتفرّق بين Demo وProduction.

## الحالة التالية

لا يُعتمد إكمال Auth end-to-end على Web/APK قبل عودة Mimo إلى حالة `device` في `adb devices`. لا توجد نتيجة Email/Google/Facebook حقيقية في هذا السجل حتى الآن؛ نتائج البناء والإقلاع والـ deep-link وحدها لا تكفي لاعتبار OAuth مكتملًا.
