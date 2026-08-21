# TASK 086 — Privacy/PII Audit Evidence

**التاريخ:** 2026-08-21

**الحالة:** PASS WITH DOCUMENTED LIMITATIONS

## النطاق

تم تدقيق مصادر البيانات الحساسة في Flutter production repository وSupabase query gateway وAdmin Web backend وnotification/request/payment payloads وaudit metadata وStorage response paths. شمل التدقيق البريد والهاتف وبيانات الحوالة وسندات الدفع ومسارات مستندات التوثيق وعناوين IP ورسائل الأخطاء.

## النتائج المثبتة قبل الإصلاح

كان `recordAudit` معرفًا في `apps/admin_web/server/admin-data.ts` عند العقدة التي تبني `actor_user_id`, `action`, `entity_type`, `entity_id`, و`metadata` ثم تُدخل السجل بعد نجاح العملية الإدارية. وُجدت مسارات كانت تضع نصوصًا خامًا داخل metadata: `paymentReference`, `reviewNote`, `note`, `adminNote`, و`email` عند إنشاء هوية إدارية. لم يكن ذلك تسريبًا إلى العميل العام، لكنه كان تخزينًا غير ضروري لقيم قد تحتوي PII أو تفاصيل دفع داخل سجل التدقيق.

أظهر فحص Production المقيد بالمفاتيح فقط، دون إرجاع أي قيم، ما يلي: `email_key_rows=0`, `phone_key_rows=0`, `sender_phone_key_rows=0`, `proof_path_key_rows=0`, `account_number_key_rows=0`, و`iban_key_rows=0`. وُجدت `payment_reference_key_rows=2` تاريخية و`image_url_key_rows=3` و`path_key_rows=3` ضمن audit metadata. لم تُجرَ إعادة كتابة للسجلات التاريخية حتى لا تُفقد أدلة التدقيق، ولذلك لا يُدّعى أن السجل التاريخي خالٍ من payment references.

مفاتيح notification payload المرصودة اقتصرت على `action`, `image_url`, `payment_status`, `request_id`, `status`, و`store_id`؛ ولم تُرصد phone أو account number أو IBAN أو proof contents. كما أن مسار سند الدفع الخاص يبقى في `assalkom_private` ولا يُعاد كـpublic URL. وعنوان IP غير موجود في مخطط Production الحالي، وهو `ADMIN_NETWORK_TELEMETRY_UNAVAILABLE` موثق في TASK 066، ولم يُخترع حقل بديل.

## الإصلاحات المحافظة

أضيفت طبقة `redactAuditMetadata` دفاعية داخل `buildAuditEntry` لتحويل مفاتيح `email`, `phone`, `senderPhone`, `accountNumber`, `iban`, `proofPath`, `paymentReference`, `note`, `reviewNote`, و`adminNote` إلى مؤشرات Boolean مثل `hasEmail`, `hasPhone`, `hasPaymentReference`, و`hasNote`، مع حذف القيمة الخام قبل الإدخال. كما عُدلت call-sites الحساسة لتنتج flags بنيويًا بدل النص الخام، بما في ذلك مراجعة طلب التاجر، تسوية الدفع، حالة الاشتراك، التفعيل اليدوي، طلب التصميم، وإنشاء هوية المدير. لم يتغير عقد الاستجابة للعميل أو صلاحيات الإدارة.

أزيلت من Flutter network diagnostics حقول `error` و`stackTrace` الخام من مسارات timeout/failure في `ProductionRepository` و`SupabaseQueryGateway`. بقيت السجلات التشغيلية محدودة إلى اسم المورد/الجدول أو RPC، المفاتيح لا القيم، الكود المعياري، العدد والزمن؛ وتستمر أخطاء الواجهة في العودة كرسائل عربية normalized دون raw Supabase error.

## الاختبارات والمراجعة

اختبار Admin الجديد يمرر email وphone وpaymentReference وnote وproofPath إلى `buildAuditEntry` ويثبت أن الناتج يحتوي flags فقط ولا يحتوي القيم. بعد الإصلاح نجحت بوابة Admin: `pnpm check`; `pnpm test -- --run` بعدد 26 اختبارًا عبر `admin-auth` (4), `admin-data` (18), و`admin-error` (4); و`pnpm build`. ونجحت بوابة Flutter بعد تعقيم logs: `flutter analyze --no-pub` و`flutter test --no-pub` بعدد 54 اختبارًا. تحذير Vite الخاص بحجم chunk أكبر من 500 kB بقي غير مانع كما في المهام السابقة.

## حدود الدليل

لا توجد إمكانية ادعاء فحص sink خارجي دائم لسجلات الجهاز أو server log خارج مخزن البيانات المتاح. لذلك يثبت هذا الدليل عقد المصدر والاختبار وعدم تمرير raw exceptions من المسارات المدققة، ولا يثبت أن أي نظام logging خارجي غير معروف لا يحتفظ بسجلات سابقة. كما لم تُعدّل صفوف audit التاريخية التي تحتوي payment references، ولم تُجرَ كتابة Production جديدة؛ وفحص القيم الحساسة في Production كان redacted/count-only داخل `BEGIN`/`ROLLBACK`.

## الملفات

`apps/admin_web/server/admin-data.ts`, `apps/admin_web/server/admin-data.test.ts`, `packages/data_dart/lib/production_repository.dart`, `apps/mobile_flutter/lib/core/supabase_query_gateway.dart`, و`docs/evidence/TASK_075_ADMIN_ERROR_CONTRACT_EVIDENCE.md`.
