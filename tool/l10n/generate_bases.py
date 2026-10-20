#!/usr/bin/env python3
"""Reproduce/check generated Dart bases without writing application files.

With --emit, print one deterministic source to stdout for a caller to review.
The default check compares literal map values, so Dart formatting is harmless.
This restricted reader accepts only these generated map declarations; it is not
a general Dart parser and does not read the hand-authored Progress dictionary.
"""

import argparse
import json
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
APP = Path(__file__).resolve().parents[2]
UI_SOURCE = Path('lib/app/localization/base_ui_messages.dart')
CATALOG_SOURCE = Path('lib/app/localization/base_catalog_messages.dart')


def _unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f'duplicate JSON key: {key[:120]!r}')
        result[key] = value
    return result


def load_string_map(path):
    value = json.loads(Path(path).read_text(encoding='utf-8'),
                       object_pairs_hook=_unique_object)
    if not isinstance(value, dict) or not value:
        raise ValueError('expected a nonempty JSON object')
    for key, text in value.items():
        if not isinstance(key, str) or not key.strip():
            raise ValueError('expected nonempty string keys')
        if not isinstance(text, str) or not text.strip():
            raise ValueError(f'expected nonempty string value: {key[:120]!r}')
    return value


def expected_values(app=APP):
    app = Path(app)
    assets = app / 'content/l10n'
    return {
        UI_SOURCE: ('baseUiMessages', {
            tag: load_string_map(assets / f'ui.{tag}.json')
            for tag in ('en', 'tr')
        }),
        CATALOG_SOURCE: ('baseCatalogTurkish',
                         load_string_map(assets / 'catalog.tr.json')),
    }


def dart_string(value):
    # JSON's double-quoted escapes are shared by these generated Dart strings.
    # Dollar escaping is additionally required to prevent Dart interpolation.
    return json.dumps(value, ensure_ascii=False).replace('$', r'\$')


def render_sources(app=APP):
    values = expected_values(app)
    ui = ['// Generated from the EN/TR UI translation inputs.',
          'const baseUiMessages = <String, Map<String, String>>{']
    for tag, rows in values[UI_SOURCE][1].items():
        ui.append(f'  {dart_string(tag)}: <String, String>{{')
        ui.extend(f'    {dart_string(key)}: {dart_string(text)},'
                  for key, text in rows.items())
        ui.append('  },')
    ui.append('};')
    catalog = [
        '// Generated from catalog.tr.json; validated against the asset source.',
        'const baseCatalogTurkish = <String, String>{',
    ]
    catalog.extend(f'  {dart_string(key)}: {dart_string(text)},'
                   for key, text in values[CATALOG_SOURCE][1].items())
    catalog.append('};')
    return {UI_SOURCE: '\n'.join(ui) + '\n',
            CATALOG_SOURCE: '\n'.join(catalog) + '\n'}


class _GeneratedMapReader:
    def __init__(self, source):
        self.source = source
        self.position = 0

    def _space(self):
        while self.position < len(self.source):
            if self.source[self.position].isspace():
                self.position += 1
            elif self.source.startswith('//', self.position):
                end = self.source.find('\n', self.position)
                self.position = len(self.source) if end < 0 else end + 1
            else:
                break

    def _take(self, token):
        self._space()
        if not self.source.startswith(token, self.position):
            raise ValueError(f'expected {token!r} at offset {self.position}')
        self.position += len(token)

    def _string(self):
        self._space()
        start = self.position
        self._take('"')
        while self.position < len(self.source):
            char = self.source[self.position]
            if char == '\\':
                self.position += 2
            elif char == '$':
                raise ValueError('unescaped Dart interpolation in generated map')
            elif char == '"':
                self.position += 1
                raw = self.source[start:self.position]
                return json.loads(raw.replace(r'\$', '$'))
            else:
                self.position += 1
        raise ValueError('unterminated generated string')

    def _map(self):
        self._space()
        if self.source.startswith('<', self.position):
            annotation = re.match(
                r'<\s*String\s*,\s*(?:Map\s*<\s*String\s*,\s*String\s*>|String)\s*>',
                self.source[self.position:])
            if not annotation:
                raise ValueError('unsupported generated map type annotation')
            self.position += annotation.end()
        self._take('{')
        result = {}
        self._space()
        while not self.source.startswith('}', self.position):
            key = self._string()
            self._take(':')
            self._space()
            value = (self._string() if self.source.startswith('"', self.position)
                     else self._map())
            if key in result:
                raise ValueError(f'duplicate generated map key: {key[:120]!r}')
            result[key] = value
            self._space()
            if self.source.startswith(',', self.position):
                self.position += 1
                self._space()
            elif not self.source.startswith('}', self.position):
                raise ValueError(f'expected comma at offset {self.position}')
        self._take('}')
        return result

    def read(self, name):
        self._take('const')
        self._take(name)
        self._take('=')
        result = self._map()
        self._take(';')
        self._space()
        if self.position != len(self.source):
            raise ValueError('unexpected content after generated declaration')
        return result


def read_generated_map(source, name):
    return _GeneratedMapReader(source).read(name)


def check_bases(app=APP):
    app = Path(app)
    expected = expected_values(app)
    canonical = render_sources(app)
    results = []
    for path, (name, values) in expected.items():
        try:
            source = (app / path).read_text(encoding='utf-8')
            actual = read_generated_map(source, name)
            results.append({
                'path': str(path),
                'matches_json_values': actual == values,
                'matches_canonical_source': source == canonical[path],
            })
        except (OSError, UnicodeError, ValueError) as error:
            results.append({'path': str(path), 'matches_json_values': False,
                            'error': str(error)})
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--app-dir', type=Path, default=APP)
    parser.add_argument('--emit', choices=('ui', 'catalog'),
                        help='print source to stdout; no file is written')
    args = parser.parse_args()
    try:
        if args.emit:
            path = UI_SOURCE if args.emit == 'ui' else CATALOG_SOURCE
            print(render_sources(args.app_dir)[path], end='')
            return 0
        results = check_bases(args.app_dir)
        passed = all(row['matches_json_values'] for row in results)
        print(json.dumps({'status': 'PASS' if passed else 'FAIL',
                          'read_only': True, 'bases': results},
                         ensure_ascii=False, indent=2))
        return 0 if passed else 1
    except (OSError, UnicodeError, ValueError) as error:
        print(json.dumps({'status': 'FAIL', 'read_only': True,
                          'error': str(error)}, ensure_ascii=False, indent=2))
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
