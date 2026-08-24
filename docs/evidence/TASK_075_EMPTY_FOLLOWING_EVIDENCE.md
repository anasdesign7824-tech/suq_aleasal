# TASK 075 — دليل حالة فراغ المتابعات

## نطاق المهمة

تغطي المهمة تبويب المتاجر المتابَعة لدى العميل المصادق عليه عندما لا توجد متابعات، مع رسالة عربية وإجراء حقيقي لاكتشاف المتاجر، وبقاء حالة الضيف خلف بوابة المحفوظات.

## نتيجة جرد المصدر

المراجع `screens/075_state_empty_following.png` و`explanations/075_state_empty_following.md` غير موجودة في checkout الحالي، كما يثبت خط الأساس العام. لم تُنشأ صورة أو عقد بديل ولم يُعلن قبول بصري.

## نتيجة التدقيق

كان `FavoritesScreen` يستخدم `_listState` المشترك لتبويب المتاجر المتابَعة، ويعالج `AssalEmpty` والقائمة الفارغة برسالة «لا تتابع متاجر بعد.» وزر «اكتشف المتاجر» المرتبط بـ`StoresScreen` الحقيقي عبر `_discoverStores`. كما بقيت إزالة المتابعة وretry وبوابة الجلسة مصدرية. لم تثبت المراجعة فجوة إنتاجية جديدة؛ أضيف اختبار TASK 075 لتثبيت هذا السلوك بدل إضافة مسار مكرر.

## الاختبارات

```text
flutter test --no-pub test/task075_empty_following_test.dart
00:04 +1: All tests passed!

flutter analyze --no-pub
No issues found!

flutter test --no-pub test/task030_following_test.dart --plain-name 'TASK 030 shows real discover-stores action when empty'
00:04 +1: All tests passed!

flutter test --no-pub test/task029_saved_items_test.dart --plain-name 'TASK 029 renders saved products and stores from source'
00:03 +1: All tests passed!
```

## القبول والحدود

القبول الوظيفي: **PASS**؛ لم تثبت فجوة سلوكية إنتاجية في مسار المتابعات بعد الجرد. القبول البصري: **BLOCKED** لفقدان PNG/Markdown TASK 075. لا يثبت هذا الاختبار مزامنة المتابعات الحية أو قبول أجهزة متعددة.
