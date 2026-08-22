# REQ-09 — Store rich read model evidence

**التاريخ:** 22 أغسطس 2026

## القرار

**PASS — customer store reads now project authored contact, delivery, and pickup data instead of fixed empty values.** The customer UI already renders these fields in the contact tab; the duplicate follow control was removed so follow is owned by the header action.

## Root cause

The previous `customer_stores` view returned `{}` for `social_links` and empty arrays for `delivery_options` and `pickup_locations`, regardless of what existed in the canonical tables. This was a read-model projection gap, not a missing Flutter widget.

## Changes

- `customer_stores` remains `security_invoker = true` and keeps public/authenticated read access for active stores.
- `social_links` is projected from `public.social_links` as a platform-to-URL JSON object.
- Active merchant delivery methods are projected by their canonical Arabic names.
- Active pickup locations are projected by their canonical names.
- Phone remains sourced from `stores.phone`; WhatsApp and Telegram are projected from their corresponding social-link platforms.
- The customer contact tab now keeps only `مراسلة التاجر`; follow/unfollow is not duplicated there because it is implemented in the header.

## Production probe

A merchant-owned temporary WhatsApp link, delivery option, and pickup location were inserted inside a transaction, read through `customer_stores`, and rolled back.

| Projection | Observed result | Result |
|---|---|---|
| `social_links.whatsapp` | `https://wa.me/967700000000` | PASS |
| `delivery_options` | `شركة توصيل` | PASS |
| `pickup_locations` | `نقطة استلام الاختبار` | PASS |
| `contact_whatsapp` | same URL | PASS |
| Persistence after probe | rollback | PASS |

A separate read of the current active store showed empty arrays because no contact/delivery/pickup rows are currently authored for that fixture; this is a data state, not evidence that the projection is still hardcoded.

## Tests

| Check | Result |
|---|---|
| Production rich projection rollback probe | PASS |
| `flutter analyze` | PASS — no issues found |
| Full Flutter suite | PASS — 67 tests |
| `git diff --check` | pending checkpoint |

## Scope boundary

This task does not claim a live two-device propagation test, external channel launch, or completion of the merchant-side store settings editor. It proves the read projection and the customer presentation path only.
