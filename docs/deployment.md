# Deployment and Environment Contract — عسلكم

## نطاق الإصدار الحالي

الإصدار الحالي يتكون من Customer Flutter Web/APK وMerchant capability داخل التطبيق وAdmin Web محلي متصل بمصدر Production-like حقيقي عند تهيئته. لا يتضمن Public Landing أو Cloudflare public deployment. يجب أن يبقى Flutter Web artifact قابلًا للبناء والنشر مستقبلًا من المستودع نفسه.

## أوضاع التشغيل

| Mode | UI | Data source | Auth | Storage | الإعلان |
|---|---|---|---|---|---|
| Demo | Customer/Merchant/Admin shell حسب fixture | Demo repositories/local fixtures | Demo session أو provider disabled بوضوح | local/demo media | لا يدعي Production |
| Production-like | Customer/Merchant/Admin local | Supabase repositories/gateway | Email/Google/Facebook + Admin role | Supabase Storage policies | يستخدم بيانات اختبار معزولة |
| Release | Customer Web/APK وAdmin local build | يحدد من config، لا fallback صامت | credentials خارج artifacts | paths/policies مهيأة | لا GO دون evidence |

## الإعدادات العامة غير السرية

يُسمح بتوفير هذه القيم عبر build/run configuration أو ملفات env غير سرية:

```text
ASSALKOM_MODE=demo|production
ASSALKOM_SUPABASE_URL=https://<project>.supabase.co
ASSALKOM_SUPABASE_ANON_KEY=<public-anon-key>
ASSALKOM_SITE_URL=http://127.0.0.1:8124
ASSALKOM_ANDROID_REDIRECT=com.assalkom.assalkom://login-callback/
ASSALKOM_STORAGE_BUCKET=sok1
ASSALKOM_ENABLE_MERCHANT=true
ASSALKOM_ENABLE_ADMIN=true
ASSALKOM_ENABLE_ANALYTICS=true
```

`ANON_KEY` يمكن أن يضمّن في client فقط إذا كانت RLS صحيحة؛ لا تُضمّن Service Role أو Google/Facebook Client Secret أو Admin password.

## الأسرار

| السر | مكانه المسموح | ممنوع |
|---|---|---|
| Google Web Client Secret | Supabase Auth Provider secret store | Flutter/Web/Admin bundle وGit |
| Facebook App Secret | Supabase/provider secret store | client source وGit |
| Supabase Service Role | server/connector secret environment فقط | Flutter/Web/Admin browser |
| Admin password | Supabase Auth + user-controlled secret handoff | Git/logs/screenshots |
| Android release keystore | خارج Git، secure operator storage | repository/client artifact |
| Test fixtures credentials | isolated secret env أو generated one-time handoff | production tables أو public docs |

## Redirect contract

- Supabase Site URL الحالية: `http://127.0.0.1:8124`.
- Supabase hosted OAuth callback: `https://gvalqfgxrkibuydoiuiz.supabase.co/auth/v1/callback`.
- Android deep link: `com.assalkom.assalkom://login-callback/`، وتُراجع قيمته الفعلية من Auth response لا من عرض RTL وحده.
- Web redirect domain النهائي لا يضاف قبل وجود domain معتمد؛ لا wildcard غير ضروري.

## التشغيل المحلي

### Customer Web

```text
flutter build web --release
npx serve -s apps/mobile_flutter/build/web -l 8124
```

يجب حفظ HTTP status وconsole/network وOAuth callback evidence.

### Customer APK

يجب ضبط JDK 17، تنفيذ build، تثبيت APK على Mimo، ثم فحص package `com.assalkom.assalkom` وlogcat وعدم وجود FATAL/ANR. SHA-1 الخاصة بـ Debug وRelease تُسجل كل واحدة باسمها؛ لا تُستخدم بصمة debug لإعلان توقيع Production.

### Admin المحلي

يُشغّل من `apps/admin_web` على localhost بعد اكتمال Auth guard. عنوان localhost لا يعادل anonymous access؛ كل query/mutation يمر عبر user session وRLS. يبقى service-side secret خارج المتصفح.

## Build/release evidence

كل release يحتاج:

1. commit وbranch نظيف.
2. `git diff --check`.
3. analyze/check/test results.
4. Web artifact hash وHTTP smoke.
5. APK hash، package، signing status، install/runtime evidence.
6. Admin build/check وlocal URL smoke.
7. Auth/Storage/RLS/Battle-Test reports.
8. Known Issues وDeferred/Blocked entries.

## قاعدة عدم التجاوز

إذا لم يمكن الوصول إلى إعداد خارجي أو credential أو device capability، يُسجل `BLOCKED` مع `ROOT CAUSE / IMPACT / REQUIRED USER INPUT`. لا يتم وضع placeholder يعلن نجاحًا، ولا تُخفى المشكلة بتفعيل public write أو fallback صامت إلى Demo.
