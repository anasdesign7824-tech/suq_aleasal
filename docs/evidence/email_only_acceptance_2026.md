# تقرير قبول إصدار Email-only لعسلكم

**التاريخ:** 17 أغسطس 2026

**آخر commit مدفوع:** `f382ad1 feat: add passwordless email otp sign in`

## الحكم المختصر

تم تحويل مسار Android في المصدر الرسمي إلى **Passwordless Email OTP لتسجيل الدخول**، مع كلمة مرور تُستخدم فقط عند إنشاء حساب جديد. أزيلت أزرار Google وFacebook من AuthScreen، أزيلت dependency الخاصة بـ`google_sign_in`، أزيلت حقول Google/redirect من runtime config وbootstrap، وأصبح Google وFacebook يرجعان حالة مؤجلة فقط إذا استُدعيا برمجيًا من مسار داخلي قديم. لا يوجد في APK الجديد استدعاء OAuth أو deep-link `login-callback`.

تمت إضافة تجربة تسجيل محسّنة تشمل اختيارًا واضحًا بين «تسجيل الدخول» و«إنشاء حساب». تسجيل الدخول لحساب موجود يعرض البريد الإلكتروني فقط ثم يرسل OTP من 6 إلى 9 أرقام، ولا يعرض كلمة المرور أو رابط reset. إنشاء الحساب فقط يعرض الاسم وكلمة المرور وتأكيدها، مع مؤشر قوة يلوّن مربع كلمة المرور نفسه ويقبل ASCII فقط، ثم ينتقل إلى OTP. كما بقي حذف الحساب من داخل Profile بعد تأكيد صريح. أضيفت migrations `0005_email_account_deletion` و`0006_revoke_anon_account_delete` إلى المصدر وطُبقتا على Supabase، ثم أضيفت وطُبقت migration `0007_harden_account_deletion_search_path` لتحصين `search_path` دون تعديل سجل migration تاريخي.

## نتائج التحقق

| الفحص | النتيجة |
|---|---:|
| `flutter analyze --no-pub` | PASS — لا توجد Issues |
| `flutter test --no-pub` | PASS — 9/9 |
| Passwordless navigation assertion | PASS — شاشة الدخول تحتوي حقل بريد واحدًا وزر OTP، دون كلمة مرور أو reset أو Google/Facebook |
| Flutter APK Release build | PASS — 82.8 MB — rebuilt with Passwordless Email OTP |
| Flutter AAB Release build | PASS — 80.8 MB — rebuilt with Passwordless Email OTP |
| Package | `com.assalkom.assalkom` |
| APK SHA-256 | `af1ff36cedd6ccdc5adb143d597dcf084e5442143b1691137a8ef9e6f9999fd8` |
| AAB SHA-256 | `aeb1f82f7256f24114c078738e2a06889e2a5c9d24b1c4de65fc660059ef3406` |
| Social dependency scan | لا توجد `google_sign_in` أو `google_identity_services` في lockfile |
| OAuth/deep-link scan | لا توجد `signInWithOAuth` أو `login-callback`؛ manifest يحتوي launcher `MAIN` فقط للتطبيق، دون `VIEW`/`BROWSABLE` deep-link خارجي |
| Supabase delete RPC ACL | `security_definer=true`, `anon=false`, `authenticated=true` بعد migration 0007 |
| GitHub | PASS — `f382ad1` مدفوع إلى `origin/main` |

فحص `aapt` النهائي أكد أن `com.assalkom.assalkom.MainActivity` هي launchable activity الوحيدة، وأن manifest لا يعلن `VIEW` أو `BROWSABLE` للتطبيق. ظهور marker عام لـ`android.intent.action.VIEW` داخل dex لا يساوي callback خارجيًا؛ مصدره مكتبات Android/Flutter العامة، وليس intent-filter في manifest.

## سبب الفشل الذي ظهر على Mimo والهاتف الحقيقي

كان عنوان Supabase صحيحًا ويستجيب من خارج التطبيق، لكن `AndroidManifest.xml` الأساسي لم يكن يعلن صلاحية `android.permission.INTERNET`؛ الصلاحية كانت موجودة في debug/profile فقط. لذلك كان إصدار release يمرر طلبات Supabase إلى طبقة الشبكة دون صلاحية Android، فتظهر رسالة `Failed host lookup` حتى على هاتف حقيقي. أضيفت الصلاحية الآن إلى manifest الأساسي، وتم التحقق بـ`aapt dump permissions` من وجودها داخل APK الجديد.

## إصلاحات Auth الأخيرة

أصبح `signUp` يمرر `emailRedirectTo` من عنوان Supabase HTTPS الإنتاجي، وأضيفت طبقة `verifyEmailConfirmation` التي تستقبل رمزًا من 6 إلى 9 أرقام وتستدعي `verifyOTP` بنوع `signup`، مع إعادة session إلى التطبيق بعد نجاح التحقق. وأضيف مسار `signInWithOtp` مع `shouldCreateUser=false` للحسابات الموجودة، ثم `verifyOTP` بنوع `email` لإعادة session دون كلمة مرور. قالبا Confirm signup وMagic Link/Email OTP موثقان باستخدام `{{ .Token }}` فقط، دون `{{ .ConfirmationURL }}` أو زر redirect.

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
