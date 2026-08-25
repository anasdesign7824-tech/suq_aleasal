# TASK 080 — دليل التقييم قيد المراجعة

## نطاق المهمة

تغطي المهمة نتيجة إرسال تقييم العميل: يظهر التقييم محليًا بعد نجاح الحفظ، ويُعرض بحالة pending واضحة إلى أن يعتمد، مع منع نشر تقييم فارغ أو ادعاء اعتماد غير مثبت.

## نتيجة جرد المصدر

المراجع `screens/080_state_review_pending.png` و`explanations/080_state_review_pending.md` غير موجودة في checkout الحالي، لذلك بقي القبول البصري محجوبًا ولم يُنشأ baseline بديل.

## نتيجة التدقيق

كان `ReviewsSection` يملك أصلًا عقد `ReviewStatus.pending`، ويعرض عبارة «قيد المراجعة؛ سيظهر للآخرين بعد الاعتماد.» لأي تقييم غير معتمد، كما يحدد SnackBar حالة النشر بحسب status. لم تثبت فجوة سلوكية إضافية تستوجب تعديل الإنتاج، لذلك اقتصر TASK 080 على إضافة اختبار مستقل وتوثيق السلوك الموجود، دون تغيير DB/API/RLS/permissions.

## الاختبارات

```text
flutter test --no-pub test/task080_review_pending_test.dart
00:27 +1: All tests passed!

flutter test --no-pub test/task016_product_detail_social_test.dart --plain-name 'TASK 016 submits a review and exposes pending moderation state'
00:04 +1: All tests passed!

flutter test --no-pub test/task097_social_accessibility_test.dart --plain-name 'review composer keeps publish disabled until text exists and gates retry'
00:13 +1: All tests passed!
```

يثبت الاختبار المستقل أن المستخدم المصادق عليه يستطيع إدخال تقييم، وأن زر النشر يمرر المسودة إلى `createReview`، ثم يظهر النص مع حالة pending وSnackBar المطابق. وتثبت regressions وجود حالة pending السابقة، وتعطيل النشر قبل إدخال النص، وحماية retry وسلوك الإرسال.

## القبول والحدود

القبول الوظيفي لحالة التقييم pending: **PASS**. القبول البصري: **BLOCKED** لفقدان PNG/Markdown TASK 080. لا يثبت ذلك اعتمادًا إداريًا أو مزامنة Production أو اختبارًا حيًا عبر أجهزة متعددة؛ لا تغييرات DB/API/RLS/permissions.
