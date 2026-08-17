# Task 18 — تحسين نظام الفلاتر بالكامل

## Task Scope

تحسين تجربة الفلاتر بعد تنفيذ الفلترة الأساسية، عبر إدارة حالة واضحة، عداد للفلاتر النشطة، شرائح قابلة للحذف، وزر مركزي لمسح كل الفلاتر وإعادة النتائج إلى الوضع الافتراضي.

## Changes

تمت إضافة طبقة إدارة حالة داخل SearchScreen:

- `_activeFilterCount` يحسب الفلاتر النشطة بما فيها القسم والتصنيف والمحافظة والمديرية والنوع والدرجة والتوثيق والأصل والمعالجة والتعبئة والتوفر والنطاق السعري/التقييم والترتيب.
- زر الفلاتر يعرض العدد النشط بدل نص ثابت فقط.
- `InputChip` لكل قيمة نشطة مع حذف فردي وإعادة تشغيل البحث.
- زر «مسح الكل» يمسح query والقيم المرجعية والنطاقات الرقمية والترتيب دفعة واحدة.
- المحافظة والمديرية تُمسحان معًا عند حذف المحافظة للحفاظ على صحة التسلسل.
- جميع التغييرات تعيد استخدام `_search()` نفسه، فلا توجد مسارات query متباينة.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/features/customer/customer_discovery.dart` | إدارة حالة الفلاتر والشرائح والمسح الكلي |
| `docs/evidence/task_18_filters_system_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

## Runtime Verification

عند حذف Chip فردي، تتغير الحالة ويعاد بناء `AssalProductQuery` ثم تُحدّث نتائج المنتجات والمتاجر. عند «مسح الكل» يعود الترتيب إلى featured ويُمسح النص وكل الاختيارات.

## Visual Verification

تظهر الشرائح أسفل شريط الفلاتر فقط عند وجود فلاتر نشطة، مع زر «مسح الكل». لا تزدحم الشاشة عند عدم وجود فلاتر.

## Architecture Verification

كل الفلاتر تمر عبر `AssalProductQuery` وRepository؛ لا توجد استعلامات مباشرة من Widget ولا نسخ query يدوية لكل زر.

## Data / Contract Verification

الفلاتر الجديدة تتوافق مع حقول `AssalProductQuery` الحالية، بما فيها `categoryId`, `subcategoryId`, `regionId`, `provinceId`, `gradeLevel`, `productType`, `originCountry`, `processingMethod`, `packaging`, `availability`, والنطاقات الرقمية.

## Regression Verification

نجحت اختبارات التنقل وطبقة البيانات ورحلة العميل، وتم إصلاح lint compile واحد أثناء التنفيذ متعلق بمتطلبات `FilterChip.onSelected` باستبداله بـ`InputChip` الأنسب لشرائح الحذف.

## Remaining Issues

لا تزال فلاتر StoresScreen مستقلة عن SearchScreen في هذه المرحلة؛ توحيدها في مكوّن مشترك يمكن أن يكون تحسينًا معماريًا لاحقًا، لكن السلوك الوظيفي ومسح الحالة مكتملان داخل SearchScreen.

## Final Gate

**PASS** — نظام الفلاتر أصبح قابلًا للفهم والإدارة والإزالة الفردية أو الجماعية، مع query موحد وفحوص ناجحة.
