import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Remembers whether the first-run screen has been shown.
///
/// Why a seam and not a direct write
/// ---------------------------------
/// This is the app's FIRST piece of persistence. Nothing else in Choreia
/// writes anything — the progress screen says so in as many words
/// (`HistoryIntegrity.notRecorded`). Putting the write behind an interface
/// keeps that fact honest: a test can prove the screen appears once without
/// touching the filesystem, and the day a real session store arrives it has a
/// pattern to follow rather than a direct `path_provider` call buried in a
/// widget.
///
/// What it deliberately does NOT do: fail loudly. A flag that cannot be read
/// makes the intro appear again, which is mildly annoying; a flag that throws
/// makes the app unopenable. The failure direction is chosen, not accidental.
abstract class FirstRunFlag {
  Future<bool> hasSeenIntro();

  Future<void> markSeen();
}

/// The shipping implementation: one empty file in the app-support directory.
///
/// A file rather than `shared_preferences` because `path_provider` is already
/// a declared dependency and was, until this class existed, imported nowhere —
/// a dependency the app carried without using. One less package to audit for
/// the privacy declaration, too: this writes a zero-byte marker and reads its
/// existence, and there is nothing in it to disclose.
class FileFirstRunFlag implements FirstRunFlag {
  const FileFirstRunFlag();

  static const String _fileName = 'intro_seen';

  Future<File> _marker() async {
    final Directory dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  @override
  Future<bool> hasSeenIntro() async {
    try {
      return (await _marker()).existsSync();
    } on Object {
      // Unreadable storage means "show the intro", never "crash on launch".
      return false;
    }
  }

  @override
  Future<void> markSeen() async {
    try {
      await (await _marker()).create(recursive: true);
    } on Object {
      // The user still gets the app; they may see the intro again next time.
      // Swallowed on purpose, and narrowly: this is the only write.
    }
  }
}

/// In-memory flag for tests and for the intro's own "show me again" path.
class MemoryFirstRunFlag implements FirstRunFlag {
  MemoryFirstRunFlag({bool seen = false}) : _seen = seen;

  bool _seen;

  bool get seen => _seen;

  @override
  Future<bool> hasSeenIntro() async => _seen;

  @override
  Future<void> markSeen() async => _seen = true;
}
