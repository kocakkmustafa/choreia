import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/hip_hop_course_page.dart';
import 'package:choreia/app/course/latin_fusion_course_page.dart';
import 'package:choreia/app/course/line_dance_course_page.dart';
import 'package:choreia/app/course/short_form_course_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _RetryBundle extends CachingAssetBundle {
  int reads = 0;
  Completer<String>? pending;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    reads++;
    if (pending != null) return pending!.future;
    throw const FormatException('Unavailable course');
  }

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}

void main() {
  final pages = <String, Widget Function(AssetBundle)>{
    'hip_hop_foundations_course': (bundle) => HipHopCoursePage(bundle: bundle),
    'hip_hop_foundations_skill_course': (bundle) =>
        HipHopCoursePage(bundle: bundle, skillCourse: true),
    'line_dance_beginner_course': (bundle) => LineDanceCoursePage(bundle: bundle),
    'latin_fusion_beginner_course': (bundle) => LatinFusionCoursePage(bundle: bundle),
    'original_short_form_beginner_course': (bundle) => ShortFormCoursePage(bundle: bundle),
  };

  for (final entry in pages.entries) {
    testWidgets('${entry.key}: repeated immediate retry errors stay handled',
        (tester) async {
      final bundle = _RetryBundle();
      await tester.pumpWidget(MaterialApp(home: entry.value(bundle)));
      await tester.pumpAndSettle();
      expect(bundle.reads, 1);
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Retry'), findsOneWidget);
        expect(bundle.reads, i + 2);
      }
    });

    testWidgets('${entry.key}: pending retry hides stale error then recovers',
        (tester) async {
      final bundle = _RetryBundle();
      await tester.pumpWidget(MaterialApp(home: entry.value(bundle)));
      await tester.pumpAndSettle();
      bundle.pending = Completer<String>();
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(bundle.reads, 2);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(bundle.reads, 2);
      final source = File('content/${entry.key}.json').readAsStringSync();
      bundle.pending!.complete(source);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Retry'), findsNothing);
      final title = (jsonDecode(source) as Map<String, dynamic>)['title']['en'];
      expect(find.text(title as String), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
