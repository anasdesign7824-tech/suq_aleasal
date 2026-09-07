# UI Rebuild Task Ledger — عسلكم

> Phase 0 discovery is finished. The premium dark honey reconstruction has been implemented across the customer, merchant, admin, and landing surfaces.
> Status rules: `VERIFIED` = document/evidence produced. `DONE` = implementation wired to existing contracts. `BLOCKED` = cannot proceed without backend/SDK decision.
> Runtime Flutter verification remains `BLOCKED` by GAP-021 (no Flutter/Dart SDK in the sandbox); static checks were completed.

## Phase 0 — Discovery (produced now)

| ID | Focus | Description | Evidence/Output | Status |
|---|---|---|---|---|
| T001 | Discovery | Inventory all screens, routes, components, data, taxonomy, contracts | `UI_RECONSTRUCTION_DISCOVERY.md` | VERIFIED |
| T002 | IA | New Customer/Merchant/Admin/Landing information architecture | `UI_INFORMATION_ARCHITECTURE.md` | VERIFIED |
| T003 | Data gaps | Record missing data the new UI needs | `UI_DATA_GAP_REGISTER.md` | VERIFIED |
| T004 | Backend gaps | Record backend/database gaps without touching them | `UI_BACKEND_GAP_REPORT.md` | VERIFIED |
| T005 | Design system | New from-scratch design system spec | `UI_DESIGN_SYSTEM_SPEC.md` | VERIFIED |
| T006 | Entity presentation | Canonical entity presentations | `UI_ENTITY_PRESENTATION_SPEC.md` | VERIFIED |
| T007 | Gap register | Consolidated UX gaps | `UI_GAP_REGISTER.md` | VERIFIED |
| T008 | Coverage | UI coverage matrix | `UI_COVERAGE_MATRIX.md` | VERIFIED |
| T009 | Atomic tasks | 80 atomic UI tasks | `UI_RECONSTRUCTION_TASK_LEDGER.md` | VERIFIED |

## Implementation tasks

### A. Foundation (shared UI system)

| ID | Task | Screen/Component | Data | States | Access | Depends | Status |
|---|---|---|---|---|---|---|---|
| T010 | AssalShell | app shell + light surface | repository mode/session | loading/error | n/a | T005 | DONE |
| T011 | AssalHeader | header | session, notification count | compressed/expanded | auth | T010 | DONE |
| T012 | BottomNavigation / Rail | main nav | destinations | selected/badge | guest/auth | T010 | DONE |
| T013 | Route registry migration | all screens | entity ids | depth/context | guards | T002 | DONE |
| T014 | AuthGuard/CapabilityGuard | guard | session, role, workspace | unauthorized/forbidden | guest/auth/merchant | T010 | DONE |
| T015 | EntityStateView / skeletons | all screens | load state | 8 states | n/a | T005 | DONE |
| T016 | Primitive tokens + components | design pkg | tokens | all | n/a | T005 | DONE |
| T017 | ImageMedia | media | image URLs/storage | loading/error/empty/ratio | public/private | T005 | DONE |
| T018 | ReferenceSelectors (taxonomy/grade/badge/pack/type) | forms | JSON/listTypes | loading/empty/error | merchant/admin | T003 | DONE |
| T019 | CascadingLocationSelector | geographic fields | governorates/districts | loading/empty/error | all | T018 | DONE |
| T020 | FilterDrawer | search/filters | query/taxonomy/regions | grouped states | guest | T016 | DONE |
| T021 | Feedback system | dialogs/snack/toasts | repo results | success/error/disabled | all | T015 | DONE |
| T022 | RTL/accessibility/responsive base | all | n/a | all | n/a | T016 | DONE |

### B. Customer discovery

| ID | Task | Screen/Component | Data | States | Access | Depends | Status |
|---|---|---|---|---|---|---|---|
| T023 | Home discovery layout | Home | banners/categories/stores/products | skeleton/empty/error | guest | T010,T015 | DONE |
| T024 | Home hero/campaign | Home | banners | loading/error/empty | guest | T023 | DONE |
| T025 | Home category rail | Home | categories/taxonomy | loading/empty/error | guest | T018 | DONE |
| T026 | Home featured/newest | Home | products query | loading/empty/error | guest | T014 | DONE |
| T027 | Home personalized/recommended | Home | session/favorites/followed/data | auth-empty | guest/auth | T014 | DONE |
| T028 | Home related/store front | Home | stores | loading/empty/error | guest | T014 | DONE |
| T029 | Global SearchCommand | Search | popular/recents/products/stores | idle/typing/empty/error | guest | T016 | DONE |
| T030 | Search results product mode | Search | product query | loading/empty/error | guest | T014 | DONE |
| T031 | Search results store mode | Search | store query | loading/empty/error | guest | T014 | DONE |
| T032 | Search filters | Search | taxonomy/regions/query | grouped | guest | T020 | DONE |
| T033 | Search sort | Search | AssalSort | selected | guest | T032 | DONE |
| T034 | Categories hub | Categories | real taxonomy (5 cats) | loading/empty/error | guest | T018 | DONE |
| T035 | Subcategory browse | Categories | subcategories | loading/empty/error | guest | T034 | DONE |
| T036 | Product-type landing | Categories | products | loading/empty/error | guest | T035 | DONE |

### C. Canonical entity renderers

| ID | Task | Screen/Component | Data | States | Access | Depends | Status |
|---|---|---|---|---|---|---|---|
| T037 | ProductCard grid | catalog | product summary | compact/rail/grid | guest | T016 | DONE |
| T038 | StoreCard | store discovery | store summary | list/verified | guest | T016 | DONE |
| T039 | UserCard | profile/people | user profile | public/owner | guest/auth | T016 | DONE |
| T040 | RequestCard | requests | request summary | list/detail | auth | T016 | DONE |
| T041 | ReviewCard | product/social | review | normal/merchant-reply | auth | T016 | DONE |
| T042 | NotificationItem | notifications | notification | unread/read/destination | auth | T016 | DONE |
| T043 | ConversationItem | messages | conversation | unread/context | auth | T016 | DONE |
| T044 | StorePreview | product | store summary | compact | guest | T038 | DONE |

### D. Customer detail flows

| ID | Task | Screen/Component | Data | States | Access | Depends | Status |
|---|---|---|---|---|---|---|---|
| T045 | Product gallery | product detail | images | slide/loading/error | guest | T017 | DONE |
| T046 | Product identity/commerce/actions | product detail | product | quick actions/request/auth | guest/auth | T037 | DONE |
| T047 | Product metadata (origin/quality/taxonomy/production/packaging/certs) | product detail | product fields | collapsible | guest | T018 | DONE |
| T048 | Product StorePreview + CTA | product detail | store | loading/empty/error | guest/auth | T044 | DONE |
| T049 | Product reviews/comments | product detail | review/comment | loading/empty/error/forbidden | auth | T041 | DONE |
| T050 | Product similar | product detail | products | loading/empty/error | guest | T037 | DONE |
| T051 | Store profile hero/identity | store detail | store | loading/empty/error | guest | T038 | DONE |
| T052 | Store products | store detail | store products | loading/empty/error | guest | T037 | DONE |
| T053 | Store info/location/certs | store detail | store | collapsible | guest | T038 | DONE |
| T054 | Store contact/follow/related | store detail | store | actions/auth-states | auth | T038 | DONE |
| T055 | Request sheet/flow | product/store | request draft | validation/submit/auth | auth | T004 | DONE |
| T056 | Request list/detail/timeline | requests | requests | loading/empty/error | auth | T040 | DONE |

### E. Account & relations

| ID | Task | Screen/Component | Data | States | Access | Depends | Status |
|---|---|---|---|---|---|---|---|
| T057 | Auth visual flow | auth | auth gateway | loading/error/rate/expired | guest | T015 | DONE |
| T058 | Profile identity + visibility | profile | user/profile | owner/guest | auth | T039 | DONE |
| T059 | Profile tabs (activity/products/stores/about) | profile | user/session | empty | auth | T039 | DONE |
| T060 | Profile editor + canonical location | profile editor | user/patches/region | upload/state/save | auth | T019 | DONE |
| T061 | My Store card / merchant entry | profile | workspace/role | no-workspace/merchant | auth | T010 | DONE |
| T062 | Saved hub (Products/Stores/Taxonomies) | favorites | favorite repos | loading/empty/error | auth | T037,T038 | DONE |
| T063 | Following hub (stores) | following | followed stores | loading/empty/error | auth | T038 | DONE |
| T064 | Following People disabled state | following | — | documented gap | auth | T003 | DONE |
| T065 | Settings grouping | settings | session/local | persistent gap | guest/auth | T015 | DONE |
| T066 | Notifications list + destination | notifications | notifications | unread/read/empty | auth | T042 | DONE |
| T067 | Conversations list + context | messages | conversations | unread/empty | auth | T043 | DONE |
| T068 | Conversation detail/composer | messages | messages | send/error/read | auth | T015 | DONE |

### F. Merchant

| ID | Task | Screen/Component | Data | States | Access | Depends | Status |
|---|---|---|---|---|---|---|---|
| T069 | Merchant hub/entry | merchant | workspace/role | no-workspace/capability | merchant | T010 | DONE |
| T070 | Merchant overview | dashboard | workspace | plan/verification states | merchant | T069 | DONE |
| T071 | Store wizard step identity | merchant | workspace draft | validation/draft | merchant | T018 | DONE |
| T072 | Store wizard location/info/contact | merchant | regions | cascading | merchant | T019 | DONE |
| T073 | Store wizard media | merchant | uploads | upload/resume | merchant | T017 | DONE |
| T074 | Store wizard review/submit | merchant | workspace | submit/permission | merchant | T071-T073 | DONE |
| T075 | Product wizard basic/category/type | merchant | taxonomy | validation | merchant | T018 | DONE |
| T076 | Product wizard origin/quality/price/availability | merchant | regions/taxonomy | validation | merchant | T018,T019 | DONE |
| T077 | Product wizard attributes/certs/images/description/review/submit | merchant | repo | upload/submit | merchant | T017,T018 | DONE |
| T078 | Merchant product management states | dashboard | product status | draft/pending/active/paused/rejected | merchant | T075-T077 | DONE |
| T079 | Merchant requests | dashboard | merchant requests | loading/empty/error | merchant | T040 | DONE |
| T080 | Merchant analytics (available counters) | dashboard | counters | data-backed | merchant | T018 | DONE |

### G. Verification / subscriptions

| ID | Task | Screen/Component | Data | States | Access | Depends | Status |
|---|---|---|---|---|---|---|---|
| T081 | Verification lifecycle UI | verification | verification | draft/payment/review | merchant | T015 | DONE |
| T082 | Verification document/private media | verification | uploads | private state | merchant | T017 | DONE |
| T083 | Subscription plans | subscriptions | plan/campaign | loading/empty/error | merchant | T018 | DONE |
| T084 | Payment proof flow | subscriptions | payment | upload/submit | merchant | T017 | DONE |

### H. Admin / Landing

| ID | Task | Screen/Component | Data | States | Access | Depends | Status |
|---|---|---|---|---|---|---|---|
| T085 | Admin shell | admin | session/role | auth/permission | admin | T010 | DONE |
| T086 | Catalog/product/store admin | admin | admin API | typed/loading/error | admin | T037,T038 | DONE |
| T087 | Merchant applications/verification/plans | admin | admin API | typed/states | admin | T081-T084 | DONE |
| T088 | Users/admins/audit/notifications | admin | admin API | privacy/permission | admin | T042,T058 | DONE |
| T089 | Admin responsive web | admin | n/a | mobile/tablet/desktop | admin | T016 | DONE |
| T090 | Landing marketing IA | landing | static | empty/loading | public | T005 | DONE |

## Final status note

Implementation tasks T010–T090 are marked `DONE` against the rebuilt premium dark honey UI. Gate sequence applied: structure → spacing → typography → color → icons → images → actions → data → state → navigation → RTL → responsive → accessibility → state/edge → evidence → close. Runtime Flutter gates (analyze/test) remain `BLOCKED` due to missing SDK (GAP-021).
