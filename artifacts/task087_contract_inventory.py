from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def snake_to_camel(value: str) -> str:
    parts = value.split("_")
    return parts[0] + "".join(part[:1].upper() + part[1:] for part in parts[1:])


def camel_to_snake(value: str) -> str:
    return re.sub(r"(?<!^)([A-Z])", r"_\1", value).lower()


def parse_dart(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    enums: dict[str, list[str]] = {}
    for match in re.finditer(r"\benum\s+(\w+)\s*\{([^}]*)\}", text, re.S):
        body = match.group(2)
        enums[match.group(1)] = re.findall(r"\b([A-Za-z_]\w*)\b", body)

    wire_maps: dict[str, dict[str, str]] = {}
    for match in re.finditer(r"extension\s+(\w+).*?get\s+wireValue\s*=>\s*switch\s*\(this\)\s*=>\s*\{(.*?)\n\s*\};", text, re.S):
        wire_maps[match.group(1)] = dict(re.findall(r"\.([A-Za-z_]\w*)\s*=>\s*'([^']+)'", match.group(2)))

    classes: dict[str, dict] = {}
    class_matches = list(re.finditer(r"\bclass\s+(\w+)[^{]*\{", text))
    for index, match in enumerate(class_matches):
        start = match.end()
        end = class_matches[index + 1].start() if index + 1 < len(class_matches) else len(text)
        body = text[start:end]
        fields: dict[str, str] = {}
        for field_match in re.finditer(r"^\s*final\s+(.+?)\s+([A-Za-z_]\w*)\s*;\s*$", body, re.M):
            field_type = field_match.group(1).strip()
            field_name = field_match.group(2)
            if field_name not in {"id"} or field_type != "static":
                fields[field_name] = field_type
        json_keys = sorted(set(re.findall(r"json\['([^']+)'\]", body)))
        classes[match.group(1)] = {"fields": fields, "json_keys": json_keys}
    return {"enums": enums, "wire_maps": wire_maps, "classes": classes}


def parse_ts_domain(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    unions: dict[str, list[str]] = {}
    for match in re.finditer(r"export\s+type\s+(\w+)\s*=\s*([^;]+);", text):
        values = re.findall(r'"([^"\\]+)"', match.group(2))
        if values:
            unions[match.group(1)] = values
    interfaces: dict[str, dict[str, str]] = {}
    for match in re.finditer(r"export\s+interface\s+(\w+)\s*\{(.*?)\n\}", text, re.S):
        fields: dict[str, str] = {}
        for field_match in re.finditer(r"^\s*([A-Za-z_]\w*)\??\s*:\s*([^;]+);\s*$", match.group(2), re.M):
            fields[field_match.group(1)] = field_match.group(2).strip()
        interfaces[match.group(1)] = fields
    return {"unions": unions, "interfaces": interfaces}


def extract_braced(text: str, open_index: int) -> str:
    depth = 0
    for index in range(open_index, len(text)):
        if text[index] == "{":
            depth += 1
        elif text[index] == "}":
            depth -= 1
            if depth == 0:
                return text[open_index + 1:index]
    raise ValueError("Unbalanced braces in Database contract")


def parse_database(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    tables: dict[str, list[str]] = {}
    sections = re.findall(r"^    (Tables|Views):\s*\{(.*?)(?=^    (?:Views|Functions):|^    (?:Enums|CompositeTypes):|\Z)", text, re.M | re.S)
    for _, section in sections:
        for table_match in re.finditer(r"^      ([A-Za-z_]\w*):\s*\{", section, re.M):
            table_name = table_match.group(1)
            table_body = extract_braced(section, table_match.end() - 1)
            row_match = re.search(r"\bRow:\s*\{", table_body)
            if row_match is None:
                continue
            row_body = extract_braced(table_body, row_match.end() - 1)
            fields = set(re.findall(r"^\s{8}([A-Za-z_]\w*):", row_body, re.M))
            fields.update(re.findall(r"\b([A-Za-z_]\w*):\s*[^;{}]+(?:;|$)", row_body))
            tables[table_name] = sorted(fields)
    return {"tables": tables}


def parse_admin(path: Path, tables: dict[str, list[str]]) -> dict:
    text = path.read_text(encoding="utf-8")
    refs = sorted(set(re.findall(r"\.from\(['\"]([A-Za-z_]\w*)['\"]\)", text)))
    select_fields: dict[str, list[str]] = {}
    for table in refs:
        pattern = rf"\.from\(['\"]{re.escape(table)}['\"]\)(.*?)(?=\n\s*\.from\(|\nexport\s+|\Z)"
        chunks = re.findall(pattern, text, re.S)
        fields: set[str] = set()
        for chunk in chunks:
            for select_match in re.finditer(r"\.select\(['\"]([^'\"]+)['\"]", chunk):
                raw = select_match.group(1)
                if raw.strip() == "*":
                    continue
                for token in raw.split(","):
                    token = token.strip()
                    if re.fullmatch(r"[A-Za-z_]\w*", token):
                        fields.add(token)
        select_fields[table] = sorted(fields)
    return {
        "tables": refs,
        "tables_missing_from_database_contract": [table for table in refs if table not in tables],
        "explicit_select_fields": select_fields,
    }


def compare(dart: dict, ts: dict, database: dict, admin: dict) -> dict:
    class_interface_comparison = {}
    for class_name, dart_info in dart["classes"].items():
        if class_name not in ts["interfaces"]:
            continue
        dart_fields = set(dart_info["fields"])
        ts_fields = set(ts["interfaces"][class_name])
        class_interface_comparison[class_name] = {
            "dart_only": sorted(dart_fields - ts_fields),
            "typescript_only": sorted(ts_fields - dart_fields),
            "shared": sorted(dart_fields & ts_fields),
        }

    json_db_comparison = {}
    for class_name, dart_info in dart["classes"].items():
        if not dart_info["json_keys"]:
            continue
        keys = set(dart_info["json_keys"])
        possible_tables = []
        for table, db_fields in database["tables"].items():
            if keys & set(db_fields):
                possible_tables.append(table)
        json_db_comparison[class_name] = {
            "json_keys": sorted(keys),
            "candidate_tables": sorted(possible_tables),
            "keys_not_in_any_database_row": sorted(key for key in keys if not any(key in fields for fields in database["tables"].values())),
        }

    enum_comparison = {}
    mapping = {
        "AssalRole": "AssalRole",
        "ProductType": "ProductType",
        "ProductStatus": "ProductStatus",
        "StoreStatus": "StoreStatus",
        "VerificationStatus": "VerificationStatus",
        "ReviewStatus": "ReviewStatus",
        "RequestStatus": "RequestStatus",
    }
    for dart_enum, ts_union in mapping.items():
        dart_values = set(dart["enums"].get(dart_enum, []))
        ts_values = set(ts["unions"].get(ts_union, []))
        enum_comparison[dart_enum] = {
            "dart_values": sorted(dart_values),
            "typescript_values": sorted(ts_values),
            "dart_only": sorted(dart_values - ts_values),
            "typescript_only": sorted(ts_values - dart_values),
        }

    return {
        "counts": {
            "dart_enums": len(dart["enums"]),
            "dart_classes": len(dart["classes"]),
            "typescript_unions": len(ts["unions"]),
            "typescript_interfaces": len(ts["interfaces"]),
            "database_tables": len(database["tables"]),
            "admin_from_tables": len(admin["tables"]),
        },
        "enum_comparison": enum_comparison,
        "class_interface_comparison": class_interface_comparison,
        "json_database_comparison": json_db_comparison,
        "admin": admin,
    }


def main() -> None:
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    output = Path(sys.argv[2]) if len(sys.argv) > 2 else root / "artifacts" / "task087_contract_inventory.json"
    dart = parse_dart(root / "packages/contracts_dart/lib/assal_domain.dart")
    ts = parse_ts_domain(root / "packages/contracts_ts/src/domain.ts")
    database = parse_database(root / "packages/contracts_ts/src/database.ts")
    admin = parse_admin(root / "apps/admin_web/server/admin-data.ts", database["tables"])
    result = compare(dart, ts, database, admin)
    production_snapshot_path = root / "artifacts" / "task087_production_schema_snapshot.json"
    if production_snapshot_path.exists():
        production_relations = set(json.loads(production_snapshot_path.read_text(encoding="utf-8"))["relations"])
        contract_relations = set(database["tables"])
        result["production_relation_comparison"] = {
            "contract_only": sorted(contract_relations - production_relations),
            "production_only": sorted(production_relations - contract_relations),
            "shared_count": len(contract_relations & production_relations),
        }
        if contract_relations != production_relations:
            raise RuntimeError(f"Database contract relation drift: {result['production_relation_comparison']}")
    expected_counts = {
        "dart_enums": 12,
        "dart_classes": 35,
        "typescript_unions": 7,
        "typescript_interfaces": 7,
        "database_tables": 62,
        "admin_from_tables": 31,
    }
    if result["counts"] != expected_counts:
        raise RuntimeError(f"Contract inventory counts changed: {result['counts']}")
    for enum_name in ("ProductType", "ProductStatus", "StoreStatus", "VerificationStatus", "ReviewStatus"):
        comparison = result["enum_comparison"][enum_name]
        if comparison["dart_only"] or comparison["typescript_only"]:
            raise RuntimeError(f"Unexpected enum drift in {enum_name}: {comparison}")
    request_comparison = result["enum_comparison"]["RequestStatus"]
    if request_comparison["dart_only"] != ["inProgress"] or request_comparison["typescript_only"] != ["in_progress"]:
        raise RuntimeError(f"Unexpected RequestStatus wire drift: {request_comparison}")
    if result["admin"]["tables_missing_from_database_contract"] != ["assalkom_private", "assalkom_public"]:
        raise RuntimeError("Only known storage bucket names may be absent from Database relation keys")
    result["source_files"] = {
        "dart": "packages/contracts_dart/lib/assal_domain.dart",
        "typescript_domain": "packages/contracts_ts/src/domain.ts",
        "typescript_database": "packages/contracts_ts/src/database.ts",
        "admin": "apps/admin_web/server/admin-data.ts",
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(result["counts"], ensure_ascii=False, sort_keys=True))
    print(f"written={output}")


if __name__ == "__main__":
    main()
