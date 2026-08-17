# خلاصة توثيق Supabase لمسار Passwordless Email OTP

**تاريخ الحفظ:** 17 أغسطس 2026

توضح وثائق Supabase الرسمية أن `signInWithOtp` يستخدم نفس تنفيذ Magic Link وEmail OTP، وأن الفرق بينهما في محتوى قالب البريد. إذا احتوى قالب Magic Link على `{{ .ConfirmationURL }}` فسيصل رابط تسجيل دخول. لإرسال رمز رقمي يجب تعديل قالب **Magic Link / OTP** ليحتوي `{{ .Token }}` بدل `{{ .ConfirmationURL }}`، ثم استدعاء `verifyOtp` بالبريد والرمز مع النوع `email`.

المسار الرسمي هو إرسال الطلب مع `shouldCreateUser: false` لمنع إنشاء مستخدم جديد تلقائيًا، ثم إدخال الرمز والتحقق منه عبر `verifyOtp({ email, token, type: 'email' })`. بعد نجاح التحقق تعود جلسة صالحة للتطبيق.

المصادر الرسمية:

1. https://supabase.com/docs/guides/auth/auth-email-passwordless — يشرح أن Email OTP وMagic Link يشتركان في التنفيذ، وأن تعديل قالب Magic Link إلى `{{ .Token }}` يحول الرسالة إلى OTP، ويحدد `shouldCreateUser: false` و`verifyOtp` بنوع `email`.
2. https://supabase.com/docs/guides/auth/auth-email-templates — يعرّف `{{ .ConfirmationURL }}` كرابط التأكيد و`{{ .Token }}` كرمز OTP، ويفصل قالب Confirm signup عن قالب Magic link or OTP.
3. https://supabase.com/docs/reference/javascript/auth-signinwithotp — مرجع `signInWithOtp` الرسمي.
4. https://supabase.com/docs/reference/javascript/auth-verifyotp — مرجع `verifyOtp` الرسمي.

الاستنتاج التشخيصي: ظهور رابط تسجيل الدخول أو رسالة «أكد حسابك ثم اذهب للتطبيق وأعد المحاولة» يعني أن قالب Magic Link/OTP في لوحة Supabase ما زال يستخدم `{{ .ConfirmationURL }}` أو أن الحساب الذي اختُبر غير مؤكد. حفظ قالب Confirm signup وحده لا يغيّر قالب Magic Link المستخدم عند تسجيل الدخول لحساب موجود.
