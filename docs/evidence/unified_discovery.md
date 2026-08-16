# Unified Discovery — Customer / Merchant / Auth / Storage / Admin

**Baseline:** `f65f1c0` بعد Authority وRepository Inventory.

## الخلاصة التنفيذية

المشروع يملك Customer foundation وDemo catalog وRepository boundary وDesign System وFlutter Web/APK evidence سابقة. لكنه لا يملك بعد مسار Production متكاملًا للمصادقة والرفع والكتابة والمزامنة، ولا Merchant Wizard حقيقيًا، ولا Admin CRUD متصلًا بقاعدة البيانات. لذلك يبدأ التنفيذ من الحفاظ على Customer، ثم إكمال Production boundaries، ثم Merchant، ثم Admin المحلي، ثم Battle-Test.

## الحالة الحالية حسب المسار

| المسار | ما يعمل فعليًا | الفجوة التي تمنع الإطلاق الكامل | قرار التنفيذ |
|---|---|---|---|
| Customer discovery | Home، carousel، categories، search، honey filters، product/store detail، favorites، requests، messages، notifications، RTL/responsive | Production auth/data/session والاختبارات الميدانية | Regression أولًا ثم لا إعادة بناء بلا root cause |
| Customer Auth | Demo/typed boundary؛ Google contract سابق | Email/Google/Facebook production callback/session restore غير مثبتة | تنفيذ Provider adapters واختبار Cross-platform |
| Profile | metrics وfavorites/following/requests/settings | history والقدرات التجارية والمزامنة الحقيقية | capability-aware profile |
| Merchant entry | `BecomeMerchantScreen` أحادي الخطوة وDemo notification | Wizard، draft/resume، media، location، delivery، docs، verification | نفس Auth UID وMerchant Capability |
| Merchant dashboard | Stub محدود في `merchant_dashboard.dart` | management حقيقي للمتجر والمنتجات والطلبات والرسائل والتحليلات | استبدال Stub بعقود وscreens تدريجيًا |
| Product management | read-only `AssalProductSummary` وcatalog | ProductDraft/create/edit/publish وgeneric taxonomy | canonical generic product model |
| Taxonomy | master database غني وDemo mapping سطحي | adapter مركزي ومحددات مشتركة وAdmin compatibility | مصدر واحد مع IDs وprovenance |
| Locations | 10 regions سطحية في Demo | Governorate→District cascading source | مصدر JSON مثبت، محافظات/مديريات فقط |
| Media/Storage | URLs demo؛ bucket `sok1` ظاهر في Supabase | policies، path convention، upload states، private docs | public media/private verification policies |
| Verification | enum/status عام فقط | documents/PDF/selfie/business evidence وحالات انتقال | evidence model + Admin review |
| Analytics | `viewsCount` read-only | event contracts، buffering، deferred sync، aggregates | deterministic analytics only |
| Database/RLS | migrations `0001`–`0006` وطبقات أمن أساسية | policies/columns/functions اللازمة للمسارات الجديدة غير مثبتة اختباريًا | GAP review ثم additive migrations |
| Admin | React/Vite RTL visual shell وDemo catalog pages | Auth/role guard/repository/CRUD/Storage/Banners/Notifications/Audit/RLS | توسيع الموجود محليًا، لا لوحة ثانية |
| Landing | README فقط | public marketing/Cloudflare | مؤجل ولا يحجب Customer/Admin release |

## Auth configuration status

تم توفير Google Android/Web client IDs وpackage/SHA-1 وSupabase callback من المستخدم. وجود القيم في المحادثة لا يثبت أن Provider configuration أو callback flow يعمل. لا تُحفظ Client Secrets داخل repo أو client bundle. بوابة Auth تتطلب تحققًا فعليًا من Email/Google/Facebook Web/APK، مع تسجيل أي إعداد خارجي غير قابل للوصول كـ `BLOCKED`.

## Storage configuration status

وجود bucket `sok1` لا يثبت public/private policy أو ownership. يجب فحص bucket settings، object paths، MIME/size، RLS على `storage.objects`، وDB media references. لا تُفتح الكتابة العامة لتجاوز نقص Admin أو Auth. Verification documents تفصل عن public store/product/banner media.

## Admin scope status

بناءً على موافقة المستخدم، Admin المحلي أصبح جزءًا من هذا التنفيذ. المقصود “محلي” هو عنوان تشغيل محلي، وليس بلا حماية. الدخول يكون عبر Supabase Auth Admin user مع role/RLS، ولا تُمنح صلاحية كاملة لمجرد الوصول إلى localhost. Public Admin deployment وLanding يبقيان خارج هذا الإصدار.

## Root-cause gaps

| ID | GAP | ROOT CAUSE | IMPACT | REQUIRED CHANGE |
|---|---|---|---|---|
| U-001 | Real Auth missing | providers/data source/session restore not wired | no cross-platform identity | Auth contracts/adapters/tests |
| U-002 | Admin is Demo | Home reads `demoCatalog` and Demo toasts | no real operational control | Admin repository + Supabase/RLS |
| U-003 | Storage unverified | bucket existence without policy/path audit | uploads/security unknown | Storage audit/policies/real upload tests |
| U-004 | Merchant incomplete | one-step application and Stub dashboard | cannot open/manage a store | wizard/domain/repository/screens |
| U-005 | Verification absent | generic status without evidence model | no safe trust badge | documents/status/review/audit |
| U-006 | Analytics absent | read-only count | no trustworthy metrics | events/buffer/aggregates |
| U-007 | Location shallow | Demo regions only | no cascading governorate/district | canonical source adapter |
| U-008 | Acceptance incomplete | build-only historical evidence | false release confidence | Battle-Test and cross-system evidence |

## Current blockers to record, not bypass

1. Facebook provider credentials/configuration must be verified before claiming Facebook PASS.
2. Supabase Admin user creation and role schema must be verified through the authorized database connector before Admin PASS.
3. Storage policies and a safe test namespace must be verified before real upload PASS.
4. Release signing key remains separate from debug/SHA configuration; it must not be invented.
5. Camera/selfie capture depends on platform capability; upload fallback is required, but a real selfie PASS needs device verification.

## Discovery gate

Discovery is complete for current repository scope. No production claim is made from this document. Next actions are environment contract, traceability commit, then Auth/Storage read-only audits.
