# TASK 081 — Data Integrity: Keys and Foreign Keys

**التاريخ:** 2026-08-21

**الحالة:** PASS — constraints and referential integrity verified

## النطاق والمنهج

فُحص Production project `gvalqfgxrkibuydoiuiz` عبر Supabase MCP بعد تثبيت project identity من `list_projects`. تم استخدام `list_tables` بــ`verbose=true` لجرد الجداول والـprimary keys والـforeign key relationships، ثم استُخدمت استعلامات PostgreSQL صريحة داخل `BEGIN; ... ROLLBACK;`. لم تُنشأ سجلات اختبارية ولم تُعدّل أي بيانات.

شمل التدقيق سلسلة الهوية والملف والتاجر والمتجر والمنتج: `auth.users → public.users → public.profiles / public.merchant_profiles → public.stores → public.products`، مع فحص `regions` و`honey_taxonomy` عند استعمالهما في `stores.region_id` و`products.taxonomy_id`.

## النتائج البنيوية

| المسار أو القيد | النتيجة الفعلية في Production |
|---|---|
| `public.users.id` | Primary key، وFK موثق إلى `auth.users(id)` مع `ON DELETE CASCADE`، و`convalidated=true`. |
| `public.profiles.user_id` | Primary key وFK إلى `public.users(id)` مع `ON DELETE CASCADE`، ويمثل علاقة one-to-one. |
| `public.merchant_profiles.user_id` | Primary key وFK إلى `public.users(id)` مع `ON DELETE CASCADE`، ويمثل علاقة one-to-one. |
| `public.stores.id` | Primary key، وFK `merchant_id` إلى `merchant_profiles(user_id)` مع `ON DELETE CASCADE`، وFK `region_id` إلى `regions(id)` مع `ON DELETE SET NULL`. |
| `public.stores.slug` | Unique constraint `stores_slug_key` مع `convalidated=true`. |
| `public.stores.merchant_id` | Unique index `stores_one_per_merchant_idx` موجود فعليًا، وهو ما يدعم افتراض `ON CONFLICT (merchant_id)` في `merchant_open_workspace`. |
| `public.products.id` | Primary key، وFK `store_id` إلى `stores(id)` مع `ON DELETE CASCADE`، وFK اختياري `taxonomy_id` إلى `honey_taxonomy(id)` مع `ON DELETE SET NULL`. |
| عقود TypeScript وDart | `profiles.user_id` و`merchant_profiles.user_id` ممثلان كعلاقات one-to-one، و`products.store_id` كعلاقة one-to-many من المتجر إلى المنتجات، وأسماء الحقول الأساسية متطابقة مع Production. |

جميع القيود التي أعادها فحص `pg_constraint` لهذه السلسلة كانت validated. كما أن فحص الفهرس أظهر:

```text
stores_merchant_idx       CREATE INDEX stores_merchant_idx ON public.stores USING btree (merchant_id)
stores_one_per_merchant_idx CREATE UNIQUE INDEX stores_one_per_merchant_idx ON public.stores USING btree (merchant_id)
```

## فحص البيانات

نتائج orphan والازدواج قبل وبعد التثبيت كانت صفرًا في جميع الحالات التالية: مستخدم بلا auth user، profile بلا user، merchant profile بلا user، store بلا merchant profile، مجموعات متكررة في `stores.merchant_id`، مجموعات متكررة في `stores.slug`، product بلا store، وproduct ذي taxonomy غير فارغ بلا taxonomy مرجعي.

النتيجة بعد migration كانت `stores_one_per_merchant_idx_exists=1`، و`stores_duplicate_merchant_id_groups=0`، وجميع counters الخاصة بالسجلات اليتيمة تساوي `0`.

## الفجوة التي عولجت

أظهر التدقيق أن Production كان يحتوي فعليًا على `stores_one_per_merchant_idx`، بينما كان ملف `0045_foreign_key_indexes.sql` المحلي لا يضمنه، مع أن RPC `merchant_open_workspace` في migration `0020` يستخدم `ON CONFLICT (merchant_id)`. لذلك كانت المشكلة **قابلية إعادة البناء والتوثيق** لا تلف البيانات الحالي: Production صحيح، لكن مصدر migrations لم يكن يثبت invariant one-store-per-merchant.

قبل التثبيت الدائم أُجري rollback test حقيقي:

```sql
BEGIN;
CREATE UNIQUE INDEX IF NOT EXISTS stores_one_per_merchant_idx
  ON public.stores(merchant_id);
SELECT indexname, indexdef ...;
ROLLBACK;
```

أعاد الاختبار الفهرس الفريد بنجاح دون تعارض. بعد ذلك أُضيفت migration محافظة idempotent وطُبقت في Production:

```text
database/migrations/0055_reconcile_store_merchant_uniqueness.sql
Production migration ledger: 0055_reconcile_store_merchant_uniqueness
version: 20260821162038
apply_migration: success=true
```

## الملفات والأدلة

| العنصر | الدليل |
|---|---|
| مصدر schema الأساسي | `database/migrations/0001_initial_souq_al_assal.sql`، تعريفات users/profiles/merchant_profiles/stores/products. |
| افتراض workspace | `database/migrations/0020_merchant_workspace_and_safe_product_edits.sql`، `ON CONFLICT (merchant_id)`. |
| فحص constraints الخام | Supabase result `2026-08-21_16-13-37.789220564_supabase_execute_sql_92e4b9d0.json`. |
| فحص orphan counts | Supabase result `2026-08-21_16-17-14.182803787_supabase_execute_sql_ef8fb15f.json`. |
| فحص index | Supabase result `2026-08-21_16-17-35.218651986_supabase_execute_sql_03177c66.json`. |
| rollback test | Supabase result `2026-08-21_16-19-46.342939610_supabase_execute_sql_c6b684af.json`. |
| post-migration verification | Supabase result `2026-08-21_16-21-03.268905291_supabase_execute_sql_df526a56.json`. |
| migration ledger | Supabase result `2026-08-21_16-21-57.495877704_supabase_list_migrations_e62ba85d.json`. |

## الحكم

**TASK 081 مغلقة PASS.** لا توجد سجلات يتيمة أو ازدواج فعلي في سلسلة الهوية/الملف/التاجر/المتجر/المنتج، والقيود الأساسية validated. تم تحويل invariant one-store-per-merchant الموجود في Production إلى migration مصدرية قابلة لإعادة البناء دون تغيير بيانات الأعمال.

لا يشمل هذا الحكم فحص جميع جداول الصور والتعليقات والطلبات اليتيمة؛ ذلك نطاق TASK 082، ولا يشمل status enum الشامل؛ ذلك نطاق TASK 083.
