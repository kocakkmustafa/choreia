# Salsa On1 course implementation plan

**Goal:** deliver 48 complete TR/EN solo lessons in eight ordered modules, with an offline player, local account-scoped progress and briefs for the later AI media pass.

**Architecture:** a validated JSON course is separate from the existing camera style catalogue. Instruction does not require a reference or camera permission. New course pages reuse Choreia theme components. A small serialized JSON event journal records viewed/practised/self-reported-complete events with content version and owner; no sensor evidence is generated. Existing account deletion and account discovery include this journal.

**Tech stack:** Flutter/Dart, existing asset bundle and path provider, existing theme and account listenable. No packages, shared Core changes, model download or media generation.

## Content and user flow

Eight modules: start/count/basic; basic vocabulary; control; turns; shines; rhythmic variation; musical choice; independent solo consolidation. Each has six lessons and a practical final task. Each lesson includes TR/EN purpose, sequential teaching, original practice, self-check, repeat advice, optional adaptation, general stop advice, source references and an AI brief. IDs and prerequisites are stable. All assessment modes are self-check while model validation is unavailable.

Open the course from the Styles page or Progress tab. The overview shows real completion counts, modules, recommended next lesson and journal history. A lesson shows the teaching steps and a silent eight-count practice guide; it does not claim that these visual pulses are verified music. The user can pause at any time. Completion requires an explicit self-check acknowledgement. The UI labels it as self-reported; it is never presented as certified intermediate skill.

General adaptations include smaller movement, slower counted practice, turn-free alternatives and seated rhythm learning. They are optional learning choices, not clinical clearance. Stop for pain, dizziness or feeling unwell and seek appropriate medical advice; specific circumstances such as pregnancy are referred to general NHS guidance. Seated rhythm completion does not imply standing footwork proficiency.

## Tasks

- [x] Create `content/salsa_on1_course.json` with all 48 authored bilingual lessons, source metadata and individual AI briefs.
- [x] Add `lib/app/course/salsa_course.dart`: parse/validate schema, local IDs, source references, prerequisites and terminal reachability; reject unsupported camera-scored modes.
- [x] Add `lib/app/course/salsa_progress.dart`: append validated events through atomic file replacement, reread on opening, preserve content version, serialize writes and coordinate account deletion.
- [x] Add `lib/app/course/salsa_course_page.dart`: overview, lesson reading/practice/check flow and history; protect against stale account changes and failed writes.
- [x] Add course entry cards to Styles and Progress using the current three-tab shell. Connect account discovery/deletion to the new store without migrating guest data.
- [x] Add contract tests for all content, malformed/prerequisite cases, replayed persistence, repeated sessions, isolation/deletion and stale accounts. Add a widget walk from course entry through saved self-check and reopening.
- [x] Add `tool/export_salsa_media_briefs.dart` to emit the entire later AI production packet, not generate assets. Include no medical correctness or licensed music assumptions.
- [x] Run targeted tests during implementation, then the complete Flutter suite and analyzer. Keep the model evaluator report unavailable, and record physical-device/media acceptance as outstanding.

## Boundaries

The same authorized app checkout remains the sole writer. `.github/workflows/quality.yml` and `tool/fetch_pose_model.sh` are pre-existing WIP. No commit, push, provider, signing, store, Vault, simulator or shared-package action belongs to this phase. Original AI demonstrations and real-device acceptance remain separate later work.

## Content map

| Module | Lessons | Focus |
|---|---|---|
| Starting with eight counts | 01–06 | Culture, space/warm-up, pulse, in-place support changes, forward/back basic, first attempt |
| A vocabulary of basics | 07–12 | Side/back/diagonal basics, transitions, step size, original 32-count sequence |
| Comfortable control | 13–18 | Touch versus step, relaxed torso/arms, placement, reduced visual guidance, review |
| Direction and turns | 19–24 | Quarter/half changes, right/left stepping turns, return to basic, original combination |
| Solo shines | 25–30 | Crossover touch, side-and-cross, simplified Suzy Q, jazz-square path, touches, combination |
| Rhythmic variety | 31–36 | Subdivisions, double touches, original syncopation, accents, return to basic, accompaniment |
| Making musical choices | 37–42 | Phrase observations, listening layers, expression, call/response, own sequence, freestyle |
| Independent solo practice | 43–48 | Integration, optional pace changes, recovery, social consent, longer practice, next plan |

The stepping turns are progressive introductory variations, not a claim to teach a fast pivot/spin from text alone. The jazz-square exploration explicitly uses a different four-step rhythm and teaches a stopped return to the On1 basic. Personal choices and adaptations remain visible in practice history. The course does not certify a measured “solid intermediate” level.

## Data contract and privacy

- Runtime contract: `lib/app/course/salsa_course.dart`; documentation schema: `docs/schema/salsa-on1-course.schema.json` (local URN, not a published endpoint). The schema JSON was inspected; no external JSON Schema validator was installed. The actual runtime contract is exercised by the content tests.
- Stable course `salsa_on1_solo`, content version `1`, lessons `so_01`–`so_48`; 8 modules, 6 lessons each. Prerequisites are recommended and form an ordered connected path. All lessons can be revisited.
- Canonical files: `course-choreia-guest.json` or `course-choreia-<lowercase-account-uuid>.json`, plus only the atomic-write `.tmp` sibling. The file envelope records schema, owner and typed events. No health condition, freeform diagnosis, audio or camera image is collected by this feature.
- Only `viewed` (shown as opened), `practised` and `selfReportedComplete` exist. Completion requires a practice report for the same lesson/version/option; the UI also requires the learner to acknowledge each self-check. No timer or opening action awards completion.
- A per-file queue serializes concurrent writes. Deletion advances the store generation so an already-open lesson cannot resurrect cleared account data. Owner discovery and deletion use regular canonical files only, including crash-left `.tmp`; guest and other accounts remain isolated.
- Prior content versions are retained but excluded from current totals. Corrupt/foreign-owner/future-schema data shows a retry error and is never replaced with a made-up empty history. No guest migration, cloud sync or clinical record is implied.

## Acceptance evidence (local, 2026-09-26)

- **335 Flutter tests passed**, including model gate, full original suite and new course tests. **Analyzer: no issues**. Legacy content validator: **OK**, with existing Salsa null-beat/unresolved-BPM warnings preserved. Earlier engine phase: **36 tests passed**.
- New content tests cover all 48 bilingual lessons and unique goals/drills, ordered prerequisites, broken source/language/ID rejection, unsupported scoring/music/media flags and distinct 48 media briefs.
- Store tests cover persistent reread, repeat attempts, options, completion prerequisites, concurrent writers, guest/account isolation, content version separation, deletion races, malformed data, symlinks and tmp-only reconciliation.
- Widget walk opens the actual course entry, saves a rhythm-only self-check, recreates the page and reads back `1 / 48`; account switching blocks stale writes; Turkish content scrolls at **375×812 and 200% text scale**. These are widget tests with the repository bundle and real local files, not device-camera or shipped-font acceptance.
- Course entries use the existing Styles and Progress tabs. Progress entry scrolls with the rest of its page, avoiding a fixed-height nested region at larger text sizes. Routes are named; the existing reachability audit points to the additional full course walk.

Reproduce:

```sh
flutter test --no-pub
flutter analyze --no-pub
dart run tool/evaluate_salsa_gate.dart # expected exit 2 until independent evidence exists
dart run tool/export_salsa_media_briefs.dart
```

Artifacts: `/Users/mustafakaankocak/Developer/YULAlab-AI/scratch/2026-09-26-motion-courses/choreia/` contains `flutter-tests.log`, `flutter-analyze.log`, `legacy-content-validation.log`, `salsa-evaluation.json` and `salsa-media-briefs.json`. The media packet contains 48 planned original silent demonstrations/diagrams with TR/EN text, view/orientation instructions, alternatives, source-reading references and required human review. **No media assets were generated.**

## Remaining acceptance

The later bulk AI pass must inspect each generated step/count/contact sequence, anatomy, mirrored labels, captions and crop with human dance review before publication. Real-device iOS/Android navigation, fonts, persistence and accessibility remain coordinator-owned acceptance. Licensed music, verified beat clocks and independent participant holdout evidence do not exist in this phase; automatic camera mastery/score stays disabled. No release, signing, store, provider, shared Core or Vault action was taken.


## Root final readback

so_21 turn counts now preserve1-2-3/5-6-7 without added4/8steps; so_32
labels its original four-count touch-touch-step drill and restores the
left-ready starting support. Teaching and mediaSequence match. Final
content SHA-256:
`da99598f459e4d6f0bf2e58aa03274b44826e818ee6f1b4effaf8ebe5a121fd1`.
The root reran the full335tests on that content: all passed.

iPhone iOS27 simulator native smoke passed: actual rootBundle and
path-provider, ephemeral UUID directory, first lesson adapted practice
and self-completion, exact JSON owner/event readback, fresh UI/store
re-entry1/48, clear and exact directory teardown. No camera or provider
auth started. This is native local flow proof, not dance or force-quit
acceptance. Log: `scratch/2026-09-26-motion-courses/choreia/ios-native-final.log`.
