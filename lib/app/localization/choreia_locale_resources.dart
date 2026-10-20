// App-owned latest-generation locale preparation; navigation keys stay unchanged.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'choreia_locale.dart';
import 'choreia_messages.dart';

/// Publishes a complete locale/resource pair without replacing navigation.
/// Raw device preference remains owned by the existing locale controller.
class ChoreiaLocaleResources extends StatefulWidget {
  const ChoreiaLocaleResources({
    required this.controller,
    required this.builder,
    this.bundle,
    super.key,
  });

  final ChoreiaLocaleController controller;
  final AssetBundle? bundle;
  final Widget Function(BuildContext context, Locale locale,
      LocalizationsDelegate<ChoreiaMessages> delegate) builder;

  @override
  State<ChoreiaLocaleResources> createState() => _ChoreiaLocaleResourcesState();
}

class _ChoreiaLocaleResourcesState extends State<ChoreiaLocaleResources>
    with WidgetsBindingObserver {
  Locale? _requested;
  Locale? _applied;
  ChoreiaMessages? _messages;
  int _generation = 0;
  bool _firstFrameDeferred = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_prepare);
    _prepare();
  }

  @override
  void didUpdateWidget(covariant ChoreiaLocaleResources oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller || oldWidget.bundle != widget.bundle) {
      oldWidget.controller.removeListener(_prepare);
      widget.controller.addListener(_prepare);
      _prepare(force: true);
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (widget.controller.value == null) _prepare();
  }

  void _prepare({bool force = false}) {
    final requested = widget.controller.value;
    final locale = requested == null
        ? ChoreiaLocaleController.resolveLocales(
            WidgetsBinding.instance.platformDispatcher.locales,
            ChoreiaLocaleController.supported)
        : ChoreiaLocaleController.resolve(requested, ChoreiaLocaleController.supported);
    if (!force && locale == _requested) return;
    _requested = locale;
    final generation = ++_generation;
    void publish(ChoreiaMessages messages) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _applied = locale;
        _messages = messages;
      });
      _releaseFirstFrame();
    }
    // The loader has a bounded asset deadline and returns a tagged fallback.
    // A late result is ignored here, before Flutter can publish its locale.
    unawaited(ChoreiaMessagesDelegate(bundle: widget.bundle).load(locale).then<void>(
      publish,
      onError: (Object _, StackTrace __) => publish(ChoreiaMessages(
          localeTag: ChoreiaLocaleController.tag(locale),
          translationUnavailable: true)),
    ));
    if (_messages == null && !_firstFrameDeferred) {
      _firstFrameDeferred = true;
      WidgetsBinding.instance.deferFirstFrame();
    }
  }

  void _releaseFirstFrame() {
    if (!_firstFrameDeferred) return;
    _firstFrameDeferred = false;
    WidgetsBinding.instance.allowFirstFrame();
  }

  @override
  void dispose() {
    _generation++;
    widget.controller.removeListener(_prepare);
    WidgetsBinding.instance.removeObserver(this);
    _releaseFirstFrame();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages;
    if (messages == null) return const SizedBox.shrink();
    return widget.builder(context, _applied!, _PreparedMessagesDelegate(messages));
  }
}

class _PreparedMessagesDelegate extends LocalizationsDelegate<ChoreiaMessages> {
  const _PreparedMessagesDelegate(this.messages);
  final ChoreiaMessages messages;

  @override
  bool isSupported(Locale locale) =>
      ChoreiaLocaleController.supports(locale) &&
      ChoreiaLocaleController.tag(locale) == messages.localeTag;

  @override
  Future<ChoreiaMessages> load(Locale locale) => SynchronousFuture(messages);

  @override
  bool shouldReload(_PreparedMessagesDelegate old) => !identical(messages, old.messages);
}
