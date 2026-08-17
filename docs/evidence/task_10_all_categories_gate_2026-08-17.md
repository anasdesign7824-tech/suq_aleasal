# Task 10 — جميع الأقسام يجب أن تظهر

## Task Scope

إظهار جميع الأقسام الرئيسية المتاحة من المصدر الفعلي، مع فصلها عن `honey_taxonomy` الفرعي، وتمكين المستخدم من فتح منتجات القسم عبر `category_id` بدل عرض مجموعة مختصرة أو قائمة ثابتة داخل الواجهة.

## Existing State

كانت `CategoriesScreen` تستدعي `listTaxonomy()` فقط، وكانت تعرض taxonomy/subcategory rows. هذا لا يضمن ظهور الأقسام الرئيسية الواردة في المنتجات أو فتحها بمعرف category.

## Changes

تم تنفيذ عقد موحد جديد:

- `AssalCategorySummary` في `packages/contracts_dart` مع id/name/description/productType/productCount.
- `AssalRepository.listCategories()` في عقد البيانات.
- `DemoRepository.listCategories()` يقرأ كل `category_id` و`category_name_ar` من المنتجات الموجودة في `demo_catalog.json` ويحسب عدد المنتجات لكل قسم.
- `ProductionRepository.listCategories()` يقرأ جدول `categories` النشط من مصدر Production، دون قائمة يدوية داخل Widget.
- `CategoriesScreen` أصبحت تستدعي `listCategories()` وتعرض كل قسم مع أيقونة نوع المنتج وعدد المنتجات.
- `SearchScreen` يدعم `initialCategoryId` ويمرره إلى `AssalProductQuery.categoryId`، مع بقاء `initialSubcategoryId` للتصنيفات الفرعية.

## Files Changed

| الملف | التغيير |
|---|---|
| `packages/contracts_dart/lib/assal_domain.dart` | إضافة `AssalCategorySummary` |
| `packages/data_dart/lib/assal_repository.dart` | إضافة `listCategories()` |
| `packages/data_dart/lib/demo_repository.dart` | تنفيذ المصدر Demo من الكتالوج الفعلي |
| `packages/data_dart/lib/production_repository.dart` | تنفيذ المصدر Production من جدول categories |
| `apps/mobile_flutter/lib/features/customer/customer_discovery.dart` | CategoriesScreen وSearchScreen category route |
| `docs/evidence/task_10_all_categories_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

ظهرت مشكلة compile واحدة أثناء التنفيذ لأن `_productType` helper خاص بعقد domain وغير متاح في package data؛ تم تشخيصها وإصلاحها بتحويل محلي صريح `_demoProductType` ثم أعيدت كل الفحوص بنجاح.

## Runtime Verification

تم التحقق من مسار CategoriesScreen/SearchScreen في Flutter navigation tests، وبقاء فتح البحث والتصنيف الفرعي سليمًا، مع إضافة مسار category الرئيسي دون تغيير Auth أو Home shell.

## Visual Verification

كل قسم يظهر في Card مستقل مع icon مناسب لنوع المنتج، الاسم العربي، وصف مصدره، عدد المنتجات، وسهم انتقال. لا توجد قائمة category ثابتة مكتوبة يدويًا داخل الواجهة.

## Architecture Verification

UI يعتمد على `AssalRepository.listCategories()`، وDemo/Production يقدمان نفس العقد. لا توجد قراءة JSON مباشرة داخل Widget، ولا اتصال Supabase داخل شاشة التصنيفات.

## Data / Contract Verification

قسم المنتج الرئيسي يمرر `categoryId`، بينما taxonomy الفرعي يمرر `subcategoryId`. هذا يحافظ على الفرق الدلالي بين القسم الرئيسي والتصنيف الفرعي ويمنع خلط المسارين.

## Regression Verification

نجحت اختبارات التنقل وطبقة البيانات ورحلة العميل. لم تُحذف أي منتجات أو فئات من Demo Catalog، ولم تتغير قواعد Honey Master أو Auth OTP.

## Remaining Issues

الـProduction path يتطلب وجود جدول `categories` وحقوله المتوافقة في Supabase؛ إذا كان الجدول غير منشور فستظهر رسالة schema واضحة بدل اختلاق أقسام محلية. كما أن جودة أسماء الأقسام في Demo تعتمد على `category_name_ar` الموجود في الكتالوج، ولا يُسمح بتصحيحها بحذف السجلات في هذه المهمة.

## Final Gate

**PASS** — أصبحت الفئات الرئيسية تُقرأ من المصدر وتظهر في شاشة مخصصة، مع مسار بحث category مستقل، بينما بقيت taxonomy الفرعية متاحة لمسارها الأصلي.
