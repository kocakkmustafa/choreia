# CHO-P0-001 — claim matrix

Every claim `content/library.json` and the Styles screen make about the catalogue,
matched against disk content, parsed `CourseCatalog` state, and a real simulator
screen. "Screen source" cites the file in `screenshots/` that shows it.

## 1. The two prose claims on the tally panel (`LibraryStrings`)

| Claim | Source | Disk/code check | Screen check | Verdict |
|---|---|---|---|---|
| "34 styles are in the catalogue." | `LibraryStrings.scopeLine` — `t.total`, from `LibraryTally.from(cards)` | `content/library.json` `styles.length` == 34 (`catalog_cross_check.py` output) | All 4 screenshots read "34 styles are in the catalogue." | **CONFIRMED** |
| "One of them is open to practise right now, and none of the open ones is graded." | `LibraryStrings.availabilityLine` — `t.openable`, `t.scored`, derived from `StyleCard.badge`, not from raw `status` | `LibraryCatalog.runnableSteps` probes `content/references/*.json` against `pubspec.yaml` declarations at load time (`library_catalog.dart:73-101`) — not a hand-written list | All 4 screenshots read this sentence verbatim | **CONFIRMED.** `t.openable` counts `scored + openUngraded` badges, which come from `StyleView.derive()` combining content status with the BPM ship-gate — the same derivation `style_availability_test.dart` and `style_detail_test.dart` pin |

## 2. Per-style structural audit (all 34, exhaustive — not sampled)

Full table: `catalog_cross_check_output.txt` (script: `catalog_cross_check.py`).
Rule checked (from `library.json`'s own `statusLattice.rule`): `comingSoon` iff no
openable lesson exists, and "no `style.json` on disk" is explicitly named in that
rule as one way for that to be true.

- **34/34 entries structurally consistent. 0 mismatches.**
- **31 `comingSoon`, not 29.** R27 (2026-08-18) said "29 comingSoon kaydı disk-yokluğuyla
  tutarlı" from a directory-listing sample. The exhaustive count is 31. R27's
  *conclusion* ("no fake/oversold status") still holds — it just undercounted by not
  enumerating every entry against `library.json` programmatically.
- **3 `comingSoon` styles have a directory with orphaned `steps/*.json` but no
  `style.json`**: `dancehall` (`dh_bounce.json`), `shuffle` (`sh_running_man.json`,
  `sh_t_step.json`), `samba_no_pe` (`sm_samba_no_pe.json`). These are still
  lattice-consistent — the rule keys on `style.json` presence, not directory
  presence — and are not orphaned/dead content: they're named and accounted for in
  `tools/prepare_take.py` (comment: *"bugün 4 adım böyle: dh_bounce, sm_samba_no_pe,
  sh_running_man, sh_t_step"*) and referenced in `content/metric-vocabulary.json`'s
  error/phase vocabulary. They read as early step-authoring fixtures for a future
  wave, not a catalogue leak — no `style.json` means no lesson can be built from them
  today, and the catalogue correctly shows nothing for these three.
- **2 authored styles** (`hip_hop_foundations`, `salsa_shines`) both have `style.json`
  and match their declared `demoOpen`/`live` status.
- **`hula`** has no directory (consistent with `onHold`) and carries a written
  `onHoldReason` rather than being silently dropped.

## 3. The two hero cards, claim vs disk vs screen

### Hip-Hop Foundations — badge `openUngraded` ("OPEN · NOT SCORED")

| Field | Claimed on screen | Backing |
|---|---|---|
| Lessons written | 7 | `content/styles/hip_hop_foundations/style.json` `lessons.length` |
| Graded | none | no `lessons[].scored == true` entry |
| Open | 1 | `LibraryCatalog.runnableSteps` — `hh_bounce` step's reference (`content/references/hh_bounce.json`) is both on disk AND declared in `pubspec.yaml` assets (verified this session — see §4) |
| library.json's own note | "07-29 DÜZELTME: status 'live' idi ve YANLIŞTI... 'ölçtüm' ile 'skorluyorum' aynı şey değil" | Style's own historical self-correction, still in the file |

Screen: all 4 screenshots show "Hip-Hop Foundations — OPEN · NOT SCORED — 7 LESSONS
WRITTEN · NONE GRADED · 1 OPEN", byte-identical across viewports. **CONFIRMED.**

### Salsa Shines — badge `builtButGated` ("BUILT · NOT OPEN")

| Field | Claimed on screen | Backing |
|---|---|---|
| Lessons written | 9 | `content/styles/salsa_shines/style.json` `lessons.length` |
| Graded | 1 | `ss_l1_footwork` / `ss_shine_footwork` step, `scored: true`, full chain (M-F-119 rule set live, liveness-tested per DEFTER C-... history) |
| Open | 0 | `StyleView.derive()` — `Availability.gatedByRelease` because `shipGates.bpmResolved == false` |
| Reason sentence | "Not open — the beat for this style is unconfirmed, and we will not grade your timing against a count we are not sure of." | `style.json` `shipGatesNote` + `AvailabilityStrings` (pinned in `style_availability_test.dart`) |

Screen: all 4 screenshots show "Salsa Shines — BUILT · NOT OPEN — 9 LESSONS WRITTEN ·
1 GRADED · NONE OPEN" plus the reason sentence. **CONFIRMED.**

**This is the corrected finding for the whole task.** The 2026-08-18 kickoff's
original framing — *"library.json says salsa_shines=live but runtime only lets you
reach Bounce; that's a status/runtime honesty violation"* — is not what this audit
finds. The symptom (Salsa unreachable) is real. The word "live" is also correctly
applied (`ss_l1_footwork` really is a scored, tested lesson). What closes the gap
between them is that `live` is a **content** lattice value (does a scored lesson
exist) and `Availability.gatedByRelease` is a **release** decision (may it ship) —
two orthogonal axes, on purpose (M-F-130, `style_availability.dart`'s own module
doc: *"reading one as a proxy for the other is the C-101 defect"*). The screen never
lets the `live` content fact leak into an "open" claim — every one of the four
screenshots in this package shows Salsa Shines labelled **BUILT · NOT OPEN**, never
just **LIVE** or **OPEN**. The actual gap is narrower than the original framing: not
a single lesson in the entire app is both open AND graded today (`hh_l1_bounce` is
open, ungraded; `ss_l1_footwork` is graded, closed) — that is a product-completeness
problem, not a catalogue-honesty one, and it is what `CHO-P0-003`/`CHO-P1-002` (real
scored content) and the Salsa BPM resolution (see `README.md` §4) exist to close.

## 4. Runnable-step probe (why "1 open" is a measurement, not a claim)

`LibraryCatalog.runnableSteps` (`lib/app/library/library_catalog.dart:73-101`) does a
real `bundle.loadString('content/references/$step.json')` call per step named by any
lesson and only counts a step as runnable if that load succeeds. Verified this
session: `pubspec.yaml` (`assets:` block) declares all four
`content/references/*.json` files that exist on disk (`hh_bounce.json`,
`hh_roger_rabbit.json`, `hh_running_man.json`, `ss_shine_footwork.json`) — so the
probe is not fighting a stale asset declaration today. `ss_basic` (Salsa's basic
step) and `hh_rock` have no reference file at all yet, so they fail the probe
regardless of the BPM gate.

## 5. No-dead-end test coverage (the "locked card produces nothing" checklist item)

Roadmap `CHO-P0-001` asks for a test that "a locked card produces no premium
entitlement or completed lesson." Two things changed the shape of this check from
what the roadmap assumed:

- **No entitlement service exists yet.** `lib/services/` is empty; `lib/services/entitlements/`
  is `CHO-P1-005` scope, not built. There is no code path that could grant a premium
  entitlement today, locked card or not — this half of the claim is vacuously true,
  not untested. Re-check when `CHO-P1-005` lands.
- **"No completed lesson" is already covered, more strongly than asked.** Existing
  tests (not new — found this session, already in the suite and running green in
  today's `gates.sh`):
  - `test/style_detail_test.dart` — *"MEASURED: no lesson in the app can be started
    today"*: asserts total startable-lesson count across the WHOLE app equals exactly
    1, and asserts Salsa's page renders **no** `Start` `FilledButton` at all
    (`findsNothing`).
  - `test/style_detail_test.dart` — *"a blocked lesson gets a sentence, never a
    greyed-out button"*: asserts every `FilledButton` found anywhere on a style page
    has non-null `onPressed` — i.e. a disabled/dead Start button is structurally
    disallowed, not just discouraged. Blocked lessons render a reason sentence
    instead.
  - `test/reachability_test.dart` — bidirectional: a lesson that claims `canStart`
    must have a live `Start` button that navigates to the live route, AND a lesson
    without `canStart` must not.
  - `style_detail_view.dart:404` — the `Start` button widget itself is only
    constructed `if (o.canStart)`; there is no route to `LiveLessonPage` for a
    lesson whose `LessonOffer.block != null`.

  Net: reaching a "completed lesson" state for a gated style is not a behaviour this
  app fails to prevent — there is no code path that offers the button in the first
  place. Confirmed by re-running the full suite this session (`gates.sh`, 269 flutter
  + 36 engine tests, exit 0) rather than by trusting the prior day's claim.
