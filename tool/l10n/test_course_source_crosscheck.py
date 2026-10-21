#!/usr/bin/env python3
"""Synthetic local fault controls; no app copy or SDK operation.

Before application, pass --validator CANDIDATE --helpers APP/tool/l10n.
After root applies the reviewed patch, this can live beside validate_catalogs.py
and run with the defaults. Every write is disposable synthetic fixture data.
Generated-base and literal-inventory branches are mocked because these tests
target source/index/overlay linkage, not the pre-existing base/UI scanners.
"""

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
options = argparse.ArgumentParser(add_help=False)
options.add_argument('--validator', type=Path, default=HERE / 'validate_catalogs.py')
options.add_argument('--helpers', type=Path, default=HERE)
selection, unittest_args = options.parse_known_args()
sys.path.insert(0, str(selection.helpers.resolve()))
spec = importlib.util.spec_from_file_location(
    'choreia_validator_crosscheck_under_test', selection.validator.resolve())
if spec is None or spec.loader is None:
    raise RuntimeError('Selected validator source cannot be loaded')
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


def pair(english):
    return {'en': english, 'tr': f'TR {english}'}


class CourseSourceCrosscheckTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='choreia-source-link-')
        self.addCleanup(temporary.cleanup)
        self.app = Path(temporary.name)
        self.content = self.app / 'content'
        self.assets = self.content / 'l10n'
        self.assets.mkdir(parents=True)
        self.addCleanup(patch.stopall)
        patch.object(gate.ui_inventory, 'inventory', return_value=[]).start()
        patch.object(gate, 'check_bases', return_value=[]).start()
        for name, identity, collection, count in gate.COURSE_SOURCES:
            fields = (gate._SALSA_TEXT_FIELDS if collection == 'lessons'
                      else gate._UNIT_TEXT_FIELDS)
            units = []
            for index in range(count):
                unit = {'id': f'{identity}_{index + 1:02}'}
                for field in fields:
                    english = f'{identity}/{index + 1}/{field}'
                    if collection == 'lessons' and field in ('teaching', 'selfCheck'):
                        unit[field] = {
                            'en': [f'{english}/{line}' for line in range(3)],
                            'tr': [f'TR {english}/{line}' for line in range(3)],
                        }
                    else:
                        unit[field] = pair(english)
                if name == 'line_dance_beginner_course.json':
                    unit['diagram'] = pair(f'{identity}/{index + 1}/diagram')
                units.append(unit)
            self.write(self.content / name, {
                'schemaVersion': 1, 'id': identity,
                'title': pair(f'Title {identity}'), collection: units,
            })
        self.rebuild_course_overlays()
        catalog = {f'Catalog synthetic {index}': f'Catalog synthetic {index}'
                   for index in range(430)}
        for tag in gate.LOCALES:
            self.write(self.assets / f'ui.{tag}.json', {'Fixture UI': 'Fixture UI'})
            self.write(self.assets / f'catalog.{tag}.json', catalog)

    @staticmethod
    def write(path, value):
        path.write_text(json.dumps(value, ensure_ascii=False) + '\n', encoding='utf-8')

    def source(self, index=0):
        path = self.content / gate.COURSE_SOURCES[index][0]
        return path, json.loads(path.read_text(encoding='utf-8'))

    def rebuild_course_overlays(self):
        source, _, errors = gate.harvest_course_sources(self.app)
        self.assertEqual(errors, [])
        index = {english: 'course.' + hashlib.sha256(english.encode()).hexdigest()[:16]
                 for english in source}
        self.write(self.assets / 'course.index.json', index)
        for tag in gate.LOCALES:
            rows = {identity: english if tag == 'en' else
                    source[english] if tag == 'tr' else f'{tag}: {english}'
                    for english, identity in index.items()}
            self.write(self.assets / f'course.{tag}.json', rows)

    def validate(self):
        return gate.validate(self.app)

    def reject(self, expected_code):
        result = self.validate()
        self.assertEqual(result['status'], 'FAIL')
        self.assertIn(expected_code, {row['code'] for row in result['errors']})
        return result

    def test_six_source_ninety_four_units_are_the_count_authority(self):
        result = self.validate()
        self.assertEqual(result['status'], 'PASS', result['errors'])
        self.assertEqual(result['course_sources']['total_units'], 94)
        self.assertEqual(len(result['course_sources']['files']), 6)
        self.assertEqual(result['expected_counts']['course'],
                         result['course_sources']['unique_english'])
        self.assertFalse(result['course_sources']['identifiers_count_as_messages'])

    def test_changed_english_with_old_index_and_all_old_assets_fails(self):
        path, value = self.source()
        value['units'][0]['instruction']['en'] += ' corrected'
        self.write(path, value)
        self.reject('course_source_index_parity')

    def test_turkish_source_and_sidecar_mismatch_fails(self):
        path, value = self.source()
        value['units'][0]['instruction']['tr'] += ' düzeltme'
        self.write(path, value)
        self.reject('course_source_turkish_identity')

    def test_same_english_cannot_select_two_different_turkish_meanings(self):
        _, first = self.source()
        path, second = self.source(1)
        second['title']['en'] = first['title']['en']
        self.write(path, second)
        self.reject('course_source_translation_conflict')

    def test_missing_one_course_does_not_redefine_the_catalog_as_complete(self):
        self.source()[0].unlink()
        result = self.reject('course_source_unavailable')
        self.assertIsNone(result['expected_counts']['course'])

    def test_missing_all_sources_cannot_pass_with_zero_expected_keys(self):
        for name, *_ in gate.COURSE_SOURCES:
            (self.content / name).unlink()
        result = self.reject('course_source_empty')
        self.assertEqual(result['course_sources']['total_units'], 0)
        self.assertIsNone(result['expected_counts']['course'])

    def test_dropping_key_from_index_and_every_overlay_still_fails(self):
        index_path = self.assets / 'course.index.json'
        index = json.loads(index_path.read_text())
        english = next(iter(index))
        identity = index.pop(english)
        self.write(index_path, index)
        for tag in gate.LOCALES:
            path = self.assets / f'course.{tag}.json'
            rows = json.loads(path.read_text())
            rows.pop(identity)
            self.write(path, rows)
        self.reject('course_source_locale_key_parity')

    def test_missing_one_locale_key_fails(self):
        path = self.assets / 'course.ar.json'
        rows = json.loads(path.read_text())
        rows.pop(next(iter(rows)))
        self.write(path, rows)
        self.reject('course_source_locale_key_parity')

    def test_empty_locale_value_fails(self):
        path = self.assets / 'course.hi.json'
        rows = json.loads(path.read_text())
        rows[next(iter(rows))] = '  '
        self.write(path, rows)
        self.reject('invalid_asset')

    def test_missing_unit_is_not_a_valid_lower_unique_count(self):
        path, value = self.source()
        value['units'].pop()
        self.write(path, value)
        self.reject('course_source_unit_count')

    def test_missing_source_translation_cannot_disappear_from_inventory(self):
        path, value = self.source()
        value['units'][0]['instruction'].pop('tr')
        self.write(path, value)
        self.reject('course_source_pair_shape')

    def test_empty_required_pair_cannot_disappear_from_inventory(self):
        path, value = self.source()
        value['units'][0]['instruction'] = {}
        self.write(path, value)
        self.reject('course_source_unit_text_field')

    def test_different_line_counts_fail_instead_of_truncating_zip(self):
        path, value = self.source(5)
        value['lessons'][0]['teaching']['tr'].pop()
        self.write(path, value)
        self.reject('course_source_pair_shape')

    def test_duplicate_source_json_keys_are_rejected(self):
        path, _ = self.source()
        path.write_text('{"id":"a","id":"b"}', encoding='utf-8')
        self.reject('course_source_unavailable')

    def test_new_pair_with_all_overlays_moves_dynamic_count_legitimately(self):
        previous = self.validate()['expected_counts']['course']
        path, value = self.source()
        value['authoredRevisionNote'] = pair('A genuinely new source message')
        self.write(path, value)
        self.rebuild_course_overlays()
        result = self.validate()
        self.assertEqual(result['status'], 'PASS', result['errors'])
        self.assertEqual(result['expected_counts']['course'], previous + 1)

    def test_identical_pair_duplicates_are_deduplicated_without_losing_occurrences(self):
        previous = self.validate()['course_sources']
        path, value = self.source()
        value['authoredRevisionNote'] = dict(value['title'])
        self.write(path, value)
        result = self.validate()
        self.assertEqual(result['status'], 'PASS', result['errors'])
        self.assertEqual(result['course_sources']['unique_english'], previous['unique_english'])
        self.assertEqual(result['course_sources']['pair_occurrences'], previous['pair_occurrences'] + 1)


if __name__ == '__main__':
    unittest.main(argv=[sys.argv[0], *unittest_args])
