# Task 14 — جميع الاختيارات المرجعية تكون Dropdown / Selector

## Task Scope

منع إدخال القيم المرجعية الحساسة يدويًا عندما تكون متاحة من Product Model/JSON/Repository، وتحويل النوع والدرجة والأصل والمعالجة والتعبئة والتوفر إلى Selectors واضحة داخل فلاتر SearchScreen.

## Changes

تم تعديل SearchScreen ليجمع خيارات الفلاتر من `AssalProductSummary` التي تصل من Repository:

- `originOptions` من `originCountry`.
- `processingOptions` من `processingMethodAr`.
- `packagingOptions` من `packagingLabelAr`.
- `availabilityOptions` من `availability`.
- Product Type من enum/contract.
- Grade من grade levels المرجعية.

تم استبدال TextFields الخاصة ببلد/منطقة الأصل وطريقة المعالجة والتعبئة والتوفر بـ`DropdownButtonFormField<String>`، مع خيار «الكل». بقيت حقول السعر والتقييم رقمية لأنها قيم كمية وليست taxonomy ثابتة.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/features/customer/customer_discovery.dart` | dynamic reference options وDropdown selectors داخل filter sheet |
| `docs/evidence/task_14_reference_selectors_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

## Runtime Verification

تم تشغيل Navigation/Data/Customer journey tests بعد التعديل، وبقي فتح SearchScreen وتشغيل `_search` وتمرير `AssalProductQuery` سليمًا.

## Visual Verification

Bottom Sheet يعرض Selectors متتابعة مع خيار «الكل»، وتبقى Switch للمتاجر الموثقة وحقول min/max السعر والتقييم كعناصر مناسبة لنوع البيانات. لم يعد المستخدم مضطرًا لكتابة قيم مرجعية قد لا تطابق المصدر.

## Architecture Verification

الخيارات تُشتق من Product Model داخل Feature بعد وصول Repository state؛ لا توجد قراءة JSON مباشرة من Widget ولا قائمة تجارية مستقلة داخل الواجهة.

## Data / Contract Verification

عند اختيار قيمة، تُمرر إلى `AssalProductQuery` كما هي (`originCountry`, `processingMethod`, `packaging`, `availability`). لا يوجد mapping يدوي لأسماء الفئات خارج البيانات.

## Regression Verification

نجحت الاختبارات الخمسة ولم تتغير Auth/OTP أو Categories أو Product Model. القيم الفارغة تعني «الكل» ولا تضيف filter إلى query.

## Remaining Issues

الخيارات تظهر بعد وصول products state؛ إذا كان المصدر فارغًا فلن تُختلق خيارات، وسيظهر Empty State. توسيع Repository إلى endpoint مستقل للفلاتر المرجعية يمكن أن يحسن الأداء لاحقًا لكنه غير ضروري لإغلاق Selector gate الحالية.

## Final Gate

**PASS** — الاختيارات المرجعية الأساسية أصبحت Dropdown/Selector ديناميكية، مع إبقاء الحقول الكمية كمدخلات رقمية مناسبة.
