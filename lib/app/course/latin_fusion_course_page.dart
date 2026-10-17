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
      'scope': tr ? 'Yazılı kapsam' : 'Written scope',
      'salsaSeparation': tr ? 'Salsa kursuyla sınır' : 'Salsa course boundary',
      'musicAndObservation': tr
          ? 'Müzik ve öz gözlem'
          : 'Music and self-observation',
      'exercise': tr ? 'Yeni satırı çöz' : 'Solve a new row',
      'answer': tr ? 'Cevabı göster' : 'Reveal the answer',
      'diagramNotice': tr ? 'Çizimleri oku' : 'Read the diagrams',
      'diagram': tr
          ? 'Özgün sayı ve ayak haritası'
          : 'Original count and foot map',
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
        title: Text(
          tr
              ? 'Latin Fusion yazılı temeller'
              : 'Latin Fusion written foundations',
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
                      tr ? 'Yazılı yol okunamadı. İlerleme kaydedilmedi.' : 'The written path could not be read. No progress was recorded.',
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
              for (final field in LatinFusionCourse.fields.where(
                (f) => f != 'title' && f != 'diagramNotice',
              ))
                section(field, course.copy),
              PracticeMusicNotice(turkish: tr),
              LineDanceDirectionDiagram(turkish: tr),
              section('diagramNotice', course.copy),
              Text(
                tr
                    ? 'Açık fiziksel öğretim bileşenleri'
                    : 'Open physical teaching components',
              ),
              for (final gap in course.openTeaching)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(gap[lang]!),
                ),
              const SizedBox(height: 16),
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
                                child: Text(unit.copy[field]![lang]!),
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
    final headings = tr
        ? ['Sayı', 'Ayak', 'Eylem', 'Yön', 'Destek']
        : ['Count', 'Foot', 'Action', 'Direction', 'Support'];
    Widget cell(String text) =>
        Padding(padding: const EdgeInsets.all(4), child: Text(text));
    String action(String value) => switch (value) {
      'W' => tr ? 'Ağırlık' : 'Weight',
      'T' => tr ? 'Dokun' : 'Touch',
      'H' => tr ? 'Durak' : 'Hold',
      'P_bend' => tr ? 'Küçük bük' : 'Tiny bend',
      _ => tr ? 'Bırak' : 'Release',
    };
    return Padding(
      key: ValueKey('latin.pattern.${pattern.id}'),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${pattern.id}: ${pattern.copy['title']![lang]!}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(pattern.copy['originality']![lang]!),
          const SizedBox(height: 8),
          Text(
            tr ? 'ÖN bakış. Destek eylemden SONRA. L sol, R sağ, B iki ayak.' : 'Facing FRONT. Support AFTER action. L left, R right, B both feet.',
          ),
          const SizedBox(height: 6),
          Text(
            tr ? 'Beş sütun: gerekiyorsa yana kaydır.' : 'Five columns: swipe sideways when needed.',
          ),
          LayoutBuilder(builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
            final width = constraints.maxWidth.clamp(480 * scale, double.infinity).toDouble();
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: width, child: Table(
            border: TableBorder.all(color: Theme.of(context).dividerColor),
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
                          ? (tr ? 'İki ayak' : 'Both')
                          : row['foot'] as String,
                    ),
                    cell(action(row['action'] as String)),
                    cell(course.directions[row['direction']]![lang]!),
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
