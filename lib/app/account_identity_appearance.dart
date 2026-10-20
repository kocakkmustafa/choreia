import 'package:flutter/material.dart';
import 'package:motion_account/motion_account.dart';

import 'localization/choreia_locale.dart';
import 'theme.dart';
import 'theme/theme_preference.dart';

/// Owns presentation listeners only; never initializes or mutates identity.
class ChoreiaIdentityAppearance extends StatefulWidget {
  const ChoreiaIdentityAppearance({
    required this.runtime,
    required this.locales,
    required this.themes,
    required this.child,
    super.key,
  });

  final MotionAccountRuntime runtime;
  final ChoreiaLocaleController locales;
  final ChoreiaThemeController themes;
  final Widget child;

  @override
  State<ChoreiaIdentityAppearance> createState() =>
      _ChoreiaIdentityAppearanceState();
}

class _ChoreiaIdentityAppearanceState extends State<ChoreiaIdentityAppearance>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    widget.locales.addListener(_changed);
    widget.themes.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant ChoreiaIdentityAppearance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locales != widget.locales) {
      oldWidget.locales.removeListener(_changed);
      widget.locales.addListener(_changed);
    }
    if (oldWidget.themes != widget.themes) {
      oldWidget.themes.removeListener(_changed);
      widget.themes.addListener(_changed);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (widget.locales.value == null) _changed();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.locales.removeListener(_changed);
    widget.themes.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preference = widget.locales.value;
    // The gate can block before the child/its async message loader is mounted.
    // Give the same canonical app decision explicitly, independent of a parent
    // locale; the raw System preference itself remains null in its controller.
    final locale = preference == null
        ? ChoreiaLocaleController.resolveLocales(
            WidgetsBinding.instance.platformDispatcher.locales,
            ChoreiaLocaleController.supported)
        : ChoreiaLocaleController.resolve(
            preference, ChoreiaLocaleController.supported);
    return MotionIdentityGate(
      runtime: widget.runtime,
      theme: ChoreiaTheme.light,
      darkTheme: ChoreiaTheme.dark,
      themeMode: widget.themes.value,
      locale: locale,
      child: widget.child,
    );
  }
}
