import 'salsa_course.dart';
import 'salsa_progress.dart';

/// A calendar week of saved course practice actions, never a skill judgement.
final class SalsaPracticeWeek {
  const SalsaPracticeWeek({
    required this.startsOn,
    required this.practiceAttempts,
    required this.distinctLessons,
  });

  /// Local Monday at midnight. The caller formats this for the learner.
  final DateTime startsOn;
  final int practiceAttempts;
  final int distinctLessons;
}

/// A dated snapshot: out-of-range records remain in the course journal.
final class SalsaWeeklyActivity {
  const SalsaWeeklyActivity({
    required this.asOf,
    required this.weeks,
    required this.futureDatedAttempts,
  });

  final DateTime asOf;
  final List<SalsaPracticeWeek> weeks;

  /// A device-clock change can make a valid saved action appear future-dated.
  /// Keep that discrepancy visible instead of silently showing four zeroes.
  final int futureDatedAttempts;
}

/// The calendar week containing [now] and the preceding three, newest first.
///
/// The course journal is separate from the live camera session journal. Only
/// `practised` actions for this exact course version belong in this view:
/// opening a lesson and marking it complete do not create extra practice.
SalsaWeeklyActivity salsaWeeklyActivity(
  SalsaProgress progress,
  SalsaCourse course, {
  DateTime? now,
}) {
  final reference = (now ?? DateTime.now()).toLocal();
  final currentMonday = _localMonday(reference);
  final starts = List<DateTime>.generate(
    4,
    (index) => DateTime(
      currentMonday.year,
      currentMonday.month,
      currentMonday.day - 7 * index,
    ),
    growable: false,
  );
  final attempts = List<int>.filled(4, 0);
  final lessons = List<Set<String>>.generate(4, (_) => <String>{});
  var futureDatedAttempts = 0;

  for (final event in progress.forCourse(course)) {
    if (event.kind != SalsaEvidence.practised) continue;
    final localTime = event.at.toLocal();
    if (localTime.isAfter(reference)) {
      futureDatedAttempts++;
      continue;
    }
    final monday = _localMonday(localTime);
    final index = starts.indexWhere((start) => start == monday);
    if (index < 0) continue;
    attempts[index]++;
    lessons[index].add(event.lessonId);
  }

  return SalsaWeeklyActivity(
    asOf: reference,
    futureDatedAttempts: futureDatedAttempts,
    weeks: List<SalsaPracticeWeek>.unmodifiable(
      List<SalsaPracticeWeek>.generate(
        4,
        (index) => SalsaPracticeWeek(
          startsOn: starts[index],
          practiceAttempts: attempts[index],
          distinctLessons: lessons[index].length,
        ),
      ),
    ),
  );
}

DateTime _localMonday(DateTime instant) {
  final local = instant.toLocal();
  // Construct a civil date rather than subtracting 24-hour durations, which
  // can land at a different local hour across daylight-saving transitions.
  return DateTime(
    local.year,
    local.month,
    local.day - (local.weekday - DateTime.monday),
  );
}
