import 'dart:convert';

import 'package:choreia/app/course/media/choreia_source_projection_pin.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<int>> _bundledBytes(String path) async {
  final data = await rootBundle.load(path);
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shipping course and source projection match app-owned pins', () async {
    final courseBytes =
        await _bundledBytes(ChoreiaSourceProjectionPin.coursePath);
    final sliceBytes =
        await _bundledBytes(ChoreiaSourceProjectionPin.slicePath);
    final projectionBytes =
        await _bundledBytes(ChoreiaSourceProjectionPin.projectionPath);
    expect(sha256.convert(courseBytes).toString(),
        ChoreiaSourceProjectionPin.courseSha256);
    expect(sha256.convert(sliceBytes).toString(),
        ChoreiaSourceProjectionPin.sliceSha256);
    expect(sha256.convert(projectionBytes).toString(),
        ChoreiaSourceProjectionPin.projectionSha256);

    final course = jsonDecode(utf8.decode(courseBytes)) as Map<String, dynamic>;
    final slice = jsonDecode(utf8.decode(sliceBytes)) as Map<String, dynamic>;
    final projection =
        jsonDecode(utf8.decode(projectionBytes)) as Map<String, dynamic>;
    expect((course['lessons'] as List).length,
        ChoreiaSourceProjectionPin.lessonCount);
    expect(projection['appId'], ChoreiaSourceProjectionPin.appId);
    expect(slice['appId'], ChoreiaSourceProjectionPin.appId);
    expect(
        slice['courseSourceSHA256'], ChoreiaSourceProjectionPin.courseSha256);
    expect((slice['lessons'] as List).length,
        ChoreiaSourceProjectionPin.lessonCount);
    expect(projection['courseSourceSHA256'],
        ChoreiaSourceProjectionPin.courseSha256);
    expect(projection['sourceCatalogSHA256'],
        ChoreiaSourceProjectionPin.sourceCatalogSha256);
    expect(projection['sourceManifestSHA256'],
        ChoreiaSourceProjectionPin.sourceManifestSha256);

    final rows = projection['rows'] as List;
    expect(rows.length, ChoreiaSourceProjectionPin.variantCount);
    expect(rows.map((row) => (row as List)[1]).toSet().length,
        ChoreiaSourceProjectionPin.lessonCount);
    expect(rows.map((row) => (row as List)[3]).toSet().length,
        ChoreiaSourceProjectionPin.sceneCount);
    expect(rows.where((row) => (row as List)[10] == true).length,
        ChoreiaSourceProjectionPin.heldCount);
  });
}
