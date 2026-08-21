# TASK 084 — RLS, SECURITY DEFINER, and Data Isolation

**التاريخ:** 2026-08-21

**الحالة:** PASS WITH DOCUMENTED LIVE-HTTP LIMITATION

## النطاق والمنهج

تم تدقيق Production project `gvalqfgxrkibuydoiuiz` على مستوى `relrowsecurity` و`pg_policies` و`pg_proc` وschema/function privileges. شمل التدقيق جداول الهوية والملف والتاجر والمتجر والمنتجات والتفاعل والمراسلة والإشعارات والدفع والتوثيق وطلبات التصميم والإدارة والتدقيق.

كل probes SQL الخاصة بالبيانات نُفذت داخل `BEGIN; ... ROLLBACK;`، ولم تُنشأ بيانات دائمة. استُخدمت هويات Production الموجودة مسبقًا فقط لمحاكاة `authenticated` claims داخل transaction: العميل، التاجر، والمدير الأعلى. لم تُستخدم هوية اختبار جديدة.

## حالة RLS والسياسات

| الفحص | النتيجة الفعلية |
|---|---|
| public base tables | كل الجداول المصدرية التي أعادها inventory لها `rls_enabled=true`. |
| FORCE ROW LEVEL SECURITY | `force_rls=false` لكل الجداول؛ التنفيذ تحت owner/service_role لا يعتمد على FORCE، بينما API roles تمر عبر RLS. |
| سياسات الجداول الحساسة | توجد سياسات CRUD مخصصة للهوية والملف والمتجر والمنتج والصور والتقييمات والتعليقات والطلبات والرسائل والإشعارات والدفع والتوثيق. |
| DELETE guard audit | الاستعلام المصحح على `qual` أعاد نتيجة فارغة؛ لم توجد سياسة DELETE عامة بلا `auth.uid()` أو admin guard. |
| Admin guard | سياسات الإدارة تستخدم `private.is_admin()` أو `is_super_admin()` أو named permissions مثل `audit.read`, `payments.read`, `payments.manage`, و`design.manage`. |
| Public catalog | سياسات banners/stores/products تسمح فقط بالسجلات العامة النشطة، مع owner/admin overrides حيث يلزم. |

الـRLS inventory أعاد `rls_enabled=true` لكل الجداول المصدرية في schema public، ومنها `users`, `profiles`, `merchant_profiles`, `stores`, `products`, `product_images`, `reviews`, `comments`, `requests`, `messages`, `notifications`, `payment_requests`, `merchant_subscriptions`, وجداول التوثيق والإدارة.

## نتائج العزل الفعلية

| الهوية / probe | النتيجة المرصودة |
|---|---|
| Anonymous | `is_admin=false`؛ يرى banners=2 وactive stores=1 وactive products=1؛ profiles=0 وpayment_requests=0. |
| Customer `d03fc0f2…` | `is_admin=false`؛ يرى profile=1 وstore=1 وproduct=1؛ payment_requests=0. |
| Merchant `4e658ebb…` | `is_admin=false`؛ يرى merchant_profile=1 وstore=1 وproduct=1 وpayment_requests=1 وverification_requests=1. |
| Super admin `1a6880b0…` | `is_admin=true` و`is_super_admin=true`؛ يرى users=3 وadmin_users=1 وaudit_logs=28 وpayment_requests=1. |

النتائج تثبت أن العميل لا يقرأ payment requests، وأن التاجر يقرأ نطاقه المملوك فقط، وأن المدير يرى النطاق الإداري الكامل. كما أثبت anon probe أن تضييق private function grants لم يكسر قراءة catalog العام.

## SECURITY DEFINER وACL

قبل hardening، كانت بعض private trigger-only functions تملك EXECUTE افتراضيًا للأدوار العامة، وكانت `private.handle_new_user()` و`public.admin_review_merchant_application(...)` تملكان search path أضيق من العقد الموحد. لم تكن هذه الدوال مكشوفة كـRPC عامة مثبتة؛ كما أن `private` schema لا يملك CREATE للأدوار anon/authenticated/public. لكن least privilege كان قابلًا للتحسين، ولذلك لم يُكتفِ بالتوثيق.

أُجري rollback test حقيقي شمل revoke مؤقتًا لدوال trigger-only، والإبقاء على grants الضرورية فقط لـ`private.is_admin()`, `private.is_super_admin()`, `private.has_admin_permission(text)`, و`private.subscription_discount_for_plan(uuid,text)`. داخل المعاملة اختُبرت قراءات العميل والتاجر، مسارات owner/admin، trigger-related inserts، وsearch_path، ثم أُعيد كل شيء بـ`ROLLBACK`.

نتيجة rollback test كانت: trigger-only execute أصبح false للأدوار العامة، بينما بقي `anon.is_admin=true` و`authenticated.has_admin_permission=true`؛ كما ظهر search path الموحد لدالة admin application. لم تُترك أي كتابة اختبارية.

بعد نجاح الاختبار طُبقت migration:

```text
database/migrations/0056_harden_private_function_execute.sql
0056_harden_private_function_execute
Production version: 20260821164931
apply_migration: success=true
```

قامت migration بإزالة EXECUTE العام من دوال enforcement وtrigger synchronization و`handle_new_user` وguards الداخلية، وأبقت grants الضرورية للـRLS helpers ومسار خصم الخطة، كما ثبتت:

```text
private.handle_new_user() → search_path=pg_catalog, public, private, auth
public.admin_review_merchant_application(...) → search_path=pg_catalog, public, private, auth
```

## Post-verification بعد migration 0056

| التحقق | النتيجة |
|---|---|
| Trigger-only EXECUTE | anon/authenticated=false للدوال التي تم تضييقها. |
| RLS helper EXECUTE | anon `private.is_admin()`=true؛ authenticated `private.has_admin_permission(text)`=true. |
| Subscription discount EXECUTE | authenticated=true. |
| Customer post-probe | is_admin=false؛ profile/store/product مرئية؛ payment_requests=0. |
| Merchant post-probe | is_admin=false؛ merchant profile/store/product/payment/verification المملوكة مرئية. |
| Admin post-probe | is_admin=true؛ is_super_admin=true؛ users/admin/audit/payment النطاق الإداري مرئي. |
| Anonymous post-probe | catalog العام مرئي؛ profiles وpayment_requests غير مرئيين. |

## الأدلة الخام

| المجال | الدليل |
|---|---|
| RLS inventory | `2026-08-21_16-35-57.430622537_supabase_execute_sql_194aab68.json`. |
| pg_policies focus | `2026-08-21_16-37-08.805926883_supabase_execute_sql_5e4f4b5f.json`. |
| SECURITY DEFINER/grants قبل hardening | `2026-08-21_16-37-34.786982820_supabase_execute_sql_7063fe2e.json`. |
| private schema ACL | `2026-08-21_16-37-59.221243535_supabase_execute_sql_8d96c313.json` و`2026-08-21_16-39-32.327441802_supabase_execute_sql_b9bdc14d.json`. |
| rollback ACL test | `2026-08-21_16-48-45.028120868_supabase_execute_sql_02ed6e1c.json`. |
| migration apply | `2026-08-21_16-49-32.160603522_supabase_apply_migration_c2c5fa14.json`. |
| post ACL verification | `2026-08-21_16-50-00.662991921_supabase_execute_sql_b950d608.json`. |
| customer post-probe | `2026-08-21_16-50-39.007453783_supabase_execute_sql_cafe7616.json`. |
| merchant post-probe | `2026-08-21_16-51-11.584114455_supabase_execute_sql_dde1f6de.json`. |
| admin post-probe | `2026-08-21_16-51-40.574627161_supabase_execute_sql_47c86de5.json`. |
| anon post-probe | `2026-08-21_16-52-58.449880188_supabase_execute_sql_e7ce7280.json`. |
| migration ledger | `2026-08-21_16-52-07.067123415_supabase_list_migrations_15a6747b.json`. |

## الحدود المقصودة

هذا الدليل يثبت العزل داخل PostgreSQL عبر role/claim probes وسياسات Production الفعلية. لم يُدّعَ اختبار HTTP حي من جهاز خارجي باستخدام JWT حقيقي أو فحص جميع combinations عبر PostgREST؛ ذلك يحتاج runtime network test مستقل. كذلك لم تُجرَ محاولة كتابة مدمرة أو حذف حقيقي. هذه حدود قياس موثقة وليست نجاحًا وهميًا.

## الحكم

**TASK 084 مغلقة PASS WITH DOCUMENTED LIVE-HTTP LIMITATION.** RLS مفعّل على الجداول المصدرية، وسياسات القراءة والكتابة الحساسة محروسة، والعزل بين anon/customer/merchant/admin مثبت عمليًا داخل transactions، وتم تضييق private SECURITY DEFINER execute grants وتوحيد search_path عبر migration 0056 بعد rollback test ناجح، مع post-verification ناجح لكل الأدوار.
