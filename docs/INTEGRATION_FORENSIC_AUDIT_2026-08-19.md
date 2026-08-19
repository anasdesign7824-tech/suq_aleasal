# التدقيق التكاملي الشامل — عسلكم

## نطاق التدقيق

يُفحص النظام على خمسة مسارات مستقلة ثم تُطابق نتائجها في مصفوفة واحدة:

| المسار | نقاط الفحص |
|---|---|
| Flutter Auth/Input | تهيئة Production، Auth Gateway، controllers، focus، validation، OTP، الأخطاء |
| Home/Filters/Banners | الصفحة الرئيسية، مصادر المنتجات والمتاجر، الحالات الفارغة، زر الفلاتر، الشرائح والبنرات |
| Merchant Flow | طلب التاجر، draft، الصور، RPC التفعيل، role، جلسة المستخدم، لوحة التاجر، المنتجات |
| Admin API/UI | كل route، كل زر كتابة، RBAC، refresh، الحذف، الرفع، الإشعارات، المستخدمون |
| Supabase Schema/RLS/Storage | الجداول، views، RPC، العلاقات، policies، storage buckets، الحقول المطلوبة |

## قاعدة الدليل

لا تُعد الواجهة عاملة لمجرد ظهور زرها. كل وظيفة يجب أن يكون لها: عنصر UI، controller، use case/repository، route أو query، جدول/حقل أو Storage/RPC، policy مناسبة، ونتيجة نجاح/فشل قابلة للتحقق.

## الأعراض الواردة من الصور

تظهر الصور أربعة أعراض مباشرة: زر إرسال OTP لا يستجيب، حقل كلمة المرور في إنشاء الحساب لا يقبل الكتابة، زر الفلاتر في شاشة البحث لا يفتح القائمة، والصفحة الرئيسية تفتقد banner carousel ومناطق مثل الأكثر مشاهدة والجديد. كما يظهر أن حالة المتجر في تجربة سابقة انعكست في بيانات المتجر للمستخدمين لكنها لم تُحدّث هوية المستخدم ومساحته التاجرية في الجلسة.

## منهج المقارنة

تُقارن كل وظيفة من واجهة العميل ولوحة الإدارة مع Production schema وRLS. تُسجل النتيجة في صورة: `UI → Controller → Repository → API/RPC → Table/View/Storage → RLS → Refresh/Session`. عند غياب حلقة تُصنف الوظيفة `BROKEN` ولا يُسمح بتركها كواجهة شكلية.

## نتائج أولية مؤكدة من الكود

| المعرّف | النتيجة | الدليل | التصنيف |
|---|---|---|---|
| AUTH-01 | نسخة Production لا تعمل إلا إذا وصلت إليها ثلاثة `--dart-define` صحيحة، وإلا تعرض شاشة خطأ بدء التشغيل بدل Auth. | `apps/mobile_flutter/lib/main.dart:12-40` و`assal_runtime_config.dart:11-25` | يحتاج تحقق بناء/تسليم |
| AUTH-02 | تسجيل دخول الحساب الموجود passwordless ويبدأ بـ`requestEmailOtp` مع `shouldCreateUser: false` ثم نافذة OTP. المسار نفسه موجود وليس زرًا بلا callback. | `customer_account.dart:188-200` و`supabase_auth_gateway.dart:28-39` | خطأ تشغيلي محتمل في Config/Auth أو رسالة عامة تخفي السبب |
| AUTH-03 | حقل كلمة المرور في التسجيل يستخدم `FilteringTextInputFormatter.allow` مع character class غير آمن يحتوي `[]` غير مهربة، وهو مرشح مباشر لرفض الإدخال أو سلوك غير متوقع. | `customer_account.dart:82-107` | BUG مؤكد/مرشح قوي |
| HOME-01 | أقسام «الأكثر مشاهدة» و«وصل حديثًا» وغيرها لا تُنشأ إلا بعد تجاوز `scrollController.position.pixels >= 180`. لذلك قد تبدو مفقودة في أول عرض، رغم وجودها في الملف. | `customer_discovery.dart:89-108` و`354-450` | تصميم تحميل كسول يحتاج تحقق بصري/وظيفي |
| HOME-02 | Carousel البنرات يرجع `SizedBox.shrink()` عندما تكون قائمة Production فارغة أو صورها غير صالحة، أي لا يظهر الإطار الفارغ المطلوب. | `customer_discovery.dart:923-959` | BUG مؤكد |
| HOME-03 | البنر يقبل فقط `http` أو `assets/`؛ أي رابط Storage غير صالح أو حقل صورة فارغ يستبعد العنصر بالكامل قبل إظهار حالة الصورة. | `customer_discovery.dart:923-927` | BUG/عقد بيانات يحتاج توحيد |
| HOME-04 | يوجد ticker نصي بديل دائمًا تقريبًا، لكن carousel نفسه ليس له Empty State في Production. | `customer_discovery.dart:728-751` و`902-987` | فجوة UI/حالة فارغة |

## فجوات Admin المؤكدة

| المعرّف | النتيجة | الدليل | التصنيف |
|---|---|---|---|
| ADMIN-01 | الخادم المحلي لا يملك أي route لحذف المستخدمين أو المتاجر أو البنرات أو المنتجات. | `apps/admin_web/server/index.ts:121-293` | وظيفة مطلوبة غير موجودة |
| ADMIN-02 | لوحة البنرات تقبل `imageUrl` نصيًا فقط؛ لا يوجد `multipart` أو endpoint رفع إلى Storage أو اختيار ملف محلي. | `AdminOperations.tsx:22-39` و`index.ts:239-254` | وظيفة مطلوبة غير موجودة |
| ADMIN-03 | الإشعار الإداري يقبل `userId` إلزاميًا ويُنشئ صفًا واحدًا فقط؛ لا يوجد broadcast ولا صورة ولا route عام. | `admin-data.ts:502-515` و`index.ts:143-147` | وظيفة مطلوبة غير موجودة |
| ADMIN-04 | لوحة المستخدمين قراءة فقط ولا تعرض زر حذف أو تعطيل أو إدارة حالة. | `Home.tsx:65` و`AdminPeople.tsx` | فجوة UI/Backend |
| ADMIN-05 | إجراءات المتجر المعروضة في الواجهة محدودة بالاعتماد عند `pending` والإيقاف عند `active`، بينما الرفض وإعادة التفعيل غير متاحين مباشرة في القائمة. | `Home.tsx:120-122` | فجوة UX/تحكم |
| ADMIN-06 | `sendError` يرجع دائمًا HTTP 500، حتى عند أخطاء صلاحية/مدخلات متوقعة، ما يجعل الواجهة تعرض فشلًا عامًا ويصعب تشخيص السبب. | `index.ts:53-59` | قابلية تشخيص ضعيفة |
| ADMIN-07 | إنشاء مدير إداري حقيقي موجود ويعزل المسار عن عميل التطبيق، لكن بيانات كلمة المرور المؤقتة تُعاد إلى الواجهة لتسليمها مرة واحدة؛ يجب التحقق من حماية العرض وعدم تخزينها. | `admin-data.ts:538-555` | يحتاج تحقق أمني لا يُغيّر بلا اختبار |

## لقطة Production مؤكدة في 2026-08-19

أظهر الاستعلام المقروء من مشروع `gvalqfgxrkibuydoiuiz` أن قاعدة البيانات ليست Demo: فيها صف إداري/اختبار واحد في `users` و`profiles`، وصف واحد في `banners`، و9 أقسام و39 تصنيف عسل و357 منطقة مرجعية، بينما `products` و`stores` و`merchant_applications` و`notifications` فارغة في لحظة الفحص. هذه الحقيقة تفسر Empty State، لكنها لا تبرر اختفاء حاوية الـCarousel أو غياب إمكانية تزويدها من Admin.

| المعرّف | النتيجة | الدليل | التصنيف |
|---|---|---|---|
| DATA-01 | مصدر Production متصل ومحدد، لكن معظم بيانات التشغيل فارغة فعليًا؛ لا يجوز إعادة إدخال Demo fallback لهذه الجداول. | استعلام Production بتاريخ 2026-08-19، نتيجة `execute_sql` المحفوظة في سجل MCP | حالة بيانات حقيقية |
| DATA-02 | وجود بانر واحد لا يعني ظهوره في التطبيق: يجب أن يكون `is_active=true` وأن يحتوي `image_url` صالحًا، ثم يمر من `customer_banners` ومن فلتر الواجهة. | `production_repository.dart:246-259` و`customer_discovery.dart:923-959` | عقد نشر/عرض غير مكتمل |
| SESSION-01 | موافقة الإدارة تحدّث `profiles.role` ذريًا، لكن `getSession()` كان يستدعي `_sessionFromIdentity()` مباشرة ولا يقرأ `profiles` أو `admin_users`؛ لذلك كانت الهوية Auth صحيحة بينما ظل الدور في التطبيق `customer`. | `0016_merchant_activation_sync.sql:130-174`، `production_repository.dart:102-110` قبل الإصلاح و`142-174` | BUG مؤكد، أُصلح بربط `getSession()` بـ`_sessionForIdentity()` |

## إصلاحات Phase 2 المنفذة

| المعرّف | الإصلاح | الملفات |
|---|---|---|
| FIX-AUTH-INPUT | أزيل `FilteringTextInputFormatter.allow` المعيب من حقل كلمة المرور؛ الإدخال أصبح حرًا، بينما بقي شرط الحروف الإنجليزية والأرقام والرمز الخاص والتحقق عند الإرسال. | `apps/mobile_flutter/lib/features/customer/customer_account.dart` |
| FIX-HOME-RAILS | بدأت أقسام «الأكثر مشاهدة» و«وصل حديثًا» و«الموثوقة» والمتاجر والمقترحات مباشرة مع تحميل الصفحة بدل انتظار أول تمرير. لا توجد Demo rows في Production؛ الحالات الفارغة تُعرض من حالة البيانات. | `apps/mobile_flutter/lib/features/customer/customer_discovery.dart` |
| FIX-BANNER-EMPTY | استُبدل `SizedBox.shrink()` بحاوية Carousel ثابتة الارتفاع مع Empty State وزر استكشاف وتحديث في Production. | `apps/mobile_flutter/lib/features/customer/customer_discovery.dart` |
| FIX-FILTER-TAP | لم تعد ضغطة الفلاتر تنتظر استعلامات Production قبل فتح BottomSheet؛ تُستخدم البيانات المحملة ويُعاد تحديثها دون حجب التفاعل. | `apps/mobile_flutter/lib/features/customer/customer_discovery.dart` |
| FIX-SESSION-ROLE | `getSession()` يعيد Hydration من `profiles` و`admin_users` في كل قراءة، فتظهر ترقية التاجر في Profile/CTA عند إعادة البناء. | `packages/data_dart/lib/production_repository.dart` |

**قيد الاختبار الحالي:** لا يوجد Flutter/Dart executable داخل sandbox، لذلك لم أعدّ فحص Dart ناجحًا من هذه البيئة. `git diff --check` نجح، واختبارات Admin وTypeScript وBuild نجحت بعد الإصلاحات الإدارية. يجب تشغيل بوابة Flutter على Windows المتصل قبل إصدار APK.

## نتائج Phase 3: دورة التاجر وAdmin وSupabase

| المعرّف | النتيجة المؤكدة | الإجراء |
|---|---|---|
| MERCHANT-01 | Migration `merchant_activation_sync` موجودة فعليًا في Production كآخر migration قبل التدقيق، وتكتب `merchant_profiles`, `profiles.role`, `stores` و`notifications` داخل RPC واحد. | أُبقي RPC، وأُغلقت إمكانية استدعائه من `anon` و`authenticated` في Migration `0017`; أصبح `service_role` فقط هو المسموح. |
| MERCHANT-02 | بعد التفعيل كانت صفحة الحساب تعتمد جلسة قديمة؛ إصلاح `getSession()` في Phase 2 يعيد Hydration للدور ويجعل CTA يتغير إلى «لوحة التاجر». | تم الإصلاح في `production_repository.dart`. |
| ADMIN-DELETE | لم تكن أزرار حذف المتاجر والمستخدمين والمنتجات والبنرات موجودة كمسارات مكتملة. | أضيفت Backend routes محمية بـRBAC، تسجيل Audit، تأكيد UI، ومنع حذف المدير الحالي أو مدير آخر من مسار المستخدمين. |
| ADMIN-MEDIA | إنشاء البانر كان يقبل رابطًا فقط. | أضيف رفع ملف محلي إلى `assalkom_public` عبر الخادم المحلي، مع حد 10MB وأنواع صور محددة، ثم يملأ رابط المسودة تلقائيًا. |
| ADMIN-NOTIFY | الإشعار كان لمستخدم واحد فقط ومن دون صورة. | أضيف اختيار مستخدم UUID أو Broadcast، ويُنشأ broadcast كصف لكل مستخدم لأن `notifications.user_id` غير قابل لـNULL؛ الصورة تُحفظ في `payload.image_url` وتُعرض في تطبيق العميل. |
| ADMIN-SECURITY | تحذيرات Advisor كشفت صلاحية RPC الإداري العامة وسياسات مكررة وفهارس FK ناقصة. | طُبقت Migrations `0017`, `0018`, `0019`. اختفى تحذير RPC، اختفت تحذيرات تكرار سياسات الإدارة، وأصبحت المتبقيات معلومات فهارس غير مستخدمة في قاعدة شبه فارغة. |

### Advisories المتبقية المقصودة

تبقى ملاحظتان أمنيتان يجب عدم إخفائهما: جدول `admin_bootstrap_state` عليه RLS بلا سياسة عامة، وهذا مقصود لأنه مسار خادم Bootstrap وليس عميلًا؛ ودالة `delete_my_account()` قابلة للمستخدم المصادق عليه، وهذا مقصود لأن العميل يحتاج حذف حسابه ذاتيًا، لكن يجب إبقاء تحقق `auth.uid()` داخل الدالة. كما يبقى تحذير Supabase Auth حول Leaked Password Protection معطلًا، وهو إعداد خارجي من لوحة Supabase وليس تعديلًا آمنًا داخل الشفرة؛ يجب تفعيله يدويًا في Auth Password Security قبل الإطلاق النهائي.

### فهارس الأداء المتبقية

بعد إضافة فهارس المفاتيح الأجنبية، لم يعد Advisor يبلغ عن FK غير مفهرس أو سياسات متكررة. التحذيرات المتبقية كلها `INFO` من نوع `unused_index`؛ سببها أن معظم جداول التشغيل وعدد كبير من الجداول المرجعية لا تحتوي بيانات أو استعلامات كافية في لحظة التدقيق. لا يُنصح بحذفها الآن لأن مسارات المتاجر والمنتجات والطلبات ستستخدمها عند امتلاء Production.

## بوابة القبول النهائية

| البوابة | النتيجة | الدليل |
|---|---|---|
| Flutter analyzer | PASS | `flutter analyze --no-pub` على Windows: No issues found |
| Flutter tests | PASS | `flutter test --no-pub`: 13 tests passed |
| Flutter formatter | PASS بعد إعادة التنسيق | الملفات الثلاثة المعدلة أُعيد تنسيقها ثم اجتازت analyzer والاختبارات |
| Production APK | PASS | `tool/build-production.ps1`، mode=production، Supabase URL الصحيح |
| APK artifact | جاهز للتسليم | `artifacts/assalkom-production-forensic-audit-arm64-release.apk`، 22,055,193 bytes، SHA-256 `5855709da784cd84d968fc7420b3be9140eabd665940f33940315937276b8981` |
| Admin TypeScript | PASS | `pnpm check` على Windows بعد المزامنة |
| Admin tests | PASS | `pnpm test`: 4 tests passed |
| Admin build | PASS | `pnpm build` على Windows بعد المزامنة |
| Supabase migrations | PASS | `merchant_activation_sync` موجودة، و`0017`, `0018`, `0019` طُبقت بنجاح على Production |

### ملاحظة مصدرية مهمة

تم اكتشاف أن أول APK أُعيد بناؤه بعد التعديلات احتفظ بالـSHA القديم لأن ملفات الإصلاح لم تكن قد نُقلت بعد إلى نسخة Windows. أُوقف التسليم، وتمت مزامنة الملفات صراحة إلى `D:\suq_aleasa`، ثم أُعيد `analyze` و`test` والبناء. لذلك النسخة التي يجب تسليمها هي artifact أعلاه فقط، وليست APK السابق ذي SHA `49211c...`.

## الحالة المتبقية قبل إطلاق عام

المشكلة الوحيدة التي لا يمكن إثباتها آليًا من sandbox هي اختبار البريد الفعلي بحساب المستخدم وإدخال OTP من جهازه؛ الكود اجتاز analyzer والاختبارات، وRuntime Config وProduction URL صحيحان. كما يجب تفعيل **Leaked Password Protection** من إعدادات Supabase Auth يدويًا، لأن Advisor يراه إعدادًا خارجيًا. لا توجد Demo rows مضافة إلى Production؛ الجداول التشغيلية الفارغة ستظهر Empty States حتى ينشئ Admin أو التجار بيانات حقيقية.

## References

[1]: https://supabase.com/docs/guides/database/database-linter "Supabase Database Linter"
[2]: https://supabase.com/docs/guides/auth/password-security "Supabase Auth password security"


## Follow-up: Existing Account Login and Filter Root Cause

أثبت الاختبار الفعلي أن تجربة التسجيل الجديد يجب أن تبقى منفصلة عن تسجيل دخول الحساب الموجود. التسجيل الجديد يستخدم الاسم والبريد وكلمة المرور وتأكيدها ثم `signUp()` و`verifyOTP(type: signup)`. أما الحساب الموجود فيستخدم البريد فقط ثم `signInWithOtp(... shouldCreateUser: false)` و`verifyOTP(type: email)`.

كان سبب عدم استجابة زر الفلاتر استثناءً مؤكدًا في `_SearchScreenState._showFilters` عند حساب `priceMax`: عندما تكون Production خالية من المنتجات يكون `dataMaxPrice == null`، وكان fallback يجعل الشرط صحيحًا ثم ينفذ `dataMaxPrice!`. النتيجة `Null check operator used on a null value` قبل `showModalBottomSheet`. تم استبدال ذلك بحساب غير قابل لـnull يبدأ من `priceMin` ويضمن نطاقًا صالحًا حتى مع Empty State.

وكانت رسالة المصادقة العامة تخفي نتيجة Supabase الخاصة بالحساب الموجود. عند عدم وجود Auth Identity للبريد مع `shouldCreateUser: false` أعاد endpoint رسالة `otp_disabled / Signups not allowed for otp`. فحص `auth.users` أكد أن البريد المستخدم في الاختبار كان موجودًا ومؤكدًا، ثم أعاد طلب OTP الحقيقي HTTP 200 بعد مراجعة إعدادات Auth؛ لذلك تم جعل الـGateway يترجم هذا الخطأ في سياق الحساب الموجود إلى «لا يوجد حساب بهذا البريد الإلكتروني. اختر إنشاء حساب أولًا» دون تغيير signup.

اجتاز المصدر بعد التعديل `flutter analyze --no-pub` و`flutter test --no-pub` بنتيجة `No issues found` و`13 tests passed`. نجح Production build gate، وخرج APK arm64 جديد ببصمة SHA-256: `03b3ae24ee674fcc4eddc9c6c81deda7ee3b6dd9c87d617901110cf613fa9b67`. تعذر نسخ APK إلى sandbox في آخر خطوة لأن mount جهاز Windows انقطع (`Transport endpoint is not connected`) بعد اكتمال البناء؛ النسخة النهائية بقيت على جهاز Windows في `D:\suq_aleasa\apps\mobile_flutter\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`.
