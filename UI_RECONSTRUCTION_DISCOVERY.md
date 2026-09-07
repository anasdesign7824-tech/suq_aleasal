# UI Reconstruction Discovery — Phase 0 only — عسلكم

> أمرتنفيذي: هذه الوثيقة هي **مرحلة الاكتشاف فقط** ولا تعدل أي كود ولا Backend ولا Database ولا Auth.
> الغرض هو تثبيت كل ما هو موجود وظيفيًا وبيانيًا، وتصنيفه، قبل بناء نظام UI جديد بالكامل.
> القاعدة الحاكمة: **Reuse data/functionality، لا نعيد استخدام التصميم القديم**.

---

## 0. مرجع التنفيذ

| Item | Value |
|---|---|
| Repository | `anasdesign7824-tech/suq_aleasal` |
| Baseline commit | `c3d7ad21a16680be351670272f1238acca0d3e48` |
| Branch | `arena/01a079dd-suq-aleasal` |
| Date | 2026-09-07 (UTC) |
| Brand displayed | **عسلكم** |
| Engineering name | `Souq Al Assal / سوق العسل` |
| App | Flutter mobile, Arabic-first RTL, Demo/Production via repository abstraction |
| Admin | React/Vite local RTL console |
| Landing | `apps/landing_web` contains only README (no executable UI) |

> This discovery reads the current UI only to learn **what functions and data exist**. It does **not** treat the current layout, cards, header, navigation, or visual ordering as a design reference.

---

## 1. ما تم فحصه

### 1.1 Flutter screens (mobile)

| File | Screens/Classes | Purpose |
|---|---|---|
| `apps/mobile_flutter/lib/app/assal_app.dart` | `AssalApp`, `AssalHomeShell` | App bootstrap, MaterialApp, RTL, theme, main shell with 5-page `IndexedStack` |
| `apps/mobile_flutter/lib/app/assal_routes.dart` | `AssalRoutes`, `AssalRouteIntent` | Canonical route registry + entity route intents |
| `apps/mobile_flutter/lib/app/assal_theme.dart` | `buildAssalTheme()` | Current theme with dark gradient AppBar / NavigationBar |
| `apps/mobile_flutter/lib/core/assal_widgets.dart` | `AssalBrandMark`, `AssalAppBar`, `AssalGlassLoading`, `AssalFutureStateView`, `AssalStateView`, `AssalMessageCard`, `SectionHeader`, `AssalImageUploadSlot`, `AssalImageTile`, `ProductCard`, `StoreCard`, `RatingStars`, `InfoChip`, `showAuthPrompt` | Shared widgets/canvas for current UI |
| `apps/mobile_flutter/lib/features/customer/customer_discovery.dart` | `HomeScreen`, `_NewsTicker`, `_PinnedHeaderDelegate`, `_Header`, `_HomeIntroTicker`, `_BannersCarousel`, `_BannerCard`, `_BannerEmptyState`, `_HeroBanner`, `_CategoryTile`, `_ProductRail`, `CategoriesScreen`, `SearchScreen`, `StoresScreen` | Home, categories, search, stores discovery |
| `apps/mobile_flutter/lib/features/customer/customer_catalog.dart` | `ProductDetailScreen`, `_MetadataCard`, `StoreProfileScreen`, `RequestSheet`, `_productTypeLabel`, `_dateLabel`, `_socialLabel` | Product detail, store profile, request/contact bottom sheet |
| `apps/mobile_flutter/lib/features/customer/customer_account.dart` | `AuthScreen`, `_PasswordStrength`, `ProfileScreen`, `ProfileEditorScreen`, `_ProfileStats`, `RequestsScreen`, `NotificationsScreen`, `ConversationScreen`, `MessagesScreen`, `SettingsScreen`, `MerchantWorkspaceSetupScreen` | Auth, profile, requests, notifications, messaging, settings, merchant setup |
| `apps/mobile_flutter/lib/features/customer/customer_favorites.dart` | `FavoritesScreen` | Favorites + followed stores + saved taxonomies |
| `apps/mobile_flutter/lib/features/customer/customer_social.dart` | `ReviewsSection`, `CommentsSection` | Product reviews/comments |
| `apps/mobile_flutter/lib/features/merchant/merchant_dashboard.dart` | `MerchantDashboard`, `MerchantStoreEditorScreen` | Merchant overview/products/drafts/stats/comments/requests; store editor |
| `apps/mobile_flutter/lib/features/merchant/merchant_product_editor.dart` | `MerchantProductEditorScreen`, `_PendingProductImage` | Product create/edit form |
| `apps/mobile_flutter/lib/features/merchant/store_verification_screen.dart` | `StoreVerificationScreen` | Pro verification request/documents/payment |
| `apps/mobile_flutter/lib/features/merchant/subscription_plans_screen.dart` | `SubscriptionPlansScreen` | Plans/campaign/local transfer/payment proof |

### 1.2 Admin screens/components

- `apps/admin_web/client/src/pages/Home.tsx` — main console, `ViewKey` = `overview, products, stores, requests, merchant-applications, store-verification, plans, banners, taxonomy, logistics, admins, audit, users, notifications, analytics`.
- `products`, `stores`, `requests`, `merchant-applications`, `plans`, `verification`, `people`, `governance`, `operations`, `creation`, `plans`, `auth gate`, `error boundary`, `theme context`, `useMobile`, `useComposition`.
- UI library large (shadcn-style components) with many visual primitives already present.
- `apps/admin_web/client/src/components/ProductCreationPanel.tsx`, `AdminStoreVerification.tsx`, `AdminMerchantApplications.tsx`, `AdminPlansPanel.tsx`, `AdminOperations.tsx`, `AdminPeople.tsx`, `AdminGovernance.tsx`.

### 1.3 Contracts and repositories

- `packages/contracts_dart/lib/assal_domain.dart` — all entity models/enums/state types.
- `packages/contracts_ts/src` — TS counterpart.
- `packages/data_dart/lib/assal_repository.dart` — repository interface / query models / auth gateway.
- `packages/data_dart/lib/demo_repository.dart` — demo implementation.
- `packages/data_dart/lib/production_repository.dart` — Supabase implementation.
- `packages/data_dart/lib/repository_factory.dart`.

### 1.4 Reference / taxonomy data

- `references/data/yemeni_honey_master_database_final.json` — read fully.
- `references/data/yemen_governorates_districts.json` — read fully.
- `apps/mobile_flutter/assets/demo_catalog.json` — demo seed data.
- `apps/mobile_flutter/assets/yemen_governorates_districts.json` — runtime locations asset.
- `packages/demo_data/data` — demo data source package.

### 1.5 Design system / assets

- `packages/design_system/dart/lib/assal_tokens.dart`
- `packages/design_system/web/tokens.ts`
- `packages/design_system/web/tokens.css`
- `docs/design-system-contract.md`, `docs/design_system.md`
- `references/brand`, `references/fonts`, `references/visual`

---

## 2. خريطة المسارات والتنقل الحالية

### Mobile top-level destinations (current shell)

| Index | Label | Screen | File |
|---|---|---|---|
| 0 | اكتشف | `HomeScreen` | `customer_discovery.dart` |
| 1 | المتاجر | `StoresScreen` | `customer_discovery.dart` |
| 2 | التصنيفات | `CategoriesScreen` | `customer_discovery.dart` |
| 3 | المراسلات | `MessagesScreen` | `customer_account.dart` |
| 4 | حسابي | `ProfileScreen` | `customer_account.dart` |

Wide view swaps `NavigationBar` with `NavigationRail` at `>=900`.

### Named routes (registry exists but mostly unused)

`AssalRoutes` defines: `home`, `discover`, `search`, `categories`, `stores`, `favorites`, `following`, `messages`, `notifications`, `profile`, `settings`, `requests`, `auth`, `merchant`, `merchantStoreWizard`, `merchantProductWizard`, `verification`, `subscriptions`, `admin`, `product(id)`, `store(id)`, `request(id)`, `conversation(id)`.

**Current usage of route names:** only `assal_routes.dart`, `assal_app.dart` (search/notifications), `customer_core.dart` (auth). Everything else still uses bare `MaterialPageRoute` without `RouteSettings`.

### Merchant flows

```text
Profile → المتابعة والحفظ (Favorites)
Profile → الإشعارات (Notifications)
Profile → الإعدادات (Settings)
Profile → طلباتي (RequestsScreen)
Profile → مساحة التاجر
  ├── MerchantDashboard (canPublish/canEdit/plan states)
  ├── MerchantStoreEditorScreen
  ├── MerchantProductEditorScreen (3 tabs)
  ├── StoreVerificationScreen (create / documents / payment / submit)
  └── SubscriptionPlansScreen (plans/campaign/transfer/proof)
```

### Admin flow (current)

```text
Admin login (session gate)
Admin Home sidebar with 15 ViewKeys
├── overview, products, stores, requests
├── merchant-applications, store-verification, plans
├── banners, taxonomy, logistics
├── admins, audit, users
├── notifications, analytics
```

---

## 3. جرد البيانات والكيانات المعتمدة

### 3.1 Core enums/status

- `AssalRole`: guest, customer, merchant, admin
- `ProductType`: honey, wax, mix, raw, gift
- `ProductStatus`: draft, pending, active, paused, rejected
- `StoreStatus`: pending, active, paused, rejected, suspended
- `StoreVerificationStatus`: notRequested, draft, paymentPending, submitted, underReview, needsMoreInfo, approved, rejected, expired, revoked
- `VerificationPaymentStatus`: notStarted, pending, paid, failed, refunded, waived
- `VerificationDocumentType`: identity, businessRegistration, taxOrLicense, originCertificate, qualityCertificate, addressProof, other
- `ReviewStatus`: pending, approved, rejected, hidden
- `RequestStatus`: open, inProgress, answered, closed, cancelled
- `HandoffOption`: pickup, delivery, office, courier, contact

### 3.2 Domain entities

| Entity | Key fields used by UI |
|---|---|
| `AssalRegion` | id, nameAr, nameEn, code, parentRegionId, isActive |
| `AssalTaxonomy` | id, code, nameAr, nameEn, description, metadata |
| `AssalBannerSummary` | id, titleAr, descriptionAr, ctaLabelAr, imageUrl, targetQuery, sortOrder, isActive |
| `AssalCategorySummary` | id, nameAr, nameEn, description, productType, productCount |
| `AssalStoreSummary` | id, merchantId, nameAr, slug, description, regionId, regionNameAr, logo/cover/avatar URLs, galleryUrls, socialLinks, deliveryOptions, pickupLocations, contactPhone/WhatsApp/Telegram, isVerified, status, ratingAverage, reviewCount, followersCount, yearsExperience, bio, specialties, certifications |
| `AssalProductSummary` | id, storeId, nameAr/nameEn, description, productType, status, taxonomyId, categoryNameAr, subcategoryNameAr, regionNameAr, gradeLevel(s), gradeLabel(s), components, isFeatured, primaryImageUrl, imageUrls, originCountry, provinceNameAr, honeyIdentity, qualityLabelAr, processingMethodAr/Status, packagingLabelAr, productionDate, packagedDate, shelfLifeLabelAr, deliveryOptions, pickupLocations, viewsCount, likesCount, price, currencyCode, ratingAverage, reviewCount, tags, badges, regions, forms, purpose, availability, weightLabel, harvestLabel, certifications |
| `AssalReviewSummary` | id, productId, storeId, authorId, rating, status, authorName, body, createdAt, updatedAt, helpfulCount, merchantReply, isLocal |
| `AssalCommentSummary` | id, targetId, authorId, authorName, body, parentId, createdAt, updatedAt, likeCount, replyCount, isLiked, isLocal |
| `AssalRequestSummary` | id, requesterId, storeId, merchantId, subject, status, productId, productName, storeName, requesterName, body, quantity, phone, preferredHandoffOption, priceNote, deliveryNote, updatedAt, createdAt |
| `AssalNotificationSummary` | id, userId, notificationType, titleAr, bodyAr, payload(map), readAt |
| `AssalUserProfile` | id, nameAr, email, avatarUrl, coverUrl, bio, phone, location, preferences, createdAt, updatedAt, followersCount, followingCount, role |
| `AssalConversationSummary` | id, storeId, storeName, lastMessage, updatedAt, participantIds, unreadCount, lastReadAt |
| `AssalMessageSummary` | id, conversationId, senderId, body, sentAt, isMine, readAt, attachments |
| `AssalMerchantWorkspaceSummary` | store, verificationStatus, publicStatus, canEdit, canPublish, planCode, planStatus, storeLimit, productLimit, designRequestsRemaining |
| `AssalMerchantApplication*` | application/draft/summary with displayName, phone, experience, location, specialties, certificateNote, storeDescription, regionId, logoUrl, coverUrl |
| `AssalProductDraft` | nameAr, nameEn, description, taxonomyId, productType, gradeLevel, metadata, imageUrls |
| `AssalStoreVerificationDraft/Summary` | storeId, status, paymentStatus, planCode, reviewNote, submittedAt, reviewedAt, expiresAt, documentCount, documentTypes |
| `AssalSubscriptionPlan`, `AssalSubscriptionCampaign`, `AssalLocalTransferSettings`, `AssalPaymentRequest` | merchant pro plans / campaign / local transfer / payment request |

### 3.3 Repository operations available to UI

- session/auth: `getSession`, `signIn`, `signInWithGoogle`, `signInWithFacebook`, `register`, `requestEmailOtp`, `verifyEmailOtp`, `requestPasswordReset`, `resendEmailConfirmation`, `verifyEmailConfirmation`, `deleteAccount`, `signOut`
- discovery: `listRegions`, `listTaxonomy`, `listCategories`, `listBanners`, `listPopularSearches`, `listStores`, `listProducts`, `getProduct`, `getStore`, `listFavoriteProducts`, `listFavoriteTaxonomies`, `listFollowedStores`
- social: `listReviews`, `listComments`, `createReview`, `createComment`, `toggleFavorite`, `toggleLike`, `trackProductView`, `toggleFollow(userId, storeId)`
- requests: `listRequests`, `listMerchantRequests`, `createRequest`
- notifications: `listNotifications`, `markNotificationRead`
- messaging: `listConversations`, `createConversation`, `listMessages`, `sendMessage`
- merchant: `loadMerchantWorkspace`, `openMerchantWorkspace`, `updateMerchantWorkspace`, `listMerchantProducts`, `createMerchantProduct`, `updateMerchantProduct`, `deleteMerchantProduct`, `submit/load/clearMerchantApplication*`
- profile: `updateUserProfile`
- media: `uploadMerchantImage`, `uploadStoreGalleryImage`, `uploadProductImage`, `uploadVerificationDocument`, `uploadPaymentProof`
- verification: `loadStoreVerification`, `createStoreVerificationRequest`, `submitStoreVerification`, `submitVerificationPaymentReference`, `addVerificationDocument`
- subscription: `listSubscriptionPlans`, `loadSubscriptionCampaign`, `loadLocalTransferSettings`, `createSubscriptionPaymentRequest`, `submitPaymentProof`, `createDesignRequest`
- state: `AssalLoadState<T>` = `AssalLoading | AssalData | AssalEmpty | AssalError`

---

## 4. جرد مرجع التصنيف `yemeni_honey_master_database_final.json` كاملًا

### 4.1 Root structure

```json
{
  "database_info": { "title", "version": "5.0.0", "description", "last_updated": "2026-08-05" },
  "global_settings": {
    "grading_system": [...],
    "badges_and_awards": [...],
    "packaging_units": [...]
  },
  "categories": [ ...5 categories... ]
}
```

### 4.2 Main categories

| ID | Arabic | English | Structure |
|---|---|---|---|
| CAT-001 | قسم العسل السائل (المصفى) | Liquid Honey Section | `sub_categories[]` (4) → `products[]` |
| CAT-002 | قسم عسل الشمع (الجبوح) | Honeycomb Section | `products[]` (5) |
| CAT-003 | قسم الخلطات العلاجية (المركبات) | Therapeutic Mixes | `products[]` (4) |
| CAT-004 | منتجات النحل الخام | Bee Raw Products | `products[]` (4) |
| CAT-005 | قسم الهدايا والباكجات | Gifts & Packaging | `products[]` (3) |

### 4.3 Subcategories (CAT-001)

| ID | Arabic |
|---|---|
| SUB-SIDR | عسل السدر والعلب |
| SUB-SUMUR | عسل السمر والطلح (أعسال الشوكيات) |
| SUB-WHITE | الأعسال البيضاء والباردة |
| SUB-SPECIAL | أعسال تخصصية ونادرة |

### 4.4 Product types represented in taxonomy

Products per category carry id/name_ar, `grades`, `regions`, `badges`, `tags`, `components`, `purpose`, `forms` as relevant. This is the authoritative source for:
- Category → Subcategory → Product Type/Item selectors
- Grade levels (`grades`: 1..4)
- Regions (`regions`)
- Badges (`badges`)
- Tags/attributes
- Forms/weights/packaging

### 4.5 Global grading system (authoritative for UI selectors)

| Level | Arabic label |
|---|---|
| 1 | ملكي فاخر (Royal) |
| 2 | درجة أولى (First Class) |
| 3 | درجة ثانية (Standard) |
| 4 | تجاري (Commercial) |

### 4.6 Badges / awards (authoritative for UI)

`GOLD-MEDAL` (فائز بالميدالية الذهبية), `LAB-TESTED` (مفحوص مخبريًا), `GUARANTEED` (بلدي مضمون — على الشرط), `SEASONAL` (إنتاج موسمي حديث), `ORGANIC` (عضوي طبيعي 100%).

### 4.7 Packaging units (authoritative for product form)

`UNIT-KG` (كيلو), `UNIT-HALF-KG` (نصف كيلو), `UNIT-QUARTER-KG` (ربع كيلو), `UNIT-GALLON` (جالون 7 كيلو), `UNIT-DABBA` (دبة 25 كيلو), `UNIT-TABLET` (قرص شمع).

### 4.8 Geographic reference (`yemen_governorates_districts.json`)

- `counts = { "governorates": 22, "districts": N }`
- `governorates[]` each with `id`, `name_ar`, `name_en`, `code`, `districts[]`.
- UI scope: Governorate → District cascading selector. No free-text location for reference fields when source exists.

---

## 5. جرد التصميم الحالي وتصنيفه

### 5.1 Existing tokens (brand identity, preserved)

| Token | Value |
|---|---|
| Primary | `#F39C12` |
| PrimaryDark | `#9C5A00` |
| HoneyLight | `#FFF0D6` |
| DeepBrown | `#4F2E1F` |
| Cream | `#F8F4EC` |
| Surface | `#FFFFFF` |
| Typography | `IBM Plex Sans Arabic` |
| Spacing | 4/8/12/16/24/32/40/48/64 |
| Radius | 8/12/18/28/pill |
| Shadows (web) | `0 8px 24px rgba(79,46,31,.08)`, `0 14px 36px rgba(79,46,31,.12)` |

These brand tokens are part of existing identity and will remain in the new design system. The **layout/component/visual language** built on top of them is not preserved.

### 5.2 Current visual problems (not fixes — facts for rebuild)

| # | Observed problem |
|---|---|
| P1 | Home is a very dense single scroll: pinned dark gradient header, ticker, carousel, categories rail, featured grid, popular/new/verified/personal rails, stores — all in one file. |
| P2 | Heavy dark gradients on AppBar, TabBar, NavigationBar create a “dark heavy” shell that fights the honey/cream identity. |
| P3 | `NavigationBar` has 5 destinations and omits Favorites, Following, Notifications, Requests as independent clear destinations; notifications is only via home header, favorites/following/requests are buried in Profile. |
| P4 | Search mixes products and stores in one unordered ListView, and the filter bottom sheet is a long vertical stream of Dropdowns/inputs without grouping/accordion. |
| P5 | `ProductCard` and `StoreCard` are the *only* canonical cards, but `FavoritesScreen` and some contexts render ad-hoc `ListTile`s instead of canonical entity renderers. |
| P6 | Product detail uses a 3-tab fixed structure inside a header + bottom CTA; social tab aggregates reviews+comments in same tab, so progressive disclosure is weak. |
| P7 | Store profile similarly uses 3 tabs and repeats data within product/store contexts; information hierarchy is flat. |
| P8 | Profile is a long `ListView` with brand mark at top, actions buried; no Activity/Products/Stores/About tabs; shows email/phone directly without a documented visibility policy. |
| P9 | Profile location is free text because `ProfileEditorScreen` uses a dialog TextField; does not use Governorate/District reference. |
| P10 | Request screen is a list of ListTiles; no Request Detail, no status timeline, no product/store context. |
| P11 | Notifications only mark read and show a snackbar; no typed destination routing. |
| P12 | Messaging list is store-name only; no unread/badge context or product/request context preview. |
| P13 | Merchant dashboard is a 6-tab `DefaultTabController` with many separate ListTile cards; store editor and product editor are form-dumps, not wizards with progress/validation states. |
| P14 | Product editor uses `TextField`/comma-string fields for taxonomy-related list fields (components, tags, badges, forms, certifications, delivery, pickup) instead of reference selectors and chips. |
| P15 | All screens use full-screen `AssalGlassLoading` in many places instead of skeletons/partial rendering. |
| P16 | Empty states use `AssalMessageCard` everywhere; many contexts show generic “لا توجد نتائج” without icon/title/description/action hierarchy. |
| P17 | Admin `Home.tsx` uses many inline styles and entity tables that are not aligned with mobile entity presentation. |
| P18 | Landing web has no executable UI. |
| P19 | No persistent user preferences contract for settings. |
| P20 | `toggleFollow` only supports store following; no user-following relation found in repository. There is no full `Order` entity; only Request/Contact. |

### 5.3 Classification of existing screens

| Screen/Component | Current classification | Phase-0 status |
|---|---|---|
| App bootstrap / shell | REBUILD | New shell + named router + guards |
| Home | REBUILD | Discovery-first, no dense duplicate rails |
| Header | REBUILD | New light header, not dark gradient stacked header |
| Navigation | REBUILD | New bottom navigation/action cluster + rail/desktop |
| Search | REBUILD | New command/mode UI with separated product/store results |
| Categories | REBUILD | New category hub reflecting 5 main categories + subcategory/product types |
| Stores discovery | REBUILD | Separate store hub with cascading geofilters + sort + verification |
| Store card | REBUILD | New canonical store presentation, not current ListTile row |
| Store profile | REBUILD | New store entity page with identity/products/info/location/contact/social/related |
| Product card | REBUILD | New canonical product presentation with variants |
| Product detail | REBUILD | New progressive product page: gallery/identity/commerce/origin/quality/taxonomy/store/request/reviews/similar |
| Favorites | REBUILD | Separate “المحفوظات” save hub; not following |
| Following | REBUILD / partially blocked | Separate following hub (store only today; user following is a gap) |
| Profile | REBUILD | New profile entity page with public identity, capability cards, tabs |
| Profile editor | REBUILD | New form sections + canonical location selector (where supported) |
| Requests | REBUILD + GAP | List + detail + timeline; no full Order |
| Notifications | REBUILD + GAP | Actionable list + typed destination adapter (backend gap for payload) |
| Messages | REBUILD + GAP | Conversation list + context preview + composer |
| Reviews / comments | REBUILD | Canonical review/comment presentation |
| Settings | REFACTOR | Group settings; persistence gap documented |
| Auth | REFACTOR | Keep auth logic, rebuild visual flow/states |
| Merchant entry | REBUILD | Capability-aware merchant hub |
| Merchant dashboard | REBUILD | Same design language as customer entity pages |
| Store wizard | REBUILD | Multi-step wizard with progress/draft/resume |
| Product wizard | REBUILD | Multi-step reference-driven wizard |
| Verification | REBUILD | Evidence/payment/review lifecycle UI |
| Subscription/plans | REBUILD | Plan cards + payment proof flow |
| Admin shell/panels | REBUILD | Canonical entity presentations + capability actions |
| Admin product/store/etc | REBUILD | Align with canonical entity contracts |
| Landing | REFACTOR / build later | Exists only as README; generic marketing IA |
| Shared state widgets | REBUILD | New state renderer for all states |
| Image system | REBUILD | New media presentation/upload contract |
| Accessibility/responsive/RTL | REBUILD | Added as gates on every component |

---

## 6. New Design Direction (kept out of the old visual structure)

The new product UI will **not** continue the dark-gradient shell, dense horizontal rails, fixed 3-tab entity pages, or the current bottom navigation ordering.

### 6.1 Principles

- **Premium calm honey marketplace**: cream canvas, soft white surfaces, very light borders, one strong brand accent, no heavy dark chrome.
- **Discovery-first**: Home = brand identity + global search + one hero + category chips + one data-driven product storefront; no full-screen loaded waits.
- **Progressive disclosure**: entity pages use a master-detail rhythm. Product page = hero gallery → identity → quick actions → summary → collapsible metadata → store preview → request/contact → social → similar.
- **Canonical entity renderers**: one ProductPresentation, StorePresentation, UserProfilePresentation, RequestPresentation, ReviewPresentation, NotificationPresentation. Roles add capabilities but do not redesign the entity.
- **Reference-driven forms**: taxonomy, grades, badges, packaging units, governorate/district, types are selectors/chips from real data, never free-text comma fields.
- **RTL-first**: directional icons, chevrons, padding, sheets, dialogs; do not mirror logos/images.
- **Responsive**: phone (<=599), tablet (600-899), desktop (>=900). Not a stretched phone layout.

### 6.2 New surface layout (proposed, to be designed in TASKs)

```text
AppShell
├── Safe brand header (light, compact, not full-height gradient)
│   ├── brand mark
│   ├── search access (icon + open command bar)
│   ├── notifications (badge)
│   └── account menu (profile / merchant / settings)
├── Content
│   ├── Mobile bottom navigation (5 stable groups + contextual deep actions)
│   ├── Desktop/tablet sidebar/rail
├── Global sheets
│   ├── Search command
│   └── Filter drawer
```

### 6.3 Visual tokens to extend

| Token | Property |
|---|---|
| `--assal-surface-elevated` | soft white raised card, no heavy gradient |
| `--assal-shadow-soft/raised` | existing low warm shadows |
| `--assal-accent` | honey/amber only for highlight, not dark brown background |
| Typography scale | Display/Heading/Title/Body/Caption/Label/Button/Metadata |

No random colors, no system font, no unconsistent icon set, no random radius. All components use the design-system component registry.

---

## 7. الفجوات المكتشفة (Phase-0 summary)

Detailed in `UI_GAP_REGISTER.md`, `UI_DATA_GAP_REGISTER.md`, `UI_BACKEND_GAP_REPORT.md`.

Key headlines:

| Gap | What UI needs | Exists? | Backend change? | Status |
|---|---|---|---|---|
| Following people | Follow User relation | No | Yes | `UI_DATA_GAP` |
| Full Order flow | Order entity/status/payment chain | No | Yes | `BACKEND_GAP` |
| Notification destination | typed target route/entity | No | Probably yes | `UI_DATA_GAP` |
| Request detail | timeline + context in existing request fields | Field exists, no mutation | No UI can build from contract | `OPEN` (UI-only) |
| Profile visibility | policy for email/phone | No contract | No | `UI_GAP` |
| User preferences | persistent settings | No repo op | Yes | `BACKEND_GAP` |
| Analytics | richer metrics | partial | Yes | `UI_GAP` |
| Flutter toolchain | can't run flutter analyze/test locally | No SDK | N/A | `BLOCKED` |

---

## 8. تعريفات الإغلاق (Phase gates)

Before closing the phase, every row in `UI_COVERAGE_MATRIX.md` must have a clear status. Every task in `UI_REBUILD_TASK_LEDGER.md` must be atomic, have dependency, data, states, RTL, responsive, accessibility, regression, and evidence fields.

No implementation task is allowed to start until this discovery and the task ledger are accepted. Then, strictly **one task at a time**: implement → verify → visual test → regression → close → evidence → next task.

---

## 9. مراجع الأدلة

| Evidence | Source |
|---|---|
| Mobile screens/classes | `apps/mobile_flutter/lib/**` |
| Shared components | `apps/mobile_flutter/lib/core/assal_widgets.dart` |
| Domain contracts | `packages/contracts_dart/lib/assal_domain.dart` |
| Repository contract | `packages/data_dart/lib/assal_repository.dart` |
| Taxonomy reference | `references/data/yemeni_honey_master_database_final.json` |
| Locations reference | `references/data/yemen_governorates_districts.json` |
| Demo data | `apps/mobile_flutter/assets/demo_catalog.json` |
| Admin UI | `apps/admin_web/client/src/**` |
| Design tokens | `packages/design_system/**`, `docs/design-system-contract.md` |
