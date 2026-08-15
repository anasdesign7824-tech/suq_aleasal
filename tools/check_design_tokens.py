import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
dart = (root / "packages/design_system/dart/lib/assal_tokens.dart").read_text(encoding="utf-8")
ts = (root / "packages/design_system/web/tokens.ts").read_text(encoding="utf-8")

names = [
    "primary", "primaryDark", "primaryLight", "secondary", "deepBrown", "honey",
    "honeyLight", "cream", "background", "surface", "surfaceVariant", "textPrimary",
    "textSecondary", "textMuted", "border", "success", "warning", "error", "info",
]

def dart_color(name):
    match = re.search(rf"static const {name} = Color\(0xFF([0-9A-Fa-f]{{6}})\);", dart)
    if not match:
        raise SystemExit(f"missing Dart token: {name}")
    return "#" + match.group(1).upper()

def ts_color(name):
    match = re.search(rf"\s{name}: \"(#[0-9A-Fa-f]{{6}})\",", ts)
    if not match:
        raise SystemExit(f"missing TypeScript token: {name}")
    return match.group(1).upper()

for name in names:
    left, right = dart_color(name), ts_color(name)
    if left != right:
        raise SystemExit(f"token mismatch {name}: {left} != {right}")


def channel(value):
    value = value / 255
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4

def luminance(hex_color):
    rgb = [int(hex_color[i:i+2], 16) for i in (1, 3, 5)]
    r, g, b = (channel(v) for v in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def contrast(a, b):
    first, second = luminance(a), luminance(b)
    light, dark = max(first, second), min(first, second)
    return (light + 0.05) / (dark + 0.05)

pairs = {
    "textPrimary_on_background": ("textPrimary", "background"),
    "textSecondary_on_background": ("textSecondary", "background"),
    "surface_on_primaryDark": ("surface", "primaryDark"),
    "surface_on_deepBrown": ("surface", "deepBrown"),
}
for label, (foreground, background) in pairs.items():
    ratio = contrast(ts_color(foreground), ts_color(background))
    print(f"{label}={ratio:.2f}")
    if ratio < 4.5:
        raise SystemExit(f"contrast below AA target: {label}={ratio:.2f}")

print("PASS: Dart and TypeScript tokens match and core text pairs meet AA contrast target")
