import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
dart = (root / "packages/contracts_dart/lib/assal_domain.dart").read_text(encoding="utf-8")
ts = (root / "packages/contracts_ts/src/domain.ts").read_text(encoding="utf-8")

pairs = {
    "AssalRole": ("AssalRole", "AssalRole"),
    "ProductType": ("ProductType", "ProductType"),
    "ProductStatus": ("ProductStatus", "ProductStatus"),
    "StoreStatus": ("StoreStatus", "StoreStatus"),
    "VerificationStatus": ("VerificationStatus", "VerificationStatus"),
    "ReviewStatus": ("ReviewStatus", "ReviewStatus"),
}

for label, (dart_name, ts_name) in pairs.items():
    dart_match = re.search(rf"enum {dart_name} \{{([^}}]+)\}}", dart, re.S)
    ts_match = re.search(rf"export type {ts_name} = ([^;]+);", ts)
    if not dart_match or not ts_match:
        raise SystemExit(f"missing enum/type: {label}")
    dart_values = {part.strip() for part in dart_match.group(1).split(',') if part.strip()}
    ts_values = {part.strip().strip('"') for part in ts_match.group(1).split('|')}
    if dart_values != ts_values:
        raise SystemExit(f"parity mismatch {label}: Dart={sorted(dart_values)} TypeScript={sorted(ts_values)}")

for class_name in [
    "AssalRegion", "AssalTaxonomy", "AssalStoreSummary", "AssalProductSummary",
    "AssalReviewSummary", "AssalRequestSummary", "AssalNotificationSummary",
]:
    if f"class {class_name}" not in dart:
        raise SystemExit(f"missing Dart model {class_name}")
    if f"interface {class_name}" not in ts:
        raise SystemExit(f"missing TypeScript model {class_name}")

if "in_progress" not in ts:
    raise SystemExit("request status wire value missing from TypeScript contract")

print("PASS: core enum values and semantic model anchors match across Dart and TypeScript")
