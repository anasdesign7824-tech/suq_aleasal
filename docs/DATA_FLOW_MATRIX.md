# DATA FLOW MATRIX — عسلكم

| المسار | يبدأ من | Data Source/Contract | Admin Control | Permission/Security | الأثر المطلوب في التطبيق | الحالة الحالية | دليل Discovery |
|---|---|---|---|---|---|---|---|
| Store onboarding | Mobile Store Wizard | merchant application contract غير مكتمل | Pending Stores + Review | merchant owner + store review RLS | ظهور حالة الطلب ثم المتجر العام بعد الموافقة | Blocked | `BecomeMerchantScreen`; ProductionRepository merchant methods |
| Store approval | Admin decision | stores/merchant_profiles status fields | Approve/Reject/Request/Suspend | store permissions + moderation guard + Audit | customer read model لا يعرض إلا الحالة النشطة | Partial/Blocked | `stores.status`; `prevent_store_moderation_changes`; customer_stores |
| Verification | Merchant evidence | merchant_profiles + private storage | Review/decision | verification permissions + private bucket RLS + Audit | الحالة تظهر للتاجر | Blocked | UI says upload unavailable; no production submit |
| Product lifecycle | Merchant/Admin CRUD | products + taxonomy/categories/images | Create/Edit/Review/Publish/Pause | owner/admin RLS + product permissions | customer_products يعرض active products | Partial | read view exists; Admin write path absent |
| Product pricing | Product form | amount/currency contract | Edit/validate/publish | product.write + field validation | price/currency visible consistently | Gap | current view reads metadata price/currency_code |
| Banner lifecycle | Admin upload | banners + storage | upload/order/activate/deactivate | banner permissions + storage policy + Audit | customer_banners → mobile carousel | Partial/Blocked | read model and DB policy exist; UI/backend absent |
| Taxonomy | canonical reference | honey_taxonomy/categories + reference JSON | compatibility/manage by policy | taxonomy permissions + RLS | same filters and product selectors | Partial | mobile reads DB; Admin reads demoCatalog |
| Regions | reference data | regions stable codes/local reference | selectors and filters | reference read/manage policy | governorate → district filtering | Partial | DB parent relation + local codes |
| Requests | Customer request | requests/request_items | Review/update/close/reply | participant/admin permissions + Audit | customer sees status/messages | Blocked | createRequest not configured |
| Messages | Customer/merchant interaction | request_messages/conversation model | read/respond/moderate as allowed | message permissions/RLS | customer/merchant sees same thread | Blocked | list/send returns empty/not configured |
| Notifications | system/event | notifications | inspect/create if approved | user/admin notification permission | user sees state | Partial | read and mark read exist |
| Reviews/comments | customer interaction | reviews/comments | approve/reject/hide | moderation permissions + RLS | only approved public content | Blocked | reads partial; writes not configured |
| Analytics | app events | event source to confirm | aggregate dashboard | analytics.read + privacy policy | dashboard indicators only | Blocked | trackProductView not configured |
| Administrator lifecycle | local admin | Auth identity + admin_users + roles | bootstrap/add/deactivate/assign | admin.manage + backend/RLS | access to local Admin only | Blocked | no Admin Auth/UI |
| Audit | every sensitive mutation | audit_logs | filter/read immutable log | audit.read + insert policy | operational evidence | Partial | table/policies exist; coverage absent |
| Public/private media | app/admin upload | assalkom_public/private | upload/replace/delete | storage policies + sensitive access | public media shown; private never public | Partial | Storage SQL exists; no Admin flow |
