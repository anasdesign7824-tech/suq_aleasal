# Taxonomy and Yemen Location Reference Evidence

## Scope and provenance

The application now carries a pinned, reviewable reference for Yemeni governorates and districts. The source is the public [YemenOpenSource/Yemen-info repository][1], file `yemen-info.json`, pinned at commit `f0bd5b523d91861088ddc9c494c11eba1a60336f`. The source snapshot SHA-256 is `49e265bc94726e83d6a67107f8195276616aa81b5fa1af028c25dbf2296c5a12`. The extraction intentionally retains only governorates and districts; uzaal and village data are not part of the selector contract.

The upstream README explains that the dataset was researched in February 2024 and does not guarantee permanent accuracy. This caveat is preserved in `references/data/yemen_governorates_districts.json`, so future location changes must update the pinned source and rerun the integrity checks rather than silently editing names in the UI.

## Reference outputs

| Artifact | Purpose | Status |
|---|---|---|
| `references/data/yemen_governorates_districts.json` | Auditable source-derived reference and provenance | Committed |
| `apps/mobile_flutter/assets/yemen_governorates_districts.json` | Flutter Web/APK asset used by Demo and local selector flows | Committed |
| `apps/mobile_flutter/lib/core/yemen_location_reference.dart` | Typed parser and cascading governorate→district API | Committed |
| `database/migrations/0003_taxonomy_regions_reference.sql` | Idempotent Production seed and schema extension | Committed and applied |
| `apps/mobile_flutter/test/yemen_location_reference_test.dart` | Parser, cascade, schema, and duplicate-safety tests | Committed |

The generated reference contains **22 governorates and 335 districts**. Region codes are stable (`YE-GOV-###` and `YE-DST-###-###`), and the Production `regions` table now carries `region_level`, Arabic/English normalized names, and indexes supporting active parent-child reads. The adapter exposes `districtsFor(governorateCode)` and rejects incompatible schema versions, invalid source hashes, duplicate codes, and declared/actual count mismatches.

## Production migration and integrity result

Migration `0003_taxonomy_regions_reference` was applied successfully to project `gvalqfgxrkibuydoiuiz`. It is idempotent and does not delete unrelated rows. The migration seeds the five canonical category roots and their child categories, then flattens the official honey reference into `public.honey_taxonomy` with metadata preserving source IDs, parent/root codes, grades, badges, tags, forms, components, and purposes.

The post-migration query returned the following result:

| Check | Result |
|---|---:|
| Active governorates | 22 |
| Active districts | 335 |
| Orphan districts | 0 |
| Duplicate region-code groups | 0 |
| Active category rows | 9 |
| Active taxonomy rows | 39 |
| Orphan categories | 0 |

Sample rows verified in Production include `YE-GOV-001` (أمانة العاصمة), `YE-DST-001-001` (صنعاء القديمة), `CAT-001` (قسم العسل السائل), `SUB-SIDR` (عسل السدر والعلب), `PROD-SIDR-DOANI` (سدر دوعني), and `GIFT-POTTERY` (عسل في جرار فخارية).

## Flutter verification

The Windows project was tested from the mapped `X:` drive to avoid the known Unicode working-directory issue. After syncing the committed files, `flutter test` returned **All tests passed** and `flutter analyze --no-pub` returned **No issues found**. This verifies that the location adapter and asset do not break the existing Demo/Auth contract. The production UI still needs the Merchant Wizard work in Phase 8 to consume this adapter as visible cascading fields; the adapter is intentionally completed first so the Wizard cannot introduce arbitrary text-field locations.

## References

[1]: https://github.com/YemenOpenSource/Yemen-info/tree/f0bd5b523d91861088ddc9c494c11eba1a60336f "YemenOpenSource/Yemen-info pinned source commit"
[2]: https://github.com/YemenOpenSource/Yemen-info/blob/f0bd5b523d91861088ddc9c494c11eba1a60336f/README.md "Yemen-info methodology and data caveats"
