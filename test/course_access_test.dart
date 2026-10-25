import 'dart:io';

import 'package:choreia/app/course/course_access.dart';
import 'package:choreia/app/course/paid_lesson_lock.dart';
import 'package:choreia/app/course/short_form_course_page.dart';
import 'package:choreia/app/library/written_courses_progress_entry.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'hip_hop_course_page_test.dart' show WrittenBundle;

/// Paywall "A" (23 Oct 2026): the first lessons of every course are free, the
/// rest open with a membership, and an owner change locks them again.
void main() {
  test('ücretsiz ders sınırı her kursta yaklaşık üçte bir', () {
    expect(CourseAccess.freeLessons.keys.toSet(),
        WrittenCoursesProgressEntry.lessonCounts.keys.toSet());
    for (final entry in CourseAccess.freeLessons.entries) {
      final total = WrittenCoursesProgressEntry.lessonCounts[entry.key]!;
      expect(entry.value, greaterThan(0), reason: entry.key);
      expect(entry.value, lessThan(total), reason: entry.key);
      expect(entry.value / total, inInclusiveRange(0.3, 0.4),
          reason: entry.key);
      expect(CourseAccess.isFree(entry.key, entry.value), isTrue);
      expect(CourseAccess.isFree(entry.key, entry.value + 1), isFalse);
    }
    // Salsa frees whole modules of six lessons.
    expect(CourseAccess.freeLessons['salsa_shines']! % 6, 0);
    expect(CourseAccess.isFree('unknown_style', 1), isFalse);
  });

  test('açık erişim her dersi açar', () {
    const access = OpenCourseAccess();
    expect(access.allOpen, isTrue);
    expect(access.canOpen('line_dance', 12), isTrue);
  });

  testWidgets('abonelik kilidi bir kez sorar, sahip değişince geri kilitlenir',
      (tester) async {
    final epoch = ValueNotifier<int>(1);
    var asked = 0;
    var answer = false;
    final access = SubscriptionCourseAccess(
        gate: (_) async {
          asked++;
          return answer;
        },
        ownerEpoch: epoch);
    late BuildContext context;
    await tester.pumpWidget(Builder(builder: (c) {
      context = c;
      return const SizedBox();
    }));

    expect(access.canOpen('line_dance', 4), isTrue);
    expect(access.canOpen('line_dance', 5), isFalse);
    expect(await access.unlock(context), isFalse);
    expect(access.canOpen('line_dance', 5), isFalse);

    answer = true;
    expect(await access.unlock(context), isTrue);
    expect(access.canOpen('line_dance', 12), isTrue);
    expect(await access.unlock(context), isTrue);
    expect(asked, 2, reason: 'an unlocked owner is not asked again');

    epoch.value = 2;
    expect(access.unlocked.value, isFalse);
    expect(access.canOpen('line_dance', 5), isFalse);
    access.dispose();
    epoch.dispose();
  });

  testWidgets('sahip kontrol sırasında değişirse kilit açılmaz',
      (tester) async {
    final epoch = ValueNotifier<int>(1);
    final access = SubscriptionCourseAccess(
        gate: (_) async {
          epoch.value = 2;
          return true;
        },
        ownerEpoch: epoch);
    late BuildContext context;
    await tester.pumpWidget(Builder(builder: (c) {
      context = c;
      return const SizedBox();
    }));
    expect(await access.unlock(context), isFalse);
    expect(access.unlocked.value, isFalse);
    access.dispose();
    epoch.dispose();
  });

  testWidgets('kısa form: ücretsiz ünite açık, ücretli ünite kilitli ve açılır',
      (tester) async {
    final source = File('content/original_short_form_beginner_course.json')
        .readAsStringSync();
    var asked = 0;
    final access = SubscriptionCourseAccess(gate: (_) async {
      asked++;
      return true;
    });
    await tester.pumpWidget(MaterialApp(
        home: ShortFormCoursePage(
            bundle: WrittenBundle(source),
            env: LiveEnvironment(courseAccess: access))));
    for (var i = 0;
        i < 20 && find.byType(ExpansionTile).evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final tiles = find.byType(ExpansionTile);
    expect(tiles, findsWidgets);
    final included = find.text('Included with membership');
    // Ten units, four free: six carry the membership note.
    expect(included, findsNWidgets(6));

    final paid = find.ancestor(of: included.first, matching: tiles);
    await tester.ensureVisible(paid);
    await tester.tap(paid);
    await tester.pumpAndSettle();
    expect(find.byType(PaidLessonLock), findsOneWidget);
    await tester.tap(find.byKey(PaidLessonLock.buttonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(asked, 1);
    expect(find.byType(PaidLessonLock), findsNothing);
    expect(included, findsNothing);
    access.dispose();
  });
}
