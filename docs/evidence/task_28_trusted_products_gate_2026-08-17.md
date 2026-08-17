# Task 28 — «المنتجات اليمنية الموثوقة»

## Task Scope

عرض قسم مستقل للمنتجات القادمة من متاجر موثقة، مع ربطه بفلاتر البيانات الفعلية وعدم اختراع شارات ثقة غير مدعومة.

## Changes

تم تحديث Home ليعرض رفًا بعنوان «المنتجات اليمنية الموثوقة» ويستخدم:

- `verifiedProductsFuture` الموجود أصلًا في Home.
- `verifiedOnly: true` في `_ProductRail`.
- تنقل «عرض الكل» إلى SearchScreen مع `verifiedOnly: true`.
- إضافة `showVerifiedBadge` إلى ProductCard.
- عرض شارة «موثق» بأيقونة `Icons.verified` على بطاقات هذا الرف فقط.
- إضافة `verifiedOnly` إلى SearchScreen وتمريره إلى البحث عند التهيئة.

## Data Boundary

الفلتر يعتمد على `AssalProductQuery.verifiedStoresOnly` في طبقة البيانات، حيث يطابق منتجات المتاجر الموثقة في Demo وProduction. لم تُضف قائمة يدوية للمنتجات الموثوقة.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/core/assal_widgets.dart` | شارة موثق اختيارية في ProductCard |
| `apps/mobile_flutter/lib/features/customer/customer_discovery.dart` | رف موثوق، Search verifiedOnly، وتنقل مفلتر |
| `docs/evidence/task_28_trusted_products_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

## Runtime Verification

قسم Home يستدعي `verifiedProductsFuture`، وSearchScreen عند «عرض الكل» يبدأ بحالة `verifiedOnly = true` ثم يرسل الاستعلام الموثق عبر Repository.

## Visual Verification

بطاقات الرف الموثوق تعرض شارة خضراء «موثق» على صورة المنتج، بينما تبقى البطاقات العامة دون شارة.

## Contract Verification

لم يتغير Product Model أو Repository contract؛ تمت إضافة وسيط عرض/استعلام يستهلك الحقل الموجود في طبقة البيانات.

## Regression Verification

نجحت اختبارات التنقل وطبقة البيانات ورحلة العميل. لم يتغير مسار Auth أو OTP أو التحميل المؤجل.

## Final Gate

**PASS** — قسم المنتجات اليمنية الموثوقة أصبح مرتبطًا بمصدر توثيق فعلي، مع شارة واضحة وتنقل مفلتر.
