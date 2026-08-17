import json
from pathlib import Path
import sys

path = Path(sys.argv[1])
data = json.loads(path.read_text())

def children(node):
    return node.get('children', []) if isinstance(node, dict) else []

def walk(node, prefix=''):
    yield prefix + node.get('n', ''), node.get('value', 0), node
    for child in children(node):
        yield from walk(child, prefix + node.get('n', '') + '/')

print('=== top-level ===')
for node in children(data):
    print(node.get('n'), node.get('value', 0))
print('=== lib children ===')
lib = next((n for n in children(data) if n.get('n') == 'lib'), None)
if lib:
    for node in children(lib):
        print(node.get('n'), node.get('value', 0))
print('=== asset children ===')
assets = next((n for n in children(data) if n.get('n') == 'assets'), None)
if assets:
    for node in children(assets):
        print(node.get('n'), node.get('value', 0))
print('=== Dart package roots by accounted value ===')
for name, value, node in sorted(walk(data), key=lambda item: item[1], reverse=True):
    if node.get('n', '').startswith('package:') and node.get('value', 0) >= 10000:
        print(node.get('n'), node.get('value', 0))
