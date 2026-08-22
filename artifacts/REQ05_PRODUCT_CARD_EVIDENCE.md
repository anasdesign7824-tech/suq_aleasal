# REQ-05 — Product card visual evidence

**التاريخ:** 22 أغسطس 2026

## القرار

**PASS — product image frame is square and the existing product core fields remain visible.** The change was kept at the shared widget and the two customer grids were given enough vertical extent to avoid clipping.

## Changes

- `ProductCard` now wraps the image area in `AspectRatio(aspectRatio: 1)`.
- `AssalImageTile` supports a bounded `expand` mode used only by the square card frame; existing fixed-height usages remain unchanged.
- Featured and search product grids use `mainAxisExtent: 400` so the square image plus Arabic title, category, price, rating, availability, and grade do not overflow on narrow cards.
- No product image was replaced with a fake URL. Missing/invalid images continue to use the existing honey-category fallback icon.

## Tests

| Check | Result |
|---|---|
| Dedicated `product_card_widget_test.dart` | PASS |
| Regression `search_filter_widget_test.dart` after the first full-gate overflow | PASS |
| Full Flutter suite | PASS — 65 tests |
| `flutter analyze` | PASS — no issues found |
| `git diff --check` | PASS before checkpoint |

## Regression found and fixed

The first full suite after changing the image to 1:1 exposed a real `RenderFlex overflowed by 27 pixels` in the search filter scenario. The cause was the old fixed grid height being insufficient for the now-square image. The grid extent was raised to 400; the failing test and then the full suite passed.

## Scope boundary

This task does not claim the full store redesign, dropdown catalogs, follower overlay, or Pro/verification removal. Those remain separate tasks.
