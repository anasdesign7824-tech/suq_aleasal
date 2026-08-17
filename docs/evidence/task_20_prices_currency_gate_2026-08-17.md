# Task 20 — الأسعار والعملات

## Task Scope

توحيد عرض السعر والعملة في واجهة المنتج، دعم العملة اليمنية بوضوح، ومنع ظهور فراغ عند غياب السعر.

## Changes

تمت إضافة `formatAssalPrice` في `assal_widgets.dart`:

- `YER` يظهر باسم «ريال يمني».
- `SAR` يظهر باسم «ريال سعودي».
- `USD` يظهر باسم «دولار أمريكي».
- الرموز غير المعروفة تُعرض كما وصلت من المصدر بدل إسقاطها.
- السعر المفقود يظهر «السعر عند الطلب» بدل اختفاء منطقة السعر.
- ProductCard يستخدم المنسق المركزي بدل تركيب النص داخل Widget.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/core/assal_widgets.dart` | منسق السعر واستبدال العرض المباشر |
| `docs/evidence/task_20_prices_currency_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

## Runtime Verification

ProductCard يستدعي `formatAssalPrice(product.price, product.currencyCode)` لكل منتج، لذلك لا يعتمد العرض على كون السعر موجودًا فقط ولا يسقط العملة عند وجودها.

## Visual Verification

يظهر السعر بجانب اسم العملة العربية الكاملة، مع نمط موحد، ويظهر «السعر عند الطلب» للمنتجات التي لا تحتوي قيمة سعرية.

## Architecture Verification

المنسق موجود في طبقة Widgets المشتركة، مما يمنع تكرار قواعد عرض العملة في كل بطاقة أو شاشة لاحقة.

## Data / Contract Verification

لم تتغير قيمة السعر أو currencyCode في العقد؛ التغيير تنسيقي في طبقة العرض فقط، ويحافظ على قيمة المصدر كما هي.

## Regression Verification

نجحت اختبارات التنقل وطبقة البيانات ورحلة العميل، ولم يحدث تعديل على Repository أو Product Model.

## Remaining Issues

إذا كانت العملة غير معروفة في المصدر، تظهر قيمة الرمز الخام. يمكن إضافة قاموس عملات أوسع عند اعتماد قائمة رسمية، دون تغيير Product Model.

## Final Gate

**PASS** — الأسعار والعملات تعرض بشكل موحد وواضح، مع fallback عربي للسعر المفقود وتحليل واختبارات ناجحة.
