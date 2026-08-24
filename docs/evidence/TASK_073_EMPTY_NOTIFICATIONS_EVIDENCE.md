# TASK 073 — دليل حالة فراغ الإشعارات

## نطاق المهمة

تغطي المهمة حالة عدم وجود إشعارات للمستخدم المصادق عليه، مع رسالة عربية واضحة وإجراء حقيقي لاستكشاف السوق، وبقاء الضيف خلف بوابة المصادقة وحالات الجلسة غير المتاحة خلف retry.

## نتيجة جرد المصدر

المراجع `screens/073_state_empty_notifications.png` و`explanations/073_state_empty_notifications.md` غير موجودة في checkout الحالي، كما يثبت خط الأساس العام. لم تُنشأ صورة أو عقد بديل ولم يُعلن قبول بصري.

## نتيجة التدقيق

كان `NotificationsScreen` يملك مسارًا صريحًا لكل من `AssalEmpty<List<AssalNotificationSummary>>` والقائمة الفارغة، ويعرض `AssalMessageCard` برسالة «لا توجد إشعارات جديدة الآن.» وزر «استكشف السوق» المرتبط بـ`HomeScreen` الحقيقي. كما يحافظ المسار على `getSession`، وبوابة الضيف، وretry للجلسة، وعمليات تعليم الإشعار المصدرية. لم تثبت المراجعة فجوة سلوكية جديدة تستحق تغيير الإنتاج؛ أضيف اختبار TASK 073 مستقل لتثبيت هذا العقد بدل إعادة البناء أو إضافة API.

## الاختبارات

```text
flutter test --no-pub test/task073_empty_notifications_test.dart
00:04 +1: All tests passed!

flutter analyze --no-pub
No issues found!

flutter test --no-pub test/task033_notifications_test.dart --plain-name 'TASK 033 renders source notifications and read action'
00:05 +1: All tests passed!

flutter test --no-pub test/task033_notifications_test.dart --plain-name 'TASK 033 keeps guest notifications behind the auth gate'
00:06 +1: All tests passed!

flutter test --no-pub test/task033_notifications_test.dart --plain-name 'TASK 033 retries an unavailable session source'
00:03 +1: All tests passed!
```

يثبت الاختبار الجديد مصدر `AssalEmpty` مع جلسة عميل مصادق عليها، وظهور الرسالة والإجراء، وعدم ظهور بوابة تسجيل الدخول. وتثبت regressions القائمة القراءة والتعليم وحدود الضيف وretry.

## القبول والحدود

القبول الوظيفي: **PASS**؛ لم تثبت فجوة سلوكية إنتاجية في مسار الإشعارات بعد الجرد. لا تغيير DB/API/RLS/permissions. القبول البصري: **BLOCKED** لفقدان PNG/Markdown TASK 073. لا يثبت هذا الاختبار دفعًا حيًا أو مزامنة إشعارات عبر أجهزة متعددة.
