import 'package:choreia/app/support_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final surface in SupportSurface.values) {
    testWidgets('${surface.name} support copies only the fixed allowlist after a tap',
        (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body:
          SupportAction(surface: surface))));
      expect(calls.where((call) => call.method == 'Clipboard.setData'), isEmpty);
      await tester.tap(find.byKey(const Key('support.copy')));
      await tester.pump();
      final copied = calls.where((call) => call.method == 'Clipboard.setData');
      expect(copied, hasLength(1));
      expect(copied.single.arguments, <String, Object>{
        'text': 'support@yulalab.com\nApp: Choreia\nSurface: ${surface.name}\nLocale: en',
      });
      expect(find.text('Support details copied.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('clipboard rejection keeps the selectable address and shows recovery',
      (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        throw PlatformException(code: 'clipboard-unavailable');
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body:
        SupportAction(surface: SupportSurface.startup))));
    await tester.tap(find.byKey(const Key('support.copy')));
    await tester.pump();
    expect(find.text('support@yulalab.com'), findsOneWidget);
    expect(find.text('Could not copy. You can select the support address above.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
