import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Exercise the shipped font bytes even under content-only asset fixtures.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final entry in <String, List<String>>{
    'Manrope': ['Manrope-Regular.ttf', 'Manrope-SemiBold.ttf'],
    'Instrument Serif': ['InstrumentSerif-Regular.ttf'],
    'IBM Plex Mono': ['IBMPlexMono-Medium.ttf'],
  }.entries) {
    final loader = FontLoader(entry.key);
    for (final file in entry.value) {
      final bytes = File('assets/fonts/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
    }
    await loader.load();
  }
  await testMain();
}
