"""Validate written coverage/gates; this does not approve dance instruction."""
from pathlib import Path
import json
root = Path(__file__).resolve().parents[1]
raw = json.loads((root / 'content/hip_hop_foundations_skill_course.json').read_text())
assert raw['id'] == 'hip_hop_foundations_skill_course'
assert raw['schemaVersion'] == raw['version'] == 1
assert all(v is False for v in raw['acceptance'].values())
units = raw['units']; assert len(units) == 8
sources = {s['id'] for s in raw['sourceRegistry']}
assert len(sources) == len(raw['sourceRegistry'])
for i, unit in enumerate(units, 1):
    assert unit['id'] == f'hhs_{i:02}'
    assert unit['prerequisiteIds'] == ([] if i == 1 else [f'hhs_{i-1:02}'])
    assert set(unit['instructionalSourceIds']) <= sources
    for field in ['title', 'prerequisite', 'outcome', 'instruction', 'practice', 'mistakes', 'adaptation', 'check']:
        assert set(unit[field]) == {'tr', 'en'}
        assert all(isinstance(t, str) and t.strip() for t in unit[field].values())
for field in ['title', 'reviewNotice', 'boundaries', 'startCompetency', 'endCompetency', 'provenance']:
    assert all(raw[field][lang].strip() for lang in ['tr', 'en'])
contract = raw['finalTaskContract']
assert contract['blocks'] == contract['beatsPerBlock'] == 8
assert contract['evidence'] == 'self_observation_only'
for field in ['physicalNamedStepsEligible','adaptationIsSamePhysicalEndpoint','cameraVerification']:
    assert contract[field] is False
assert set(contract['requiredCompetencies']) == {'external_pulse','phrase_entry','grounded_bounce','side_rock','two_sided_weight','step_touch','running_man_selected','roger_rabbit_singles_selected','transitions','recovery','audible_response','error_identification','correction','same_condition_reassessment'}
print('PASS: bilingual written coverage, ordered prerequisites, provenance and closed acceptance gates; physical teaching NOT approved')
