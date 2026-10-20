import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Only a device appearance preference; never account or practice data.
abstract interface class ChoreiaThemeStore {
  Future<String?> read();
  Future<void> write(String contents);
}

class FileChoreiaThemeStore implements ChoreiaThemeStore {
  const FileChoreiaThemeStore();
  Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/choreia_display_theme.json');
  }

  @override
  Future<String?> read() async {
    final file = await _file();
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String contents) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(contents, flush: true);
    await temporary.rename(file.path);
  }
}

class ChoreiaThemeController extends ValueNotifier<ThemeMode> {
  ChoreiaThemeController.memory([ThemeMode mode = ThemeMode.system])
      : _store = null,
        super(mode);
  ChoreiaThemeController.persisted(
      {ChoreiaThemeStore store = const FileChoreiaThemeStore()})
      : _store = store,
        super(ThemeMode.system);
  final ChoreiaThemeStore? _store;
  bool readFailed = false;
  bool saveFailed = false;
  bool _disposed = false;
  int _revision = 0;
  ThemeMode? _pending;
  Future<void>? _draining;

  /// The entire read has one deadline. Its late result is never applied.
  Future<void> restore(
      {Duration deadline = const Duration(milliseconds: 500)}) async {
    final store = _store;
    if (store == null || _disposed) return;
    final revision = _revision;
    try {
      final contents = await store.read().timeout(deadline);
      if (_disposed || revision != _revision || contents == null) return;
      final raw = jsonDecode(contents);
      if (raw is! Map ||
          raw['schemaVersion'] != 1 ||
          raw['themeMode'] is! String) {
        throw const FormatException('Invalid appearance preference');
      }
      final mode = ThemeMode.values
          .where((mode) => mode.name == raw['themeMode'])
          .firstOrNull;
      if (mode == null) throw const FormatException('Unknown appearance mode');
      readFailed = false;
      value = mode;
    } on Object {
      if (!_disposed && revision == _revision) {
        readFailed = true;
        notifyListeners();
      }
    }
  }

  Future<void> select(ThemeMode mode,
      {Duration deadline = const Duration(seconds: 3)}) {
    if (_disposed) return Future<void>.value();
    final revision = ++_revision;
    readFailed = false;
    saveFailed = false;
    value = mode;
    // Same-mode selection is also a deliberate retry and must clear warnings.
    notifyListeners();
    if (_store == null) return Future<void>.value();
    _pending = mode;
    final operation = _draining ??= _drain();
    return operation.timeout(deadline).catchError((Object _) {
      if (!_disposed && revision == _revision) {
        saveFailed = true;
        notifyListeners();
      }
    });
  }

  Future<void> _drain() async {
    // Assign the shared future before even a synchronously failing store runs.
    await Future<void>.value();
    // A timeout does not cancel write/rename. Keep one real writer and only
    // the newest queued choice. Never start a second writer after timeout.
    while (_pending != null && !_disposed) {
      final mode = _pending!;
      final revision = _revision;
      _pending = null;
      try {
        await _store!
            .write(jsonEncode({'schemaVersion': 1, 'themeMode': mode.name}));
        if (!_disposed && revision == _revision) {
          saveFailed = false;
          notifyListeners();
        }
      } on Object {
        if (!_disposed && revision == _revision) {
          saveFailed = true;
          notifyListeners();
        }
      }
    }
    _draining = null;
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    _pending = null;
    super.dispose();
  }
}

class ChoreiaThemeScope extends InheritedNotifier<ChoreiaThemeController> {
  const ChoreiaThemeScope(
      {required ChoreiaThemeController controller,
      required super.child,
      super.key})
      : super(notifier: controller);
  static ChoreiaThemeController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChoreiaThemeScope>()?.notifier;
}
