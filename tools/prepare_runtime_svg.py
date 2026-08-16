from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path('/home/ubuntu/suq_aleasal/apps/mobile_flutter/assets')

for name in ('logo-internal.svg', 'logo-external.svg'):
    source = ROOT / name
    target = ROOT / name.replace('.svg', '-runtime.svg')
    text = source.read_text(encoding='utf-8')
    text = re.sub(r'<filter\b[^>]*>.*?</filter>', '', text, flags=re.DOTALL)
    text = re.sub(r'\sfilter="url\(#[^\"]+\)"', '', text)
    ET.fromstring(text)
    target.write_text(text, encoding='utf-8')
    print(f'{source.name}: {source.stat().st_size} -> {target.stat().st_size}')
