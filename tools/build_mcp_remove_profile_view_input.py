import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
sql = (root / "database" / "migrations" / "0006_remove_security_definer_view.sql").read_text(encoding="utf-8")
payload = {
    "project_id": "gvalqfgxrkibuydoiuiz",
    "name": "remove_security_definer_view",
    "query": sql,
}
output = root / "database" / "migrations" / "0006_remove_security_definer_view.mcp.json"
output.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
print(output)
