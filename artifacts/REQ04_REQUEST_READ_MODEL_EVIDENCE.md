# REQ-04 — Unified request read model evidence

**التاريخ:** 22 أغسطس 2026

## القرار

**PASS — request listing now uses one protected read model for customer and merchant surfaces.** The change is intentionally separate from the live two-device synchronization proof.

## Production migration

- Migration: `customer_requests_read_model`
- Source: `database/migrations/0063_customer_requests_read_model.sql`
- View: `public.customer_requests`
- Protection: `security_invoker = true`; direct grants are limited to `authenticated`.
- The view projects request ID, requester/store/merchant IDs, subject, status, product ID/name, store name, requester display name, body, quantity, handoff option, notes, and timestamps.
- The product projection uses a lateral query limited to one product row per request, matching the current request composer contract and avoiding duplicate request cards.

## Read probe

A temporary request was created through the existing atomic request RPC inside a transaction, then read from `customer_requests` while impersonating the requester. The transaction was rolled back.

| Field | Observed value | Result |
|---|---|---|
| `product_name` | `عسل بلدي` | PASS |
| `store_name` | `عسل` | PASS |
| `requester_name` | `مستخدم عسلكم` | PASS |
| `quantity` | `2` | PASS |
| `status` | `open` | PASS |
| Persistence after probe | rollback | PASS |

## Flutter integration

- `ProductionRepository.listRequests` now reads `customer_requests` by `requester_id`.
- `ProductionRepository.listMerchantRequests` now reads `customer_requests` by `merchant_id` in one call instead of selecting stores and then looping over raw requests.
- `flutter analyze`: PASS — no issues found.
- Full Flutter suite: PASS — 64 tests.

## Scope boundary

This task does not yet implement the product/store visual redesign, dropdown catalogs, follower button, or two-device Realtime proof. Those remain separate tasks and are not claimed here.
