import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
sql = (root / "database" / "migrations" / "0004_admin_helper_security.sql").read_text(encoding="utf-8")
payload = {
    "project_id": "gvalqfgxrkibuydoiuiz",
    "name": "admin_helper_security",
    "query": sql,
}
output = root / "database" / "migrations" / "0004_admin_helper_security.mcp.json"
output.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
print(output)
