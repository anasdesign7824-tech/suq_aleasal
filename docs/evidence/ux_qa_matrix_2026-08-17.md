# UX QA Matrix — 2026-08-17

## Visual/runtime evidence

تم تثبيت `app-release-demo-arm64.apk` المبني بعد التحسينات على Mimo. تم سحب الـAPK المثبت من Mimo ومطابقة SHA-256:

| الحقل | القيمة |
|---|---|
| الحجم | 20,673,094 bytes |
| SHA-256 | `fde6c5033c8e98d572fea39c1d7e6ca23a334da58529317e30b12ce0cfad9fb0` |
| مقارنة | مطابق لـ `build_matrix_2026-08-17/app-release-demo-arm64.apk` |
| التشغيل | `monkey` نجح، لا يوجد `FATAL EXCEPTION` أو `E/flutter` أثناء بدء التشغيل |

شجرة UI الأصلية لا تعرض عناصر Flutter canvas في `uiautomator`; لذلك لا تُعتبر شجرة UI دليلًا بصريًا كاملًا. لقطة الشاشة محفوظة على جهاز المستخدم باسم `D:\suq_aleasa\demo_current_screen.png`، وستبقى مراجعتها المرئية النهائية مرتبطة بفتحها على الجهاز أو رفعها في الجلسة التالية.

## Architecture QA

- لا توجد مراجع `Supabase` أو `ProductionQueryGateway` أو `AssalAuthGateway` أو استدعاءات gateway مباشرة داخل `apps/mobile_flutter/lib/features`.
- الشاشات تمر عبر `AssalRepository`.

## Data QA

- Honey Master: version 5.0.0، 5 categories، 30 products، duplicate IDs = 0، missing product IDs = 0.
- المقارنة بين Demo fixtures حفظت نطاقين معلنين: fixture صغير للحزمة وruntime catalog غني لتطبيق Flutter؛ لا يوجد حذف تلقائي للمحتوى.
- `git diff --check`: PASS.

## البوابة

**PASS — architecture/data QA.**

**BLOCKED — visual screenshot review in this sandbox, لأن Mimo يعرض Flutter canvas غير قابل للاستخراج عبر UIAutomator ولأن ملف screenshot محفوظ على جهاز المستخدم لا على مسار sandbox المرئي.**
