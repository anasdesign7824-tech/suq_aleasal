# TASK 079 — دليل التعليق قيد المراجعة

## نطاق المهمة

تغطي المهمة نتيجة إرسال تعليق العميل: يظهر التعليق محليًا فور نجاح الحفظ، ويُوسم بوضوح بأنه قيد المراجعة بدل الادعاء بأنه ظاهر أو متزامن مع جميع المستخدمين قبل اعتماد المسار الخلفي.

## نتيجة جرد المصدر

المراجع `screens/079_state_comment_pending.png` و`explanations/079_state_comment_pending.md` غير موجودة في checkout الحالي، لذلك بقي القبول البصري محجوبًا ولم يُنشأ baseline بديل.

## الفجوة المثبتة والإصلاح

كان `CommentsSection` يضيف التعليق محليًا، لكنه يعرض عبارة «تم حفظ التعليق والمزامنة مع التاجر.»؛ وهذه العبارة تؤكد مزامنة لا يثبتها العقد الحالي ولا الاختبار المحلي. كما كانت رسالة SnackBar تقول إنه أُرسل للتاجر دون بيان حالة المراجعة.

استُبدلت الدلالة بعبارة «قيد المراجعة؛ سيظهر للآخرين بعد الاعتماد.» ورسالة حفظ صادقة «تم حفظ تعليقك؛ تتم مراجعته قبل ظهوره للآخرين.». بقي `createComment` و`listComments` ومسار الجلسة كما هي، ولم تُضف حالة moderation أو endpoint جديد لعدم وجود عقد مثبت لها. يظل التعليق ظاهرًا لصاحبه محليًا عبر `isLocal`، بينما لا يُدّعى ظهوره العام قبل الاعتماد.

## الاختبارات

```text
flutter analyze --no-pub
No issues found! (ran in 139.8s)

flutter test --no-pub test/task079_comment_pending_test.dart
00:09 +1: All tests passed!

flutter test --no-pub test/task016_product_detail_social_test.dart --plain-name 'TASK 016 submits a comment and keeps the local result visible'
00:12 +1: All tests passed!

flutter test --no-pub test/task097_social_accessibility_test.dart --plain-name 'comment composer disables duplicate submit and supports keyboard submit'
00:12 +1: All tests passed!
```

يثبت الاختبار المستقل إرسال تعليق بمسار authenticated حقيقي داخل المستودع الاختباري، ظهوره للمستخدم، وظهور pending copy وSnackBar الجديدين. وتثبت regressions أن منع الإرسال المكرر والإرسال من لوحة المفاتيح ما زالا يعملان.

## القبول والحدود

القبول الوظيفي لدلالة pending والظهور المحلي: **PASS**. القبول البصري: **BLOCKED** لفقدان PNG/Markdown TASK 079. لا يثبت ذلك اعتمادًا حقيقيًا من الإدارة أو مزامنة مستخدمين متعددين أو كتابة Production حيّة؛ لا تغيير DB/API/RLS/permissions.
