# Task 05 — تجربة تسجيل الدخول المعتمدة

## Task Scope

تقديم شاشة بريد نهائية واضحة للحساب الموجود: شعار عسلكم في المنتصف، بريد إلكتروني، زر إرسال رمز التحقق، تعليمات مفهومة، وحالات Loading/Error/Success دون عبارة غامضة أو مسار OAuth.

## Existing State

كانت شاشة `AuthScreen` تستخدم `AssalBrandMark(size: 66)` مع الإعداد الافتراضي `showName: true`، ما يعرض الشعار والنص في صف واحد وقد يضعف التوازن البصري في شاشة الدخول. كانت رحلة OTP والإشعارات النصية موجودة.

## Changes

تم تعديل شاشة Auth الرئيسية لتعرض مكوّن العلامة المركزي بالشعار الداخلي فقط:

```dart
const Center(
  child: AssalBrandMark(size: 92, showName: false),
)
```

بقيت تعليمات الدخول واضحة: «أدخل بريدك الإلكتروني فقط، وسنرسل لك رمز دخول آمنًا»، وبقي زر «إرسال رمز الدخول» وحالات loading/error والانتقال إلى Dialog OTP دون تغيير عقد المصادقة.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/features/customer/customer_account.dart` | تكبير الشعار الداخلي ووضعه في المنتصف وإخفاء النص المكرر على شاشة البريد |
| `docs/evidence/task_05_login_experience_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart` | PASS — 4 tests passed |
| `git diff --check` | PASS |

## Runtime Verification

شغّل Flutter widget/navigation tests بعد التعديل. تؤكد اختبارات التنقل أن AuthScreen ما زالت تفتح من حساب الضيف، وتعرض TextField البريد وزر إرسال الرمز، ولا تعرض Password reset أو Google/Facebook UI. طبقة البيانات تؤكد بقاء Email OTP وDemo-first.

## Visual Verification

تم التحقق من الكود المرئي للشاشة: الشعار الداخلي runtime في مركز الشاشة وبلا نص «عسلكم» مكرر بجانبه، ثم يأتي العنوان والتعليمات الوظيفية. لم يتغير الثيم أو الخط أو RTL.

## Architecture Verification

التغيير Presentation-only، ويستمر المسار:

```text
AuthScreen → AssalRepository.requestEmailOtp → Production/Demo Repository
```

لم تنتقل أي صلاحية أو اتصال إلى Widget، ولم يتغير Repository أو Auth Gateway.

## Data / Contract Verification

لم تتغير عقود Email OTP أو Signup أو Session. الشعار يُستدعى من `AssalAssets` عبر `AssalBrandMark`، وليس من SVG مكرر داخل الشاشة.

## Regression Verification

نجح analyze والاختباران المستهدفان. لم تتأثر شاشة التسجيل الجديدة أو Dialog OTP أو Demo navigation. تغيير OTP Dialog إلى icon-only مسجل للبوابة المرئية الخاصة به لاحقًا ولا يُنسب إلى هذه المهمة.

## Remaining Issues

التحقق البصري على Mimo يتطلب إعادة بناء APK بعد استكمال مجموعة تحسينات الهوية اللاحقة؛ اختبارات Widget الحالية تثبت السلوك ولا تستبدل screenshot النهائي. كما أن OTP Dialog ما زال يستخدم العلامة الافتراضية حتى Task 06/25 وفق ترتيب البوابات.

## Final Gate

**PASS** — شاشة البريد الآن واضحة، والشعار الداخلي مركزي وغير مكرر نصيًا، مع نجاح التحليل والاختبارات وعدم تغيير عقد المصادقة.
