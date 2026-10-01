import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/salsa_course.dart';
import 'package:choreia/app/course/salsa_progress.dart';
import 'package:choreia/app/course/salsa_weekly_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final course = SalsaCourse.fromJson(
    jsonDecode(File('content/salsa_on1_course.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  SalsaProgressEvent event(
    String lessonId,
    SalsaEvidence kind,
    DateTime at, {
    int? version,
  }) =>
      SalsaProgressEvent(
        courseId: course.id,
        version: version ?? course.version,
        lessonId: lessonId,
        kind: kind,
        option: SalsaPracticeOption.standard,
        at: at,
      );

  test('four local Monday weeks count only saved practice for this version',
      () {
    final progress = SalsaProgress([
      event('so_01', SalsaEvidence.practised, DateTime(2026, 12, 28, 0, 1)),
      event('so_01', SalsaEvidence.practised, DateTime(2026, 12, 31, 9)),
      event('so_02', SalsaEvidence.practised, DateTime(2026, 12, 27, 23, 59)),
      event('so_03', SalsaEvidence.practised, DateTime(2026, 12, 7, 12)),
      event('so_04', SalsaEvidence.practised, DateTime(2026, 11, 30, 12)),
      event('so_01', SalsaEvidence.viewed, DateTime(2026, 12, 30, 10)),
      event('so_01', SalsaEvidence.selfReportedComplete,
          DateTime(2026, 12, 30, 11)),
      event('so_02', SalsaEvidence.practised, DateTime(2026, 12, 30, 9),
          version: course.version + 1),
      event('so_02', SalsaEvidence.practised, DateTime(2027, 1, 2, 9)),
    ]);

    final activity = salsaWeeklyActivity(
      progress,
      course,
      now: DateTime(2027, 1, 1, 12),
    );
    final weeks = activity.weeks;

    expect(activity.asOf, DateTime(2027, 1, 1, 12));
    expect(activity.futureDatedAttempts, 1);
    expect(weeks.map((week) => week.startsOn), [
      DateTime(2026, 12, 28),
      DateTime(2026, 12, 21),
      DateTime(2026, 12, 14),
      DateTime(2026, 12, 7),
    ]);
    expect(weeks.map((week) => week.practiceAttempts), [2, 1, 0, 1]);
    expect(weeks.map((week) => week.distinctLessons), [1, 1, 0, 1]);
    expect(() => weeks.clear(), throwsUnsupportedError);
  });
}
