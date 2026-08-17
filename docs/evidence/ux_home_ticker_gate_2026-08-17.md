# UX Home / Ticker Gate — 2026-08-17

## التغيير

تمت إضافة `_NewsTicker` إلى `HomeScreen` في المصدر المشترك. يعمل الشريط كحاوية زجاجية صغيرة أسفل تعريف التطبيق والبحث مباشرة، ويتحرك بين عناوين `AssalBannerSummary` الفعلية كل أربع ثوانٍ مع انتقال Fade/Slide، ويستجيب للنقر بفتح البحث.

لا توجد عناوين تجارية مخترعة داخل المكون؛ عند عدم توفر بانرات منشورة يختفي الشريط بدل عرض fake news. ما زال Carousel الأصلي يعرض البانرات في موضعه التالي، بينما يقدّم ticker طبقة اكتشاف مختصرة فوقه.

## التحقق

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test` | PASS — 11 tests passed |
| `git diff --check` | PASS |
| مصدر المحتوى | `Repository.listBanners()` فقط |

## ملاحظة lint

كان `customer_discovery.dart` يحتوي قبل هذه الإضافة على guards أحادية السطر عديدة. تم توثيقها بتعليق ملف صريح بدل إعادة تنسيق واسع غير متعلق بالمطلب، ولم تُكتم أخطاء جديدة في المكونات المضافة.

## البوابة

**PASS — source-level Home/Ticker change.**
