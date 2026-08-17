# Task 24 — شعار عسلكم في الصفحة الرئيسية

## Task Scope

إظهار الأيقونة الداخلية في Header الصفحة الرئيسية دون كتابة اسم «عسلكم» كنص منفصل أو تكراره بجانب الأيقونة.

## Changes

تم تعديل `_Header` في HomeScreen لاستخدام:

```dart
const AssalBrandMark(showName: false)
```

وبذلك يستدعي التطبيق أصل العلامة المركزي نفسه، لكن يعرض الرسم الداخلي فقط.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/features/customer/customer_discovery.dart` | إزالة النص المكرر من Home Header |
| `docs/evidence/task_24_home_logo_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

## Runtime Verification

Home Header يستدعي `AssalBrandMark` مع `showName: false`، ولا توجد قيمة نصية مستقلة «عسلكم» في هذا الموضع.

## Visual Verification

الجهة المخصصة للعلامة في Header تعرض الأيقونة الداخلية فقط، بينما تبقى أزرار الإعدادات والإشعارات في الجهة المقابلة.

## Asset Verification

المكوّن يستدعي `AssalAssets.logoInternal` المركزي، وهو الأصل المعلن في pubspec والموجود في runtime؛ لم تتم إضافة نسخة مكررة أو asset جديد.

## Regression Verification

نجحت اختبارات التنقل وطبقة البيانات ورحلة العميل. لم يتغير نص الاكتشاف أو عناوين الأقسام أو مسار Auth.

## Remaining Issues

Task 25 سيطبق القاعدة نفسها على شاشة تسجيل الدخول، ولا يُعتبر هذا التعديل بديلًا عنه.

## Final Gate

**PASS** — الصفحة الرئيسية تعرض الأيقونة الداخلية وحدها دون اسم نصي مكرر.
