from pathlib import Path
import base64
import io
import re
import sys
from PIL import Image, ImageChops

root = Path('/home/ubuntu/suq_aleasal/apps/mobile_flutter/assets')
mode = sys.argv[1] if len(sys.argv) > 1 else 'inspect'

for path in sorted(root.glob('logo*-runtime.svg')):
    text = path.read_text(encoding='utf-8')
    matches = list(re.finditer(r'data:image/(png);base64,([A-Za-z0-9+/=]+)', text))
    print(f'=== {path.name} ===')
    replacements = []
    for index, match in enumerate(matches, start=1):
        raw = base64.b64decode(match.group(2))
        source = Image.open(io.BytesIO(raw))
        source.load()
        print(f'image_{index}: size={source.size} mode={source.mode} bytes={len(raw)} info_keys={sorted(source.info.keys())}')
        buffer = io.BytesIO()
        source.save(buffer, format='PNG', optimize=True, compress_level=9)
        optimized = buffer.getvalue()
        check = Image.open(io.BytesIO(optimized))
        check.load()
        if source.size != check.size or source.mode != check.mode or ImageChops.difference(source.convert('RGBA'), check.convert('RGBA')).getbbox() is not None:
            raise RuntimeError(f'pixel mismatch in {path.name} image {index}')
        print(f'image_{index}_optimized_bytes={len(optimized)} saved={len(raw)-len(optimized)}')
        replacements.append((match.start(2), match.end(2), base64.b64encode(optimized).decode('ascii')))
    if mode == 'write':
        result = []
        cursor = 0
        for start, end, replacement in replacements:
            result.append(text[cursor:start])
            result.append(replacement)
            cursor = end
        result.append(text[cursor:])
        out = path.with_name(path.stem + '-optimized.svg')
        out.write_text(''.join(result), encoding='utf-8')
        print(f'written={out} bytes={out.stat().st_size}')
