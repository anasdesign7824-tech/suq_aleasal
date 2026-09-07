# UI Entity Presentation Specification — عسلكم (canonical)

> Discovery/spec artifact. This is the **single source** of how each entity is presented for Customer, Merchant, and Admin. Differences are capabilities/actions/permissions/visibility, not different designs.

## 1. Rule

- One `ProductPresentation`, one `StorePresentation`, one `UserProfilePresentation`, one `RequestPresentation`, one `ReviewPresentation`, one `NotificationPresentation`, one `ConversationPresentation`.
- Variants expose more/fewer **actions**, never a different data hierarchy.
- Do not repeat the full Store inside Product; use a `StorePreview`.

## 2. ProductPresentation

Structure (top → bottom):

```text
Product gallery (1:1 primary + thumbnails/slides)
→ Identity (nameAr, category/subcategory/type)
→ Commerce (price+currency or "السعر عند الطلب", availability)
→ Quick actions (Save/Share; Like/Comment/Request placed later)
→ Trust summary (verification badge, rating, review count, badges)
→ Product information (progressive disclosure)
    → Origin (country, governorate/district/regions)
    → Quality (grade/gradeLabel, qualityLabel)
    → Taxonomy (category, subcategory, type)
    → Production (methods/status, harvest, dates, shelf life)
    → Packaging/weights/forms
    → Certifications/badges
→ StorePreview (name, logo, region, verification, follow/contact)
→ CTA (Request / Contact) — kept at bottom, not a permanent full-width bar unless screen density allows
→ Reviews
→ Comments
→ Similar products
```

| Layer | Customer | Merchant | Admin |
|---|---|---|---|
| Media | view | manage images | view/manage storage |
| Commerce | read + request | edit price/currency/availability | review values |
| Provenance | read | edit from reference selectors | approve/reject |
| Trust | badges only from data | document source | review/verify |
| Social | add review/comment, save/like | read + reply where supported | moderate/hide |
| Store | StorePreview | owned store link | full ownership context |
| Actions | request/contact | edit/delete/preview/submit | approve/reject/suspend |

## 3. StorePresentation

```text
Cover + logo/identity
→ Name + verification/status
→ Follow / Contact
→ Products (canonical grid)
→ About/description
→ Information (region, governorate/district, years, specialties)
→ Certifications
→ Location/delivery/pickup
→ Contact/order channels
→ Reviews/comments (where supported)
→ Related/similar stores
```

StoreCard: image, name, verification, location, products count, follow. No overly long description.

| Capability | Customer | Merchant | Admin |
|---|---|---|---|
| read | published stores | owned store | all stores |
| follow/contact | auth | owner/manage | not impersonate |
| edit | no | yes (permission) | moderate |
| media | public | upload public | manage public, never private without policy |
| moderate | no | no | approve/reject/suspend/reactivate |

## 4. UserProfilePresentation

User and Store are separate entities. Do not merge a customer profile into a store card.

```text
Profile identity (avatar, name, bio/presentation, location, role/store link)
→ visibility policy (email/phone only when permitted)
→ capability/actions (edit profile, my store, saved, following, requests, settings, sign-out)
→ owned stores (links/cards)
→ owned products (if public/permitted)
→ activity (data-backed only)
→ reviews
```

`UserProfile` fields include `followersCount`, `followingCount`, role. No user-following relation exists in repository today (see gaps).

## 5. RequestPresentation

Request = request/contact entity. It is **not** a full commercial order.

```text
Subject
→ Product/Store context
→ Requester (name/phone optional)
→ Quantity/handoff option/price note/delivery note
→ Status timeline (open → in_progress → answered → closed/cancelled)
→ Actions per role
```

Customer: read + view detail; Merchant: manage/answer (where contract supports); Admin: review/audit.

## 6. ReviewPresentation / CommentPresentation

Canonical: author, rating (only review), body, date, helpful count, merchant reply, moderation state. Always render loading/empty/error/forbidden correctly; never show submitted review success without a repository result.

## 7. NotificationPresentation

```text
Icon/type → title → body → time → read state → destination
```

If `payload` contains no resolvable destination, render as informational read-only notification (documented `UI_DATA_GAP`), not a fake action.

## 8. ConversationPresentation

```text
Conversation header: store/party name + ContextPreview (product/request where contract supports)
→ Messages (sender, read state, timestamp, attachments)
→ composer (send state, disabled/error)
```

Store-only context today; product/request context is a documented gap.

## 9. VerificationPresentation

State machine/status must be shown in every role:

```text
draft → payment_pending → submitted → under_review →
  approved | needs_more_info | rejected | expired | revoked
```

Merchant sees evidence + payment instructions + next step. Admin sees review tools and decision log. Customer never sees private documents.

## 10. Media contract

| Entity | Primary | Gallery | Storage |
|---|---|---|---|
| Product | 1:1 | gallery | public when published |
| Store | logo | cover + gallery | public when published |
| User | avatar | cover | public per policy |
| Banner | hero media | — | public |
| Verification/payment | — | documents/proof | private |

All entities use the same `ImageMedia` rules (loading, error, empty, ratio, semantics).

## 11. Required states for every entity

`loading, empty, success, partial, error, disabled, unauthorized, forbidden, offline`. Do not render a positive badge or action before the repository response.
