from pathlib import Path
import base64
import io
import re
import sys
from PIL import Image, ImageChops

source_name = sys.argv[1]
target_path = Path(sys.argv[2])
target_width = int(sys.argv[3])
source_path = Path('/home/ubuntu/suq_aleasal/apps/mobile_flutter/assets') / source_name
text = source_path.read_text(encoding='utf-8')
pattern = re.compile(r'data:image/(png);base64,([A-Za-z0-9+/=]+)')
matches = list(pattern.finditer(text))
if not matches:
    raise RuntimeError('no embedded PNG payloads found')
replacements = []
for match in matches:
    raw = base64.b64decode(match.group(2))
    source = Image.open(io.BytesIO(raw))
    source.load()
    if source.width != 6144:
        raise RuntimeError(f'unexpected width {source.width}')
    target_height = round(source.height * target_width / source.width)
    resized = source.resize((target_width, target_height), Image.Resampling.LANCZOS)
    buffer = io.BytesIO()
    resized.save(buffer, format='PNG', optimize=True, compress_level=9)
    optimized = buffer.getvalue()
    # Decode again to catch invalid output and preserve mode/geometry.
    check = Image.open(io.BytesIO(optimized))
    check.load()
    if check.size != resized.size or check.mode != resized.mode:
        raise RuntimeError('round-trip image mismatch')
    replacements.append((match.start(2), match.end(2), base64.b64encode(optimized).decode('ascii')))
result = []
cursor = 0
for start, end, replacement in replacements:
    result.append(text[cursor:start])
    result.append(replacement)
    cursor = end
result.append(text[cursor:])
output = ''.join(result)
output = output.replace('width="6144"', f'width="{target_width}"')
target_path.parent.mkdir(parents=True, exist_ok=True)
target_path.write_text(output, encoding='utf-8')
print(f'{source_name} -> {target_path} bytes={target_path.stat().st_size}')
