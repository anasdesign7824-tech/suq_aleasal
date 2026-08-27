# UI Reconstruction Task Ledger — عسلكم

## قواعد السجل

هذا السجل يحول إعادة البناء إلى مهام ذرية. لا تنتقل المهمة إلى التالية إلا بعد تحققها وتسجيل الدليل. لا تُستخدم حالة `DONE` بلا Evidence. المهام `BLOCKED` لا تُلتف عليها ببيانات وهمية أو تعديل Backend غير معتمد.

| ID | Feature | Description | Files | Dependencies | Status | Implementation | Verification | Visual Result | Data Result | Permission Result | Regression Result | Evidence |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| T001 | Discovery | جرد الشاشات والبيانات والأفعال والحالات | `UI_RECONSTRUCTION_DISCOVERY.md` | repo baseline | VERIFIED | جدول Discovery مكتوب | تمت مراجعة الجدول مقابل الكود | موثق | موثق | موثق | docs-only | `docs/evidence/ui-reconstruction-discovery-2026-08-26.md` |
| T002 | IA | تعريف بنية Customer/Merchant/Admin/Landing | `UI_INFORMATION_ARCHITECTURE.md` | T001 | VERIFIED | IA موثق | تمت مراجعة المسارات | موثق | العلاقات موثقة | الحراس موثقة | docs-only | `docs/evidence/ui-reconstruction-discovery-2026-08-26.md` |
| T003 | Entities | تعريف Presentation Models للكيانات | `UI_ENTITY_PRESENTATION_SPEC.md` | T001 | VERIFIED | Product/Store/User/Verification وغيرها | تمت مراجعة العقود | موثق | mappings موثقة | capabilities موثقة | docs-only | `docs/evidence/ui-reconstruction-discovery-2026-08-26.md` |
| T004 | Design System | تثبيت tokens والمكونات والحالات | `UI_DESIGN_SYSTEM_SPEC.md` | T001 | VERIFIED | spec موحد مكتوب | تمت مطابقة design contract | موثق | لا تغيير Backend | موثق | docs-only | `docs/evidence/ui-reconstruction-discovery-2026-08-26.md` |
| T005 | Coverage | إنشاء مصفوفة تغطية كل المسارات | `UI_COVERAGE_MATRIX.md` | T001-T004 | VERIFIED | 29 مجالًا مسجلًا | تمت مراجعة القائمة | موثق | gaps ظاهرة | gaps ظاهرة | docs-only | `docs/evidence/ui-reconstruction-discovery-2026-08-26.md` |
| T006 | Gaps | تسجيل الفجوات والتعارضات دون تخمين | `UI_GAP_REGISTER.md` | T001-T004 | VERIFIED | 20 Gap مسجلة | تمت مراجعة الأدلة | موثق | واضح ما هو غير مدعوم | واضح ما هو غير مدعوم | docs-only | `docs/evidence/ui-reconstruction-discovery-2026-08-26.md` |
| T007 | Governance | اعتماد سجل التنفيذ الذري | `UI_RECONSTRUCTION_TASK_LEDGER.md` | T001-T006 | VERIFIED | السجل منشأ وفيه 72 مهمة | تم فحص الملف وcommit | موثق | موثق | موثق | docs-only | `docs/evidence/ui-reconstruction-discovery-2026-08-26.md` |
| T008 | Navigation | إنشاء Route Registry مسمى | `apps/mobile_flutter/lib/app/` | T002,T006 | VERIFIED-NARROW | `assal_routes.dart` هو السجل القانوني وربطت به المسارات المعتمدة | `assal_routes_test.dart` وnavigation tests نجحت | مراجعة startup/navigation جارية؛ golden القديم عولج فقط للشاشات المراجعة | لا تغيير بيانات | لا تغيير صلاحيات | full regression يحتوي goldens قديمة أخرى | `docs/evidence/flutter-full-regression-2026-08-27.log` |
| T009 | States | توحيد حالات loading/empty/error/partial | `apps/mobile_flutter/lib/core/` | T004,T006 | VERIFIED-NARROW | `AssalStateView` و`AssalExplicitStateView` يعرضان حالات صريحة ورسائل عربية وإعادة المحاولة | `assal_state_view_test.dart` نجح | حالات loading/empty/error مرئية؛ يلزم استمرار مراجعة كل شاشة | لا تغيير بيانات | callbacks مرتبطة بقدرات/جلسة | full visual regression غير مغلق | `docs/evidence/flutter-full-regression-2026-08-27.log` |
| T010 | Capabilities | تعريف capability matrix للعميل والتاجر والإدارة | `packages/contracts_dart/`, `packages/contracts_ts/` | T003,T006 | VERIFIED-NARROW | أضيفت capabilities وحراس customer/merchant/admin دون توسيع صلاحيات العميل | `assal_capabilities_test.dart` وtests الحراس نجحت | الأفعال غير المسموحة تظهر disabled/guard صريحًا | لا تغيير DB | role/ownership checks موثقة ومختبرة محليًا | full E2E production للكتابة ما زال مطلوبًا | `docs/evidence/production-data-audit-2026-08-27.md` |
| T011 | Media | تثبيت نسب الصور ومسارات public/private | `apps/mobile_flutter/lib/core/` | T003,T006 | VERIFIED-NARROW | `AssalMediaSpec` يحدد identity/discovery/verification ونطاق public/private | `assal_assets_test.dart` نجح | Product/Store/cover/avatar تستخدم نسبًا محددة؛ QA الشامل للصور مستمر | لا تغيير Storage | verification media private في العقد | يلزم Storage smoke حقيقي | `docs/evidence/production-data-audit-2026-08-27.md` |
| T012 | App Shell | إعادة بناء shell حول IA الجديدة | `apps/mobile_flutter/lib/app/assal_app.dart` | T008-T011 | VERIFIED-NARROW | shell يستخدم navigation/routes/state/capability foundations الحالية مع RTL وعلامة عسلكم | `navigation_test.dart`, `customer_journey_test.dart` وflutter analyze المرحلي نجحت | startup golden الجديد معتمد بعد مراجعة؛ goldens بقية الشاشات لم تُعتمد | لا تغيير بيانات | guest/customer guard واضح | 46 golden references تحتاج triage، منها 45 لم تعتمد | `docs/evidence/flutter-golden-triage-2026-08-27.md` |
| T013 | Navigation | توحيد selected destination وdeep links | `assal_app.dart`, route registry | T008,T012 | VERIFIED-NARROW | destinations الخمسة مصدرها `AssalCustomerNavigation` وRouteSettings تحمل entity ids | `assal_navigation_test.dart`, `assal_routes_test.dart`, navigation tests نجحت | تحقق بصري جزئي؛ لا deep-link production smoke حتى الآن | لا تغيير بيانات | الحراسة مرتبطة بالـcapability | full regression محجوب بالgoldens القديمة | `docs/evidence/flutter-full-regression-2026-08-27.log` |
| T014 | Auth Guard | بناء حارس guest/auth/merchant/admin | `customer_core.dart`, core | T009,T010,T012 | VERIFIED-NARROW | `requireCapability` وsession guards تمنع الأفعال المقيدة دون silent fallback | auth/capability/profile tests الوظيفية نجحت | guest/unavailable/error states مرئية؛ OTP الحقيقي ما زال يحتاج mailbox اختبار | لا تغيير بيانات | role/ownership checks واضحة | لا يوجد authenticated E2E كامل | `docs/evidence/production-data-audit-2026-08-27.md` |
| T015 | Product | إنشاء ProductPresentation renderer | `assal_widgets.dart`, contracts | T003,T004 | VERIFIED-NARROW | `ProductCard` يعرض الحقول canonical والصورة/السعر/التقييم/المفضلة ويمنع overflow في rail | product card functional tests و`task008` بعد مراجعة golden نجحت | golden مربع معتمد بعد مراجعة؛ تفاصيل المنتج ما زالت ضمن QA | قراءة المصدر/fixtures فقط | favorite action capability-aware | full golden suite غير مغلق | `docs/evidence/flutter-golden-triage-2026-08-27.md` |
| T016 | Store | إنشاء StorePresentation renderer | `assal_widgets.dart`, contracts | T003,T004 | VERIFIED-NARROW | `StoreCard` يعرض الهوية والتحقق والمنطقة والمتابعين ويفصل الإجراءات | store functional tests وfollowers tests الوظيفية نجحت | golden المتجر لم يعتمد بعد | لا تغيير بيانات | follow/contact خلف auth/capability | full golden suite غير مغلق | `docs/evidence/flutter-full-regression-2026-08-27.log` |
| T017 | User | إنشاء UserProfilePresentation renderer | `assal_widgets.dart`, contracts | T003,T004,T010 | PENDING | لم يبدأ | — | — | — | — | — |
| T018 | Verification | توحيد شارة وحالة التوثيق | core, contracts | T003,T009 | PENDING | لم يبدأ | — | — | — | — | — |
| T019 | Banner | توحيد عرض البنر والوجهة | core, customer discovery | T003,T008 | PENDING | لم يبدأ | — | — | — | — | — |
| T020 | Request | توحيد RequestPresentation وحالاته | customer catalog/account | T003,T009 | PENDING | لم يبدأ | — | — | — | — | — |
| T021 | Messaging | إضافة ContextPreview للمحادثة | customer account/catalog | T003,T006,T008 | BLOCKED | لا يوجد context كامل في العقد | ينتظر قرار contract | لا يُخفى النقص | لا اختراع context | صلاحية auth فقط | — | GAP-017 |
| T022 | Images | توحيد loading/error/fallback للصور | `assal_widgets.dart` | T011,T015,T016 | PENDING | لم يبدأ | — | — | — | — | — | — |
| T023 | Components | توحيد Primary/Secondary actions | core/design package | T004,T009 | PENDING | لم يبدأ | — | — | — | — | — |
| T024 | Components | توحيد Input/Filter/Dialog | core/design package | T004,T009 | PENDING | لم يبدأ | — | — | — | — | — |
| T025 | Home | إعادة بناء Header والهوية | `customer_discovery.dart` | T012,T015,T019 | PENDING | لم يبدأ | — | — | — | — | — |
| T026 | Home | إعادة بناء Search entry | `customer_discovery.dart` | T024,T025 | PENDING | لم يبدأ | — | — | — | — | — |
| T027 | Home | قسم Featured/Hero مع بيانات حقيقية | `customer_discovery.dart` | T019,T025 | PENDING | لم يبدأ | — | — | — | — | — |
| T028 | Home | قسم Categories وإخفاء الفارغ | `customer_discovery.dart` | T009,T025 | PENDING | لم يبدأ | — | — | — | — | — |
| T029 | Home | قسم Popular Products | `customer_discovery.dart` | T015,T025 | PENDING | لم يبدأ | — | — | — | — | — |
| T030 | Home | قسم Most Viewed | `customer_discovery.dart` | T015,T025 | PENDING | لم يبدأ | — | — | — | — | — |
| T031 | Home | قسم Featured Stores | `customer_discovery.dart` | T016,T025 | PENDING | لم يبدأ | — | — | — | — | — |
| T032 | Home | Recently Added/Recommended/Following states | `customer_discovery.dart` | T009,T025 | PENDING | لم يبدأ | — | — | — | — | — |
| T033 | Search | إعادة بناء نتائج البحث ووضع الكيان | `customer_discovery.dart` | T015,T016,T024 | PENDING | لم يبدأ | — | — | — | — | — |
| T034 | Search | إعادة بناء فلاتر المنتج والمتجر | `customer_discovery.dart` | T024,T033 | PENDING | لم يبدأ | — | — | — | — | — |
| T035 | Categories | صفحة تصنيف مستقلة بدل الاعتماد على البحث فقط | `customer_discovery.dart` | T028,T033 | PENDING | لم يبدأ | — | — | — | — | — |
| T036 | Stores | Store Discovery بفلاتر المنطقة والتحقق والنوع والترتيب | `customer_discovery.dart`, data contract | T016,T024,T006 | PENDING | لم يبدأ | — | — | — | — | — |
| T037 | Store | إعادة بناء Store Entity Page | `customer_catalog.dart` | T016,T018,T020,T036 | PENDING | لم يبدأ | — | — | — | — | — |
| T038 | Product | إعادة بناء Product Gallery | `customer_catalog.dart` | T011,T022,T015 | PENDING | لم يبدأ | — | — | — | — | — |
| T039 | Product | إعادة بناء Identity/Price/Availability/Info | `customer_catalog.dart` | T015,T038 | PENDING | لم يبدأ | — | — | — | — | — |
| T040 | Product | إعادة بناء Social/Reviews/Comments | `customer_catalog.dart`, `customer_social.dart` | T020,T039 | PENDING | لم يبدأ | — | — | — | — | — |
| T041 | Product | إعادة بناء Request CTA مع context | `customer_catalog.dart` | T020,T039 | PENDING | لم يبدأ | — | — | — | — | — |
| T042 | Following | فصل المحفوظات عن المتابعة | `customer_favorites.dart` | T003,T010,T015,T016 | PENDING | لم يبدأ | — | — | — | — | — |
| T043 | Profile | إعادة بناء Profile Header والهوية | `customer_account.dart` | T017,T018 | PENDING | لم يبدأ | — | — | — | — | — |
| T044 | Profile | إضافة tabs والسياسة الخصوصية | `customer_account.dart` | T017,T010,T006 | PENDING | لم يبدأ | — | — | — | — | — |
| T045 | Profile | إعادة بناء Profile Editor وموقعه | `customer_account.dart` | T011,T024,T006 | PENDING | لم يبدأ | — | — | — | — | — |
| T046 | Requests | إضافة Request detail وحالات timeline | `customer_account.dart`, catalog | T020,T008 | PENDING | لم يبدأ | — | — | — | — | — |
| T047 | Notifications | ربط Notification بالوجهة القابلة للتنفيذ | `customer_account.dart`, route registry | T008,T006 | BLOCKED | payload destination غير typed | ينتظر contract أو read-only | لا fake destination | لا اختراع payload | auth required | — |
| T048 | Messages | إعادة بناء Conversations list مع context | `customer_account.dart` | T021,T009 | PENDING | لم يبدأ | — | — | — | — | — |
| T049 | Messages | إعادة بناء Conversation composer/send states | `customer_account.dart` | T021,T024 | PENDING | لم يبدأ | — | — | — | — | — |
| T050 | Settings | تقسيم الإعدادات وتوثيق persistence gap | `customer_account.dart` | T006,T024 | PENDING | لم يبدأ | — | — | — | — | — |
| T051 | Auth | إعادة بناء OTP/register/loading/error states | `customer_account.dart` | T009,T014,T024 | PENDING | لم يبدأ | — | — | — | — | — |
| T052 | Merchant | إعادة بناء Merchant entry capability-aware | `customer_account.dart`, merchant | T010,T014 | PENDING | لم يبدأ | — | — | — | — | — |
| T053 | Store Wizard | خطوة Basic Identity + validation | `merchant_dashboard.dart` | T010,T024 | PENDING | لم يبدأ | — | — | — | — | — |
| T054 | Store Wizard | خطوات Location/Info/Contact | `merchant_dashboard.dart` | T053,T006 | PENDING | لم يبدأ | — | — | — | — | — |
| T055 | Store Wizard | صور/توثيق/Review/Submit وdraft resume | `merchant_dashboard.dart`, verification | T011,T018,T053,T054 | PENDING | لم يبدأ | — | — | — | — | — |
| T056 | Product Wizard | Product Identity/Category/Type | `merchant_product_editor.dart` | T015,T024 | PENDING | لم يبدأ | — | — | — | — | — |
| T057 | Product Wizard | Origin/Quality/Price/Availability/Attributes | `merchant_product_editor.dart` | T056,T006 | PENDING | لم يبدأ | — | — | — | — | — |
| T058 | Product Wizard | Certificates/Images/Description/Preview/Submit | `merchant_product_editor.dart` | T011,T056,T057 | PENDING | لم يبدأ | — | — | — | — | — |
| T059 | Merchant | إعادة بناء dashboard داخل App Shell | `merchant_dashboard.dart` | T012,T010,T015,T016 | PENDING | لم يبدأ | — | — | — | — | — |
| T060 | Merchant | توحيد product management actions/states | merchant dashboard/editor | T015,T058 | PENDING | لم يبدأ | — | — | — | — | — |
| T061 | Verification | إعادة بناء evidence/payment/review states | `store_verification_screen.dart` | T018,T022,T010 | PENDING | لم يبدأ | — | — | — | — | — |
| T062 | Subscription | إعادة بناء plans/payment proof states | `subscription_plans_screen.dart` | T009,T024 | PENDING | لم يبدأ | — | — | — | — | — |
| T063 | Admin | إعادة بناء Admin shell من IA القائمة الحالية | `apps/admin_web/client/src/pages/Home.tsx` | T003,T004,T010 | PENDING | لم يبدأ | — | — | — | — | — |
| T064 | Admin | ربط Product/Store presentation والقدرات | admin panels, contracts_ts | T015,T016,T063 | PENDING | لم يبدأ | — | — | — | — | — |
| T065 | Admin | Applications/Verification/Plans workflows | admin panels, admin-api | T018,T063 | PENDING | لم يبدأ | — | — | — | — | — |
| T066 | Admin | Users/Admins/Audit privacy and permissions | admin governance panels | T010,T017,T063 | PENDING | لم يبدأ | — | — | — | — | — |
| T067 | Admin | Notifications/Analytics actionable states | admin people panels | T047,T063 | PENDING | لم يبدأ | — | — | — | — | — |
| T068 | Landing | بناء Landing عامة دون اختراع بيانات تشغيلية | `apps/landing_web/` | T004,T006 | PENDING | لم يبدأ | — | — | — | — | — |
| T069 | States | تطبيق الحالات الثماني على كل Screen/Entity | all UI | T009,T025-T068 | PENDING | لم يبدأ | — | — | — | — | — |
| T070 | QA | فحص RTL/accessibility/responsive/image ratios | all UI | T011,T069 | PENDING | لم يبدأ | — | — | — | — | — |
| T071 | Regression | تشغيل analyze/test/build واختبارات المسارات | repo test/build config | T070 | PENDING | لم يبدأ | — | — | — | — | — |
| T072 | Acceptance | Production UI audit وتحديث Evidence والـcommit والقبول | docs/evidence, ledger | T071,T006 | PENDING | لم يبدأ | — | — | — | — | — |

## قاعدة التنفيذ الحالية

بعد إنشاء الوثائق T001–T007، المهمة التالية المسموح بها هي **T008 فقط**. يجب أن تسجل كل مهمة تنفيذًا ونتيجة تحقق وأثرًا بصريًا وبيانيًا وصلاحيًا ونتيجة Regression قبل فتح المهمة التالية.
