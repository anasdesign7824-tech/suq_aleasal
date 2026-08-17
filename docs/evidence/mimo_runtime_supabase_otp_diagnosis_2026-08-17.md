# Mimo Runtime / Supabase / OTP Diagnosis — 2026-08-17

## الحكم على النسخة التي كانت مثبتة قبل اختبار Production

الـAPK الذي سُحب من Mimo قبل تثبيت مرشح Production كان:

- `package=com.assalkom.assalkom`
- `versionName=0.1.0`
- `versionCode=2001`
- `size=20,672,806 bytes = 19.715 MiB`
- `SHA-256=3617a942b35e207d4b116ed9abbce04aa6356d8fe0533b6f911333374781b4f2`

وهذا الـhash يطابق `app-arm64-v8a-release.apk` المبني من المصدر الحالي في مسار البناء العادي.

لكن مسار البناء العادي الذي شُغل سابقًا لم يمرر `ASSALKOM_MODE=production` ولا متغيرات Supabase؛ و`AssalRuntimeConfig` يضع `mode=demo` افتراضيًا. لذلك فالنسخة المثبتة كانت **Demo Mode** رغم أنها Release ARM64.

## سبب عدم وصول OTP في النسخة السابقة

في `DemoRepository`:

- `requestEmailOtp` يحفظ البريد في الذاكرة فقط ولا يرسل رسالة.
- `verifyEmailOtp` يقبل الرمز التجريبي `123456` فقط.
- المسار لا يستدعي Supabase Auth.

إذًا عدم وصول الرمز الحقيقي في نسخة Mimo السابقة متوقع ومثبت من المصدر؛ المشكلة ليست حجم APK ولا ABI ولا بالضرورة انقطاع الإنترنت.

## فحص Supabase المباشر

تم اختبار REST باستخدام نفس `SUPABASE_URL` و`SUPABASE_KEY` المتاحين لبيئة البناء:

| المورد | HTTP | النتيجة |
|---|---:|---|
| `regions` | 200 | بيانات فعلية موجودة |
| `honey_taxonomy` | 200 | بيانات فعلية موجودة |
| `categories` | 200 | بيانات فعلية موجودة |
| `customer_banners` | 200 | قائمة فارغة |
| `customer_stores` | 200 | قائمة فارغة |
| `customer_products` | 200 | قائمة فارغة |

هذا يثبت أن الاتصال الأساسي بـSupabase يعمل، لكنه يثبت أيضًا أن جداول المنتجات والمتاجر المستخدمة في Production لا تعيد صفوفًا حاليًا. قد يكون السبب عدم إدخال بيانات، أو RLS/filters، أو عدم اكتمال مزامنة المصدر؛ لا يجوز عرضها كبيانات تجارية حقيقية قبل معالجة ذلك.

## مرشح Production

تم بناء مرشح ARM64 جديد من الجذر المشترك عبر:

```text
ASSALKOM_MODE=production
ASSALKOM_SUPABASE_URL=<environment value>
ASSALKOM_SUPABASE_PUBLISHABLE_KEY=<environment value>
```

حجمه `21,262,630 bytes`، ونُزّل إلى جهاز المستخدم وثُبّت على Mimo بنجاح. لم تُرسل رسالة OTP حقيقية خلال هذا التحقيق حتى لا تُرسل رسالة إلى بريد غير معتمد دون موافقة أو صندوق اختبار واضح. اختبار HTTP أثبت الاتصال، أما اختبار وصول الرسالة وتسليم الرمز فيحتاج بريد اختبار يملكه المستخدم أو تنفيذًا مباشرًا من واجهة التطبيق مع مراقبة النتيجة.

## القرار

**PASS — هوية النسخة السابقة وتشخيص وضع Demo.**

**PASS — اتصال REST الأساسي بـSupabase.**

**BLOCKED — إثبات وصول OTP إلى صندوق بريد حقيقي، بسبب عدم وجود بريد اختبار مصرح به في هذه الدورة.**

**OPEN — تعبئة `customer_stores` و`customer_products` أو توثيق سبب بقائها فارغة، ثم اختبار Production UI على بيانات فعلية.**
