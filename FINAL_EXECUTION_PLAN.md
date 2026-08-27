# خطة التنفيذ النهائية الموسعة — عسلكم

هذه الخطة توسع سجل المهام الأساسي إلى **120 مهمة ذرية**. لا تُعلن أي مهمة مكتملة إلا بعد تنفيذها، تشغيل اختبار مناسب، توثيق الدليل، ومراجعة أثرها على البيانات والصلاحيات والنسخ السابقة. المهام T001–T072 موجودة في `UI_RECONSTRUCTION_TASK_LEDGER.md`، والمهام التالية تغلق النطاق المتبقي للمنتج النهائي.

## حالة المهام الحالية

المهام T008–T016 نُفذت محليًا على كمبيوتر المستخدم مع نجاح بوابات الاختبار الضيقة والتحليل. ما زالت اختبارات regression/golden الكاملة، Landing، النشر العام، وبعض التكاملات الإنتاجية بحاجة إلى إغلاق موثق.

## المهام الموسعة T073–T120

| ID | المجال | المهمة الذرية | شرط القبول |
|---|---|---|---|
| T073 | Baseline | تجميد قائمة المصادر الحالية ونسخها المرجعية | تقرير hash ومسارات المصدر |
| T074 | Baseline | مقارنة branch المحلي مع `origin/main` | تقرير اختلاف لا يتضمن أسرارًا |
| T075 | Baseline | تصنيف كل تعديل محلي إلى مستخدم/إعادة بناء/مولد | لا commit مختلط |
| T076 | Baseline | توحيد متغيرات البيئة بين Demo وProduction | لا fallback صامت |
| T077 | Baseline | فحص الأسرار والمفاتيح داخل Git والتاريخ | لا secret مكشوف |
| T078 | Baseline | تثبيت مصدر الحقيقة للإصدارات والـartifacts | manifest واحد |
| T079 | Baseline | إنشاء تقرير فجوات محدث بعد التدقيق | كل gap لها سبب وأثر |
| T080 | Baseline | اعتماد بوابة البدء للمنتج النهائي | Evidence قبل UI جديد |
| T081 | Customer | إغلاق App Shell النهائي RTL/responsive | shell يعمل على المقاسات المستهدفة |
| T082 | Customer | إغلاق selected destination والتنقل العكسي | لا dead-end |
| T083 | Customer | توحيد loading/empty/error/offline على shell | الحالات صريحة |
| T084 | Customer | إغلاق Home header والهوية | copy وأصل الأصول موثق |
| T085 | Customer | إغلاق Home search entry | يفتح Search الحقيقي |
| T086 | Customer | إغلاق Home hero/banner | بيانات حقيقية أو empty موثق |
| T087 | Customer | إغلاق Home categories | taxonomy من العقد فقط |
| T088 | Customer | إغلاق Home product rails | ProductCard موحد |
| T089 | Customer | إغلاق Home store rails | StoreCard موحد |
| T090 | Customer | إغلاق Home personalized states | لا claims بلا بيانات |
| T091 | Search | إغلاق Search query lifecycle | query ثابت وقابل لإعادة المحاولة |
| T092 | Search | إغلاق فلاتر المنطقة والمحافظة والمديرية | IDs من المرجع الرسمي |
| T093 | Search | إغلاق فلاتر التصنيف والنوع | mapping typed |
| T094 | Search | إغلاق فلاتر السعر والتقييم والتوفر | query يطابق العقد |
| T095 | Search | إغلاق sorting والـpagination | لا نتائج وهمية |
| T096 | Search | إغلاق نتائج Product/Store entity mix | entity presentation واضح |
| T097 | Search | إغلاق search no-result/offline/error | actions صريحة |
| T098 | Search | إصلاح اختبارات Search regression | baseline أو contract موثق |
| T099 | Product | إغلاق Gallery loading/error/fallback | النسب ثابتة |
| T100 | Product | إغلاق Product identity/price/availability | مصدر بيانات واحد |
| T101 | Product | إغلاق Product store context | route وstore ID موثقان |
| T102 | Product | إغلاق Product info/attributes | الحقول المدعومة فقط |
| T103 | Product | إغلاق likes/favorites capability | guest/auth/server guard |
| T104 | Product | إغلاق reviews/comments states | لا إرسال بلا session |
| T105 | Product | إغلاق request CTA وcontext | request contract كامل |
| T106 | Store | إغلاق Store identity/location/verification | presentation موحد |
| T107 | Store | إغلاق Store products rail/grid | ProductCard موحد |
| T108 | Store | إغلاق Store contact/social actions | capabilities واضحة |
| T109 | Store | إغلاق follow/follower states | repository state صريح |
| T110 | Store | إغلاق Store empty/error/offline | retry وempty actions |
| T111 | Account | إغلاق OTP/register/login states | real provider أو blocked موثق |
| T112 | Account | إغلاق profile header/editor | user contract فقط |
| T113 | Account | إغلاق orders/requests detail timeline | statuses typed |
| T114 | Account | إغلاق notifications destinations | payload typed أو read-only |
| T115 | Account | إغلاق conversations/context preview | gap contract أو placeholder معلن |
| T116 | Account | إغلاق settings/privacy persistence | فجوات persistence موثقة |
| T117 | Merchant | إغلاق merchant capability entry | role/session guard |
| T118 | Merchant | إغلاق store wizard identity/location/contact | draft محفوظ بعقد |
| T119 | Merchant | إغلاق product wizard/media/preview/submit | validation + repository |
| T120 | Merchant | إغلاق merchant dashboard/actions | لا handlers ميتة |

## مهام الإصدار والمنصات

| ID | المجال | المهمة الذرية | شرط القبول |
|---|---|---|---|
| T121 | Verification | إغلاق evidence وreview وpayment states | private media فقط |
| T122 | Subscription | إغلاق plans وproof وpending states | مصدر خطط موثق |
| T123 | Admin | إغلاق Admin shell والـauth gate | anonymous = 401/redirect |
| T124 | Admin | إغلاق product/store moderation | permission + audit |
| T125 | Admin | إغلاق merchant applications workflow | approve/reject/request-info |
| T126 | Admin | إغلاق users/admins/audit privacy | least privilege |
| T127 | Admin | إغلاق notifications/analytics states | no fake metrics |
| T128 | Landing | بناء Landing فعلية عربية RTL | route `/` يعمل |
| T129 | Landing | إضافة الهوية والنصوص التسويقية المعتمدة | لا claims غير مثبتة |
| T130 | Landing | إضافة مزايا المنصة من العقود | content traceable |
| T131 | Landing | إضافة قسم تحميل التطبيق | artifact links valid |
| T132 | Landing | إضافة SEO/Open Graph/robots | metadata checked |
| T133 | Landing | اختبار responsive/accessibility | mobile + desktop pass |
| T134 | Landing | اختبار success/error/empty للروابط | no broken CTA |
| T135 | Cloudflare | التحقق من الحساب والمشروع المصرح به | API auth pass |
| T136 | Cloudflare | إنشاء إعداد نشر قابل لإعادة الإنتاج | config no secret in Git |
| T137 | Cloudflare | بناء Landing production artifact | build pass |
| T138 | Cloudflare | إنشاء Preview deployment | URL HTTP 200 |
| T139 | Cloudflare | فحص headers/SPA routes/assets | routes/assets pass |
| T140 | Cloudflare | تثبيت رابط المعاينة في Evidence | URL + timestamp |

## بوابة القبول النهائية

لا تُغلق المهمة T072 أو تُعلن النسخة النهائية قبل تحقق جميع البنود التالية: نجاح `flutter analyze` و`flutter test` مع معالجة الفشل أو تسجيله مقابل baseline، نجاح `pnpm check/test/build` للوحة الإدارة، نجاح بناء Landing، فحص HTTP للمعاينة، تحقق تطابق إعداد Production مع Supabase، تثبيت أن Service Role غير موجود في العميل، إزالة/أرشفة النسخ القديمة وفق manifest، وإرفاق تقرير Evidence يحدد ما هو **VERIFIED** وما هو **BLOCKED** وما يحتاج إدخالًا من المستخدم.
