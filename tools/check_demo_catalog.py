import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = json.loads((root / "references/data/yemeni_honey_master_database_final.json").read_text(encoding="utf-8"))
catalog = json.loads((root / "packages/demo_data/data/demo_catalog.json").read_text(encoding="utf-8"))

if catalog.get("demo_only") is not True:
    raise SystemExit("Demo catalog must be explicitly marked demo_only")
if catalog.get("source", {}).get("version") != source.get("database_info", {}).get("version"):
    raise SystemExit("Demo catalog source version drifted")
if len(catalog.get("stores", [])) != 3:
    raise SystemExit("Demo catalog must contain exactly three deterministic stores")
if len(catalog.get("products", [])) != 30:
    raise SystemExit("Demo catalog product count must remain 30")
if len(catalog.get("reviews", [])) != 3:
    raise SystemExit("Demo catalog review fixtures must remain three")

required_product_keys = {"id", "store_id", "category_id", "name_ar", "product_type", "status", "grade_levels", "badges", "tags"}
for product in catalog["products"]:
    missing = required_product_keys - product.keys()
    if missing:
        raise SystemExit(f"product missing keys: {sorted(missing)}")
    if not product["id"].startswith("demo-"):
        raise SystemExit(f"non-demo product id: {product['id']}")
    if product["status"] != "active":
        raise SystemExit(f"unexpected demo product status: {product['status']}")

text = (root / "packages/demo_data/data/demo_catalog.json").read_text(encoding="utf-8").lower()
for forbidden in ["service_role", "supabase_key", "postgresql://", "https://gvalqfgxrkibuydoiuiz"]:
    if forbidden in text:
        raise SystemExit(f"production reference leaked into demo catalog: {forbidden}")

print("PASS: demo catalog is deterministic, source-versioned, demo-only, and production-independent")
