# TASK 085 — Storage Buckets, Policies, and Upload Isolation

**التاريخ:** 2026-08-21

**الحالة:** PASS WITH DOCUMENTED STORAGE-API LIMITATION

## النطاق والمنهج

تم فحص `storage.buckets` و`storage.objects` و`pg_policies` وRLS/table privileges في Production project `gvalqfgxrkibuydoiuiz`. كما قورنت السياسات بمسارات الرفع الفعلية في Flutter gateway وAdmin backend. كل probes الخاصة بالبيانات نُفذت داخل `BEGIN; ... ROLLBACK;`، ولم يُنشأ object دائم أو يُرفع ملف حقيقي.

## Buckets الفعلية

| bucket | public | الحجم الأقصى | MIME المسموح | objects المرصودة |
|---|---:|---:|---|---:|
| `assalkom_public` | نعم | 10 MiB | JPEG, PNG, WEBP, SVG | 5 |
| `assalkom_private` | لا | 20 MiB | JPEG, PNG, WEBP, PDF | 0 |
| `sok1` | لا | غير محدد | غير محدد | 0 |

`assalkom_public` هو bucket الوسائط العامة، بينما `assalkom_private` مخصص للصور/المستندات الخاصة مثل proof. أما `sok1` فهو bucket private بلا policies وبلا objects وبلا references في مصدر Flutter/Admin؛ لذلك عومل كـlegacy idle bucket ولم تُفتح له صلاحيات جديدة. استخدامه مستقبلًا يجب أن يمر أولًا بعقد canonical مستقل، لا بإضافة policy عشوائية.

## Policies وRLS

| المسار | القراءة | الكتابة | الحذف/التحديث |
|---|---|---|---|
| `assalkom_public` | `public` يستطيع القراءة فقط عندما `bucket_id='assalkom_public'`. | `authenticated` فقط، مع prefix أول يساوي `auth.uid()` أو `public.is_admin()`. | authenticated owner/admin فقط. |
| `assalkom_private` | authenticated owner/admin فقط؛ لا public read. | authenticated owner/admin فقط، بنفس prefix guard. | authenticated owner/admin فقط. |
| `sok1` | لا policy؛ bucket private ولا objects. | لا policy؛ لا upload عبر API roles. | لا policy. |

`storage.objects` و`storage.buckets` لديهما `rls_enabled=true` و`force_rls=false`. وعلى الرغم من أن table-level grants العامة موجودة في catalog الداخلي، فإن RLS policies هي التي تحسم الوصول الفعلي؛ probe العميل رفض المسار غير المملوك، كما أن anonymous لم يرَ private objects.

## الخلل المكتشف وإصلاحه

كشفت محاولة upload owner داخل transaction خطأً حقيقيًا:

```text
ERROR: 42501: permission denied for function is_admin
```

السبب أن جميع storage policies كانت تعتمد على `is_admin()` غير المؤهلة، وقد ثبت dependency probe أن المرجع هو `public.is_admin()`. لكن ACL الفعلي للدالة كان لا يمنح EXECUTE لـ`anon` أو `authenticated`، رغم أن policy تحتاج استدعاءها حتى عند تقييم مسار المالك. لذلك كان upload/update يفشلان قبل وصولهما إلى فحص prefix.

أُجري rollback test بعد grant مؤقت لـ`public.is_admin()`؛ نجح insert وupdate لـobject في prefix المالك، وظهر `objects_inside_transaction=1`، ثم أُعيدت المعاملة بـ`ROLLBACK`. أُضيفت migration محافظة:

```text
database/migrations/0057_restore_public_is_admin_execute.sql
Production migration: 0057_restore_public_is_admin_execute
version: 20260821170048
apply_migration: success=true
```

وبعد التطبيق نجح post-probe بدون grant مؤقت: `auth_is_admin_exec=true` و`objects_inside_transaction=1` داخل transaction، ثم rollback. كما نجح admin في insert/update لمسار `admin-task085/rollback.webp` لا يبدأ بمعرّف المدير، لأن `private.is_admin()` أعاد true.

## نتائج العزل الفعلية

| probe | النتيجة |
|---|---|
| Owner upload/update بعد الإصلاح | PASS؛ insert/update ينجحان داخل transaction، ولا يبقى object بعد rollback. |
| Customer إلى prefix مستخدم آخر | PASS؛ رُفض بـ`42501`، ولم تُحفظ بيانات. |
| Admin إلى prefix غير مملوك | PASS؛ `is_admin=true` وinsert/update نجحا داخل transaction، ثم rollback. |
| Anonymous read | يرى `assalkom_public=5`، ولا يرى `assalkom_private=0` أو `sok1=0`. |
| Direct SQL DELETE | محظور عمدًا بواسطة `storage.protect_delete()` مع رسالة استخدام Storage API؛ لم يُعتبر ذلك فشلًا في policy. |

## مقارنة مسارات التطبيق

Flutter `supabase_query_gateway.dart` يستخدم فقط `assalkom_public` للوسائط العامة و`assalkom_private` للوسائط الخاصة/المستندات، ويعيد public URL للأول ومسارًا خاصًا للثاني. سياسات owner تتطلب أن يبدأ path بمعرّف المستخدم؛ هذا شرط عقدي على call sites. Admin `uploadPublicImage` يستخدم service-role backend ويرفع إلى `assalkom_public` بمسار purpose/timestamp، وهو مسار إداري مقصود لا يعتمد على RLS العميل، مع تسجيل audit للرفع.

## الأدلة الخام

| الدليل | الملف |
|---|---|
| buckets | `2026-08-21_16-54-37.598253953_supabase_execute_sql_d60e7080.json`. |
| storage policies | `2026-08-21_16-55-05.053743533_supabase_execute_sql_fd03579e.json`. |
| object counts | `2026-08-21_16-56-16.773078377_supabase_execute_sql_395c87be.json`. |
| storage columns | `2026-08-21_16-56-48.361599923_supabase_execute_sql_4fb74906.json`. |
| original failed probe | `2026-08-21_16-57-52.559990559_supabase_execute_sql_52cf9423.txt`، permission denied على `is_admin`. |
| dependency diagnosis | `2026-08-21_16-59-05.281804323_supabase_execute_sql_d7d53170.json`. |
| grant rollback test | `2026-08-21_17-00-03.065949310_supabase_execute_sql_22a83fc0.json`. |
| migration apply | `2026-08-21_17-00-49.118832428_supabase_apply_migration_db23c3b4.json`. |
| post owner upload | `2026-08-21_17-01-20.706318414_supabase_execute_sql_4c58be7d.json`. |
| negative prefix probe | `2026-08-21_17-01-53.788070416_supabase_execute_sql_e44febf0.json`. |
| ACL inventory | `2026-08-21_17-02-23.682820298_supabase_execute_sql_fb0388de.json`. |
| admin write probe | `2026-08-21_17-02-58.899572905_supabase_execute_sql_cadd2840.json`. |
| anonymous read probe | `2026-08-21_17-03-27.234154695_supabase_execute_sql_9ae03632.json`. |
| migration ledger | `2026-08-21_17-05-25.720983973_supabase_list_migrations_fb1656c4.json`. |

## الحدود المقصودة

لم يُنفذ حذف object عبر HTTP Storage API لأن direct SQL DELETE محمي صراحة بـ`storage.protect_delete()`، ولم يُدّعَ اختبار حذف حي من العميل. هذا دليل على أن الحذف يجب أن يستخدم Storage API، ويُستكمل في اختبار runtime مستقل. كما لم تُغيّر حالة bucket `sok1` ولم تُنقل objects، لأنه فارغ وغير مستخدم في المصدر.

## الحكم

**TASK 085 مغلقة PASS WITH DOCUMENTED STORAGE-API LIMITATION.** buckets الخاصة والعامة مضبوطة، policies تعزل owner/admin وتمنع prefix cross-user، anonymous يرى public فقط، وخلل upload الحقيقي بسبب ACL لـ`public.is_admin()` أُصلح عبر migration 0057 بعد rollback test وpost-verification ناجحين. لم تُترك objects اختبارية في Production.
