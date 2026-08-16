# الخطة التنفيذية الموحّدة — عسلكم / Souq Al Assal

## الهدف النهائي

تحويل ما هو موجود إلى منتج قابل للتشغيل الحقيقي والإطلاق المرحلي، مع الحفاظ على الهوية والمعمارية وDemo-first، ودمج مسار العميل والتاجر وAuth وSupabase Database/RLS وStorage وAdmin Web المحلي داخل منظومة واحدة. نسخة Web العامة/التسويقية وCloudflare تبقى خارج الإطلاق الحالي، لكن Flutter Web artifact يظل محفوظًا وقابلًا لإعادة البناء مستقبلًا. Admin Web المحلي جزء من الإطلاق التشغيلي الحالي، ويعمل بحساب Admin حقيقي في Supabase دون Firebase أو Push خارجي.

## ثوابت لا يجوز كسرها

| الثابت | القرار |
|---|---|
| المنتج | منصة اجتماعية/تجارية متخصصة بالعسل اليمني، وليست Checkout تقليديًا |
| الهوية الظاهرة | عسلكم |
| الاسم الهندسي | Souq Al Assal / سوق العسل |
| التاجر | نفس المستخدم: `User → Open My Store → Merchant Capability` |
| Framework | Flutter/Dart، Web وAPK من codebase العميل نفسه |
| Demo | يعمل كاملًا دون Supabase/إنترنت، ولا يدعي Production persistence |
| Production | Supabase Auth + Postgres + Storage خلف Repository/Data Source |
| Auth | Email، Google، Facebook؛ Google Web Client في Supabase، Android Client في Google Cloud |
| Firebase | غير مستخدم في هذه الدفعة |
| Notifications | In-App عبر DB؛ Push خارجي مؤجل |
| Admin | Web محلي متصل بـ Supabase، Auth محمي، لا Admin public deployment الآن |
| Landing | وحدة مستقلة لاحقًا، لا تدخل في Customer/Admin acceptance الحالية |
| Security | RLS/Storage policies هي مصدر الصلاحية، لا UI visibility |
| Architecture | `UI → Controller → Use Case → Repository → Data Source` |

## المعطيات المثبتة

| العنصر | القيمة/الحالة |
|---|---|
| Supabase project | `gvalqfgxrkibuydoiuiz` |
| Supabase URL | `https://gvalqfgxrkibuydoiuiz.supabase.co` |
| Supabase OAuth callback | `https://gvalqfgxrkibuydoiuiz.supabase.co/auth/v1/callback` |
| Google Cloud project | `assalkom` |
| Google Android client | `351620134668-abbmnhboppngksocnuitjvpgikefigrc.apps.googleusercontent.com`، package `com.assalkom.assalkom`، SHA-1 المعطاة |
| Google Web client | `351620134668-ue6n2n72nnqi95q6r9s9o1fuua90b09g.apps.googleusercontent.com`، من نوع Web، callback مضبوط |
| Supabase Site URL | `http://127.0.0.1:8124` |
| Android redirect | القيمة التي أدخلها المستخدم صحيحة؛ يتم التحقق فعليًا أثناء OAuth بدل الحكم من RTL display |
| Storage | bucket `sok1` موجود ويحتاج audit/policies قبل اعتماده نهائيًا |
| Taxonomy | `yemeni_honey_master_database_final.json`، الإصدار/المرجع الفعلي يثبت في manifest |
| Current customer app | Customer Web/APK وDemo journey وAPK Mimo وtests الأساسية موجودة؛ لا يعاد بناؤها بلا سبب |
| Current Admin | scaffold/موقع محلي موجود؛ يوسّع إلى Admin حقيقي بدل إنشاء مشروع متوازٍ |

## قاعدة السرية

لا تُحفظ Google Client Secret أو Supabase Service Role أو أي FCM/service credential أو keystore أو كلمة مرور داخل Git أو Flutter bundle أو `main.dart.js`. تُحفظ الأسرار في لوحة Supabase/بيئة تشغيل محلية ignored، وتُسلم بيانات Admin الأولية للمستخدم مرة واحدة بعد الإنشاء، ثم يُطلب تغييرها. لا تُعاد طباعة الأسرار في التقارير.

## دورة إلزامية لكل مهمة

لكل Task مستقل:

> **PLAN → IMPLEMENT → RUN → VERIFY → TEST → VISUAL CHECK → ARCHITECTURE CHECK → FIX → RETEST → EVIDENCE**

لا تنتقل المهمة التالية إلا بعد نجاح بوابة الحالية أو تسجيل `BLOCKED` مع `ROOT CAUSE / IMPACT / REQUIRED INPUT`.

---

# Phase 0 — Authority, Discovery, Architecture

### Task 1 — تثبيت مصادر السلطة والمخرجات

**النطاق:** Prompt التنفيذي، Amendment، قاعدة العسل، صور/أصول الهوية، قرارات Auth/Storage/Admin الحالية. **المخرج:** `docs/evidence/master_authority.md` ومصفوفة تعارضات. **البوابة:** لا قرار UX أو Schema خارج مصدر موثق.

### Task 2 — جرد المستودع والأصول والنسخ العاملة

**النطاق:** Flutter، packages، Admin، migrations، assets، tests، Web/APK artifacts، Git. **المخرج:** inventory hashes/paths وحالة كل مكوّن. **البوابة:** تحديد ما يُحافظ عليه وما هو Stub.

### Task 3 — Discovery Report الموحّد

**النطاق:** Merchant Flow، Store Creation، Verification، Product Creation، Taxonomy، Locations، Analytics، Auth، Profile، Supabase، Demo، Admin. **المخرج:** تحديث `docs/evidence/merchant_amendment_discovery.md` مع GAP→ROOT CAUSE→IMPACT. **البوابة:** لا تعديل Feature قبل تثبيت baseline.

### Task 4 — Requirements Traceability من 50 مهمة

**النطاق:** ربط كل بند في Prompt/Amendment بمهمة وملف واختبار وحالة. **المخرج:** تحديث `docs/requirements_traceability.md` بعناصر Customer/Merchant/Admin/Auth/Storage/RLS. **البوابة:** لا متطلب orphan.

### Task 5 — تثبيت حدود المعمارية والبيئات

**النطاق:** Demo/Production/Admin local/Web artifact، flags، secret boundaries، local commands. **المخرج:** `docs/architecture.md`, `docs/deployment.md`, environment template redacted. **البوابة:** لا Widget→Supabase ولا Admin direct SQL.

---

# Phase 1 — Auth, Admin Identity, Session Foundation

### Task 6 — تدقيق Auth Providers وRedirects

**النطاق:** Supabase Google/Facebook/Email، Google Web/Android clients، Site URL، Android deep link. **المخرج:** read-only audit evidence. **البوابة:** Web client فقط في Supabase Google Provider، Android client في Google Cloud فقط.

### Task 7 — إنشاء Admin Auth User ودوره

**النطاق:** إنشاء Supabase Auth user إداري مخصص، trigger profile، `admin_roles`, `admin_users`, role selection. **المخرج:** حساب Admin محلي وcredential handoff آمن. **البوابة:** Auth user يدخل، user عادي لا يملك admin policy.

### Task 8 — Admin Login/Session Guard

**النطاق:** Admin local login، session persistence، sign-out، expiry، route guard، no-admin error. **المخرج:** شاشة دخول عربية محلية وحالات واضحة. **البوابة:** لا Admin route قبل تحقق الدور.

### Task 9 — Auth Domain/Repository Contracts

**النطاق:** Email/Google/Facebook/session/restore/linking/cancel/error. **المخرج:** contracts وDemo/Production implementations. **البوابة:** Demo يبقى يعمل دون Supabase.

### Task 10 — Email Auth الحقيقي

**النطاق:** sign-up/sign-in/reset/confirmation حسب إعداد البريد، validation/error/loading. **المخرج:** customer + admin login tests. **البوابة:** session/Auth UID/Profile restoration.

### Task 11 — Google OAuth Web وAndroid

**النطاق:** hosted OAuth الموصى به، Web client في Supabase، Android deep-link، callback/session. **المخرج:** Google Web/APK path. **البوابة:** Google→Supabase→APK/Web callback بلا loop.

### Task 12 — Facebook OAuth

**النطاق:** Provider Facebook، callback، UI، cancel/error، identity linking. **المخرج:** Facebook path عبر نفس Auth UID. **البوابة:** لا duplicate user.

### Task 13 — Session Synchronization

**النطاق:** profile، favorites، follows، history، store، products، requests، messages، notifications، settings. **المخرج:** restore/cache-first refresh. **البوابة:** لا تحميل شامل عند boot ولا login wall للضيف.

---

# Phase 2 — Storage, Media, Taxonomy, Location References

### Task 14 — Storage Read-only Audit

**النطاق:** `sok1`، public/private، MIME، size، objects، Storage RLS، DB paths. **المخرج:** storage audit report. **البوابة:** لا اعتماد bucket بمجرد وجوده.

### Task 15 — Storage Policies وPath Convention

**النطاق:** public media paths للـ stores/products/banners، private verification path، owner/admin policies. **المخرج:** additive migration/policy evidence. **البوابة:** public read مقصود، private docs غير عامة.

### Task 16 — Media Repository وUpload State

**النطاق:** upload/replace/delete/preview/compress/progress/error/retry، Demo local وProduction gateway. **المخرج:** typed media contracts. **البوابة:** لا Service Role أو direct Storage في UI.

### Task 17 — Taxonomy Master Audit

**النطاق:** قراءة كاملة لقاعدة العسل: global settings، main categories، subcategories، product types، grades، badges، tags، regions، attributes. **المخرج:** canonical taxonomy manifest. **البوابة:** لا Honey-only model مغلق ولا taxonomy موازية.

### Task 18 — Location Source وProvenance

**النطاق:** Governorate→District JSON قابل للاستبدال، ids، duplicate check، source/commit/license. **المخرج:** vendored reference adapter وprovenance. **البوابة:** لا hardcoded Widget values ولا إدخال عزل/قرى.

### Task 19 — Shared Reference Repository

**النطاق:** taxonomy/location/certificates/delivery/quality/processing/packaging/availability. **المخرج:** common repository يستخدمه Customer/Merchant/Admin/Search. **البوابة:** مصدر واحد لا نسخ متعارضة.

### Task 20 — Searchable Cascading Selectors

**النطاق:** Governorate selector ثم District selector، disabled/loading/empty/error، IDs persistence. **المخرج:** widget/controller tests. **البوابة:** district list لا تظهر قبل governorate ولا تُحفظ أسماء بلا IDs.

---

# Phase 3 — Customer Experience Audit and Preservation

### Task 21 — Customer Home/Navigation Regression

**النطاق:** carousel، banners، popular searches، rails، categories، responsive shell، badges. **المخرج:** regression evidence. **البوابة:** الميزات الحالية لا تنكسر.

### Task 22 — Search/Filters/Category Contract Audit

**النطاق:** كل honey-specific filters، popular searches، taxonomy source، region/location linkage. **المخرج:** filter matrix expanded. **البوابة:** لا filters عامة لـ checkout/cart.

### Task 23 — Product/Store/Social Regression

**النطاق:** gallery، metadata، store profile، follow، reviews، comments، likes، share، requests/handoff. **المخرج:** customer journey regression. **البوابة:** لا dead CTA ولا broken image.

### Task 24 — Profile/Favorites/History Center

**النطاق:** آخر المشاهدة، المفضلة الثلاثية، المتاجر المتابعة، reviews/comments/requests/messages/notifications/settings. **المخرج:** Profile capability model. **البوابة:** Demo/auth user swap دون فقد semantics.

### Task 25 — Customer Auth UI Ordering

**النطاق:** ترتيب Email ثم Google ثم Facebook، prompts، guest behavior، disabled reasons Demo. **المخرج:** Auth UX evidence. **البوابة:** لا provider button وهمي أو onPressed فارغ.

---

# Phase 4 — Merchant Capability and Store Creation Wizard

### Task 26 — Merchant Domain Model

**النطاق:** StoreDraft/Summary، merchant capability، identity، business، media، location، delivery، documents، verification، status. **المخرج:** contracts لا تعتمد على UI أو Supabase. **البوابة:** نفس Auth UID.

### Task 27 — Merchant Entry and Resume

**النطاق:** Profile→فتح متجري، draft/resume/exit/back/progress، new vs existing store. **المخرج:** route/controller وDemo persistence. **البوابة:** لا انتقال مباشر إلى Dashboard فارغ.

### Task 28 — Wizard Step: Store Identity

**النطاق:** الاسم، الاسم الظاهر، الوصف، النشاط، المجال، الخبرة، نبذة، التواصل. **المخرج:** structured fields/selectors/chips وvalidation. **البوابة:** step cannot advance invalid.

### Task 29 — Wizard Step: Store Media

**النطاق:** logo/avatar/cover/gallery، preview/replace/delete/compress/loading/error/success. **المخرج:** Media repository integration. **البوابة:** paths/metadata محفوظة وfallback سليم.

### Task 30 — Wizard Step: Location

**النطاق:** governorate/district، IDs، محل فعلي، contact/hours/notes. **المخرج:** cascading searchable selector. **البوابة:** location تظهر في store/search/product عند الحاجة.

### Task 31 — Wizard Step: Experience and Specialties

**النطاق:** سنوات الخبرة، products sold، honey specialties، communication channels، structured taxonomy. **المخرج:** no random TextField-only model. **البوابة:** values canonical.

### Task 32 — Wizard Step: Delivery and Pickup

**النطاق:** offers delivery، zones، method، fee، pickup/store/office/courier، configure later/skip. **المخرج:** delivery/pickup drafts/settings. **البوابة:** skip لا يخفي الإعداد، edit لاحقًا.

### Task 33 — Wizard Step: Review/Submit

**النطاق:** summary، missing fields، terms/privacy، save draft، submit store/application. **المخرج:** submission state وnotification. **البوابة:** no false published/verified state.

### Task 34 — Store Profile Integration

**النطاق:** cover/logo/avatar/gallery، verification، stats، specialties، certifications، delivery/pickup، contact/message/request. **المخرج:** public social store profile. **البوابة:** customer public view لا يكشف private docs.

### Task 35 — Merchant Capability Dashboard

**النطاق:** overview/products/requests/messages/followers/reviews/ratings/store/delivery/pickup/verification/settings. **المخرج:** يستبدل Stub الحالي. **البوابة:** كل card/CTA يعمل أو يوضح disabled reason.

---

# Phase 5 — Documents, Verification, Product Management

### Task 36 — Documents Domain and Private Storage

**النطاق:** images/PDF، type/name/preview/progress/delete/replace/review status/upload date. **المخرج:** private document contracts/paths. **البوابة:** no public URL/default public.

### Task 37 — Identity and Selfie Verification

**النطاق:** front/back ID، selfie capture when platform allows، upload fallback، validation/process states. **المخرج:** evidence model. **البوابة:** لا checkbox موثق ولا status fake.

### Task 38 — Business Verification States

**النطاق:** business registry/store docs، stages Not Started/In Progress/Submitted/Under Review/Verified/Rejected/Requires Action. **المخرج:** deterministic transitions. **البوابة:** Verified Badge يظهر فقط على Verified.

### Task 39 — Admin Verification Compatibility Contract

**النطاق:** review queue، secure signed access، approve/reject/request action، audit event. **المخرج:** contract الآن وAdmin UI لاحقًا/ضمن Phase Admin. **البوابة:** لا Admin access بلا role/policy.

### Task 40 — Generic Product Domain

**النطاق:** Product→Category→Subcategory→Type→Attributes→Media→Pricing→Availability→Origin→Quality. **المخرج:** create/edit/publish drafts عامة لكل أنواع المصدر. **البوابة:** canonical product IDs.

### Task 41 — Add Product Wizard

**النطاق:** Basic Info، taxonomy، images، description، quality، origin، production، packaging، availability، delivery، review، publish. **المخرج:** Demo/Production repository flow. **البوابة:** كل step validation/state.

### Task 42 — Product Media and Metadata

**النطاق:** 3+ images، 1:1 cards، gallery، honey identity، quality/processing/packaging/dates/certifications/weight. **المخرج:** Product detail/store/customer mapping. **البوابة:** no arbitrary blob text.

### Task 43 — Merchant Product Management

**النطاق:** list/create/edit/draft/publish/unpublish/delete، moderation status، availability، product stats. **المخرج:** Dashboard management. **البوابة:** owner-only write and admin moderation boundary.

---

# Phase 6 — Analytics, Performance, Deterministic Personalization

### Task 44 — View Event Contracts

**النطاق:** store/product/content views، actor/session/device/page context، privacy. **المخرج:** event + aggregate models. **البوابة:** Demo metrics labeled; Production no fake numbers.

### Task 45 — Buffered Analytics Sync

**النطاق:** local buffer، dedupe، throttle، batch، deferred sync، retry، offline. **المخرج:** no request-per-pixel implementation. **البوابة:** bounded network/load tests.

### Task 46 — Merchant/Admin Analytics

**النطاق:** store/product views، trends، top products، permissioned aggregates. **المخرج:** read models for merchant/Admin. **البوابة:** user sees only allowed stats.

### Task 47 — Load on Demand and Cache

**النطاق:** lazy features، pagination، debounce search، cache-first، targeted refresh، Realtime only when needed. **المخرج:** startup/network profile. **البوابة:** no all-connections boot.

### Task 48 — Deterministic Personalization and Notifications

**النطاق:** rules based on location/interests/views/favorites/follows/interactions؛ in-app notification events/types/read state. **المخرج:** deterministic recommendations and DB notifications. **البوابة:** no fake AI/no Firebase Push.

---

# Phase 7 — Admin Local Integration and System Acceptance

### Task 49 — Admin Shell and Authenticated Routing

**النطاق:** local desktop responsive shell، Admin login، roles، navigation: Users/Merchants/Stores/Products/Taxonomy/Banners/Reviews/Requests/Messages/Verification/Settings/Analytics/Audit. **المخرج:** Admin screens بدل scaffold. **البوابة:** role guard/RLS.

### Task 50 — Admin Repository and Integration

**النطاق:** users/merchants/stores/products/taxonomy/verification/banners/notifications/storage/audit/analytics، CRUD، search/filter/pagination، loading/error/empty/retry، banner upload→DB→Customer Home، notification create→Customer Center، Storage policies، RLS tests، full Customer/Merchant/Admin journeys، Web/APK/Mimo/build/artifacts/docs/GO gate. **المخرج:** Admin local release + final acceptance matrix. **البوابة:** لا إعلان إطلاق قبل نجاح كل البنود أو تسجيل Deferred/Blocked صريح.

## تفصيل بوابة Task 50

| المحور | PASS فقط إذا |
|---|---|
| Auth | Email/Google/Facebook تعمل، session restore، نفس Auth UID، Admin role صحيح |
| Customer | Home/Search/Filters/Categories/Product/Store/Social/Request/Message/Handoff/Profile/Favorites/Notifications تعمل |
| Merchant | فتح المتجر، Wizard، Media، Location، Delivery/Pickup، Docs، Verification، Product Wizard، Dashboard تعمل |
| Admin | login، roles، users، merchants، verification، products، taxonomy، banners، storage، notifications، audit تعمل |
| Database | Production mappings صحيحة، migrations additive، no orphan critical data |
| Storage | public media تعمل، private docs محمية، owner/Admin policies مجربة |
| RLS | users/merchants/requests/messages/reviews/favorites/notifications/audit/admin policies backend-enforced |
| Performance | lazy load/cache/debounce/batch، لا تحميل شامل أو request-per-pixel |
| Demo | يعمل دون Supabase ولا يخلط Demo بProduction |
| Web/APK | Web artifact محفوظ دون نشر عام، APK/Mimo يعمل، release signing حالة موثقة |
| UX/RTL | لا overflow/dead buttons/empty handlers، RTL/keyboard/safe areas/contrast/semantics مجربة |
| Evidence | What changed/Why/Verification/Tests/Remaining لكل مهمة، commits منطقية، manifest نهائي |

## قواعد التوقف

إذا احتاجت مهمة إعدادًا لا يمكن الوصول إليه عبر الموصلات أو ملفات المشروع، لن أتجاوزه. سأصدر سجلًا يوضح **CONFLICT → ROOT CAUSE → IMPACT → OPTIONS → REQUIRED USER INPUT** وأوقف المهمة التي تعتمد عليه فقط. لن أستخدم أسرارًا وهمية، ولن أفتح Storage/RLS للعامة لتجاوز تعذر الإعداد، ولن أعلن Production PASS من Demo أو build فقط.

## ترتيب التنفيذ الفعلي

البدء يكون بالمهام 1–5 Discovery/Authority ثم 6–13 Auth/Admin identity ثم 14–20 Storage/References، وبعدها 21–25 Customer regression، ثم 26–43 Merchant، ثم 44–48 Analytics/Performance، وأخيرًا 49–50 Admin/System acceptance. لا يوجد انتقال إلى Landing/Cloudflare أو Public Web deployment قبل اجتياز Customer + Merchant + Admin local acceptance.


---

# ملحق إلزامي — Battle-Test Validation

لا يُعد أي Task أو Phase مكتملًا بمجرد نجاح build أو unit tests. بعد كل مسار قابل للتشغيل، وخصوصًا Tasks 7–13 و14–16 و26–43 و49–50، تُطبق خطة `docs/evidence/battle_test_validation_plan.md` وتشمل:

1. تشغيل Demo offline وProduction-like Supabase ببيانات اختبار معزولة.
2. تسجيل دخول Email/Google/Facebook وAdmin فعلي مع session restore وdeep-link APK.
3. رفع صور وملفات اختبار فعلية، ثم replace/delete/retry وفحص public/private policies.
4. اختبارات RLS وIDOR وprivilege escalation لكل Customer/Merchant/Admin actor.
5. اختبار Banner upload→DB→Customer Home، وNotification DB→Customer Center→read.
6. اختبارات انقطاع الشبكة، OAuth failure، Storage timeout، duplicate submit، app kill/resume، malformed data، و401/403.
7. اختبارات أداء وضغط متدرجة، وقياس p50/p95/p99 وerror/timeout/memory/network، دون استخدام polling غير ضروري.
8. تشغيل Flutter Web، APK على Mimo، Admin المحلي، وفحص console/logcat وعدم وجود FATAL/ANR/overflow.
9. حفظ raw logs/screenshots/fixtures/cleanup/performance/security evidence في `docs/evidence`.
10. منع GO عند وجود Auth failure، public private-file exposure، RLS bypass، data loss، crash/ANR، sync corruption، أو fake Production persistence.

المخرج الإلزامي قبل التسليم: `battle_test_report.md`, `security_rls_matrix.md`, `storage_upload_report.md`, `auth_cross_platform_report.md`, `performance_report.md`, وRelease/Acceptance Manifest.
