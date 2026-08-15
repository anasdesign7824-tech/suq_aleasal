import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
sql = (root / "database" / "migrations" / "0002_security_hardening.sql").read_text(encoding="utf-8")
payload = {
    "project_id": "gvalqfgxrkibuydoiuiz",
    "name": "security_hardening",
    "query": sql,
}
output = root / "database" / "migrations" / "0002_security_hardening.mcp.json"
output.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
print(output)
