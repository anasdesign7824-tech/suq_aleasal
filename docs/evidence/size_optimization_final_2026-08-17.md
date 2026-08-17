# تقرير تحسين حجم تطبيق عسلكم — قبل/بعد

**التاريخ:** 17 أغسطس 2026
**الحزمة:** `com.assalkom.assalkom`
**نوع البناء:** Flutter Release، debug signing مؤقت، مع builds منفصلة حسب ABI وAAB

## الحكم التنفيذي

تم تنفيذ تحسينات الحجم من مصدر التضخم الحقيقي، دون حذف وظائف التطبيق أو فصل البيانات التشغيلية عن مصدرها. أكبر سبب كان وجود صور PNG ضخمة مضمّنة بصيغة Base64 داخل أربعة ملفات SVG، مع إعلان مجلد الخطوط كاملًا رغم استخدام أربعة أوزان فقط. أزيلت الشعارات غير المستخدمة من `pubspec.yaml`، واستُخدمت نسخة runtime lossless بدقة مناسبة (`1024px`) للشعار المستخدم، وحُصر IBM Plex Sans Arabic في الأوزان المستخدمة فعليًا: Regular وMedium وSemiBold وBold.

> النتيجة: انخفض Universal APK من **82,786,915** إلى **59,069,723** بايت، أي تخفيض **23,717,192** بايت / **23.717 MB** / **28.65%**. وانخفض AAB من **80,828,731** إلى **57,110,915** بايت، أي تخفيض **23,717,816** بايت / **23.718 MB** / **29.34%**.

## المقارنة الرقمية

| Artifact | قبل التحسين | بعد التحسين | التخفيض | النسبة |
|---|---:|---:|---:|---:|
| Universal APK | 82,786,915 B (82.787 MB) | 59,069,723 B (59.070 MB) | 23,717,192 B (23.717 MB) | 28.65% |
| AAB | 80,828,731 B (80.829 MB) | 57,110,915 B (57.111 MB) | 23,717,816 B (23.718 MB) | 29.34% |
| split `arm64-v8a` | — | 21,000,058 B (21.000 MB) | — | — |
| split `armeabi-v7a` | — | 18,654,436 B (18.654 MB) | — | — |
| split `x86_64` | — | 22,500,169 B (22.500 MB) | — | — |

الأرقام بوحدة MB عشرية (`1 MB = 1,000,000 B`) حتى تكون المقارنة ثابتة وقابلة لإعادة الحساب. Universal APK يضم مكتبات ABI الثلاثة، بينما Google Play مع AAB يسلّم الجهاز الموارد والمعمارية الملائمة فقط.

## ما تم تغييره وسبب ثبوت أمانه

| المجال | التشخيص | الإجراء | التحقق |
|---|---|---|---|
| SVG/PNG | أربعة SVG احتوت صور PNG مضمّنة بإجمالي يقارب 31.755 MB، وبعضها غير مستخدم في Flutter runtime | إزالة الإعلانات غير المستخدمة، واستبدال `logo-internal-runtime.svg` بنسخة lossless بعرض 1024px | الشعار ما زال داخل الحزمة، وentry النهائي حجمه 426,517 B |
| الخطوط | إعلان `assets/fonts/` كان يضم أوزان Thin وExtraLight وLight غير المستخدمة | إعلان أربعة ملفات TTF مستخدمة فقط | `unzip -l` النهائي يظهر Regular/Medium/SemiBold/Bold فقط |
| البيانات | الكتالوج وملف المحافظات صغيران وضروريان لـDemo/الواجهة الحالية | لم تُحذف بيانات تشغيلية؛ بقيت JSON الصغيرة فقط | entries النهائية: `demo_catalog.json` و`yemen_governorates_districts.json` |
| ABI | Universal يكرر native libraries لكل من arm64 وarmeabi-v7a وx86_64 | إنتاج split-per-ABI وAAB إلى جانب Universal | أحجام split مسجلة أعلاه |
| جودة الهوية | عدم استخدام ضغط lossy للشعار أو الصور التجارية | الإبقاء على SVG وPNG المضمّن lossless بدقة استخدام عملية | فحص بكسلات أداة إنشاء candidate محفوظ ضمن `tools/` |

## جرد الموارد النهائية داخل Universal APK

| المورد | الحجم غير المضغوط في ZIP |
|---|---:|
| `assets/logo-internal-runtime.svg` | 426,517 B |
| `assets/fonts/IBMPlexSansArabic-Regular.ttf` | 226,560 B |
| `assets/fonts/IBMPlexSansArabic-Medium.ttf` | 231,796 B |
| `assets/fonts/IBMPlexSansArabic-SemiBold.ttf` | 234,232 B |
| `assets/fonts/IBMPlexSansArabic-Bold.ttf` | 236,256 B |
| `assets/demo_catalog.json` | 147,760 B |
| `assets/yemen_governorates_districts.json` | 108,565 B |

لا تظهر في الحزمة النهائية الشعارات الثلاثة غير المستخدمة، ولا أوزان Thin أو ExtraLight أو Light. كما بقيت بيانات المتاجر/المنتجات التشغيلية قابلة للفصل والتحميل عند الطلب من المصدر الحقيقي، ولم تُحشَ قاعدة البيانات داخل APK.

## تحليل مكوّنات APK النهائي

أُعيد تشغيل `flutter build apk --release --analyze-size` بعد آخر تعديل، وحُفظ التحليل في:

`/home/ubuntu/.flutter-devtools/apk-code-size-analysis_03.json`

الملخص الأعلى مستوى لتحليل x86_64 النهائي:

| مكوّن | الحجم المحسوب |
|---|---:|
| native `lib` — x86_64 | 20,922,488 B |
| `assets` | 869,170 B |
| `classes.dex` | 380,119 B |
| `res/` | 128,667 B |
| `resources.arsc` | 90,860 B |
| Dart AOT symbols accounted decompressed size | نحو 7 MB |

الحجم الأكبر المتبقي هو Flutter engine/native runtime، وليس assets غير مستخدمة. وهذا متوقع في Flutter APK، ويُعالج على مستوى التوزيع باستخدام AAB وdevice-specific delivery، لا بحذف موارد لازمة أو تقليل جودة الهوية.

## التحقق الوظيفي بعد التحسين

| الفحص | النتيجة |
|---|---|
| تثبيت split `x86_64` النهائي على Mimo | PASS — `Success: streamed 22500169 bytes` |
| تشغيل `com.assalkom.assalkom` بعد التثبيت | PASS — PID ظهر، و`MainActivity` أصبحت Fully drawn خلال نحو 620 ms |
| `FATAL EXCEPTION` في آخر 300 سجل | لا توجد نتيجة مطابقة |
| `Unable to load asset` في آخر 300 سجل | لا توجد نتيجة مطابقة |
| وجود شعار runtime في APK | PASS |
| وجود الخطوط الأربعة المطلوبة فقط | PASS |
| اختبارات Flutter السابقة | PASS — `flutter analyze` بلا Issues و`flutter test` ‏9/9 |
| Demo Mode | PASS في الاختبارات السابقة — الرمز التجريبي `123456` مخصص للاختبار فقط |

## البصمات النهائية

| Artifact | SHA-256 |
|---|---|
| Universal APK | `e1032e25b9a792564647a9ac46e87fb198678d4cd234195cd3754d180c953966` |
| `arm64-v8a` APK | `4dbdc6ba18e7fdf175c8d9e4a702d08f421d3451174da4a8d7993a34d5c588e4` |
| `armeabi-v7a` APK | `20ff5b4a5116258c4e2a89b4998b4132a77ff06b888b77cc757aca9f350f0992` |
| `x86_64` APK | `093b7d2a0ec87258b0d86abaf92cd1590034c9a85d0258cacd354b14a10f1cfb` |
| AAB | `096edae1cc5b6f22167e4315da515b95b1591b309545466a0d85a88884119b59` |

## حدود الاعتماد قبل Google Play

هذه artifacts محسّنة وقابلة للاختبار، لكن التوقيع الحالي **Debug certificate** وليس upload keystore للإطلاق. قبل النشر يجب إنشاء release keystore خارج Git، بناء AAB موقّع به، تفعيل Play App Signing، ثم إعادة اختبار مسار البريد وOTP وحذف الحساب على Internal Testing. لا يُنشر الرمز التجريبي `123456` كمسار مستخدم إنتاجي.

## الملفات المرجعية

- `docs/evidence/size_baseline_2026/baseline_summary.md`
- `docs/evidence/size_baseline_2026/asset_audit_findings.md`
- `tools/analyze_svg_payloads.py`
- `tools/build_logo_runtime_candidate.py`
- `tools/optimize_embedded_logo_pngs.py`
- `tools/summarize_flutter_size.py`
- `/home/ubuntu/.flutter-devtools/apk-code-size-analysis_03.json`
