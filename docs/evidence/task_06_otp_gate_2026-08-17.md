# Task 06 — شاشة رمز التحقق OTP

## Task Scope

تحسين شاشة OTP لتكون Dialog إلزامية واضحة وآمنة: عنوان وتعليمات، بريد قابل للتعديل، حقول رقمية، auto-focus، paste عبر حقل النص، منع الإدخال غير الرقمي، حد 6–9 أرقام، إعادة إرسال مع countdown، انتهاء الانتظار، حالات الخطأ/النجاح/loading، منع الضغط المتكرر، Keyboard behavior وRTL مناسب.

## Existing State

كانت الشاشة Dialog غير قابلة للإغلاق وتعرض البريد كنص ثابت، وحقل OTP رقمي واحد بحد 9 أرقام، وزر إعادة إرسال بلا عدّاد. كانت حالات error/notice موجودة، لكن لم يكن تعديل البريد أو التحكم في فترة إعادة الإرسال ممثلًا بوضوح.

## Changes

تمت إعادة بناء `_showEmailOtpDialog` داخل `AuthScreen` مع الحفاظ على نفس Repository contracts:

- إضافة `Timer` وعدّاد 30 ثانية قبل إعادة الإرسال.
- تعطيل إعادة الإرسال أثناء العدّاد أو الطلب.
- إضافة حقل بريد قابل للتعديل داخل Dialog مع تحقق مبسط.
- تمرير البريد المعدل إلى `requestEmailOtp`/`resendEmailConfirmation` وعمليات التحقق.
- جعل OTP رقميًا فقط مع حد 6–9 أرقام و`TextDirection.ltr` وauto-focus؛ يدعم اللصق الطبيعي لحقل Flutter النصي.
- إضافة رسالة زمنية: «يمكنك طلب رمز جديد بعد …» ثم «يمكنك طلب رمز جديد الآن».
- إبقاء Dialog غير قابل للإغلاق أثناء المسار الإلزامي، وتعطيل الأزرار أثناء الطلب، وإظهار Glass Loading أثناء التحقق.
- جعل علامة Dialog icon-only من `AssalBrandMark` لمنع تكرار النص داخل نافذة OTP.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/features/customer/customer_account.dart` | إعادة بناء Dialog OTP وإضافة Timer وحقل البريد القابل للتعديل |
| `docs/evidence/task_06_otp_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

خلال الدورة الأولى ظهر lint واحد متعلقًا بـunnecessary string interpolation، وتم إصلاحه فورًا ثم إعادة تشغيل analyze والاختبارات بنجاح.

## Runtime Verification

اختبارات navigation/data/customer journey نجحت. المسار يستمر في طلب Email OTP والتحقق منه عبر Repository، ولا يُسمح بإغلاق Dialog أو الضغط المتكرر أثناء الطلب.

## Visual Verification

تمت مراجعة البنية المرئية: شعار داخلي صغير icon-only داخل Dialog، بريد قابل للتعديل، رمز مركزي، نص العدّاد، رسائل الخطأ/النجاح، وزرا إعادة الإرسال والتحقق. الأرقام تُعرض باتجاه LTR داخل الحقول مع بقاء الصفحة RTL.

## Architecture Verification

التغيير بقي داخل طبقة UI مع استدعاء نفس `AssalRepository.requestEmailOtp` و`verifyEmailOtp`/`verifyEmailConfirmation`. لم يُوضع Supabase داخل Dialog ولم تتغير Gateway أو العقود.

## Data / Contract Verification

لم يتغير طول الرمز المسموح في العقد؛ التطبيق يتحقق من 6–9 أرقام كما يطلب قالب البريد الحالي. إعادة الإرسال للحساب الموجود تستخدم Email OTP، وللتسجيل الجديد تستخدم resend signup، مع رسائل منفصلة واضحة.

## Regression Verification

نجحت اختبارات التنقل وطبقة البيانات ورحلة العميل. لم يتغير Demo OTP `123456` أو Email-only authentication. لا يوجد fake verification داخل Production.

## Remaining Issues

التحقق من البريد الحقيقي ومدة صلاحية الرمز يعتمد على إعداد Supabase/SMTP الخارجي، ولا يمكن إثباته من اختبارات Demo وحدها. كما أن OTP الحالي حقل واحد محسّن وليس ست خلايا مستقلة؛ يدعم paste وauto-focus ويمنع الأخطاء، وسيظل هذا الفرق مسجلًا إذا تطلبت الهوية لاحقًا multi-cell UI صريحًا.

## Final Gate

**PASS** — Dialog OTP أصبح إلزاميًا، قابلًا للتعديل، محكومًا بالعدّاد، واضح الحالات، ونجحت بوابة التحليل والاختبارات.
