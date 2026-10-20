import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui_language.dart';
import '../live/live_environment.dart';
import 'written_unit_practice.dart';
import 'line_dance_course.dart';
import 'line_dance_direction_diagram.dart';
import 'notation_text.dart';
import 'practice_music_notice.dart';

class LineDanceCoursePage extends StatefulWidget {
  const LineDanceCoursePage(
      {this.bundle, this.env = const LiveEnvironment(), super.key});
  final AssetBundle? bundle;
  final LiveEnvironment env;

  @override
  State<LineDanceCoursePage> createState() => _LineDanceCoursePageState();
}

class _LineDanceCoursePageState extends State<LineDanceCoursePage> {
  late Future<LineDanceCourse> _course;

  @override
  void initState() {
    super.initState();
    _course = _load()..ignore();
  }

  @override
  void didUpdateWidget(covariant LineDanceCoursePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bundle != widget.bundle) {
      _course = _load()..ignore();
    }
  }

  // Observe immediately: a retry can fail before FutureBuilder rebuilds.
  // The original future still delivers its error to the reader UI.
  Future<LineDanceCourse> _load() async {
    final bundle = widget.bundle ?? rootBundle;
    final source = await bundle
        .loadString('content/line_dance_beginner_course.json')
        .timeout(const Duration(seconds: 10));
    return LineDanceCourse.decode(source);
  }

  @override
  Widget build(BuildContext context) {
    final tr = UiLanguage.isTurkish(context);
    final labels = <String, String>{
      'exercise': UiLanguage.pair(context, turkish: tr, en: 'Solve a new row', tr: 'Yeni satırı çöz'),
      'answer': UiLanguage.pair(context, turkish: tr, en: 'Reveal the answer', tr: 'Cevabı göster'),
      'diagramNotice': UiLanguage.pair(context, turkish: tr, en: 'Read the diagrams', tr: 'Çizimleri oku'),
      'diagram':
          UiLanguage.pair(context, turkish: tr, en: 'Original count and foot map', tr: 'Özgün sayı ve ayak haritası'),
      'provenance': UiLanguage.pair(context, turkish: tr, en: 'Sources and limits', tr: 'Kaynaklar ve sınırlar'),
      'reviewNotice': UiLanguage.pair(context, turkish: tr, en: 'Review status', tr: 'İnceleme durumu'),
      'boundaries': UiLanguage.pair(context, turkish: tr, en: 'Before every attempt', tr: 'Her denemeden önce'),
      'startCompetency': UiLanguage.pair(context, turkish: tr, en: 'Starting point', tr: 'Başlangıç'),
      'endCompetency': UiLanguage.pair(context, turkish: tr, en: 'Target', tr: 'Hedef'),
      'prerequisite': UiLanguage.pair(context, turkish: tr, en: 'Prerequisite', tr: 'Ön koşul'),
      'outcome': UiLanguage.pair(context, turkish: tr, en: 'Stage target', tr: 'Bu aşamanın hedefi'),
      'instruction': UiLanguage.pair(context, turkish: tr, en: 'Learn', tr: 'Öğren'),
      'practice': UiLanguage.pair(context, turkish: tr, en: 'Practise', tr: 'Çalış'),
      'mistakes': UiLanguage.pair(context, turkish: tr, en: 'Common mistakes and reset', tr: 'Yaygın hatalar ve dönüş'),
      'adaptation': UiLanguage.pair(context, turkish: tr, en: 'Lower-impact option', tr: 'Daha düşük yük seçeneği'),
      'check': UiLanguage.pair(context, turkish: tr, en: 'Self-check and revisit', tr: 'Öz kontrol ve tekrar'),
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
              if (field == 'diagram')
                NotationText(UiLanguage.courseText(context, copy[field]!))
              else
                Text(UiLanguage.courseText(context, copy[field]!)),
            ],
          ),
        );
    return Scaffold(
      appBar: AppBar(
        title:
            Text(UiLanguage.pair(context, turkish: tr, en: 'Line Dance written course', tr: 'Line Dance yazılı kursu')),
      ),
      body: FutureBuilder<LineDanceCourse>(
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
                      UiLanguage.pair(context, turkish: tr, en: 'The written path could not be read. No progress was recorded.', tr: 'Yazılı yol okunamadı. İlerleme kaydedilmedi.'),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _course = _load()..ignore();
                      }),
                      child: Text(UiLanguage.pair(context, turkish: tr, en: 'Retry', tr: 'Tekrar dene')),
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
                UiLanguage.courseText(context, course.copy['title']!),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              for (final field in LineDanceCourse.fields.where(
                (f) => f != 'title',
              ))
                section(field, course.copy),
              PracticeMusicNotice(turkish: tr),
              LineDanceDirectionDiagram(turkish: tr),
              LineDanceWallMaps(turkish: tr),
              const SizedBox(height: 16),
              for (final unit in course.units)
                Card(
                  child: ExpansionTile(
                    key: ValueKey(unit.id),
                    title: Text(UiLanguage.courseText(context, unit.copy['title']!)),
                    childrenPadding: const EdgeInsets.all(16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WrittenUnitPractice(
                        key: ValueKey('written.practice.${unit.id}'),
                        courseId: 'line_dance_beginner_written',
                        version: 2,
                        unitId: unit.id,
                        bundle: widget.bundle ?? rootBundle,
                        env: widget.env,
                      ),
                      const SizedBox(height: 12),
                      if (['ld_02', 'ld_03', 'ld_04', 'ld_08']
                          .contains(unit.id))
                        LineDanceWeightLedger(unitId: unit.id, turkish: tr),
                      const SizedBox(height: 12),
                      for (final field in unit.displayFields.where(
                        (f) => f != 'title',
                      ))
                        if (field == 'answer')
                          ExpansionTile(
                              key: const ValueKey('line.answer'),
                              title: Text(labels[field]!),
                              children: [
                                Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(UiLanguage.courseText(context, unit.copy[field]!)))
                              ])
                        else
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
