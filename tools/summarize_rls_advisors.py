import json
from pathlib import Path
from collections import defaultdict

path = Path("/home/ubuntu/.mcp/tool-results/2026-08-15_21-10-04.325002113_supabase_get_advisors_f8ea75c2.json")
data = json.loads(path.read_text(encoding="utf-8"))
groups = defaultdict(list)
for lint in data.get("result", {}).get("lints", []):
    groups[lint.get("name")].append(lint.get("detail"))
for name, details in sorted(groups.items()):
    print(f"[{name}] count={len(details)}")
    for detail in sorted(set(details)):
        print(detail)
