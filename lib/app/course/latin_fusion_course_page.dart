import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui_language.dart';
import '../live/live_environment.dart';
import 'written_unit_practice.dart';
import 'latin_fusion_course.dart';
import 'line_dance_direction_diagram.dart';
import 'practice_music_notice.dart';

class LatinFusionCoursePage extends StatefulWidget {
  const LatinFusionCoursePage(
      {this.bundle, this.env = const LiveEnvironment(), super.key});
  final AssetBundle? bundle;
  final LiveEnvironment env;

  @override
  State<LatinFusionCoursePage> createState() => _LatinFusionCoursePageState();
}

class _LatinFusionCoursePageState extends State<LatinFusionCoursePage> {
  late Future<LatinFusionCourse> _course;

  @override
  void initState() {
    super.initState();
    _course = _load()..ignore();
  }

  @override
  void didUpdateWidget(covariant LatinFusionCoursePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bundle != widget.bundle) {
      _course = _load()..ignore();
    }
  }

  // Observe immediately: a retry can fail before FutureBuilder rebuilds.
  // The original future still delivers its error to the reader UI.
  Future<LatinFusionCourse> _load() async {
    final bundle = widget.bundle ?? rootBundle;
    final source = await bundle
        .loadString('content/latin_fusion_beginner_course.json')
        .timeout(const Duration(seconds: 10));
    return LatinFusionCourse.decode(source);
  }

  @override
  Widget build(BuildContext context) {
    final tr = UiLanguage.isTurkish(context);
    final lang = tr ? 'tr' : 'en';
    final labels = <String, String>{
      'scope': UiLanguage.pair(context,
          turkish: tr, en: 'Written scope', tr: 'Yazılı kapsam'),
      'salsaSeparation': UiLanguage.pair(context,
          turkish: tr, en: 'Salsa course boundary', tr: 'Salsa kursuyla sınır'),
      'musicAndObservation': UiLanguage.pair(context,
          turkish: tr,
          en: 'Music and self-observation',
          tr: 'Müzik ve öz gözlem'),
      'exercise': UiLanguage.pair(context,
          turkish: tr, en: 'Solve a new row', tr: 'Yeni satırı çöz'),
      'answer': UiLanguage.pair(context,
          turkish: tr, en: 'Reveal the answer', tr: 'Cevabı göster'),
      'diagramNotice': UiLanguage.pair(context,
          turkish: tr, en: 'Read the diagrams', tr: 'Çizimleri oku'),
      'diagram': UiLanguage.pair(context,
          turkish: tr,
          en: 'Original count and foot map',
          tr: 'Özgün sayı ve ayak haritası'),
      'provenance': UiLanguage.pair(context,
          turkish: tr, en: 'Sources and limits', tr: 'Kaynaklar ve sınırlar'),
      'reviewNotice': UiLanguage.pair(context,
          turkish: tr, en: 'Review status', tr: 'İnceleme durumu'),
      'boundaries': UiLanguage.pair(context,
          turkish: tr, en: 'Before every attempt', tr: 'Her denemeden önce'),
      'startCompetency': UiLanguage.pair(context,
          turkish: tr, en: 'Starting point', tr: 'Başlangıç'),
      'endCompetency':
          UiLanguage.pair(context, turkish: tr, en: 'Target', tr: 'Hedef'),
      'prerequisite': UiLanguage.pair(context,
          turkish: tr, en: 'Prerequisite', tr: 'Ön koşul'),
      'outcome': UiLanguage.pair(context,
          turkish: tr, en: 'Stage target', tr: 'Bu aşamanın hedefi'),
      'instruction':
          UiLanguage.pair(context, turkish: tr, en: 'Learn', tr: 'Öğren'),
      'practice':
          UiLanguage.pair(context, turkish: tr, en: 'Practise', tr: 'Çalış'),
      'mistakes': UiLanguage.pair(context,
          turkish: tr,
          en: 'Common mistakes and reset',
          tr: 'Yaygın hatalar ve dönüş'),
      'adaptation': UiLanguage.pair(context,
          turkish: tr,
          en: 'Lower-impact option',
          tr: 'Daha düşük yük seçeneği'),
      'check': UiLanguage.pair(context,
          turkish: tr,
          en: 'Self-check and revisit',
          tr: 'Öz kontrol ve tekrar'),
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
              Text(UiLanguage.courseText(context, copy[field]!)),
            ],
          ),
        );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          UiLanguage.pair(context,
              turkish: tr,
              en: 'Latin Fusion written foundations',
              tr: 'Latin Fusion yazılı temeller'),
        ),
      ),
      body: FutureBuilder<LatinFusionCourse>(
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
                      UiLanguage.pair(context,
                          turkish: tr,
                          en: 'The written path could not be read. No progress was recorded.',
                          tr: 'Yazılı yol okunamadı. İlerleme kaydedilmedi.'),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _course = _load()..ignore();
                      }),
                      child: Text(UiLanguage.pair(context,
                          turkish: tr, en: 'Retry', tr: 'Tekrar dene')),
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
              for (final field in LatinFusionCourse.fields.where(
                (f) => f != 'title' && f != 'diagramNotice',
              ))
                section(field, course.copy),
              PracticeMusicNotice(turkish: tr),
              LineDanceDirectionDiagram(turkish: tr),
              section('diagramNotice', course.copy),
              Text(
                UiLanguage.pair(context,
                    turkish: tr,
                    en: 'Open physical teaching components',
                    tr: 'Açık fiziksel öğretim bileşenleri'),
              ),
              for (final gap in course.openTeaching)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(UiLanguage.courseText(context, gap)),
                ),
              const SizedBox(height: 16),
              for (final unit in course.units)
                Card(
                  child: ExpansionTile(
                    key: ValueKey(unit.id),
                    title: Text(
                        UiLanguage.courseText(context, unit.copy['title']!)),
                    childrenPadding: const EdgeInsets.all(16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WrittenUnitPractice(
                        key: ValueKey('written.practice.${unit.id}'),
                        courseId: 'latin_fusion_beginner_written',
                        version: 1,
                        unitId: unit.id,
                        bundle: widget.bundle ?? rootBundle,
                        env: widget.env,
                      ),
                      const SizedBox(height: 12),
                      for (final id in unit.patternIds)
                        _PatternTable(
                          pattern: course.patterns[id]!,
                          course: course,
                          lang: lang,
                        ),
                      const SizedBox(height: 12),
                      for (final field in unit.displayFields.where(
                        (f) => f != 'title',
                      ))
                        if (field == 'answer')
                          ExpansionTile(
                            key: const ValueKey('latin.answer'),
                            title: Text(labels[field]!),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(UiLanguage.courseText(
                                    context, unit.copy[field]!)),
                              ),
                            ],
                          )
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

/// Original count/weight/direction ledger, not a foot-contact demonstration.
class _PatternTable extends StatelessWidget {
  const _PatternTable({
    required this.pattern,
    required this.course,
    required this.lang,
  });
  final LatinFusionPattern pattern;
  final LatinFusionCourse course;
  final String lang;
  @override
  Widget build(BuildContext context) {
    final tr = lang == 'tr';
    final headings = [
      UiLanguage.pair(context, turkish: tr, en: 'Count', tr: 'Sayı'),
      UiLanguage.pair(context, turkish: tr, en: 'Foot', tr: 'Ayak'),
      UiLanguage.pair(context, turkish: tr, en: 'Action', tr: 'Eylem'),
      UiLanguage.pair(context, turkish: tr, en: 'Direction', tr: 'Yön'),
      UiLanguage.pair(context, turkish: tr, en: 'Support', tr: 'Destek'),
    ];
    Widget cell(String text) =>
        Padding(padding: const EdgeInsets.all(4), child: Text(text));
    String action(String value) => switch (value) {
          'W' =>
            UiLanguage.pair(context, turkish: tr, en: 'Weight', tr: 'Ağırlık'),
          'T' =>
            UiLanguage.pair(context, turkish: tr, en: 'Touch', tr: 'Dokun'),
          'H' => UiLanguage.pair(context, turkish: tr, en: 'Hold', tr: 'Durak'),
          'P_bend' => UiLanguage.pair(context,
              turkish: tr, en: 'Tiny bend', tr: 'Küçük bük'),
          _ =>
            UiLanguage.pair(context, turkish: tr, en: 'Release', tr: 'Bırak'),
        };
    return Padding(
      key: ValueKey('latin.pattern.${pattern.id}'),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${pattern.id}: ${UiLanguage.courseText(context, pattern.copy['title']!)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(UiLanguage.courseText(context, pattern.copy['originality']!)),
          const SizedBox(height: 8),
          Text(
            UiLanguage.pair(context,
                turkish: tr,
                en: 'Facing FRONT. Support AFTER action. L left, R right, B both feet.',
                tr: 'ÖN bakış. Destek eylemden SONRA. L sol, R sağ, B iki ayak.'),
          ),
          const SizedBox(height: 6),
          Text(
            UiLanguage.pair(context,
                turkish: tr,
                en: 'Five columns: swipe sideways when needed.',
                tr: 'Beş sütun: gerekiyorsa yana kaydır.'),
          ),
          LayoutBuilder(builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
            final width = constraints.maxWidth
                .clamp(480 * scale, double.infinity)
                .toDouble();
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                  width: width,
                  child: Table(
                    border:
                        TableBorder.all(color: Theme.of(context).dividerColor),
                    columnWidths: const {
                      0: FlexColumnWidth(.65),
                      1: FlexColumnWidth(.8),
                      2: FlexColumnWidth(1.15),
                      3: FlexColumnWidth(1.55),
                      4: FlexColumnWidth(1),
                    },
                    children: [
                      TableRow(children: headings.map(cell).toList()),
                      for (final row in pattern.rows)
                        TableRow(
                          children: [
                            cell('${row['count']}'),
                            cell(
                              row['foot'] == 'BOTH'
                                  ? (UiLanguage.pair(context,
                                      turkish: tr, en: 'Both', tr: 'İki ayak'))
                                  : row['foot'] as String,
                            ),
                            cell(action(row['action'] as String)),
                            cell(UiLanguage.courseText(
                                context, course.directions[row['direction']]!)),
                            cell(row['supportAfter'] as String),
                          ],
                        ),
                    ],
                  )),
            );
          }),
        ],
      ),
    );
  }
}
