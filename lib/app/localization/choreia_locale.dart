import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// A device display preference. It contains no account or practice data.
class ChoreiaLocaleController extends ValueNotifier<Locale?> {
  ChoreiaLocaleController.memory([Locale? locale])
      : _persist = false,
        super(locale);
  ChoreiaLocaleController.persisted()
      : _persist = true,
        super(null);

  final bool _persist;

  bool persistenceFailed = false;
  int _revision = 0;
  bool _disposed = false;
  Future<void> _writes = Future<void>.value();

  void _setPersistenceFailed(bool failed) {
    if (_disposed || persistenceFailed == failed) return;
    persistenceFailed = failed;
    notifyListeners();
  }

  static const supported = <Locale>[
    Locale('tr'),
    Locale('en'),
    Locale('es', '419'),
    Locale('pt', 'BR'),
    Locale('de'),
    Locale('fr'),
    Locale('ja'),
    Locale('ar'),
  ];
  static const names = <String, String>{
    'tr': 'Türkçe',
    'en': 'English',
    'es-419': 'Español (Latinoamérica)',
    'pt-BR': 'Português (Brasil)',
    'de': 'Deutsch',
    'fr': 'Français',
    'ja': '日本語',
    'ar': 'العربية',
  };

  static String tag(Locale locale) =>
      switch (locale.languageCode.toLowerCase()) {
        'es' => 'es-419',
        'pt' => 'pt-BR',
        final code when names.containsKey(code) => code,
        _ => 'en',
      };

  static Locale resolve(Locale? requested, Iterable<Locale> _) {
    final wanted = requested == null ? 'en' : tag(requested);
    return supported.firstWhere((locale) => tag(locale) == wanted);
  }

  Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/choreia_display_locale.json');
  }

  Future<void> restore() async {
    final revision = _revision;
    try {
      final file = await _file().timeout(const Duration(seconds: 2));
      if (!await file.exists().timeout(const Duration(seconds: 2))) return;
      final raw = jsonDecode(
          await file.readAsString().timeout(const Duration(seconds: 2)));
      final saved = raw is Map ? raw['locale'] : null;
      if (!_disposed &&
          saved is String &&
          names.containsKey(saved) &&
          revision == _revision) {
        value = supported.firstWhere((locale) => tag(locale) == saved);
      }
    } on Object {
      if (!_disposed && revision == _revision) _setPersistenceFailed(true);
    }
  }

  Future<void> select(Locale? locale, {bool persist = true}) {
    final selected = locale == null ? null : resolve(locale, supported);
    final revision = ++_revision;
    _setPersistenceFailed(false);
    value = selected;
    if (!persist || !_persist) return Future<void>.value();
    // A timeout is not cancellation. Serialize real writes so a late old
    // value cannot overwrite a newer selection.
    final operation = _writes.then((_) async {
      final file = await _file();
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
          jsonEncode({
            'schemaVersion': 1,
            'locale': selected == null ? null : tag(selected),
          }),
          flush: true);
      await temporary.rename(file.path);
    });
    _writes = operation.catchError((Object _) {});
    return operation.timeout(const Duration(seconds: 3)).catchError((Object _) {
      if (!_disposed && revision == _revision) {
        _setPersistenceFailed(true);
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }
}

class ChoreiaLocaleScope extends InheritedNotifier<ChoreiaLocaleController> {
  const ChoreiaLocaleScope(
      {required ChoreiaLocaleController controller,
      required super.child,
      super.key})
      : super(notifier: controller);

  static ChoreiaLocaleController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ChoreiaLocaleScope>()
      ?.notifier;
}
