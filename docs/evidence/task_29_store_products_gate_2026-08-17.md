# Task 29 — المتاجر + المنتجات

## Task Scope

ضمان أن فتح المتجر يقود إلى ملف المتجر الفعلي، وأن منتجاته تُجلب من Repository داخل StoreProfile بدل عرض متجر منفصل أو بيانات ثابتة.

## Changes

تم الحفاظ على مسار `StoreProfileScreen` الذي:

- يجلب `AssalStoreSummary` من `getStore(storeId)`.
- يجلب منتجات المتجر On Demand عبر `listProducts(query: AssalProductQuery(storeId: storeId))`.
- يعرض المنتجات في شبكة قابلة للنقر إلى `ProductDetailScreen`.
- يعرض Empty State عند عدم وجود منتجات.
- يعرض شارة «موثق» على بطاقات منتجات المتجر عندما يكون `store.isVerified == true`.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/features/customer/customer_catalog.dart` | تمرير حالة توثيق المتجر إلى بطاقات المنتجات داخل StoreProfile |
| `docs/evidence/task_29_store_products_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

## Data and Navigation Verification

من StoresScreen يستطيع المستخدم فتح StoreProfile بالمعرّف نفسه، ومن StoreProfile يستطيع فتح ProductDetail لكل منتج مرتبط بالمتجر. لا يوجد إنشاء لنموذج متجر بديل أو قائمة منتجات ثابتة داخل الواجهة.

## Visual Verification

المتجر الموثق ينعكس بصريًا على منتجاته من خلال شارة «موثق»، بينما المتجر غير الموثق يحتفظ بالعرض العام دون ادعاء توثيق.

## Regression Verification

نجحت اختبارات التنقل وطبقة البيانات ورحلة العميل، ولم يتغير Auth أو OTP أو الفلاتر أو التحميل المؤجل.

## Final Gate

**PASS** — مسار المتاجر والمنتجات متكامل من StoreCard إلى StoreProfile إلى ProductDetail، مع توثيق بصري مشروط بحالة المتجر الفعلية.
