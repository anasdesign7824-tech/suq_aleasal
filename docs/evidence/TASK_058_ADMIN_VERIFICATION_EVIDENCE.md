# دليل TASK 058 — توثيق المتاجر Pro في لوحة الإدارة

**التاريخ:** 23 أغسطس 2026

**النطاق:** مراجعة قائمة طلبات توثيق المتاجر، تفاصيل المستندات، تسوية الدفع المحلي، وقرارات التوثيق، دون تشغيل دفع بطاقة أو تغيير DB/API/RLS/الصلاحيات.

## ملاحظة المصدر

فهرس ما قبل التغيير يربط TASK 058 بـ`AdminStoreVerification.tsx` و`admin-api.ts` و`admin-data.ts` ويصف مرجعًا مكتبيًا 1600×1000. ملفا `screens/058_admin_verification.png` و`explanations/058_admin_verification.md` غير موجودين في checkout الحالي أو شجرة GitHub المتاحة، لذلك لم تُنشأ صورة أو golden بديل.

## الجرد والتنفيذ

تعرض اللوحة طلبات التوثيق بحالات loading/error/empty/refresh، وتفتح تفاصيل الطلب وتقرأ المستندات الموقعة مؤقتًا عبر `adminApi.storeVerificationRequest`. تسجل أزرار تسوية الدفع المحلي `paid/waived/failed/refunded` قرار الإدارة فقط، بينما تسجل أفعال `approve/reject/needs_more_info/revoke` قرار المراجعة؛ النص الصريح يوضح أن هذه الأزرار لا تنفذ عملية مالية خارجية. الصلاحيات موزعة بين `verification.read_sensitive` و`verification.review` و`verification.approve` و`verification.reject`، والخادم يستدعي RPCs القائمة ويسجل audit.

كان فشل قراءة تفاصيل المستندات يضع رسالة في خطأ القائمة العامة بينما يترك منطقة التفاصيل بلا حالة واضحة، ما يصعّب إعادة المحاولة وقد يخلط بين فشل القائمة وفشل المستند. عولج ذلك داخل `AdminStoreVerification.tsx` بإضافة `detailLoading` و`detailError`، وعرض تحميل عربي وتنبيه `role=alert` وزر «إعادة المحاولة» يعيد قراءة الطلب المحدد. لا تتجاوز هذه المعالجة عقد التخزين الخاص أو signed URLs، ولا تفتح دفع بطاقة مجمدًا.

## بوابات الإثبات

| البوابة | النتيجة |
|---|---|
| `pnpm test` | PASS — 8 ملفات اختبار قائمة |
| `pnpm check` | PASS — `tsc --noEmit` |
| `pnpm build` | PASS — Vite وesbuild؛ تحذير chunk أكبر من 500 kB بقي تحذير أداء |
| مراجعة verification path | PASS — list/detail loading-error-retry، signed document boundary، payment reconciliation، review actions، permissions وaudit مثبتة مصدرًا |

النتيجة المهيكلة محفوظة في `artifacts/task058_admin_verification_result.json`.

## الحدود والقرار

لم تُفتح مستندات Production أو تُسوّى رسوم فعلية أو يُعتمد متجر حي خلال المهمة، ولم تُشغّل مقارنة golden لغياب Markdown وPNG. لا يُدّعى دفع بطاقة أو تفعيل تلقائي أو مزامنة حية؛ ذلك خارج العقد الحالي ويحتاج اختبارًا آمنًا واعتمادًا منفصلًا.

**قرار TASK 058:** PASS للتعديل الوظيفي المحدود والبناء والاختبارات، مع GAP-032 لفقدان أصول التدقيق البصرية/السلوكية. لا تغيير DB/API/RLS/الصلاحيات.
