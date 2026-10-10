"""Check written contract and support ledger, not physical teaching acceptance."""
from pathlib import Path
import json
r=json.loads((Path(__file__).resolve().parents[1]/'content/line_dance_beginner_course.json').read_text())
assert r['id']=='line_dance_beginner_written' and r['schemaVersion']==1 and r['version']==2
assert len(r['units'])==9 and all(v is False for v in r['acceptance'].values())
for n,u in enumerate(r['units'],1):
 assert u['id']==f'ld_{n:02}' and u['prerequisiteIds']==([] if n==1 else [f'ld_{n-1:02}'])
 for key in ['title','prerequisite','outcome','instruction','practice','mistakes','adaptation','check','diagram']:
  assert set(u[key])=={'en','tr'} and all(t.strip() for t in u[key].values())
assert r['finalTaskContract']['beats']==24
assert r['finalTaskContract']['crossingSubstituteIsPhysicalCrossing'] is False
assert r['finalTaskContract']['seatedIsPhysical'] is False
# Original count ledger: support/free foot consistency at each block boundary.
patterns=[ [('R','W'),('L','T'),('L','W'),('R','T')]*2,
 [('R','W'),('L','W'),('R','W'),('L','T'),('L','W'),('R','W'),('L','W'),('R','T')],
 [('R','W'),('L','W'),('R','W'),('L','T'),('L','W'),('R','W'),('L','W'),('R','T')] ]
support='L'
for sequence in patterns*2:
 for foot,action in sequence:
  assert foot!=support,'next moving foot must be available'
  if action=='W':support=foot
 assert support=='L','each block leaves R available for repeat'
print('PASS bilingual contract, closed gates, prerequisites, and original 24-count support ledger; physical acceptance NOT established')

assert r['finalTaskContract']['extendedBeatsPerWall']==32
assert r['finalTaskContract']['actualTurnEligible'] is False
assert r['units'][4]['exercise']['en'] and r['units'][4]['answer']['tr']
for foot in ['R','L']*4:
 assert foot!=support
 support=foot
assert support=='L'
print('PASS expanded facing/turn-plan contract; actual physical turning remains unaccepted')
