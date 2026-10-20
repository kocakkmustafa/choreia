import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// A device display preference. It contains no account or practice data.
class ChoreiaLocaleController extends ValueNotifier<Locale?> {
  ChoreiaLocaleController.memory([super.value]) : _persist = false, _preferenceFile = null;
  ChoreiaLocaleController.persisted({Future<File> Function()? preferenceFile})
      : _persist = true, _preferenceFile = preferenceFile, super(null);

  final bool _persist;
  final Future<File> Function()? _preferenceFile;
  bool readFailed = false;

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
    Locale('it'),
    Locale('ko'),
    Locale('id'),
    Locale('pl'),
    Locale('hi'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
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
    'it': 'Italiano',
    'ko': '한국어',
    'id': 'Bahasa Indonesia',
    'pl': 'Polski',
    'hi': 'हिन्दी',
    'zh-Hans': '简体中文',
  };

  static String tag(Locale locale) =>
      switch (locale.languageCode.toLowerCase()) {
        'es' => 'es-419',
        'pt' => 'pt-BR',
        'zh' => 'zh-Hans',
        final code when names.containsKey(code) => code,
        _ => 'en',
      };

  static Locale resolve(Locale? requested, Iterable<Locale> _) {
    final wanted = requested == null ? 'en' : tag(requested);
    return supported.firstWhere((locale) => tag(locale) == wanted);
  }

  /// Respect the OS preference order before falling back to English.
  static Locale resolveLocales(List<Locale>? requested, Iterable<Locale> _) {
    for (final locale in requested ?? const <Locale>[]) {
      if (supported.any((entry) => entry.languageCode == locale.languageCode.toLowerCase())) {
        return resolve(locale, supported);
      }
    }
    return const Locale('en');
  }

  Future<File> _file() async {
    if (_preferenceFile != null) return _preferenceFile();
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/choreia_display_locale.json');
  }

  Future<String?> _readSaved() async {
    final file = await _file();
    if (!await file.exists()) return null;
    final raw = jsonDecode(await file.readAsString());
    if (raw is! Map || raw['schemaVersion'] != 1 || !raw.containsKey('locale')) {
      throw const FormatException('Invalid language preference');
    }
    final saved = raw['locale'];
    if (saved != null && (saved is! String || !names.containsKey(saved))) {
      throw const FormatException('Unsupported saved language');
    }
    return saved as String?;
  }

  /// One total deadline; late reads never overwrite a newer choice or first frame.
  Future<void> restore({Duration deadline = const Duration(milliseconds: 500)}) async {
    if (!_persist || _disposed) return;
    final revision = _revision;
    try {
      final saved = await _readSaved().timeout(deadline);
      if (!_disposed && revision == _revision) {
        readFailed = false;
        value = saved == null ? null : supported.firstWhere((locale) => tag(locale) == saved);
        notifyListeners();
      }
    } on Object {
      if (!_disposed && revision == _revision) {
        readFailed = true;
        notifyListeners();
      }
    }
  }

  Future<void> select(Locale? locale, {bool persist = true, Duration deadline = const Duration(seconds: 3)}) {
    if (_disposed) return Future<void>.value();
    final hadReadFailure = readFailed;
    readFailed = false;
    final selected = locale == null ? null : resolve(locale, supported);
    final revision = ++_revision;
    _setPersistenceFailed(false);
    value = selected;
    if (hadReadFailure) notifyListeners();
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
    return operation.timeout(deadline).catchError((Object _) {
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
