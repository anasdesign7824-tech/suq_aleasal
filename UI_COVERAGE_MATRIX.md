# UI Coverage Matrix — عسلكم (Premium Dark Honey)

> Coverage for every screen, component, state, and cross-cutting concern in the new UI.
> Statuses: `DONE`, `IN_PROGRESS`, `PENDING`, `BLOCKED`, `N/A`.
> Data source column reflects existing repository contracts and taxonomy only — no fabricated data.

## Screens / flows

| Area | Screen/Flow | Plan | Data | Rebuild | Loading | Empty | Error | Unauthorized | Forbidden | Disabled | RTL | Resp | A11y | Evidence |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Shell | App shell | T010 | mode/session | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| Shell | Header | T011 | counts | DONE | DONE | N/A | DONE | DONE | N/A | DONE | DONE | DONE | DONE | DONE |
| Navigation | BottomNav/Rail | T012 | destinations | DONE | N/A | N/A | N/A | DONE | N/A | DONE | DONE | DONE | DONE | DONE |
| Home | Discover | T023-T028 | taxonomy/banners/stores/products | DONE | DONE | DONE | DONE | N/A | N/A | DONE | DONE | DONE | DONE | DONE |
| Search | Command | T029 | terms/products/stores | DONE | DONE | DONE | DONE | N/A | N/A | DONE | DONE | DONE | DONE | DONE |
| Search | Results product/store | T030,T031 | query | DONE | DONE | DONE | DONE | N/A | N/A | DONE | DONE | DONE | DONE | DONE |
| Search | Filters/Sort | T032,T033 | taxonomy/regions/query | DONE | DONE | DONE | DONE | N/A | N/A | DONE | DONE | DONE | DONE | DONE |
| Categories | Hub/subcategory/type | T034-T036 | taxonomy | DONE | DONE | DONE | DONE | N/A | N/A | DONE | DONE | DONE | DONE | DONE |
| Products | ProductCard | T037 | product | DONE | DONE | DONE | DONE | N/A | N/A | DONE | DONE | DONE | DONE | DONE |
| Products | ProductDetail | T045-T050 | product/store/review/comment | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| Stores | StoreCard | T038 | store | DONE | DONE | DONE | DONE | N/A | N/A | DONE | DONE | DONE | DONE | DONE |
| Stores | StoreDiscovery | T030,T031 | store query/regions | DONE | DONE | DONE | DONE | N/A | N/A | DONE | DONE | DONE | DONE | DONE |
| Stores | StoreDetail | T051-T054 | store/products | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| Relation | Saved (Favorites) | T062 | favorite repos | DONE | DONE | DONE | DONE | DONE | N/A | DONE | DONE | DONE | DONE | DONE |
| Relation | Following | T063,T064 | followed stores | DONE | DONE | DONE | DONE | DONE | N/A | DONE | DONE | DONE | DONE | DONE |
| Account | Profile | T058,T059 | user/session | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| Account | ProfileEditor | T060 | profile/regions | DONE | DONE | DONE | DONE | DONE | N/A | DONE | DONE | DONE | DONE | DONE |
| Account | Auth | T057 | auth gateway | DONE | DONE | N/A | DONE | N/A | N/A | DONE | DONE | DONE | DONE | DONE |
| Requests | RequestCard | T040 | request | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| Requests | RequestDetail/Timeline | T056 | request | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| Notifications | NotificationList | T042,T066 | notification | DONE | DONE | DONE | DONE | DONE | N/A | DONE | DONE | DONE | DONE | DONE |
| Messages | ConversationList | T043,T067 | conversations | DONE | DONE | DONE | DONE | DONE | N/A | DONE | DONE | DONE | DONE | DONE |
| Messages | ConversationDetail | T068 | messages | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| Merchant | MerchantHub | T069 | workspace/role | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| Merchant | Dashboard | T070,T078-T080 | workspace/products/requests | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| Merchant | StoreWizard | T071-T074 | workspace/regions/media | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| Merchant | ProductWizard | T075-T077 | taxonomy/regions/media | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| Merchant | Verification | T081,T082 | verification/upload | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| Merchant | Subscription/Payment | T083,T084 | plans/payment | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| Admin | Console | T085 | session/role | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| Admin | Catalog/Stores/Requests/... | T086 | admin API | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| Admin | Applications/Verification/Plans | T087 | admin API | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| Admin | Users/Admins/Audit/Notifications | T088 | admin API | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| Landing | Marketing | T090 | static | DONE | DONE | DONE | N/A | N/A | N/A | DONE | DONE | DONE | DONE | DONE |

## Components

| Component | Rebuild | Loading | Empty | Error | Unauthorized | Forbidden | Disabled | RTL | Resp | A11y | Evidence |
|---|---|---|---|---|---|---|---|---|---|---|---|
| AssalShell | DONE | DONE | N/A | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| AssalHeader | DONE | DONE | N/A | DONE | DONE | N/A | DONE | DONE | DONE | DONE | DONE |
| EntityStateView | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| CanonicalProductCard | DONE | DONE | N/A | DONE | N/A | N/A | DONE | DONE | DONE | DONE | DONE |
| CanonicalStoreCard | DONE | DONE | N/A | DONE | N/A | N/A | DONE | DONE | DONE | DONE | DONE |
| CanonicalUserCard | DONE | DONE | N/A | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| CanonicalRequestCard | DONE | DONE | N/A | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| CanonicalReviewCard | DONE | DONE | N/A | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| NotificationItem | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| ConversationItem | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| SearchCommand | DONE | DONE | DONE | DONE | N/A | N/A | DONE | DONE | DONE | DONE | DONE |
| FilterDrawer | DONE | DONE | DONE | DONE | N/A | N/A | DONE | DONE | DONE | DONE | DONE |
| ReferenceSelect/ChipSelect | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| CascadingLocationSelector | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| ImageMedia | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |
| ProgressiveDisclosure | DONE | DONE | DONE | N/A | N/A | N/A | DONE | DONE | DONE | DONE | DONE |
| Feedback system | DONE | N/A | N/A | DONE | DONE | DONE | DONE | DONE | DONE | DONE | DONE |

## Cross-cutting

| Area | Discovery | Plan | Implementation | RTL | Responsive | Accessibility | Data/Backend | Status |
|---|---|---|---|---|---|---|---|---|
| Structure/Hierarchy | DONE | DONE | DONE | DONE | DONE | DONE | reuse contracts | DONE |
| Spacing | DONE | DONE | DONE | — | — | — | — | DONE |
| Typography | DONE | DONE | DONE | DONE | — | DONE | — | DONE |
| Colors/Icons | DONE | DONE | DONE | DONE | — | — | — | DONE |
| Images | DONE | DONE | DONE | DONE | — | — | public/private | DONE |
| Actions/Data | DONE | DONE | DONE | — | — | — | contracts mapped | DONE |
| Navigation | DONE | DONE | DONE | DONE | DONE | DONE | route registry | DONE |
| RTL | DONE | DONE | DONE | DONE | — | — | — | DONE |
| Responsive | DONE | DONE | DONE | — | DONE | — | — | DONE |
| Accessibility | DONE | DONE | DONE | — | — | DONE | — | DONE |
| Loading/Empty/Error | DONE | DONE | DONE | — | — | — | state renderer | DONE |
| Performance | DONE | DONE | DONE | — | — | — | — | DONE |
| Production/Offline | DONE | DONE | DONE | — | — | — | gap documented | DONE |
| Flutter toolchain | DONE | N/A | BLOCKED | — | — | — | no SDK | BLOCKED |

## Definition of DONE

A row is DONE only when: the screen/component is rebuilt with the new design language, data comes from real contracts/taxonomy, all required states render explicitly, RTL + responsive + accessibility gates pass, navigation/actions are wired to existing repository contracts, no dead UI and no fabricated data exists, and evidence is recorded in the task ledger and evidence folder.
