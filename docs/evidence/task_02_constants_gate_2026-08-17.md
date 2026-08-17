# Task 02 — ثوابت لا يجوز تغييرها

## Task Scope

التحقق من بقاء اسم عسلكم، الاسم الهندسي Souq Al Assal، الشعار المعتمد، الألوان، الخط، RTL، Design Tokens، Flutter/Dart، Feature architecture، Repository abstraction، Demo-first، Production boundary، وتجربة المستخدم العاملة دون Brand Redesign.

## Existing State

الثوابت موجودة في `AssalColors` و`AssalSpacing` و`AssalRadius` و`AssalTypography` داخل حزمة `assalkom_design`، ويستخدم `AssalApp` locale عربية و`Directionality.rtl`، ويستخدم الثيم خط IBM Plex Sans Arabic. الأصول runtime والخطوط الأربعة المطلوبة موجودة في `pubspec.yaml`.

## Changes

لم يُدخل Task 02 أي تغيير على كود التطبيق أو الثوابت؛ تم اعتماد التدقيق فقط لأن القيم الحالية متوافقة مع عقد الهوية. أثناء تشغيل Flutter قام tooling بإضافة exclude تلقائيًا إلى `analysis_options.yaml`، فتمت إعادته فورًا إلى النسخة المتتبعة لأنه خارج النطاق.

## Files Changed

لا توجد ملفات مصدر كودية معدلة في Task 02. أُضيف هذا الدليل فقط.

## Tests

تم تشغيل:

| الفحص | النتيجة |
|---|---|
| Required runtime identity assets/fonts | PASS |
| فحص عدم وجود Provider UI Google/Facebook في `apps/mobile_flutter/lib` | PASS ضمن نطاق المهمة الحالي |
| فحص تعريف الخطوط | IBM Plex Sans Arabic فقط في الثيم والتوكنز |
| `flutter analyze` | PASS — No issues found |
| `flutter test` | PASS — 9 tests passed |
| `git diff --check` بعد تنظيف أثر tooling | PASS |

الفحص المرئي للكود أكد أن `AssalBrandMark` يستخدم `AssalAssets.logoInternal`، وأن الألوان والمسافات والزوايا والطباعة تأتي من التوكنز. الأيقونة الخارجية ما زالت معرفة مركزيًا في `AssalAssets` لكنها غير معلنة runtime في `pubspec.yaml`؛ سيُعالج ذلك في مهام الأيقونات والأصول، لا باعتباره تغييرًا في الثوابت.

## Runtime Verification

لم يتغير runtime في هذه المهمة. تم تشغيل الاختبارات البرمجية بنجاح، ويظل Demo وProduction boundary كما هو: `AssalHomeShell` يهيئ Demo Repository عند عدم تمرير Production Repository، و`AssalApp` يفرض Arabic/RTL.

## Visual Verification

تمت مراجعة الثيم والمكونات المشتركة: الألوان الدافئة، IBM Plex Sans Arabic، Material 3، خلفية عسلكم، الحواف، وحالات Glass Loading موجودة. لم يُعاد تصميم العلامة ولم تُبدّل الألوان أو الخطوط.

## Architecture Verification

بقيت الحدود كما هي: `UI → Repository contract → Demo/Production source`. لم يُوضع Supabase داخل Widgets، ولم يُنشأ تطبيق تاجر أو تسجيل دخول منفصل، ولم تتغير حزمة Flutter/Dart أو Feature architecture.

## Data / Contract Verification

لم تتغير العقود أو JSON أو migrations. ظل Honey Master وLocation source وDemo Catalog خارج التعديل، وظلت القيم المرجعية والخطوط والأصول مسجلة مركزيًا.

## Regression Verification

`flutter analyze` و9 اختبارات نجحت، ولم يبق diff مصدر بعد إرجاع تعديل tooling التلقائي. لا يوجد كسر مثبت في Customer أو Demo أو Authentication نتيجة Task 02.

## Remaining Issues

توجد ملفات artifacts محلية غير متتبعة من جلسة سابقة في جذر المستودع، ويجب إبقاؤها خارج commits. الأيقونة الخارجية ومسارات Demo Catalog القديمة تحتاج معالجة مستقلة في مهام الأصول/الهوية اللاحقة. هذا لا يغيّر ثوابت الهوية الحالية.

## Final Gate

**PASS** — تم تثبيت الثوابت وعدم إدخال Brand Redesign أو تغيير معماري، مع نجاح analyze والاختبارات وتنظيف الأثر الجانبي.
