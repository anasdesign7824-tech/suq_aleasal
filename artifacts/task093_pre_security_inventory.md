# TASK 093 — Pre-fix Admin Security Inventory

## نطاق الملفات

تمت مراجعة `apps/admin_web/server/admin-auth.ts`, `apps/admin_web/server/index.ts`, `apps/admin_web/client/src/lib/admin-api.ts`, و`apps/admin_web/client/src/components/AdminAuthGate.tsx`.

## النتائج المثبتة من source review

| المجال | الحالة قبل الإصلاح | الدليل |
|---|---|---|
| رفض الطلبات الإدارية بلا جلسة | موجود عبر `requireAdmin()` في المسارات التشغيلية، بينما auth session/password routes تتحقق يدويًا من الجلسة. | `admin-auth.ts:216-237`, `index.ts:152-513`. |
| CSRF صريح | غير موجود؛ لا يوجد Origin/Referer enforcement أو CSRF token middleware. الحماية الحالية تعتمد على `SameSite=Lax` فقط. | `index.ts` قبل routes لا يحتوي mutation middleware. |
| Cookie flags | `httpOnly=true`, `sameSite=lax`, `path=/`, و`secure` مشروط بـ`ASSALKOM_ADMIN_HTTPS=true`. | `admin-auth.ts:71-85`. |
| Session fixation | login يبني session من Supabase ثم يكتب access/refresh cookies؛ refresh يعيد كتابة cookies عند نجاح refresh. لم يظهر قبول session ID من العميل أو تثبيت token خارجي. | `admin-auth.ts:154-185`, `193-213`. |
| Frontend credentials | جميع طلبات الإدارة تستخدم `credentials: same-origin`، وmutations تستخدم POST/PATCH/PUT/DELETE. | `client/src/lib/admin-api.ts:28-36`, `59-122`. |
| Client login sequence | الواجهة تفحص session أولًا ثم ترسل login عبر same-origin fetch. | `AdminAuthGate.tsx:18-35`, `71-81`. |

## قرار التدقيق

الحالة المثبتة ليست تجاوزًا مباشرًا للجلسة، لكنها نقص دفاع CSRF صريح على state-changing Admin Web requests. الإصلاح المحافظ المقترح هو same-origin Origin enforcement على `/api/admin` للطلبات غير الآمنة، مع السماح للمنفذين المحليين `localhost` و`127.0.0.1` وبOrigins إضافية صريحة عبر `ADMIN_ALLOWED_ORIGINS`. لن يتغير عقد الجلسة أو Supabase Auth أو صلاحيات `requireAdmin()`.
