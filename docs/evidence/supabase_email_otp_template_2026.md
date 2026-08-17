# قالب Email OTP لعسلكم في Supabase

## الإعداد المطلوب

في لوحة Supabase افتح **Authentication → Email Templates → Confirm signup**. احذف `{{ .ConfirmationURL }}` وأي رابط HTML للتأكيد، واستخدم `{{ .Token }}` داخل الرسالة.

## Subject

رمز التحقق من بريدك الإلكتروني — عسلكم

## Body

```html
<div dir="rtl" style="font-family:Arial,sans-serif;line-height:1.8;color:#3d2418">
  <h2>تأكيد بريدك الإلكتروني</h2>
  <p>مرحبًا بك في تطبيق عسلكم.</p>
  <p>استخدم رمز التحقق التالي داخل التطبيق لإكمال إنشاء حسابك:</p>
  <div style="margin:24px 0;padding:18px;text-align:center;background:#fff4d6;border:1px solid #f0c36a;border-radius:12px;font-size:32px;letter-spacing:8px;font-weight:700;color:#9c5a00">
    {{ .Token }}
  </div>
  <p>صلاحية الرمز محدودة. لا تشارك هذا الرمز مع أي شخص.</p>
  <p>إذا لم تطلب إنشاء الحساب، فتجاهل هذه الرسالة.</p>
  <p>خدمة دعم تطبيق عسلكم</p>
</div>
```

## ضوابط مهمة

يجب ألا يحتوي قالب Confirm signup على `{{ .ConfirmationURL }}` أو أي زر `<a href=...>`؛ التطبيق هو الذي يستقبل الرمز ويستدعي `verifyOTP` من داخله. اترك قالب Reset password منفصلًا حتى يواصل استخدام رابط/آلية reset الحالية، ما لم يُنفّذ مسار OTP مستقل لإعادة تعيين كلمة المرور.

بعد الحفظ، أنشئ حساب اختبار جديد أو اضغط «إعادة إرسال رمز التحقق». استخدم أحدث رمز مرة واحدة فقط. إذا وصل بريد يحتوي رابطًا بدل الرمز، فهذا يعني أن القالب المحفوظ ليس قالب **Confirm signup** الصحيح أو أن رسالة قديمة استُخدمت.
