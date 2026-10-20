import 'package:choreia/app/course_catalog.dart';
import 'package:choreia/app/progress_summary.dart';
import 'package:choreia/app/progress_view.dart';
import 'package:choreia/app/recorded_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_core/motion_core.dart';

const _catalog = CourseCatalog(lessons: [], blockedGates: []);

SessionRecord _record({int planned = 8, int cycles = 3}) => SessionRecord(
      lessonId: 'practice',
      completedAt: DateTime.utc(2026, 10, 19),
      workedSeconds: 60,
      unitsCompleted: cycles,
      plannedUnits: planned,
      unitLabel: 'cycle',
      lessonClass: ChoreiaLessonClass.demoOnly,
    );

void main() {
  test('rows and totals use one recent reading even if later reads change',
      () async {
    final store = _ChangingStore();
    final summary = await ProgressSummary.from(store: store, catalog: _catalog);

    expect(store.recentCalls, 1);
    expect(summary.recorded.single.sessions, 1);
    expect(summary.totals!.sessions, 1);
    expect(
        summary.totals!.workedSeconds, summary.recorded.single.workedSeconds);
  });

  test('integrity lookup cannot mutate the captured rows and totals', () async {
    final store = _ChangingStore(mutateDuringIntegrity: true);
    final summary = await ProgressSummary.from(store: store, catalog: _catalog);

    expect(store.records, hasLength(2),
        reason: 'the store really changed after its recent reading');
    expect(summary.recorded.single.sessions, 1);
    expect(summary.totals!.sessions, 1);
    expect(summary.integrity.readableRecords, 1);
  });

  test('targetless sessions cannot inflate a mixed row completion count', () {
    final summary = ProgressSummary.build(
      history: [_record(planned: 0), _record(planned: 8)],
      catalog: _catalog,
    );

    expect(summary.recorded.single.sessions, 2);
    expect(summary.recorded.single.targetedSessions, 1);
    expect(summary.recorded.single.completedSessions, 0);
  });

  test('snapshot totals count a single-pass iterable without a second read',
      () {
    var read = false;
    Iterable<SessionRecord> once() sync* {
      if (read) throw StateError('The records were iterated twice.');
      read = true;
      yield _record(planned: 0);
      yield _record(planned: 8, cycles: 8);
    }

    final totals = RecordedSummary.fromRecords(once());

    expect(totals.sessions, 2);
    expect(totals.targetedSessions, 1);
    expect(totals.completed, 1);
    expect(totals.demoOnlySessions, 2);
  });

  testWidgets('empty camera history keeps the independent course entry visible',
      (tester) async {
    final summary = ProgressSummary.build(history: [], catalog: _catalog);
    await tester.pumpWidget(MaterialApp(
      home: ProgressView(
        summary: summary,
        courseEntry: const Text('Course learning record'),
      ),
    ));

    expect(find.byKey(ProgressView.historyScopeKey), findsOneWidget);
    expect(find.text(ProgressStrings.historyScope), findsOneWidget);
    expect(find.text(ProgressStrings.emptyHistory), findsOneWidget);
    expect(find.text('Course learning record'), findsOneWidget);
    expect(find.textContaining('there is simply nothing here'), findsNothing);
  });

  testWidgets('mixed rows show all sessions and the target-only completion',
      (tester) async {
    final summary = ProgressSummary.build(
      history: [_record(planned: 0), _record(planned: 8)],
      catalog: _catalog,
    );
    await tester.pumpWidget(MaterialApp(home: ProgressView(summary: summary)));

    expect(find.text('2 sessions'), findsOneWidget);
    expect(find.text('0 of 1 sessions finished'), findsOneWidget);
    expect(find.text('6 cycles read'), findsOneWidget);
    expect(find.text('6 of 8 cycles'), findsNothing,
        reason: 'the eight-cycle plan belongs to only one of the sessions');
  });
}

final class _ChangingStore implements SessionStore {
  _ChangingStore({this.mutateDuringIntegrity = false});

  final bool mutateDuringIntegrity;
  final List<SessionRecord> records = [_record()];
  int recentCalls = 0;

  @override
  Future<List<SessionRecord>> recent({int? limit}) async {
    recentCalls++;
    if (recentCalls > 1) records.add(_record());
    return records;
  }

  @override
  Future<int> unreadableRecords() async {
    if (mutateDuringIntegrity) records.add(_record());
    return 0;
  }

  @override
  Future<void> append(SessionRecord record) async => records.add(record);

  @override
  Future<int> workedSecondsFor(String lessonId) async => records
      .where((record) => record.lessonId == lessonId)
      .fold<int>(0, (seconds, record) => seconds + record.workedSeconds);
}
