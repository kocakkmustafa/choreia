import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:choreia/app/course/salsa_course.dart';

/// Emits one reproducible production packet; performs no network or generation.
void main() {
  final file = File('content/salsa_on1_course.json');
  final bytes = file.readAsBytesSync();
  final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  final course = SalsaCourse.fromJson(data);
  final lessons = (data['lessons'] as List).cast<Map<String, dynamic>>();
  stdout.writeln(const JsonEncoder.withIndent('  ').convert({
    'packetSchemaVersion': 1,
    'courseId': course.id,
    'contentVersion': course.version,
    'contentSha256': sha256.convert(bytes).toString(),
    'status': 'planned_no_assets_generated',
    'assetCount': lessons.length,
    'audio': 'silent; no music rights or tempo evidence supplied',
    'provenance':
        'Original course text. Sources are reading references only, not licensed training media.',
    'releaseGates': [
      'Human dance review of generated anatomy, left/right, step/contact/count sequence and alternatives.',
      'TR/EN caption review and full-body/feet visibility check in both crop formats.',
      'No personal likeness imitation, copied choreography, source footage or soundtrack.',
      'AI-generated demo labeling and source/rights receipts before any asset enters the app.',
      'Generated media is never independent model evaluation or evidence of learner accuracy.',
    ],
    'assets': lessons
        .map((lesson) => {
              'lessonId': lesson['id'],
              'title': lesson['title'],
              'sourceReferenceIds': lesson['sourceIds'],
              'brief': lesson['mediaBrief'],
            })
        .toList(),
  }));
}
