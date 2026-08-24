# TASK 072 — دليل حالة فراغ الرسائل

## نطاق المهمة

تغطي المهمة فراغ قائمة المحادثات وفراغ سجل الرسائل داخل محادثة موجودة، مع إبقاء الإجراء البديل حقيقيًا، وعدم خلط حالة عميل مصادق عليه بحالة الضيف أو رسالة خطأ.

## نتيجة جرد المصدر

المراجع `screens/072_state_empty_messages.png` و`explanations/072_state_empty_messages.md` غير موجودة في checkout الحالي، كما يثبت خط الأساس العام. لم تُنشأ صورة أو عقد بديل ولم يُعلن قبول بصري.

## نتيجة التدقيق

كان `MessagesScreen` يملك بالفعل حالة فراغ مخصصة لقائمة المحادثات، وتشمل «لا توجد محادثات بعد.» وزر «استكشف المتاجر» المرتبط بـ`StoresScreen` الحقيقي، كما أن `ConversationScreen` يستخدم `AssalStateView` برسالة عربية مخصصة مع محرر الرسالة المتاح للمستخدم المصادق عليه. لم يثبت التدقيق فجوة إنتاجية تبرر إعادة بناء هذا المسار أو إضافة API جديد؛ لذلك اقتصر الإغلاق على اختبار regression مستقل يغطي الفراغين وحدود الجلسة. بقيت رسائل القائمة والرسائل داخل المحادثة مصدرية عبر `listConversations` و`listMessages`، وبقي الإرسال مربوطًا بـ`sendMessage` القائم.

## الاختبارات

```text
flutter test --no-pub test/task072_empty_messages_test.dart
00:03 +2: All tests passed!

flutter analyze --no-pub
No issues found!

flutter test --no-pub test/task026_messages_list_test.dart --plain-name 'TASK 026 shows empty guidance and explores real stores route'
00:15 +1: All tests passed!

flutter test --no-pub test/task026_messages_list_test.dart --plain-name 'TASK 026 renders source-backed conversation fields'
00:09 +1: All tests passed!
```

يستخدم الاختبار الجديد مستودعًا مصدرّيًا اختباريًا يعيد `AssalEmpty` لقائمة المحادثات وسجل الرسائل، ويسجل ظهور الإرشاد العربي، زر الاستكشاف، اسم المتجر، محرر الإرسال، وعدم ظهور رسالة تسجيل الدخول للإرسال عند وجود جلسة مصادق عليها.

## القبول والحدود

القبول الوظيفي: **PASS**؛ لم تكن هناك فجوة إنتاجية مثبتة في هذه المسارات بعد الجرد. لا تغيير DB/API/RLS/permissions. القبول البصري: **BLOCKED** لفقدان PNG/Markdown TASK 072. لا يثبت هذا الاختبار مزامنة الرسائل في Production أو عبر أجهزة متعددة.
