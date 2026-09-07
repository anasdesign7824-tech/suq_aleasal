# BACKEND GAP REPORT — عسلكم (Phase 0)

> تم اكتشاف هذه الفجوات أثناء Discovery فقط. **لا يتم تعديل أي Backend/Database/Supabase/RLS في Phase 0.**
> كل بند يوضح: الواجهة تحتاج ماذا، ولماذا، وما هو البديل الآمن حاليًا.

## 1. Full Order flow

| Item | Value |
|---|---|
| UI need | تجربة طلب تجاري كاملة (إضافة منتج → سلة/كمية → عنوان/تسليم → دفع → حالة طلب → تتبع) |
| Current | `AssalRequestSummary` + `createRequest` (طلب تواصل، ليس Order) |
| Why needed | Customer/Request UI بالمطلوب في التعليمات |
| Safe alternative | إبقاء "طلب تواصل" كما هو، مع عدم عرض Checkout كامل أو حالات دفع لا يملكها العقد |
| Backend change | `Yes` — جداول/عيقد Order ودفع وتتبع |
| Action | `BACKEND_GAP` — لا تنفذ في Phase 0 |

## 2. Following People

| Item | Value |
|---|---|
| UI need | صفحة Following مع تبويب People/Stores |
| Current | `toggleFollow(userId, storeId)` فقط |
| Why needed | فهم متابعة المستخدمين وتمييزها عن متابعة المتاجر |
| Safe alternative | عرض `Following Stores` فقط، وكتابة `UI_DATA_GAP` لـ Following People |
| Backend change | `Yes` (جدول/عقد متابعة مستخدم) |
| Action | `BACKEND_GAP` |

## 3. Notification destinations

| Item | Value |
|---|---|
| UI need | Notification → product/store/request/conversation |
| Current | `payload` هو `Map<String,Object?>` غير typed |
| Why needed | "لا إشعار لا يؤدي إلى أي مكان" |
| Safe alternative | الإشعار read-only إذا لم يوجد destination، مع إبقاء mark read |
| Backend change | `Probably yes` (payload schema / route contract) |
| Action | `BACKEND_GAP` |

## 4. Conversation product/request context

| Item | Value |
|---|---|
| UI need | رأس المحادثة يعرض متجر/منتج/طلب |
| Current | `storeId` + `storeName` only |
| Safe alternative | عرض متجر فقط، واترك context empty state |
| Backend change | `Yes` (conversation context columns) |
| Action | `BACKEND_GAP` |

## 5. User preferences persistence

| Item | Value |
|---|---|
| UI need | settings notifications/theme/language persist |
| Current | local session toggle |
| Safe alternative | local-only + documented gap |
| Backend change | `Yes` (preferences ops) |
| Action | `BACKEND_GAP` |

## 6. Analytics

| Item | Value |
|---|---|
| UI need | real metrics (views per product, conversions, requests/social) |
| Current | counters + `trackProductView` |
| Safe alternative | عرض counters الموجودة فقط؛ لا اختراع أرقام |
| Backend change | `Yes` (events aggregation) |
| Action | `BACKEND_GAP` |

## 7. Profile visibility / privacy policy

| Item | Value |
|---|---|
| UI need | field-level visibility for email/phone/location |
| Current | no policy contract |
| Safe alternative | show own account data only; avoid exposing others' sensitive fields |
| Backend change | `Probably yes` |
| Action | `BACKEND_GAP` |

## 8. Full taxonomy-backed selectors on merchant/admin

| Item | Value |
|---|---|
| UI need | reference-driven dropdowns/chips for category/type/grade/badge/packaging/location |
| Current | product editor uses mostly comma strings + partial dropdowns |
| Safe alternative | use `listTaxonomy`/`listRegions`/JSON reference + chips; keep commas only where no source exists |
| Backend change | `No` (except explicit reference endpoints) |
| Action | `OPEN` UI-only |

## 9. Admin typed API

| Item | Value |
|---|---|
| UI need | typed presentation across admin panels |
| Current | many `unknown` values in `admin-api.ts` |
| Safe alternative | build typed adapters; don't render unknown fields as if typed |
| Backend change | `Probably yes` (response schemas) |
| Action | `BACKEND_GAP` |

## 10. Flutter SDK availability

| Item | Value |
|---|---|
| UI need | run `flutter analyze/test/build` for visuals/regression |
| Current | no Dart/Flutter SDK in sandbox (`which flutter`/`which dart` empty) |
| Safe alternative | static review + web preview where possible; mark Flutter checks `BLOCKED` |
| Backend change | No |
| Action | `BACKEND_GAP` / `ENV GAP` |
