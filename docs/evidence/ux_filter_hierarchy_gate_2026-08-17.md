# UX Filter Hierarchy Gate — 2026-08-17

## التغيير

تم تعديل `SearchScreen._showFilters` في المصدر المشترك لإظهار:

- المحافظة ثم المديرية من `YemenLocationReference` مع إعادة تصفير المديرية عند تغيير المحافظة.
- القسم من `repository.listCategories()`.
- التصنيف الفرعي من `repository.listTaxonomy()`.
- نوع المنتج ودرجة الجودة والتوثيق والأصل والمعالجة والتعبئة والتوفر.
- RangeSlider للسعر وSlider للتقييم كما كانا.

اختيار القسم أو التصنيف الفرعي يكتب إلى `AssalProductQuery` عبر `categoryId` و`subcategoryId`، ولا توجد Taxonomy موازية داخل Widget. عند فشل جلب قوائم القسم/التصنيف تبقى النافذة قابلة للفتح بعنصر «الكل» بدل اختلاق خيارات.

## التحقق

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test` | PASS — 11 tests passed |
| `git diff --check` | PASS |
| مصدر الأقسام والتصنيفات | Repository/JSON فقط |

## البوابة

**PASS — source-level filter hierarchy.**
