# Task 17 — فلترة المتاجر

## Task Scope

توفير فلترة عملية لقائمة المتاجر دون اتصالات جديدة لكل تغيير، مع بحث باسم المتجر/المنطقة، اختيار المحافظة، وخيار المتاجر الموثقة.

## Changes

تم تحويل `StoresScreen` إلى Stateful screen تحتفظ بقائمة المتاجر القادمة من `Repository.listStores()` ثم تطبق الفلاتر محليًا:

- بحث نصي باسم المتجر أو اسم المنطقة.
- Dropdown للمحافظة من `YemenLocationReference`.
- FilterChip للمتاجر الموثقة.
- Empty State عربي عند عدم وجود نتائج مطابقة.
- فتح Store Profile يستمر باستخدام نفس Repository ونفس store id.
- تحميل مرجع المحافظات داخل StoresScreen عند فتح الشاشة، وليس عند startup.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/features/customer/customer_discovery.dart` | Stateful StoresScreen وفلاترها |
| `docs/evidence/task_17_store_filter_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

## Runtime Verification

لا يطلق تغيير النص أو FilterChip طلبًا جديدًا؛ تتم إعادة تصفية القائمة التي وصلت من `listStores()`. المرجع الجغرافي يُحمّل عند فتح StoresScreen فقط.

## Visual Verification

تظهر خانة بحث أعلى القائمة، ثم Selector المحافظة وFilterChip «موثقة». عند عدم التطابق تظهر رسالة «لا توجد متاجر تطابق الفلاتر الحالية» بدل قائمة فارغة بلا تفسير.

## Architecture Verification

المسار هو:

```text
StoresScreen → Repository.listStores() → in-memory query filters → StoreCard → StoreProfileScreen
```

لا توجد بيانات متجر مكتوبة يدويًا داخل الشاشة.

## Data / Contract Verification

فلترة المحافظة تستخدم `store.regionId` مقابل كود مرجع المحافظة، وخيار التوثيق يستخدم `store.isVerified`. لا يتم الاعتماد على الاسم العربي كمعرف.

## Regression Verification

نجحت اختبارات التنقل وطبقة البيانات ورحلة العميل، ولم يتغير زر المتاجر المركزي أو فلاتر المنتجات أو Auth.

## Remaining Issues

Task 18 سيحسن نظام الفلاتر بصورة أوسع، مثل إدارة حالة الفلاتر، زر مسح الكل، وتوحيد filter chips؛ Task 17 يثبت الفلترة الأساسية فقط.

## Final Gate

**PASS** — قائمة المتاجر قابلة للبحث والفلترة بالمحافظة والتوثيق، مع Empty State واضح واختبارات ناجحة.
