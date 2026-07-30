import 'package:choreia/app/course_catalog.dart';
import 'package:choreia/app/progress_summary.dart';
import 'package:choreia/app/progress_view.dart';
import 'package:choreia/app/session_store.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show CachingAssetBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests measure the HONESTY STRUCTURE of the progress surface, not its
/// appearance — there is no device in this session, so nothing here claims
/// anything about how it looks.
///
/// The load-bearing choice: every section assertion is SCOPED to a section key
/// via `find.descendant`. An unscoped `find.text` would pass even if Recorded
/// and Evaluated were merged into one list, which is precisely the defect
/// §3.9 exists to prevent — so an unscoped test would be a test that cannot
/// fail for the reason it was written.
void main() {
  // Content shaped like the real files, trimmed to what the derivation reads.
  final Map<String, dynamic> salsaStyle = <String, dynamic>{
    'id': 'salsa_shines',
    'shipGates': <Map<String, dynamic>>[
      {
        'gate': 'bpmResolved',
        'blocked': true,
        'why': 'bpmRange unresolved (two passes ~2x apart)',
        'unblockedBy': 'one live tap on a known track',
      },
      {'gate': 'referencesBuilt', 'blocked': false, 'why': 'done'},
    ],
    'levels': <Map<String, dynamic>>[
      {
        'level': 1,
        'lessons': <Map<String, dynamic>>[
          {
            'id': 'ss_l1_footwork',
            'displayName': {'en': 'Shine footwork'},
            'step': 'ss_shine_footwork',
            'scored': true,
            'minutes': 10,
          },
          {
            'id': 'ss_l1_basic',
            'displayName': {'en': 'The basic'},
            'step': 'ss_basic',
            'scored': false,
            'demoOnly': true,
            'demoOnlyClass': 'structural-circular',
            'demoOnlyReason': {'en': 'the plateau is below what we can measure'},
            'promotionPath': {'unblockedBy': 'a source with visible holds'},
            'minutes': 8,
          },
          {
            'id': 'ss_l1_locked_example',
            'displayName': {'en': 'Not written yet'},
            'scored': false,
            'lockedReason': {'en': 'no teachers measured for it yet'},
            'minutes': 6,
          },
        ],
      },
    ],
  };

  final Map<String, Map<String, dynamic>> steps = <String, Map<String, dynamic>>{
    'ss_shine_footwork': <String, dynamic>{
      // Key is `errors`, matching the real step documents.
      'errors': <Map<String, dynamic>>[
        {
          'code': 'NO_WEIGHT_TRANSFER',
          'status': 'blocked',
          'blockedBy': 'threshold(1.0deg) < noiseFloor(6.0deg)',
        },
        {'code': 'WRONG_FOOT', 'status': 'live (M-F-117)'},
        {
          'code': 'STEP_LATE',
          'status': 'blocked',
          'blockedBy': 'beatsStatus:PENDING — no beat grid to be late against',
        },
      ],
    },
    'ss_basic': <String, dynamic>{'errors': <Map<String, dynamic>>[]},
  };

  final CourseCatalog catalog =
      CourseCatalog.fromStyles(<Map<String, dynamic>>[salsaStyle], steps: steps);

  SessionRecord rec({
    required String lesson,
    LessonClass klass = LessonClass.scored,
    int worked = 600,
    int cycles = 8,
    int planned = 8,
    DateTime? at,
  }) =>
      SessionRecord(
        lessonId: lesson,
        lessonClass: klass,
        completedAt: at ?? DateTime.utc(2026, 7, 30, 12),
        workedSeconds: worked,
        cyclesCompleted: cycles,
        plannedCycles: planned,
      );

  ProgressSummary summaryOf(List<SessionRecord> history) =>
      ProgressSummary.build(
        history: history,
        catalog: catalog,
        totals: const RecordedSummary(
          sessions: 0,
          completed: 0,
          workedSeconds: 0,
          scoredSessions: 0,
          demoOnlySessions: 0,
        ),
      );

  group('CourseCatalog — blocked gates are DERIVED, never prose', () {
    test('all three scopes are picked up, and only the blocked ones', () {
      final Set<String> ids =
          catalog.blockedGates.map((BlockedGate g) => g.id).toSet();
      expect(ids, contains('bpmResolved'));           // style scope
      expect(ids, contains('NO_WEIGHT_TRANSFER'));    // errorCode scope
      expect(ids, contains('STEP_LATE'));             // errorCode scope
      expect(ids, contains('ss_l1_basic'));           // lesson scope
      expect(ids, contains('ss_l1_locked_example'));  // lesson scope

      expect(ids, isNot(contains('referencesBuilt')),
          reason: 'a PASSED gate must not be listed as blocked — '
              'over-claiming a limit is still a false statement');
      expect(ids, isNot(contains('WRONG_FOOT')),
          reason: 'a live error code is not a blocked gate');
      expect(ids, isNot(contains('ss_l1_footwork')),
          reason: 'a scored lesson is not a blocked gate');
    });

    test('the three lesson kinds stay distinct — locked is NOT weak demoOnly',
        () {
      expect(catalog.lessonById('ss_l1_footwork')!.kind, LessonKind.scored);
      expect(catalog.lessonById('ss_l1_basic')!.kind, LessonKind.demoOnly);
      expect(catalog.lessonById('ss_l1_locked_example')!.kind,
          LessonKind.locked);
    });

    test('every ungraded lesson carries a reason', () {
      for (final LessonInfo l in catalog.lessons.where((l) => !l.isScored)) {
        expect(l.reason, isNotNull, reason: '${l.id} has no stated reason');
        expect(l.reason, isNotEmpty);
      }
    });

    test('a step shared by two lessons emits its gate ONCE', () {
      final Iterable<BlockedGate> nwt =
          catalog.blockedGates.where((g) => g.id == 'NO_WEIGHT_TRANSFER');
      expect(nwt, hasLength(1));
    });
  });

  group('ProgressSummary — the two sections cannot merge', () {
    test('there is no combined list on the type at all', () {
      final ProgressSummary s = summaryOf(<SessionRecord>[]);
      // Structural, not stylistic: a surface literally cannot render one list,
      // because no field offers one.
      expect(s.recorded, isEmpty);
      expect(s.evaluated, isEmpty);
    });

    test('Evaluated is empty AND says why — a blank would blame the user', () {
      final ProgressSummary s = summaryOf(<SessionRecord>[
        rec(lesson: 'ss_l1_footwork'),
      ]);
      expect(s.evaluated, isEmpty);
      expect(s.evaluatedUnavailableReason, isNotNull);
      expect(s.evaluatedUnavailableReason, contains('camera'));
    });

    test('a demoOnly session appears in Recorded with its completion counted',
        () {
      final ProgressSummary s = summaryOf(<SessionRecord>[
        rec(lesson: 'ss_l1_basic', klass: LessonClass.demoOnly),
      ]);
      final RecordedRow row = s.recorded.single;
      expect(row.isDemoOnly, isTrue);
      expect(row.completedSessions, 1,
          reason: 'completion is a MEASUREMENT; withholding it would make the '
              'lesson second class — the thing K10 prevents');
    });

    test('a lesson practised across a promotion reports the CAUTIOUS class',
        () {
      final ProgressSummary s = summaryOf(<SessionRecord>[
        rec(lesson: 'ss_l1_basic', klass: LessonClass.demoOnly,
            at: DateTime.utc(2026, 1, 1)),
        rec(lesson: 'ss_l1_basic', klass: LessonClass.scored,
            at: DateTime.utc(2026, 7, 1)),
      ]);
      expect(s.recorded.single.lessonClass, LessonClass.demoOnly,
          reason: 'calling the whole history scored would over-claim exactly '
              'the sessions danced before the promotion');
    });

    test('display names come from content, unknown ids fall back to the id', () {
      final ProgressSummary s = summaryOf(<SessionRecord>[
        rec(lesson: 'ss_l1_footwork'),
        rec(lesson: 'a_lesson_no_longer_in_content'),
      ]);
      final Map<String, String> names = <String, String>{
        for (final RecordedRow r in s.recorded) r.lessonId: r.displayName,
      };
      expect(names['ss_l1_footwork'], 'Shine footwork');
      expect(names['a_lesson_no_longer_in_content'],
          'a_lesson_no_longer_in_content',
          reason: 'a removed lesson must still render its history — dropping '
              'the row would delete the record');
    });

    test('unit-bearing strings: no bare numbers reach a surface', () {
      expect(ProgressStrings.duration(600), '10 min practised');
      expect(ProgressStrings.duration(3661), '1h 1m practised');
      expect(ProgressStrings.duration(7200), '2h practised');
      expect(ProgressStrings.cycles(3, 8), '3 of 8 cycles');
      expect(ProgressStrings.sessionsCompleted(1, 2), '1 of 2 sessions finished');
    });
  });

  group('ProgressView — WHICH SECTION each string lands in', () {
    Future<void> pump(WidgetTester tester, ProgressSummary s) =>
        tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: ProgressView(summary: s, catalog: catalog),
        ));

    Finder inSection(Key section, String text) => find.descendant(
        of: find.byKey(section), matching: find.text(text));

    testWidgets('the reason for an empty Evaluated sits INSIDE Evaluated, '
        'not in Recorded', (WidgetTester tester) async {
      final ProgressSummary s = summaryOf(<SessionRecord>[
        rec(lesson: 'ss_l1_footwork'),
      ]);
      await pump(tester, s);
      final String reason = s.evaluatedUnavailableReason!;
      expect(inSection(ProgressView.evaluatedSectionKey, reason), findsOneWidget);
      expect(inSection(ProgressView.recordedSectionKey, reason), findsNothing);
    });

    testWidgets('practice facts land in Recorded and NOWHERE in Evaluated',
        (WidgetTester tester) async {
      await pump(tester, summaryOf(<SessionRecord>[
        rec(lesson: 'ss_l1_footwork', worked: 600, cycles: 8, planned: 8),
      ]));
      expect(inSection(ProgressView.recordedSectionKey, '10 min practised'),
          findsOneWidget);
      expect(inSection(ProgressView.evaluatedSectionKey, '10 min practised'),
          findsNothing,
          reason: 'a measurement rendered under Evaluated would read as a grade');
    });

    testWidgets('a demoOnly row shows the completion mark AND the no-band dash',
        (WidgetTester tester) async {
      await pump(tester, summaryOf(<SessionRecord>[
        rec(lesson: 'ss_l1_basic', klass: LessonClass.demoOnly),
      ]));
      final Finder row = find.byKey(const Key('progress.recorded.ss_l1_basic'));
      expect(
          find.descendant(
              of: row,
              matching: find.textContaining('Taught, not graded')),
          findsOneWidget);
      expect(
          find.descendant(
              of: row, matching: find.text(ProgressStrings.noBand)),
          findsOneWidget,
          reason: 'a blank would look like a missing value; the dash says the '
              'judgement is ABSENT, not zero');
      expect(
          find.descendant(
              of: row,
              matching: find.textContaining('below what we can measure')),
          findsOneWidget,
          reason: 'the reason travels with the row (K10: not dropped, marked '
              'with a reason in the language the user reads)');
    });

    testWidgets('a scored lesson row carries NO band and NO demo mark',
        (WidgetTester tester) async {
      await pump(tester, summaryOf(<SessionRecord>[
        rec(lesson: 'ss_l1_footwork'),
      ]));
      final Finder row =
          find.byKey(const Key('progress.recorded.ss_l1_footwork'));
      expect(
          find.descendant(
              of: row, matching: find.textContaining('Taught, not graded')),
          findsNothing);
      expect(
          find.descendant(
              of: row, matching: find.text(ProgressStrings.noBand)),
          findsNothing,
          reason: 'the dash is the demo-only marker; on a scored lesson it '
              'would claim a judgement was withheld');
    });

    testWidgets('every blocked gate is NAMED on screen, with its reason',
        (WidgetTester tester) async {
      await pump(tester, summaryOf(<SessionRecord>[]));
      for (final BlockedGate g in catalog.blockedGates) {
        expect(
            find.descendant(
                of: find.byKey(ProgressView.blockedSectionKey),
                matching: find.textContaining(g.id)),
            findsOneWidget,
            reason: '${g.id} is blocked but not on the screen — silence is a '
                'lie (J-066)');
      }
    });

    testWidgets('the no-retroactive-credit statement is present',
        (WidgetTester tester) async {
      await pump(tester, summaryOf(<SessionRecord>[]));
      expect(find.byKey(ProgressView.retroactiveNoteKey), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(ProgressView.blockedSectionKey),
              matching: find.byKey(ProgressView.retroactiveNoteKey)),
          findsOneWidget,
          reason: 'it answers the question the blocked list provokes, so it '
              'belongs beside that list');
    });

    testWidgets('empty history says so without hiding anything',
        (WidgetTester tester) async {
      await pump(tester, summaryOf(<SessionRecord>[]));
      expect(
          inSection(
              ProgressView.recordedSectionKey, ProgressStrings.emptyHistory),
          findsOneWidget);
      // The blocked list is NOT conditional on having history: a new user must
      // see the limits before investing time, not after.
      expect(
          find.descendant(
              of: find.byKey(ProgressView.blockedSectionKey),
              matching: find.textContaining('bpmResolved')),
          findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // The REAL content, not a fixture. This is the group that earns its keep:
  // C-111 was found by a Dart test that read the real artifact rather than a
  // hand-built one, and content drift is the same class of defect — a fixture
  // agrees with whatever I believed when I wrote it.
  // ─────────────────────────────────────────────────────────────────────────
  group('real content (asset bundle)', () {
    // WHY A DISK-BACKED BUNDLE AND NOT `rootBundle`
    //
    // `rootBundle.loadString` never completes under `flutter test` in this
    // setup — probed all three ways (plain `test`, `testWidgets`, and
    // `testWidgets` + `runAsync`) and every one hung with the tester process at
    // 0% CPU, which is what separates a deadlock from a slow machine. Rather
    // than skip the real-content check, the bundle is backed by the repository
    // files: `CourseCatalog.load` runs in full, including its tolerance for an
    // unwritten step document.
    //
    // The honest limit: this exercises the LOADER and the DERIVATION against
    // real content, not Flutter's own asset plumbing. Whether the declared
    // asset paths resolve on a device is a separate claim, and this test does
    // not make it.
    Future<CourseCatalog> loadReal(WidgetTester tester) async =>
        CourseCatalog.load(_DiskBundle());

    testWidgets('loads, and every ungraded lesson names a reason',
        (WidgetTester tester) async {
      final CourseCatalog real = await loadReal(tester);
      expect(real.lessons, isNotEmpty);

      for (final LessonInfo l in real.lessons.where((l) => !l.isScored)) {
        expect(l.reason, isNotNull,
            reason: '${l.id} is ungraded with NO stated reason — the silence '
                'K10 forbids');
        expect(l.reason!.trim(), isNotEmpty, reason: '${l.id} reason is blank');
      }
    });

    testWidgets('the blocked gates Choreia actually has today are all named',
        (WidgetTester tester) async {
      final CourseCatalog real = await loadReal(tester);
      final Set<String> ids =
          real.blockedGates.map((BlockedGate g) => g.id).toSet();

      // These three are the measured limits recorded in the plan and UI-BRIEF
      // §3.9. If one stops being blocked, this test SHOULD fail — that is the
      // moment the surface's text must change too, and a stale limit is the
      // failure mode a hand-written list has.
      expect(ids, contains('bpmResolved'),
          reason: 'BPM is DISPUTED; if this gate cleared, the beat grid landed '
              'and §3.9 needs rewriting');
      expect(ids, contains('NO_WEIGHT_TRANSFER'));
      expect(ids, contains('STEP_LATE'));
    });

    testWidgets('an UNWRITTEN step is recorded as unknown, not as clean',
        (WidgetTester tester) async {
      final CourseCatalog real = await loadReal(tester);
      // `hh_l1_rock` points at `hh_rock`, whose step document is deliberately
      // not written yet. Loading must survive it (content says so on purpose)
      // AND must not report "no blocked checks" for it — absence of the
      // document is absence of KNOWLEDGE.
      expect(real.unreadableSteps, contains('hh_rock'));
      expect(real.blockedGates.map((BlockedGate g) => g.id), contains('hh_rock'),
          reason: 'an unreadable step must appear as something we cannot check, '
              'otherwise the screen implies it needs no checks');
    });

    testWidgets('a scored lesson exists and is NOT listed as blocked',
        (WidgetTester tester) async {
      final CourseCatalog real = await loadReal(tester);
      final List<LessonInfo> scored = real.scoredLessons.toList();
      expect(scored, hasLength(1),
          reason: 'exactly one scored lesson today (ss_l1_footwork). If this '
              'changes, the honesty copy that says so must change with it');
      final Set<String> gateIds =
          real.blockedGates.map((BlockedGate g) => g.id).toSet();
      for (final LessonInfo l in scored) {
        expect(gateIds, isNot(contains(l.id)));
      }
    });

    testWidgets('the surface renders against real content without throwing',
        (WidgetTester tester) async {
      final CourseCatalog real = await loadReal(tester);
      final ProgressSummary s = ProgressSummary.build(
        history: <SessionRecord>[
          rec(lesson: 'ss_l1_footwork'),
          rec(lesson: 'ss_l1_basic', klass: LessonClass.demoOnly),
        ],
        catalog: real,
        totals: const RecordedSummary(sessions: 2, completed: 2,
            workedSeconds: 1200, scoredSessions: 1, demoOnlySessions: 1),
      );
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: ProgressView(summary: s, catalog: real),
      ));
      expect(tester.takeException(), isNull);
      // The real demo-only reason must reach the row, not a placeholder.
      expect(
          find.descendant(
              of: find.byKey(const Key('progress.recorded.ss_l1_basic')),
              matching: find.textContaining('Taught, not graded — ')),
          findsOneWidget);
    });
  });
}

/// Serves the repository's real content files through the [AssetBundle] API, so
/// the production loader is the thing under test.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final File file = File(key);
    if (!file.existsSync()) {
      // Same shape of failure the real bundle raises for a missing asset —
      // which is the branch `CourseCatalog.load` has to survive for a step
      // whose document is not written yet.
      throw FlutterError('asset not found: $key');
    }
    return ByteData.view(file.readAsBytesSync().buffer);
  }
}
