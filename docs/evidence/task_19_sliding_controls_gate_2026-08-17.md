# Task 19 — Slider / Sliding Controls

## Task Scope

استبدال إدخال السعر والتقييم الحر بعناصر تحكم مناسبة للبيانات الكمية، مع حدود مشتقة من Product Model وعدم استخدام أرقام عشوائية أو ثابتة بلا مصدر.

## Changes

تمت إضافة حدود ديناميكية داخل SearchScreen:

- `dataMinPrice` و`dataMaxPrice` من الأسعار الموجودة في نتائج المنتجات.
- `dataMaxRating` من التقييمات الموجودة، مع سقف منطقي ابتدائي 5.
- `RangeSlider` لاختيار حدّي السعر.
- `Slider` لاختيار الحد الأدنى للتقييم.
- إلغاء تمرير القيم القصوى إلى query عند بقاء RangeSlider على كامل النطاق.
- استمرار `AssalProductQuery.minPrice/maxPrice/minRating` كعقد النقل.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/features/customer/customer_discovery.dart` | حدود ديناميكية وRangeSlider/Slider داخل filter sheet |
| `docs/evidence/task_19_sliding_controls_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

## Runtime Verification

عند فتح الفلاتر تُعرض حدود السعر بناءً على المنتجات التي وصلت من Repository. RangeSlider يحدّث الطرفين، وSlider يحدّث الحد الأدنى للتقييم، ثم يمرران القيم إلى query عند الضغط على «تطبيق الفلاتر».

## Visual Verification

يظهر نص نطاق السعر بالأرقام العربية/الرقمية المتاحة مع RangeSlider، ثم سطر الحد الأدنى للتقييم مع Slider. لا توجد ثلاثة حقول سعر متجاورة ضيقة على الشاشة.

## Architecture Verification

الحدود تُجمع من Product Model في Feature state، ولا تُختلق من backend أو من قائمة عشوائية. البحث الفعلي يبقى مسؤولية Repository.

## Data / Contract Verification

الحقول الرقمية هي `minPrice`, `maxPrice`, و`minRating` في `AssalProductQuery`، وتظل متوافقة مع Demo وProduction.

## Regression Verification

نجحت الاختبارات الخمسة. تم إصلاح خطأ lint واحد متعلقًا باسم توكن طباعة غير موجود، واستُخدم `AssalTypography.bodyLarge` الموجود فعليًا.

## Remaining Issues

إذا لم تتضمن نتائج المصدر أسعارًا أو تقييمات، يستخدم Slider نطاقًا آمنًا للعرض ولا يختلق نتائج؛ يمكن لاحقًا إضافة endpoint رسمي لـfacets لتحسين الدقة قبل تحميل المنتجات.

## Final Gate

**PASS** — تم تنفيذ Slider وRangeSlider بحدود مشتقة من البيانات وبعقد query موجود، مع نجاح التحليل والاختبارات.
