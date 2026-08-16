# خطة التنفيذ الذرية — 60 مهمة

هذه النسخة الذرية توسّع الخطة الموحدة السابقة. لا تُغلق أي مهمة إلا بعد دورة: **PLAN → IMPLEMENT → RUN → VERIFY → TEST → VISUAL/SECURITY CHECK → EVIDENCE → COMMIT**. كل مهمة لها مخرج وبوابة مستقلة.

| # | المهمة الذرية | المخرج الإلزامي | بوابة القبول |
|---:|---|---|---|
| 1 | تثبيت مصادر السلطة | Authority baseline وبصمات الملفات | المصادر قابلة للتحقق |
| 2 | جرد monorepo | Inventory للمسارات والملفات | لا مكوّن مجهول |
| 3 | جرد Customer Flutter | feature/build/test baseline | Customer الحالي محفوظ |
| 4 | جرد Merchant الحالي | Store/Application/Dashboard gap | Stub موثق |
| 5 | جرد Admin الحالي | routes/demo data/UI gap | shell موثق |
| 6 | جرد Database/migrations | schema/RLS/migration map | لا SQL تخميني |
| 7 | جرد Storage/assets | buckets/paths/fonts/images | provenance محفوظ |
| 8 | Discovery موحّد | GAP→ROOT CAUSE→IMPACT→CHANGE | baseline معتمد |
| 9 | Traceability 60 بندًا | matrix files/tests/status | لا requirement orphan |
| 10 | عقد البيئات والأسرار | deployment/env contract | لا secret في Git/client |
| 11 | اكتشاف موصل Supabase MCP | project/tool evidence | project صحيح |
| 12 | اختبار موصل Supabase API | REST health evidence | HTTP 200 صحيح |
| 13 | اختبار الموصل المخصص | service-role health evidence | HTTP 200 بلا كشف سر |
| 14 | مقارنة الموصلات الثلاثة | connector audit report | نفس المشروع والهوية |
| 15 | تدقيق Auth settings | Email/Google/Facebook flags | configuration evidence |
| 16 | تدقيق Google redirects | Web callback + Android deep-link | لا loop أو mismatch |
| 17 | تدقيق Facebook callback | provider redirect/config | provider path محدد |
| 18 | عقد Auth Domain | provider/session/error models | compile + contract tests |
| 19 | Demo Auth implementation | local sign-in/disabled reasons | Demo بلا Supabase |
| 20 | Production Auth adapter | gateway/client boundary | لا UI direct Auth |
| 21 | إنشاء Admin Auth user | Auth user + safe handoff | user exists; secret خارج Git |
| 22 | ربط Admin role | admin_users/admin_roles/profile | role policy tested |
| 23 | تدقيق `is_admin()` | function security report | لا role self-escalation |
| 24 | اختبار RLS baseline | anon/customer/merchant/admin matrix | failures documented |
| 25 | تصميم security migration | additive SQL + rollback notes | review قبل التنفيذ |
| 26 | تطبيق RLS migration | policies/functions/indexes | migration succeeds |
| 27 | اختبار RLS إيجابي | allowed actions evidence | owner/admin pass |
| 28 | اختبار RLS سلبي | IDOR/privilege tests | cross-owner denied |
| 29 | تدقيق Storage bucket | bucket/MIME/size/publicity | classification correct |
| 30 | اتفاق مسارات Storage | public/private path contract | canonical paths |
| 31 | Storage policies | object ownership/admin policies | no broad public write |
| 32 | Media repository | upload/delete/replace states | Demo/Production parity |
| 33 | Upload integration fixture | real isolated image/PDF upload | URL/path verified |
| 34 | Taxonomy master adapter | canonical hierarchy/IDs | source hash preserved |
| 35 | Location provenance | governorate/district source | version/license recorded |
| 36 | Cascading selectors | governorate→district search | invalid sequence blocked |
| 37 | Shared reference repository | taxonomy/location/delivery refs | one source used |
| 38 | Customer Auth UI | Email→Google→Facebook order | no dead button |
| 39 | Session restoration | profile/favorites/follows/history | browser/APK restart pass |
| 40 | Customer Production reads | Home/Search/Product/Store source | loading/error/retry pass |
| 41 | Customer Production writes | favorites/follows/reviews/requests | owner/RLS pass |
| 42 | Merchant identity capability | same user→merchant mode | no separate account |
| 43 | Store Wizard state | draft/progress/back/resume | kill/resume pass |
| 44 | Store identity/business steps | structured fields/validation | invalid next blocked |
| 45 | Store media/location steps | logo/cover/gallery/location | upload/cascade pass |
| 46 | Delivery/pickup steps | methods/points/skip-later | product/store display pass |
| 47 | Documents/verification steps | PDF/images/status machine | private evidence pass |
| 48 | Store submit/profile | submit/review/public profile | no false verified |
| 49 | Product domain draft | generic product/taxonomy/media | canonical IDs |
| 50 | Product create/edit wizard | metadata/images/availability | validation + Demo pass |
| 51 | Merchant dashboard management | products/requests/messages/store | each CTA works |
| 52 | Views analytics events | view contract/dedupe/throttle | deterministic events |
| 53 | Buffered sync/performance | batch/retry/cache/lazy load | bounded network/memory |
| 54 | In-App notifications | DB events/read state/admin insert | badge/read lifecycle |
| 55 | Admin shell/auth routing | local login/role guard/layout | non-admin denied |
| 56 | Admin users/merchants/stores | list/search/filter/detail/status | RLS and audit pass |
| 57 | Admin products/taxonomy/verification | moderation/approval/rejection | status sync pass |
| 58 | Admin banners/storage | upload/schedule/enable/order/CTA | Admin→Home sync pass |
| 59 | Admin notifications/audit/analytics | create notification/logs/metrics | customer receipt + audit |
| 60 | Full Battle-Test and release | Web/APK/Mimo/Admin/E2E/security/pressure/evidence | GO/CONDITIONAL/NO-GO formal |

## قاعدة التسليم

المهمة 60 لا تُغلق من خلال build فقط. يجب أن تشمل تقريرًا بأرقام وبيانات الاختبار، raw logs وscreenshots حيث يلزم، نتائج Auth/RLS/Storage، نتائج failure/pressure/soak، cleanup للـ fixtures، hashes للـ artifacts، Known Issues، وقرار إطلاق رسمي. أي إعداد لا يمكن الوصول إليه يُسجل `BLOCKED` مع المطلوب من المستخدم بدل تجاوزه.
