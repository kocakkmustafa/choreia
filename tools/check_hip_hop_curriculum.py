"""Content contract checks, not teaching or Dart acceptance."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
course = json.loads((root / 'content/hip_hop_foundations_course.json').read_text())
units = course['units']
assert course['schemaVersion'] == course['version'] == 1
assert course['acceptance']['scoring'] is False
assert course['acceptance']['progressWrites'] is False
assert [u['id'] for u in units] == [f'hhf_{n:02d}' for n in range(1, 7)]
fields = ['title', 'prerequisite', 'outcome', 'instruction', 'practice', 'mistakes', 'adaptation', 'check']
for index, unit in enumerate(units):
    for field in fields:
        assert set(unit[field]) == {'en', 'tr'}, (unit['id'], field)
        assert all(isinstance(v, str) and v.strip() for v in unit[field].values())
    assert unit['prerequisiteIds'] == ([] if index == 0 else [units[index - 1]['id']])
for field in ['title', 'reviewNotice', 'boundaries', 'startCompetency', 'endCompetency']:
    assert set(course[field]) == {'en', 'tr'}
assert 'revision' in units[-1]['practice']['en']
assert 'physical mastery' in units[-1]['adaptation']['en']
task = course['finalTaskContract']
assert task['physicalStudies'] == ['bounce', 'side_rock_preparation', 'step_touch']
assert set(task['sides']) == {'right', 'left'}
assert task['externalPulseRequiredForTiming'] and task['transitionsRequired']
assert task['pauseAndReentryRequired'] and task['blocks'] * task['beatsPerBlock'] == 32
assert task['adaptationEstablishesPhysicalMastery'] is False
assert task['completeBeginnerCurriculumAccepted'] is False
source_ids = {entry['id'] for entry in course['provenance']}
for unit in units:
    assert set(unit['instructionalSourceIds']) <= source_ids
    assert 'smithsonian-social' not in unit['instructionalSourceIds']
    assert 'legacy' not in unit['instruction']['en'].lower()
assert 'camera' not in units[2]['instruction']['en'].lower()
assert 'feet-only arms' not in json.dumps(course)
assert all('supports' in source for source in course['provenance'])
assert (root / 'lib/app/course/hip_hop_course_page.dart').is_file()
assert 'content/' in (root / 'pubspec.yaml').read_text()
print('PASS: bilingual content contract, ordered prerequisites, final revision task, provenance, no scoring/progress flags. Not Dart or instructor acceptance.')
