# APK artifact quarantine — 2026-08-27

## Purpose

هذا السجل يمنع الخلط بين المرشح الإنتاجي الجديد، ونسخ Demo/UX التاريخية، وملفات البناء المحلية. لم تُحذف أو تُنقل أي حزمة لأن الحذف irreversible وقد يكسر أدلة المستخدم أو روابط الاختبار.

| Path | Size | SHA-256 | Classification |
|---|---:|---|---|
| `apps/mobile_flutter/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` | 23,378,422 bytes | `67DD0ED2E8DE8599B9B816D45B863FD44E06D4619BF18612F1B7A4FEA86B2B31` | **Canonical production candidate** built by `tool/build-production.ps1`; not public yet. |
| `artifacts/assalkom-production-connected-arm64-release.apk` | 21,872,688 bytes | `F94B69EF058443C0B33F143547CBF1C0620D01B1A8FF4AAA1414B0A43065001D` | Historical production-connected artifact; retain for evidence, do not link until revalidated. |
| `artifacts/assalkom-production-arm64-release.apk` | 21,282,864 bytes | `3BFB555C3B486A5A027B4926E66D79D0833399BF6DC6CF730C3DC480F13BDF27` | Quarantined historical build; previous manifest says required defines were absent. |
| `mimo_demo_current_base.apk` | 20,673,094 bytes | `FDE6C5033C8E98D572FEA39C1D7E6CA23A334DA58529317E30B12CE0CFAD9FB0` | Demo/reference artifact; never a production download. |

## Release decision

لا يوجد حتى الآن رابط تنزيل عام canonical. لا تُضاف روابط APK إلى Landing قبل إغلاق full Flutter regression، device install/runtime smoke، وpublic distribution approval. لا يُنفذ حذف النسخ القديمة إلا بعد موافقة صريحة على قائمة الحذف.

## Configuration note

المرشح الجديد اجتاز بوابة الإنتاج التي تحقّق `mode=production` وSupabase project URL وpublishable key shape. لم يُدرج أي Service Role secret في الحزمة أو هذا السجل. فحص النص الخام داخل APK لا يكفي وحده لإثبات كل runtime constants بسبب طريقة تعبئة/ضغط Dart؛ لذلك لا يُعلن تطابق API الكامل إلا بعد runtime smoke أو فحص build configuration المستقل.
