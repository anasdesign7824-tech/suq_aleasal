import json
from collections import Counter
from pathlib import Path

path = Path(__file__).resolve().parents[1] / "references" / "data" / "yemeni_honey_master_database_final.json"
data = json.loads(path.read_text(encoding="utf-8"))

categories = data.get("categories", [])
records = []
category_ids = []
subcategory_ids = []
product_ids = []

for category in categories:
    category_ids.append(category.get("id"))
    for subcategory in category.get("sub_categories", []):
        subcategory_ids.append(subcategory.get("id"))
        for product in subcategory.get("products", []):
            records.append((category.get("id"), subcategory.get("id"), product))
            product_ids.append(product.get("id"))
    for product in category.get("products", []):
        records.append((category.get("id"), None, product))
        product_ids.append(product.get("id"))

all_ids = category_ids + subcategory_ids + product_ids
missing_product_ids = [p.get("name_ar") for _, _, p in records if not p.get("id")]
duplicate_ids = sorted([key for key, count in Counter(all_ids).items() if key and count > 1])
product_field_counts = Counter()
for _, _, product in records:
    product_field_counts.update(product.keys())

print("database_version=", data.get("database_info", {}).get("version"))
print("categories=", len(categories))
print("subcategories=", len(subcategory_ids))
print("products=", len(records))
print("unique_ids=", len(set(filter(None, all_ids))))
print("duplicate_ids=", duplicate_ids)
print("missing_product_ids=", missing_product_ids)
print("product_fields=")
for field, count in sorted(product_field_counts.items()):
    print(f"  {field}: {count}")
print("global_settings=")
for key, value in data.get("global_settings", {}).items():
    size = len(value) if hasattr(value, "__len__") else 1
    print(f"  {key}: {size}")

if duplicate_ids or missing_product_ids:
    raise SystemExit("Validation failed: duplicate or missing product identifiers")
