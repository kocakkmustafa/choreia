# Salsa On1 offline model gate — design and implementation plan

**Goal:** reproduce the existing Salsa diagnostic behavior offline and prevent it from becoming a learner score without accepted independent evidence.

**Architecture:** preserve `DanceJudge` as a diagnostic candidate. Add a pure Dart evidence gate consumed by the live session and by an offline evaluator. The evaluator uses existing derived angle fixtures and controlled transformations, reports provenance and hashes, and fails closed. No new training data, model weights, downloads, audio, or demonstration assets are produced.

**Tech stack:** existing Dart engine, Flutter replay tests, JSON content, `crypto` already present in the app development dependencies.

Authority: `holding/plans/MOTION-FIVE-COURSES-DESIGN-2026-09-26.md` and the delegated model-first phase. Salsa On1 is chosen for solo pedagogy and product fit, not as a proven worldwide popularity winner. Founder authorization covers implementation here; commits, pushes and shared packages remain outside this phase.

## Evidence and label contract

The existing `ss_shine_footwork` reference is provisional. Its two in-vocabulary fixtures are derived from the reference's own source pool. They are regression inputs, not a held-out population. Their source video IDs do not establish a current commercial training license. Existing numeric fixtures may be inspected for regression; no source footage is fetched, trained on, repackaged or licensed by this work.

On1 label convention: eight musical pulses, primary foot-change events on 1, 2, 3, 5, 6, 7; 4 and 8 are not required new primary steps, not whole-body freezes. Store anatomical left/right separately from mirrored presentation. A reference phase bin is not a beat annotation. Existing angle fixtures have no independently verified beat labels; the report must keep beat timing unassessed.

Future recordings need labels for step identity and named variation, anatomical starting foot, step events/counts, direction, visible/occluded joints, camera orientation, timestamps and clock domain. Human labeling must distinguish observed foot motion from inferred body-weight transfer. Two raters and an adjudication record are needed before camera judgments are considered. Keep participants and source recordings separate between calibration and holdout; transformed copies remain in their original split.

Camera setup: one adult, full body and both feet in frame, stationary phone near waist/torso height, clear level floor and even lighting. Frontal view supports initial lateral footwork; front/back steps and turns need separately tested views. Known mirrored display is normalized once. Unsupported angle, absent feet, low confidence or unknown camera/audio clock relationship yields no verdict. No pixel-derived force, pressure, pain, injury-risk or clinical suitability claim is permitted.

## Evaluation cases

1. Existing sided Salsa fixture: candidate diagnostic behavior, not holdout accuracy.
2. Its anatomically mirrored cycle: controlled wrong-foot case.
3. Double mirror: presentation normalization must recover the original cycle.
4. Freeze at one phase and small periodic sway: synthetic distractors, not labeled dancers.
5. Existing out-of-vocabulary Hip-Hop cycles: known counterexamples from the repository, not independent validation.
6. Missing leg joint, partial cycle and non-finite coordinates: no complete measurements or verdict.
7. Live frame replay with invisible feet/whole body and visible sway: no learner judgment; unknown frames must not become poor performance.

The evaluator returns per-case raw candidate findings, accepted learner verdict count, gate reasons, content/fixture SHA-256, and explicit evidence limitations. Its `assessmentAccuracy` is null: no independent labeled holdout exists. Exit 2 means assessment unavailable, exit 1 means malformed inputs or broken regression, not a skipped successful release check.

## Implementation tasks

- [x] Add `packages/choreia_engine/lib/src/assessment_gate.dart` and export it. `DanceAssessmentGate.forReference(reference)` records missing accepted calibration plus actual reference weaknesses; content flags cannot mint an accepted evaluation. `cycleIssues` validates every required leg series before diagnostics.
- [x] Add `test/salsa_model_gate_test.dart`: load real numeric fixtures, exercise wrong-foot/mirror/sway/occlusion cases and assert no approved learner findings. Verify the sided diagnostic still distinguishes the deliberate wrong-foot transformation; do not disguise disabled diagnostics as improved recognition.
- [x] Add `tool/evaluate_salsa_gate.dart`: read inputs from the repository, call the same gate and diagnostic evaluator, emit deterministic JSON and exit 2 while evidence is absent. Invocation: `dart run tool/evaluate_salsa_gate.dart`.
- [x] Change `LiveSession.isScored` to require the evidence gate, expose a plain-language validation reason, and retain measurement-only live states. Clear its pending cycle when an unjudgeable frame interrupts observation; separated fragments must not fabricate a complete cycle.
- [x] Change `SessionTally` so a scored request produces a scored journal class only after an actual `LiveJudged` state and no measurement-only fallback. Add persistence regression coverage.
- [x] Run `flutter test --no-pub test/salsa_model_gate_test.dart test/live_path_test.dart test/session_tally_test.dart`, engine diagnostic tests, and `flutter analyze --no-pub`. Write evaluator output to workspace scratch, inspect exit code and report. Review the complete diff and preserve the two pre-existing WIP files.

## Source basis and next phase

- [Library of Dance: Salsa Shines](https://www.libraryofdance.org/dances/salsa-shines/) supports a substantial solo vocabulary within Salsa.
- [Google Pose Landmarker](https://developers.google.com/edge/mediapipe/solutions/vision/pose_landmarker) describes approximate landmarks, not clinical measurements.
- [IADMS motor learning](https://iadms.org/media/dtvep123/iadms-resource-paper-motor-learning-and-teaching-dance.pdf) supports observation, execution, feedback and repetition; only indexed excerpts were available during research.
- [CDC adaptations](https://www.cdc.gov/physical-activity-basics/guidelines/chronic-health-conditions-and-disabilities.html) and [NHS pregnancy exercise](https://www.nhs.uk/pregnancy/keeping-well/exercise/) inform general options and stop guidance, not a personalized prescription.

The course-player phase was subsequently implemented in this same authorized app checkout: 48 TR/EN lessons in eight modules, teaching accessible without camera, authored small-step/no-turn/short-session options, distinct self-reported and camera-observed progress, and account-specific deletion. AI demonstration assets will be created in the later bulk pass. No threshold or mastery badge is inferred from this regression report.

## Verification receipt

- Existing fixture replay and gate/live/tally tests: 25 passed in the focused model phase. Engine diagnostics: 36 passed in that phase; engine source did not change during course-player work.
- Final whole-app Flutter suite after the course integration: **335 passed**. `flutter analyze --no-pub`: no issues. `git diff --check`: clean.
- `dart run tool/evaluate_salsa_gate.dart` emits 12 regression cases and exits **2**, deliberately unavailable. `assessmentReady=false`; accepted learner verdicts remain zero; independent holdout participants/clips and physical devices are zero. The declared pose-model pin is reported but its binary was not evaluated.
- Raw diagnostics on frozen/sway and the existing different-step cycles can have no findings. This exposes an existing recognition limitation; it is not evidence those movements are correct Salsa. Missing/non-finite/partial joints are rejected before diagnostic averaging.
- Report: `/Users/mustafakaankocak/Developer/YULAlab-AI/scratch/2026-09-26-motion-courses/choreia/salsa-evaluation.json`.
- No source media downloaded, no training, no new weights and no cleanup needed. No simulator/device acceptance is implied.
