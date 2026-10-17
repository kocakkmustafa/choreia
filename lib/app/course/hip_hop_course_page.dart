import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui_language.dart';
import '../live/live_environment.dart';
import 'written_unit_practice.dart';
import 'hip_hop_course.dart';
import 'practice_music_notice.dart';

class HipHopCoursePage extends StatefulWidget {
  const HipHopCoursePage(
      {this.bundle,
      this.skillCourse = false,
      this.env = const LiveEnvironment(),
      super.key});
  final bool skillCourse;
  final AssetBundle? bundle;
  final LiveEnvironment env;

  @override
  State<HipHopCoursePage> createState() => _HipHopCoursePageState();
}

class _HipHopCoursePageState extends State<HipHopCoursePage> {
  late Future<HipHopCourse> _course;

  @override
  void initState() {
    super.initState();
    _course = _load()..ignore();
  }

  @override
  void didUpdateWidget(covariant HipHopCoursePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skillCourse != widget.skillCourse ||
        oldWidget.bundle != widget.bundle) {
      _course = _load()..ignore();
    }
  }

  // Observe immediately: a retry can fail before FutureBuilder rebuilds.
  // The original future still delivers its error to the reader UI.
  Future<HipHopCourse> _load() async {
    // Capture the request's mode before I/O; a later widget update cannot
    // reinterpret an old response as another curriculum.
    final skillCourse = widget.skillCourse;
    final bundle = widget.bundle ?? rootBundle;
    final source = await bundle
        .loadString(skillCourse
            ? 'content/hip_hop_foundations_skill_course.json'
            : 'content/hip_hop_foundations_course.json')
        .timeout(const Duration(seconds: 10));
    return HipHopCourse.decode(source, skillCourse: skillCourse);
  }

  @override
  Widget build(BuildContext context) {
    final tr = UiLanguage.isTurkish(context);
    final lang = tr ? 'tr' : 'en';
    final labels = <String, String>{
      'provenance': tr ? 'Kaynaklar ve sınırlar' : 'Sources and limits',
      'reviewNotice': tr ? 'İnceleme durumu' : 'Review status',
      'boundaries': tr ? 'Her denemeden önce' : 'Before every attempt',
      'startCompetency': tr ? 'Başlangıç' : 'Starting point',
      'endCompetency': tr ? 'Hedef' : 'Target',
      'prerequisite': tr ? 'Ön koşul' : 'Prerequisite',
      'outcome': tr ? 'Bu aşamanın hedefi' : 'Stage target',
      'instruction': tr ? 'Öğren' : 'Learn',
      'practice': tr ? 'Çalış' : 'Practise',
      'mistakes': tr ? 'Yaygın hatalar ve dönüş' : 'Common mistakes and reset',
      'adaptation': tr ? 'Daha düşük yük seçeneği' : 'Lower-impact option',
      'check': tr ? 'Öz kontrol ve tekrar' : 'Self-check and revisit',
    };
    Widget section(String field, Map<String, Map<String, String>> copy) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labels[field]!,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(copy[field]![lang]!),
            ],
          ),
        );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.skillCourse
            ? (tr ? 'Hip-Hop kurs adayı' : 'Hip-Hop course candidate')
            : (tr ? 'Hip-Hop yazılı yolu' : 'Hip-Hop written path')),
      ),
      body: FutureBuilder<HipHopCourse>(
        future: _course,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tr
                          ? 'Yazılı yol okunamadı. İlerleme kaydedilmedi.'
                          : 'The written path could not be read. No progress was recorded.',
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _course = _load()..ignore();
                      }),
                      child: Text(tr ? 'Tekrar dene' : 'Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          // FutureBuilder retains old data briefly when its future changes.
          // Never render a prior mode while the new request is pending.
          final course = snapshot.connectionState == ConnectionState.done
              ? snapshot.data
              : null;
          if (course == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                course.copy['title']![lang]!,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              for (final field in course.displayFields.where(
                (f) => f != 'title',
              ))
                section(field, course.copy),
              PracticeMusicNotice(turkish: tr),
              for (final unit in course.units)
                Card(
                  child: ExpansionTile(
                    key: ValueKey(unit.id),
                    title: Text(unit.copy['title']![lang]!),
                    childrenPadding: const EdgeInsets.all(16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WrittenUnitPractice(
                        key: ValueKey('written.practice.${unit.id}'),
                        courseId: widget.skillCourse
                            ? 'hip_hop_foundations_skill_course'
                            : 'hip_hop_foundations_beginner',
                        version: 1,
                        unitId: unit.id,
                        bundle: widget.bundle ?? rootBundle,
                        env: widget.env,
                      ),
                      const SizedBox(height: 12),
                      for (final field in HipHopUnit.fields.where(
                        (f) => f != 'title',
                      ))
                        section(field, unit.copy),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
