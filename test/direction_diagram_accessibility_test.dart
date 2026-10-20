import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:choreia/app/course/line_dance_direction_diagram.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

const _description = 'Top-down direction map: front upward, your own right '
    'on the right, left on the left. Not a movement demonstration.';
const _ink = Color(0xff112233);
const _accent = Color(0xff0066ff);

Widget _screen(Widget child,
        {double scale = 1,
        TextScaler? scaler,
        TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      locale: const Locale('en'),
      theme: ThemeData(
        colorScheme: const ColorScheme.light(onSurface: _ink, primary: _accent),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: scaler ?? TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Directionality(textDirection: direction, child: child),
        ),
      ),
    );

void _narrowViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Finder _canvas(String id) => find.byKey(ValueKey('lineDance.$id.canvas'));
Finder _scroll(String id) => find.byKey(ValueKey('lineDance.$id.scroll'));

ScrollController _controller(WidgetTester tester, String id) =>
    tester.widget<SingleChildScrollView>(_scroll(id)).controller!;

// Rasterize the actual widget's painter at its actual laid-out size. This
// checks canvas scaling and physical axes, without a font-dependent golden.
Future<Uint8List> _raster(WidgetTester tester, String id) async {
  final painter = tester.widget<CustomPaint>(_canvas(id)).painter!;
  final size = tester.getSize(_canvas(id));
  return (await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.ceil(), size.height.ceil());
    try {
      final bytes =
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      return Uint8List.fromList(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    } finally {
      image.dispose();
      picture.dispose();
    }
  }))!;
}

bool _hasAccent(Uint8List pixels, Size size, Offset point) {
  final width = size.width.ceil();
  final height = size.height.ceil();
  for (var y = point.dy.floor() - 3; y <= point.dy.ceil() + 3; y++) {
    for (var x = point.dx.floor() - 3; x <= point.dx.ceil() + 3; x++) {
      if (x < 0 || y < 0 || x >= width || y >= height) continue;
      final index = (y * width + x) * 4;
      if (pixels[index] == 0 &&
          pixels[index + 1] == 0x66 &&
          pixels[index + 2] == 0xff &&
          pixels[index + 3] > 0) {
        return true;
      }
    }
  }
  return false;
}

int _frontLabelHeight(Uint8List pixels, Size size, double scale) {
  final width = size.width.ceil();
  var first = size.height.ceil();
  var last = -1;
  // FRONT is above y=30 in normalized coordinates; the arrow starts at y=38.
  for (var y = 0; y < (30 * scale).floor(); y++) {
    for (var x = 0; x < width; x++) {
      if (pixels[(y * width + x) * 4 + 3] == 0) continue;
      if (y < first) first = y;
      if (y > last) last = y;
    }
  }
  expect(last, greaterThanOrEqualTo(first), reason: 'FRONT must be painted');
  return last - first + 1;
}

Future<void> _accessibleScroll(WidgetTester tester, String id) async {
  final controller = _controller(tester, id);
  expect(controller.position.axisDirection, AxisDirection.right);
  expect(controller.offset, 0);
  expect(controller.position.maxScrollExtent, greaterThan(0));
  // Scroll chrome can resolve to a semantics ancestor without scroll actions.
  // Find the action owner within this keyed viewport, excluding sibling maps.
  final actionOwner = find.descendant(
    of: _scroll(id),
    matching: find.byElementPredicate((element) {
      if (element is! RenderObjectElement) {
        return false;
      }
      final data = element.renderObject.debugSemantics?.getSemanticsData();
      return data?.hasAction(SemanticsAction.scrollLeft) ?? false;
    }),
  );
  expect(actionOwner, findsOneWidget);
  final target = tester.getSemantics(actionOwner);
  final accessible = find.semantics.byPredicate((node) => node.id == target.id);
  expect(accessible.evaluate(), hasLength(1));
  expect(target.getSemanticsData().flagsCollection.isHidden, isFalse);
  expect(
      accessible
          .evaluate()
          .single
          .getSemanticsData()
          .hasAction(SemanticsAction.scrollLeft),
      isTrue);
  tester.semantics.scrollLeft(scrollable: accessible);
  await tester.pumpAndSettle();
  expect(controller.offset, greaterThan(0));
  controller.jumpTo(0);
  await tester.pump();
  await tester.drag(_scroll(id), const Offset(-150, 0));
  await tester.pumpAndSettle();
  expect(controller.offset, greaterThan(0));
  controller.jumpTo(controller.position.maxScrollExtent);
  await tester.pump();
  expect(tester.getRect(_canvas(id)).right,
      closeTo(tester.getRect(_scroll(id)).right, 0.01),
      reason: 'the far physical edge must be reachable without clipping');
}

void main() {
  testWidgets('normal and smaller text preserve finite maps without scrolling',
      (tester) async {
    _narrowViewport(tester);
    for (final scale in [1.0, 0.75]) {
      for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
        await tester.pumpWidget(_screen(
          const Column(children: [
            LineDanceDirectionDiagram(turkish: false),
            LineDanceWallMaps(turkish: false),
          ]),
          scale: scale,
          direction: direction,
        ));
        await tester.pumpAndSettle();
        expect(tester.getSize(_canvas('direction')),
            Size(320 * scale, 160 * scale));
        for (final id in [
          'direction',
          'wall.12',
          'wall.9',
          'wall.6',
          'wall.3'
        ]) {
          expect(_controller(tester, id).position.maxScrollExtent, 0);
          expect(tester.getSize(_canvas(id)).height,
              (id == 'direction' ? 160 : 200) * scale);
        }
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('320px 3x direction map enlarges text, scrolls and never mirrors',
      (tester) async {
    _narrowViewport(tester);
    final semantics = tester.ensureSemantics();
    try {
      await tester
          .pumpWidget(_screen(const LineDanceDirectionDiagram(turkish: false)));
      final normalSize = tester.getSize(_canvas('direction'));
      final normalTextHeight =
          _frontLabelHeight(await _raster(tester, 'direction'), normalSize, 1);
      Uint8List? ltrPixels;
      for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
        await tester.pumpWidget(_screen(
          const LineDanceDirectionDiagram(turkish: false),
          scale: 3,
          direction: direction,
        ));
        await tester.pumpAndSettle();
        final size = tester.getSize(_canvas('direction'));
        expect(size, const Size(960, 480));
        final pixels = await _raster(tester, 'direction');
        expect(_frontLabelHeight(pixels, size, 3),
            closeTo(normalTextHeight * 3, 4));
        if (ltrPixels == null) {
          ltrPixels = pixels;
        } else {
          expect(pixels, orderedEquals(ltrPixels),
              reason:
                  'RTL may shape labels; it must not reflect the physical map');
        }
        final description = tester
            .getSemantics(find.bySemanticsLabel(_description))
            .getSemanticsData();
        expect(description.flagsCollection.isImage, isTrue);
        expect(description.label, _description);
        await _accessibleScroll(tester, 'direction');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('320px 3x wall maps keep room axes and accessible scrolling',
      (tester) async {
    _narrowViewport(tester);
    final semantics = tester.ensureSemantics();
    try {
      final ltrPixels = <String, Uint8List>{};
      for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
        await tester.pumpWidget(_screen(const LineDanceWallMaps(turkish: false),
            scale: 3, direction: direction));
        await tester.pumpAndSettle();
        for (final facing in ['12', '9', '6', '3']) {
          final id = 'wall.$facing';
          final size = tester.getSize(_canvas(id));
          final viewportWidth = tester.getSize(_scroll(id)).width;
          expect(size.width, closeTo(viewportWidth * 3, 0.01));
          expect(size.height, 600);
          final pixels = await _raster(tester, id);
          final forward = switch (facing) {
            '9' => const Offset(-1, 0),
            '6' => const Offset(0, 1),
            '3' => const Offset(1, 0),
            _ => const Offset(0, -1),
          };
          final centre = Offset(size.width / 2, 300);
          expect(_hasAccent(pixels, size, centre + forward * 120), isTrue,
              reason: 'facing $facing must point toward its fixed room wall');
          expect(_hasAccent(pixels, size, centre - forward * 120), isFalse);
          if (!ltrPixels.containsKey(facing)) {
            ltrPixels[facing] = pixels;
          } else {
            expect(pixels, orderedEquals(ltrPixels[facing]!));
          }
        }
        await _accessibleScroll(tester, 'wall.12');
        const summary = 'Front 12 • Right 3 • Left 9 • Back 6';
        final summaryText = find.text(summary);
        await Scrollable.ensureVisible(tester.element(summaryText));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel(RegExp(RegExp.escape(summary))),
            findsOneWidget);
        expect(find.text('12/9/6/3 label the floor; they are not beat counts.'),
            findsNWidgets(4));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('nonlinear scaling uses each painter font size', (tester) async {
    _narrowViewport(tester);
    await tester.pumpWidget(_screen(
      const Column(children: [
        LineDanceDirectionDiagram(turkish: false),
        LineDanceWallMaps(turkish: false),
      ]),
      scaler: const _NonlinearScaler(),
    ));
    await tester.pumpAndSettle();
    expect(tester.getSize(_canvas('direction')).height, 480,
        reason: '14px direction labels use the 3x part of this text scaler');
    for (final facing in ['12', '9', '6', '3']) {
      expect(tester.getSize(_canvas('wall.$facing')).height, 400,
          reason: '16px wall labels use the 2x part of this text scaler');
    }
    expect(tester.takeException(), isNull);
  });
}

class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();

  @override
  double scale(double fontSize) => fontSize * (fontSize <= 14 ? 3 : 2);

  @override
  double get textScaleFactor => 3;
}
