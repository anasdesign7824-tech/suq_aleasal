# TASK 069 — دليل حالة فراغ المنتجات

## النطاق

تغطي المهمة حالة عدم وجود منتجات في مسارات العميل، مع رسالة مفهومة وإجراء بديل حقيقي لا يترك المستخدم في طريق مسدود. جرى فحص صفحة البحث والمنتجات المختارة والرفوف، ومقارنة ذلك بحالات التفاصيل والكتالوج الموجودة مسبقًا.

## نتيجة جرد المصدر

المراجع المتوقعة `screens/069_state_empty_products.png` و`explanations/069_state_empty_products.md` غير موجودة في checkout الحالي، كما يثبت خط الأساس العام. لم تُنشأ صورة أو عقد بديل، ولم تُستخدم لقطة actual كمرجع قبول.

## الفجوة المثبتة والإصلاح

كان `AssalStateView` يعرض رسالة `AssalEmpty` أو القائمة الفارغة دون دعم CTA بديل؛ لذلك لم تستطع شاشة البحث تمييز فراغ المنتجات برسالة موجهة أو عرض إجراء مسح حقيقي. أضيفت معاملات اختيارية للمكوّن المشترك: `emptyActionLabel` و`onEmptyAction` و`emptyIcon`، كما أضيفت معاملات `actionLabel` و`onAction` إلى `AssalMessageCard`. يظهر زر الفعل فقط عندما يُمرر callback حقيقي.

استُخدمت هذه القدرة في `customer_discovery.dart` بحيث تعرض الصفحة الرئيسية والرفوف رسالة عربية مناسبة مع «استكشف المنتجات» المرتبط بالبحث، وتعرض شاشة البحث «لا توجد منتجات مطابقة. جرّب إزالة البحث أو الفلاتر.» مع «مسح البحث والفلاتر» الذي يستدعي `_clearFilters` ويعيد تحميل النتائج. لم تُضف بيانات منتجات أو endpoint أو صلاحية جديدة. بقي كتالوج التاجر وتفاصيل المنتجات يستخدمان مساراتهما المصدرية القائمة، بما فيها CTA إضافة المنتج أو العودة للمتاجر، دون تكرار منطق غير مطلوب.

## الاختبارات

```text
flutter test --no-pub test/task069_empty_products_test.dart
00:03 +2: All tests passed!

flutter analyze --no-pub
No issues found!

flutter test --no-pub test/task007_home_test.dart --plain-name 'TASK 007 renders the home discovery contract and CTA'
00:07 +1: All tests passed!

flutter test --no-pub test/task010_search_test.dart --plain-name 'TASK 010 renders search controls and real demo results'
00:04 +1: All tests passed!

flutter test --no-pub test/product_card_widget_test.dart
00:02 +1: All tests passed!
```

يتضمن الاختبار الجديد ثلاثة محاور قابلة للإثبات: تنفيذ callback الفعلي للزر في المكوّن المشترك، ظهور رسالة المنتجات الفارغة في Search مع إعادة التشغيل بعد مسح الفلاتر، وعدم اعتماد بيانات إنتاجية وهمية. اختبارات golden لـTASK 007 وTASK 010 بقيت محجوبة كما هي موثقة سابقًا ولم تُحدّث.

## القبول والحدود

القبول الوظيفي لحالة فراغ المنتجات وCTA: **PASS**. لا تغيير DB/API/RLS/permissions. القبول البصري: **BLOCKED** لفقدان PNG/Markdown TASK 069. لم تثبت هذه المهمة مزامنة إنتاجية أو قبولًا عبر جهاز خارجي.
