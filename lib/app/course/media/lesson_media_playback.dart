import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../theme.dart';
import '../../history/account_store_lifetime.dart';

const Duration _nativeRetireDeadline = Duration(seconds: 2);
bool _nativePlaybackUnconfirmed = false;
Completer<void>? _nativeSlotOwner;

Future<Completer<void>?> _takeNativeSlot() async {
  while (!_nativePlaybackUnconfirmed) {
    final owner = _nativeSlotOwner;
    if (owner == null) {
      final acquired = Completer<void>();
      _nativeSlotOwner = acquired;
      return acquired;
    }
    await owner.future;
  }
  return null;
}

void _releaseNativeSlot(Completer<void> owner) {
  if (!identical(_nativeSlotOwner, owner)) return;
  _nativeSlotOwner = null;
  owner.complete();
}

/// Only a test seam until a separately signed media acceptance root exists.
/// This type is not a publication receipt and cannot be populated from a v3
/// staging candidate by the shipping lesson route.
final class LessonMediaPlaybackFixture {
  const LessonMediaPlaybackFixture({
    required this.lessonId,
    required this.videoAssetPath,
    required this.captionAssetPaths,
  });

  final String lessonId, videoAssetPath;
  final Map<String, String> captionAssetPaths;
}

@immutable
final class LessonVideoFrame {
  const LessonVideoFrame({
    this.initialized = false,
    this.playing = false,
    this.hasError = false,
    this.aspectRatio = 16 / 9,
    this.caption = '',
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  final bool initialized, playing, hasError;
  final double aspectRatio;
  final String caption;
  final Duration position, duration;
}

/// Small adapter so lifecycle tests never need a native video texture.
abstract interface class LessonVideoHandle {
  ValueListenable<LessonVideoFrame> get frame;
  Future<void> initialize();
  Future<void> silence();
  Future<void> play();
  Future<void> pause();
  Future<void> close();
  Widget buildVideo();
}

/// Optional transport capability; existing playback-only adapters remain valid.
abstract interface class SeekableLessonVideoHandle
    implements LessonVideoHandle {
  Future<void> seekTo(Duration position);
}

typedef LessonVideoFactory = LessonVideoHandle Function(
    String videoAssetPath, String captionText);

LessonVideoHandle createAssetLessonVideo(
        String videoAssetPath, String captionText) =>
    _AssetLessonVideo(videoAssetPath, captionText);

final class _AssetLessonVideo implements SeekableLessonVideoHandle {
  _AssetLessonVideo(String videoAssetPath, String captionText)
      : _controller = VideoPlayerController.asset(
          videoAssetPath,
          closedCaptionFile:
              Future<ClosedCaptionFile>.value(WebVTTCaptionFile(captionText)),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        ) {
    _controller.addListener(_sync);
  }

  final VideoPlayerController _controller;
  final ValueNotifier<LessonVideoFrame> _frame =
      ValueNotifier<LessonVideoFrame>(const LessonVideoFrame());
  bool _closed = false;

  @override
  ValueListenable<LessonVideoFrame> get frame => _frame;

  void _sync() {
    if (_closed) return;
    final value = _controller.value;
    _frame.value = LessonVideoFrame(
      initialized: value.isInitialized,
      playing: value.isPlaying,
      hasError: value.hasError,
      aspectRatio: value.isInitialized &&
              value.aspectRatio.isFinite &&
              value.aspectRatio > 0
          ? value.aspectRatio
          : 16 / 9,
      caption: value.caption.text,
      position: value.position,
      duration: value.duration,
    );
  }

  @override
  Future<void> initialize() async {
    // video_player reapplies its current value during initialization. Seed it
    // with zero before creation so that asynchronous apply cannot restore 1.0.
    await _controller.setVolume(0);
    await _controller.initialize();
  }

  @override
  Future<void> silence() => _controller.setVolume(0);

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> seekTo(Duration position) => _controller.seekTo(position);

  @override
  Widget buildVideo() => VideoPlayer(_controller);

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _controller.removeListener(_sync);
    try {
      await _controller.dispose();
    } finally {
      _frame.dispose();
    }
  }
}

/// Playback remains user-started and never writes lesson progress. Parent
/// route/lifecycle/account changes remove this widget and close its handle.
class LessonMediaPlayback extends StatefulWidget {
  const LessonMediaPlayback({
    required this.fixture,
    required this.bundle,
    required this.locale,
    required this.videoFactory,
    this.admissionOpen,
    this.ownerTicket,
    super.key,
  });

  final LessonMediaPlaybackFixture fixture;
  final AssetBundle bundle;
  final String locale;
  final LessonVideoFactory videoFactory;
  final ValueListenable<bool>? admissionOpen;
  final AppStoreOwnerTicket? ownerTicket;

  @override
  State<LessonMediaPlayback> createState() => _LessonMediaPlaybackState();
}

class _LessonMediaPlaybackState extends State<LessonMediaPlayback> {
  AppStoreOwnerTicket? _resourceOwner;
  int _epoch = 0;
  LessonVideoHandle? _video;
  Completer<void>? _slotOwner;
  Future<void> _closing = Future<void>.value();
  Future<void> _nativeOperation = Future<void>.value();
  bool _ready = false;
  bool _failed = false;
  bool _commandPending = false;
  bool _retired = false;
  bool get _admitted => !_retired && widget.admissionOpen?.value != false;

  @override
  void initState() {
    super.initState();
    _resourceOwner = widget.ownerTicket;
    _resourceOwner?.registerResource(_closeOwnedPlayback);
    widget.admissionOpen?.addListener(_onAdmission);
    if (widget.admissionOpen?.value == false) _onAdmission();
    _prepare();
  }

  @override
  void didUpdateWidget(covariant LessonMediaPlayback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.admissionOpen != widget.admissionOpen) {
      oldWidget.admissionOpen?.removeListener(_onAdmission);
      widget.admissionOpen?.addListener(_onAdmission);
      _retire();
    }
    if (oldWidget.fixture != widget.fixture ||
        oldWidget.bundle != widget.bundle ||
        oldWidget.locale != widget.locale ||
        oldWidget.videoFactory != widget.videoFactory) {
      _epoch++;
      _drop();
      _ready = false;
      _failed = false;
      _prepare();
    }
  }

  void _onAdmission() {
    if (widget.admissionOpen?.value != false) return;
    _retire();
    if (mounted) setState(() {});
  }

  Future<void> _closeOwnedPlayback() async {
    _retire();
    await _closing;
    if (_nativePlaybackUnconfirmed) throw StateError('video-close-uncertain');
  }

  void _retire() {
    _retired = true;
    _epoch++;
    _ready = false;
    _drop();
  }

  void _onFrame() {
    if (!mounted || !_admitted) return;
    if (_video?.frame.value.hasError == true) {
      _drop();
      setState(() => _failed = true);
    } else {
      setState(() {});
    }
  }

  Future<T> _invokeNative<T>(Future<T> Function() invoke) {
    // Reserve the in-flight marker before invoking the adapter. A synchronous
    // frame-error callback can otherwise drop the handle before its Future is
    // assigned to [_nativeOperation].
    final settled = Completer<void>();
    _nativeOperation = settled.future;
    try {
      final operation = invoke();
      unawaited(operation.then<void>(
        (_) => settled.complete(),
        onError: (Object _, StackTrace __) => settled.complete(),
      ));
      return operation;
    } catch (_) {
      settled.complete();
      rethrow;
    }
  }

  Future<void> _safeClose(
    LessonVideoHandle video,
    Future<void> pending,
    Completer<void>? owner,
  ) async {
    var unconfirmed = owner == null;
    Future<void> attempt(Future<void> Function() operation) async {
      try {
        await operation().timeout(_nativeRetireDeadline);
      } catch (_) {
        unconfirmed = true;
      }
    }

    try {
      await attempt(() => pending);
      await attempt(video.pause);
      await attempt(video.close);
    } finally {
      // Timeouts do not cancel native Futures. A new route must not acquire
      // playback after any part of the previous close remains uncertain.
      if (unconfirmed) _nativePlaybackUnconfirmed = true;
      if (owner != null) _releaseNativeSlot(owner);
    }
  }

  void _drop() {
    final video = _video;
    final owner = _slotOwner;
    _video = null;
    _slotOwner = null;
    _commandPending = false;
    if (video == null) {
      if (owner != null) _releaseNativeSlot(owner);
      return;
    }
    video.frame.removeListener(_onFrame);
    final pending = _nativeOperation;
    _closing = _closing.then((_) => _safeClose(video, pending, owner));
    unawaited(_closing);
  }

  Future<void> _prepare() async {
    final epoch = ++_epoch;
    if (!_admitted) return;
    try {
      await _closing;
      if (!mounted || !_admitted || epoch != _epoch) return;
      final captionPath = widget.fixture.captionAssetPaths[widget.locale];
      if (captionPath == null || captionPath.isEmpty) {
        throw const FormatException('Missing caption locale');
      }
      final captionText = await widget.bundle.loadString(captionPath);
      if (!captionText
          .startsWith('WEBVTT - Motion locale=${widget.locale}\n\n')) {
        throw const FormatException('Unexpected caption profile');
      }
      if (WebVTTCaptionFile(captionText).captions.isEmpty) {
        throw const FormatException('Empty caption track');
      }
      if (!mounted || !_admitted || epoch != _epoch) return;
      final owner = await _takeNativeSlot();
      if (owner == null) {
        throw StateError('Previous native playback is unconfirmed');
      }
      if (!mounted || !_admitted || epoch != _epoch) {
        _releaseNativeSlot(owner);
        return;
      }
      _slotOwner = owner;
      final video = widget.videoFactory(
        widget.fixture.videoAssetPath,
        captionText,
      );
      _video = video;
      video.frame.addListener(_onFrame);
      final initializing = _invokeNative(video.initialize);
      await initializing;
      if (!mounted || !_admitted || epoch != _epoch || _video != video) return;
      if (video.frame.value.hasError || !video.frame.value.initialized) {
        throw StateError('Video did not initialize');
      }
      // A demonstration must not become playable until the native player has
      // acknowledged zero volume, even if an imported master has an audio track.
      await _invokeNative(video.silence);
      if (!mounted || !_admitted || epoch != _epoch || _video != video) return;
      if (video.frame.value.hasError) {
        throw StateError('Video could not be silenced');
      }
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted || !_admitted || epoch != _epoch) return;
      _drop();
      setState(() => _failed = true);
    }
  }

  Future<void> _toggle() async {
    final video = _video;
    if (!_admitted || video == null || !_ready || _failed || _commandPending) {
      return;
    }
    setState(() => _commandPending = true);
    try {
      final operation = _invokeNative(
        video.frame.value.playing ? video.pause : video.play,
      );
      await operation;
    } catch (_) {
      if (!mounted || !_admitted || _video != video) return;
      _drop();
      setState(() => _failed = true);
      return;
    }
    if (mounted && _admitted && _video == video) {
      setState(() => _commandPending = false);
    }
  }

  Future<void> _seek(Duration target) async {
    final video = _video;
    if (!_admitted ||
        video is! SeekableLessonVideoHandle ||
        !_ready ||
        _failed ||
        _commandPending) {
      return;
    }
    final duration = video.frame.value.duration;
    if (duration <= Duration.zero ||
        target < Duration.zero ||
        target > duration) {
      return;
    }
    final epoch = _epoch;
    setState(() => _commandPending = true);
    try {
      // Seek stays paused. Each acknowledgement is bounded by the route and
      // account generation, including backgrounding during a pending pause.
      await _invokeNative(video.pause);
      if (!mounted || !_admitted || epoch != _epoch || _video != video) return;
      await _invokeNative(() => video.seekTo(target));
    } catch (_) {
      if (!mounted || !_admitted || epoch != _epoch || _video != video) return;
      _drop();
      setState(() => _failed = true);
      return;
    }
    if (mounted && _admitted && epoch == _epoch && _video == video) {
      setState(() => _commandPending = false);
    }
  }

  @override
  void dispose() {
    widget.admissionOpen?.removeListener(_onAdmission);
    _epoch++;
    _drop();
    unawaited(_closing.then<void>((_) {
      if (!_nativePlaybackUnconfirmed) {
        _resourceOwner?.unregisterResource(_closeOwnedPlayback);
      }
    }));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.locale == 'tr';
    if (!_admitted) return const SizedBox.shrink();
    if (_failed) {
      return GlassPanel(
        child: Text(
          tr
              ? 'Gösterim oynatılamadı. Yazılı derse devam edebilirsin.'
              : 'The demonstration could not play. You can continue with the written lesson.',
          key: const Key('choreia.mediaPlaybackFailure'),
          style: ChoreiaType.of(context).body(),
        ),
      );
    }
    final video = _video;
    final frame = video?.frame.value;
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(tr ? 'Gösterim' : 'Demonstration',
              style: ChoreiaType.of(context).label(color: ChoreiaPalette.of(context).amber)),
          const SizedBox(height: 10),
          if (!_ready || video == null || frame == null)
            const AspectRatio(
              aspectRatio: 16 / 9,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            AspectRatio(
              aspectRatio: frame.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  video.buildVideo(),
                  if (frame.caption.isNotEmpty)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        key: const Key('choreia.mediaCaption'),
                        color: const Color(0xCC000000),
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          frame.caption,
                          textAlign: TextAlign.center,
                          style: ChoreiaType.of(context).body(color: ChoreiaPalette.onVideoCaption),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (_ready &&
              video is SeekableLessonVideoHandle &&
              frame != null &&
              frame.duration > Duration.zero)
            Slider(
              key: const Key('choreia.mediaPlaybackSeek'),
              semanticFormatterCallback: (value) =>
                  tr ? '${value.round()} saniye' : '${value.round()} seconds',
              min: 0,
              max: frame.duration.inMilliseconds / 1000,
              value: frame.position.inMilliseconds
                      .clamp(0, frame.duration.inMilliseconds) /
                  1000,
              onChanged: _commandPending
                  ? null
                  : (seconds) =>
                      _seek(Duration(milliseconds: (seconds * 1000).round())),
            ),
          TextButton.icon(
            key: const Key('choreia.mediaPlaybackToggle'),
            onPressed: _ready && !_commandPending ? _toggle : null,
            icon: Icon(frame?.playing == true ? Icons.pause : Icons.play_arrow),
            label: Text(frame?.playing == true
                ? (tr ? 'Duraklat' : 'Pause')
                : (tr ? 'Oynat' : 'Play')),
          ),
          Text(
            tr
                ? 'Gösterimi izlemek ders ilerlemesini değiştirmez.'
                : 'Watching the demonstration does not change lesson progress.',
            style: ChoreiaType.of(context).body(size: 12),
          ),
        ],
      ),
    );
  }
}
