# UI Design System Specification — عسلكم (new, from scratch)

> Discovery/spec artifact. The visual component system described here replaces the old UI shell, header, navigation, cards, and entity presentation. It does **not** change the brand mark, brand palette, font family, or backend/data contracts.

## 1. Visual identity

- **Name:** عسلكم.
- **Positioning:** Premium Arabic honey social-marketplace. Calm, warm, clear, trustworthy.
- **Feel:** Warm cream canvas, white elevated surfaces, very light warm borders, one primary amber accent as highlight (not full background), dark brown used for text/primary brand moments only.
- **Avoid:** heavy dark gradients as default chrome, dense multi-rail home, `ListTile`-only entity cards, unorganized filter sheet, full-screen spinners, random card radius/colors.

## 2. Design tokens

Use the existing brand tokens as the base (not changed): `IBM Plex Sans Arabic`, honey/amber palette, `#F8F4EC` cream, `#FFFFFF` surface, `#342118` text primary, `#6F5B4C` text secondary, `#E8DCCB` border, `#4F7A45` success, `#B86B1E` warning, `#A64232` error.

Extend with semantic tokens (new):

| Token | Intent |
|---|---|
| `--assal-surface-inverse` | small dark surfaces only for selected actions/badges |
| `--assal-surface-elevated` | white raised card with very soft warm shadow |
| `--assal-divider` | very light `#E8DCCB` divider |
| `--assal-action-primary` | filled dark-brown/amber button only for single primary action |
| `--assal-action-secondary` | outlined / tonal secondary action |
| `--assal-focus-ring` | amber focus ring, always visible on focus |
| `--assal-feedback-success/error/warning/info` | state colors |
| `--assal-metadata` | caption or tiny text color for metadata |

Spacing scale: 4, 8, 12, 16, 24, 32, 40, 48, 64.
Radius scale: 8 (control), 12 (card), 18 (large container), 28 (hero media), pill (chips/badges).
Shadow scale: soft (page-level), raised (interactive sheet/dialog), none for flat cards.

## 3. Typography scale (canonical)

| Role | Size | Line-height | Weight | Use |
|---|---|---|---|---|
| Display | 36 | 48 | 700 | Brand moments only |
| H1 | 30 | 40 | 700 | Page identity |
| H2 | 24 | 34 | 600 | Section title |
| H3 / Title | 20 | 30 | 600 | Card title / open section |
| Title | 18 | 28 | 600 | Entity name |
| Subtitle | 16 | 26 | 500 | Supporting lead |
| BodyLarge | 16 | 28 | 400 | Paragraph |
| Body | 14 | 24 | 400 | Standard content |
| BodySmall | 12 | 20 | 400 | Secondary line |
| Caption | 11 | 18 | 500 | Metadata |
| Label | 12 | 18 | 500 | Input label |
| Button | 14 | 22 | 600 | Button |
| Navigation | 13 | 20 | 600 | Bottom nav / rail |
| Metadata | 10–11 | 16–18 | 400–500 | Timestamp, counts |

No screen may introduce a different text scale.

## 4. Core component system (new)

| Component | Contract |
|---|---|
| `AssalShell` | outer app shell, header + content + nav, light surface |
| `AssalHeader` | brand mark + context title + search access + notifications + account |
| `BottomNavigation` / `Rail` | 5 stable destinations; contextual deep actions in header/profile/cards |
| `SearchCommand` | global search overlay with recents/popular + product/store mode |
| `CanonicalProductCard` | image 1:1, name, price+currency, category/type, store, verification, rating, availability, one action; variants: grid, rail, compact, merchant/edit, admin/review |
| `CanonicalStoreCard` | logo/cover, name, verification, location, product count, follow; no overstuffed fields |
| `CanonicalUserCard` | avatar, name, bio, role/store link, follow/contact when supported |
| `CanonicalRequestCard` | subject, product/store context, status, handoff, time |
| `CanonicalReviewCard` | author, rating, body, merchant reply, helpful count |
| `CanonicalNotificationItem` | icon, title, body, time, read state, destination |
| `EntityStateView` | loading/empty/success/partial/error/disabled/unauthorized/forbidden/offline |
| `HoneySectionHeader` | title + optional action |
| `HoneyCard` | white surface, border + soft shadow, spacing 16 |
| `HoneyInput` | labeled field, help/error, focus ring |
| `CascadingLocationSelector` | Governorate → District from reference |
| `ReferenceSelect` / `ChipSelect` | selectors from taxonomy/grade/badges/packaging/type |
| `FilterDrawer` | grouped filter sheet / accordion |
| `ImageMedia` | ratio-aware, loading+failed+empty+private handling |
| `ProgressiveDisclosure` | collapsible metadata sections |
| `ConfirmationDialog` / `SnackFeedback` | consistent confirmation and feedback |

## 5. Action hierarchy

- **One primary action** per entity card/page (where required): for customer product = request/contact; for merchant product = edit/preview/submit; for admin = review/moderate.
- Secondary actions (save/follow/like/share/comment) are grouped contextually, never in a single crowded icon bar.
- Sensitive actions require a confirmation dialog and a success/failure state from the actual repository result.

## 6. States

**Always render**, in order:

| State | Render |
|---|---|
| Loading | `EntityStateView.loading` — skeleton/partial, never full-screen spinner for a single section |
| Empty | icon + short title + optional description + action (no huge empty card) |
| Success | entity content |
| Partial | content + small notice about what failed |
| Error | message + retry, context preserved |
| Disabled | reason + disabled control |
| Unauthorized | guest CTA to sign in |
| Forbidden | reason without leaking security details |
| Offline | recovery action |

## 7. Images

- Product primary: **1:1**.
- Store: logo/identity + cover + gallery when present.
- Profile: avatar, cover.
- Banner/hero: aspect based on slot.
- Never distort/stretch/crop badly. Always provide fallback and semantics.

## 8. RTL, accessibility, responsive

- Arabic + RTL default. Use directional padding/margins/arrows.
- Minimum touch target 44×44. All icons/tooltips have Arabic labels. Images have semantics or exclude if decorative. Text scaling must not overflow.
- Mobile `<=599`, tablet `600–899`, desktop `>=900`. No stretched mobile layout; responsive-column/rule is used.

## 9. Taxonomy-driven forms

- Categories/Subcategories/Product Types/Grades/Badges/Packaging/Governorate/District/Origin/Quality come from real data sources (JSON/repository).
- Never use comma-separated `TextField` for reference-list metadata. Use chips / multi-select / cascading selectors.

## 10. Adoption rule

Any new visual element must be tokenized, use the canonical component registry, support all required states, pass RTL/responsive/accessibility checks, and have a data/contract source. Deviations are logged in `UI_GAP_REGISTER.md` before implementation.
