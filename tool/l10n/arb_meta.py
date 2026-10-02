#!/usr/bin/env python3
"""Adds @key placeholder metadata to the template ARB in order of appearance,
so generated method parameters follow the order they appear in the English
text (gen-l10n otherwise sorts them alphabetically). Run after editing
lib/l10n/app_en.arb, then `flutter gen-l10n`."""
import json, re, sys
from collections import OrderedDict

path = sys.argv[1] if len(sys.argv) > 1 else 'lib/l10n/app_en.arb'
data = json.load(open(path, encoding='utf-8'), object_pairs_hook=OrderedDict)
out = OrderedDict()
for k, v in data.items():
    if k.startswith('@'):
        continue
    out[k] = v
    if not isinstance(v, str):
        continue
    names = []
    # top-level placeholders and plural/select selectors
    for m in re.finditer(r'\{(\w+)(?=\}|\s*,\s*(?:plural|select))', v):
        n = m.group(1)
        if n not in names and n not in ('other',) and not re.fullmatch(r'=?\d+', n):
            names.append(n)
    # drop words that are plural case labels like "one"
    names = [n for n in names if n not in ('zero', 'one', 'two', 'few', 'many')]
    if names:
        ph = OrderedDict()
        for n in names:
            if re.search(r'\{' + n + r',\s*plural', v) or n in ('count', 'seconds', 'age', 'max', 'value'):
                ph[n] = {'type': 'int'}
            else:
                ph[n] = {'type': 'String'}
        out['@' + k] = {'placeholders': ph}
json.dump(out, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
open(path, 'a').write('\n')
