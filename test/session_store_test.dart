import 'dart:io';

import 'package:choreia/app/session_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// Failure behaviour is the point of these tests, not the happy path.
///
/// Persistence is the DATA LAYER of a promise ("we remember what you practised"),
/// so the interesting question is not "does append work" but "what survives a
/// process being killed mid-write, a downgraded app, a corrupt line". Each case
/// below was named in the delta contract before the code existed
/// (`docs/design/SESSION-STORE-DELTA.md` §1).
void main() {
  late Directory tmp;
  late File file;
  late JsonlSessionStore store;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('choreia_sessions_');
    file = File('${tmp.path}/sessions.jsonl');
    store = JsonlSessionStore(file);
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  SessionRecord rec({
    String lesson = 'ss_l1_footwork',
    LessonClass klass = LessonClass.scored,
    int worked = 300,
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

  group('empty history', () {
    test('first launch reads as empty, does not throw', () async {
      expect(await store.recent(), isEmpty);
      expect(await store.workedSecondsFor('anything'), 0);
    });

    test('J-064 TRAP: the empty result must be MUTABLE (recent() sorts in '
        'place, and a const [] crashed first launch in JabLab)', () async {
      final List<SessionRecord> got = await store.recent();
      expect(() => got.add(rec()), returnsNormally);
    });
  });

  group('append and read', () {
    test('round-trips every field including lessonClass', () async {
      await store.append(rec(klass: LessonClass.demoOnly, worked: 120,
          cycles: 3, planned: 8));
      final List<SessionRecord> got = await store.recent();
      expect(got, hasLength(1));
      expect(got.single.lessonClass, LessonClass.demoOnly);
      expect(got.single.workedSeconds, 120);
      expect(got.single.cyclesCompleted, 3);
      expect(got.single.plannedCycles, 8);
      expect(got.single.isComplete, isFalse);
    });

    test('newest first', () async {
      await store.append(rec(lesson: 'old', at: DateTime.utc(2026, 1, 1)));
      await store.append(rec(lesson: 'new', at: DateTime.utc(2026, 7, 1)));
      expect((await store.recent()).map((SessionRecord r) => r.lessonId),
          <String>['new', 'old']);
    });

    test('an ABANDONED session is kept, not discarded', () async {
      await store.append(rec(cycles: 2, planned: 8));
      final SessionRecord got = (await store.recent()).single;
      expect(got.isComplete, isFalse);
      expect(got.cyclesCompleted, 2,
          reason: '"they stopped" is data, not a shame to delete');
    });

    test('workedSecondsFor sums only the asked lesson', () async {
      await store.append(rec(lesson: 'a', worked: 100));
      await store.append(rec(lesson: 'b', worked: 500));
      await store.append(rec(lesson: 'a', worked: 200));
      expect(await store.workedSecondsFor('a'), 300);
    });
  });

  group('corruption survival', () {
    test('a corrupt line does NOT delete the surrounding history', () async {
      await store.append(rec(lesson: 'first'));
      await store.append(rec(lesson: 'second'));
      // Splice garbage into the middle, as a half-flushed write would.
      final List<String> lines = file.readAsStringSync().trim().split('\n');
      file.writeAsStringSync('${lines[0]}\n{not json at all\n${lines[1]}\n');

      final List<SessionRecord> got = await store.recent();
      expect(got, hasLength(2),
          reason: 'declaring months of history unreadable over one bad line '
              'has the same effect as losing it');
    });

    test('a HALF-WRITTEN last line does not take the file down', () async {
      await store.append(rec(lesson: 'kept'));
      file.writeAsStringSync('${file.readAsStringSync()}{"v":1,"lessonId":"cut');
      expect((await store.recent()).single.lessonId, 'kept');
    });

    test('an UNKNOWN schema version is skipped, not thrown on (a user can '
        'downgrade the app)', () async {
      await store.append(rec(lesson: 'known'));
      file.writeAsStringSync(
          '${file.readAsStringSync()}{"v":99,"lessonId":"from_the_future"}\n');
      final List<SessionRecord> got = await store.recent();
      expect(got, hasLength(1));
      expect(got.single.lessonId, 'known');
    });

    test('an unknown lessonClass reads as demoOnly, never as scored', () async {
      file.writeAsStringSync('{"v":1,"lessonId":"x","lessonClass":"gibberish",'
          '"completedAt":"2026-07-30T12:00:00.000Z","workedSeconds":60,'
          '"cyclesCompleted":1,"plannedCycles":1}\n');
      expect((await store.recent()).single.lessonClass, LessonClass.demoOnly,
          reason: 'over-claiming a grade is the failure this layer exists to '
              'avoid; when in doubt, claim less');
    });
  });

  group('atomicity', () {
    test('append leaves no .tmp behind', () async {
      await store.append(rec());
      expect(File('${file.path}.tmp').existsSync(), isFalse);
    });

    test('the store creates its own directory', () async {
      final JsonlSessionStore nested =
          JsonlSessionStore(File('${tmp.path}/deep/nested/s.jsonl'));
      await nested.append(rec());
      expect((await nested.recent()), hasLength(1));
    });
  });

  group('RecordedSummary — facts only, split by class', () {
    test('no field claims quality; counts split scored vs demoOnly', () async {
      await store.append(rec(klass: LessonClass.scored, worked: 600));
      await store.append(rec(klass: LessonClass.demoOnly, worked: 300));
      await store.append(
          rec(klass: LessonClass.demoOnly, worked: 60, cycles: 1, planned: 8));

      final RecordedSummary s = await RecordedSummary.from(store);
      expect(s.sessions, 3);
      expect(s.completed, 2);
      expect(s.stoppedEarly, 1);
      expect(s.scoredSessions, 1);
      expect(s.demoOnlySessions, 2,
          reason: '"you completed 3 lessons" would hide that two are never '
              'graded — the surface needs the split to stay honest');
      expect(s.workedSeconds, 960);
    });

    test('demoOnly sessions DO earn completion marks', () async {
      await store.append(rec(klass: LessonClass.demoOnly));
      final RecordedSummary s = await RecordedSummary.from(store);
      expect(s.completed, 1,
          reason: 'completion is a MEASUREMENT; withholding it too would make '
              'the lesson second class, which is what K10 prevents');
    });

    test('duration label hides seconds', () async {
      await store.append(rec(worked: 3661));
      expect((await RecordedSummary.from(store)).workedLabel, '1h 1m');
    });

    test('empty history summarises to zeros without throwing', () async {
      final RecordedSummary s = await RecordedSummary.from(store);
      expect(s.sessions, 0);
      expect(s.workedLabel, '0 min');
    });
  });
}
