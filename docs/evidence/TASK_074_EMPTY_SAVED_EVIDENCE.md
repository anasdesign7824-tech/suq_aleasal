# TASK 074 — دليل حالة فراغ المحفوظات

## نطاق المهمة

تغطي المهمة تبويبات المحفوظات والمتابعات والتصنيفات المرتبطة لدى العميل المصادق عليه، مع رسالة عربية مناسبة وإجراء حقيقي عندما تكون البيانات فارغة.

## نتيجة جرد المصدر

المراجع `screens/074_state_empty_saved.png` و`explanations/074_state_empty_saved.md` غير موجودة في checkout الحالي، كما يثبت خط الأساس العام. لم تُنشأ صورة أو عقد بديل ولم يُعلن قبول بصري.

## الفجوة والإصلاح

كان تبويبا المنتجات المحفوظة والمتاجر المتابَعة يملكان رسائل وإجراءات فارغة، بينما كان تبويب التصنيفات المرتبطة يستخدم `AssalStateView` العامة دون رسالة أو CTA مخصصين. أضيفت رسالة «لا توجد تصنيفات مرتبطة بالمحفوظات بعد. احفظ منتجًا لاقتراح تصنيفاته.» وزر «استكشف المنتجات» المرتبط بـ`_exploreProducts` و`SearchScreen` الحقيقي. بقيت `listFavoriteProducts` و`listFollowedStores` و`listFavoriteTaxonomies` المصدرية، وكذلك retry والإزالة وبوابة الجلسة، دون تغيير DB/API/RLS/permissions.

استُكملت stubs اختبار TASK 029 بعقود البحث التي يحتاجها المسار الفعلي (`listTaxonomy` و`listCategories` و`listPopularSearches`) وصُحح توقع النص إلى «ابحث عن منتج أو متجر» المطابق للمصدر. هذه تعديلات اختبارية فقط لاستعادة صلاحية regression، وليست بيانات إنتاجية.

## الاختبارات

```text
flutter test --no-pub test/task074_empty_saved_test.dart
00:03 +1: All tests passed!

flutter analyze --no-pub
No issues found!

flutter test --no-pub test/task029_saved_items_test.dart --plain-name 'TASK 029 shows empty guidance with real explore action'
00:04 +1: All tests passed!

flutter test --no-pub test/task030_following_test.dart --plain-name 'TASK 030 shows real discover-stores action when empty'
00:04 +1: All tests passed!
```

## القبول والحدود

القبول الوظيفي: **PASS**. القبول البصري: **BLOCKED** لفقدان PNG/Markdown TASK 074. لا يثبت هذا الاختبار مزامنة المحفوظات الحية أو القبول عبر أجهزة متعددة.
