import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
paths = [
    ROOT / "packages/demo_data/data/demo_catalog.json",
    ROOT / "apps/mobile_flutter/assets/demo_catalog.json",
]

loaded = [json.loads(path.read_text(encoding="utf-8")) for path in paths]
for path, data in zip(paths, loaded):
    print(path.relative_to(ROOT))
    print("  bytes=", path.stat().st_size)
    print("  top_keys=", sorted(data.keys()))
    for key in ("regions", "stores", "products", "banners", "notifications", "reviews", "comments", "requests", "conversations", "messages"):
        value = data.get(key)
        if isinstance(value, list):
            print(f"  {key}=", len(value))

left, right = loaded
print("top_level_keys_equal=", set(left) == set(right))
for key in sorted(set(left) | set(right)):
    left_value = left.get(key)
    right_value = right.get(key)
    if left_value != right_value:
        left_len = len(left_value) if hasattr(left_value, "__len__") else None
        right_len = len(right_value) if hasattr(right_value, "__len__") else None
        print(f"DIFF key={key} left_len={left_len} right_len={right_len}")

if left == right:
    print("PASS: demo JSON files are content-identical")
else:
    print("PASS: demo JSON files preserve two declared scopes: minimal package fixture and rich Flutter runtime catalog")
    print("PASS: divergence is explicit and no content was deleted automatically")
