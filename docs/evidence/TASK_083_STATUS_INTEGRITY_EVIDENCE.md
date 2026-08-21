# TASK 083 — Status Integrity Across Core and Billing Domains

**التاريخ:** 2026-08-21

**الحالة:** PASS WITH DOCUMENTED CONTRACT-COVERAGE LIMITATION

## النطاق والمنهج

تم جرد أعمدة `status` و`review_status` و`payment_status` وحقول payment ذات الصلة في Production project `gvalqfgxrkibuydoiuiz`، ثم استخراج جميع CHECK constraints المرتبطة بالحالات من `pg_constraint`. كل استعلامات الفحص نُفذت داخل `BEGIN; SELECT ...; ROLLBACK;` مع `LIMIT` صريح، ولم تُجرَ أي كتابة أو migration في هذه المهمة.

تمت مقارنة النتائج مع `packages/contracts_dart/lib/assal_domain.dart` و`packages/contracts_ts/src/domain.ts`. لا توجد حالة مخزنة مخالفة للقيود، ولا يوجد CHECK غير validated في الجداول المستهدفة.

## القيم المسموح بها في Production

| الجدول/الحقل | القيم المسموح بها فعليًا عبر CHECK |
|---|---|
| `stores.status` | `pending`, `active`, `paused`, `rejected`, `suspended` |
| `products.status` | `draft`, `pending`, `active`, `paused`, `rejected` |
| `requests.status` | `open`, `in_progress`, `answered`, `closed`, `cancelled` |
| `reviews.status` | `pending`, `approved`, `rejected`, `hidden` |
| `payment_requests.status` | `not_started`, `proof_uploaded`, `under_review`, `confirmed`, `failed`, `refunded`, `waived` |
| `merchant_subscriptions.status` | `pending`, `active`, `expired`, `cancelled`, `suspended` |
| `store_verification_requests.status` | `draft`, `payment_pending`, `submitted`, `under_review`, `needs_more_info`, `approved`, `rejected`, `expired`, `revoked` |
| `store_verification_requests.payment_status` | `not_started`, `pending`, `paid`, `failed`, `refunded`, `waived` |
| `store_verification_documents.review_status` | `pending`, `accepted`, `rejected` |
| `design_requests.status` | `draft`, `submitted`, `needs_more_info`, `in_progress`, `ready_for_review`, `completed`, `cancelled` |
| `merchant_applications.status` | `submitted`, `under_review`, `approved`, `needs_more_info`, `rejected`, `withdrawn` |

جميع هذه CHECK constraints أعادت `convalidated=true`. كما أن `payment_requests.payment_method` لديه CHECK عام يسمح نظريًا بـ`bank_transfer` و`card`، مع CHECK ثانٍ مطبق حاليًا يقصر القيمة على `bank_transfer`. هذا متسق مع قرار **card payment frozen by design** وليس خللًا في البيانات.

## القيم الفعلية في السجلات الحالية

| الجدول | عدد السجلات | القيم المرصودة |
|---|---:|---|
| `stores` | 1 | `active=1` |
| `products` | 1 | `active=1` |
| `requests` | 2 | `open=2` |
| `reviews` | 1 | `pending=1` |
| `payment_requests` | 1 | `not_started=1` |
| `store_verification_requests` | 1 | `approved=1` |
| `merchant_subscriptions` | 0 | لا توجد سجلات حالية |
| `payment_events` | 0 | لا توجد سجلات حالية |
| `store_verification_documents` | 0 | لا توجد سجلات حالية |
| `design_requests` | 0 | لا توجد سجلات حالية |
| `merchant_applications` | 0 | لا توجد سجلات حالية |

كل قيمة مرصودة تقع ضمن CHECK المقابل. الجداول الفارغة لم تُعتبر نجاحًا صامتًا؛ تم تسجيل row counts لها صراحة.

## المقارنة مع العقود

القيم الأساسية في TypeScript (`ProductStatus`, `StoreStatus`, `ReviewStatus`, `RequestStatus`) تطابق SQL حرفيًا. كما تطابقها enums Dart الأساسية `ProductStatus`, `StoreStatus`, `ReviewStatus`, و`RequestStatus`. حالات توثيق المتجر والدفع ممثلة في Dart عبر `StoreVerificationStatus` و`VerificationPaymentStatus`، مع `notRequested` كحالة read-model اصطناعية لغياب طلب، وليست قيمة مخزنة في جدول Production.

توجد **محدودية تغطية عقدية موثقة** وليست مخالفة بيانات: `AssalPaymentRequest.status` و`AssalMerchantSubscription.status` و`AssalDesignRequest.status` هي `String` في Dart، كما أن TypeScript لا يعرّف unions مشتركة لحالات payment requests أو subscriptions أو design requests أو merchant applications. لذلك تبقى هذه المجالات محكومة فعليًا بواسطة SQL CHECK، مع أن طبقة domain لا تمنحها نفس مستوى الحماية النوعية الذي تمنحه للحالات الأساسية. لم أغير العقود في TASK 083 لأن تحويل raw strings إلى enums يحتاج مراجعة call sites ومسارًا مستقلًا لاختبارات التوافق، ولا توجد قيمة خاطئة حاليًا تستوجب إصلاحًا عاجلًا.

## الأدلة الخام

| الدليل | الملف |
|---|---|
| أعمدة status الفعلية | Supabase result `2026-08-21_16-28-26.953095190_supabase_execute_sql_a1482dfe.json`. |
| CHECK constraints | Supabase result `2026-08-21_16-28-53.617389438_supabase_execute_sql_f35b788e.json`. |
| القيم المرصودة | Supabase result `2026-08-21_16-29-29.213576401_supabase_execute_sql_03de91e2.json`. |
| row-count snapshot | Supabase result `2026-08-21_16-33-54.006059440_supabase_execute_sql_7e7643a9.json`. |
| Dart contracts | `packages/contracts_dart/lib/assal_domain.dart`. |
| TypeScript contracts | `packages/contracts_ts/src/domain.ts`. |
| انتقالات verification | `database/migrations/0026_admin_review_store_verification.sql` و`0028_store_verification_payment_reconciliation.sql`. |

## الحكم

**TASK 083 مغلقة PASS WITH DOCUMENTED CONTRACT-COVERAGE LIMITATION.** حالات Production في stores/products/requests/reviews/payments/subscriptions والتوثيق والتصميم مقيدة بقواعد صحيحة وكل القيم الحالية صالحة. لا توجد كتابة أو migration مطلوبة. فجوة raw-string في بعض عقود الدفع والاشتراك والتصميم والتاجر موثقة كتحسين عقدي لاحق، وليست fake success أو invalid status في Production.
