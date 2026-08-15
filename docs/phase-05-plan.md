# Phase 5 — Demo Data Layer وProduction Repository Switch

## الهدف

إنشاء طبقة بيانات تجريبية مستقلة عن Supabase، قابلة للتشغيل والاختبار دون اتصال إنتاجي، وتطابق عقود Dart وTypeScript الدلالية نفسها. بعد استقرار Demo، تُجهز موصلات Production Repository القابلة للتبديل دون تغيير UX أو Domain Model.

## المخرجات

ستتضمن المرحلة Demo Catalog وDemo Stores وDemo Products وDemo Reviews وDemo Requests وDemo Notifications مستخرجة حتميًا من Honey Master، مع حالات loading/empty/error، وRepository Contracts، وDemo Repository، وProduction Repository adapters تتطلب تهيئة صريحة فقط. ستتضمن أيضًا مصدر تبديل واضح `demo`/`production` ومعلومات تشخيصية تمنع الاتصال الصامت بـ Supabase أثناء Demo.

## الحدود

لا تُزرع بيانات Demo في Supabase ولا تُستخدم مفاتيح Supabase داخل Demo. لا تُنفذ واجهات Feature النهائية في هذه المرحلة؛ المخرجات تجهزها للمراحل التالية. لا يُعتبر Repository أو Schema Feature مكتملة دون UI وState وDomain Behavior وTests وEvidence.

## بوابة المرحلة

تتبع المرحلة: `PLAN → IMPLEMENT → RUN → VERIFY → TEST → VISUAL CHECK → ARCHITECTURE CHECK → FIX → RETEST → EVIDENCE → GIT COMMIT → ACCEPTANCE GATE`.
