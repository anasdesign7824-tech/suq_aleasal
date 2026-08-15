import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
sql = (root / "database" / "migrations" / "0003_rls_performance_and_policy_cleanup.sql").read_text(encoding="utf-8")
payload = {
    "project_id": "gvalqfgxrkibuydoiuiz",
    "name": "rls_performance_and_policy_cleanup",
    "query": sql,
}
output = root / "database" / "migrations" / "0003_rls_performance_and_policy_cleanup.mcp.json"
output.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
print(output)
