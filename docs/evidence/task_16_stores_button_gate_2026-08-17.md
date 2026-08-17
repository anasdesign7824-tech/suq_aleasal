# Task 16 — زر «المتاجر»

## Task Scope

توفير زر واضح ومباشر للوصول إلى قائمة المتاجر، مع ربطه بمسار واحد موثوق لا يفتح شاشة وهمية ولا يكرر منطق التنقل.

## Changes

تمت إضافة زر `FilledButton.icon` بعنوان «المتاجر» داخل منطقة اكتشاف Home، باستخدام أيقونة storefront، وربطه بـ`_openStores()` الذي يفتح `StoresScreen(repository: widget.repository)`.

كما أُعيد استخدام نفس handler في SectionHeader «متاجر موثوقة» بعد بدء التحميل المؤجل، بحيث لا توجد نسختان من منطق فتح StoresScreen.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/features/customer/customer_discovery.dart` | زر المتاجر وhandler موحد |
| `docs/evidence/task_16_stores_button_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

## Runtime Verification

الزر يستدعي Navigation إلى StoresScreen مع نفس Repository المحقون في Home، وتبقى بيانات المتاجر On Demand عبر `listStores()` داخل StoresScreen.

## Visual Verification

الزر ظاهر أسفل حقل البحث في Home بعرض كامل، وتظهر معه أيقونة متجر ونص عربي واضح. لا يعتمد ظهوره على اكتمال البيانات المؤجلة.

## Architecture Verification

المسار هو:

```text
Home «المتاجر» → _openStores() → StoresScreen → Repository.listStores()
```

لا توجد قراءة مباشرة من Supabase أو JSON داخل الزر.

## Regression Verification

نجحت اختبارات التنقل وطبقة البيانات ورحلة العميل، ولم يتغير Auth أو Categories أو الفلاتر أو المرجع الجغرافي.

## Remaining Issues

تحميل قائمة المتاجر نفسها يظل On Demand حسب Task 08؛ الزر لا يطلق طلب المتاجر قبل فتح الشاشة، وهذا مقصود لتجنب اتصالات startup غير اللازمة.

## Final Gate

**PASS** — زر «المتاجر» واضح، قابل للوصول، مرتبط بمسار حقيقي ومختبر، مع تحميل بيانات المتاجر عند الحاجة فقط.
