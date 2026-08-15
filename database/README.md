# Production Database — Supabase

هذا المسار يحوي migrations المصدر لمشروع Supabase الإنتاجي لمشروع **Souq Al Assal / سوق العسل**. الاسم التجاري الظاهر في البيانات والواجهات هو **عسلكم**.

## المigrations

تُطبق ملفات `database/migrations/*.sql` بالترتيب الرقمي. ملفات `*.mcp.json` إن وُجدت هي payloads مؤقتة لتشغيل أدوات الإدارة ولا تُتبع في Git.

| الملف | الدور |
|---|---|
| `0001_initial_souq_al_assal.sql` | الجداول والعلاقات والفهارس وRLS الأساسي |
| `0002_security_hardening.sql` | private functions ومنع تنفيذ توابع SECURITY DEFINER علنًا |
| `0003_rls_performance_and_policy_cleanup.sql` | دمج سياسات القراءة وتحسين auth init plans وفهارس Foreign Keys |
| `0004_admin_helper_security.sql` | فصل helper الإداري الخاص عن public invoker wrapper |
| `0005_public_profile_cards.sql` | تجربة إسقاط القراءة العامة المحدودة، أزيل لاحقًا بعد advisor |
| `0006_remove_security_definer_view.sql` | إزالة View غير الآمن والحفاظ على RLS المحافظ |

## قاعدة Demo

Supabase هو مصدر الإنتاج الرسمي، لكنه ليس شرطًا لتشغيل Demo Mode. لا تُزرع بيانات Demo في قاعدة الإنتاج ضمن هذه المرحلة. يجب أن تلتزم Demo Repository وProduction Repository بالعقود الدلالية نفسها.

## التحقق

تم تطبيق migrations الستة على مشروع Supabase ذي المعرّف `gvalqfgxrkibuydoiuiz`. تم فحص Security Advisor بنتيجة نظيفة، وأصبح أداء RLS خاليًا من WARN وunindexed foreign keys وmultiple permissive policies، مع بقاء ملاحظات `unused_index` المعلوماتية المتوقعة في قاعدة فارغة.
