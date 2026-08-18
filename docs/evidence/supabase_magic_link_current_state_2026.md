# الحالة الفعلية لقالب Magic Link / OTP في Supabase

**تاريخ الفحص:** 17 أغسطس 2026

تم فتح لوحة Supabase للمشروع `gvalqfgxrkibuydoiuiz` عبر المسار:

`Authentication → Emails → Magic link or OTP`

كانت الحالة الفعلية قبل الإصلاح:

- **Subject:** `من فضلك قم بتاكيد حسابك ثم اذهب للتطبيق وأعد المحاولة مرة اخرى`
- **Body Source:** القالب الافتراضي الإنجليزي الذي يحتوي على:

```html
<h2>Your sign-in link</h2>
<p>Follow the link below to sign in. This link expires shortly and can only be used once.</p>
<p><a href="{{ .ConfirmationURL }}">Sign in</a></p>
```

النتيجة: هذا يثبت أن سبب وصول رابط تسجيل الدخول ورسالة التأكيد القديمة هو أن قالب Magic link or OTP لم يكن قد حُفظ عليه قالب OTP العربي، رغم حفظ قالب Confirm signup سابقًا.

الإجراء المطلوب: استبدال Subject بقيمة عربية لرمز الدخول، واستبدال Body Source بالقالب الموجود في `docs/evidence/final_magic_link_otp_template_ar.html`، مع بقاء `{{ .Token }}` فقط وعدم وجود `{{ .ConfirmationURL }}` أو زر رابط، ثم الضغط على Save changes وإعادة تحميل الصفحة للتأكد من الثبات.
