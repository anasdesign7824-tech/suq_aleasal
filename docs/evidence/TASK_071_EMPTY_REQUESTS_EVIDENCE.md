# TASK 071 — دليل حالة فراغ الطلبات

## نطاق المهمة

تغطي المهمة قائمة «طلباتي» للعميل المصادق عليه عندما لا توجد طلبات، مع الحفاظ على مرشح الحالة، retry الحقيقي، وإجراء استكشاف المنتجات. يجب ألا تتحول حالة الضيف أو فشل الجلسة إلى فراغ مضلل.

## نتيجة جرد المصدر

المراجع `screens/071_state_empty_requests.png` و`explanations/071_state_empty_requests.md` غير موجودة في checkout الحالي؛ لم تُنشأ صورة أو عقد بديل ولم يُعلن قبول بصري.

## الفجوة والإصلاح

كان `RequestsScreen` يعالج `AssalData<List<AssalRequestSummary>>` الفارغة عبر `_RequestsEmptyState` المخصص، لكنه يمرر `AssalEmpty<List<AssalRequestSummary>>` المصدرية إلى `AssalStateView` العامة، ما يفقد مرشح الحالات وCTA «استكشف المنتجات». أضيف فرع صريح لـ`AssalEmpty` يعرض نفس الحالة المخصصة المستخدمة للقائمة الفارغة، مع retry مربوط بـ`listRequests(userId)` وCTA ينتقل إلى `SearchScreen` الحقيقي. بقيت بوابة الجلسة: الضيف يرى تسجيل الدخول، و`AssalSession.unavailable` يرى رسالة المزامنة وretry؛ لم تُضف بيانات أو API أو DB أو صلاحية.

## الاختبارات

```text
flutter test --no-pub test/task071_empty_requests_test.dart
00:03 +1: All tests passed!

flutter analyze --no-pub
No issues found!

flutter test --no-pub test/task024_customer_requests_test.dart --plain-name 'TASK 024 exposes empty guidance and real product exploration'
00:07 +1: All tests passed!

flutter test --no-pub test/task025_customer_request_detail_test.dart --plain-name 'TASK 025 renders source-backed request fields and messages'
00:04 +1: All tests passed!
```

يثبت اختبار TASK 071 تسجيل مستخدم Demo قبل فتح الشاشة، ثم ظهور «لا توجد طلبات تواصل بعد.» و«استكشف المنتجات» واختفاء بوابة تسجيل الدخول؛ وهذا يميز فراغ القائمة المصادق عليه عن حالة الضيف.

## القبول والحدود

القبول الوظيفي: **PASS**. لا تغيير DB/API/RLS/permissions. القبول البصري: **BLOCKED** لفقدان PNG/Markdown TASK 071. المراسلة والمزامنة عبر Production وأجهزة متعددة خارج إثبات هذه المهمة.
