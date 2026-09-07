# UI Information Architecture — عسلكم (new IA)

> Discovery-only artifact. Approved IA for the new visual layer. Does not modify backend contracts.

## 1. Principle

The new UI is organized around **entities + capabilities + states**, not around old screens or old visual order. The same Product / Store / User / Request / Review / Notification presentation is reused across Customer, Merchant, and Admin; roles add capabilities, not new designs.

## 2. Top-level IA

```text
عسلكم
├── Customer (guest / signed-in)
│   ├── Discover (Home)
│   │   ├── Header + global Search
│   │   ├── Hero / campaign
│   │   └── Discovery sections (canonical, only non-empty)
│   ├── Categories (Main → Subcategory → Product type → products)
│   ├── Stores (hub: search/filter/browse/open)
│   ├── Product detail
│   ├── Store detail
│   ├── Search command
│   ├── Saved (Favorites: Products + Stores + Taxonomies)
│   ├── Following (separate from Saved; store following today)
│   ├── Messages (conversations → detail)
│   ├── Notifications
│   ├── Requests (list + detail/timeline)
│   ├── Profile (public identity + capability actions)
│   └── Settings
├── Merchant (same user, same design language)
│   ├── Merchant hub (My Store card + capabilities)
│   ├── Store management
│   ├── Product management / Product wizard
│   ├── Requests / Messages
│   ├── Verification
│   ├── Plans / subscriptions / payments
│   └── Analytics
├── Admin
│   ├── Overview / Analytics
│   ├── Catalog / Products / Taxonomy / Banners
│   ├── Stores / Logistics
│   ├── Merchant applications / Verification / Plans
│   ├── Requests / Messages / Notifications
│   ├── Users / Admins / Audit
└── Public Landing (marketing, data-free for operational UI)
```

## 3. Customer navigation (new)

| Destination | Entry | Guard | Notes |
|---|---|---|---|
| Discover | Default | guest OK | Hide empty sections |
| Categories | Nav or Home chip | guest OK | Full taxonomy hierarchy |
| Stores | Nav or Home link | guest OK | Store hub via repository |
| Search | Header icon | guest OK | Command bar, product/store modes |
| Notifications | Header badge + profile | auth | typed destination when available |
| Saved (Favorites) | Nav/profile | auth | Products, stores, taxonomies |
| Following | Nav/profile | auth | Store following; user-following documented gap |
| Messages | Nav/profile | auth | Conversation list + context preview |
| Requests | Profile | auth | List + detail/timeline |
| Profile | Nav/profile | guest + auth | Public identity; separate from Store |
| Settings | Profile | guest + auth | Local session unless persistent contract |

Mobile bottom navigation (new):
- Anchor 5 stable destinations: **Discover, Categories, Stores, Saved/Following combined via one "My saved hub" or separate Saved**, **Profile/Menu**.
- Messages / Notifications / Requests / Merchant are **contextual destinations**, reachable from header/profile / capability cards, to avoid an overcrowded 8-item bar.

## 4. Merchant navigation

```text
Profile → My Store / Merchant hub
├── Store overview (canPublish/canEdit states)
├── Store details (canonical Store entity + manage actions)
├── Products
│   ├── Published
│   ├── Drafts / review
│   └── Product Wizard (+ edit)
├── Requests
├── Messages
├── Verification (evidence timeline)
├── Subscriptions / Payment proofs
└── Analytics (data-backed metrics only)
```

## 5. Admin navigation

Keep same capability domains but present them through canonical entity renderers and typed admin API adapters.

## 6. Entity routing rules

- Every deep link carries `route + entityId + context` (already defined by `AssalRouteIntent`).
- Notification without a resolvable destination is rendered as a read-only informational notification, never a fake actionable one.
- Requests/order: today this is Request/Contact, not a full commercial Order. UI should not present a full checkout unless a backend Order contract is approved.

## 7. Responsive rules

- `<=599`: single column, bottom navigation, drawer/sheet filters.
- `600–899`: two/three column, rail or top bar, constrained reading width.
- `>=900`: sidebar/rail, canonical entity pages within a max reading column; admin table data converts to cards/expandable rows where needed.

## 8. RTL

Arabic first. All chevrons, back buttons, horizontal scrolls, text alignment, forms, sheets, dialogs, and tables use directional semantics. Brand logos/images are never mirrored.

## 9. Gap boundaries

User-following, full order, notification destination, profile visibility policy, and persistent settings are documented as gaps; the new IA uses `UI_DATA_GAP` / `BACKEND_GAP_REPORT` rather than inventing unsupported flows.
