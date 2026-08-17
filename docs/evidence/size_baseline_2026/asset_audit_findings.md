# نتائج جرد الأصول والاستخدام — 2026-08-17

## الاستخدام الفعلي في Flutter

`apps/mobile_flutter/lib/core/assal_assets.dart` يعرّف فقط:

- `logoInternal = 'assets/logo-internal-runtime.svg'`
- `logoExternal = 'assets/logo-external-runtime.svg'`
- `demoCatalog = 'assets/demo_catalog.json'`

ويستخدم `assal_widgets.dart` `SvgPicture.asset(AssalAssets.logoInternal)`. لم يظهر في كود Flutter runtime مرجع مباشر إلى النسخ الأصلية `logo-internal.svg` أو `logo-external.svg`؛ ظهرت مراجعها في أدوات توليد Demo وملفات البيانات والتوثيق، لا في widget runtime مباشر.

## نتيجة مقارنة النسخ

النسخ الأصلية وruntime ليست متطابقة byte-for-byte لأن أداة `prepare_runtime_svg.py` تزيل تعريفات `<filter>` فقط. البصمات مختلفة، لكن كل زوج يحتفظ بصورتهما المضمنة نفسها تقريبًا:

- `logo-internal.svg`: 7,940,482 بايت، filter_count=2.
- `logo-internal-runtime.svg`: 7,940,041 بايت، filter_count=0.
- `logo-external.svg`: 7,937,603 بايت، filter_count=2.
- `logo-external-runtime.svg`: 7,937,162 بايت، filter_count=0.

## سبب التضخم داخل SVG

كل SVG يحتوي على صورتين PNG مضمنتين بصيغة base64:

| الزوج | الصورة 1 decoded | الصورة 2 decoded | مجموع PNG الخام التقريبي |
|---|---:|---:|---:|
| internal | 904,735 بايت | 5,048,115 بايت | 5,952,850 بايت |
| external | 904,740 بايت | 5,045,551 بايت | 5,950,291 بايت |

إزالة filters خفضت أقل من 500 بايت فقط لكل runtime SVG، لذلك لم تكن معالجة filters حلًا حقيقيًا. التضخم الحقيقي هو تكرار PNG المضمنة داخل أربعة ملفات SVG، ثم تكرار ABI native داخل Universal APK.

## قرار التحسين

لا يجوز حذف أي ملف قبل تحديث كل مراجع runtime والـDemo واختبار الهوية. لكن ثبت أن النسخ الأصلية غير مطلوبة من Flutter runtime المباشر، وأن زوج runtime هو الذي يُستخدم في `AssalAssets`. الخطوة الآمنة التالية هي بناء نسخة runtime محسّنة lossless من كل زوج، ثم تعديل pubspec/مراجع البيانات أو فصل مراجع Demo التي لا تُحمّل كأصول فعلية، ثم قياس APK قبل اعتماد الحذف.

لن تُحذف صور الهوية أو تُستبدل بجودة أقل. سيتم أولًا اختبار إمكان تقليل PNG losslessly، أو استخراج أصل واحد مطلوب فعليًا من شعار runtime مع الحفاظ على المظهر في كل سياق، ثم مقارنة screenshot وhash والحجم.

## مرشحو الدقة المناسبة

تم إنشاء مرشحين lossless-per-context من `logo-internal-runtime.svg` بعرض 1024 و512 بكسل. المرشح 1024 حجمه 426,517 بايت بدل 7,940,041 بايت، والمرشح 512 حجمه 154,643 بايت. أداة الإنشاء أعادت فك PNG بعد التحجيم وتحققت من الحجم والنمط وعدم تلف payload. فحص إحصاءات البكسلات أثبت أن المرشح 1024 يحتفظ بتوزيع الألوان وnon-black bounding box المتوقع؛ ظهور شاشة سوداء في عارض SVG العام لا يكفي لرفضه، وسيُحسم القرار باختبار Flutter/Android ولقطة شاشة فعلية.

بما أن أكبر عرض مؤكد في `AssalBrandMark` هو 66 logical pixels، فإن 1024 pixels يعطي هامشًا كبيرًا لشاشات high-density، بينما 512 يعطي حجمًا أصغر بكثير. لن يُعتمد أحدهما قبل اختبار العرض في APK.
