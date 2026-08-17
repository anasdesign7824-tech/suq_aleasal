# Task 22 — Loading States

## Task Scope

توحيد حالات التحميل بصريًا داخل التطبيق باستخدام Glass Loading متحرك بدل الدوارات التقليدية، مع skeleton layout مفهوم وSemantics مناسب.

## Changes

تم تحسين `AssalGlassLoading` في `assal_widgets.dart`:

- الإبقاء على `BackdropFilter` والزجاج المتدرج وهوية عسلكم.
- الإبقاء على حركة اللمعان المتكررة عبر `AnimationController` و`ShaderMask`.
- إضافة `Semantics(liveRegion: true)` باستخدام label الحالة.
- تحويل skeleton الكبير إلى ثلاثة أشرطة متدرجة بدل شريطين فقط.
- إبقاء الوضع المصغر للارتفاعات الصغيرة في صورة صف مختصر.
- عدم إدخال `CircularProgressIndicator` في هذه الحالة.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/core/assal_widgets.dart` | Glass Loading وskeleton وSemantics |
| `docs/evidence/task_22_loading_states_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

## Runtime Verification

`AssalFutureStateView` و`AssalStateView` يستدعيان `AssalGlassLoading` في حالة عدم اكتمال البيانات أو `AssalLoading`. لذلك تنتقل الشاشات إلى حالة موحدة بدل spinner خاص بكل شاشة.

## Visual Verification

التحميل يظهر كبطاقة زجاجية ذات حدود وظلال ولمعان متحرك، مع أيقونة hive ونص الحالة وثلاثة skeleton bars في الارتفاعات الكبيرة.

## Accessibility Verification

تمت إضافة live region label ليتمكن قارئ الشاشة من معرفة أن المحتوى في حالة تحميل.

## Regression Verification

نجحت اختبارات التنقل وطبقة البيانات ورحلة العميل. تم إصلاح ثلاثة lint hints بإضافة `const` إلى skeleton bars.

## Remaining Issues

ما زالت بعض الواجهات التي تبني رسائلها مباشرةً تستخدم `AssalMessageCard` عند الخطأ؛ هذا مقصود لأن Task 22 يركز على loading لا error state.

## Final Gate

**PASS** — حالات التحميل الزجاجية متحركة وموحدة ومفهومة بصريًا وسمعيًا دون Spinner تقليدي.
