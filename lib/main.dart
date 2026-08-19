import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/shell/choreia_shell.dart';
import 'app/theme.dart';

/// Choreia's entry point.
///
/// Until 2026-08-07 this file WAS the app: it opened one hardcoded lesson's
/// live path and nothing else, with its own comment explaining why — "building
/// [a navigation shell] around an unverified chain would be decorating
/// something that does not work." The chain was verified in `b9e448e`, so the
/// shell exists now and this file is back to what an entry point should be: a
/// theme and a first screen.
///
/// CHO-P0-002: `GoogleFonts.config.allowRuntimeFetching` kapatır — üç aile
/// artık `assets/fonts/` altında bundle (`pubspec.yaml`, `tool/
/// fetch_fonts.sh`, lissom L-348/LIS-P0-002 ile aynı desen). Kapatılmadan
/// önce ölçüldü: baseline'ın kendi §1'i "google_fonts runtime bağımlılığı"nı
/// GERÇEK bir ağ davranışı olarak listeliyordu, icat edilmiş bir kusur
/// değil.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const ChoreiaApp());
}

class ChoreiaApp extends StatelessWidget {
  const ChoreiaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Choreia',
        theme: ChoreiaTheme.dark,
        home: const ChoreiaShell(),
      );
}
