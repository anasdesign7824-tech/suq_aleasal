# تقرير قبول إصدار Email-only لعسلكم

**التاريخ:** 17 أغسطس 2026

**آخر commit مدفوع:** `96d4493 feat: ship email-only android auth flow`

## الحكم المختصر

تم تحويل مسار Android في المصدر الرسمي إلى **Email/Password فقط**. أزيلت أزرار Google وFacebook من AuthScreen، أزيلت dependency الخاصة بـ`google_sign_in`، أزيلت حقول Google/redirect من runtime config وbootstrap، وأصبح Google وFacebook يرجعان حالة مؤجلة فقط إذا استُدعيا برمجيًا من مسار داخلي قديم. لا يوجد في APK الجديد استدعاء OAuth أو deep-link `login-callback`.

تمت إضافة تجربة تسجيل محسّنة تشمل تأكيد كلمة المرور عند إنشاء الحساب، حدًا أدنى من 8 أحرف في واجهة APK، رسالة تأكيد البريد عند عدم وجود session، رابط «نسيت كلمة المرور؟» موصولًا بـ`resetPasswordForEmail`، وحذف الحساب من داخل Profile بعد تأكيد صريح. أضيفت migrations `0005_email_account_deletion` و`0006_revoke_anon_account_delete` إلى المصدر وطُبقتا على Supabase، ثم أضيفت وطُبقت migration `0007_harden_account_deletion_search_path` لتحصين `search_path` دون تعديل سجل migration تاريخي.

## نتائج التحقق

| الفحص | النتيجة |
|---|---:|
| `flutter analyze --no-pub` | PASS — لا توجد Issues |
| `flutter test --no-pub` | PASS — 8/8 |
| Email-only navigation assertion | PASS — حقلا Email/Password وReset موجودة، Google/Facebook غير موجودين |
| Flutter APK Release build | PASS — 82.5 MB |
| Flutter AAB Release build | PASS — 80.6 MB |
| Package | `com.assalkom.assalkom` |
| APK SHA-256 | `5a093bbd82faf7ac5018e91961cdf0ff971f05db39e74261e61fc3611430f680` |
| AAB SHA-256 | `2a081658d29cfccd634e1b7c2a74772c35a17a8c060b35cc55ce8bcd32c7cf35` |
| Social dependency scan | لا توجد `google_sign_in` أو `google_identity_services` في lockfile |
| OAuth/deep-link scan | لا توجد `signInWithOAuth` أو `login-callback` في client source أو dex scan |
| Supabase delete RPC ACL | `security_definer=true`, `anon=false`, `authenticated=true` بعد migration 0007 |
| GitHub | `origin/main` عند `96d4493` قبل commit hardening التوثيقي التالي |

## ما تم على Supabase

أضيفت الوظيفة `public.delete_my_account()` بصلاحية `security definer`، وتتحقق من `auth.uid()` قبل حذف صف المستخدم من `auth.users`. علاقات قاعدة البيانات الحالية تجعل صف `public.users` وملف `profiles` وسجلات المستخدم التابعة تُحذف وفق foreign keys ذات `ON DELETE CASCADE` أو `SET NULL` حسب الجدول. تم اكتشاف أن منح الوظيفة الأولي ترك `anon` بصلاحية تنفيذ صريحة، فتم تصحيح ذلك في migration 0006 ثم التحقق خارجيًا من أن `anon` لا يستطيع التنفيذ وأن `authenticated` فقط يستطيع التنفيذ.

## تنبيه Supabase الأمني المقبول والمحدود

يعرض Supabase Advisor تحذيرًا على `authenticated_security_definer_function_executable` لأن `delete_my_account()` دالة `SECURITY DEFINER` قابلة للتنفيذ من المستخدم المسجّل. هذا مقصود وظيفيًا؛ حذف صف `auth.users` يحتاج صلاحيات المالك، والدالة لا تقبل معرّف مستخدم من العميل بل تستخدم `auth.uid()` الحالي فقط، وتمنع `anon`، وتتحقق من عدم كون الهوية فارغة، وتستخدم `search_path` محصّنًا. لا يمكن تحويلها إلى `SECURITY INVOKER` مع الحفاظ على حذف الحساب من داخل التطبيق.

## ما لم أعتبره مكتملًا دون دليل خارجي

إعداد `mailer_autoconfirm=false` ما زال يعني أن التسجيل الإنتاجي يعتمد على رسالة تأكيد البريد. الكود يتعامل مع هذا الوضع ويعرض رسالة صحيحة بدل فتح session وهمية، لكن نجاح التسليم الفعلي للبريد يحتاج SMTP إنتاجيًا واختبارًا بصندوق بريد حقيقي. لا أستطيع اختراع SMTP credentials أو اعتبار endpoint العام لإعدادات Auth دليلًا على أن SMTP الإنتاجي يعمل.

كما أن artifact الحالي مبني وموقّع بشهادة `Android Debug` داخل بيئة البناء الذاتية، وليس upload key خاصًا بـGoogle Play. لذلك يجب قبل النشر إنشاء keystore release خارج Git، بناء AAB به، تفعيل Play App Signing، ثم اختبار التسجيل وتأكيد البريد وإعادة تعيين كلمة المرور وحذف الحساب على Internal Testing أو جهاز Android حقيقي.

تم إبقاء Google وFacebook مفعّلين في إعدادات Supabase العامة كموفرين غير مستخدمين، لأن مسار Web مؤجل ولأن موصل الإدارة المتاح لا يقدم عملية آمنة لتعديل Auth provider settings. هذا لا يفتح أي زر أو OAuth من APK Email-only. إذا كان المطلوب تعطيلهما على مستوى مشروع Supabase نفسه، يجب إيقافهما من Authentication → Providers بعد التأكد أن ذلك لن يؤثر على Web المؤجل.

## الخطوات الخارجية النهائية

1. إعداد SMTP في Supabase، ثم اختبار إنشاء حساب جديد، وصول رسالة التأكيد، إعادة الإرسال، تسجيل الدخول بعد التأكيد، ورابط reset.
2. إعداد Privacy Policy ورابط خارجي لحذف الحساب، وإضافة رابط الحذف داخل التطبيق وPlay Console.
3. إنشاء upload keystore، حفظه خارج Git، تفعيل Play App Signing، وبناء AAB release غير موقّع بشهادة Debug.
4. إجراء Internal/Closed Testing على Google Play بحساب اختبار قابل للمراجعة، ثم اختبار دورة Email الكاملة على artifact الذي سيصل للمستخدم.
5. إدخال محتوى إنتاجي فعلي؛ قاعدة البيانات ما زالت تحتاج stores/products/banners حقيقية قبل استقبال الجمهور.

## المراجع

[1]: https://supabase.com/docs/guides/auth/passwords "Supabase Password-based Auth"

[2]: https://support.google.com/googleplay/android-developer/answer/13327111?hl=en "Google Play Account Deletion Requirements"

[3]: https://developer.android.com/studio/publish/app-signing "Android App Signing"

[4]: https://support.google.com/googleplay/android-developer/answer/11926878?hl=en "Google Play Target API Requirements"
