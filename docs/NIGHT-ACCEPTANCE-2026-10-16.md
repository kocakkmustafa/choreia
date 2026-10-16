# Choreia local software acceptance — 16 October 2026

Baseline: `38c8f3b74a3d72bb7d0981c3182d352c0055681e`, clean canonical
`ventures/choreia/app`, one checkout. The previous three-job CI run
[`38770539370`](https://github.com/kocakkmustafa/choreia/actions/runs/38770539370)
tested exactly the same tree (`28c39f65ce2c612b191ab5976f8fb2b8f0b7c259`).
Its unsigned Android/iOS builds are baseline evidence, not builds of this fix.

## Changes and regression evidence

The four written-course readers could leave the old error and active Retry on
screen while a retry was pending. An immediate second failure could also escape
before FutureBuilder subscribed. Each request is now observed immediately,
without replacing its future, and an error is rendered only for a completed
request. A pending request displays the existing loading indicator.

`test/written_course_retry_test.dart` covers both failures in the Hip-Hop
introduction and skill reader, Line, Latin and Short-form. All ten cases failed
before the production fix. The final tests also check that successful retries
render each actual bundled course title. An intermediate five-case failure was
a test assumption about lazily built ExpansionTiles; its log is retained and
is not accepted as a product failure or a passing run.

## Bounded acceptance checklist

| Area | Evidence | Result and boundary |
|---|---|---|
| Current lesson inventory | Six bundled course JSON files and their runtime decoder tests | Five areas, 86 written units: Hip-Hop introduction 6 + skill candidate 8; Salsa 48; Line 9; Latin 8; Short-form 7. Ten recall activities are separate. Full physical curricula remain open. |
| Written-course navigation | Hip-Hop, Line, Latin and Short-form page tests | Real bundled route access, final written tasks, Back, timeout, replacement and stale responses remain covered. |
| Salsa learning record | Salsa page/progress/criterion/owner-drain/weekly tests | Guest/account/version separation, chosen-option evidence, preparation/lifecycle resets, reopening and weekly summaries pass with test-owned local files. Completion is self-reported. |
| Failed save and recovery | New Salsa page test | A directory at the test journal's `.tmp` path makes the actual file write fail. The previous journal bytes survive, completion stays disabled, and retry after removing only that test directory saves exactly one practice event. Recreated pages read it back. |
| Start/finish and error paths | `first_walk_test.dart`, `end_to_end_test.dart`, permission/lifecycle/fallback tests | Replay-driven lesson start → result → style → library → progress and real journal round-trip pass. Refused camera writes nothing. Replay does not establish camera or movement accuracy. |
| Readable errors | `course_error_layout_test.dart` | EN/TR at 320×568 and 640×320, 2× text: written and Salsa integrity/progress errors remain readable, Retry is reachable when allowed, Back works, and corrupt history is preserved. No production layout change was needed. |
| Analysis and engine | Full `flutter analyze --no-pub`; pure Dart engine suite | No analysis issues; 36 engine cases pass. |

Baseline local focus: **167 passing cases**, zero skips/errors. After the fix:
**97 passing cases** across eight affected acceptance files, zero skips/errors.
The latter includes ten retry regressions, 28 error-screen cases and the actual
Salsa failed-save/recovery path. Counts exclude loading and hidden setup events.
The content validator also passes with the existing unresolved Salsa Shines
beat/BPM warnings; these gates are not promoted.

## Remaining acceptance

No simulator, local Xcode/Gradle build, physical-device probe, store upload,
IAP transaction or paid run was started. LifeOS retains simulator priority.
The existing native `production_main_boot_test.dart` and
`salsa_course_smoke_test.dart` still need a coordinated simulator slot for this
candidate. The latter covers native asset/path-provider/file readback, not
process force-quit/relaunch or physical dance.

Lawful music, accepted demonstration media/trust root, real camera/pose/timing,
learner performance, full curricula, physical suitability and competent teaching
review remain open. No lesson, dose, health/safety claim, shared Motion package,
Core pin, icon, store image, signing setting or build number was changed.

Exact source SHA, command results, content hashes, prior CI readback and raw
test logs are retained outside the checkout at
`../data/night-acceptance-2026-10-16/`. Publication and any later simulator result
must be recorded against their own exact source identity.
