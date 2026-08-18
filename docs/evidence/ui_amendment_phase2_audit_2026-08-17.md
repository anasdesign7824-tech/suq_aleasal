# تدقيق ما قبل تنفيذ UI/UX Amendment — 17 أغسطس 2026

## نطاق التدقيق

تمت مراجعة الملفين المرفقين من المستخدم، المرجع التنفيذي الأصلي، سجل سلطة الملفات، مصفوفة المتطلبات، التتبع الحالي، عقد نظام التصميم، العقود البرمجية، Demo Repository، Production Repository، ملفات Flutter الرئيسية، مصدر Honey Master كاملًا، ومصدر المحافظات والمديريات كاملًا. لم تُعدّل ملفات التطبيق أو migrations أثناء هذا التدقيق.

## مصادر السلطة والقرارات الملزمة

| المصدر | الدور | القرار المستخدم |
|---|---|---|
| `/home/ubuntu/upload/pasted_content_2.txt` | Amendment تحسينات العميل والتاجر والواجهة والبيانات | اعتماد كل بنوده ضمن حدود التطبيق الحالي |
| `/home/ubuntu/upload/pasted_content_4.txt` | حوكمة التنفيذ والبوابات | الحفاظ على 35 مهمة مستقلة، وعدم دمجها أو اختصارها، ودورة قبول مستقلة لكل مهمة |
| `references/instructions/execution-prompt.txt` | الرؤية والمعمارية والمنتج والاختبارات | منصة اجتماعية/تجارية للعسل اليمني، Demo-first، Repository boundary، RTL، لا Checkout تقليدي |
| `docs/design-system-contract.md` | الهوية المرئية | IBM Plex Sans Arabic، التوكنز، الألوان الدافئة، RTL، المكونات المشتركة، وعدم hard-code داخل الشاشات |
| `references/data/yemeni_honey_master_database_final.json` | Taxonomy canonical | الإصدار 5.0.0، التصنيفات والأنواع والدرجات والشارات والتغليف والمنتجات مصدر مرجعي لا يُختصر |
| `references/data/yemen_governorates_districts.json` | Location canonical | 22 محافظة و335 مديرية، بأكواد `YE-GOV-*` و`YE-DST-*`، دون عزل وقرى |

مصدر المحافظات يرجع إلى [YemenOpenSource/Yemen-info](https://github.com/YemenOpenSource/Yemen-info)، والملف المثبت يسجل commit المصدر `f0bd5b523d91861088ddc9c494c11eba1a60336f` وSHA-256 `49e265bc94726e83d6a67107f8195276616aa81b5fa1af028c25dbf2296c5a12`.

## تعارضات يجب ضبطها قبل التنفيذ

المرجع التنفيذي القديم يحتوي قرارات أقدم لـEmail/Password وGoogle، بينما ملف Amendment المقدم لاحقًا يثبت أن نطاق هذه الحزمة هو **Email + Verification Code فقط**، وقد تم تنفيذ وإغلاق هذا القرار في الحزمة السابقة. لذلك لن تُعاد Google أو Facebook إلى واجهة العميل أو إلى نطاق هذه المهام.

المستودع يحتوي وثائق خطة أقدم ذات 50/60 مهمة، لكن الملف المقدم من المستخدم يفرض صراحةً الحفاظ على **35 مهمة مستقلة** بنفس الترتيب وعدم إعادة تقسيمها. سيُستخدم سجل 35 مهمة كـTask Gates لهذه الحزمة، مع الاستفادة من الوثائق الأقدم كمراجع داخلية دون تحويلها إلى مهام جديدة أو دمج المهام المطلوبة.

## حالة المصدر عند بداية الحزمة

- المستودع: `anasdesign7824-tech/suq_aleasal`، الفرع `main`، آخر commit متزامن `7dde63d`.
- تغييرات البناء السابقة الخاصة بالحجم مدفوعة بالفعل؛ توجد artifacts وملفات محلية غير متتبعة في جذر المستودع، ولن تُدرج في commits اللاحقة إلا إذا كانت مطلوبة كإرفاق خارجي.
- Flutter/Dart وFeature architecture وRepository abstraction وDemo-first موجودة، لكنها جزئية حسب `docs/requirements_traceability.md`.
- شاشة العميل الحالية تشمل Home/Discovery/Categories/Search/Stores/Product/Store/Profile/Favorites/Requests/Messaging/Notifications/Settings، مع فجوات واضحة في selectors، merchant wizard، media، verification، generic product management، analytics، وAdmin integration.
- `merchant_dashboard.dart` لا يزال Stubًا، و`BecomeMerchantScreen` نموذجًا أحادي الخطوة، لذلك ستبقى المهام merchant مستقلة ولا تُعتبر مكتملة من وجود الملف فقط.

## تدقيق الأيقونات والشعارات

أرشيف `references/brand/app-icons-and-logos.zip` يحتوي أصلين كبيرين:

| الأصل المرجعي | الحجم في الأرشيف | الاستخدام المقصود |
|---|---:|---|
| أيقونة التطبيق الخارجية المربعة | 7,937,603 B | سطح المكتب/Launcher |
| شعار التطبيق الداخلي العرضي | 7,940,482 B | Splash، الموقع، والمواضع الداخلية العامة |

النسخة الحالية `assets/logo-internal-runtime.svg` ما زالت موجودة ومعلنة وتستخدمها `AssalAssets.logoInternal` عبر `AssalBrandMark`. حذف الإعلانات القديمة من `pubspec.yaml` طال ملفات غير مستخدمة، لكنه ترك مراجع قديمة داخل Demo Catalog مثل `assets/brand/logo-internal.svg`، كما أن `AssalImageTile` يعرض صور HTTP فقط ثم يسقط المسار المحلي إلى Material fallback. هذا يفسر اختفاء شعار العلامة في بعض البطاقات، مع بقاء الشعار الرئيسي ممكنًا في موضع `AssalBrandMark`.

التنفيذ المطلوب لاحقًا هو توحيد مسارات الأيقونة الداخلية والخارجية في `AssalAssets` ومكونات reusable، وعدم نسخ SVG داخل الشاشات، وإزالة النص المرئي المكرر «عسلكم» من موضع العلامة في الصفحة الرئيسية وتسجيل الدخول، مع إبقاء النصوص الوظيفية الأخرى. لا يجوز إعادة الأصول الكبيرة إلى الحزمة دون إثبات الحاجة؛ يجب أولًا فحص نسخة runtime ومحاذاة مواضع الاستخدام.

## Honey Master — نتيجة القراءة الكاملة

- `database_info.version = 5.0.0` و`last_updated = 2026-08-05`.
- `global_settings` يتضمن grading system من أربع درجات، خمس badges/awards، وست وحدات تغليف.
- المصدر يحتوي خمس فئات رئيسية، وفئات فرعية داخل قسم العسل السائل، ومنتجات سدر وسمر وأعسال بيضاء وتخصصية، وشمع، وخلطات علاجية، ومنتجات نحل خام، وهدايا/باكجات.
- يجب ألا يُحوّل إلى نموذج Honey-only مغلق أو إلى قائمة قسمين فقط؛ العقود الحالية تحتاج Adapter/Reference Repository أوسع عند إغلاق مهام taxonomy/product.

## نقاط الكود التي ستدخل التنفيذ لاحقًا

| المجال | الملف/الموضع الحالي | الملاحظة |
|---|---|---|
| العلامة الرئيسية | `apps/mobile_flutter/lib/core/assal_widgets.dart`، `AssalBrandMark` | يضيف `Text('عسلكم')` افتراضيًا بجانب SVG؛ يحتاج icon-only reusable API |
| أصول الهوية | `lib/core/assal_assets.dart` و`pubspec.yaml` | `logoInternal` موجود؛ `logoExternal` يشير إلى أصل غير معلن حاليًا؛ يحتاج توحيد وتصحيح |
| Home | `lib/features/customer/customer_discovery.dart`، `_Header` | يستخدم `const AssalBrandMark()` ويحمّل عدة استدعاءات Home عند البدء؛ يحتاج تحسين العلامة وLoad on Demand لاحقًا |
| Login/OTP | `lib/features/customer/customer_account.dart` | الشعار يظهر في شاشة الدخول وداخل Dialog OTP؛ OTP الحالي حقل واحد 6–9 أرقام بلا countdown/multi-cell/paste flow مكتمل |
| Search/Filters | `customer_discovery.dart` | الفلاتر تحتوي TextFields للأصل والمعالجة والتغليف والتوفر والسعر؛ المطلوب selectors/slider/canonical values |
| Stores | `customer_discovery.dart`، `StoresScreen` | قائمة بسيطة بلا بحث/فرز/فلترة مستقلة |
| Locations | `lib/core/yemen_location_reference.dart` | Loader/validator typed موجودان؛ المطلوب توصيلهما بالنماذج والـselectors بدل إعادة إنشاء المصدر |
| Demo | `packages/data_dart/lib/demo_repository.dart` | Demo mutations محلية، لكن taxonomy يستخرج من المنتجات لا من Honey Master canonical مباشرة |
| Production | `packages/data_dart/lib/production_repository.dart` | القراءة خلف Gateway، لكن كثير من الكتابات والرسائل والإعجابات والمؤثرات الإنتاجية غير مهيأة وتُرجع BLOCKED/Error صريحًا |
| Contracts | `packages/contracts_dart/lib/assal_domain.dart` و`packages/data_dart/lib/assal_repository.dart` | أساس جيد، لكنه يحتاج توسيعًا تدريجيًا مع الحفاظ على نفس IDs والطبقات |

## بوابة الانتقال إلى Task 01

تمت قراءة المرجع واستخراج سلسلة 35 مهمة من الملف الأول، مع تثبيت أن تحسين الأيقونات يدخل ضمن المهام المرئية الخاصة بالهوية (Design System/Home/Login) ولا يُنفذ كإعادة تصميم منفصلة. قبل أي كود، يجب أن تكون لكل مهمة بطاقة مستقلة تحتوي Scope وExisting State وChanges وFiles وTests وRuntime/Visual/Architecture/Data/Regression Verification وRemaining Issues وFinal Gate.

الحالة الحالية للمرحلة: **PASS — Discovery/Authority baseline complete، ولم يبدأ تنفيذ الكود بعد**.
