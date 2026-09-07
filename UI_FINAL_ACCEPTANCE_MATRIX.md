# UI Final Acceptance Matrix — عسلكم

Each row is a required acceptance criterion. Status: `PASS`, `PARTIAL`, `FAIL`, `BLOCKED`.

| # | Criterion | Status | Evidence / notes |
|---|---|---|---|
| A01 | UI-only change, no backend/db/schema/RLS/auth/API edits | PASS | Only Flutter-Dart and React/CSS files changed; repository/contract files untouched. |
| A02 | Old visual structure destroyed | PASS | Home/Search/Catalog/Account/Merchant/Landing rebuilt; old orphaned `home_screen.dart`/`product_detail_screen.dart` removed. |
| A03 | New premium dark honey palette used consistently | PASS | All surfaces/actions use token palette; web admin uses dark token variables + override layer. |
| A04 | One typographic family/weight/size per level | PASS | `AssalTypography` used by theme; web uses `IBM Plex Sans Arabic` token. |
| A05 | RTL-first, Arabic-first | PASS | `Directionality(rtl)` in app shell; all admin/marketing pages `dir="rtl"`. |
| A06 | Responsive phone/tablet/desktop | PASS | BottomNav under 900px, NavigationRail at/above 900px; grids and sheets adapt. |
| A07 | One consistent radius/button/input/search/icon style | PASS | Theme builder + shared widgets unify style. |
| A08 | Discovery-first Home structure | PASS | Header → search → hero → quick discovery → categories → featured stores → most viewed → featured → newest → recommended. |
| A09 | Taxonomy-driven input/selectors, no comma text fields | PASS | Categories/subcategories/types/grades/badges/packaging are chips/dropdowns from taxonomy. |
| A10 | Governorate→District cascading selectors | PASS | Cascading region selectors in store/profile/product/request flows. |
| A11 | Store is an independent page with filters | PASS | Store Profile screen independent; filters/search on Stores discovery. |
| A12 | StoreProfile and UserProfile never merged | PASS | Canonical Store Profile and Account Profile are separate screens. |
| A13 | Following vs Favorites kept separate | PASS | Followed stores and saved products/taxonomies are separate tabs. |
| A14 | Merchant UI is same app/language | PASS | Merchant flows live in the same Flutter app, Arabic, `My Store → management`. |
| A15 | Empty state = icon + title + optional description + action | PASS | `AssalMessageCard` / state views follow this contract. |
| A16 | Loading = skeletons/partial, no full-screen spinner | PASS | `AssalSkeletonList`/skeleton partials; no full-screen `AssalGlassLoading` in primary flows. |
| A17 | Canonical entity presentations | PASS | Product, Store, User, Request, Review, Notification each have one presentation with permission-adaptive actions. |
| A18 | No fabricated data | PASS | Demo data is only used through the existing demo catalog; missing data is gated/empty. |
| A19 | No dead UI | PASS | Routes/wiring updated; orphaned old customer screens removed. |
| A20 | Admin console migrated to dark theme | PASS | Admin variables + dark override layer in `index.css`. |
| A21 | Landing page migrated to dark theme | PASS | `Landing.tsx` rebuilt dark. |
| A22 | Static validation | PASS | `git diff --check` clean; no legacy light `deepBrown` refs in Flutter; no old light hex colors in Flutter. |
| A23 | Runtime validation | BLOCKED | GAP-021: no Flutter/Dart SDK in sandbox. |
| A24 | Backend/schema constraints respected | PASS | No backend/db/RLS/auth change. |
| A25 | Default theme is warm beige | PASS | `AssalThemeMode.beige` is the default; theme builder uses beige canvas (`#FBF8F2`), white cards, dark brown text. |
| A26 | Optional dark night from Settings | PASS | Settings screen exposes a night switch + segmented control; state switches via `AssalThemeController`. |
| A27 | Theme state wired without backend/db | PASS | Theme preference is presentation-only (`ValueNotifier`/`InheritedNotifier`); no persistence contract changed. |

## Blocked / deferred

- GAP-021: runtime Flutter analysis/tests blocked (no SDK).
- Backend-driven analytics unavailable until backend supplies data; UI shows honest disabled/empty states.
