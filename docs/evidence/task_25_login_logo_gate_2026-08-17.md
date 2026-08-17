# Task 25 — شعار شاشة تسجيل الدخول

## Task Scope

إظهار العلامة الداخلية في شاشة تسجيل الدخول دون نص «عسلكم» مكرر، ودون تكرار الأيقونة في App Bar والمحتوى معًا.

## Changes

تم تعديل AuthScreen إلى:

```dart
appBar: AssalAppBar(
  title: registerMode ? 'إنشاء حساب' : 'تسجيل الدخول',
  showBrand: false,
)
```

ويظل شعار المحتوى:

```dart
const AssalBrandMark(size: 92, showName: false)
```

وبذلك تظهر أيقونة داخلية واحدة في وسط شاشة المصادقة، بينما يبقى عنوان الشاشة مستقلًا وواضحًا في الشريط.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/features/customer/customer_account.dart` | استخدام AssalAppBar دون علامة وإبقاء AssalBrandMark الداخلي وحده |
| `docs/evidence/task_25_login_logo_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

## Runtime Verification

AuthScreen لا يعرض علامة في App Bar، ويعرض العلامة الداخلية المركزية من `AssalAssets.logoInternal` داخل body فقط. مسار Email OTP وتسجيل الحساب لم يتغير.

## Visual Verification

يظهر عنوان «تسجيل الدخول» أو «إنشاء حساب» في App Bar، وتظهر الأيقونة الداخلية الكبيرة في الوسط دون اسم نصي مكرر.

## Asset Verification

يُستخدم `AssalBrandMark` المركزي نفسه، بلا asset إضافي أو نسخة SVG مكررة.

## Regression Verification

نجحت اختبارات التنقل وطبقة البيانات ورحلة العميل، ولم يتغير مسار OTP أو كلمة المرور أو زر التحويل بين الدخول والتسجيل.

## Remaining Issues

لم يتم بعد تنفيذ فحص بصري على جهاز Mimo لهذه التغييرات الجديدة؛ سيُجمع ذلك ضمن Full Integration Verification بعد إغلاق المهام الفردية.

## Final Gate

**PASS** — شاشة تسجيل الدخول تعرض الأيقونة الداخلية وحدها داخل المحتوى، مع AppBar موحد بلا تكرار بصري.
