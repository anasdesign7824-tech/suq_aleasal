from pathlib import Path

root = Path(__file__).resolve().parents[1]
app = root / "apps/mobile_flutter"
required = [
    app / "pubspec.yaml",
    app / "lib/main.dart",
    app / "lib/app/assal_app.dart",
    app / "lib/app/assal_theme.dart",
    app / "lib/core/demo_loader.dart",
    app / "lib/core/assal_widgets.dart",
    app / "lib/features/customer/home_screen.dart",
    app / "lib/features/customer/product_detail_screen.dart",
    app / "lib/features/merchant/merchant_dashboard.dart",
    app / "test/data_layer_test.dart",
    app / "assets/demo_catalog.json",
    app / "assets/logo-internal.svg",
    app / "assets/logo-external.svg",
]
missing = [str(path.relative_to(root)) for path in required if not path.exists()]
if missing:
    raise SystemExit("missing Flutter app files: " + ", ".join(missing))

pubspec = (app / "pubspec.yaml").read_text(encoding="utf-8")
for token in ["name: assalkom", "flutter_svg:", "IBM Plex Sans Arabic", "assets/demo_catalog.json"]:
    if token not in pubspec:
        raise SystemExit(f"pubspec missing {token}")

source_files = list((app / "lib").rglob("*.dart"))
source = "\n".join(path.read_text(encoding="utf-8") for path in source_files)
for token in ["DemoRepository", "DemoModePill", "HomeScreen", "ProductDetailScreen", "MerchantDashboard", "Directionality", "AssalColors"]:
    if token not in source:
        raise SystemExit(f"Flutter source missing anchor {token}")

if "Supabase" in source or "supabase" in source:
    raise SystemExit("Flutter Demo UI must not connect directly to Supabase")

print(f"PASS: Flutter app scaffold, Demo boundary, assets, Customer/Merchant anchors verified ({len(source_files)} Dart files)")
