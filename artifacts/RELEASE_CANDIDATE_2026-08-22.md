# مرشح الإصدار الداخلي — 22 أغسطس 2026

## النتيجة

تم بناء مرشح Production قابل للتثبيت، متصل بعنوان مشروع Supabase Production ومفتاح publishable مضمّن في build configuration فقط. لم تُجرَ أي تغييرات كودية جديدة في هذه الجولة لأن تدقيق حواجز P0 لم يجد عطلًا كوديًا يمنع المسار الأساسي؛ الموجود حاليًا هو حزمة مبنية للاختبار الداخلي، لا إعلان نشر عام نهائي.

## البوابات المنفذة

| البوابة | النتيجة |
|---|---|
| Flutter analyze | PASS — No issues found |
| Flutter full tests | PASS — 70 tests |
| Admin TypeScript | PASS |
| Admin Vitest | PASS — 8 files / 47 tests |
| Admin production build | PASS — Vite + Node bundle |
| Admin local runtime | PASS — `GET /api/health` أعاد HTTP 200 و`source=supabase-production` |
| Supabase public connectivity | PASS — REST read endpoint أعاد HTTP 200 |
| Production APK split-per-ABI | PASS — arm64 / armeabi-v7a / x86_64 |
| Production AAB | PASS — `app-release.aab` |
| Android emulator/device smoke | BLOCKED — لا يوجد emulator أو جهاز Android متصل في جلسة البناء |

## حدود الحكم

اختبارات Flutter وAdmin الداخلية تثبت البناء والعقود والحالات المعروفة، لكنها لا تستبدل تسجيل دخول بشري فعلي في APK. لذلك تبقى الخطوات التالية لازمة قبل إعلان النشر العام: تثبيت APK على هاتف Android، إنشاء/استخدام حساب عميل مخصص، فتح حساب تاجر، اختبار الرد، ثم تسجيل الدخول إلى لوحة الإدارة بحساب admin مفعّل ومراجعة العملية. لا يُعتبر بناء Production وحده إثباتًا لرمز OTP حي أو مزامنة جهازين.

## الملفات

نسخ APK وAAB الحالية موثقة في `RELEASE_CANDIDATE_SHA256SUMS.md`. نسخة arm64 هي الاختيار المعتاد لمعظم الهواتف الحديثة. نسخة armeabi-v7a للأجهزة الأقدم، ونسخة x86_64 للمحاكيات المتوافقة. لوحة الإدارة الحالية Local Admin وتُشغّل من `apps/admin_web` بعد توفير ملف `.env` الموجود، عبر `pnpm start`، وتفتح على `http://127.0.0.1:3210`.

## commits ذات الصلة

`305f620` يربط قنوات المتجر والتوصيل، و`ae12d01` يحدّث تقرير التدقيق، و`e701df2` يوثق artifact سابقًا. يجب حفظ هذا التقرير وسجل hashes مع مرشح الإصدار الحالي عند نقله للاختبار.
