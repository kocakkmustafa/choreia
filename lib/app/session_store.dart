import 'dart:convert';
import 'dart:io';

/// Whether a lesson was GRADED when the session happened.
///
/// Recorded rather than derived at read time, and that is the whole point: a
/// lesson's class CHANGES. `ss_l1_basic` is demoOnly today and has a named
/// promotion path to scored (M-F-152). If the surface derived the class from
/// today's config, every pre-promotion session would retroactively look
/// "scored" — the seance-layer counterpart of pinning `modelSha256`/`corePin`
/// so a model upgrade cannot silently reinterpret history.
enum LessonClass { scored, demoOnly }

/// One completed (or abandoned) practice session.
///
/// **Why so few fields:** every field recorded is an invitation for some future
/// surface to lean on it. Today this carries only what can be honestly measured
/// with NO camera bridge in the family: which lesson, when, how much work, how
/// many cycles. There is deliberately NO judgement/score field — recording
/// zeros while the camera is absent would mean drawing zeros on a progress
/// chart tomorrow (J-064's reasoning, adopted).
///
/// Delta from JabLab's SessionRecord (M-F-161 delta contract §2): boxing counts
/// ROUNDS — a time box, "work 3 minutes, rest, repeat". Dance has no such unit;
/// a lesson is built on a repeating CYCLE, which is already this repo's unit of
/// measurement (`cyclesInSegment`, `evidenceThickness.cyclesPerTake`, C-054's
/// take != source != cycle). The shared core interface should eventually carry
/// a unit-agnostic name plus an app-declared label — that decision belongs to
/// the third consumer, not to this file.
final class SessionRecord {
  const SessionRecord({
    required this.lessonId,
    required this.lessonClass,
    required this.completedAt,
    required this.workedSeconds,
    required this.cyclesCompleted,
    required this.plannedCycles,
  });

  factory SessionRecord.fromJson(Map<String, dynamic> j) => SessionRecord(
        lessonId: j['lessonId'] as String,
        lessonClass: switch (j['lessonClass']) {
          'scored' => LessonClass.scored,
          'demoOnly' => LessonClass.demoOnly,
          // An unknown class is NOT guessed as scored: over-claiming a grade
          // is the failure mode this whole layer exists to avoid.
          _ => LessonClass.demoOnly,
        },
        completedAt: DateTime.parse(j['completedAt'] as String),
        workedSeconds: (j['workedSeconds'] as num).toInt(),
        cyclesCompleted: (j['cyclesCompleted'] as num).toInt(),
        plannedCycles: (j['plannedCycles'] as num).toInt(),
      );

  final String lessonId;
  final LessonClass lessonClass;
  final DateTime completedAt;

  /// Seconds actually DANCED, rest excluded. Progress gates count practice
  /// time; folding rest in would let a learner pass a gate without earning it.
  final int workedSeconds;

  /// An abandoned session is recorded too — "they stopped" is data, not a
  /// shame to be deleted. With [plannedCycles] the completion ratio stays
  /// readable.
  final int cyclesCompleted;
  final int plannedCycles;

  bool get isComplete => cyclesCompleted >= plannedCycles;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lessonId': lessonId,
        'lessonClass': lessonClass.name,
        'completedAt': completedAt.toUtc().toIso8601String(),
        'workedSeconds': workedSeconds,
        'cyclesCompleted': cyclesCompleted,
        'plannedCycles': plannedCycles,
      };
}

/// Session history. **Interface deliberately narrow** (family rule of three).
///
/// It exists in this shape because a second app already needed it: JabLab wrote
/// the first, Choreia is the second, and when Lissom becomes the third the
/// implementation is promoted into `motion_core` with consumers unchanged. So
/// there is not one dance-specific term in this interface.
abstract interface class SessionStore {
  Future<void> append(SessionRecord record);

  /// Newest FIRST. All of them when [limit] is omitted.
  Future<List<SessionRecord>> recent({int? limit});

  /// Total practice time for one lesson — what a progress gate asks.
  Future<int> workedSecondsFor(String lessonId);
}

/// FACTS about recorded sessions. No judgement whatsoever.
///
/// Not one field here says "good" or "bad". Everything is measurable without a
/// camera, which is exactly why the K8 calibration lock does not close it: K8
/// withholds the SCORE, not the fact (M-F-04).
///
/// Choreia-specific (delta contract §4): counts are split by lesson class,
/// because "you completed 6 lessons" would hide that five of them are never
/// graded. Completion is a MEASUREMENT; a band is a JUDGEMENT. The progress
/// surface shows both, in separate sections, and never merges them.
final class RecordedSummary {
  const RecordedSummary({
    required this.sessions,
    required this.completed,
    required this.workedSeconds,
    required this.scoredSessions,
    required this.demoOnlySessions,
  });

  final int sessions;
  final int completed;
  final int workedSeconds;

  /// How much of the history could carry a judgement at all.
  final int scoredSessions;

  /// Taught-but-never-graded sessions. These EARN a completion mark and never
  /// a band — withholding the mark too would make the lesson second class,
  /// precisely what K10 exists to prevent.
  final int demoOnlySessions;

  int get stoppedEarly => sessions - completed;

  /// Human-readable duration. Seconds are NOT shown: at practice-session scale
  /// second precision carries no information, only an impression of precision.
  String get workedLabel {
    final int m = workedSeconds ~/ 60;
    if (m < 60) return '$m min';
    final int h = m ~/ 60;
    final int rem = m % 60;
    return rem == 0 ? '${h}h' : '${h}h ${rem}m';
  }

  static Future<RecordedSummary> from(SessionStore store) async {
    final List<SessionRecord> all = await store.recent();
    int worked = 0;
    int done = 0;
    int scored = 0;
    int demo = 0;
    for (final SessionRecord r in all) {
      worked += r.workedSeconds;
      if (r.isComplete) done++;
      switch (r.lessonClass) {
        case LessonClass.scored:
          scored++;
        case LessonClass.demoOnly:
          demo++;
      }
    }
    return RecordedSummary(
      sessions: all.length,
      completed: done,
      workedSeconds: worked,
      scoredSessions: scored,
      demoOnlySessions: demo,
    );
  }
}

/// Append-only JSONL store (family ruling: no 3rd-party DB).
///
/// **Why JSONL and why append-only:** a session record is an EVENT stream with
/// no query load — today's need is "append at the end, read from the start". A
/// DB would bring schema migration, a query layer and a platform dependency;
/// that need arrives when it is MEASURED. (The family's Hive gotcha is also on
/// record: with the wrong cipher it does not throw, it silently empties.)
///
/// **Every LINE carries its own schema version.** A single file-level version
/// makes it unreadable which rule an old line was written under — migration day
/// would mean rewriting the whole file or guessing.
///
/// **Atomicity:** the append is written to a temp file and moved with `rename`.
/// If the process dies during a direct append (mobile OSes kill apps at will) a
/// HALF line is left at the end and the next read breaks on it. `rename` is
/// atomic on POSIX: either the old file or the new one is visible, never a
/// state in between.
final class JsonlSessionStore implements SessionStore {
  JsonlSessionStore(this._file);

  /// Today's line schema. Incremented when a field is added; the reader SKIPS
  /// a version it does not know (rather than throwing) — forward compatibility,
  /// because a user can also downgrade the app.
  static const int schemaVersion = 1;

  final File _file;

  @override
  Future<void> append(SessionRecord record) async {
    final String line = jsonEncode(<String, dynamic>{
      'v': schemaVersion,
      ...record.toJson(),
    });

    final String existing =
        await _file.exists() ? await _file.readAsString() : '';
    final String next = existing.isEmpty ? '$line\n' : '$existing$line\n';

    final File tmp = File('${_file.path}.tmp');
    await tmp.parent.create(recursive: true);
    await tmp.writeAsString(next, flush: true);
    await tmp.rename(_file.path);
  }

  @override
  Future<List<SessionRecord>> recent({int? limit}) async {
    final List<SessionRecord> all = await _readAll();
    all.sort((SessionRecord a, SessionRecord b) =>
        b.completedAt.compareTo(a.completedAt));
    if (limit == null || limit >= all.length) return all;
    return all.sublist(0, limit);
  }

  @override
  Future<int> workedSecondsFor(String lessonId) async {
    int total = 0;
    for (final SessionRecord r in await _readAll()) {
      if (r.lessonId == lessonId) total += r.workedSeconds;
    }
    return total;
  }

  Future<List<SessionRecord>> _readAll() async {
    // Returning a MUTABLE list is required: `recent()` sorts the result in
    // place. Returning `const []` broke the empty-history path — that is, the
    // FIRST LAUNCH — in JabLab, and its test caught it. Carried here as a
    // known trap rather than rediscovered (delta contract §1).
    if (!await _file.exists()) return <SessionRecord>[];
    final List<SessionRecord> out = <SessionRecord>[];
    for (final String raw in (await _file.readAsString()).split('\n')) {
      final String line = raw.trim();
      if (line.isEmpty) continue;
      // A CORRUPT LINE DOES NOT DELETE THE WHOLE HISTORY. Declaring months of
      // accumulated records unreadable because of one half-written or
      // from-the-future line has the same effect as losing the data — that
      // line is skipped, the rest is read.
      try {
        final Map<String, dynamic> j =
            (jsonDecode(line) as Map).cast<String, dynamic>();
        final int v = (j['v'] as num?)?.toInt() ?? 0;
        if (v != schemaVersion) continue;
        out.add(SessionRecord.fromJson(j));
      } on Object catch (_) {
        continue;
      }
    }
    return out;
  }
}
