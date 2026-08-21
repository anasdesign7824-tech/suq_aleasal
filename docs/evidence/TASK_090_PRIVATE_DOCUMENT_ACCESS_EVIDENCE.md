# TASK 090 — Private Payment and Verification Document Access Evidence

**التاريخ:** 2026-08-21

**الحالة:** PASS WITH DOCUMENTED LIVE-HTTP LIMITATION

## النطاق

تم تدقيق عدم كشف سندات الدفع ومستندات توثيق المتجر عبر public URL أو حساب غير مالك. شمل ذلك bucket flags، MIME limits، `storage.objects` policies، عدد objects الخاصة في Production، مسارات الرفع الفعلية في Flutter، عقد `merchant_submit_payment_proof`، وnegative HTTP probe على public object endpoint.

## النتيجة الفعلية في Production

| bucket | public | الحد الأقصى | MIME المسموح | objects الخاصة المرصودة |
|---|---:|---:|---|---:|
| `assalkom_private` | لا | 20 MiB | JPEG، PNG، WEBP، PDF | 0 |
| `assalkom_public` | نعم | 10 MiB | JPEG، PNG، WEBP، SVG | 5 |
| `sok1` | لا | غير محدد | غير محدد | 0 |

أعاد استعلام `storage.objects` المحدود على `assalkom_private` و`sok1` صفوفًا صفرية. لذلك لا توجد في Production حاليًا وثيقة دفع أو توثيق حقيقية يمكن تنزيلها في probe حي دون إنشاء بيانات اختبارية جديدة.

## سياسات القراءة والكتابة

أثبت `pg_policies` في Production أن `assalkom_private` لا يملك public SELECT. القراءة مقتصرة على `authenticated`، مع شرط أن يساوي أول جزء من المسار `auth.uid()` أو أن يكون المستدعي Admin عبر `public.is_admin()`. وتستخدم INSERT/UPDATE/DELETE نفس owner/admin prefix guard. في المقابل، public SELECT موجود فقط لـ`assalkom_public` مع شرط `bucket_id = 'assalkom_public'`.

هذه النتيجة تطابق migration `0002_storage_canonical_policies.sql` وreconciliation migration `0051_reconcile_private_storage_policies.sql`. كما أن TASK 085 أثبت عمليًا داخل معاملات قابلة للـrollback: owner upload، رفض cross-prefix، Admin override، وanonymous read الذي لا يرى private objects. لم تُنشأ objects دائمة في تلك الاختبارات.

## مسارات التطبيق وعقد RPC

يبني Flutter مستندات التوثيق داخل `assalkom_private/<userId>/verification/<requestId>/document-<timestamp>.<safeExtension>`، ويبني سندات الدفع داخل `assalkom_private/<userId>/payment-proofs/<paymentRequestId>-<timestamp>.<safeExtension>`. يعيد gateway المسار الخاص فقط، ولا يستدعي `getPublicUrl` إلا في public bucket.

يفرض `merchant_submit_payment_proof` في migration 0031 أن يبدأ `p_proof_path` بمسار المستخدم `/payment-proofs/`، وأن تكون حالة payment request مملوكة للمستخدم، وأن يكون MIME والحجم ضمن الحدود. كما يرفض المسارات التي لا تطابق prefix المستخدم قبل تحديث `payment_requests`. هذا يمنع إرسال مسار public أو مسار مستخدم آخر عبر مسار RPC العادي.

وتحصر سياسة `store_verification_documents_owner_insert` الإدخال بمالك طلب التوثيق، بينما تحصر `store_verification_documents_owner_read` القراءة بالمالك أو Admin صاحب صلاحية `verification.read_sensitive`. لا توجد public policy لهذه الجداول.

## HTTP negative probe

تم تنفيذ طلب بلا Authorization إلى شكل public object endpoint لمسار غير موجود في private bucket:

```text
/storage/v1/object/public/assalkom_private/task090-probe/nonexistent.pdf
HTTP status: 400
body bytes: 98
```

لم يُرجع endpoint ملفًا أو نجاحًا عامًا. هذا probe لا يعتمد على وجود object، لكنه يثبت أن private bucket لا يُقدم عبر public object route. تفاصيله محفوظة في `artifacts/task090_private_storage_probe.json`، ومخرجات SQL الخام محفوظة في سجل Production للمهمة.

## الحكم والحدود

الحدود الخاصة بالمستندات صحيحة: private bucket غير عام، لا توجد public read policy، ومسارات التطبيق وRPC مرتبطة ببادئة المستخدم. لذلك لا يوجد خلل يحتاج migration جديدة في هذه المهمة.

يبقى **live authenticated cross-user HTTP download** غير منفذ لأن bucket الخاصة فارغة حاليًا ولا يوجد JWT مستخدم حقيقي مكشوف للاختبار. لا يُدّعى PASS كامل لهذا الجزء؛ تم تسجيله كحدّ موثق، مع إحالة probes owner/cross-prefix/anonymous السابقة إلى دليل TASK 085. لا توجد أي كتابة أو رفع أو حذف في Production ضمن TASK 090.
