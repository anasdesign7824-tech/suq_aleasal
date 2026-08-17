# Task 23 — Header / App Bar

## Task Scope

توحيد App Bar في الشاشات الرئيسية التي تستخدم عنوانًا مستقلًا، مع الحفاظ على هوية عسلكم ومكوّن علامة مركزي قابل لإعادة الاستخدام.

## Changes

تم إنشاء `AssalAppBar` في `assal_widgets.dart`:

- يقبل عنوانًا عربيًا وقائمة actions اختيارية.
- يعرض `AssalBrandMark(showName: false)` كعلامة مركزية صغيرة.
- يحافظ على `AppBar` القياسي في Material بدل إنشاء Header منفصل لكل شاشة.
- يدعم `showBrand` عند الحاجة إلى App Bar بدون علامة.
- استُخدم في SearchScreen وStoresScreen.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/core/assal_widgets.dart` | AssalAppBar reusable |
| `apps/mobile_flutter/lib/features/customer/customer_discovery.dart` | استخدام AssalAppBar في البحث والمتاجر |
| `docs/evidence/task_23_appbar_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

## Runtime Verification

Search وStores يمران عبر نفس مكوّن App Bar، مع بقاء navigation والـRepository كما هما.

## Visual Verification

تظهر العلامة الداخلية بدون النص المكرر بجانب عنوان الشاشة، وتبقى العناوين «البحث» و«المتاجر» واضحة.

## Architecture Verification

المسار المرئي مركزي:

```text
AssalBrandMark → AssalAppBar → SearchScreen / StoresScreen
```

ولا تُنسخ بنية العلامة داخل كل شاشة.

## Regression Verification

نجحت الاختبارات ولم يتغير Auth/OTP أو فلاتر المنتجات أو Stores filter logic.

## Remaining Issues

سيتم تدقيق تطبيق العلامة الداخلية وحدها في Home وAuthScreen كمهام مستقلة لاحقة (§25 و§26)، لذلك لا يُعتبر هذا البند بديلًا عنهما.

## Final Gate

**PASS** — App Bar موحد وقابل لإعادة الاستخدام، ويحافظ على الهوية دون تكرار النص داخل المكوّن.
