import 'package:flutter/material.dart';
import '../ui_language.dart';

/// Original repo-native symbolic map, never a movement demonstration.
class LineDanceDirectionDiagram extends StatelessWidget {
  const LineDanceDirectionDiagram({required this.turkish, super.key});
  final bool turkish;
  @override
  Widget build(BuildContext context) => Semantics(
        label: UiLanguage.pair(context,
            turkish: turkish,
            en: 'Top-down direction map: front upward, your own right on the right, left on the left. Not a movement demonstration.',
            tr: 'Üstten yön haritası: ön yukarı, kendi sağın sağda, solun solda. Hareket gösterimi değildir.'),
        image: true,
        child: _ScalableDiagram(
            id: 'direction',
            height: 160,
            fontSize: 14,
            painter: (scale) => _DirectionPainter({
              'front': UiLanguage.pair(context,
                  turkish: turkish, en: 'FRONT', tr: 'ÖN'),
              'back': UiLanguage.pair(context,
                  turkish: turkish, en: 'BACK', tr: 'ARKA'),
              'left': UiLanguage.pair(context,
                  turkish: turkish, en: 'LEFT', tr: 'SOL'),
              'right': UiLanguage.pair(context,
                  turkish: turkish, en: 'RIGHT', tr: 'SAĞ'),
            }, Directionality.of(context),
                    Theme.of(context).colorScheme.onSurface, scale)),
      );
}

class _DirectionPainter extends CustomPainter {
  _DirectionPainter(this.labels, this.direction, this.color, this.scale);
  final Map<String, String> labels;
  final TextDirection direction;
  final Color color;
  final double scale;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);
    size = Size(size.width / scale, size.height / scale);
    final centre = Offset(size.width / 2, 80);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    void arrow(Offset start, Offset end) {
      canvas.drawLine(start, end, paint);
      final vector = end - start;
      final norm = vector / vector.distance;
      final side = Offset(-norm.dy, norm.dx);
      canvas.drawLine(end, end - norm * 7 + side * 4, paint);
      canvas.drawLine(end, end - norm * 7 - side * 4, paint);
    }

    arrow(centre, const Offset(0, -42) + centre);
    arrow(centre, const Offset(0, 42) + centre);
    final travel = (size.width / 2 - 54).clamp(35.0, 100.0);
    arrow(centre, centre + Offset(travel, 0));
    arrow(centre, centre - Offset(travel, 0));
    void label(String value, Offset position) {
      final tp = TextPainter(
          text: TextSpan(
              text: value,
              style:
                  TextStyle(color: color, fontSize: 14, fontFamily: 'Manrope')),
          textDirection: direction)
        ..layout();
      final x = (position.dx - tp.width / 2)
          .clamp(0.0, (size.width - tp.width).clamp(0.0, double.infinity))
          .toDouble();
      tp.paint(canvas, Offset(x, position.dy - tp.height / 2));
    }

    // Canvas coordinates describe the dancer's own axes. RTL changes label
    // shaping only; it must never mirror physical left/right or clock faces.
    label(labels['front']!, Offset(centre.dx, 17));
    label(labels['back']!, Offset(centre.dx, 143));
    label(labels['left']!, Offset(27, 80));
    label(labels['right']!, Offset(size.width - 27, 80));
    canvas.drawOval(
        Rect.fromCenter(
            center: centre + const Offset(-9, 15), width: 9, height: 16),
        paint);
    canvas.drawOval(
        Rect.fromCenter(
            center: centre + const Offset(9, 15), width: 9, height: 16),
        paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DirectionPainter oldDelegate) =>
      labels.entries
          .any((entry) => oldDelegate.labels[entry.key] != entry.value) ||
      oldDelegate.direction != direction ||
      oldDelegate.color != color ||
      oldDelegate.scale != scale;
}

/// Original room-facing maps. The room labels stay fixed; own-limb axes rotate.
class LineDanceWallMaps extends StatelessWidget {
  const LineDanceWallMaps({required this.turkish, super.key});
  final bool turkish;
  @override
  Widget build(BuildContext context) => Column(children: [
        for (final row in const [
          ['12', '12', '3', '9', '6'],
          ['9', '9', '12', '6', '3'],
          ['6', '6', '9', '3', '12'],
          ['3', '3', '6', '12', '9'],
        ])
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    Text(
                        UiLanguage.format(context,
                            en: 'Facing {facing}: your own-limb directions',
                            tr: 'Bakış {facing}: kendi uzuv yönlerin',
                            values: {'facing': row[0]}),
                        style: Theme.of(context).textTheme.titleSmall),
                    _ScalableDiagram(
                        id: 'wall.${row[0]}',
                        height: 200,
                        fontSize: 16,
                        painter: (scale) => _WallPainter(
                                row[0],
                                Theme.of(context).colorScheme.onSurface,
                                Theme.of(context).colorScheme.primary, scale)),
                    Text(UiLanguage.format(context,
                        en: 'Front {front} • Right {right} • Left {left} • Back {back}',
                        tr: 'Ön {front} • Sağ {right} • Sol {left} • Arka {back}',
                        values: {
                          'front': row[1],
                          'right': row[2],
                          'left': row[3],
                          'back': row[4]
                        })),
                    Text(UiLanguage.pair(context,
                        turkish: turkish,
                        en: '12/9/6/3 label the floor; they are not beat counts.',
                        tr: '12/9/6/3 zemin etiketidir; vuruş sayısı değildir.')),
                  ]))),
      ]);
}

class _WallPainter extends CustomPainter {
  _WallPainter(this.facing, this.ink, this.accent, this.scale);
  final String facing;
  final Color ink, accent;
  final double scale;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);
    size = Size(size.width / scale, size.height / scale);
    final c = Offset(size.width / 2, 100);
    final forward = switch (facing) {
      '9' => const Offset(-1, 0),
      '6' => const Offset(0, 1),
      '3' => const Offset(1, 0),
      _ => const Offset(0, -1)
    };
    final right = Offset(-forward.dy, forward.dx);
    final p = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    void arrow(Offset direction, double distance) {
      final e = c + direction * distance;
      canvas.drawLine(c, e, p);
      final side = Offset(-direction.dy, direction.dx);
      canvas.drawLine(e, e - direction * 8 + side * 5, p);
      canvas.drawLine(e, e - direction * 8 - side * 5, p);
    }

    arrow(forward, 55);
    p
      ..color = ink
      ..strokeWidth = 1.5;
    arrow(right, 35);
    void label(String value, Offset at) {
      final t = TextPainter(
          text: TextSpan(
              text: value,
              style:
                  TextStyle(color: ink, fontFamily: 'Manrope', fontSize: 16)),
          textDirection: TextDirection.ltr)
        ..layout();
      t.paint(canvas, at - Offset(t.width / 2, t.height / 2));
    }

    label('12', Offset(c.dx, 12));
    label('6', Offset(c.dx, 188));
    label('9', Offset(15, 100));
    label('3', Offset(size.width - 15, 100));
    label('L', c - right * 13 - forward * 16);
    label('R', c + right * 13 - forward * 16);
    // Foot symbols distinguish own sides; they do not encode foot angles/contact.
    canvas.drawCircle(c - right * 13, 5, p);
    canvas.drawCircle(c + right * 13, 5, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WallPainter oldDelegate) =>
      oldDelegate.facing != facing ||
      oldDelegate.ink != ink ||
      oldDelegate.accent != accent ||
      oldDelegate.scale != scale;
}

/// Scale the whole notation, including custom-painted text, without changing
/// its physical axes. A wide map scrolls from the same left edge in every UI.
class _ScalableDiagram extends StatefulWidget {
  const _ScalableDiagram({
    required this.id,
    required this.height,
    required this.fontSize,
    required this.painter,
  });

  final String id;
  final double height, fontSize;
  final CustomPainter Function(double scale) painter;

  @override
  State<_ScalableDiagram> createState() => _ScalableDiagramState();
}

class _ScalableDiagramState extends State<_ScalableDiagram> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final requestedScale =
              MediaQuery.textScalerOf(context).scale(widget.fontSize) /
                  widget.fontSize;
          final scale = requestedScale.isFinite && requestedScale > 0
              ? requestedScale
              : 1.0;
          final width =
              constraints.hasBoundedWidth ? constraints.maxWidth : 320.0;
          final scrolls = width * scale > width;
          return SizedBox(
            width: width,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: scrolls,
                interactive: true,
                scrollbarOrientation: ScrollbarOrientation.bottom,
                child: SingleChildScrollView(
                  key: ValueKey('lineDance.${widget.id}.scroll'),
                  controller: _scrollController,
                  primary: false,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.only(bottom: scrolls ? 16 : 0),
                  child: SizedBox(
                    width: width * scale,
                    height: widget.height * scale,
                    child: CustomPaint(
                      key: ValueKey('lineDance.${widget.id}.canvas'),
                      painter: widget.painter(scale),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

/// Explicit weight ledger: T never changes the support foot.
class LineDanceWeightLedger extends StatelessWidget {
  const LineDanceWeightLedger(
      {required this.unitId, required this.turkish, super.key});
  final String unitId;
  final bool turkish;
  @override
  Widget build(BuildContext context) {
    final pattern = unitId == 'ld_02'
        ? const ['RW', 'LT', 'LW', 'RT']
        : unitId == 'ld_08'
            ? const ['RW', 'LW', 'RW', 'LW', 'RW', 'LW', 'RW', 'LW']
            : const ['RW', 'LW', 'RW', 'LT', 'LW', 'RW', 'LW', 'RT'];
    var support = 'L';
    final rows = <TableRow>[];
    String foot(String value) => UiLanguage.pair(context,
        turkish: turkish,
        en: value == 'R' ? 'Right' : 'Left',
        tr: value == 'R' ? 'Sağ' : 'Sol');
    rows.add(TableRow(children: [
      for (final label in [
        UiLanguage.pair(context, turkish: turkish, en: 'Beat', tr: 'Sayı'),
        UiLanguage.pair(context, turkish: turkish, en: 'Foot', tr: 'Ayak'),
        UiLanguage.pair(context, turkish: turkish, en: 'Action', tr: 'Eylem'),
        UiLanguage.pair(context, turkish: turkish, en: 'Support', tr: 'Destek'),
      ])
        Padding(padding: const EdgeInsets.all(4), child: Text(label))
    ]));
    for (var n = 0; n < pattern.length; n++) {
      final step = pattern[n];
      if (step[1] == 'W') support = step[0];
      rows.add(TableRow(children: [
        for (final label in [
          '${n + 1}',
          foot(step[0]),
          step[1] == 'W'
              ? UiLanguage.pair(context,
                  turkish: turkish, en: 'Weight', tr: 'Ağırlık')
              : UiLanguage.pair(context,
                  turkish: turkish, en: 'Touch', tr: 'Dokun'),
          foot(support)
        ])
          Padding(padding: const EdgeInsets.all(4), child: Text(label))
      ]));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(UiLanguage.pair(context,
          turkish: turkish,
          en: 'Touch: no weight transfer. Support is the foot AFTER the action.',
          tr: 'Dokun: ağırlık aktarılmaz. Destek, eylemden SONRAKİ ayaktır.')),
      Table(
          border: TableBorder.all(color: Theme.of(context).colorScheme.outline),
          children: rows)
    ]);
  }
}
