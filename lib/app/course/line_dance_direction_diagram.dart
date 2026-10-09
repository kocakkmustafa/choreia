import 'package:flutter/material.dart';

/// Original repo-native symbolic map, never a movement demonstration.
class LineDanceDirectionDiagram extends StatelessWidget {
  const LineDanceDirectionDiagram({required this.turkish, super.key});
  final bool turkish;
  @override
  Widget build(BuildContext context) => Semantics(
        label: turkish
            ? 'Üstten yön haritası: ön yukarı, kendi sağın sağda, solun solda. Hareket gösterimi değildir.'
            : 'Top-down direction map: front upward, your own right on the right, left on the left. Not a movement demonstration.',
        image: true,
        child: SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
                painter: _DirectionPainter(
                    turkish, Theme.of(context).colorScheme.onSurface))),
      );
}

class _DirectionPainter extends CustomPainter {
  _DirectionPainter(this.tr, this.color);
  final bool tr;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
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
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, position - Offset(tp.width / 2, tp.height / 2));
    }

    label(tr ? 'ÖN' : 'FRONT', Offset(centre.dx, 17));
    label(tr ? 'ARKA' : 'BACK', Offset(centre.dx, 143));
    label(tr ? 'SOL' : 'LEFT', Offset(27, 80));
    label(tr ? 'SAĞ' : 'RIGHT', Offset(size.width - 27, 80));
    canvas.drawOval(
        Rect.fromCenter(
            center: centre + const Offset(-9, 15), width: 9, height: 16),
        paint);
    canvas.drawOval(
        Rect.fromCenter(
            center: centre + const Offset(9, 15), width: 9, height: 16),
        paint);
  }

  @override
  bool shouldRepaint(covariant _DirectionPainter oldDelegate) =>
      oldDelegate.tr != tr || oldDelegate.color != color;
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
                        turkish
                            ? 'Bakış ${row[0]}: kendi uzuv yönlerin'
                            : 'Facing ${row[0]}: your own-limb directions',
                        style: Theme.of(context).textTheme.titleSmall),
                    SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: CustomPaint(
                            painter: _WallPainter(
                                row[0],
                                Theme.of(context).colorScheme.onSurface,
                                Theme.of(context).colorScheme.primary))),
                    Text(turkish
                        ? 'Ön ${row[1]} • Sağ ${row[2]} • Sol ${row[3]} • Arka ${row[4]}'
                        : 'Front ${row[1]} • Right ${row[2]} • Left ${row[3]} • Back ${row[4]}'),
                    Text(turkish
                        ? '12/9/6/3 zemin etiketidir; vuruş sayısı değildir.'
                        : '12/9/6/3 label the floor; they are not beat counts.'),
                  ]))),
      ]);
}

class _WallPainter extends CustomPainter {
  _WallPainter(this.facing, this.ink, this.accent);
  final String facing;
  final Color ink, accent;
  @override
  void paint(Canvas canvas, Size size) {
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
  }

  @override
  bool shouldRepaint(covariant _WallPainter oldDelegate) =>
      oldDelegate.facing != facing ||
      oldDelegate.ink != ink ||
      oldDelegate.accent != accent;
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
    String foot(String value) =>
        turkish ? (value == 'R' ? 'Sağ' : 'Sol') : value;
    rows.add(TableRow(children: [
      for (final label in turkish
          ? ['Sayı', 'Ayak', 'Eylem', 'Destek']
          : ['Beat', 'Foot', 'Action', 'Support'])
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
              ? (turkish ? 'Ağırlık' : 'Weight')
              : (turkish ? 'Dokun' : 'Touch'),
          foot(support)
        ])
          Padding(padding: const EdgeInsets.all(4), child: Text(label))
      ]));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(turkish
          ? 'Dokun: ağırlık aktarılmaz. Destek, eylemden SONRAKİ ayaktır.'
          : 'Touch: no weight transfer. Support is the foot AFTER the action.'),
      Table(
          border: TableBorder.all(color: Theme.of(context).colorScheme.outline),
          children: rows)
    ]);
  }
}
