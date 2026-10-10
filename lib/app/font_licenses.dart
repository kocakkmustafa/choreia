import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Exact-version upstream notices for the unmodified bundled font files.
/// Registered once at startup and loaded only when the license page is opened.
void registerBundledFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in const <String, String>{
      'Instrument Serif': 'assets/fonts/OFL-InstrumentSerif.txt',
      'IBM Plex Mono': 'assets/fonts/OFL-IBMPlexMono.txt',
      'Manrope': 'assets/fonts/OFL-Manrope.txt',
    }.entries) {
      yield LicenseEntryWithLineBreaks(
        <String>[entry.key],
        await rootBundle.loadString(entry.value),
      );
    }
  });
}
