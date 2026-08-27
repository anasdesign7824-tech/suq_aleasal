# UI Coverage Matrix — عسلكم

## مفتاح الحالة

`NOT_STARTED` تعني أن المسار لم يدخل التنفيذ بعد. `IN_PROGRESS` تعني أن الجرد أو المواصفة بدأت ولم يكتمل التنفيذ. `DONE` لا تُستخدم إلا بعد دليل تنفيذ واختبار ومراجعة. `BLOCKED` تعني أن العقد أو البيئة لا يدعمان الادعاء دون قرار أو تكامل إضافي.

## المصفوفة

| المجال | Discovery | IA/Spec | UI | Data/State | Permissions | RTL/Responsive | Verification | Status |
|---|---|---|---|---|---|---|---|---|
| Home | مكتمل أوليًا | مكتمل | قائم يحتاج إعادة تركيب | Product/Store/Category/Banner | guest + auth actions | جزئي | لم يُعد بعد | IN_PROGRESS |
| Search | مكتمل أوليًا | مكتمل | قائم | ProductQuery/Taxonomy/Regions | guest + auth actions | جزئي | لم يُعد بعد | IN_PROGRESS |
| Categories | مكتمل أوليًا | مكتمل | قائم | categories/taxonomy | guest | جزئي | لم يُعد بعد | IN_PROGRESS |
| Products | مكتمل أوليًا | مكتمل | ProductCard/Detail قائم | AssalProductSummary | حسب المنتج والجلسة | جزئي | لم يُعد بعد | IN_PROGRESS |
| Stores | مكتمل أوليًا | مكتمل | StoreCard/Detail قائم | StoreSummary/regions | guest + follow/contact | جزئي | لم يُعد بعد | IN_PROGRESS |
| Profile | مكتمل أوليًا | مكتمل | قائم | session/profile/relations | visibility policy ناقصة | جزئي | لم يُعد بعد | IN_PROGRESS |
| Following | مكتمل أوليًا | مكتمل | Favorites يتضمن stores فقط | followed stores | auth | جزئي | لم يُعد بعد | IN_PROGRESS |
| Messages | مكتمل أوليًا | مكتمل | list/detail قائم | conversations/messages | auth | جزئي | لم يُعد بعد | IN_PROGRESS |
| Notifications | مكتمل أوليًا | مكتمل | قائم | notifications/read state | auth | جزئي | destination ناقصة | IN_PROGRESS |
| Merchant | مكتمل أوليًا | مكتمل | Dashboard قائم | workspace/products/requests | merchant capability | جزئي | لم يُعد بعد | IN_PROGRESS |
| Store Wizard | مكتمل أوليًا | مكتمل | setup/editor قائم | workspace draft/media/regions | merchant/owner | جزئي | لم يُعد بعد | IN_PROGRESS |
| Product Wizard | مكتمل أوليًا | مكتمل | editor قائم | ProductDraft/taxonomy/media | merchant/admin | جزئي | لم يُعد بعد | IN_PROGRESS |
| Orders | فجوة موثقة | جزئي | لا يوجد Order كامل | لا يوجد عقد كامل | BLOCKED | — | — | BLOCKED |
| Verification | مكتمل أوليًا | مكتمل | قائم | verification/documents/payment | merchant/admin | جزئي | device/storage pending | IN_PROGRESS |
| Admin | مكتمل أوليًا | مكتمل | React console قائم | adminApi endpoints | admin session/role/RLS | جزئي | server/RLS pending | IN_PROGRESS |
| Auth | مكتمل أوليًا | مكتمل | OTP/register قائم | auth gateway/repository | guest/auth | جزئي | provider config pending | IN_PROGRESS |
| Settings | مكتمل أوليًا | مكتمل | قائم | notification toggle local | authenticated/guest | جزئي | persistence gap | IN_PROGRESS |
| Errors | مكتمل أوليًا | مكتمل | `AssalMessageCard` جزئي | load state | per action | جزئي | لم يُعد بعد | IN_PROGRESS |
| Empty States | مكتمل أوليًا | مكتمل | `AssalStateView` جزئي | empty result | per feature | جزئي | لم يُعد بعد | IN_PROGRESS |
| Loading | مكتمل أوليًا | مكتمل | `AssalGlassLoading` قائم | future states | n/a | جزئي | لم يُعد بعد | IN_PROGRESS |
| Permissions | مكتمل أوليًا | جزئي | requireAuth جزئي | role/session | RLS/server required | جزئي | لم يُعد بعد | IN_PROGRESS |
| Responsive | جرد أولي | مكتمل | mobile/wide shell قائم | n/a | n/a | wide Flutter partial | visual check pending | IN_PROGRESS |
| RTL | جرد أولي | مكتمل | `Directionality` على مستوى التطبيق | n/a | n/a | Arabic-first | visual check pending | IN_PROGRESS |
| Images | مكتمل أوليًا | مكتمل | image tile/upload قائم | URLs/bytes/storage | public/private split | ratios pending | storage audit pending | IN_PROGRESS |
| Accessibility | جرد أولي | مكتمل | Semantics جزئي | n/a | n/a | text scaling pending | audit pending | IN_PROGRESS |
| Audit Trail | Admin discovery مكتمل | IA مكتمل | audit panel قائم | admin audit API | admin permission | web responsive pending | server evidence pending | IN_PROGRESS |
| Performance | جرد أولي | جزئي | futures/rails تحتاج مراجعة | caching غير موحد | n/a | pending | benchmark pending | IN_PROGRESS |
| Production/Offline | مكتمل من docs | مكتمل | Demo/Production boundary قائم | repository modes | auth/RLS | offline UI ناقص | integration pending | IN_PROGRESS |

## تعريف DONE

لا تنتقل الخانة إلى `DONE` بمجرد ظهور الشاشة. يلزم تنفيذ UI، وربطه بعقد البيانات، وإثبات الحالات loading/empty/error/permission المناسبة، واختبار السلوك، وفحص RTL/responsive/accessibility، ثم تسجيل commit ودليل في سجل المهام.

## Checkpoint — 2026-08-27

تمت مراجعة التنفيذ الحالي مقابل الاختبارات والأدلة. الأساسيات T008–T016 أصبحت `VERIFIED-NARROW`: route registry، explicit states، capabilities، media specs، app shell، ProductCard، StoreCard، وsession guards. كما نجحت اختبارات سلوك المنتج والمتجر والمتابعين والملف الشخصي والبحث. لا تُرفع المجالات إلى `DONE` لأن full Flutter regression ما زال يحوي 46 golden reference غير معتمدة (اعتمدت startup وProductCard فقط بعد مراجعة)، ولأن authenticated production E2E وStorage/RLS smoke وCloudflare deployment لم تُغلق بعد. يظل Orders `BLOCKED` لعدم وجود Order contract، وتظل Notifications destination وprovider config وprofile visibility فجوات صريحة.
