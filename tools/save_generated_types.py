import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser(description="Save generated Supabase TypeScript types into the repository")
parser.add_argument("source", type=Path, help="Path to the MCP result JSON containing a types field")
args = parser.parse_args()

root = Path(__file__).resolve().parents[1]
data = json.loads(args.source.read_text(encoding="utf-8"))
types = data["types"]
output = root / "packages" / "contracts_ts" / "src" / "database.ts"
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(types + "\n", encoding="utf-8")
print(f"saved={output} bytes={len(types.encode('utf-8'))}")
