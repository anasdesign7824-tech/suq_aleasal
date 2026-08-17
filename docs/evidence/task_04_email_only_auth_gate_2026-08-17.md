# Task 04 — تصحيح نظام تسجيل الدخول — مهم جدًا

## Task Scope

اعتماد المصادقة الحالية للبريد الإلكتروني ورمز التحقق فقط، وإبقاء Google وFacebook خارج نطاق واجهة العميل الحالية، دون إضافة OAuth UI أو تسجيل دخول خارجي في هذه الحزمة.

## Existing State

مسار الحساب الموجود يستخدم `requestEmailOtp` ثم `verifyEmailOtp`. بوابة Supabase تستدعي `signInWithOtp` مع `shouldCreateUser: false`، ثم `verifyOTP` بنوع `OtpType.email`. شاشة العميل لا تعرض أزرار Google أو Facebook. مسار إنشاء الحساب الجديد يحتفظ بالاسم والبريد وكلمة المرور ثم ينتقل إلى OTP/تأكيد البريد وفق القرار السابق، ولا يخلط ذلك مع Passwordless login للحساب الموجود.

## Changes

لم تُضف مزودات جديدة ولم تُعرض أزرار مؤجلة. تم تدقيق التنفيذ الموجود وتثبيت أن المسار الموحد المطلوب للحساب الموجود يمر عبر Email OTP الحقيقي خلف Repository/Gateway.

## Files Changed

أُضيف دليل Task 04 فقط. لم تُعدّل ملفات Auth أو UI في هذه المهمة لأن التنفيذ المعتمد موجود مسبقًا ونجح التدقيق.

## Tests

| الفحص | النتيجة |
|---|---|
| Provider UI scan داخل Features/App | PASS — لا Google/Facebook UI |
| `signInWithOtp(... shouldCreateUser: false)` | PASS |
| `verifyOTP(... type: OtpType.email)` | PASS |
| Contract/Production/Demo request/verify wiring | PASS |
| `flutter test test/data_layer_test.dart test/navigation_test.dart` | PASS — 4 tests passed |
| `git diff --check` بعد تنظيف أثر Flutter tooling | PASS |

## Runtime Verification

اختبارات طبقة البيانات والتنقل نجحت، وتؤكد أن شاشة الدخول الحالية تعرض مسار البريد فقط، بينما Demo يدعم الرمز `123456` للاختبار المحلي. لا توجد قفزة إلى متصفح أو OAuth في هذا المسار.

## Visual Verification

تم فحص واجهة العميل بحثًا عن Google/Facebook/Provider buttons، ولم توجد عناصر مرئية لها. مسار الدخول يعرض البريد وزر إرسال رمز الدخول، ومسار التسجيل الجديد يحتفظ بعناصره المطلوبة دون إظهار مزودي OAuth.

## Architecture Verification

المسار يظل:

```text
Auth UI → AssalRepository → ProductionRepository/DemoRepository → AssalAuthGateway/Supabase
```

لا توجد Supabase calls مباشرة من Widgets، ولا يوجد provider-specific UI داخل Customer shell.

## Data / Contract Verification

تمت مطابقة `AssalRepository.requestEmailOtp/verifyEmailOtp` مع `AssalAuthGateway` وProduction/Demo implementations. `shouldCreateUser: false` يمنع إنشاء حساب جديد من مسار دخول الحساب الموجود، و`OtpType.email` يثبت نوع التحقق الصحيح.

## Regression Verification

نجحت اختبارات data layer والتنقل، ولم تتأثر Demo-first أو شاشة العميل. Google وFacebook مسجلان كـDeferred وليس كـPASS، ولا يُسمح بإعادتهما إلى الواجهة ضمن هذه المهمة.

## Remaining Issues

مسار signup الإنتاجي ما زال يتطلب إعدادات البريد/التأكيد الخارجية الصحيحة عند اختبار Production، ولا تُثبت هذه المهمة صلاحية SMTP أو حساب Supabase حقيقيًا. هذا اعتماد خارجي منفصل، وليس سببًا لإعادة Google/Facebook.

## Final Gate

**PASS** — Email + Verification Code هو المسار المعتمد للحساب الموجود، ولا توجد واجهة Google/Facebook في العميل. أي إعداد Production غير متاح سيبقى `BLOCKED` موثقًا، لا نجاحًا وهميًا.
