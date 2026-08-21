# TASK 095 — Failure, Timeout, and Recovery Evidence

## النتيجة

**PASS WITH DOCUMENTED WORKSPACE-SCOPE LIMITATION.** تم اختبار فشل Supabase/الشبكة والمهلة واستعادة القراءة في Flutter، وتحسين تطبيع أخطاء Admin Web المحلية. لا توجد استجابة نجاح وهمية في المسارات المفحوصة، وأثبتت المحاولة التالية بعد transient failure عودة البيانات الصحيحة.

## الحالة قبل الإصلاح

كان `ProductionRepository` يملك بالفعل mapping محافظًا لـ`TimeoutException` و`SocketException` وفشل الخادم داخل `_write` و`_readList`: timeout/network يعيدان `AssalError` من نوع network مع `retryable=true`، والفشل العام يعيد `AssalError` غير ناجحة ولا يتحول إلى `AssalData`. كما كانت هناك اختبارات timeout وoffline socket/server failure للكتابة.

في Admin Web كان `client/src/lib/admin-api.ts` يترجم `AbortError` إلى `504 admin_request_timeout`، لكن فشل `fetch`/الشبكة العادي كان يمر كـError عام بلا `status` أو `code` موحدين، مع أن request wrapper لا يعلن نجاحًا عند فشل HTTP أو fetch.

## الإصلاح المحافظ

أضيفت `normalizeAdminRequestError()` في Admin API. وهي تحول browser abort إلى خطأ retryable برمز `admin_request_timeout` وحالة `504`، وتحول `TypeError` وفشل fetch/network المعروف إلى `admin_network_unavailable` وحالة `503`. أخطاء التطبيق العادية مثل invalid status لا تُبتلع وتستمر إلى response parser.

لم يتغير عقد Supabase أو repository production data، ولم تُضف retries تلقائية قد تكرر mutation. الاستعادة بقيت explicit عبر إعادة استدعاء القراءة/زر إعادة المحاولة، وهو السلوك الآمن للكتابات الحساسة.

## Fault-injection وrecovery

أضيف اختبار Flutter مستقل في `apps/mobile_flutter/test/task095_failure_recovery_test.dart` باستخدام gateway يفشل في أول `listRegions()` بـ`SocketException('network unavailable')` ثم يعيد صف منطقة صحيح في المحاولة الثانية. النتيجة الأولى كانت `AssalError<List<AssalRegion>>` من النوع network، برمز `network`، و`retryable=true`، وليست `AssalData`. النتيجة الثانية كانت `AssalData<List<AssalRegion>>` بقيمة حضرموت، وعدد الاستدعاءات كان 2. هذا يثبت recovery دون state نجاح وهمي.

## نتائج الاختبارات

| الاختبار | النتيجة |
|---|---|
| Admin `pnpm check` | PASS |
| Admin `pnpm test -- --run` | PASS؛ 7 ملفات و43 اختبارًا، منها 3 اختبارات error normalization |
| Admin `pnpm build` | PASS؛ تحذير chunk الحجم informational فقط |
| Flutter `flutter analyze --no-pub` من `apps/mobile_flutter` | PASS؛ No issues found |
| Flutter `flutter test --no-pub` من `apps/mobile_flutter` | PASS؛ 60 اختبارًا |
| Existing Flutter timeout/socket/server tests | PASS؛ لا fake success |
| New transient read recovery test | PASS؛ failure ثم valid data في المحاولة التالية |

## ملاحظة تشغيلية قابلة للتدقيق

المحاولة الأولى لـ`flutter analyze --no-pub` من جذر monorepo `D:\suq_aleasa` أعادت 830 dependency-scope errors لأن التحليل شمل workspace غير مهيأ كتطبيق Flutter واحد. لم تُحسب هذه النتيجة فشلًا في التعديل؛ أُعيد التنفيذ من `D:\suq_aleasa\apps\mobile_flutter`، وهو نطاق التطبيق الفعلي، ونجح التحليل بلا issues. كما حدث انقطاع sidecar أثناء command مركب، فأُعيدت gates منفصلة بعد عودة الاتصال؛ النتائج أعلاه تخص الأوامر المنفصلة الناجحة.

## الملفات

| الملف | الغرض |
|---|---|
| `apps/admin_web/client/src/lib/admin-api.ts` | تطبيع timeout/network failures. |
| `apps/admin_web/client/src/lib/admin-api.test.ts` | اختبارات 503/504 وعدم ابتلاع الأخطاء العادية. |
| `apps/mobile_flutter/test/task095_failure_recovery_test.dart` | transient read failure ثم recovery. |
| `docs/evidence/TASK_095_FAILURE_RECOVERY_EVIDENCE.md` | هذا الدليل. |

## الحدود

لم تُنفذ fault injection مباشرة داخل Production Supabase أو mutation حقيقية؛ جرى استخدام fake gateways واختبارات HTTP/client محلية منعًا لتغيير بيانات المستخدمين. لا يُدعى أن هذه الاختبارات تثبت availability فعلية لمزود Supabase، لكنها تثبت طبقة التطبيق عند استلام timeout/network/server failure واستعادتها الآمنة.
