# Battle-Test Validation Plan — عسلكم

## الغرض

هذه الخطة إضافة إلزامية إلى `master_execution_plan.md`. لا يكفي أن ينجح `flutter analyze` أو `flutter build`. لن يُعلن Customer/Merchant/Admin جاهزًا إلا بعد تشغيل المسارات فعليًا، باستخدام بيانات اختبار حقيقية معزولة، ورفع ملفات حقيقي في بيئة الاختبار، وفحص الصلاحيات والفشل والأداء والتزامن.

## قواعد السلامة قبل الاختبار

1. لا نستخدم بيانات عملاء حقيقيين أو مستندات هوية حقيقية.
2. كل المستخدمين والملفات والبانرات والإشعارات التجريبية تحمل prefix واضحًا مثل `e2e_2026_08_16_...`.
3. نستخدم بيئة اختبار/مساحة معزولة داخل Supabase أو namespace اختبار لا يلوث البيانات الفعلية؛ لا نحذف بيانات إنتاجية بالتخمين.
4. لا نستخدم Service Role داخل Flutter أو Web أو Admin bundle.
5. كل اختبار يملك fixture وcleanup/reconciliation، وتُحفظ نتائج cleanup.
6. عند غياب إعداد ضروري، نسجل `BLOCKED` ولا نستبدله بـ fake success.

## بيئات الاختبار

| البيئة | الغرض | ما يُثبت |
|---|---|---|
| Demo offline | تشغيل بلا إنترنت/Supabase | اكتمال الرحلة المحلية وعدم وجود اعتماد خفي |
| Production-like Supabase | Auth/DB/Storage/RLS حقيقية ببيانات اختبار | التكامل الحقيقي والصلاحيات والرفع |
| Flutter Web local | Customer Web artifact عبر خادم محلي | callback، RTL، keyboard، responsive، console/network |
| Android Mimo | APK Debug/Release حسب المتاح | Google deep-link، Auth، lifecycle، runtime، logcat |
| Admin local | لوحة تشغيل محلية بحساب Admin | CRUD/Storage/Notifications/RLS/audit |

## مسارات التشغيل الفعلية

### 1. Customer

- Guest: Launch → Home → Categories → Search → Filters → Product → Store.
- Auth: Email → Google → Facebook، مع cancel/error/reset/session restore.
- Social: Follow/unfollow، favorite product/store/category، like/share، review/comment/reply.
- Requests: Send Request → Summary → Submit → My Requests → Detail → Messaging → Handoff.
- Profile: history، favorites، following، reviews/comments، messages، notifications، settings.

### 2. Merchant

- Auth user نفسه → Profile → فتح متجري.
- Store Wizard: identity، business، media، location، experience، delivery/pickup، review/submit.
- رفع حقيقي: logo، cover، gallery، product images.
- Product Wizard: taxonomy canonical، attributes، metadata، images، availability، delivery، publish.
- Verification: documents/PDF، identity front/back، selfie fallback، status transitions.
- Dashboard: products، requests، messages، reviews، delivery، verification، analytics.

### 3. Admin

- Admin Auth user → local Admin login → role guard.
- Users/Merchants/Stores/Products/Taxonomy.
- Verification review مع private signed access فقط.
- Banner: create → real image upload → DB path → publish/schedule → Customer Home.
- Notification: create in-app notification → Customer Center → mark read.
- Audit: كل عملية حساسة تسجل actor/action/resource/time/result.

## مصفوفة المستخدمين والصلاحيات

| Actor | يجب أن يستطيع | يجب أن يُرفض عنه |
|---|---|---|
| Guest | القراءة العامة المسموحة | الكتابة، private files، notifications الخاصة |
| Customer A | ملفه، favorites، follows، requests/messages الخاصة | Store B، Product ownership، Admin tables، verification files لغيره |
| Merchant A | متجره ومنتجاته وملفاته وanalytics الخاصة | Merchant B، Admin roles، audit العام، ملفات خاصة لغيره |
| Admin | ما يسمح به role، moderation، banners، notifications، audit | تجاوز سياسات بدون سجل أو دون role |
| Non-admin | Customer فقط | كل Admin CRUD |

يُختبر كل صف عبر API/Repository فعلي، لا عبر إخفاء الأزرار فقط. يجب أن تكون النتيجة `403/permission denied` أو empty حسب policy، مع عدم تسريب البيانات.

## اختبارات Authentication

1. Email valid/invalid، duplicate email، wrong password، reset، expired session.
2. Google Web callback، Google Android deep-link، إعادة فتح التطبيق، sign-out.
3. Facebook callback/cancel/error/identity linking.
4. Auth UID واحد عند استخدام providerين حسب إعداد linking.
5. refresh token، device/browser restart، network interruption أثناء callback.
6. Admin user role correct؛ user عادي لا يفتح Admin.
7. لا secrets في source أو `main.dart.js` أو APK أو logs.

## اختبارات Storage الحقيقية

1. رفع JPEG/PNG/WebP صالح إلى public media، ثم قراءة الصورة من Web وAPK.
2. رفع ملف غير مسموح، امتداد مزيف، حجم زائد، ملف تالف، واسم path غير صالح.
3. replace/delete/retry/progress، وفشل الشبكة أثناء الرفع.
4. Customer لا يرفع إلى مسار Merchant/Admin.
5. Merchant A لا يقرأ أو يحذف ملفات Merchant B.
6. verification/private file لا يملك public URL دائمًا ولا يقرأه Guest.
7. Admin يستطيع الوصول عبر policy/signed URL، ويسجل Audit Log.
8. كل DB media record يملك canonical `storage_path` ولا توجد orphan records بعد cleanup.

## اختبارات قاعدة البيانات وRLS

1. قراءة/كتابة users/profiles حسب owner.
2. Merchant ownership على stores/products/gallery/delivery.
3. Requests وmessages للـ participants فقط.
4. Reviews/comments/favorites/notifications self-access.
5. Admin roles/admin_users/audit_logs/banners admin-only.
6. محاولة IDOR بتغيير UUID في كل endpoint/repository method.
7. محاولة privilege escalation بتغيير `profiles.role` من Customer/Merchant.
8. التحقق من indexes/policies وعدم وجود broad public write.
9. اختبارات migration على schema نظيف وfixture اختبار، ثم rollback/reconciliation إن أمكن.

## اختبارات حالات الفشل والانهيار

| الحالة | السلوك المطلوب |
|---|---|
| لا إنترنت عند boot | Demo/Cache يظهران، لا Loading forever |
| انقطاع أثناء OAuth | رسالة قابلة لإعادة المحاولة، لا session نصفية |
| 401/403 | session refresh أو رفض واضح، لا fallback مزيف |
| Storage timeout | progress يتوقف بوضوح، retry، draft محفوظ |
| DB timeout | Error state مع retry، لا قائمة فارغة مضللة |
| duplicate submit | idempotency أو منع إرسال مكرر |
| app kill أثناء Wizard | آخر checkpoint يستعاد محليًا |
| app kill أثناء upload | الملف لا يُعلن مكتملًا بلا تحقق، واستئناف/retry واضح |
| malformed taxonomy/location | لا crash، empty/error state، مصدر version ظاهر |
| rotation/back/resume | لا فقد session ولا overflow |
| invalid deep link | رفض آمن، لا فتح route محمي بلا session |
| invalid image/PDF | رفض قبل الحفظ العام، رسالة عربية واضحة |

## اختبارات الضغط والأداء

### Client/Web

- قياس cold start وwarm start وauth callback وHome first render وSearch debounce وProduct/Store gallery.
- اختبار text scale، RTL، viewport mobile/tablet/desktop، keyboard focus، memory أثناء تنقل متكرر.
- اختبار gallery كبيرة وscroll rails وrebuilds، مع رصد overflow وjank وconsole errors.
- لا يقبل الأداء تدهورًا غير مبرر عن baseline قبل التعديل؛ كل regression يسجل بالقياس.

### Data/API/Storage

- اختبار تحميل read-only لصفحات Home/Search/Product/Store على دفعات متزايدة.
- اختبار concurrent sessions على الأقل بمستويات 5/10/25 مستخدم اختبار حسب قدرة بيئة الاختبار، ثم رفع المستوى فقط إذا ظلت البيانات معزولة.
- اختبار burst للبانرات/notifications ورفع ملفات متزامن محدود.
- قياس p50/p95/p99، error rate، timeout rate، DB/Storage response، وعدد الاتصالات.
- اختبار soak لمدة تشغيل مستمر مناسب للبيئة مع مراقبة memory/queue/retries، دون إبقاء polling غير ضروري.
- معيار الفشل ليس رقمًا اعتباطيًا: أي error rate غير صفري في مسار حرج، timeout متكرر، تسريب صلاحية، أو نمو غير محدود في الذاكرة يوقف بوابة الإطلاق؛ أرقام الأداء النهائية تسجل مع مواصفات الجهاز/البيئة.

## اختبارات التزامن بين الأنظمة

1. Admin يرفع صورة Banner → Storage path → DB record → Customer Home يعرضها.
2. Admin يعدل/يعطل Banner → Customer refresh لا يعرض النسخة غير النشطة.
3. Admin ينشئ In-App notification → Customer يراه → mark read → unread badge يتحدث.
4. Merchant يضيف Product → Admin/Customer يراه وفق status/policy.
5. Admin يغير verification status → Merchant badge/flow يتحدث دون fake status.
6. Customer request/message → Merchant receives/reads/replies → Customer sees state.
7. تحديث من Web ثم إعادة فتح APK، والعكس، للتأكد من مصدر البيانات المشترك.

## اختبارات Web وAPK وMimo

### Web

- `flutter build web --release`.
- خادم static محلي وHTTP 200 لـ index/main bundle.
- Google callback، Email، Facebook عند provider جاهز.
- browser console/network، RTL، keyboard، focus، responsive.
- لا client secret في generated assets.

### APK

- debug build وrelease build مع توثيق signing.
- install/upgrade/uninstall/reinstall على Mimo.
- Google deep-link وEmail/Facebook، back/resume/rotation.
- Android logcat: لا FATAL/uncaught exception/ANR.
- package `com.assalkom.assalkom` وSHA-1 configuration verified.

### Admin local

- فتح local URL، login، session restore، role guard.
- CRUD/Upload/Banner/Notification/Audit مع DB/Storage حقيقيين.
- non-admin rejection من API/RLS، لا من UI فقط.

## أمن التطبيق والاعتمادات

1. secret scan على Git history والملفات generated.
2. تحقق من عدم وجود Service Role في Dart/TypeScript/client bundle.
3. تحقق من عدم وجود SQL credentials أو Google/Facebook secrets في source.
4. CORS/redirect allowlist أقل نطاق ممكن؛ لا wildcard غير ضروري.
5. Storage public/private classification ومراجعة policies.
6. Audit logs غير قابلة للحذف العام.
7. cleanup لبيانات الاختبار مع تقرير ما تم حذفه وما بقي بسبب حماية.

## أدلة يجب حفظها

لكل اختبار:

- test ID، وقت التنفيذ، commit، environment، actor، fixture IDs.
- command أو route، expected، actual، status.
- screenshots/console/logcat/raw response عند الحاجة.
- performance CSV/JSON وsummary.
- security/RLS matrix.
- cleanup result.
- Root Cause/Fix/Regression Test عند الفشل.

المخرجات النهائية:

- `docs/evidence/battle_test_report.md`
- `docs/evidence/security_rls_matrix.md`
- `docs/evidence/storage_upload_report.md`
- `docs/evidence/auth_cross_platform_report.md`
- `docs/evidence/performance_report.md`
- `docs/evidence/release_manifest.md`
- acceptance matrix محدثة.

## قرار الإطلاق

- **GO:** كل مسار حرج يعمل فعليًا، لا critical security/performance/runtime defect، Web/APK/Admin local evidence مكتملة، وRLS/Storage مثبتة.
- **CONDITIONAL GO:** وظائف غير حرجة مؤجلة وموثقة، دون عيب أمني/فقد بيانات/كسر Auth.
- **NO-GO:** فشل Auth، تسريب صلاحية، private file public، فقد بيانات Wizard، crash/ANR، sync corruption، أو اعتماد على fake Production persistence.

لن أقول “تم” بناءً على build فقط. سأعرض في التسليم What changed، Why، Verification، Tests، Failures/Fixes، Remaining، والقرار الرسمي لكل بوابة.
