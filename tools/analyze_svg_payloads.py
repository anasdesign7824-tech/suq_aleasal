from pathlib import Path
import base64
import re

root = Path('/home/ubuntu/suq_aleasal/apps/mobile_flutter/assets')
for path in sorted(root.glob('logo*.svg')):
    text = path.read_text(encoding='utf-8')
    print(f'=== {path.name} ===')
    print(f'file_bytes={path.stat().st_size}')
    matches = re.findall(r'data:image/([^;]+);base64,([A-Za-z0-9+/=]+)', text)
    print(f'embedded_count={len(matches)}')
    for index, (mime, payload) in enumerate(matches, start=1):
        raw = base64.b64decode(payload)
        print(f'embedded_{index}: mime={mime} base64_chars={len(payload)} decoded_bytes={len(raw)} signature={raw[:16].hex()}')
    print(f'filter_count={text.count("<filter")}')
