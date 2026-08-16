# Merchant Experience & Store Opening Optimization — Discovery Report

**المشروع:** عسلكم — Souq Al Assal / سوق العسل

**النطاق:** Amendment لمسار المستخدم نفسه عند الانتقال إلى قدرة التاجر وفتح المتجر. لا ينشئ حسابًا أو تطبيقًا أو Login منفصلًا للتاجر، ولا يغيّر Flutter/Dart أو الهوية التجارية. هذا التقرير سابق لأي تعديل في كود التطبيق.

**مصادر القراءة:** Prompt التنفيذ المعتمد كاملًا، Amendment المرفق كاملًا، `yemeni_honey_master_database_final.json` كاملًا، migrations الحالية، عقود Dart، Repositories، Demo catalog، مسار Profile/BecomeMerchant، Merchant Dashboard، ومصفوفة التتبع.

## 1. القرار المعماري المثبت قبل التنفيذ

المستخدم يبقى هوية واحدة: `User → Open My Store → Merchant Capability`. سيبقى الاسم التجاري الظاهر **عسلكم**، بينما تبقى أسماء المشروع والهندسة **Souq Al Assal / سوق العسل**. لن تُنقل أي مسؤولية Supabase إلى Widgets، ولن يقود Schema تجربة المستخدم. المسار الإلزامي سيبقى:

```text
UI → ViewModel / Controller → Use Case → Repository Interface
   → Demo Repository / Production Repository → Data Source
```

سيتم الحفاظ على تجربة العميل الحالية التي تعمل، ثم دمج مسار التاجر معها بدل إعادة بناء ما هو ناجح بلا سبب. لا يوجد Checkout في هذا Amendment؛ الطلبات والتواصل والتسليم تبقى semantics المنصة الاجتماعية/التجارية.

## 2. خلاصة الحالة الحالية

| المحور | الموجود فعليًا | الحالة الحالية |
|---|---|---|
| نقطة الدخول | Profile يملك زر `كن تاجرًا` يفتح `BecomeMerchantScreen` | موجود لكنه ليس `فتح متجري` ولا Wizard |
| Store Creation | نموذج واحد من 6 حقول نصية تقريبًا: اسم النشاط، الهاتف، الخبرة، الموقع، التخصصات، ملاحظة شهادة | غير كافٍ؛ لا حفظ مرحلي ولا خطوات ولا استكمال لاحق |
| Merchant Dashboard | ملف `merchant_dashboard.dart` يعرض بطاقتين ثابتتين فقط لحالة التحقق والمنتجات | Stub/Placeholder وليس Dashboard قابلًا للعمل |
| Domain | `AssalMerchantApplicationDraft/Summary` فقط | لا توجد StoreDraft أو Wizard state أو Media/Document/Verification/ProductDraft/Analytics contracts |
| Repository | `submitMerchantApplication` فقط لطلب التحول | لا توجد create/update store/product، uploads، documents، verification، views، history، session restoration |
| Demo | In-memory session ومتابعات/محفوظات/طلبات/رسائل/إشعارات ومراجعات وتعليقات | جيد لمسار العميل الحالي؛ لا يخزن فتح متجر أو مسودة متعددة الخطوات أو وسائط أو منتجات التاجر |
| Production | `ProductionQueryGateway` وحدود قراءة وبعض update للإشعار | أغلب الكتابات والمصادقة وطلب التاجر ترجع `not configured` |
| المواقع | `AssalRegion` يدعم parent ID، لكن Demo catalog يملك 10 مناطق سطحية فقط | لا يوجد Governorate → District مصدر JSON ولا Cascading Selector |
| Taxonomy | المصدر المرجعي محمل في `references/data/yemeni_honey_master_database_final.json`، بينما Demo يحول بعض المنتجات إلى Taxonomy سطحية | المصدر غني؛ عقود UI الحالية لا تمثل hierarchy الكامل ولا global settings بصورة قابلة للإنشاء |
| Product creation | لا توجد شاشة أو عقد Create/Edit Product للتاجر | غير منفذ |
| Media | StoreProfile يقرأ URLs عامة موجودة في catalog، و`AssalImageTile` placeholder مرئي في onboarding | لا upload/preview/replace/delete/compression/progress/error storage |
| Documents | لا عقد ولا جدول ولا شاشة | غير منفذ |
| Verification | enum عام `VerificationStatus` وطلب تاجر `submitted` فقط | لا مراحل هوية/Selfie/Business ولا حالات Not Started/In Progress/Submitted/Under Review/Verified/Rejected/Requires Action |
| Analytics | `viewsCount` قراءة فقط داخل Product، ولا event tracking أو buffering | غير منفذ |
| History | لا recent views في Profile أو Repository | غير منفذ |
| Auth | Demo email/password typed، Google صريح غير متاح في Demo، Production provider غير مهيأ | لا session restoration حقيقي ولا Facebook boundary؛ Amendment يطلب Email ثم Google ثم Facebook |
| Profile | يملك إحصاءات متابعة/محفوظات/طلبات وروابط الإشعارات والإعدادات وكن تاجرًا | يحتاج مركز مستخدم كامل + Merchant mode/cards/history |
| DB/RLS | migrations تشمل stores/gallery/stats/products/images/taxonomy/regions/certs/delivery/pickup/handoff/social/admin/audit مع RLS أساسي | لا documents/identity/selfie/verification events/view events/view aggregates/history/draft checkpoints/storage policies المتخصصة |
| Admin | مشروع مستقل موجود لكن لا توجد في واجهته الحالية دلائل Merchant Verification/Product/Analytics قابلة للاستخدام | خارج التنفيذ الحالي؛ سنحافظ على contracts قابلة للإدارة لاحقًا |
| Tests | اختبارات customer journey/data/navigation/widget/catalog integrity موجودة وتمر وفق سجل المرحلة السابقة | لا اختبارات Wizard/media/location/product/verification/analytics/auth providers |

## 3. قاعدة البيانات المرجعية للعسل — نتيجة القراءة الفعلية

تمت قراءة `yemeni_honey_master_database_final.json` كاملًا، وليس التعامل معه كملف Demo عام. المصدر يحمل الإصدار `5.0.0` وتاريخ تحديث `2026-08-05`، ويحتوي على إعدادات عامة وأقسام هرمية.

| طبقة المصدر | المحتوى الفعلي |
|---|---|
| Global settings | 4 مستويات جودة، 5 badges/awards، 6 packaging units |
| Main categories | 5: العسل السائل، عسل الشمع، الخلطات العلاجية، منتجات النحل الخام، الهدايا والباكجات |
| Subcategories | 4 داخل قسم العسل السائل: السدر، السمر/الطلح، البيضاء/الباردة، التخصصية/النادرة |
| Canonical product entries | 30 معرفًا موزعة على الأقسام الخمسة، مع حقول تختلف حسب نوع المنتج |
| Product attributes | `grades`, `badges`, `tags`, `regions`, `description`, `components`, `purpose`, `forms` بحسب المنتج |
| Required modeling implication | لا يجوز بناء `HoneyProduct` مغلق؛ يجب أن يكون Product عامًا مع Category/Subcategory/Type/Attributes/Media/Pricing/Availability/Origin/Quality |

سيكون المصدر نفسه هو المرجع في Add/Edit Product وSearch وFilters وStore/Product pages وRecommendations والتهيئة المتوافقة مع Admin، مع الاحتفاظ بالمعرفات الأصلية وعدم اختراع Taxonomy موازية.

## 4. المحافظات والمديريات — نتيجة البحث وعدم التجاوز

المستودع الحالي لا يحتوي مصدرًا لمحافظات ومديريات اليمن؛ لديه 10 مناطق Demo سطحية فقط. تم البحث عن مصدر قابل للاستبدال، ووجدت مستودع `YemenOpenSource/Yemen-info` العام على GitHub، بترخيص MIT، وملف `yemen-info.json` يضم محافظات ومديريات وعُزل وقرى بالعربية والإنجليزية ومعرفات متداخلة. يذكر المصدر أنه أُنجز بحثه في فبراير 2024 ولا يضمن الدقة المطلقة، لذلك سيُستخدم في Amendment **للمحافظات والمديريات فقط** مع تسجيل المصدر والإصدار/commit، ولن تُضمّن العزل والقرى في selector.

لن تُكتب أسماء المحافظات أو المديريات داخل Widgets، ولن يُحفظ الاسم وحده. النموذج المطلوب هو `governorateId` ثم `districtId`، مع إعادة تحميل المصدر دون تعديل الكود، وSearchable Cascading Selector. قبل اعتماد الملف داخل المشروع، يجب تثبيت نسخة المصدر التي ستدخل Git وتسجيل commit/hash لها في manifest؛ هذا ليس تخمينًا أو بيانات مولدة.

## 5. الفجوات التنفيذية الجذرية

| ID | الفجوة | Root cause | Impact | Required change |
|---|---|---|---|---|
| G-001 | لا يوجد Store Creation Wizard | `BecomeMerchantScreen` نموذج أحادي الخطوة | لا يمكن إكمال فتح متجر احترافي أو حفظ التقدم | Wizard controller/state + 6–9 خطوات مترابطة مع validation وresume |
| G-002 | النموذج الحالي نصي وعشوائي | لا توجد Reference Catalog contracts | تخمين وتكرار وعدم توافق مع Admin | Dropdowns/searchable selectors/chips/structured fields من مصادر مركزية |
| G-003 | لا يوجد store draft/domain | عقد التطبيق صغير جدًا | لا persistence ولا edit/resume | Store draft/summary/media/location/delivery contracts |
| G-004 | لا يوجد Media pipeline | لا upload abstraction أو local demo media state | الأيقونة والغلاف والمعرض لا تعمل | Media repository، preview/replace/delete، compression boundary، progress/error/success |
| G-005 | لا يوجد governorate/district source | Demo regions سطحية | لا cascading selector ولا IDs | JSON source adapter وcascading searchable selectors |
| G-006 | لا يوجد delivery/pickup wizard | الموجود read-side summaries فقط | التاجر لا يضبط نطاق وخيارات الاستلام | Delivery/pickup drafts، skip/configure later، edit settings |
| G-007 | لا يوجد private documents | لا contracts/tables/storage policy | لا شهادات/PDF/هوية آمنة | Document model/upload state/private bucket contract/admin review state |
| G-008 | Verification مجرد status عام | لا stages ولا evidence model | لا flow هوية/Selfie/Business | Multi-stage verification domain مع الحالات السبع والمراجعة |
| G-009 | لا يوجد Product Creation | `AssalProductSummary` read model فقط | لا يستطيع التاجر إضافة/تعديل/نشر منتج | Generic ProductDraft wizard من taxonomy المرجعية |
| G-010 | لا Analytics event path | `viewsCount` رقم قراءة فقط | لا أرقام حقيقية أو dashboard | view event contract + throttle/batch/local buffer/deferred sync + aggregates |
| G-011 | لا history/session restoration | session in-memory فقط | فقدان الرحلة عند إعادة التشغيل | persistence boundary/cache/session restore/history contract |
| G-012 | Auth providers ناقصة | Demo/Production providers غير مهيأة | لا يمكن إثبات Email/Google/Facebook production | typed provider boundary، Demo behavior واضح، credentials/config gate |
| G-013 | Profile لا يميز merchant capability | Profile عميل فقط | لا متجر/منتجات/طلبات تاجر/توثيق/توصيل | Capability-aware Profile وMerchant home بعد store state |
| G-014 | لا load-on-demand للميزات الجديدة | repository الحالي read methods بسيطة | خطر فتح كل الاتصالات/تحميل كل البيانات | lazy feature loaders، pagination، debounce، cache وdeferred sync |
| G-015 | لا توجد اختبارات Amendment | suite الحالية لا تغطي التاجر العميق | لا دليل قبول حقيقي | unit/widget/repository/navigation/offline/error/loading/empty/upload/RTL/performance |

## 6. الموجود الذي يجب عدم كسره

يجب الحفاظ على Demo-first وGuest Discovery وProduct/Store public surfaces وRequest-not-Checkout وSocial mutations وNotifications lifecycle وRTL/IBM Plex Sans Arabic وDesign Tokens وResponsive Navigation وProduction Repository boundary. لا يُستبدل `AssalProductSummary` العام بعقد Honey-only، ولا تُنقل Supabase إلى Widgets، ولا تُحوّل البيانات التجريبية إلى ادعاء Production persistence.

## 7. الملفات المتوقع تأثرها

| الطبقة | الملفات الحالية | نوع التعديل المتوقع |
|---|---|---|
| Contracts | `packages/contracts_dart/lib/assal_domain.dart` | إضافة typed drafts/summaries للمتجر والمنتج والموقع والوسائط والوثائق والتحقق والتحليلات والتاريخ |
| Repository | `packages/data_dart/lib/assal_repository.dart` | إضافة use-case contracts create/update/resume/upload/verification/delivery/product/views/history/session |
| Demo | `packages/data_dart/lib/demo_repository.dart` و`apps/mobile_flutter/assets/demo_catalog.json` | Demo state حقيقي مترابط مع local drafts/media/doc/verification/product/view buffer |
| Production boundary | `packages/data_dart/lib/production_repository.dart` | mapping واضح إلى gateway مع أخطاء `not configured` الصريحة عند غياب مصدر مصادق |
| Reference assets | `references/data/` و`apps/mobile_flutter/assets/` | إضافة نسخة governorate/district الموثقة وcatalog adapter، دون نسخ taxonomy يدويًا داخل Widgets |
| Merchant UI | `apps/mobile_flutter/lib/features/merchant/merchant_dashboard.dart` وملف feature جديد | استبدال Stub بواجهة merchant capability وStore Wizard وProduct Wizard وmanagement screens |
| Account/Profile | `apps/mobile_flutter/lib/features/customer/customer_account.dart` و`customer_core.dart` | فتح متجري، profile capability cards، history/session/merchant state |
| App shell | `apps/mobile_flutter/lib/app/assal_app.dart` وrouting/config | route/state injection دون تغيير الهوية أو كسر guest flow |
| Database compatibility | `database/migrations/` | لا migration قبل مراجعة GAP→ROOT CAUSE→IMPACT؛ لاحقًا migrations additive للوثائق والتحقق والتحليلات عند اعتماد Backend |
| Tests | `apps/mobile_flutter/test/` و`packages/*/test/` | إضافة acceptance coverage لكل Task |
| Evidence | `docs/evidence/` و`docs/requirements_traceability.md` | سجل What changed/Why/Verification/Tests/Remaining لكل دفعة |

## 8. خطة التنفيذ المرحلية — 12 Tasks كما طلب Amendment

كل Task يمر حرفيًا بالتسلسل: **PLAN → IMPLEMENT → RUN → VERIFY → TEST → VISUAL CHECK → ARCHITECTURE CHECK → FIX → RETEST → EVIDENCE**. لا ينتقل التنفيذ إلى Task التالي قبل نجاح بوابة السابق.

| Task | النطاق | أهم المخرجات | بوابة الانتقال |
|---|---|---|---|
| 1 | Taxonomy + Governorates/Districts | canonical reference adapters، hierarchy، searchable cascading selectors، IDs | integrity tests وعدم وجود hardcoded selector values |
| 2 | Merchant Identity + Store Wizard | one-user capability، identity/business/location/experience steps، draft/resume/validation | journey test من Profile إلى draft submitted |
| 3 | Store Media + Store Profile | avatar/logo/cover/gallery، preview/replace/delete/progress/errors، public mapping | media state tests وstore profile regression |
| 4 | Delivery + Pickup | configure/skip/later، points/methods/fees/notes، edit settings | delivery/pickup/request display tests |
| 5 | Documents + Verification | private docs/PDF/images، identity front/back/selfie، business evidence، seven statuses | status transition/security contract tests |
| 6 | Product Creation + Taxonomy Selectors | generic ProductDraft، add/edit/review/publish، source taxonomy | product CRUD demo journey and canonical ID tests |
| 7 | Authentication + Session Synchronization | email/Google/Facebook boundaries، restore profile/favorites/follows/history/store/products/messages/notifications/settings | provider/config gates + restore tests |
| 8 | Profile + Favorites + History | full social profile، merchant mode، recent views، favorites/follows/reviews/comments/requests/messages | profile navigation/data tests |
| 9 | Views Analytics | store/product/content event contracts، dedupe/throttle/batch/local buffer/deferred sync، merchant read models | deterministic analytics tests, no fake Production metrics |
| 10 | Performance + Lazy Loading + Caching | on-demand loaders، pagination، debounce، local cache، no eager all-connections boot | performance/static checks and loading state tests |
| 11 | Admin compatibility + RLS + Data Contracts | contract parity and additive migration plan; no Admin redesign in this package | static contract audit; Backend/RLS remains gated by real source |
| 12 | Full Integration Testing | customer+merchant Demo journey، errors/loading/empty/upload/RTL/keyboard/build/Mimo | full acceptance matrix and evidence report |

## 9. تعارضات وقرارات لا يجوز تخمينها

| Conflict | Root cause | Impact | Recommendation |
|---|---|---|---|
| Prompt الأصلي يذكر Email/Password وGoogle فقط، Amendment يطلب Email ثم Google ثم Facebook | Amendment أحدث ومحدد لمسار المصادقة | Facebook provider غير موجود ولا يمكن إعلان Production PASS بلا إعداد | نضيف typed Facebook boundary ونُبقي Demo/Production غير متاحين بوضوح حتى تُسلّم إعدادات provider؛ لا ندعي نجاحًا حقيقيًا |
| المصدر المرجعي الخارجي يصرح بأنه غير مضمون الدقة ومؤرخ 2024 | لا يوجد مصدر جغرافي داخل repo | تخزين location IDs يحتاج provenance | نعتمد نسخة مثبتة بcommit/hash للمحافظات والمديريات فقط، ونوثق التحذير؛ لا نخلطها مع regions honey source |
| DB الحالية فيها stores/products لكن لا evidence/private verification/views | schema سبق customer package ولا يغطي Amendment | UI وحده لا يحقق security/analytics | لا نوسع schema عشوائيًا؛ بعد contract review نضيف migrations additive فقط عند بدء Backend/RLS task |
| المستخدم طلب تنفيذًا حرفيًا، لكن Production OAuth/Storage credentials غير موجودة في repo | إعدادات خارجية لازمة | لا يمكن إثبات real Google/Facebook/uploads | ننفذ Demo والحدود typed دون تجاوز، ونوقف بوابة Production عند هذه الاعتمادات بدل fake success |

## 10. الاعتمادات المطلوبة قبل إغلاق Production Gate

لا يمنع غياب هذه القيم بدء Discovery أو تنفيذ Demo/local contracts، لكنه يمنع إعلان Production PASS: إعدادات Email Auth، Google OAuth، Facebook OAuth، Supabase Auth/Storage، bucket الخاص والـ policies، وآلية camera/file picker الخاصة بالمنصة إن كان الالتزام بـ Selfie Capture الحقيقي مطلوبًا. عند الوصول إلى هذه الخطوات لن تُستبدل بإعدادات وهمية؛ سيُطلب توفيرها أو سيُسجل القرار كـ blocked مع الدليل.

## 11. حالة التقرير

هذا التقرير هو **Discovery فقط**، ولم تُعدّل ملفات التطبيق أو العقود أو migrations لتنفيذ Amendment بعد. الخطوة التالية المصرح بها هي مراجعة التقرير واعتماد مصدر المحافظات والمديريات وتأكيد التعامل مع بوابات OAuth/Storage الخارجية، ثم بدء Task 1 وحده وفق دورة التنفيذ المحددة.
