# دليل TASK 048 — دخول الإدارة واكتشاف بوابة Admin

**التاريخ:** 23 أغسطس 2026

**النطاق:** تدقيق شاشة دخول لوحة الإدارة المحلية الخاصة ومسار اكتشاف الجلسة، دون دمجها مع تطبيق العميل أو التاجر، ودون تغيير قاعدة البيانات أو API أو RLS أو الصلاحيات.

## ملاحظة المصدر

فهرس ما قبل التغيير يربط TASK 048 بـ`AdminAuthGate.tsx` و`App.tsx` و`Home.tsx` و`admin-api.ts`، ويصف المرجع المكتبي بأبعاد 1600×1000. ملفا المصدر المشار إليهما في جدول التنفيذ، `screens/048_admin_login.png` و`explanations/048_admin_login.md`، غير موجودين في checkout الحالي أو في شجرة GitHub المتاحة للمستودع؛ لذلك لم تُنشأ صورة مرجعية بديلة ولم تُدَّع مطابقة golden. هذه فجوة في أصول التدقيق، وليست مبررًا لتخمين واجهة أو تغيير مسار قائم.

## الجرد والتنفيذ

تبدأ `App.tsx` بـ`ErrorBoundary` ثم `AdminAuthGate` قبل عرض `Home`. تتحقق `AdminAuthGate` من `/api/admin/auth/session`، وتعرض حالة تحقق عربية، ثم تنتقل إلى نموذج البريد وكلمة المرور عند غياب الجلسة، أو إلى حاجز تغيير كلمة المرور الإلزامي عند `requiresPasswordChange`، أو إلى محتوى الإدارة بعد نجاح الجلسة. يعتمد النموذج على `adminApi.login` الحقيقي، ويعرض الخطأ داخل `role=alert`، ويعطل الإرسال أثناء الطلب. يعتمد العميل على cookies same-origin ولا يكشف service role.

على الخادم، يتحقق `POST /api/admin/auth/login` من الحقول قبل استدعاء `signInAdmin`، ويحل العضوية النشطة في `admin_users` والدور من `admin_roles`، ثم يضع access/refresh cookies. يعيد `GET /api/admin/auth/session` جلسة محمّلة أو 401، ويعيد `POST /api/admin/auth/password` تغيير كلمة المرور فقط لجلسة مصادق عليها، بينما logout يمسح الكوكيز. الطلبات mutation محمية بـsame-origin CSRF، والمسارات اللاحقة محمية بـ`requireAdmin` والصلاحية المناسبة.

لم يتطلب الجرد تعديلًا في الإنتاج؛ سلوك login/session/password gate/logout كان موجودًا ومطابقًا لحدود الهوية الإدارية المستقلة، ولذلك اقتصر التنفيذ على التحقق والتوثيق. لم تُضف شاشة عميل أو OAuth أو ربطًا جديدًا.

## بوابات الإثبات

| البوابة | النتيجة |
|---|---|
| `pnpm test -- client/src/lib/admin-api.test.ts client/src/lib/ui-consistency.test.ts server/admin-auth.test.ts server/admin-csrf.test.ts server/admin-security.test.ts` | PASS — خمسة ملفات اختبار، 19 assertion موزعة على الحدود الحالية |
| `pnpm check` | PASS — `tsc --noEmit` |
| `pnpm build` | PASS — Vite وesbuild؛ تحذير chunk أكبر من 500 kB بقي تحذير أداء فقط |
| `GET /api/health` | 200، المصدر `supabase-production` من الخدمة المحلية |
| `GET /api/admin/auth/session` بلا cookies | 401، لا جلسة وهمية |
| `POST /api/admin/auth/login` body فارغ مع same-origin | 400، validation محلي قبل الاتصال |
| `POST /api/admin/auth/login` باعتماد غير صالح | 401، لم تُنشأ cookies |
| `POST /api/admin/auth/password` بلا cookies | 401 |
| `POST /api/admin/auth/logout` بلا cookies | 200، logout idempotent مع clear cookies |
| فتح `/` محليًا | 200، العنوان «عسلكم — لوحة الإدارة» و`#root` موجودان |

النتائج الخام محفوظة في `artifacts/task048_admin_login_result.json`. أُرسلت طلبات mutation في probe مع `Origin` و`Referer` same-origin؛ رفض CSRF قبل ذلك بـ403 كان متوقعًا من الحماية وليس فشلًا في login validation.

## الحدود والقرار

لم تُستخدم بيانات اعتماد المدير الحقيقية، ولم يُنفذ login إيجابي أو refresh إيجابي أو تغيير كلمة مرور حي، لذلك تبقى هذه الحالات `UNVERIFIED` إلى اختبار آمن بحساب يقدمه صاحب المشروع. وبسبب فقدان Markdown وPNG المصدرين لا توجد مقارنة بصرية قابلة لإعادة الإنتاج في هذه المهمة.

**قرار TASK 048:** PASS للمسارات المصدرية والحدود السلبية والبناء، مع **GAP أصول التدقيق** و**عدم تحقق جلسة Admin الحية**. لا تغيير DB/API/RLS/الصلاحيات، ولا يُعلن قبول بصري أو production readiness.
