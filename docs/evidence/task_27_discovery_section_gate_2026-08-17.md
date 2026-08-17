# Task 27 — قسم «اكتشف العسل من مصدره»

## Task Scope

تحويل المقدمة الرئيسية في Home إلى قسم اكتشاف واضح بصريًا، يشرح القيمة للمستخدم ويربطه مباشرةً بالبحث والمتاجر دون اختراع مصدر بيانات جديد.

## Changes

تم تحويل مقدمة Home إلى Card موحدة تحتوي على:

- أيقونة `Icons.hive_outlined` داخل حاوية بلون عسلي خفيف.
- عنوان «اكتشف العسل من مصدره».
- وصف يوضح تصفح المتاجر والمنتجات اليمنية الموثوقة والتواصل مع التاجر.
- حقل بحث read-only يفتح SearchScreen عند النقر.
- زر «استكشف المتاجر» يفتح StoresScreen عبر نفس handler الموجود.
- الحفاظ على hint البحث المرتبط بمنتجات العسل: سدر، سمر، شمع أو هدية.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/features/customer/customer_discovery.dart` | بطاقة اكتشاف جديدة داخل Home |
| `docs/evidence/task_27_discovery_section_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

## Runtime Verification

حقل البحث يستدعي `widget.onOpenSearch`، وزر المتاجر يستدعي `_openStores`; لا توجد مصفوفة منتجات أو متجر مكتوبة يدويًا داخل البطاقة.

## Visual Verification

القسم يظهر كـCard ذات تسلسل بصري واضح: أيقونة، عنوان، وصف، بحث، ثم CTA للمتاجر، مع الحفاظ على RTL ومسافات Design System.

## Data Boundary Verification

البطاقة لا تضيف بيانات تشغيلية جديدة؛ المنتجات والمتاجر والنتائج تُجلب من المسارات القائمة عبر Repository.

## Regression Verification

نجحت اختبارات التنقل وطبقة البيانات ورحلة العميل، ولم تتغير فلاتر Search أو مسار Auth أو التحميل المؤجل.

## Final Gate

**PASS** — قسم اكتشاف العسل واضح وقابل للاستخدام ويرتبط بالمسارات الفعلية للبحث والمتاجر.
