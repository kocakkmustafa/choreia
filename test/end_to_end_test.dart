import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course_catalog.dart';
import 'package:choreia/app/progress_summary.dart';
import 'package:choreia/app/progress_view.dart';
import 'package:choreia/app/recorded_summary.dart';
import 'package:choreia/app/style_availability.dart';
import 'package:choreia_engine/choreia_engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_core/motion_core.dart';

/// END TO END: real reference → real judge → recorded session → surface.
///
/// **Replay is not a convenience here, it is the only verification path.** There
/// is no camera bridge in the family, so a fixture recorded from real footage is
/// the closest thing to a learner this project has. Everything in this file runs
/// against material on disk: the built reference artifact, the authored content,
/// and one canonical cycle exported from a take that is itself one of the
/// reference's sources.
///
/// **Versioned on purpose.** The fixture carries its provenance and this test
/// ASSERTS it. If the reference is rebuilt, the core pin moves, or the fixture
/// is regenerated from different material, the chain being verified is no longer
/// the chain that was verified — and a silent pass would be a lie about what was
/// checked. The pins below are the "what did we actually replay" record.
void main() {
  final Directory repo = Directory.current;
  final File refFile =
      File('${repo.path}/content/references/ss_shine_footwork.json');
  // TWO fixtures on purpose: one whose side call is confident, one whose is
  // not. The contract has two halves and a single fixture can only nail one.
  final File fixtureFile =
      File('${repo.path}/test/fixtures/replay_ss_shine_cycle.json');
  final File sidedFixtureFile =
      File('${repo.path}/test/fixtures/replay_ss_shine_cycle_sided.json');

  late DanceReference reference;
  late Cycle replayCycle;
  late Map<String, dynamic> provenance;
  late Cycle sidedCycle;
  late Map<String, dynamic> sidedProvenance;
  // Moment bins are READ from the step config, never hardcoded here: a copy of
  // a threshold in a test is a second source of truth that drifts silently and
  // then asserts the old contract (M-F-03).
  late int momentA;
  late int momentB;

  setUpAll(() {
    reference = DanceReference.load(refFile);
    final Map<String, dynamic> fx =
        (jsonDecode(fixtureFile.readAsStringSync()) as Map)
            .cast<String, dynamic>();
    provenance = (fx['provenance'] as Map).cast<String, dynamic>();
    final Map<String, dynamic> step = (jsonDecode(File(
                '${repo.path}/content/styles/salsa_shines/steps/'
                'ss_shine_footwork.json')
            .readAsStringSync()) as Map)
        .cast<String, dynamic>();
    final Map<String, int> bins = <String, int>{
      for (final Object? p in (step['phases'] as List))
        (p as Map)['id'] as String:
            ((p['enter'] as Map)['phaseBin'] as num).toInt(),
    };
    momentA = bins['settle_a']!;
    momentB = bins['settle_b']!;

    Cycle readCycle(Map<String, dynamic> doc) => <String, List<double>>{
          for (final MapEntry<String, dynamic> e
              in (doc['cycle'] as Map).cast<String, dynamic>().entries)
            e.key: (e.value as List)
                .map((Object? v) =>
                    v == null ? double.nan : (v as num).toDouble())
                .toList(growable: false),
        };
    replayCycle = readCycle(fx);

    final Map<String, dynamic> sfx =
        (jsonDecode(sidedFixtureFile.readAsStringSync()) as Map)
            .cast<String, dynamic>();
    sidedProvenance = (sfx['provenance'] as Map).cast<String, dynamic>();
    sidedCycle = readCycle(sfx);
  });

  group('what we actually replayed (version pins)', () {
    test('the fixture and the reference describe the SAME step and axis', () {
      expect(provenance['step'], reference.step);
      expect(provenance['phaseBins'], reference.phaseBins,
          reason: 'a cycle sampled on a different phase axis than the '
              'reference cannot be compared bin to bin — it would score the '
              'learner against the wrong moment');
    });

    test('the replayed material is NAMED, not anonymous', () {
      expect(provenance['videoId'], 'SHGkSbJm2Iw');
      expect(provenance['corePin'], isNotNull);
      expect(provenance['generatedBy'], contains('take_canonical_cycle'),
          reason: 'cycle construction belongs to the Python pipeline; a Dart '
              'reimplementation would be a second source of truth (M-F-03)');
    });

    test('the reference under test is the provisional one we think it is', () {
      // Not a decoration: if these bases quietly clear, the chain is being
      // verified against a reference with different guarantees, and the
      // conclusions in DEFTER stop applying.
      expect(reference.isProvisional, isTrue);
      expect(reference.hasBasis('mirror-ambiguity'), isFalse,
          reason: 'shine resolved mirroring — WRONG_FOOT is live BECAUSE of '
              'this, so the test below depends on it');
      expect(reference.mirrorConfident, isTrue);
      expect(reference.takeCount, 3);
    });
  });

  group('the chain, on real material', () {
    test('a take that BUILT the reference judges clean against it', () {
      final JudgeResult r = DanceJudge(reference: reference)
          .judge(replayCycle, momentA: momentA, momentB: momentB);
      expect(r.anyFired, isFalse,
          reason: 'this cycle is one of the three the consensus was built '
              'from; if it fails its own reference, the reference does not '
              'describe its own sources');
      // `findings` is NOT empty even on a clean run — the engine's contract is
      // ALWAYS-MEASURE, so every live code reports a verdict including `ok`
      // (M-F-71). Asserting emptiness here would quietly demand that measuring
      // stop, which is the opposite of the contract.
      expect(r.findings, isNotEmpty);
      expect(r.measurements, isNotEmpty);
    });

    test('MIRRORING a cycle with a CONFIDENT side margin fires WRONG_FOOT — '
        'and nothing else', () {
      expect((sidedProvenance['sideMarginDeg'] as num).toDouble(),
          greaterThan(minToleranceDeg),
          reason: 'the fixture is only a valid probe of WRONG_FOOT while its '
              'margin clears the noise floor — pin that, do not assume it');
      final JudgeResult r = DanceJudge(reference: reference)
          .judge(mirrorCycle(sidedCycle), momentA: momentA, momentB: momentB);
      expect(r.anyFired, isTrue);
      expect(r.fired.map((ErrorFinding f) => f.code), contains('WRONG_FOOT'));
      // The corruption is controlled: only the side changed, so only the
      // side-dependent code may FIRE. A second firing would mean the mirror
      // operation perturbed something it should not have.
      expect(r.fired, hasLength(1),
          reason: 'a controlled corruption must produce a controlled result — '
              'extra firings mean the test is measuring its own side effects');
    });

    test('a cycle whose OWN side margin is inside the noise floor gets NO side '
        'verdict — even though the REFERENCE is mirrorConfident', () {
      // The distinction this nails, found by measurement rather than reasoning:
      // reference-level `mirrorConfident` is about the SOURCES the build
      // resolved; it does not promise that any given learner cycle is
      // asymmetric enough to call. SHGkSbJm2Iw sits 3.0 deg apart between the
      // two orientations, inside the 6.0 deg floor, so the honest answer is
      // "cannot tell" in BOTH orientations.
      expect(reference.mirrorConfident, isTrue);
      for (final Cycle c in <Cycle>[replayCycle, mirrorCycle(replayCycle)]) {
        final JudgeResult r = DanceJudge(reference: reference)
            .judge(c, momentA: momentA, momentB: momentB);
        final ErrorFinding wf =
            r.findings.firstWhere((ErrorFinding f) => f.code == 'WRONG_FOOT');
        expect(wf.verdict, Verdict.noVerdict);
        expect(wf.why, contains('noise floor'));
      }
    });

    test('a blocked check NEVER fires, even end to end', () {
      final DanceJudge judge = DanceJudge(reference: reference);
      final JudgeResult clean =
          judge.judge(replayCycle, momentA: momentA, momentB: momentB);
      final JudgeResult mirrored = judge.judge(mirrorCycle(replayCycle),
          momentA: momentA, momentB: momentB);
      // The contract is NOT absence — it is a stated non-verdict. I asserted
      // absence first, from a stale doc comment in judge.dart; the code was
      // right and the comment was wrong (fixed there). A blocked check that
      // simply vanished could not be told apart from one nobody wrote, which
      // is the same defect the surface avoids by NAMING blocked gates.
      for (final JudgeResult r in <JudgeResult>[clean, mirrored]) {
        for (final String code in <String>['NO_WEIGHT_TRANSFER', 'STEP_LATE']) {
          final ErrorFinding f =
              r.findings.firstWhere((ErrorFinding f) => f.code == code);
          expect(f.verdict, Verdict.noVerdict,
              reason: '$code cannot be judged today; a real verdict here would '
                  'be a decision taken inside the noise floor / without a grid');
          expect(f.fired, isFalse);
          expect(f.why, isNotNull,
              reason: 'a non-verdict without a reason is indistinguishable '
                  'from a bug');
          expect(f.why, isNotEmpty);
        }
        expect(r.fired.map((ErrorFinding f) => f.code),
            isNot(contains('NO_WEIGHT_TRANSFER')));
        expect(r.fired.map((ErrorFinding f) => f.code),
            isNot(contains('STEP_LATE')));
      }
    });
  });

  group('judgement reaches the surface — through the right section', () {
    late Directory tmp;
    late SessionStore store;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('choreia_e2e_');
      store = JsonlSessionStore(File('${tmp.path}/sessions.jsonl'));
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    testWidgets('a scored session lands in Recorded; Evaluated stays empty '
        'and says why', (WidgetTester tester) async {
      // REAL file IO inside `testWidgets` must go through `runAsync`: the test
      // body runs in a FAKE-ASYNC zone where a real disk write never
      // completes, and the process hangs at 0% CPU instead of failing. Found
      // once in this codebase already (progress_test) and walked into again
      // here — documenting a trap does not prevent re-entering it, so the
      // guard has to be structural: every store call in a widget test is
      // wrapped, no exceptions.
      await tester.runAsync(() async {
        await store.append(SessionRecord(
          lessonId: 'ss_l1_footwork',
          lessonClass: ChoreiaLessonClass.scored,
          completedAt: DateTime.utc(2026, 7, 30, 12),
          workedSeconds: 600,
          unitsCompleted: 8,
          plannedUnits: 8,
          unitLabel: choreiaUnitLabel,
        ));
      });

      final CourseCatalog catalog = CourseCatalog.fromStyles(
        <Map<String, dynamic>>[
          (jsonDecode(File('${repo.path}/content/styles/salsa_shines/'
                      'style.json')
                  .readAsStringSync()) as Map)
              .cast<String, dynamic>(),
        ],
        steps: <String, Map<String, dynamic>>{
          'ss_shine_footwork': (jsonDecode(File(
                      '${repo.path}/content/styles/salsa_shines/steps/'
                      'ss_shine_footwork.json')
                  .readAsStringSync()) as Map)
              .cast<String, dynamic>(),
        },
      );

      final ProgressSummary summary = (await tester.runAsync(
          () => ProgressSummary.from(store: store, catalog: catalog)))!;

      expect(summary.recorded, hasLength(1));
      expect(summary.evaluated, isEmpty);
      expect(summary.evaluatedUnavailableReason, isNotNull);

      // The 0.10.0 adoption, proved through the REAL chain rather than in
      // isolation: this store was written by this replay, so its reading must
      // come back `ok` and say nothing. The twin (a corrupted file reporting
      // partial) lives in history_integrity_test — together they pin both
      // directions. Asserting only the corrupt case would be satisfied by a
      // surface that warns unconditionally.
      expect(summary.integrity.fidelity, HistoryFidelity.ok);
      expect(summary.integrity.note, isNull,
          reason: 'a clean replay must not caption itself with a warning');
      expect(summary.totals, isNotNull);

      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: ProgressView(summary: summary, catalog: catalog),
      ));
      expect(tester.takeException(), isNull);

      // The practice fact is under Recorded and NOT under Evaluated — the one
      // structural claim §3.9 makes, verified on the real chain rather than a
      // fixture catalogue.
      expect(
          find.descendant(
              of: find.byKey(ProgressView.recordedSectionKey),
              matching: find.text('10 min practised')),
          findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(ProgressView.evaluatedSectionKey),
              matching: find.text('10 min practised')),
          findsNothing);
    });

    testWidgets('the style the learner just practised is NOT presented as '
        'openable — its release gate is closed', (WidgetTester tester) async {
      final CourseCatalog catalog = CourseCatalog.fromStyles(
        <Map<String, dynamic>>[
          (jsonDecode(File('${repo.path}/content/styles/salsa_shines/'
                      'style.json')
                  .readAsStringSync()) as Map)
              .cast<String, dynamic>(),
        ],
      );

      // The library calls this style `live` — truthfully, it has a scored
      // lesson, and the judge above just scored against it. It is STILL not
      // openable, because BPM is unresolved. That both facts hold at once is
      // the whole point of keeping the two axes apart.
      final StyleView view = StyleView.derive(
        styleId: 'salsa_shines',
        contentStatus: 'live',
        blockedGates: catalog.blockedGates,
      );
      expect(view.contentStatus, 'live');
      expect(view.isOpenable, isFalse);
      expect(view.availability, Availability.gatedByRelease);
      expect(view.userFacingReason, contains('beat'));
      expect(view.userFacingReason, isNot(contains('bpm')),
          reason: 'the field name is not the user-facing reason');
    });
  });
}
