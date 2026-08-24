# TASK 076 — دليل فشل الاتصال وإعادة المحاولة

## نطاق المهمة

تغطي المهمة تحويل أخطاء الاتصال في طبقة Production إلى حالات `AssalError` قابلة لإعادة المحاولة، وعدم تحويل فشل استعلام الهوية إلى استثناء غير معالج أو إلى ضيف صامت.

## نتيجة جرد المصدر

المراجع `screens/076_state_connection_error.png` و`explanations/076_state_connection_error.md` غير موجودة في checkout الحالي، لذلك بقي القبول البصري محجوبًا ولم يُنشأ baseline بديل.

## الفجوة المثبتة والإصلاح

كان `_readList` في `ProductionRepository` يلتقط بعض رسائل الشبكة بصيغة حساسة لحالة الأحرف، لكنه لا يصنف رسالة عامة مثل `network unavailable` كخطأ شبكي قابل لإعادة المحاولة. أدى ذلك إلى `AssalErrorKind.server` و`retryable=false` رغم أن السبب شبكي. كما كان استدعاء `AssalAuthGateway.currentIdentity()` خارج حارس استثناء، مما قد يترك `getSession()` كـFuture فاشل بدل إرجاع `AssalSession.unavailable` الموحدة.

أضيفت دالة داخلية موحدة `_isNetworkError` تشمل timeout وSocketException وفشل/رفض/إغلاق الاتصال ورسائل الشبكة العامة، واستُخدمت في مساري القراءة والكتابة وتصنيف الخطأ. كما حُرس استدعاء `currentIdentity()` وأصبح فشله يعيد جلسة غير متاحة ويمسح cache الجلسة، دون تغيير عقد API أو DB أو RLS أو الصلاحيات.

## الاختبارات

```text
flutter analyze --no-pub
No issues found!

flutter test --no-pub test/task076_connection_error_test.dart
00:02 +2: All tests passed!

flutter test --no-pub test/task095_failure_recovery_test.dart --plain-name 'ProductionRepository recovers after a transient read failure'
00:03 +1: All tests passed!

flutter test --no-pub test/data_layer_test.dart --plain-name 'Unavailable session is distinct from an intentional guest session'
00:02 +1: All tests passed!

flutter test --no-pub test/data_layer_test.dart --plain-name 'Factory rejects production without an explicit gateway'
00:02 +1: All tests passed!
```

يثبت الاختبار الجديد أن القراءة التي تفشل برسالة شبكة عامة تعيد `AssalErrorKind.network` مع `retryable=true` وcode=`network`، وأن فشل `currentIdentity()` يعيد `AssalSession.unavailable`. كما يثبت regression TASK 095 التعافي بعد فشل قراءة شبكي عابر، وتحافظ اختبارات طبقة البيانات على تمييز الضيف المقصود عن الجلسة غير المتاحة وحدود factory.

## القبول والحدود

القبول الوظيفي لطبقة التحويل والحارس: **PASS**. القبول البصري: **BLOCKED** لفقدان PNG/Markdown TASK 076. لا يثبت ذلك اتصالًا حيًا بـSupabase أو زمن استجابة أو مزامنة متعددة الأجهزة؛ لا تغييرات DB/API/RLS/permissions.
