import 'package:flutter/material.dart';

import '../course/salsa_course_page.dart';
import '../live/live_environment.dart';
import '../localization/choreia_locale.dart';
import '../theme.dart';
import '../ui_language.dart';
import 'library_catalog.dart';
import 'style_content_copy.dart';
import 'style_detail_view.dart';

/// The Progress tab's door into every written course, not only Salsa.
///
/// Salsa keeps its own panel ([SalsaCourseEntry]) because its progress and
/// weekly activity live behind it; the other four courses open the same route
/// the catalogue card and style page open ([WrittenCourseLink]).
class WrittenCoursesProgressEntry extends StatelessWidget {
  const WrittenCoursesProgressEntry({
    required this.entries,
    this.env = const LiveEnvironment(),
    super.key,
  });

  /// Catalogue entries in catalogue order; only written-course styles show.
  final List<LibraryEntry> entries;
  final LiveEnvironment env;

  static const Key summaryKey = Key('progress.writtenCourses');
  static Key openKey(String styleId) => Key('progress.writtenCourse.$styleId');

  /// Lessons per written course. Each course parser already rejects any
  /// other count, and `written_courses_progress_entry_test` pins these
  /// against the bundled documents, so the numbers cannot drift silently.
  static const Map<String, int> lessonCounts = <String, int>{
    'salsa_shines': 48,
    'hip_hop_foundations': 8,
    'line_dance': 12,
    'latin_fusion_fitness': 10,
    'tiktok_format': 10,
  };

  @override
  Widget build(BuildContext context) {
    final List<LibraryEntry> others = entries
        .where((LibraryEntry e) =>
            e.id != 'salsa_shines' && WrittenCourseLink.supports(e.id))
        .toList(growable: false);
    final int languages = ChoreiaLocaleController.supported.length;
    final bool tr = UiLanguage.isTurkish(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(UiLanguage.text(context, en: 'Written courses', tr: 'Yazılı kurslar'),
            style: ChoreiaType.of(context).display(size: 22)),
        const SizedBox(height: 4),
        Text(
          UiLanguage.format(context,
              en: '{courses} written courses · {lessons} lessons · {languages} languages',
              tr: '{courses} yazılı kurs · {lessons} ders · {languages} dil',
              values: <String, Object>{
                'courses': lessonCounts.length,
                'lessons': lessonCounts.values.fold(0, (a, b) => a + b),
                'languages': languages,
              }),
          key: summaryKey,
          style: ChoreiaType.of(context)
              .body(size: 12.5, color: ChoreiaPalette.of(context).text(0.6)),
        ),
        const SizedBox(height: 12),
        SalsaCourseEntry(env: env),
        for (final LibraryEntry e in others) ...<Widget>[
          const SizedBox(height: 10),
          GlassPanel(
            radius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  UiLanguage.text(context,
                      en: StyleContentCopy.styleName(e, turkish: false),
                      tr: StyleContentCopy.styleName(e, turkish: tr)),
                  style: ChoreiaType.of(context).display(size: 21),
                ),
                const SizedBox(height: 6),
                Text(
                  UiLanguage.format(context,
                      en: '{lessons} lessons · {languages} languages',
                      tr: '{lessons} ders · {languages} dil',
                      values: <String, Object>{
                        'lessons': lessonCounts[e.id] ?? 0,
                        'languages': languages,
                      }),
                  style: ChoreiaType.of(context).body(),
                ),
                const SizedBox(height: 8),
                WrittenCourseLink(
                    styleId: e.id, env: env, buttonKey: openKey(e.id)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
