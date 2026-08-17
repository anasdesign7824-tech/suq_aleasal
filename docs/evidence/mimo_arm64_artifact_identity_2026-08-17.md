# Mimo ARM64 Artifact Identity — 2026-08-17

## النتيجة

تم سحب APK المثبت فعليًا من Mimo عبر `pm path` و`adb pull` إلى:

```text
D:\suq_aleasa\installed_mimo_base.apk
```

خصائصه:

| الحقل | القيمة |
|---|---|
| package | `com.assalkom.assalkom` |
| versionName | `0.1.0` |
| versionCode | `2001` |
| targetSdk | 36 |
| الحجم | 20,672,806 bytes = 20.673 MB = 19.715 MiB |
| SHA-256 | `3617a942b35e207d4b116ed9abbce04aa6356d8fe0533b6f911333374781b4f2` |
| آخر تحديث على Mimo | 2026-08-17 13:55:25 |

## المطابقة مع المصدر الحالي

SHA-256 للملف التالي في بيئة البناء يطابق الملف المثبت على Mimo حرفيًا:

```text
apps/mobile_flutter/build/app/outputs/apk/release/app-arm64-v8a-release.apk
```

هذا يثبت أن نسخة Mimo التي يستخدمها المستخدم هي **Release ARM64 الحالية المبنية من المصدر الحالي**، وليست نسخة قديمة مختلفة عن آخر APK arm64 في المشروع. الفرق بين «19» و«20.67 MB» هو عرض MiB مقابل MB العشري.

## ملاحظة مهمة عن البيانات والمصادقة

مطابقة الـhash تثبت هوية الملف فقط، ولا تثبت أن وضع التشغيل داخله Production أو أن Supabase Auth مهيأ. هذا يحدده `ASSALKOM_MODE` و`ASSALKOM_SUPABASE_URL` و`ASSALKOM_SUPABASE_PUBLISHABLE_KEY` وقت البناء. لذلك المرحلة التالية هي فحص مسار التشغيل الفعلي، وقراءة السجلات أثناء OTP، وتحديد هل النسخة Demo أم Production-configured قبل تعديل أي APK.

## قرار البوابة

**PASS — artifact identity.**

**OPEN — runtime mode and OTP verification.**
