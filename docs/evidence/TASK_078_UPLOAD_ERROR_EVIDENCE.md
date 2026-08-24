# TASK 078 — دليل فشل رفع الصور والملفات

## نطاق المهمة

تغطي المهمة رفض الامتدادات غير المدعومة في رفع صور التاجر والمتجر والمنتج، وتحويل فشل التحقق إلى حالة عربية صادقة لا إلى نجاح وهمي أو استثناء غير معالج.

## نتيجة جرد المصدر

المراجع `screens/078_state_upload_error.png` و`explanations/078_state_upload_error.md` غير موجودة في checkout الحالي، لذلك بقي القبول البصري محجوبًا ولم يُنشأ baseline بديل.

## الفجوة المثبتة والإصلاح

كان `uploadProductImage` يحول أي امتداد غير `png` إلى `jpg` بصمت، كما كانت مسارات الرفع تحتاج إلى ضمان موحد بأن `FormatException` الناتج عن سياسة التخزين لا يتسرب كاستثناء. كان `SupabaseQueryGateway` يطبق التحقق من الامتداد والتوقيع والحجم، لكن `ProductionRepository` لا يحول رفض التحقق إلى `AssalError` موحد.

أصبحت دوال رفع صور التاجر والمتجر والمنتج تستخدم `normalizePublicImageExtension` بدل fallback صامت. وأضيف فرع `FormatException` إلى `_write` يعيد `AssalErrorKind.validation` وcode=`upload_validation_failed` ورسالة عربية واضحة مع `retryable=false`. لا تغيير DB/API/RLS/permissions، ولم يتغير التحقق الأمني في gateway.

## الاختبارات

```text
flutter analyze --no-pub
No issues found!

flutter test --no-pub test/task078_upload_error_test.dart
00:03 +2: All tests passed!

flutter test --no-pub test/data_layer_test.dart --plain-name 'Factory rejects production without an explicit gateway'
00:03 +1: All tests passed!

flutter test --no-pub test/data_layer_test.dart --plain-name 'ProductionRepository maps image uploads to public prefixes and DB rows'
00:02 +1: All tests passed!
```

يثبت الاختبار الجديد رفض `gif` في رفع صورة التاجر والمتجر والمنتج، وعدم استدعاء الرفع أو إدخال صفوف قاعدة البيانات، وعودة حالة validation قابلة للعرض. ويثبت regression data layer أن المسار المدعوم ما زال يوجه الصور إلى prefix العام ويسجل صف قاعدة البيانات كما كان.

## القبول والحدود

القبول الوظيفي لمسار الرفض والتحقق: **PASS**. القبول البصري: **BLOCKED** لفقدان PNG/Markdown TASK 078. لا يثبت الاختبار رفعًا حيًا إلى Storage أو سلوك picker على جهاز حقيقي أو موافقة RLS في Production.
