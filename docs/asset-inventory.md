# Asset and Data Inventory — Customer Web/APK

## Source assets confirmed

| Asset family | Current location | Count/shape | Intended use | Current state |
|---|---|---:|---|---|
| IBM Plex Sans Arabic | `assets/fonts/`, `apps/mobile_flutter/assets/fonts/` | 7 weights + OFL license | Shared Arabic typography on Web/APK | Present; pubspec currently declares Regular/Medium/SemiBold/Bold only |
| Internal logo | `assets/brand/logo-internal.svg`, `apps/mobile_flutter/assets/logo-internal.svg` | Horizontal SVG | Splash, app-wide brand, wide responsive header | Present; must audit load/error fallback and optimize payload |
| External app icon | `assets/brand/logo-external.svg`, `apps/mobile_flutter/assets/logo-external.svg` | Square SVG | Android/Web app icon and compact brand | Present; Android host icon still needs tracked reproducible verification |
| Identity references | `assets/identity-reference/*.jpg` | 9 reference JPGs | Visual comparison only | Present; must be used for spacing/visual audit, not architecture |
| Honey master data | `references/data/yemeni_honey_master_database_final.json` | v5.0.0, 5 categories, 4 subcategories, 30 products, 39 unique IDs | Taxonomy and seed reference | Present; rich optional fields require flexible contracts |
| Demo catalog | `apps/mobile_flutter/assets/demo_catalog.json` | App-local catalog | Offline runtime | Present but must be checked against 20+ stores/categories and linked social/request records |

## Current wiring

`apps/mobile_flutter/pubspec.yaml` declares the internal and external logos and four IBM Plex Sans Arabic weights. The remaining three weights exist in the repository but are not currently declared. This is a direct reusability opportunity, not a reason to introduce another font. SVG rendering is provided through `flutter_svg`.

## Confirmed data quality

The Honey Master analyzer reports database version `5.0.0`, five top-level categories, four subcategories, thirty products, thirty product IDs, no duplicate IDs, no missing product IDs, four grading levels, five badges/awards, and six packaging units. Optional product fields include grades, components, descriptions, forms, purpose, regions, tags, badges, and awards. Domain mapping must preserve optionality rather than inventing values.

## Gaps to close

The current app inventory has no separate product/store/gallery image corpus beyond SVG brand assets and identity references. The runtime therefore needs an explicit asset policy: use the existing project images wherever present, use the Honey Master taxonomy as structured data, and provide a truthful `AssalImageTile` fallback for records without a product image rather than silently showing a broken image or an unrelated stock photo.

The current mobile package has a small set of feature files, with most customer UI in `customer_experience.dart`. The Android host was generated during local APK troubleshooting but was not confirmed on the GitHub `main` branch after the desktop connection interruption. This remains a release-blocking repository gap until the host is committed and reproducibly rebuilt from a clean clone.

## Reuse decisions

The IBM Plex Sans Arabic family, internal/external SVG logos, Honey Master taxonomy, Demo catalog loader, typed contracts, existing color/typography tokens, and shared cards will be reused. The large monolithic customer file will not be deleted before feature-level replacement and tests exist. Admin and Landing assets are not pulled into Customer Web/APK implementation.
