import 'package:flutter/material.dart';

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
void main() => runApp(const ChoreiaApp());

class ChoreiaApp extends StatelessWidget {
  const ChoreiaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Choreia',
        theme: ChoreiaTheme.dark,
        home: const ChoreiaShell(),
      );
}
