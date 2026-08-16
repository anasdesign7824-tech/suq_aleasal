# Repository Inventory — Baseline

**Baseline commit:** `f65f1c0` بعد تثبيت Authority Baseline.

## صورة المستودع

المستودع ليس مشروعًا فارغًا؛ هو monorepo يحتوي تطبيق Flutter للعميل، packages Dart للعقود والبيانات ونظام التصميم، مشروع Admin Web قائم، مجلد Landing مؤجل، migrations وverification artifacts، ومراجع الهوية والبيانات.

| المسار | الغرض | الحالة عند baseline | قرار التنفيذ |
|---|---|---|---|
| `apps/mobile_flutter` | Customer Flutter Web/APK وMerchant capability | يعمل Demo ومسارات العميل الأساسية؛ merchant dashboard Stub | الحفاظ على Customer وإكمال Merchant داخل نفس codebase |
| `packages/contracts_dart` | Domain contracts | read models واسعة؛ Merchant creation/verification/product drafts ناقصة | إضافة عقود typed تدريجيًا دون ربط Flutter/Supabase |
| `packages/data_dart` | Repository interfaces وDemo/Production | Demo غني؛ Production gateway boundary وكتابات قليلة/غير مهيأة | توسيع interfaces وDemo أولًا ثم Supabase data source |
| `packages/design_system/dart` | tokens/typography/colors/radii/spacing | موجود ويُستخدم | لا Brand redesign؛ تحسين داخل tokens فقط |
| `packages/contracts_ts` و`packages/data_ts` | عقود/بيانات Web | موجودة كحدود عامة | مواءمة دلالية مع Dart دون خلط الطبقات |
| `packages/demo_data` | Demo resources | موجود | توحيد fixtures وعدم ادعاء Production persistence |
| `apps/admin_web` | Admin Web محلي | React/Vite shell وHome تعمل على `demoCatalog`؛ لا Auth/DB/Storage حقيقي | استبدال Demo data source تدريجيًا، مع إبقاء shell والهوية القابلة للمراجعة |
| `apps/landing_web` | Landing public | README فقط عند baseline | خارج الإطلاق الحالي؛ لا يحجب Customer/Admin acceptance |
| `database/migrations` | Supabase schema/RLS | migrations `0001`–`0006` موجودة مع طبقات أمن أساسية | مراجعة أولًا ثم migrations additive، لا schema عشوائي |
| `database/verification` | مخرجات تحقق schema | counts/profile cards موجودة | إعادة التشغيل بعد كل migration ذات صلة |
| `references/data` | مصادر taxonomy والبيانات المرجعية | `yemeni_honey_master_database_final.json` موجود | canonical source للمنتج/التصنيف، مع provenance |
| `assets`, `references/brand`, `references/fonts`, `references/visual` | الأصول والخطوط والهوية | موجودة | لا نسخ بديلة أو brand drift |
| `docs` | architecture/requirements/evidence | غني بقرارات وتقارير سابقة | تحديث traceability/evidence بدل حذف التاريخ |

## Flutter Customer baseline

### نقاط الدخول

`apps/mobile_flutter/lib/main.dart` و`lib/app/assal_app.dart` هما boot shell. الميزات الحالية مجمعة في `features/customer/*` مع `features/merchant/merchant_dashboard.dart`، وليست بعد في بنية مجلدات `presentation/domain/data` الكاملة الموصوفة في architecture contract. لن يتم النقل الشامل؛ يُنقل feature فقط عند إضافة contract واختبار parity.

### ميزات مثبتة من سجل المرحلة السابقة

Home/hero carousel/popular searches/product rails/categories/search/honey filters/product detail/gallery/store profile/favorites/profile/notifications/settings/requests/messaging/reviews/comments ودعم RTL/responsive navigation وDemo catalog مترابط. هذه الميزات تدخل regression suite ولا تُستبدل بلا root cause.

### Merchant الحالي

نقطة الدخول الحالية من Profile إلى `BecomeMerchantScreen`، بينما `merchant_dashboard.dart` يعرض بطاقة حالة التحقق والمنتجات بصورة Stub. لا يوجد Store Creation Wizard، draft/resume، media pipeline، documents، verification evidence، product creation أو analytics path حقيقي.

## Admin baseline

`apps/admin_web/client/src/App.tsx` يربط `/` بـ `Home` و`/landing` بـ `Landing` و404. `Home.tsx` يعرّف `ViewKey` محدودًا إلى `overview/products/stores/requests` ويقرأ `demoCatalog` مباشرة من `client/src/data/demoCatalog.ts`. الأزرار الحالية تُظهر Demo toasts، وتعلن صراحة أن مصدر الإنتاج غير مفعّل. هذا مفيد كـ visual shell لكنه ليس Admin Production integration.

### Admin gaps

لا يوجد عند baseline Admin Auth/role guard، Supabase client boundary، Repository/Data Source، CRUD حقيقي، Storage upload، Banner management، Notification write path، Verification review، Users/Roles، RLS test harness، Audit Log integration أو production error/loading/empty states. المطلوب هو توسيع الموجود، لا إنشاء لوحة ثانية.

## Database baseline

المigrations الحالية تُراجع في Task 3/6/14–15 قبل أي إضافة. وجود جداول stores/products/regions/admin لا يثبت اكتمال Merchant/Verification/Analytics/Storage. أي نقص يمر بصيغة `GAP → ROOT CAUSE → IMPACT → REQUIRED CHANGE`، ثم migration additive مع verification.

## الاختبارات والوثائق

| الفئة | الموجود |
|---|---|
| Flutter tests | customer journey، data layer، demo catalog integrity، navigation، widget boot |
| Evidence | customer app evidence، GO memo، release manifest، phase reports، discovery، battle-test plan |
| Missing battle evidence | Auth cross-platform، real upload، RLS matrix، pressure/performance، Admin sync، production-like E2E |

## حدود العمل الناتجة من الجرد

1. لا نعيد بناء Customer UI الحالي؛ نثبت regression ثم نوسّع العقود.
2. لا نقرأ `demoCatalog` مباشرة داخل Admin بعد إنشاء Data Source؛ ذلك انتقال تكاملي مقصود.
3. لا نضع Supabase داخل Flutter Widgets أو React pages؛ نستخدم client adapters/repositories.
4. لا نفتح RLS/Storage للعامة لتجاوز غياب Admin integration.
5. لا نعلن إطلاقًا قبل Auth وStorage وRLS وBattle-Test، حتى لو بقي Landing مؤجلًا.

## بوابة Task 2

Inventory مكتمل وقابل للتتبع عند baseline `f65f1c0`. الخطوة التالية هي توحيد Discovery/Traceability وحدود البيئات، ثم تنفيذ Auth/Storage بعد تسجيل كل blockers الخارجية.
