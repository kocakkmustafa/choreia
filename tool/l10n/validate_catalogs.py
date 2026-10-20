#!/usr/bin/env python3
"""Read-only checks for the checked-in Choreia localization assets.

Run from any directory: python3 -B tool/l10n/validate_catalogs.py
No SDK, network, workspace seed, git checkout/HEAD or third-party package is
needed. Exit 0 means static source/asset checks passed, not product acceptance.
"""

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import sys

# Importing the sibling inventory must not create bytecode in the checkout.
sys.dont_write_bytecode = True
import ui_inventory
from generate_bases import check_bases, load_string_map

APP = Path(__file__).resolve().parents[2]
LOCALES = ('en', 'tr', 'es-419', 'pt-BR', 'de', 'fr', 'ja', 'ar', 'it', 'ko', 'id', 'pl', 'hi', 'zh-Hans')
# UI grows with app-owned copy; its English asset defines the current key set.
EXPECTED_COUNTS = {'course': 1054, 'ui': None, 'catalog': 430}
PLACEHOLDER = re.compile(r'\{([A-Za-z][A-Za-z0-9_]*)\}')
# RFC 3986 URI characters. In particular, Japanese prose/full-width punctuation
# may immediately follow an ASCII URI without whitespace; it is not URL text.
URL = re.compile(r'https?://[A-Za-z0-9._~:/?#\[\]@!$&()*+,;=%-]+')

# Explicit English Progress source keys, used ONLY as inventory coverage
# exceptions. This validator never parses/guesses the hand-authored Dart maps.
# Changes to that dictionary still need its dedicated Dart parity/widget tests;
# keep this reviewed source-key list in sync when app-owned copy changes.
PROGRESS_ENGLISH_KEYS = frozenset({
    'Your practice',
    'Progress',
    'The session history below covers camera practice only. Written-course practice and self reports are kept separately in each course; they are not included in these session counts.',
    'Camera-session records',
    'Saved session measurements, not dance-skill grades.',
    'Evaluated',
    'Judgements about how you did. Graded lessons only.',
    'No camera-session grades are shown here. A verdict is not kept in these session records, so they never turn into a score. Written-course practice and self reports are separate learning records, not measured dance skill. An absent grade is not a zero.',
    'What we cannot check',
    'Named, with the reason. We would rather tell you than leave it out.',
    'One saved session could not be read back. Everything below counts what we could read, so treat it as "at least this much" rather than a full total.',
    '{count} saved sessions could not be read back. Everything below counts what we could read, so treat it as "at least this much" rather than a full total.',
    'We found one saved session but could not read it. That is not the same as you not having practised — we simply cannot tell you what is in it.',
    'We found {count} saved sessions but could not read any of them. That is not the same as you not having practised — we simply cannot tell you what is in them.',
    'This session-history source does not save camera practice. There is nothing in this source to show or lose. Written-course learning records are kept separately.',
    'We could not open your camera-session history. Rather than show you a zero that would be wrong, we are not showing numbers until we can read it.',
    'No camera sessions are saved in this history. Written-course practice may still be recorded in the courses.',
    'We cannot show these camera-session records because the history could not be read. That is not the same as an empty history; its contents cannot be confirmed. Written-course records are separate.',
    '—',
    '{minutes} min practised',
    '{hours}h practised',
    '{hours}h {minutes}m practised',
    '{count} cycle read',
    '{count} cycles read',
    '{completed} of {planned} cycles',
    '{completed} of {total} sessions finished',
    '{count} session',
    '{count} sessions',
    'Taught, not graded',
    'Taught, not graded — {reason}',
    '{count} cycle we could not check (framing or lighting)',
    '{count} cycles we could not check (framing or lighting)',
    'When a check opens up later, it applies from that point on — never backwards over dancing we were not measuring at the time. This history source saves no camera sessions, so it has no past sessions waiting to be re-scored. Written-course records are separate.',
    'When a check opens up later, it applies from that point on. Practice time already recorded stays a record of practice — it is not converted into a score for something we were not measuring at the time.',
    'Opens when: {condition}',
})


def placeholders(text):
    return Counter(PLACEHOLDER.findall(text))


def urls(text):
    # Plain-text UI/course links may be followed by sentence punctuation or a
    # closing wrapper. Preserve the URL's scheme, host, path, query and fragment.
    result = []
    for match in URL.findall(text):
        match = match.rstrip('.,;:!?،؛')
        for opening, closing in [('(', ')'), ('[', ']')]:
            while (match.endswith(closing)
                   and match.count(closing) > match.count(opening)):
                match = match[:-1]
        result.append(match)
    return Counter(result)


def _sample(values, limit=5):
    return sorted(values)[:limit]


def validate(app=APP):
    app = Path(app)
    assets_dir = app / 'content/l10n'
    errors = []
    counts = {}
    catalogs = {}

    def error(code, **details):
        errors.append({'code': code, **details})

    def load(path):
        relative = str(path.relative_to(app))
        try:
            return load_string_map(path)
        except (OSError, UnicodeError, ValueError) as problem:
            error('invalid_asset', path=relative, detail=str(problem))
            return None

    for kind, expected_count in EXPECTED_COUNTS.items():
        found = {path.name[len(kind) + 1:-5]
                 for path in assets_dir.glob(f'{kind}.*.json')
                 if path.name != 'course.index.json'}
        if found != set(LOCALES):
            error('locale_files', kind=kind,
                  missing=sorted(set(LOCALES) - found),
                  unexpected=sorted(found - set(LOCALES)))
        localized = catalogs[kind] = {}
        counts[kind] = {}
        for tag in LOCALES:
            path = assets_dir / f'{kind}.{tag}.json'
            rows = load(path)
            if rows is None:
                counts[kind][tag] = None
                continue
            localized[tag] = rows
            counts[kind][tag] = len(rows)
            if expected_count is not None and len(rows) != expected_count:
                error('entry_count', path=str(path.relative_to(app)),
                      expected=expected_count, actual=len(rows))
        english = localized.get('en')
        if english is None:
            continue
        english_keys = set(english)
        if kind in ('ui', 'catalog'):
            nonidentity = [key for key, value in english.items() if key != value]
            if nonidentity:
                error('english_source_identity', kind=kind,
                      count=len(nonidentity), examples=_sample(nonidentity))
        for tag, rows in localized.items():
            actual_keys = set(rows)
            if actual_keys != english_keys:
                error('locale_key_parity', kind=kind, locale=tag,
                      missing_count=len(english_keys - actual_keys),
                      extra_count=len(actual_keys - english_keys),
                      missing_examples=_sample(english_keys - actual_keys),
                      extra_examples=_sample(actual_keys - english_keys))
            placeholder_errors = []
            url_errors = []
            for key in sorted(english_keys & actual_keys):
                source = english[key]
                translated = rows[key]
                if placeholders(source) != placeholders(translated):
                    placeholder_errors.append({
                        'key': key, 'expected': dict(placeholders(source)),
                        'actual': dict(placeholders(translated)),
                    })
                if urls(source) != urls(translated):
                    url_errors.append({
                        'key': key, 'expected': dict(urls(source)),
                        'actual': dict(urls(translated)),
                    })
            for code, problems in [('placeholder_parity', placeholder_errors),
                                   ('url_parity', url_errors)]:
                if problems:
                    error(code, kind=kind, locale=tag, count=len(problems),
                          examples=problems[:5])

    index = load(assets_dir / 'course.index.json')
    counts['course_index'] = len(index) if index is not None else None
    course_english = catalogs['course'].get('en')
    if index is not None:
        if len(index) != EXPECTED_COUNTS['course']:
            error('course_index_count', expected=EXPECTED_COUNTS['course'],
                  actual=len(index))
        ids = set(index.values())
        if len(ids) != len(index):
            error('course_index_id_collision', source_count=len(index),
                  unique_id_count=len(ids))
        bad_hashes = []
        for english, identity in index.items():
            expected = 'course.' + hashlib.sha256(
                english.encode('utf-8')).hexdigest()[:16]
            if identity != expected:
                bad_hashes.append({'english': english, 'expected': expected,
                                   'actual': identity})
        if bad_hashes:
            error('course_source_hash', count=len(bad_hashes),
                  examples=bad_hashes[:5])
        if course_english is not None:
            if ids != set(course_english):
                error('course_index_key_parity',
                      missing_count=len(ids - set(course_english)),
                      extra_count=len(set(course_english) - ids),
                      missing_examples=_sample(ids - set(course_english)),
                      extra_examples=_sample(set(course_english) - ids))
            mismatch = [english for english, identity in index.items()
                        if course_english.get(identity) != english]
            if mismatch:
                error('course_index_english_identity', count=len(mismatch),
                      examples=_sample(mismatch))

    available = (set(catalogs['ui'].get('en', {}))
                 | set(catalogs['catalog'].get('en', {}))
                 | set(index or {}) | PROGRESS_ENGLISH_KEYS)
    inventory_result = {'status': 'UNAVAILABLE'}
    original_inventory_app = ui_inventory.APP
    try:
        # inventory() scans lib only. Its CLI/output-writing branch is not run.
        ui_inventory.APP = app
        bound = ui_inventory.inventory()
        missing = [row for row in bound if row['en'] not in available]
        inventory_result = {
            'status': 'PASS' if not missing else 'FAIL',
            'bound_literal_pairs': len(bound),
            'covered_literal_pairs': len(bound) - len(missing),
            'union_english_keys': len(available),
            'explicit_progress_source_keys': len(PROGRESS_ENGLISH_KEYS),
            'missing_count': len(missing), 'missing': missing,
        }
        if missing:
            error('bound_literal_coverage', missing_count=len(missing))
    except (OSError, UnicodeError, ValueError) as problem:
        error('inventory_unavailable', detail=str(problem))
    finally:
        ui_inventory.APP = original_inventory_app

    try:
        bases = check_bases(app)
        for row in bases:
            if not row['matches_json_values']:
                error('generated_base_parity', **row)
    except (OSError, UnicodeError, ValueError) as problem:
        bases = []
        error('generated_base_unavailable', detail=str(problem))

    return {
        'status': 'PASS' if not errors else 'FAIL',
        'kind': 'STATIC_LOCALIZATION_SOURCE_ASSET_VALIDATION_ONLY',
        'read_only': True,
        'dependencies': 'Python standard library and checked-in app sources only',
        'expected_counts': {
            kind: (expected if expected is not None
                   else len(catalogs[kind]['en'])
                   if 'en' in catalogs[kind] else None)
            for kind, expected in EXPECTED_COUNTS.items()
        },
        'counts': counts,
        'inventory': inventory_result,
        'generated_bases': bases,
        'error_count': len(errors),
        'errors': errors,
        'acceptance_not_established': [
            'Flutter/Dart compilation or widget/layout behavior',
            'Physical device, fonts, RTL rendering or screen-reader behavior',
            'Native-speaker translation or cultural/physical-instruction review',
            'Dynamic/unbound UI text outside the inventory literal patterns',
            'Progress Dart locale-map parity (explicit source keys only here)',
        ],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--app-dir', type=Path, default=APP)
    args = parser.parse_args()
    report = validate(args.app_dir)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
