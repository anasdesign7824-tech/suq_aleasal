# مقارنة حجم تطبيق عسلكم قبل/بعد — 2026-08-17

## الخلاصة المهمة

الهبوط الكبير من نحو **82.79 MB** إلى نحو **59.07 MB** لم ينتج عن المهام الـ35 نفسها؛ بل حدث في مرحلة تحسين الحجم السابقة، قبل baseline المهام، عبر إزالة أصول شعارات مكررة وأوزان خطوط غير مستخدمة من قائمة Flutter assets المعبأة داخل APK. أما المهام الـ35 فقد غيّرت تجربة المستخدم والعقود والمنطق والاختبارات، ولم تضف dependency ثقيلة أو أصلًا جديدًا إلى `pubspec.yaml`؛ ولذلك كان أثرها على Release صغيرًا ومقاسًا.

المقارنة الصحيحة لها ثلاث مراحل، لا مرحلتان فقط:

| المرحلة | المخرج | الحجم بالبايت | MB عشري | MiB ثنائي | التفسير |
|---|---|---:|---:|---:|---|
| قبل تحسين الحجم السابق | `assalkom_email_otp_release.apk` | 82,786,915 | 82.787 | 78.952 | Universal APK حقيقي يحوي arm64 وarmeabi-v7a وx86_64، مع أصول شعارات مكررة كبيرة |
| baseline قبل المهام الـ35 | `assalkom_email_otp_size_optimized_universal.apk` | 59,069,723 | 59.070 | 56.333 | Universal APK محسن سابقًا، وهو المرجع العادل قبل المهام الـ35 |
| baseline قبل المهام الـ35 | `assalkom_email_otp_size_optimized_arm64-v8a.apk` | 21,345,589 | 21.346 | 20.356 | ملف قديم arm64 باسم مختلف؛ للمقارنة التشغيلية الأدق استُخدم أيضًا ملف 21,000,058 bytes |
| بعد المهام الـ35 | Release arm64-v8a | 20,672,806 | 20.673 | 19.715 | APK لجهاز Android ARM64 فعلي |
| بعد المهام الـ35 | Release x86_64 | 22,172,917 | 22.173 | 21.146 | APK لمحاكي أو جهاز x86_64، وهو سبب ظهور رقم قريب من 21 |
| بعد المهام الـ35 | Release AAB | 56,204,848 | 56.205 | 53.601 | Bundle للرفع إلى Google Play، وليس APK مثبتًا مباشرًا |
| بعد المهام الـ35 | Debug APK | 184,317,600 | 184.318 | 175.779 | ملف تطوير غير صالح للمقارنة مع Release أو لحساب حجم التنزيل النهائي |

> عندما تظهر لك قيمة **53** فهي تقريبًا `53.601 MiB` لحجم ملف AAB الحالي. وعندما تظهر قيمة **19** فهي `19.715 MiB` لنسخة arm64. وعندما تظهر قيمة **21** فهي `21.146 MiB` لنسخة x86_64. الاختلاف هنا وحدة عرض وABI، وليس اختلافًا غامضًا في التطبيق.

## من هي كل نسخة؟

| النسخة | لمن؟ | هل هي النسخة التي ينبغي اعتمادها؟ |
|---|---|---|
| `app-arm64-v8a-release.apk` | معظم الهواتف الحديثة ذات معمارية ARM64 | نعم، للاختبار المباشر على هاتف ARM64 أو للتوزيع الجانبي المحدد |
| `app-x86_64-release.apk` | محاكي Mimo أو جهاز Android x86_64 | نعم، للمحاكي؛ وهي أكبر قليلًا لأن Flutter engine الخاص بـx86_64 أكبر |
| `app-release.aab` | Google Play؛ يحتوي حزمًا حسب ABI والجهاز | نعم، هو مخرج النشر الأساسي للمتجر |
| APK Universal حقيقي | ملف واحد يحتوي arm64 وarmeabi-v7a وx86_64 | مفيد للتثبيت العام، لكنه أكبر من APK الخاص بـABI؛ لم يُعد بناؤه في آخر أمر split-per-ABI |
| `app-debug.apk` | التطوير والتصحيح المحلي فقط | لا، لا يستخدم لقياس حجم المنتج أو النشر |

الملف `apps/mobile_flutter/build/app/outputs/flutter-apk/app-release.apk` الذي ظهر مع `--split-per-abi` لا ينبغي تسميته Universal في هذه المقارنة؛ ففحص ZIP أثبت أنه يحتوي `lib/x86_64/libflutter.so` و`lib/x86_64/libapp.so` كاملين، مع ملفات صغيرة فقط لبعض ABI الأخرى. المرجع الصحيح هو ملفات ABI المسماة صراحة أو AAB.

## لماذا Debug حجمه كبير؟

الحجم الحالي للـDebug هو **184,317,600 bytes**. تحليل داخله يوضح أنه يحتوي على عناصر لا توجد في Release بالطريقة نفسها:

| مكوّن Debug | الحجم غير المضغوط التقريبي | السبب |
|---|---:|---|
| `kernel_blob.bin` | 59.75 MB | Dart kernel للتطوير وhot reload |
| `libflutter.so` عبر ABIات Debug | 120.23 MB تقريبًا | Flutter engine غير محسّن بالكامل للتصحيح |
| `libVkLayer_khronos_validation.so` | 15.24 MB | طبقة Vulkan للتحقق والتشخيص |
| `isolate_snapshot_data` | 11.65 MB | snapshot خاص بمسار Debug |
| `classes.dex` ومقاطع DEX | أكثر من 12 MB غير مضغوط | معلومات وتصحيح واعتماديات Debug |
| Material Icons في Debug | 1.65 MB | لم يحصل tree-shaking بالطريقة نفسها |

إذًا قيمة Debug الكبيرة **ليست حجم التطبيق الذي سيصل للمستخدم**. Release يستخدم AOT، tree-shaking للأيقونات، ويفصل ABI. لهذا لا يصح مقارنة Debug البالغ 175.779 MiB مع AAB البالغ 53.601 MiB.

## أين حدث الهبوط الكبير من 82.79 إلى 59.07 MB؟

تحليل APK القديم أثبت أن أربعة ملفات شعار كانت مضمّنة كاملة داخل الحزمة:

| الأصل القديم | الحجم غير المضغوط |
|---|---:|
| `logo-external-runtime.svg` | 7,937,162 bytes |
| `logo-external.svg` | 7,937,603 bytes |
| `logo-internal-runtime.svg` | 7,940,041 bytes |
| `logo-internal.svg` | 7,940,482 bytes |
| **الإجمالي** | **31,755,288 bytes** |

كما كانت سبعة أوزان IBM Plex Sans Arabic موجودة في الحزمة، بما فيها `Thin` و`ExtraLight` و`Light`، مع أن التطبيق المعبأ يستخدم أربعة أوزان فقط: Regular وMedium وSemiBold وBold.

في APK المحسن بقي أصل الشعار runtime الداخلي المطلوب فقط، وبقيت أوزان الخطوط الأربعة المستخدمة. هبط حجم Flutter assets المضغوط من **24,584,978 bytes** إلى **868,914 bytes**، أي أن أصول Flutter هي مصدر الهبوط السابق تقريبًا بالكامل. وبذلك هبط Universal APK من **82,786,915** إلى **59,069,723 bytes**، أي تخفيض **23,717,192 bytes / 28.648%**.

هذا التخفيض لم يحذف بيانات المنتج التشغيلية؛ ملف `demo_catalog.json` بقي موجودًا بحجم **147,760 bytes**، وملف المحافظات والمديريات بقي بحجم **108,565 bytes**.

## ماذا أضافت أو غيّرت المهام الـ35؟

Baseline المقارنة العادل هو commit `7dde63d`، وهو سابق لتنفيذ المهام الـ35 لكنه يأتي بعد تحسين الحجم السابق. عند مقارنة baseline بالمصدر الحالي، لم يتغير `pubspec.yaml` من ناحية dependencies أو asset declarations، ولم تتغير ملفات الأصول المعبأة. التغيير كان في منطق التطبيق وواجهته وعقوده واختباراته.

| المجال | قبل المهام الـ35 | بعد المهام الـ35 |
|---|---|---|
| المصادقة | Email-only وOTP ضمن المسار السابق | Email + Verification Code مع Dialog وcountdown ومزامنة Session Restore، وتأجيل Google/Facebook |
| البيانات | طبقة Demo/Production موجودة | Repository boundary أوضح، Demo-first، وProduction errors صريحة بلا fake success |
| الواجهة | مسارات أساسية | Glass Loading، Empty States، App Bar، Sticky Header، فلاتر وSelectors، Stores وDiscovery وVerified Products |
| نموذج المنتج | حقول أساسية | gradeLevels وgradeLabels وcomponents وحقول المصدر والجودة والتعبئة |
| التاجر | نموذج أولي لفتح المتجر | Draft وForm validation، حالات توثيق أربع، Merchant Dashboard يقرأ Repository |
| التخصيص | لا تخصيص deterministic موثق | تخصيص يعتمد على الموقع والمفضلة والمتاجر المتابعة والتفاعلات دون AI وهمي |
| Analytics | حقلا views/likes في النموذج | local view-event buffer في Demo، وProduction `production_analytics_not_configured` |
| Architecture | يحتاج تدقيقًا | لا توجد استدعاءات Supabase مباشرة داخل features؛ UI يمر عبر Repository |
| الاختبارات | مجموعة أساسية | `flutter test` الكامل: 11 اختبارًا ناجحًا، مع اختبارات Draft وview buffer وحالة التاجر |
| الأصول المعبأة | أربعة أصول runtime معلنة فعليًا في pubspec + أربعة أوزان خطوط | نفس asset declarations المعبأة؛ لم تتم إضافة موارد ثقيلة بسبب المهام الـ35 |

## الفرق الحقيقي بعد المهام الـ35 في Release

لأن baseline السابق كان محسّن الحجم بالفعل، فالتغيير المقاس بين `size_optimized` والنسخة الحالية صغير:

| المقارنة | قبل المهام الـ35 | بعد المهام الـ35 | الفرق | النسبة |
|---|---:|---:|---:|---:|
| arm64-v8a | 21,000,058 bytes | 20,672,806 bytes | −327,252 bytes | −1.558% |
| x86_64 | 22,500,169 bytes | 22,172,917 bytes | −327,252 bytes | −1.454% |
| AAB | 57,110,915 bytes | 56,204,848 bytes | −906,067 bytes | −1.587% |

لا يصح نسبة كامل هذا الانخفاض الصغير إلى UI/UX وحده؛ ففحص المصدر أثبت عدم تغيير assets أو dependencies، والمكوّن الأكبر هو Flutter AOT/native libraries. قياس AAB يوضح أن base native libraries المضغوطة انخفضت من **25,369,099** إلى **24,931,963 bytes**، بينما بقي Flutter assets تقريبًا ثابتًا عند **868–869 KB مضغوطًا**. لذلك السبب المؤكد هو أن حجم الكود الأصلي/AOT والبناء الحالي أصغر قليلًا، مع بقاء المحرك هو المكوّن الأكبر.

## ما الذي يستهلك Release فعليًا؟

في arm64 الحالي:

| المكوّن | الحجم غير المضغوط |
|---|---:|
| `libflutter.so` | 11,747,528 bytes |
| `libapp.so` | 7,340,936 bytes |
| `libdatastore_shared_counter.so` | 7,112 bytes |
| **native libraries** | **19,095,576 bytes** |
| Flutter assets الكاملة | 1,769,691 bytes |
| DEX | 839,044 bytes |
| Android resources | 170,880 bytes |

في x86_64 يرتفع Flutter engine إلى **13,051,040 bytes**، ويرتفع `libapp.so` إلى **7,537,544 bytes**؛ لذلك يكون APK x86_64 أكبر من arm64 بنحو 1.5 MB تقريبًا. هذا متوقع بسبب اختلاف native Flutter engine بين ABIات.

في AAB الحالي توجد جميع ABIات الثلاثة في `base/lib` لأن Play يحتاجها ليولّد split delivery حسب الجهاز. كما توجد debug symbols في `BUNDLE-METADATA` بحجم مضغوط يقارب **29.16 MB**؛ هذه رموز رفع وتحليل أعطال وليست payload مثبتًا في APK المستخدم النهائي. لذلك لا ينبغي مساواة ملف AAB نفسه بحجم التثبيت على جهاز واحد.

## الحكم النهائي

ما تم اكتشافه هو الآتي:

1. الرقم الكبير **82.79 MB** كان ناتجًا أساسًا عن أربعة شعارات SVG ضخمة مكررة داخل Universal APK، وليس عن Flutter engine وحده.
2. الهبوط إلى **59.07 MB** حصل في تحسين الحجم السابق، قبل المهام الـ35، نتيجة حصر الأصول المعبأة في runtime logo واحد وأربعة أوزان خطوط.
3. المهام الـ35 لم تضف حجمًا خطيرًا؛ فقد حافظت على نفس dependencies وasset declarations، وأضافت وظائف وواجهات وعقودًا واختبارات.
4. الرقم الحالي **53.601 MiB** هو AAB، والرقم **19.715 MiB** هو arm64، والرقم **21.146 MiB** هو x86_64. هذه ليست ثلاث نسخ متناقضة، بل ثلاثة أنواع مخرجات مختلفة.
5. لا يجوز استخدام Debug البالغ **175.779 MiB** للحكم على حجم النشر؛ Debug يحمل kernel وvalidation layer وengine غير محسّن.
6. أصغر حجم عملي للمستخدم سيكون عبر AAB مع Play device-specific delivery، أو عبر APK split الخاص بـABI. لا يمكن جعل arm64 يساوي حجم AAB أو جعل Debug يساوي Release من دون تعطيل أدوات التطوير أو الوظائف الأصلية.

## الأدلة والملفات الخام

القياسات الخام محفوظة في `/home/ubuntu/size_components_report.tsv` و`/home/ubuntu/debug_components.tsv`، كما أن مخرجات البناء الحالية موجودة في `apps/mobile_flutter/build/app/outputs/`.

## المراجع المحلية

[1]: ../../assalkom_email_otp_release.apk "Pre-size raw APK"
[2]: ../../assalkom_email_otp_size_optimized_universal.apk "Pre-35 optimized universal APK"
[3]: ../../assalkom_email_otp_size_optimized.aab "Pre-35 optimized AAB"
[4]: ../../apps/mobile_flutter/build/app/outputs/bundle/release/app-release.aab "Current release AAB"
[5]: ../../apps/mobile_flutter/build/app/outputs/apk/release/app-arm64-v8a-release.apk "Current arm64 release APK"
[6]: ../../apps/mobile_flutter/build/app/outputs/apk/release/app-x86_64-release.apk "Current x86_64 release APK"
[7]: ../../apps/mobile_flutter/build/app/outputs/flutter-apk/app-debug.apk "Current debug APK"
