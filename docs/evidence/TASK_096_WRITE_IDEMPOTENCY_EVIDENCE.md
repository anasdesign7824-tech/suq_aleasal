# TASK 096 — Write Idempotency Evidence

## النتيجة

**PASS — Production write idempotency مثبتة بأدلة قبل/بعد وlegacy compatibility.** تمت إضافة migration `0061_write_idempotency_keys.sql` وتطبيقها بنجاح على مشروع Supabase Production `gvalqfgxrkibuydoiuiz`. الإصلاح يحمي عمليات الإنشاء التي كانت قابلة لتكرار السجل عند retry أو double-submit، مع إبقاء semantics الخاصة بأزرار التبديل كما هي مقصودة.

## الحالة قبل الإصلاح

تم تنفيذ duplicate probes داخل معاملات تجريبية مع `ROLLBACK` قبل تطبيق migration. أظهرت النتائج:

| العملية | الدليل قبل الإصلاح |
|---|---|
| `customer_create_comment` | `APPEND_ONLY_BEFORE=0 AFTER=2` مع `first` و`second` بمعرّفين مختلفين |
| `customer_create_request` | `APPEND_ONLY_BEFORE=0 AFTER=2` مع `first` و`second` بمعرّفين مختلفين |
| `customer_send_message` | `APPEND_ONLY_DELTA=2` مع معرّفين مختلفين |
| `customer_create_conversation` | كانت idempotent أصلًا (`IDEMPOTENT_SAME_ID_COUNT=1`) |
| `customer_create_review` | كانت idempotent أصلًا (`IDEMPOTENT_SAME_ID`) بسبب قيد/سلوك المراجعة الموجود |
| favorite / product-like / store-follow toggles | `first=false second=true`؛ هذا double-toggle behavior مقصود وليس retry-idempotency لطلب إنشاء منفصل |

المصدر الخام: `artifacts/task096_pre_duplicate_probe.json`.

## الإصلاح المحافظ المنفذ

أضيفت migration `database/migrations/0061_write_idempotency_keys.sql`، وتحتوي على العناصر التالية:

1. جدول ledger خاص `private.client_mutations` بالأعمدة `user_id`, `operation`, `mutation_key`, `result_id`, `created_at`، وبـprimary key مركب `(user_id, operation, mutation_key)`.
2. فهارس زمنية للـledger، مع `REVOKE ALL` من `public`, `anon`, و`authenticated`؛ لا يتم توسيع عقد العلاقات العامة للتطبيق.
3. دعم `p_mutation_key` اختياري في RPCs المستهدفة، مع إبقاء signatures القديمة متاحة عبر default `NULL`.
4. عند عدم إرسال key من العميل الحالي، يُشتق fallback deterministic key من هوية المستخدم، الهدف، ومحتوى العملية. لذلك لا يحتاج الإصلاح إلى تعديل UI أو كسر client contract الحالي.
5. استخدام `pg_advisory_xact_lock` قبل قراءة ledger، ثم إعادة `result_id` الأصلي إذا كان mutation مسجلًا؛ هذا يغطي race بين محاولتين متزامنتين.
6. تغطية عمليات `customer_create_request`, `customer_create_comment`, `customer_send_message`, `customer_create_review`, و`merchant_create_design_request`. وفي design request لا تُستهلك entitlement إضافية عند retry لنفس mutation.
7. الدوال `SECURITY DEFINER` تستخدم `search_path` ثابتًا، وتُمنح صلاحية التنفيذ فقط للدور `authenticated` على signatures الجديدة.

## دليل Production apply

تم تنفيذ migration عبر Supabase MCP، ونتيجة التطبيق المحفوظة هي:

```json
{"success":true}
```

المصدر الخام: `artifacts/task096_apply_migration_result.json`.

## الحالة بعد الإصلاح

أعيد تشغيل probes بعد migration، داخل معاملات اختبارية، وكانت النتائج:

| العملية | الدليل بعد الإصلاح |
|---|---|
| `customer_create_comment` | `BEFORE=0 AFTER=1 SAME_ID=true` |
| `customer_create_request` | `BEFORE=0 AFTER=1 SAME_ID=true` |
| `customer_send_message` | `ROWS=1 SAME_ID=true` |
| `customer_create_review` | `SAME_ID=true` |
| `customer_create_conversation` | بقيت idempotent (`IDEMPOTENT_SAME_ID`) |
| favorite toggle | `first=false second=true rows_protected_by_unique=true` |
| product-like toggle | `first=false second=true rows_protected_by_pk=true` |
| store-follow toggle | `first=false second=true rows_protected_by_unique=true` |

المصدر الخام: `artifacts/task096_post_duplicate_probe.json`.

## Backward compatibility للـclients الحالية

أعيد اختبار signatures القديمة دون تمرير `p_mutation_key` صراحةً. fallback deterministic keys منعت التكرار كما يلي:

| signature قديمة | النتيجة |
|---|---|
| `customer_create_comment(uuid,text)` | `ROWS=1 SAME_ID=true` |
| `customer_send_message(uuid,text)` | `ROWS=1 SAME_ID=true` |
| `customer_create_request(..., integer)` | `ROWS=1 SAME_ID=true` |
| `customer_create_review(uuid,uuid,integer,text)` | `SAME_ID=true` |

المصدر الخام: `artifacts/task096_legacy_signature_probe.json`.

## Semantics المقصودة للتبديلات

أزرار favorite وproduct-like وstore-follow ليست عمليات create append-only؛ هي toggles صريحة. لذلك ضغط الزر مرتين يغيّر الحالة ذهابًا وإيابًا (`false` ثم `true` في probe)، ولا ينبغي تحويله إلى replay لنفس النتيجة. حماية الصف من duplicate rows قائمة أصلًا عبر unique indexes أو primary key المركب، كما هو موثق في `artifacts/task096_production_write_constraints.md`.

## الاختبارات وRegression gates

| البوابة | النتيجة |
|---|---|
| Admin TypeScript check (`pnpm check`) | PASS |
| Admin tests | PASS — `43` اختبارًا عبر `7` ملفات |
| Admin production build (`pnpm build`) | PASS |
| Flutter tests (`flutter test --no-pub`) | PASS — `60` اختبارًا |

لم يتطلب هذا الإصلاح تغييرًا في Flutter أو Admin UI؛ تم الاكتفاء بحماية server-side/RPC لأن ذلك يغطي retries حتى عند تعدد الأجهزة أو إعادة إرسال الطلب من client قديم. تحذير Vite الخاص بحجم chunk أكبر من 500 kB موجود في build السابق وليس regression سببه TASK 096، ولم يفشل build.

## حدود وقواعد التشغيل

هذا الإصلاح لا يحوّل عمليتي إرسال متطابقتين عمدًا إلى عمليتين مختلفتين: نفس المستخدم، ونفس operation، ونفس fallback/passed key، ونفس payload تمثل retry لنفس mutation. تغيير محتوى العملية أو هدفها ينتج mutation مختلفة. أما toggle actions فتبقى toggle semantics ولا تُعاد صياغتها كـidempotent create.

الـprobes مؤقتة ومغلفة بـ`BEGIN ... ROLLBACK`؛ الدليل الدائم المقصود هو migration والledger وقواعد RPC، وليس سجلات probe. لا توجد UI busy guards ضمن هذه المهمة، لأن server-side idempotency هو الضمان الأساسي عبر الشبكات البطيئة، double-click، وإعادة المحاولة من أجهزة متعددة.

## الملفات والأدلة

| المسار | الغرض |
|---|---|
| `database/migrations/0061_write_idempotency_keys.sql` | مصدر الإصلاح المطبق |
| `artifacts/task096_apply_migration_result.json` | إثبات Production apply |
| `artifacts/task096_pre_duplicate_probe.json` | نتائج ما قبل الإصلاح |
| `artifacts/task096_post_duplicate_probe.json` | نتائج ما بعد الإصلاح |
| `artifacts/task096_legacy_signature_probe.json` | إثبات backward compatibility |
| `artifacts/task096_production_write_constraints.md` | قيود Production السابقة للتدقيق |
| `artifacts/task096_write_rpc_defs_summary.md` | ملخص تعريفات RPC وتحليل idempotency |

## الحكم النهائي

**TASK 096 = PASS.** جميع عمليات الإنشاء القابلة للتكرار التي استهدفها التدقيق أصبحت محمية بمفتاح idempotency صريح أو fallback deterministic، مع advisory locking، ledger خاص، وإثبات pre/post وlegacy probes، دون كسر client contract أو semantics التبديلات المقصودة.
