import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui_language.dart';
import 'line_dance_course.dart';
import 'line_dance_direction_diagram.dart';
import 'practice_music_notice.dart';

class LineDanceCoursePage extends StatefulWidget {
  const LineDanceCoursePage({this.bundle, super.key});
  final AssetBundle? bundle;

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
    final lang = tr ? 'tr' : 'en';
    final labels = <String, String>{
      'exercise': tr ? 'Yeni satırı çöz' : 'Solve a new row',
      'answer': tr ? 'Cevabı göster' : 'Reveal the answer',
      'diagramNotice': tr ? 'Çizimleri oku' : 'Read the diagrams',
      'diagram':
          tr ? 'Özgün sayı ve ayak haritası' : 'Original count and foot map',
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
        title:
            Text(tr ? 'Line Dance yazılı kursu' : 'Line Dance written course'),
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
                    title: Text(unit.copy['title']![lang]!),
                    childrenPadding: const EdgeInsets.all(16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                    child: Text(unit.copy[field]![lang]!))
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
