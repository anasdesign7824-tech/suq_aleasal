# REQ-08 — Product editor reference dropdowns evidence

**التاريخ:** 22 أغسطس 2026

## القرار

**PASS — high-value product reference fields now use canonical dropdown choices and the local source field is read-only.** Free-text fields that legitimately require custom content, such as description, tags, components, delivery notes, and pickup notes, were intentionally left editable.

## Changes

- Added a shared `_choiceField` helper that preserves an existing legacy value as a selectable first option instead of silently discarding it.
- Converted country of origin, weight/size, honey identity, quality grade, harvest season, processing method, processing status, and packaging type to dropdown-backed fields.
- Kept governorate/district selections sourced from `listRegions`.
- Replaced the misleading free-text `وصف المصدر المحلي (اختياري)` control with a read-only `المصدر المحلي` field populated from the selected region.
- Enabled `isExpanded` on dropdown controls to prevent Arabic labels from overflowing narrow rows.
- The option labels are based on the existing catalog vocabulary and grading/packaging settings; no production records were rewritten.

## Regression and fix

The first widget test exposed an actual narrow-layout overflow in the currency dropdown. `isExpanded: true` was added to the shared dropdown helper and the currency field. The test also initially selected the horizontal TabBar scrollable; the test was corrected to target the vertical editor scrollable. No production failure was hidden or ignored.

## Tests

| Check | Result |
|---|---|
| Dedicated `merchant_product_editor_dropdown_test.dart` | PASS |
| Full Flutter suite | PASS — 67 tests |
| `flutter analyze` | PASS — no issues found |
| Production data migration | None; editor-only change |

## Scope boundary

This task does not claim that every free-form business description should be forced into a fixed list. It also does not claim store-level delivery configuration, image upload redesign, or live merchant/customer synchronization; those remain separate tasks.
