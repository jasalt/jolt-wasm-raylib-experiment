#!/usr/bin/env python3
"""Measure raw and deterministic gzip-9 bytes; never confuse boot with Wasm."""
import gzip
import hashlib
import json
import sys
from pathlib import Path

baseline, current, output = map(Path, sys.argv[1:])
names = ['scheme.wasm', 'scheme.data', 'scheme.js', 'jolt.boot']
def measure(root):
    return {name: {'bytes': len(data), 'gzip9_bytes': len(gzip.compress(data, compresslevel=9, mtime=0)),
                   'sha256': hashlib.sha256(data).hexdigest()}
            for name in names for data in [(root / name).read_bytes()]}
old, new = measure(baseline), measure(current)
result = {'baseline_revision': '6cb7d2ec4c82201fe54f0685f6c6ff433f106ecf',
          'updated_revision': '5b46858a171f30949f5b09eb484bc6c5ff93c6ea',
          'baseline': old, 'updated': new,
          'delta': {name: {'bytes': new[name]['bytes'] - old[name]['bytes'],
                           'percent': round(100 * (new[name]['bytes'] / old[name]['bytes'] - 1), 3)}
                    for name in names}}
for label, data in [('baseline', old), ('updated', new)]:
    result[label + '_download_bytes'] = sum(data[n]['bytes'] for n in names[:3])
    result[label + '_download_gzip9_bytes'] = sum(data[n]['gzip9_bytes'] for n in names[:3])
output.write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
