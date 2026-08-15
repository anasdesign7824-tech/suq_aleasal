import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
sql = (root / "database" / "migrations" / "0001_initial_souq_al_assal.sql").read_text(encoding="utf-8")
payload = {
    "project_id": "gvalqfgxrkibuydoiuiz",
    "name": "initial_souq_al_assal",
    "query": sql,
}
output = root / "database" / "migrations" / "0001_initial_souq_al_assal.mcp.json"
output.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
print(output)
