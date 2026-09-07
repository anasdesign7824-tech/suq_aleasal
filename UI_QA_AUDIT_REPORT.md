# UI QA / Quality Audit Report — عسلكم

**Date:** 2026-09-07  
**Branch:** `arena/01a079dd-suq-aleasal`  
**Scope:** UI-only rebuild, premium dark honey + default beige theme switch.

## 1. Contract compliance (UI vs existing data layer)

Verified by static inspection of every repository call used by the rebuilt screens against
`packages/data_dart/lib/assal_repository.dart` and `packages/contracts_dart/lib/assal_domain.dart`.

| Call | Contract present | Signature matched | Notes |
|---|---|---|---|
| `listTaxonomy()`, `listCategories()`, `listRegions()` | YES | YES | taxonomy/data filters use existing records |
| `listBanners()`, `listPopularSearches()`, `listStores()` | YES | YES | Home / Stores only read real data |
| `listProducts(query:)`, `getProduct()`, `getStore()` | YES | YES | query fields match `AssalProductQuery` |
| `listFavoriteProducts`, `listFollowedStores`, `listFavoriteTaxonomies` | YES | YES | Saved/Following remain separate |
| `toggleFollow`, `toggleFavorite`, `toggleLike` | YES | YES | no custom relation table introduced |
| `listReviews`, `listComments`, `createReview`, `createComment` | YES | YES | drafts match `AssalReviewDraft`/`createComment` |
| `listRequests`, `createRequest` | YES | YES | `AssalRequestDraft` fields match |
| `listConversations`, `listMessages`, `sendMessage` | YES | YES | `AssalMessageDraft(conversationId, body)` matches |
| `listNotifications`, `markNotificationRead` | YES | YES | match |
| `loadMerchantApplicationDraft`, `saveMerchantApplicationDraft` | YES | YES | workspace setup uses existing draft contract |
| `loadMerchantWorkspace`, `openMerchantWorkspace`, `updateMerchantWorkspace` | YES | YES | workspace draft matches domain |
| `listMerchantProducts`, `createMerchantProduct`, `updateMerchantProduct`, `deleteMerchantProduct` | YES | YES | merchant product lifecycle uses real API |
| Verification ops (`createStoreVerificationRequest`, `submitVerificationPaymentReference`, `addVerificationDocument`) | YES | YES | no new contract |
| Subscription ops (`listSubscriptionPlans`, `loadSubscriptionCampaign`, `loadLocalTransferSettings`, `createSubscriptionPaymentRequest`, `uploadPaymentProof`, `submitPaymentProof`) | YES | YES | match existing contracts |
| Auth ops (`getSession`, `requestEmailOtp`, `register`, `signOut`) | YES | YES | no auth behavior changed |
| Uploads (`uploadMerchantImage`, `uploadProductImage`, `uploadStoreGalleryImage`, `uploadVerificationDocument`, `uploadPaymentProof`) | YES | YES | use existing storage service |

An automated static check extracted every `repository.<method>(` call from the rebuilt UI and compared it with the `AssalRepository` interface: **49 UI calls, 0 missing methods**.

**Result:** no UI call is wired to a fake/nonexistent repository method; no new API, no schema, no RLS, no auth path.

## 2. No data fabrication / no "دخيلة" data

- Empty states use `AssalEmpty`/`AssalMessageCard` with explicit messages sourced from real load state.
- No hard-coded product, store, review, metric, or merchant record exists in any rebuilt screen.
- Demo data is only used through `DemoRepository` when the app is explicitly in Demo mode; all screen data flows through the same repository contract.
- Merchant metrics that the backend does not supply render honest-disabled/empty state rather than invented numbers.

## 3. UI/UX standards

| Check | Result |
|---|---|
| RTL-first / Arabic-first | PASS |
| One typographic family/weight/size per level | PASS |
| Shared radius / spacing / button / input / chip style | PASS |
| Discovery-first Home | PASS |
| Taxonomy-only selectors (no comma text) | PASS |
| Governorate → District cascading selector | PASS |
| Independent Store page with filters | PASS |
| Empty = icon + title + optional description + action | PASS |
| Loading = skeleton/partial, no full-screen spinner | PASS |
| Canonical entity cards | PASS |
| Responsive phone/tablet/desktop | PASS |
| Theme switch in Settings | PASS (default beige, dark optional) |

## 4. Database / backend compliance

- No `.sql` migration, no Supabase schema change, no RLS edit, no auth provider change, no service-side endpoint change.
- Only UI/Dart tokens, Flutter widgets, TS/CSS, and documentation were modified.

## 5. Static validation performed

- `git diff --check` clean.
- Repository method usage compared against real interface.
- No legacy `AssalColors.deepBrown` / hard-coded dark literals remain in screen files.
- Admin web `tsc --noEmit` passes.
- Flutter/Dart runtime validation remains **BLOCKED** — no Flutter/Dart SDK in this environment (GAP-021).

## 6. Known risks / open items

| ID | Risk | Status |
|---|---|---|
| GAP-021 | Flutter analyze/test/build cannot run here | BLOCKED |
| — | Runtime visual QA (tap every screen) still needs a real device/Flutter environment | PENDING |
| — | Web admin ships beige default; its CSS has a `.dark` night layer for a future web toggle | NOTE |
| — | `Landing.tsx` remains the premium dark night marketing surface; can be switched to beige in a follow-up if required | NOTE |

## 7. Recommendation

Approve after:
1. Running `flutter analyze`, `flutter test`, and `flutter build apk --debug` in a Flutter-equipped environment.
2. A manual acceptance pass of the five customer tabs, merchant dashboard, product editor, verification, subscriptions, admin, and landing.
