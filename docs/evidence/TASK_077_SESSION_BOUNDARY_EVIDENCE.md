# TASK 077 — دليل حدود الجلسة وانتهائها

## نطاق المهمة

تغطي المهمة عدم خلط فشل مزامنة الجلسة بالضيف المقصود، وإظهار حالة قابلة لإعادة المحاولة، مع تحديد ما يثبته العقد الحالي بشأن انتهاء الجلسة.

## نتيجة جرد المصدر

المراجع `screens/077_state_session_expired.png` و`explanations/077_state_session_expired.md` غير موجودة في checkout الحالي. كما أن عقد `AssalSession` الحالي يعرّف `guest` و`unavailable` فقط، ولا يعرّف حالة أو code مستقلًا باسم `expired`. لم تُنشأ صورة أو عقد بديل ولم يُخترع enum جديد.

## الإصلاح والاختبار

لم يثبت الجرد حاجة إلى تعديل إنتاجي إضافي بعد تحصين `ProductionRepository` في TASK 076. أضيف اختبار TASK 077 يمرر جلسة `AssalSession.unavailable` إلى `FavoritesScreen`، ويتحقق من ظهور «تعذر مزامنة جلسة الحساب. حاول مرة أخرى.» وزر «إعادة المحاولة» وعدم ظهور بوابة تسجيل الدخول. بعد retry يعيد المستودع جلسة مصادقًا عليها وتظهر حالة المحفوظات الفارغة؛ بذلك يثبت الفصل بين unavailable والضيف والتعافي الحقيقي من المسار نفسه.

## الاختبارات

```text
flutter analyze --no-pub
No issues found!

flutter test --no-pub test/task077_session_boundary_test.dart
00:04 +1: All tests passed!

flutter test --no-pub test/data_layer_test.dart --plain-name 'Unavailable session is distinct from an intentional guest session'
00:02 +1: All tests passed!

flutter test --no-pub test/task029_saved_items_test.dart --plain-name 'TASK 029 gates favorites behind the real session'
00:03 +1: All tests passed!
```

## القبول والحدود

القبول الوظيفي لحدود `unavailable` والضيف وretry: **PASS**. القبول الصريح لسيناريو «انتهاء الجلسة» غير ممكن من العقد الحالي لغياب حالة expired، لذلك يبقى هذا الجزء **BLOCKED/غير معرّف تعاقديًا** ولا يُدّعى إنجازه. القبول البصري: **BLOCKED** لفقدان PNG/Markdown TASK 077. لا يثبت الاختبار refresh token أو OTP حيًا أو أجهزة متعددة، ولا يغير DB/API/RLS/permissions.
