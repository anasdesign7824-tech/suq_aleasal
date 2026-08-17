# تقرير قبول إصدار Email-only لعسلكم

**التاريخ:** 17 أغسطس 2026

**آخر commit مدفوع:** قيد الدفع بعد تنفيذ Email OTP

## الحكم المختصر

تم تحويل مسار Android في المصدر الرسمي إلى **Email/Password فقط**. أزيلت أزرار Google وFacebook من AuthScreen، أزيلت dependency الخاصة بـ`google_sign_in`، أزيلت حقول Google/redirect من runtime config وbootstrap، وأصبح Google وFacebook يرجعان حالة مؤجلة فقط إذا استُدعيا برمجيًا من مسار داخلي قديم. لا يوجد في APK الجديد استدعاء OAuth أو deep-link `login-callback`.

تمت إضافة تجربة تسجيل محسّنة تشمل تأكيد كلمة المرور عند إنشاء الحساب، حدًا أدنى من 8 أحرف في واجهة APK، مؤشر قوة يلوّن مربع كلمة المرور نفسه بالأخضر عند الاكتمال وبالأحمر عند النقص، قبول الحروف الإنجليزية والأرقام الإنجليزية والرموز ASCII فقط، وإدخال Email OTP من 6 إلى 9 أرقام داخل التطبيق بعد التسجيل. كما بقي رابط «نسيت كلمة المرور؟» موصولًا بـ`resetPasswordForEmail`، وحذف الحساب من داخل Profile بعد تأكيد صريح. أضيفت migrations `0005_email_account_deletion` و`0006_revoke_anon_account_delete` إلى المصدر وطُبقتا على Supabase، ثم أضيفت وطُبقت migration `0007_harden_account_deletion_search_path` لتحصين `search_path` دون تعديل سجل migration تاريخي.

## نتائج التحقق

| الفحص | النتيجة |
|---|---:|
| `flutter analyze --no-pub` | PASS — لا توجد Issues |
| `flutter test --no-pub` | PASS — 8/8 |
| Email-only navigation assertion | PASS — حقلا Email/Password وReset موجودة، Google/Facebook غير موجودين |
| Flutter APK Release build | PASS — 82.8 MB — rebuilt with Email OTP |
| Flutter AAB Release build | PASS — 80.8 MB — rebuilt with Email OTP |
| Package | `com.assalkom.assalkom` |
| APK SHA-256 | `39e13f5292902f64f2f62dfa0430b3720b4cd4dffbdf1b04a2246ccc737baa08` |
| AAB SHA-256 | `d6371f96a9b6549629edaae53b13a46c97f50e6d370d4486792fd2b6bf289baf` |
| Social dependency scan | لا توجد `google_sign_in` أو `google_identity_services` في lockfile |
| OAuth/deep-link scan | لا توجد `signInWithOAuth` أو `login-callback`؛ manifest يحتوي launcher `MAIN` فقط للتطبيق، دون `VIEW`/`BROWSABLE` deep-link خارجي |
| Supabase delete RPC ACL | `security_definer=true`, `anon=false`, `authenticated=true` بعد migration 0007 |
| GitHub | سيُحدّث بعد دفع تنفيذ Email OTP |

فحص `aapt` النهائي أكد أن `com.assalkom.assalkom.MainActivity` هي launchable activity الوحيدة، وأن manifest لا يعلن `VIEW` أو `BROWSABLE` للتطبيق. ظهور marker عام لـ`android.intent.action.VIEW` داخل dex لا يساوي callback خارجيًا؛ مصدره مكتبات Android/Flutter العامة، وليس intent-filter في manifest.

## سبب الفشل الذي ظهر على Mimo والهاتف الحقيقي

كان عنوان Supabase صحيحًا ويستجيب من خارج التطبيق، لكن `AndroidManifest.xml` الأساسي لم يكن يعلن صلاحية `android.permission.INTERNET`؛ الصلاحية كانت موجودة في debug/profile فقط. لذلك كان إصدار release يمرر طلبات Supabase إلى طبقة الشبكة دون صلاحية Android، فتظهر رسالة `Failed host lookup` حتى على هاتف حقيقي. أضيفت الصلاحية الآن إلى manifest الأساسي، وتم التحقق بـ`aapt dump permissions` من وجودها داخل APK الجديد.

## إصلاحات Auth الأخيرة

أصبح `signUp` يمرر `emailRedirectTo` من عنوان Supabase HTTPS الإنتاجي، وأضيفت طبقة `verifyEmailConfirmation` التي تستقبل رمزًا من 6 إلى 9 أرقام وتستدعي `verifyOTP` بنوع `signup`، مع إعادة session إلى التطبيق بعد نجاح التحقق. أضيف زر «إعادة إرسال رمز التحقق» يظهر فقط أثناء حالة انتظار OTP. قالب Confirm signup محفوظ الآن باستخدام `{{ .Token }}` فقط، دون `{{ .ConfirmationURL }}` أو زر redirect، ويحتوي على رمز عسلكم العام عبر HTTPS. القالب النهائي موثق في `docs/evidence/final_confirm_signup_otp_template_ar.html`.

أضيف مؤشر تفاعلي لقوة كلمة المرور أثناء الكتابة، مع تلوين مربع كلمة المرور نفسه، ومرشح إدخال يمنع الحروف العربية ويقبل الحروف الإنجليزية والأرقام الإنجليزية والرموز فقط. كما أزيلت رسائل Supabase الإنجليزية الخام، وأضيفت مزامنة Profile بعد الدخول وتسجيل الخروج وحذف الحساب دون `Navigator.pop` من جذر التطبيق. نافذة OTP إلزامية غير قابلة للإخفاء، وتُمسح حقول كلمة المرور فور انتقال التسجيل إلى التحقق حتى لا تظهر كلمة المرور مرة أخرى. واستُخدم التحميل الزجاجي المتحرك داخل زر التحقق بدل مؤشر الدوران التقليدي.

## ما تم على Supabase

أضيفت الوظيفة `public.delete_my_account()` بصلاحية `security definer`، وتتحقق من `auth.uid()` قبل حذف صف المستخدم من `auth.users`. علاقات قاعدة البيانات الحالية تجعل صف `public.users` وملف `profiles` وسجلات المستخدم التابعة تُحذف وفق foreign keys ذات `ON DELETE CASCADE` أو `SET NULL` حسب الجدول. تم اكتشاف أن منح الوظيفة الأولي ترك `anon` بصلاحية تنفيذ صريحة، فتم تصحيح ذلك في migration 0006 ثم التحقق خارجيًا من أن `anon` لا يستطيع التنفيذ وأن `authenticated` فقط يستطيع التنفيذ.

## تنبيه Supabase الأمني المقبول والمحدود

يعرض Supabase Advisor تحذيرًا على `authenticated_security_definer_function_executable` لأن `delete_my_account()` دالة `SECURITY DEFINER` قابلة للتنفيذ من المستخدم المسجّل. هذا مقصود وظيفيًا؛ حذف صف `auth.users` يحتاج صلاحيات المالك، والدالة لا تقبل معرّف مستخدم من العميل بل تستخدم `auth.uid()` الحالي فقط، وتمنع `anon`، وتتحقق من عدم كون الهوية فارغة، وتستخدم `search_path` محصّنًا. لا يمكن تحويلها إلى `SECURITY INVOKER` مع الحفاظ على حذف الحساب من داخل التطبيق.

## ما يحتاج اختبارًا خارجيًا قبل النشر العام

إعداد `mailer_autoconfirm=false` يعني أن التسجيل الإنتاجي يعتمد على رسالة تأكيد البريد. الكود والقالب جاهزان لتدفق OTP، لكن يلزم اختبار صندوق بريد حقيقي من داخل APK بعد آخر حفظ للتأكد من وصول رمز جديد، ثم اختبار تسجيل الدخول، إعادة الإرسال، reset، وحذف الحساب على جهاز Android حقيقي أو Google Play Internal Testing. المرسل الإنتاجي هو `info.assalkom@gmail.com` باسم العرض `خدمة دعم تطبيق عسلكم`.

كما أن artifact الحالي مبني وموقّع بشهادة `Android Debug` داخل بيئة البناء الذاتية، وليس upload key خاصًا بـGoogle Play. لذلك يجب قبل النشر إنشاء keystore release خارج Git، بناء AAB به، تفعيل Play App Signing، ثم اختبار التسجيل وتأكيد البريد وإعادة تعيين كلمة المرور وحذف الحساب على Internal Testing أو جهاز Android حقيقي.

تم إبقاء Google وFacebook مفعّلين في إعدادات Supabase العامة كموفرين غير مستخدمين، لأن مسار Web مؤجل ولأن موصل الإدارة المتاح لا يقدم عملية آمنة لتعديل Auth provider settings. هذا لا يفتح أي زر أو OAuth من APK Email-only. إذا كان المطلوب تعطيلهما على مستوى مشروع Supabase نفسه، يجب إيقافهما من Authentication → Providers بعد التأكد أن ذلك لن يؤثر على Web المؤجل.

## الخطوات الخارجية النهائية

1. إعداد SMTP في Supabase، ثم اختبار إنشاء حساب جديد، وصول رسالة التأكيد، إعادة الإرسال، تسجيل الدخول بعد التأكيد، ورابط reset.
2. إعداد Privacy Policy ورابط خارجي لحذف الحساب، وإضافة رابط الحذف داخل التطبيق وPlay Console.
3. إنشاء upload keystore، حفظه خارج Git، تفعيل Play App Signing، وإعادة بناء AAB release به بدل شهادة Android Debug الحالية.
4. إجراء Internal/Closed Testing على Google Play بحساب اختبار قابل للمراجعة، ثم اختبار دورة Email الكاملة على artifact الذي سيصل للمستخدم.
5. إدخال محتوى إنتاجي فعلي؛ قاعدة البيانات ما زالت تحتاج stores/products/banners حقيقية قبل استقبال الجمهور.

## المراجع

[1]: https://supabase.com/docs/guides/auth/passwords "Supabase Password-based Auth"

[2]: https://support.google.com/googleplay/android-developer/answer/13327111?hl=en "Google Play Account Deletion Requirements"

[3]: https://developer.android.com/studio/publish/app-signing "Android App Signing"

[4]: https://support.google.com/googleplay/android-developer/answer/11926878?hl=en "Google Play Target API Requirements"
