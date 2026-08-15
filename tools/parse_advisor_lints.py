import json
from pathlib import Path

path = Path("/home/ubuntu/.mcp/tool-results/2026-08-15_21-10-04.325002113_supabase_get_advisors_f8ea75c2.json")
data = json.loads(path.read_text(encoding="utf-8"))
lints = data.get("result", {}).get("lints", [])
print(f"count={len(lints)}")
for lint in lints:
    print(f"{lint.get('name')}|{lint.get('level')}|{lint.get('detail')}|{lint.get('remediation')}")
