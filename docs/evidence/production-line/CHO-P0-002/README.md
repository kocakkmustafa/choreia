# CHO-P0-002 — Offline, privacy, signing ve CI baseline'ını kapat

**State:** ACCEPTED. **Date:** 2026-08-19. **Owner:** Choreia solo session.
**Reviewer:** none assigned — R0/R1 risk (build tooling, no payment/prod-secret/
migration surface; signing gate touches release infra but produces no signed
artifact and handles no real secret). **Input SHA:** baseline `c5edf98` (before
this task's commit) → see `git-log-baseline.txt`. Common pin unchanged
(`f13bdc93b2eae2f741bfcdb4c9270a88e5d75e5d`).

## What this closes, checklist-by-checklist

| Roadmap item | Status | Where |
|---|---|---|
| Debug signing'i release variant'tan çıkar | ✅ Already done by a **concurrent motion-core session** (`a3eab87`, this same day) — see `../CHO-P0-001/input-bridge-retest.md`-adjacent finding in DEFTER C-317. This task only **extended** it with an opt-in `-PallowDebugSigning` escape hatch (gravita/lissom precedent) so CI/local can actually produce an unsigned release build, which the base JabLab-style pattern structurally could not do. | `android/app/build.gradle.kts`, `test/android_signing_test.dart` |
| Runtime font fetch kaldır, offline cold start | ✅ | `lib/main.dart`, `pubspec.yaml`, `tool/fetch_fonts.sh`, `assets/fonts/` |
| iOS privacy manifest, Info.plist, Android permissions/Data safety | ✅ verified, not rewritten — see below | `docs/store/data-safety-matrix.md` |
| CI: secret scan, dependency audit, analyze, test, content validation, Android release build, unsigned iOS build | ✅ | `.github/workflows/quality.yml`, `tools/secret_scan.py` |
| `bash tool/gates.sh`, `flutter analyze`, `flutter test`, `flutter build appbundle --release`, `flutter build ios --release --no-codesign` | ✅ all run, all green | `gates-sh-output-2026-08-19.txt`, this README §3 |
| Evidence: workflow run URL, build hashes, offline video, permission manifest diff, SBOM | ⚠️ partial — see §4 | `sbom.txt`, screenshots, this README |

## 1. Android signing — what was already there vs. what this task added

`android/app/build.gradle.kts` and `test/android_signing_test.dart` were written and
committed by a **different, concurrently-running session** (confirmed via a live
`.git/index.lock` collision mid-turn, session ID visible in `ps aux` differed from
this session's — full account in `../CHO-P0-001/README.md` and DEFTER C-317). That
version ported JabLab's J-215 pattern **wholesale**: no keystore → hard
`GradleException`, no escape hatch at all.

That's correct for preventing a *silent* debug-signed artifact, but it also means
`flutter build appbundle --release` — which this task's own checklist and the new
CI workflow both need to run **without a real keystore** — would unconditionally
fail. Gravita and Lissom had already solved exactly this tension
(`release_signing_test.dart`, `-PallowDebugSigning` flag: opt-in, loud, never
default). This task ported *that* evolution into Choreia:

- `android/app/build.gradle.kts`: added `allowDebugSigning` project-property check;
  `signingConfig` is now a three-way `when` (real keystore → debug-if-flagged →
  `null`); the noisy-stop gate warns-and-continues under the flag instead of
  throwing.
- `test/android_signing_test.dart`: rewritten from a single negative regex (which
  would have gone stale the moment a legitimate debug-signing branch existed) to
  gravita/lissom's positive-presence + **sabotage** pattern — a twin test that
  truncates the guard out of the source and asserts the detector actually goes red.
- **Verified via real Gradle, not text** (gravita's own hard-learned lesson,
  quoted in its header comment): `JAVA_HOME=…/temurin-17… ./gradlew :app:assembleRelease --dry-run`
  fails with the expected banner when unflagged, and `... -PallowDebugSigning=true --dry-run`
  succeeds with the expected warning. Both captured live this session (see
  transcript; not re-pasted here to avoid a third copy of the same log).

## 2. Fonts — what was measured, not assumed

`google_fonts` was a genuine runtime network dependency (three families:
Instrument Serif, Manrope, IBM Plex Mono, via `GoogleFonts.instrumentSerif/
manrope/ibmPlexMono` and `manropeTextTheme` in `lib/app/theme.dart`). Rather than
guess which weights to bundle:

- A throwaway measurement test (`test/_font_weight_probe_test.dart`, deleted after
  use) printed Flutter's actual Material3 dark `TextTheme` weights — **all `null`**
  (i.e. every role falls back to the font's own default, w400), which is why
  `manropeTextTheme` doesn't pull in extra weights beyond what `body()`'s explicit
  overrides already need.
- Explicit call-site grep found exactly one non-default weight in use:
  `body(weight: FontWeight.w600)`.
- Net: 4 files needed — InstrumentSerif-Regular (w400, the family's only static
  weight), Manrope-Regular (w400), Manrope-SemiBold (w600), IBMPlexMono-Medium
  (w500, `label()`'s hardcoded weight).
- Hashes are not invented: they're read directly from the installed
  `google_fonts` 6.3.3 package's own generated source
  (`google_fonts_parts/part_{i,m}.g.dart`), which is the exact SHA-256 the package
  would itself fetch from `fonts.gstatic.com` at runtime. `tool/fetch_fonts.sh`
  moves that same download to build time; files are `.gitignore`d (not committed,
  same pattern as `assets/models/*.task`).
- `main.dart` sets `GoogleFonts.config.allowRuntimeFetching = false` — a missing or
  mis-bundled weight now fails LOUDLY (an exception at first use) instead of
  silently phoning home, which is the failure direction this whole codebase
  prefers.

**Offline proof:** `flutter analyze` (0 issues) + full `flutter test` (272/272,
including the new signing tests) with fetching disabled — if any glyph needed a
weight that wasn't bundled, the suite would have failed loudly, not passed by
accident. On top of that: a genuine fresh install (uninstall + rebuild + reinstall,
`screenshots/offline-cold-start-bundled-fonts.png`) on `choreia-hatti`, showing the
onboarding screen rendering all three custom faces correctly (the Instrument Serif
display title, Manrope body copy, IBM Plex Mono labels are visually distinct from
system fonts). A literal network-severed run was not additionally performed: with
`allowRuntimeFetching = false` the code path structurally cannot attempt a fetch
regardless of connectivity, so connectivity state doesn't change what's being
proven here.

## 3. Privacy/permission surfaces — verified, not rewritten

Measured this session, matching CHO-P0-001's discipline of checking before fixing:

- `ios/Runner/PrivacyInfo.xcprivacy` — **already correct**, already measured, already
  gated (`tools/privacy_manifest_check.py`, C-266/A8, passes in every `gates.sh`
  run including this one). `NSPrivacyTracking: false`, `NSPrivacyCollectedDataTypes: []`
  — both true today: no analytics/tracking SDK in the dependency tree, no writes
  from `SessionStore` (read-only).
- `ios/Runner/Info.plist` — carries `NSCameraUsageDescription` matching the app's
  actual camera-only behavior; no microphone string, because `lib/` has zero
  microphone/audio-recording references today (grepped this session) — adding an
  unused permission string would itself be a false claim.
- `android/app/src/main/AndroidManifest.xml` — `CAMERA` permission +
  `android.hardware.camera` optional feature, matching actual behavior; same
  absence-of-microphone reasoning.
- **New:** `docs/store/data-safety-matrix.md` — the roadmap's "Android permissions/
  Data safety matrisi" didn't exist as a document anywhere in the repo (verified —
  no sibling Motion app had one either; LifeOS's was used as a *format* reference
  only, different app class). Written from the measured baseline above: no
  account, no backend, no analytics, nothing collected. Documents explicitly when
  it goes stale (CHO-P1-003 mic, CHO-P1-004 local storage).

No `Info.plist`/`AndroidManifest.xml`/`PrivacyInfo.xcprivacy` diff exists in this
task's commit — they were already accurate. The "permission manifest diff"
evidence item the roadmap asks for is, honestly, empty; that emptiness is the
finding.

## 4. Build verification — real commands, real artifacts

All run this session, in this order (sequential, not parallel — the machine is
under heavy concurrent-session load today and parallel builds would only have
slowed each other down):

```
bash tool/gates.sh
  → 272 flutter tests (269 + 3 new signing tests) + 36 engine tests +
    26 self-tests/validators (25 prior + secret_scan), 0 red, exit 0

flutter build appbundle --release -PallowDebugSigning=true
  → build/app/outputs/bundle/release/app-release.aab, 75.7 MB
  → sha256 48a1d57de075ca2c0555839f38f608bb289fece702a6e37ba2a14e35d0d402d6

flutter build ios --release --no-codesign
  → build/ios/iphoneos/Runner.app, 46.0 MB (zipped for hashing: 21.7 MB)
  → sha256 (of the zipped .app) 46454e5caec80e46ca7d8d145ee4fb799740fe3b933e37e80ba1efe5a86bc3d2
```

Full `gates.sh` transcript: `gates-sh-output-2026-08-19.txt`.
Baseline commit this task started from: `git-log-baseline.txt`.
Dependency list (64 packages, direct+transitive, name/version/source):
`sbom.txt` (`flutter pub deps --json`, no third-party SBOM tool available offline
for Dart — this is the SDK's own dependency resolution report, which is what an
SBOM needs at minimum: what's in the tree and where it came from).

**Not produced:** a GitHub Actions workflow run URL. `.github/workflows/quality.yml`
is new this session and has not run on GitHub yet — it only runs after this
commit is pushed and GitHub picks it up. The workflow's first real run (and
whether `MOTION_CORE_RO_TOKEN` needs to be added as a repo secret for the
private motion-core checkout step to activate) is the natural next-session
follow-up, not fabricated here.

## 5. What's still open (not this task's scope)

- First real CI run of `quality.yml` on GitHub, and adding `MOTION_CORE_RO_TOKEN`
  if the private motion-core checkout step needs it (graceful no-secret
  degradation was built in, matching gravita/lissom).
- Real device (not simulator) offline/signing verification — `CHO-DEVICE-001`,
  `EXTERNAL_GATE`, unaffected by this task.
- Actual release signing (real keystore, `~/.secrets/yula/`) — founder-only,
  `Founder Day CHO-FD3` per roadmap §14.
