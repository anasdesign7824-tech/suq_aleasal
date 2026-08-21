# TASK 093 — Admin CSRF / Session / Cookie Evidence

## النتيجة

**PASS WITH DOCUMENTED LOCAL-ADMIN LIMITATION.** تم تدقيق Admin Web المحلي وإضافة دفاع same-origin صريح للطلبات غير الآمنة، مع إبقاء جلسة Supabase وصلاحيات `requireAdmin()` كما هي. أُعيد تشغيل `pnpm check` و`pnpm test -- --run` و`pnpm build` بنجاح بعد التعديل.

## ما ثبت قبل الإصلاح

تمت مراجعة `server/admin-auth.ts`, `server/index.ts`, `client/src/lib/admin-api.ts`, و`client/src/components/AdminAuthGate.tsx`. كانت المسارات التشغيلية محمية بـ`requireAdmin()`، والطلبات بلا جلسة الصحيحة تعيد `401`. كانت الكوكيز تحتوي `HttpOnly`, `SameSite=Lax`, و`Path=/`، وكان `Secure` يُفعّل فقط عند `ASSALKOM_ADMIN_HTTPS=true`. لم يكن هناك فحص صريح لـ`Origin` أو`Referer` على state-changing requests؛ وكانت الحماية من CSRF تعتمد على SameSite فقط.

اختبار HTTP baseline على server 3211 أثبت رفض العمليات بلا جلسة عند إرسال طلب بلا body: `overview=401`, `store_approve_no_body=401`, `password_no_body=401`, `delete_user_no_body=401`, و`notifications_no_body=401`. مسار logout أعاد `200` بلا جلسة، وهو سلوك مقصود لأنه عملية تنظيف cookies محلية لا تغيّر بيانات Supabase. حدثت استجابة `400` في محاولة أخرى بسبب JSON غير صالح أرسله PowerShell/curl، وسُجل سببها في server log ولم تُحسب كفشل مصادقة.

## الإصلاح

أُضيف `server/admin-csrf.ts`، ويطبق `requireSameOriginAdminMutation` على `/api/admin` قبل routes. تسمح القاعدة بـ`GET`, `HEAD`, و`OPTIONS`، وتتحقق للطلبات غير الآمنة من `Origin` أو أصل `Referer`. يُسمح تلقائيًا بأصل host المحلي الفعلي، ويمكن إضافة أصل Vite تطويري أو reverse proxy صريح عبر `ASSALKOM_ADMIN_ALLOWED_ORIGINS` مفصولًا بفواصل. إذا غابت أدلة المصدر، يُسمح فقط بعلامة المتصفح `Sec-Fetch-Site: same-origin`. الطلبات cross-origin أو بلا origin evidence تعيد `403 admin_csrf_rejected` قبل الوصول إلى handler أو Supabase.

لم تُغيّر migration أو Supabase Auth، ولم يُقبل أي session ID يرسله العميل. login يبني cookies من tokens التي يصدرها Supabase، وrefresh يعيد كتابة access/refresh cookies عند نجاح refresh؛ لذلك لا يوجد session identifier ثابت تقبله الواجهة قبل المصادقة. هذا مثبت أيضًا باختبارات cookie serialization التي تتحقق من overwrite tokens وflags.

## نتائج post-patch HTTP regression

| الحالة | النتيجة | الحكم |
|---|---:|---|
| `/api/health` GET | `200` | health endpoint يعمل. |
| `/api/admin/overview` GET بلا origin/cookie | `401` | رفض بلا جلسة محفوظ. |
| store approve POST مع `Origin: https://evil.example` | `403` | CSRF مرفوض قبل handler. |
| store approve POST مع `Origin: http://127.0.0.1:3212` بلا session | `401` | same-origin يمر إلى session guard، ولا يسمح بلا جلسة. |
| admin login POST مع origin خبيث | `403` | login CSRF مرفوض أيضًا. |
| admin login POST same-origin بلا body | `400` | وصل إلى login validation، لا إلى CSRF أو Supabase session. |
| logout POST مع origin خبيث | `403` | لا يمكن cross-origin إجبار logout. |
| logout POST same-origin | `200` | logout المحلي يعمل. |
| store approve POST مع `Sec-Fetch-Site: same-origin` بلا cookie | `401` | fallback المتصفح يمرر المصدر الصحيح فقط ثم يرفض بلا جلسة. |

## الاختبارات الآلية

| الاختبار | النتيجة |
|---|---|
| `pnpm check` | PASS. |
| `pnpm test -- --run` | PASS؛ 5 ملفات و37 اختبارًا ناجحًا، منها 6 CSRF و2 cookie-security. |
| `pnpm build` | PASS؛ bundle server/client بُني بنجاح. تحذير chunk الحجم السابق بقي informational ولم يمنع build. |
| Cookie flags في HTTP المحلي | `httpOnly=true`, `sameSite=lax`, `secure=false`, `path=/`. |
| Cookie flags عند HTTPS الصريح | `secure=true` مع بقية flags. |

## الحدود الموثقة

اللوحة مصممة محليًا على loopback؛ لذلك لا يوجد نشر عام أو reverse-proxy production يُدّعى اختباره. عند استخدام Vite dev أو proxy مختلف يجب ضبط `ASSALKOM_ADMIN_ALLOWED_ORIGINS` صراحة، ولا ينبغي تعطيل middleware. كما أن CSRF لا يبدّل نموذج صلاحيات Supabase؛ فالمسارات بلا جلسة بقيت مرفوضة بواسطة `requireAdmin()`، وCSRF أصبح طبقة إضافية قبلها.

## الملفات

| الملف | الغرض |
|---|---|
| `apps/admin_web/server/admin-csrf.ts` | same-origin mutation guard. |
| `apps/admin_web/server/admin-csrf.test.ts` | اختبارات Origins وsafe methods والمصدر المفقود. |
| `apps/admin_web/server/admin-security.test.ts` | اختبارات cookie flags وtoken overwrite. |
| `apps/admin_web/server/index.ts` | تركيب middleware قبل Admin routes. |
| `artifacts/task093_pre_security_inventory.md` | جرد الحالة قبل الإصلاح. |
| `docs/evidence/TASK_093_ADMIN_CSRF_SESSION_EVIDENCE.md` | هذا الدليل. |
