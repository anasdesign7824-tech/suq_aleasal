# REQ-07 — Temporary Pro/verification UI deferral evidence

**التاريخ:** 22 أغسطس 2026

## القرار

**PASS — Pro/verification is hidden by default from the shared customer-facing store header and customer product list, while backend records and future plan screens remain intact.** This is a reversible UI scope decision, not deletion or revocation of verification data.

## Changes

- `AssalStoreHeaderCard` now accepts `showVerificationBadge` and defaults it to `false`.
- When disabled, a verified store receives the ordinary status label such as `متجر مفعّل` rather than `موثق Pro`.
- The customer store page no longer passes `showVerifiedBadge: true` to product cards.
- Follow/unfollow and ordinary store status remain visible and functional.

## Tests

| Check | Result |
|---|---|
| Header widget test with `isVerified: true` | PASS; `موثق Pro` absent, `متجر مفعّل` present |
| Full Flutter suite | PASS — 66 tests |
| `flutter analyze` | PASS — no issues found |
| Data deletion | None; no migration or destructive operation |

## Scope boundary

The Pro/subscription/verification backend and merchant administration flows were not removed. They remain deferred and can be re-enabled explicitly by passing `showVerificationBadge: true` or by a later product decision. This task does not claim payment or plan activation behavior.
