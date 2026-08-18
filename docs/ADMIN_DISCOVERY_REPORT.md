# ADMIN DISCOVERY REPORT — عسلكم

## حالة التقرير

هذا التقرير هو مخرج **Discovery فقط**. لم تُنفذ خلاله Migration أو Bootstrap أو إعادة هيكلة للكود أو اتصال إداري تغييري بقاعدة البيانات. الغرض منه تثبيت الحالة الحالية، ومصادر البيانات، والفجوات، والاعتماديات قبل Gate 1.

| الحقل | القيمة |
|---|---|
| المنتج | عسلكم / Souq Al Assal |
| النطاق | Private/Local Admin Console + Supabase Production |
| مرجع الواجهة | آخر نسخة Domain/UI المعتمدة في تطبيق العميل |
| لوحة الإدارة الحالية | `apps/admin_web` |
| تطبيق العميل | `apps/mobile_flutter` |
| مصدر Production | Supabase عبر `ProductionRepository` و`SupabaseQueryGateway` |
| مصدر Demo | `DemoRepository` و`demoCatalog`/ملفات Demo |
| حالة التعديل | ممنوع قبل اعتماد Discovery |
| حالة Production الحالية | توجد قراءات موصولة، لكن توجد مسارات كتابة صريحة غير مهيأة |

## القرار المعماري المثبت

> **Admin Identity مستقلة → `admin_users` → Role → Permissions → Scope → Local Admin Backend → Supabase Production**

ليست لوحة الإدارة مستخدمًا عاديًا بصلاحيات أعلى، ولا تُفتح عبر OTP المستخدم، ولا تعتمد على `Customer/Merchant Capability`. يمكن تقنيًا استخدام Supabase Auth كمزود هوية، لكن سلطة الدخول الإداري تأتي من Admin Auth Identity وعضوية `admin_users` والدور والصلاحية.

لوحة الإدارة محلية افتراضيًا عبر `localhost/127.0.0.1`. لا توجد عملية نشر Cloud أو Public Ingress ضمن النطاق. اتصال Supabase يتم من الخادم المحلي الآمن، ولا يصل service-role key إلى React أو المتصفح.

## 1. الحالة الحالية للوحة الإدارة

لوحة الإدارة الحالية هي Vite/React/TypeScript مع Express لخدمة ملفات البناء. `package.json` لا يحتوي على Supabase client أو tRPC أو Drizzle أو طبقة Repository/Backend بيانات. أمر التطوير الحالي هو `vite --host`، وأمر الخادم يقرأ `PORT` ويستمع دون تثبيت صريح لـ`127.0.0.1`، ولذلك يحتاج التشغيل المحلي لاحقًا إلى تثبيت bind محلي صريح.

غلاف المسارات الحالي في `client/src/App.tsx` يعرّف `/` للصفحة الرئيسية و`/landing` وصفحة fallback فقط. الصفحة الرئيسية `Home.tsx` تجمع التنقل والحالات في ملف واحد، وتعرض أربع واجهات داخلية: `overview`, `products`, `stores`, و`requests`.

الخادم الحالي في `server/index.ts` يخدم الملفات الثابتة ويعيد `index.html` للمسارات، ولا يملك API أو Auth Gate أو Admin Controller أو Storage handler أو Repository.

## 2. الوظائف الحالية والـStubs

| الوظيفة | الحالة الحالية | الدليل | الأثر |
|---|---|---|---|
| Dashboard | واجهة Demo | `Home.tsx` و`demoCatalog` | لا إحصاءات Production |
| Metrics | أرقام محسوبة من Demo arrays | `metricCards` | ممنوعة في Production |
| Products | بحث وفئة محليان، أول 5/12 عناصر | `ProductTable` | لا Pagination ولا حفظ |
| Stores | بطاقات Demo | قسم `stores` | لا مراجعة أو موافقة حقيقية |
| Requests | Drawer/Toast Demo | `RequestsPanel` | لا رد أو تغيير حالة حقيقي |
| Admin Auth | غير موجود كـAdmin Gate | `App.tsx`/server | أي تشغيل حقيقي يحتاج تأسيسًا |
| Routes | محدودة جدًا | `App.tsx` | لا صفحات إدارية مستقلة |
| Repository | غير موجود في Admin Web | `package.json`/server | لا اتصال بيانات |
| RLS enforcement | موجود في SQL فقط | migrations | غير مستهلك من Admin Web |
| Audit UI | غير موجود | routes/pages الحالية | لا عرض أو تدقيق إداري |
| Upload | غير موجود | server/package | لا Banner lifecycle |
| Permissions UI | غير موجود | `Home.tsx` | لا Permission gates |

تحتوي `demoCatalog.ts` على علامة `demo_only: true`، وتضم تصنيفات ومناطق ومتاجر ومنتجات وطلبات وإشعارات محلية. كما تحتوي على تسمية داخلية مرتبطة بمصدر مرجعي للكتالوج؛ يجب ألا تظهر هذه التسمية في واجهة Production، ويجب أن يُربط مصدر التصنيفات المرجعي بعقد واحد دون نسخة يدوية ثانية.

## 3. ما هو متصل حاليًا في تطبيق العميل

نقطة تشغيل Flutter في `main.dart` تقرأ `ASSALKOM_MODE`. القيمة الافتراضية `demo`، وعند `production` تشترط `ASSALKOM_SUPABASE_URL` و`ASSALKOM_SUPABASE_PUBLISHABLE_KEY` ثم تهيئ Supabase وتستخدم `ProductionRepository`.

`ProductionRepository` متصل بقراءات فعلية عبر `SupabaseQueryGateway`. من القراءات الظاهرة في الكود:

| مورد | المصدر الحالي | الحالة |
|---|---|---|
| الجلسة والملف | `profiles` + فحص `admin_users` | قراءة موجودة، نموذج الإدارة يحتاج فصلًا إداريًا صريحًا |
| المناطق | `regions` | قراءة Production |
| التصنيفات | `categories` | قراءة Production |
| Taxonomy | `honey_taxonomy` | قراءة Production |
| البنرات | `customer_banners` | قراءة Production، والـView تعتمد RLS invoker |
| المتاجر | `customer_stores`/الجداول canonical | قراءة Production ضمن Repository |
| المنتجات | `customer_products`/الجداول canonical | قراءة Production ضمن Repository |
| الإشعارات | `notifications` | قراءة موجودة |
| الطلبات | `requests` | قراءة موجودة |
| حالة Auth | Supabase Auth gateway | مسار العميل OTP/password موجود تقنيًا |

نماذج القراءة `customer_stores`, `customer_products`, و`customer_banners` تستخدم `security_invoker = true`، وهو seam مناسب للحفاظ على عقود واجهة العميل مع بقاء RLS فعالًا.

## 4. الحواجز الإنتاجية الحالية

توجد في `ProductionRepository` عمليات تعيد أخطاء صريحة بدل Fake Success، وهذا صحيح من ناحية عدم الادعاء، لكنه يعني أن الإنتاج غير مكتمل بعد. المسارات المتوقفة أو غير المهيأة تشمل:

| المسار | الحالة الحالية |
|---|---|
| إنشاء Request | `production_write_not_configured` |
| المحادثات والرسائل | قراءة فارغة/كتابة `production_write_not_configured` |
| Reviews وComments | كتابة غير مهيأة |
| Follow/Favorite/Like | كتابة غير مهيأة |
| Product view analytics | `production_analytics_not_configured` |
| Submit merchant application | `production_merchant_application_not_configured` |
| Load merchant application | غير مهيأ |
| Merchant draft save/load/clear | غير مهيأ |
| بعض التفاعلات الاجتماعية | غير مهيأة |

واجهة `BecomeMerchantScreen` تجمع بيانات نصية وتعرض صراحة أن رفع المستندات غير متاح بعد، ثم تستدعي عمليات Repository التي لا تملك تنفيذ Production حاليًا. هذه نقطة حاسمة في دورة Store/Verification End-to-End.

## 5. Auth الحالي والفجوة الإدارية

`SupabaseAuthGateway` مصمم أساسًا لمسار مستخدم العميل: OTP، إنشاء الحساب، التحقق، إعادة التعيين، وحذف الحساب. `ProductionRepository` يحدد `isAdmin` بمجرد وجود صف في `admin_users`، بينما `is_admin()` في قاعدة البيانات يعتمد على وجود الهوية في `admin_users`.

هذا يوفر أساسًا أمنيًا أوليًا، لكنه لا يحقق كامل النموذج المطلوب بعد، للأسباب التالية:

1. لا توجد Admin UI أو Admin Backend محلية لتسجيل الدخول بالبريد وكلمة المرور.
2. لا يوجد Bootstrap Super Admin لمرة واحدة مع إغلاق مسار الإنشاء بعد النجاح.
3. `admin_roles.permissions` الحالية coarse-grained، والـRLS الحالية تعتمد غالبًا على `is_admin()` بدل صلاحيات عملية ونطاق.
4. قاعدة `handle_new_user()` تنشئ صفًا في `public.users` و`profiles` لكل `auth.users`. لذلك يجب التفريق منطقيًا: هذا الصف المساند لا يمنح Capability للمستخدم ولا يثبت إدارة؛ السلطة الإدارية تكون في Auth Identity + `admin_users` + Role/Permission.
5. `profiles.role` يقبل `admin`، لكن لا يجوز استخدامه منفردًا كسلطة دخول إداري.

## 6. قاعدة البيانات الحالية

المخطط الأساسي يضم الكيانات التشغيلية اللازمة لمعظم نطاق التكامل: `users`, `profiles`, `merchant_profiles`, `regions`, `categories`, `honey_taxonomy`, `stores`, `products`, الصور، الشهادات، المراجعات، التعليقات، المفضلة، الطلبات، الرسائل، الإشعارات، والبنرات.

كما يضم `admin_roles`, `admin_users`, و`audit_logs`. توجد دالة `is_admin()` وحراس لمنع تغيير دور الملف الشخصي أو حالة توثيق التاجر أو حالة Moderation للمتجر من غير Admin. توجد RLS على الجداول، وسياسات Public/Owner/Admin، وأدوار ابتدائية `super_admin`, `admin`, و`moderator`.

لكن المخطط الحالي لا يحقق بعد كل متطلبات النموذج النهائي، خصوصًا نطاقات الصلاحية الدقيقة، حالة تفعيل المدير، دعوات المدراء، سجل انتقالات الحالات، وتعريف عقد سعر/عملة منفصل عن JSON metadata. تُسجل هذه النقاط كفجوات، ولا تُنفذ Migration قبل اعتماد GAP Report.

## 7. Storage الحالي

يوجد فصل بين bucket عام `assalkom_public` وbucket خاص `assalkom_private`. العام مقروء عموميًا، والكتابة والتعديل والحذف للمالك أو Admin. الخاص غير مقروء عموميًا، وتسمح سياساته للمالك أو Admin وفق المسار.

هذا يوفر أساسًا جيدًا للبنرات العامة وملفات التوثيق الخاصة، لكن لوحة الإدارة لا تملك حاليًا Upload flow أو Backend handler أو UI. كما يجب إعادة اختبار أن صلاحية Admin المقصودة هي Permission-based وليست `is_admin()` العام فقط، وأن ملفات التوثيق لا تصبح عامة بسبب مسار أو URL.

## 8. نماذج القراءة والتزامن

`customer_banners` يعرض البنرات من `public.banners`، و`customer_products` يقرأ السعر والعملة وبعض خصائص المنتج من `products.metadata`. هذا يثبت وجود seam واحد بين canonical data وتطبيق العميل، لكنه يكشف حاجتين للتدقيق والتنفيذ:

- توحيد Product Contract ليستخدم `amount` و`currency` بوضوح، لا نصًا حرًا أو JSON غير مضبوط.
- إثبات أن تحديث Admin للـcanonical tables ينعكس على customer views ثم على التطبيق دون نسخة Catalog ثانية.

المرجع الجغرافي موجود في قاعدة البيانات عبر `regions` وparent relation، ويوجد في التطبيق loader مرجعي يعتمد codes ثابتة. يجب توحيد المصدر والـprovenance والإصدار وعدم حفظ الاسم وحده.

## 9. العلاقة الحالية بين Domain/UI ولوحة الإدارة

الواجهة المعتمدة في تطبيق العميل هي المرجع البصري والعقدي. لا تُنشأ واجهة مستخدم بديلة. لكن لوحة الإدارة الحالية ليست مستهلكًا لهذه العقود؛ فهي تملك shapes محلية داخل `demoCatalog` ولا تملك Admin Repository. لذلك الفجوة ليست في تصميم Domain/UI، بل في تحويل العقود إلى مسار إداري حقيقي مع الحفاظ على نفس الهوية.

## 10. المخاطر والحواجز

| المعرف | الخطورة | الوصف | حالة القرار |
|---|---|---|---|
| BLOCK-ADMIN-001 | P0 | لا يوجد Admin Auth/Bootstrap محلي حتى الآن | يتطلب تصميم وتنفيذ بعد Gate 1 |
| BLOCK-ADMIN-002 | P0 | Admin Web بلا Backend/Repository/Supabase client | يتطلب طبقة محلية آمنة |
| BLOCK-DATA-001 | P0 | Merchant application وعملياتها الإنتاجية غير مهيأة | يمنع Store E2E |
| BLOCK-DATA-002 | P1 | التفاعلات والرسائل والمشاهدات غير مهيأة | يمنع اكتمال Domain sync |
| GAP-RBAC-001 | P0 | صلاحيات DB الحالية عامة أكثر من Permission model المطلوب | يتطلب مراجعة RLS/Migration |
| GAP-RBAC-002 | P1 | لا يوجد scope/status للمديرين الفرعيين | يتطلب عقدًا ومخططًا |
| GAP-PRICE-001 | P1 | السعر/العملة في metadata لا Product Contract مضبوط | يتطلب توحيدًا قبل CRUD |
| GAP-TAX-001 | P1 | Demo source يكرر تمثيلًا محليًا للمصدر المرجعي | يلزم Canonical taxonomy mapping |
| GAP-LOCAL-001 | P1 | التشغيل الحالي لا يثبت bind على localhost فقط | يلزم تقييد server/Vite لاحقًا |
| GAP-AUDIT-001 | P1 | Audit table موجودة لكن لا توجد Admin UI/عمليات موحدة | يتطلب use case وشاشة واختبارات |

## 11. ما لم يُنفذ في Discovery

لم يتم إنشاء حساب Bootstrap، ولم يتم تغيير Auth، ولم تُطبق Migration، ولم تُغير RLS، ولم تُرفع ملفات، ولم تُعدل Admin UI، ولم تُستدعَ عمليات تغيير على Supabase. الخطوة التالية بعد اعتماد هذا التقرير هي تثبيت `ADMIN_CONTROL_MATRIX` و`DATA_FLOW_MATRIX` و`SCHEMA_RLS_GAP_REPORT` ثم الانتقال إلى Gate 1.

## 12. توصية Discovery

المشروع يملك أساسًا جيدًا في Domain/UI وفي مخطط Supabase وRLS الأولي، لكن لوحة الإدارة الحالية ما تزال Demo shell، كما أن عدة write paths في تطبيق العميل غير مهيأة. لذلك لا يجوز إعلان تكامل أو إنتاج الآن. المسار الصحيح هو: اعتماد Discovery، ثم تثبيت العقود والفجوات، ثم بناء Local Admin Backend وAdmin Identity/Bootstrap، ثم إغلاق حواجز Merchant/Verification والتفاعلات، ثم تنفيذ CRUD وStorage وRBAC وE2E.

## مصادر التقرير

- `README.md`
- `apps/admin_web/package.json`
- `apps/admin_web/client/src/App.tsx`
- `apps/admin_web/client/src/pages/Home.tsx`
- `apps/admin_web/server/index.ts`
- `apps/admin_web/client/src/data/demoCatalog.ts`
- `apps/mobile_flutter/lib/main.dart`
- `apps/mobile_flutter/lib/app/assal_runtime_config.dart`
- `apps/mobile_flutter/lib/core/supabase_auth_gateway.dart`
- `packages/data_dart/lib/production_repository.dart`
- `database/migrations/0001_initial_souq_al_assal.sql`
- `database/migrations/0002_storage_canonical_policies.sql`
- `database/migrations/0004_customer_read_models.sql`
- `database/README.md`
