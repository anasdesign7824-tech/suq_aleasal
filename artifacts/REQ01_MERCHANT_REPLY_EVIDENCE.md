# REQ-01 — Merchant request reply evidence

**التاريخ:** 22 أغسطس 2026

## القرار

**PASS — database contract and repository/UI wiring compile and test.** The live rollback probe passed all checks for the database contract. A two-device authenticated end-to-end event-delivery test is still a separate SYNC-01 task and is not claimed here.

## Production migration

- Migration name: `merchant_request_reply`
- Production version: `20260822024942`
- Added: `request_messages.response_code` with allowed values `available`, `unavailable`, `contact_required`.
- Added: `public.merchant_reply_to_request(uuid,text,text,text)`.
- Execution grants: `authenticated`; revoked from `public` and `anon`.
- The function derives merchant identity from `auth.uid()`, locks the request, validates store ownership and reply state, inserts the request message, updates request status to `answered`, inserts a minimal `request_answered` notification for the requester, and records a deterministic mutation result in `private.client_mutations`.

## Controlled rollback probe

Input: `req01_probe_input.json` in the sandbox. The probe created a temporary request with the real production fixture, called the RPC twice with the same idempotency key, read the notification under the requester identity, then rolled everything back.

| Assertion | Result |
|---|---|
| Request creation starts as `open` | PASS |
| Merchant reply returns `answered` | PASS |
| Response code is `available` | PASS |
| Same retry returns the same message ID / one message row | PASS |
| Same retry creates one notification only | PASS |
| Customer reads `answered` status and one merchant message | PASS |
| Notification payload is minimal and excludes body/phone | PASS |
| Non-owner merchant/customer attempt is rejected with `42501 request_not_owned` | PASS |
| Anonymous execution is rejected with `42501` | PASS |
| Post-probe persistence | ROLLBACK; no probe rows retained |

The first probe version counted notifications while impersonating the merchant and returned zero because `notifications_self_read` correctly hides the customer’s notification from the merchant. The probe was corrected to read it as the requester; the corrected result is the authoritative result above.

## Flutter gate after contract wiring

- `flutter analyze`: PASS — no issues found.
- Dedicated `customer_request_detail_widget_test.dart`: PASS — 2 tests.
- Full Flutter suite: PASS — 64 tests.
- The shared screen opens from merchant and customer request lists. The merchant receives response choices and a reply field; the customer sees request details and the request message thread.

## Scope boundary

This evidence does not claim that the final UI is complete, that Realtime delivered an event between two physical devices, or that the Pro/verification surfaces have been removed. Those remain separate tasks.
