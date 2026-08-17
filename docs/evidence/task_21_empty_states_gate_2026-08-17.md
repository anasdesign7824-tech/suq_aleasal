# Task 21 — Empty States

## Task Scope

منع ظهور القوائم الفارغة بلا تفسير، وتقديم رسالة عربية تعليمية مع إعادة المحاولة عندما يسمح المسار بذلك.

## Changes

تم تحسين `AssalStateView<T>` في `assal_widgets.dart`:

- إذا كانت `AssalData<T>` تحتوي Iterable فارغًا، تظهر بطاقة Empty State موحدة.
- الرسالة الافتراضية: «لا توجد نتائج متاحة الآن. جرّب تغيير الفلاتر أو البحث مرة أخرى.»
- `AssalEmpty` يمرر زر إعادة المحاولة عند توفر `onRetry`.
- `AssalError` يحافظ على زر إعادة المحاولة الموجود.
- لا تتغير عقود Repository أو طريقة تمثيل البيانات.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/core/assal_widgets.dart` | Empty State موحد للقوائم الفارغة |
| `docs/evidence/task_21_empty_states_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

## Runtime Verification

المسارات التي تستخدم `AssalStateView` لن تعرض Grid/List فارغة بصمت عندما تصلها `AssalData` فارغة، بل تستخدم البطاقة الموحدة. المسارات التي تحتاج رسالة أكثر تحديدًا ما زالت تستطيع إرسال `AssalEmpty(messageAr)` من Repository.

## Visual Verification

تظهر أيقونة inbox ورسالة عربية في بطاقة واضحة، ويظهر زر «إعادة المحاولة» إذا مرر المسار callback مناسبًا.

## Architecture Verification

التحسين مركزي في طبقة Widgets المشتركة، لذلك تستفيد منه Home وSearch وStores وواجهات الكتالوج دون تكرار الشروط.

## Regression Verification

نجحت اختبارات التنقل وطبقة البيانات ورحلة العميل، ولم تتغير مسارات Auth أو filters أو Product Model.

## Remaining Issues

لا تزال بعض الشاشات التي تبني `AssalMessageCard` مباشرةً برسالة مخصصة خارج `AssalStateView`; سيتم تدقيق تحسينات Loading وواجهة Header في المهام التالية دون إعادة تعريف Empty State.

## Final Gate

**PASS** — القوائم الفارغة أصبحت حالات مفهومة ومترجمة مع إعادة محاولة عند توفرها.
