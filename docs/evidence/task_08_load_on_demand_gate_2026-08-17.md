# Task 08 — عدم فتح الاتصالات بلا حاجة

## Task Scope

تطبيق Load on Demand في Home/Discovery: عدم فتح طلبات المتاجر ورفوف المنتجات الثلاثة عند startup، واستخدام lazy/deferred loading مع ScrollController، مع الإبقاء على البيانات الضرورية للواجهة الأولى فقط.

## Existing State

كانت `_HomeScreenState._load()` تطلق ثمانية Futures دفعة واحدة: featured products، taxonomy، stores، banners، popular products، newest products، verified products، وnotifications، ثم تجعل `initialContentFuture` ينتظرها كلها قبل إظهار الصفحة.

## Changes

تم تعديل `customer_discovery.dart` كالتالي:

- تبقى Featured products وTaxonomy وBanners وNotifications ضمن Required/initial content.
- أصبحت Stores وPopular/New/Verified product rails nullable ولا تُنشأ في `_load()`.
- أُضيف `ScrollController` مع listener يبدأ deferred requests عند تجاوز 180px.
- أُضيف `_startDeferredData()` مع guard يمنع الإطلاق المتكرر.
- لا تظهر الرفوف المؤجلة قبل بدء deferred loading؛ وعند البدء تُرسم حالات loading عبر مكونات الرفوف.
- Refresh يعيد ضبط deferred state ويعيد إطلاق required data فقط، ثم يعيد تفعيل التحميل المؤجل عند التمرير.
- تم التخلص من `ScrollController` في `dispose`.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/features/customer/customer_discovery.dart` | Required/Deferred loading وScrollController وبدء الطلبات عند الحاجة |
| `docs/evidence/task_08_load_on_demand_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

## Runtime Verification

تم تشغيل اختبارات التنقل ورحلة العميل وطبقة البيانات بعد التعديل. Home تُبنى دون انتظار كل رفوف المنتجات والمتاجر، بينما تظل الشاشة قادرة على فتح StoresScreen مباشرة عند الضغط على عرض المتاجر، حيث يقوم المسار المطلوب بتحميل بياناته عند فتحه.

## Visual Verification

تظهر الصفحة الأولى بمحتوى Required، ثم تُضاف الرفوف المؤجلة عند التمرير. لا توجد شاشة فارغة أو انتظار شامل للبيانات المؤجلة؛ الرفوف تستخدم Glass Loading/State View الخاصة بها بعد بدء الطلب.

## Architecture Verification

التغيير بقي داخل Feature UI lifecycle ويستخدم `AssalRepository` الموجود. لا توجد Supabase calls جديدة داخل Widgets، ولا يوجد listener دائم أو اتصال global؛ الـScrollController محلي للشاشة ويتم التخلص منه.

## Data / Contract Verification

لم تتغير عقود `listStores` أو `listProducts`. تم الحفاظ على نفس queries والفرز وverified filters، لكن توقيت استدعائها أصبح deferred. Required data لا يعتمد على المتاجر أو الرفوف المؤجلة.

## Regression Verification

نجحت 5 اختبارات ولم يتغير Auth/OTP أو Customer journey. فتح StoresScreen/Search وProduct detail ما زال يستخدم Repository نفسه.

## Remaining Issues

لم تُضف Pagination حقيقية إلى Repository في هذه المهمة، لأن ذلك يحتاج توسيع Contract ومصدر Production؛ هذه مهمة مستقلة لاحقة. كما أن Notifications ما زالت تُجهّز للـheader لأنها جزء مرئي من required shell؛ يمكن تأجيلها أكثر في تحسين لاحق إذا أُضيف badge cache/refresh مستقل.

## Final Gate

**PASS** — الاتصالات الثقيلة لم تعد تُفتح دفعة واحدة عند startup، وأصبح Home يستخدم Required content ثم Deferred data عند التمرير دون كسر الرحلة الحالية.
