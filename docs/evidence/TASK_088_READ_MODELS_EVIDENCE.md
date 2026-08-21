# TASK 088 — Customer Read Models Evidence

**التاريخ:** 2026-08-21

**الحالة:** PASS

## النطاق

تم تدقيق جميع `customer_*` read models التي يقرأها `ProductionRepository`، ومقارنتها بتعريفات migrations وبـ`information_schema.columns` في Production وبـmappers داخل `assal_domain.dart`. شمل التدقيق البانرات، المتاجر، المنتجات، المحفوظات، المتاجر المتابَعة، التعليقات، والمحادثات، مع التحقق من أن كل loader يقرأ اسم View الصحيح ويحوّل الحقول إلى DTO المقابل.

## خريطة المصادر الفعلية

| Read model | المصدر الأساسي | Loader في ProductionRepository | أعمدة Production بعد التدقيق |
|---|---|---|---:|
| `customer_banners` | `banners` عبر migration 0004 | `listBanners` | 12 |
| `customer_stores` | `stores` مع `regions`, `merchant_profiles`, `store_statistics`, `store_gallery` عبر migration 0004 | `listStores`, `getStore` | 27 |
| `customer_products` | `products` مع taxonomy/categories/regions/product_images عبر migration 0004 | `listProducts`, `getProduct` | 54 |
| `customer_comments` | `comments` مع `profiles` عبر migration 0039 | `listComments` | 11 |
| `customer_conversations` | `conversation_participants`, `conversations`, `stores`, وآخر `messages` عبر migration 0038 | `listConversations` | 9 |
| `customer_favorite_products` | `favorites` + `customer_products` عبر migration 0038 ثم 0059 | `listFavoriteProducts`, `listFavoriteTaxonomies` | 55 |
| `customer_followed_stores` | `store_followers` + `customer_stores` عبر migration 0038 | `listFollowedStores` | 28 |

الـsnapshot المختصر محفوظ في `artifacts/task088_customer_views_snapshot.json`، ومخرجات Production الكاملة محفوظة في نتائج SQL الخاصة بـ`information_schema.columns` ضمن سجل المهمة.

## الخلل المكتشف وسببه

كان `customer_products` يعرض معظم metadata الأساسية، لكنه كان يسقط حقولًا يكتبها Merchant editor ويقرأها `AssalProductSummary.fromJson`: `components`, `grade_levels`, `grade_labels`, `shelf_life_label_ar`. كما كان يعيد `production_date` و`packaged_date` كـ`NULL` ثابتين رغم أن محرر المنتج يحفظهما داخل `products.metadata`. أدى ذلك إلى DTO صالح شكليًا لكنه ناقص وظيفيًا؛ فالقوائم كانت تصبح فارغة أو null بصمت، وخصوصًا في شاشة المنتج والتاجر.

وكان `customer_favorite_products` يعتمد على `cp.*` لكنه بقي عند projection القديم ذي 51 عمودًا بعد تحديث `customer_products`. لذلك كان مسار المحفوظات سيظل يفقد الحقول نفسها حتى بعد إصلاح View المنتجات.

## الإصلاحات المحافظة

أضيفت migration `0058_complete_customer_product_read_model` إلى Production بالإصدار `20260821175606`. حافظت على ترتيب أول 50 عمودًا حتى لا تغيّر PostgreSQL أسماء أو أنواع الأعمدة القائمة، ثم أضافت الأعمدة الجديدة في نهاية View. تستخرج migration القوائم من JSONB فقط عندما تكون Array، وتستخرج `grade_levels` من metadata مع fallback إلى `grade_level`، و`grade_labels` مع fallback إلى `grade_label_ar`. كما تستخرج التاريخين فقط عند مطابقة صيغة `YYYY-MM-DD`، وإلا تعيد null بدل أن تفشل القراءة بسبب قيمة metadata غير صالحة.

أضيفت migration `0059_refresh_customer_favorite_products_read_model` بالإصدار `20260821180728` لإعادة تعريف `customer_favorite_products` بعد توسع `customer_products`. حافظت على `security_invoker = true` وعلى authenticated-only SELECT، وأبقت العلاقة read-only.

وتم تحديث `packages/contracts_ts/src/database.ts` بإضافة الحقول الأربعة إلى `customer_products` و`customer_favorite_products`، مع إبقاء Insert/Update للمحفوظات read-only عبر `never`. كما أضيفت اختبارات Flutter تغطي projection الغني، ثم اختبار شامل يثبت mappings واسم View للبنرات والمتاجر والمحفوظات والمتابعات والتعليقات والمحادثات.

## الأدلة والاختبارات

نجح rollback dry-run لـ0058 وأظهر `customer_products` مع 54 عمودًا، ونجح rollback dry-run لـ0059 وأظهر `customer_favorite_products` مع 55 عمودًا قبل التطبيق. وبعد التطبيق، أعاد `information_schema` الحقول الجديدة كلها في relationين بالمواقع والأنواع التالية: `components` و`grade_levels` و`grade_labels` كـARRAY، و`shelf_life_label_ar` كـtext.

تم تنفيذ post-apply SELECT محدود على `customer_products` و`customer_favorite_products`، ونجحت قراءة الحقول الجديدة من Production. العينة الحالية احتوت صفًا واحدًا في كل View، وكانت القيم الاختيارية فارغة أو null لأن metadata للمنتج الحالي لا تحتوي تلك القيم؛ هذا يثبت قابلية القراءة وليس وجود بيانات اختبارية مصطنعة.

| بوابة | النتيجة |
|---|---|
| Flutter `analyze --no-pub` | PASS — No issues found |
| Flutter `test --no-pub` مع standalone TASK 088 coverage | PASS — 55 tests |
| Admin `pnpm check` | PASS |
| Admin `pnpm test -- --run` | PASS — 26 tests (4 auth، 18 data، 4 error) |
| Admin `pnpm build` | PASS؛ بقي تحذير chunk size غير المانع المعروف |
| Production migrations | 0058 و0059 موجودتان في migration history بالإصدارين المذكورين |
| Security advisor بعد DDL | لم يظهر تحذير View جديد؛ التحذيرات الموجودة تخص دوال SECURITY DEFINER وAuth وكانت موثقة قبل TASK 088 وليست ناتجة عن read-model migrations |

## الخلاصة

أصبح كل `customer_*` View المستخدم في عميل Flutter موجودًا في Production ومطابقًا لمصدره الأساسي ولـmapper المقابل. أُصلح إسقاط metadata الغني في المنتجات، وتبعته المحفوظات حتى لا تبقى نسخة قديمة ناقصة. لا توجد كتابة مباشرة في الجداول الأساسية، ولا تغيير في RLS أو صلاحيات القراءة، وكل اختبارات Flutter وAdmin اجتازت بعد التعديل.
