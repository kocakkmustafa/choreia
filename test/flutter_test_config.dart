import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Runs once before every test file in this directory tree.
///
/// `google_fonts` tries to FETCH its three families at runtime, and under
/// `flutter_test` that request is served by a stub that answers 400 — so a
/// screen styled with `ChoreiaType` prints a font-loading error on every pump
/// and, on a machine where the override behaves differently, can fail outright.
/// This is a family-wide trap, recorded in the shared core: the fix is to tell
/// the package it may not go to the network, once, here.
///
/// The honest limit: this makes tests render with a FALLBACK face, not the
/// design's Instrument Serif / Manrope / IBM Plex Mono. Layout assertions in
/// this suite therefore measure the app's own spacing and wrapping rules, and
/// do NOT prove the shipped typefaces fit — the overflow tests are pinned to a
/// real phone width so they stay a meaningful floor rather than a proof.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
