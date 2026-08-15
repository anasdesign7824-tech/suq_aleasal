import json
from pathlib import Path

repo = Path(__file__).resolve().parents[1]
source = repo / "packages" / "demo_data" / "data" / "demo_catalog.json"
target = Path("/home/ubuntu/assalkom-admin/client/src/data/demoCatalog.ts")

catalog = json.loads(source.read_text(encoding="utf-8"))
target.parent.mkdir(parents=True, exist_ok=True)
payload = json.dumps(catalog, ensure_ascii=False, indent=2)
target.write_text(
    "// Design: دار العسل التحريرية — Demo data only; do not connect to Supabase here.\n"
    "export const demoCatalog = " + payload + " as const;\n",
    encoding="utf-8",
)
print(f"catalog products={len(catalog['products'])} stores={len(catalog['stores'])} reviews={len(catalog['reviews'])} -> {target}")
