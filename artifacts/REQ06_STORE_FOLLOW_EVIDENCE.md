# REQ-06 — Store follow action evidence

**التاريخ:** 22 أغسطس 2026

## القرار

**PASS — the customer store header now exposes a real follow/unfollow action and the store product grid matches the square product-card sizing.** The Pro/verification badge remains a separate deferred scope and is not claimed as redesigned here.

## Changes

- `StoreProfileScreen` loads the current user's followed stores through `listFollowedStores` and derives the state for the current store.
- The header accepts `isFollowing`, `followBusy`, and `onFollow` and renders an actionable add/remove control over the cover area.
- The action is guarded against duplicate taps, requires a user session, calls `repository.toggleFollow`, and updates the icon state only after the repository result succeeds.
- The store product grid now uses `mainAxisExtent: 400`, matching the shared square `ProductCard` introduced in REQ-05.
- No Pro or verification records were deleted. That feature remains intentionally deferred, as requested.

## Tests

| Check | Result |
|---|---|
| Dedicated `store_header_widget_test.dart` | PASS |
| Full Flutter suite | PASS — 66 tests |
| `flutter analyze` | PASS — no issues found |
| `git diff --check` | pending checkpoint |

## Scope boundary

This task proves the widget action and the page-level repository wiring. It does not claim a live two-device follow propagation test; that requires two authenticated clients and remains part of the synchronization acceptance protocol.
