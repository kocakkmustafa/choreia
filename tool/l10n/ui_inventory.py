"""Inventory literal bilingual UI copy; never guesses runtime/dynamic text.

This is a source inventory, not a Dart parser or a product acceptance test.
"""
import argparse
import ast
import json
import re
from pathlib import Path

APP = Path(__file__).resolve().parents[2]

def literal(source, start):
    start += len(source[start:]) - len(source[start:].lstrip())
    begin = start
    parts = []
    while start < len(source) and source[start] in "'\"":
        quote = source[start]
        if source[start:start+3] == quote * 3:
            return None
        end = start + 1
        while end < len(source):
            if source[end] == '\\':
                end += 2
                continue
            if source[end] == quote:
                break
            end += 1
        raw = source[start:end+1]
        if '$' in raw:
            return None
        try:
            parts.append(ast.literal_eval(raw))
        except (SyntaxError, ValueError):
            return None
        start = end + 1
        start += len(source[start:]) - len(source[start:].lstrip())
    return (''.join(parts), start, source[begin:start].rstrip()) if parts else None

def inventory():
    pairs = {}
    files = sorted((APP / 'lib').rglob('*.dart'))
    qualified = {}
    for file in files:
        source = file.read_text()
        classes = list(re.finditer(r'^\s*(?:(?:abstract|final|sealed|base)\s+)*class\s+(\w+)', source, re.M))
        for match in re.finditer(r'\bstatic const String\s+(\w+)\s*=', source):
            value = literal(source, match.end())
            owner = [c[1] for c in classes if c.start() < match.start()]
            if value and owner:
                qualified[f'{owner[-1]}.{match[1]}'] = value[0]
    for file in files:
        if file.name.endswith('_messages.dart'):
            continue
        source = file.read_text()
        constants = {}
        for match in re.finditer(r'\bstatic const String\s+(\w+)\s*=', source):
            value = literal(source, match.end())
            if value:
                constants[match[1]] = value[0]
        def add(en, tr, offset):
            if not en or en in {'en', 'tr'}:
                return
            entry = pairs.setdefault(en, {'en': en, 'tr': tr, 'sources': []})
            entry['sources'].append(f'{file.relative_to(APP)}:{source.count(chr(10), 0, offset)+1}')
        for match in re.finditer(r'\b(?:_?tr|turkish)\s*\?', source):
            tr = literal(source, match.end())
            if not tr or source[tr[1]:tr[1]+1] != ':':
                continue
            en = literal(source, tr[1]+1)
            if en:
                add(en[0], tr[0], match.start())
        for match in re.finditer(r'\b(?:t|_pick|_pair|_format|StudyText)\s*\(', source):
            en = literal(source, match.end())
            if not en or source[en[1]:en[1]+1] != ',':
                continue
            tr = literal(source, en[1]+1)
            if tr:
                add(en[0], tr[0], match.start())
        # Known page helper: context is followed by literal EN/TR arguments.
        # Calls with a runtime English value or without a Turkish literal are
        # deliberately omitted rather than guessed.
        for match in re.finditer(r'\b_text\s*\(\s*context\s*,', source):
            en = literal(source, match.end())
            if not en or source[en[1]:en[1]+1] != ',':
                continue
            tr = literal(source, en[1]+1)
            if tr:
                add(en[0], tr[0], match.start())
        for match in re.finditer(r'\ben:\s*', source):
            en = literal(source, match.end())
            if not en:
                continue
            after = re.match(r',\s*tr:\s*', source[en[1]:])
            if after:
                tr = literal(source, en[1]+after.end())
                if tr:
                    add(en[0], tr[0], match.start())
        # A known UI constant followed by a literal Turkish translation.
        for match in re.finditer(r'\b(?:_pick\(\s*|en:\s*)((?:\w+)\.\w+)\s*,\s*(?:tr:\s*)?', source):
            en = qualified.get(match[1])
            tr = literal(source, match.end())
            if en and tr:
                add(en, tr[0], match.start())
        for match in re.finditer(r'\btr:\s*', source):
            tr = literal(source, match.end())
            if not tr:
                continue
            after = re.match(r',\s*en:\s*', source[tr[1]:])
            if after:
                en = literal(source, tr[1]+after.end())
                if en:
                    add(en[0], tr[0], match.start())
    return list(pairs.values())

def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path,
                        help='explicit destination for inventory JSON; otherwise no file is written')
    parser.add_argument('--json', action='store_true',
                        help='print the complete inventory instead of its summary')
    args = parser.parse_args(argv)
    rows = inventory()
    if args.output is not None:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(
            json.dumps(rows, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    summary = {'kind': 'STATIC_LITERAL_SOURCE_INVENTORY_ONLY',
        'unique_pairs': len(rows), 'english_words': sum(len(row['en'].split()) for row in rows),
        'written_to': str(args.output) if args.output is not None else None,
        'dynamic_and_unbound_text': 'not inferred; separate screen acceptance required'}
    print(json.dumps(rows if args.json else summary, ensure_ascii=False,
                     indent=2 if args.json else None))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
