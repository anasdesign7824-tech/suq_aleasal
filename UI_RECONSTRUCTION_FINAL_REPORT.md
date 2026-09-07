# UI Reconstruction Final Report — عسلكم

**Branch:** `arena/01a079dd-suq-aleasal`  
**Base commit:** `c3d7ad21a16680be351670272f1238acca0d3e48`  
**Date:** 2026-09-07

## 1. Outcome

The visible experience of عسلكم has been rebuilt from zero on top of the existing data, contracts, services, repositories, routes, and business rules. No backend, database, Supabase schema, RLS, auth, or API logic was changed. The old visual structure is not preserved: the customer, merchant, admin, and marketing view now use a single **premium dark honey** design language.

The new identity is a warm dark marketplace: near-black coffee canvas (`#0D0906`), warm brown surfaces (`#1A120C`, `#24180F`, `#2B1D12`), honey/amber accents (`#F5A623`), deep-brown brand moments, and cream text (`#F7EDE2`). It is RTL-first, Arabic-first, and responsive from phone to tablet to desktop.

## 2. Design system

| Layer | File | Role |
|---|---|---|
| Tokens (Flutter) | `packages/design_system/dart/lib/assal_tokens.dart` | single source of **beige + dark** palettes, radius, spacing, typography |
| Tokens (Web) | `packages/design_system/web/tokens.ts` + `tokens.css` | mirrored tokens for admin/marketing web |
| Theme builder | `apps/mobile_flutter/lib/app/assal_theme.dart` | Material 3 ThemeData builder for both modes |
| Shared widgets | `apps/mobile_flutter/lib/core/assal_widgets.dart` | brand mark, app bar, skeletons, state views, cards, chips, pills |
| App shell | `apps/mobile_flutter/lib/app/assal_app.dart` | theme scope, BottomNav / NavigationRail, RTL, startup state |
| Theme controller | `packages/design_system/dart/lib/assal_tokens.dart` | `AssalThemeMode` + `AssalThemeController` + `AssalThemeScope` |

The theme keeps **one** typographic family (`IBM Plex Sans Arabic`), one weight/size per level, one radius scale, one spacing scale, one button/input/search style, and consistent empty/loading/error states.

### Theme modes (new note)

- **Default = Beige (البيج):** near-white warm canvas `#FBF8F2`, white cards, honey amber `#D79A2B`, dark brown text `#342118`.
- **Dark night (from Settings):** premium dark honey canvas `#0D0906`, warm brown surfaces `#1A120C/#24180F/#2B1D12`, golden accent `#F5A623`, cream text `#F7EDE2`.

The preference is presentation-only (`AssalThemeController`) and lives for the app session. It does **not** touch backend, schema, RLS, auth, or business logic.

## 3. Rebuilt surfaces

### Customer Flutter app
- `customer_experience.dart` — facade that exposes the new customer feature set.
- `customer_discovery.dart` — Home (Discovery First: header → search → hero → quick discovery → categories → featured stores → most viewed → featured → newest → recommended), Categories hub, Search command + filters/sort, Stores discovery.
- `customer_catalog.dart` — canonical Product Detail (gallery, identity, metadata, store preview, request sheet, similar products, reviews/comments), Store Profile (independent page with filters), Request Sheet.
- `customer_social.dart` — canonical Review and Comments sections.
- `customer_favorites.dart` — Saved products, followed stores, favorite taxonomies.
- `customer_account.dart` — Auth (email OTP + strong password), Profile, Profile Editor, Requests, Notifications, Messages/Settings, Merchant workspace setup.

### Merchant Flutter app
- `merchant_dashboard.dart` — rebuilt workspace hub, overview, products, drafts, statistics, comments, requests, store editor.
- `merchant_product_editor.dart` — product wizard with taxonomy, regions, grades, packaging, delivery, images, re-styled to the dark system.
- `store_verification_screen.dart` — Pro verification request, payment reference, document upload, submission, re-styled to the dark system.
- `subscription_plans_screen.dart` — plans, discounts, local transfer, proof upload, re-styled to the dark system.

### Admin and marketing web
- Admin console (`apps/admin_web/client`) is fully migrated to the dark token variables and a dark override layer in `index.css`; all legacy ivory classes are remapped to dark surfaces without changing any API contract.
- `apps/admin_web/client/src/pages/Landing.tsx` was rebuilt as the premium dark honey marketing landing.
- `apps/admin_web/client/src/pages/NotFound.tsx` was rebuilt to the same dark language.

## 4. Data and backend preserves

All screens continue to use the existing `AssalRepository`, repository contracts, taxonomy, `yemen_governorates_districts.json`, catalog data, and Supabase-backed operations. The implementation does not introduce fake products, fake stores, fake reviews, fake metrics, or new backend endpoints. Missing UI data is explicitly rendered as a documented gap/empty state (see `UI_DATA_GAP_REGISTER.md` and `UI_BACKEND_GAP_REPORT.md`).

## 5. Loading / empty / error / auth gates

- Loading uses skeletons / partial sections; the previous full-screen spinner pattern is removed from the main product/merchant/account flows.
- Empty states render an icon, title, optional description, and a contextual action.
- Error states render a retryable state view; auth gates show a prompt instead of fake content.
- Forbidden/disabled states render explicit disabled/fallback UI.

## 6. Known limitations

- **GAP-021 (BLOCKED):** no Flutter/Dart SDK is installed in this environment, so `flutter analyze`, `flutter test`, and `dart format` could not be run. Static checks only were performed (`git diff --check`, token grep, import/reference scan).
- Backend and schema gaps are documented, not engineered around (see `UI_BACKEND_GAP_REPORT.md`).
- Some deep backend-driven metrics (e.g., live merchant view analytics) remain honest-disabled until the backend supplies real data.

## 7. Delivery artifacts

- `UI_RECONSTRUCTION_DISCOVERY.md`
- `UI_INFORMATION_ARCHITECTURE.md`
- `UI_DESIGN_SYSTEM_SPEC.md`
- `UI_ENTITY_PRESENTATION_SPEC.md`
- `UI_RECONSTRUCTION_TASK_LEDGER.md` (90 tasks)
- `UI_COVERAGE_MATRIX.md`
- `UI_GAP_REGISTER.md`
- `UI_DATA_GAP_REGISTER.md`
- `UI_BACKEND_GAP_REPORT.md`
- `UI_FINAL_ACCEPTANCE_MATRIX.md`
- `docs/evidence/ui-reconstruction-phase-0-2026-09-07.md`
