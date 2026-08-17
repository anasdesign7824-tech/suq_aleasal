# Task 35 — Demo وProduction

## النطاق

التحقق من أن Demo يعمل دون Supabase، وأن Production لا يدّعي جاهزية للوظائف التي لم تُهيأ، بل يعيد حالات صريحة قابلة للفهم.

## النتائج

| الفحص | النتيجة |
|---|---|
| `flutter test` الكامل | PASS — 11 tests passed |
| `flutter build apk --debug --no-pub` | PASS |
| Demo bootstrap | `AssalApp` ينشئ `DemoRepository` مع `RootBundleDemoCatalogLoader` عند غياب Repository |
| Production bootstrap | يتطلب `ASSALKOM_MODE=production` وإعدادات Supabase، وإلا يعرض Startup Error بدل خلط Demo بالإنتاج |
| Production write/auth/merchant/analytics paths | تعيد `AssalError` مع أكواد `*_not_configured` أو رسائل مصدر حقيقية |
| Honey Master integrity | PASS — الإصدار 5.0.0، 5 فئات، 30 منتجًا، duplicate IDs فارغة |
| Demo JSON comparison | PASS — الاختلاف بين fixture المصغر وruntime catalog معلن كنطاقين، دون حذف تلقائي |
| Debug APK | PASS — تم البناء بنجاح، الحجم 184,317,600 bytes |
| `git diff --check` | PASS |

## Demo

تعمل نسخة Demo من الموارد المحلية فقط، وتضم runtime catalog الغني، ولا تحتاج Supabase لعرض المسارات الأساسية والتجارب الاجتماعية وEmail OTP التجريبي. الاختبارات الكاملة أثبتت رحلة العميل وطبقة البيانات.

## Production

نسخة Production لا تتحول تلقائيًا إلى Demo عند نقص الإعدادات. عند غياب عنوان Supabase أو المفتاح العام تعرض شاشة Startup Error عربية. الوظائف غير المهيأة، مثل كتابة التفاعل، طلب التاجر، Draft، Analytics، والمصادقة عند غياب Gateway، تعيد `AssalError` بأكواد صريحة بدل نجاح وهمي.

## Visual / Runtime QA

تم البناء والتثبيت سابقًا على محاكي Android، لكن استخراج Screenshot تفاعلي صالح عبر ADB بقي محجوبًا بسبب ملف `screencap` صفري الحجم. لذلك لا أعتبر ذلك دليلاً بصريًا كاملاً.

## بوابة القبول

**BLOCKED** — Demo وProduction behavior والاختبارات والبناء وسلامة البيانات ناجحة. سبب الحجب هو Visual QA التفاعلي غير المكتمل فقط؛ أما حالة Production غير المهيأة فهي سلوك مقصود ومثبت، وليست فشلًا مخفيًا.
