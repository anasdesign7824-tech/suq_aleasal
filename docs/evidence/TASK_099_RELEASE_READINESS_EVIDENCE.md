# TASK 099 — Release Readiness Gate Evidence

## الحكم التنفيذي

**PASS WITH DOCUMENTED RELEASE BLOCKERS — NOT GO FOR PUBLIC DISTRIBUTION.** تم تنفيذ Release Readiness Gate على source baseline قابل للبناء، ونجحت بوابات Flutter/Admin وProduction APK/Web smoke وSupabase health. لكن لا يجوز إعلان الإصدار جاهزًا للتوزيع العام حاليًا بسبب **توقيع APK بمفتاح debug**، وتحذيرات Security Advisors غير مغلقة، ووجود untracked evidence/legacy files خارج commit الإصدار. هذه ليست Fake Success؛ الحالة النهائية موثقة كـrelease limitation صريح، ويجب إغلاق blockers قبل public launch.

## مصدر الإصدار

| البند | النتيجة المثبتة |
|---|---|
| Repository | `D:/suq_aleasa` |
| Branch | `audit/launch-fixes-2026-08-20` |
| Release source baseline | commit `ad73e43` — `task 099: commit release source baseline` |
| Previous functional commit | `b89d815` — TASK 098 |
| Source baseline content | 12 tracked production/test changes، 3 Admin files جديدة، 6 Flutter tests جديدة، و8 migrations كانت untracked وأصبحت ملتزمة |
| Tracked worktree بعد baseline | لا توجد tracked modifications؛ `git status --porcelain --untracked-files=all` سجّل `352` untracked entries من evidence/logs/APKs/legacy discovery خارج release commit |

الـrelease package يجب أن يُبنى من commit `ad73e43` أو export نظيف منه، لا من working directory الذي يحتوي artifacts غير ملتزمة. لم تُحذف هذه الملفات ولم تُضمّن عشوائيًا؛ بعضها أدلة سابقة وبعضها legacy outputs، وتم فصلها عن source baseline.

## Production database and migration gate

| الفحص | النتيجة |
|---|---|
| Supabase project | `gvalqfgxrkibuydoiuiz`، الحالة `ACTIVE_HEALTHY` |
| Production URL | `https://gvalqfgxrkibuydoiuiz.supabase.co` |
| PostgreSQL | `17.6` |
| Required tables | `public.users`, `public.stores`, `public.products`, `public.messages`, `public.requests` موجودة |
| Idempotency ledger | `private.client_mutations` موجود |
| RLS | مفعّل على الجداول العامة الخمسة المفحوصة |
| Latest Production migration | `0061_write_idempotency_keys`, version `20260821204742` |
| Source SQL inventory | `54` SQL migration files بعد ضم baseline files |
| Production migration history | `60` migration entries؛ أسماء التاريخ لا تطابق filenames source واحدًا لواحد في بعض migrations القديمة، لذلك تم تسجيل provenance limitation بدل ادعاء تطابق زائف |

الـraw outputs محفوظة في `artifacts/task099_production_migrations.json`, `artifacts/task099_table_health_probe.json`, `artifacts/task099_rls_health_probe.json`, و`artifacts/task099_migration_source_compare.txt`.

## Environment contract

`AssalRuntimeConfig` يفرض في Flutter أن تكون القيم `ASSALKOM_MODE=production`، و`ASSALKOM_SUPABASE_URL` بعنوان HTTPS، و`ASSALKOM_SUPABASE_PUBLISHABLE_KEY` بمقدمة `sb_publishable_`. عند غيابها لا يحدث fallback صامت إلى Demo؛ يعرض التطبيق startup error بدل الادعاء بأنه متصل. سكربت `tool/build-production.ps1` تحقّق من هذه الشروط قبل البناء باستخدام `--dart-define-from-file`، ولم يطبع المفتاح العام أو أي secret في artifact evidence.

تم حصر أسماء Admin environment variables دون القيم، ومنها `ASSALKOM_ADMIN_HTTP`, `ASSALKOM_ADMIN_HTTPS`, `ASSALKOM_ADMIN_ALLOWED_ORIGINS`, `ASSALKOM_SUPABASE_URL`, و`ASSALKOM_SUPABASE_SERVICE_ROLE_KEY`. لا تُضمّن Service Role أو Admin password في Flutter/Web bundle وفق contract المشروع. قائمة الأسماء الحمراء محفوظة في `artifacts/task099_admin_env_keys_redacted.txt`.

## Health checks

| المسار | النتيجة |
|---|---|
| Supabase Management project status | `ACTIVE_HEALTHY` |
| Read-only DB table/version probe | PASS؛ database `postgres`, PostgreSQL `17.6`, required relations returned non-null |
| Critical RLS probe | PASS؛ `users`, `stores`, `products`, `messages`, `requests` = `rls_enabled=true` |
| Admin local `/api/health` | PASS؛ HTTP JSON `ok=true`, service `assalkom-admin-local`, source `supabase-production` |
| Flutter Web HTTP smoke | PASS؛ `index.html` HTTP 200 و`main.dart.js` HTTP 200 من localhost:8124 |

الـAdmin health route يثبت process/source contract فقط، ولا يُقدّم على أنه authenticated business transaction. أما Supabase table/RLS probe فهو read-only ولم يكتب Production data.

## Build and artifact evidence

| Artifact | النتيجة |
|---|---|
| Flutter APK split arm64 | `22,768,389` bytes؛ SHA-256 `9a543552d46d80ee793f621f09219c31f1856c97c03d6c2e797cff1362878e8a` |
| Flutter APK split armeabi-v7a | `20,590,611` bytes؛ SHA-256 `d14c72ce3b7af6ee997da18f4546733dee42a677ce194ba87122a525e90c81e0` |
| Flutter APK split x86_64 | `24,242,592` bytes؛ SHA-256 `26953cc06d209533224dd7c868eb1bb51e4df04c22b7de730562a109ba1d7253` |
| Flutter Web | `45` files، `46,498,074` bytes؛ `main.dart.js` SHA-256 `58962581c37cc7c3125510225d27e276776ca6d93382f4d6e0d273c57b080239` |
| Admin dist | `6` files، `1,248,252` bytes |
| Android applicationId | `com.assalkom.assalkom` |

### Signing blocker

`apps/mobile_flutter/android/app/build.gradle.kts` يحدد `signingConfig = signingConfigs.getByName("debug")` داخل `release`. كما لم يوجد keystore أو `key.properties` في Android tree. لذلك APKs أعلاه **build-valid وليست production-signing-valid**. المطلوب قبل التوزيع العام هو release keystore محفوظ خارج Git مع alias/password/secure path يقدّمها مالك المشروع، ثم إضافة configuration آمنة لا تنقل السر إلى repository أو logs. لم يتم إنشاء placeholder ولم يُعلن التوقيع نجاحًا.

## Release regression gates

| Gate | النتيجة |
|---|---|
| Flutter `analyze --no-pub` | PASS — `No issues found!` |
| Flutter `test --no-pub` | PASS — `62` tests |
| Admin `pnpm check` | PASS |
| Admin tests | PASS — `47` tests عبر `8` files |
| Admin `pnpm build` | PASS؛ Vite chunk-size warning non-blocking فقط |
| Production APK build script | PASS؛ mode/URL/publishable-key validation وsplit APK outputs |
| Flutter Web release build | PASS |
| Admin local `/api/health` smoke | PASS |
| Flutter Web localhost smoke | PASS |

## Advisors and known release blockers

| المصدر | النتيجة | التصنيف والإجراء |
|---|---|---|
| Security Advisors | `20 WARN` | تشمل `anon/authenticated SECURITY DEFINER function executable` لعدد من public RPCs، إضافة إلى `auth_leaked_password_protection` disabled. يجب مراجعة intent/grants وAuth Dashboard قبل public GO؛ لا تم تغيير Production grants ضمن TASK 099. |
| Performance Advisors | `22 WARN` و`59 INFO` | يوجد WARNان لـRLS init-plan على messages، وINFOs لفهارس غير مستخدمة. ليست migration rollback تلقائية؛ تُسجل كتحسينات لاحقة مع مراقبة قبل scale. |
| APK signing | Debug signing في release build | **HIGH blocker**؛ مطلوب release keystore حقيقي. |
| Source migration provenance | 54 source SQL مقابل 60 Production history entry مع أسماء تاريخية غير one-to-one | **MEDIUM limitation**؛ لا يُدّعى replay clean من صفر حتى تتم مطابقة التاريخ أو اعتماد snapshot رسمي. |
| Worktree hygiene | 352 untracked evidence/legacy entries خارج baseline commit | **MEDIUM process blocker**؛ release يجب أن يصدر من clean export للـcommit، لا من dirty working directory. |

تفاصيل Advisors الخام محفوظة في `artifacts/task099_security_advisors.json` و`artifacts/task099_performance_advisors.json`. من أمثلة remediation الرسمية: [Security Definer advisor][8] و[RLS init-plan advisor][9] و[leaked password protection][10].

## Rollback note

Code rollback target هو commit السابق `b89d815` إذا ثبت أن regression introduced by the release baseline، مع الاحتفاظ بـ`ad73e43` كمرجع build. **لا توجد reverse migrations تلقائية أو آمنة تم تنفيذها**؛ migrations Production تتطلب rollback عبر forward corrective migration أو restore procedure معتمد ونافذة تغيير ونسخة احتياطية، وليس `DROP` يدويًا. لا يتم إجراء rollback حقيقي ضمن هذا gate لأن ذلك سيكون تغييرًا تشغيليًا غير مطلوب وقد يعرّض Production للبيانات.

## القرار

هذا gate يثبت أن source baseline قابل للبناء، وأن Production health وRLS وmigrations الأخيرة قابلة للرصد، وأن Flutter Web/APK وAdmin local artifacts أنتجت بنجاح. لكنه لا يمنح **GO للتوزيع العام** حتى تُغلق signing blocker، وتُراجع Security Advisor warnings، ويُنشَر الإصدار من clean export/commit. لذلك الحالة المعتمدة هي **PASS WITH DOCUMENTED RELEASE BLOCKERS** وليست PASS مطلقة.

## References

[1]: `artifacts/task099_release_source_inventory.txt`
[2]: `artifacts/task099_worktree_after_baseline.txt`
[3]: `artifacts/task099_production_migrations.json`
[4]: `artifacts/task099_table_health_probe.json`
[5]: `artifacts/task099_rls_health_probe.json`
[6]: `artifacts/task099_release_artifact_metadata.txt`
[7]: `artifacts/task099_signing_audit.txt`
[8]: https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable
[9]: https://supabase.com/docs/guides/database/database-linter?lint=0003_auth_rls_initplan
[10]: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection
