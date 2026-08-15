# Typed Contracts — عسلكم

## القاعدة التنفيذية

يستخدم تطبيق Flutter عقود Dart، وتستخدم مشاريع Web عقود TypeScript عند الحاجة. لا يغيّر استخدام TypeScript تقنية تطبيق الجوال، ولا يُسمح بتكرار Domain Model دلاليًا بين المسارين دون توثيق.

## مصادر العقود

| المستوى | المصدر | الدور |
|---|---|---|
| Production schema | `database/migrations/0001_initial_souq_al_assal.sql` | مصدر مخطط Supabase |
| Security/performance | `database/migrations/0002_security_hardening.sql`, `0003_rls_performance_and_policy_cleanup.sql`, `0004_admin_helper_security.sql` | RLS، الأمان، والفهارس |
| TypeScript database types | `packages/contracts_ts/src/database.ts` | أنواع قاعدة البيانات المولدة من Supabase |
| TypeScript domain | `packages/contracts_ts/src/domain.ts` | عقود Web الدلالية |
| Dart domain | `packages/contracts_dart/lib/assal_domain.dart` | عقود Flutter الدلالية |

## التطابق الدلالي

تتطابق أسماء المجالات الأساسية: Region، Taxonomy، StoreSummary، ProductSummary، ReviewSummary، RequestSummary، NotificationSummary، وحالات التحميل `loading/data/empty/error`. قد تختلف صياغة الحالة التقنية بين Dart وTypeScript، لكن لا تختلف دلالة الحالة أو حدود الوصول أو مصدرها.

## قواعد التغيير

أي تعديل في Schema يتطلب migration جديدة، وتحديث الأنواع المولدة، ومراجعة عقود Dart وTypeScript، وتحديث اختبارات التطابق. لا يُعتبر تعديل Schema أو إنشاء RLS اكتمال Feature؛ اكتمال Feature يتطلب UI + State + Domain Behavior + Repository Contract + Demo Implementation + Demo Data + Loading/Empty/Error States + Tests + Evidence، ثم Production Data Source في مرحلته.

## Demo boundary

هذه العقود لا تجعل Supabase شرطًا لتشغيل Demo Mode. يجب أن تنفذ طبقة Demo Repository نفس العقود الدلالية، ثم تُستبدل بمصدر Production Repository دون تغيير User Journey أو الواجهات.
