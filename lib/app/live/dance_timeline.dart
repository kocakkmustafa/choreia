/// Presentation-clock mapping for a future licensed demonstration/provider.
/// A player position alone is not the time a sound reached the learner.
enum DanceTimingStatus {
  aligned,
  paused,
  calibrationRequired,
  stale,
  outOfRange
}

final class DanceTimingObservation {
  const DanceTimingObservation(this.status,
      {this.mediaUs, this.beat, this.phase});
  final DanceTimingStatus status;
  final int? mediaUs, beat;
  final double? phase;
  // Alignment is diagnostic. It never establishes step identity or mastery.
  bool get confirmsCorrectStep => false;
}

/// Offsets must be measured for this device/route/clock session. Synthetic
/// values exercise the contract only and are never installed by production.
final class DanceClockCalibration {
  const DanceClockCalibration({
    required this.cameraClockId,
    required this.presentationClockId,
    required this.cameraToPresentationUs,
    required this.uncertaintyUs,
    required this.maxUncertaintyUs,
    required this.validUntilUs,
  });
  final String cameraClockId, presentationClockId;
  final int cameraToPresentationUs,
      uncertaintyUs,
      maxUncertaintyUs,
      validUntilUs;
}

final class DanceTimeline {
  DanceTimeline({required this.durationUs, required List<int> beatsUs})
      : beatsUs = List.unmodifiable(beatsUs) {
    if (durationUs <= 0 ||
        beatsUs.isEmpty ||
        beatsUs.first < 0 ||
        beatsUs.last >= durationUs) {
      throw const FormatException('Invalid beat timeline');
    }
    for (var i = 1; i < beatsUs.length; i++) {
      if (beatsUs[i] <= beatsUs[i - 1]) {
        throw const FormatException('Beat times must increase');
      }
    }
  }

  final int durationUs;
  final List<int> beatsUs;
  int _epoch = 0;
  int? _anchorUs, _positionUs, _lastCameraUs;
  String? _clockId;
  bool _playing = false;
  int get epoch => _epoch;

  /// Pause, seek, background, owner changes and route replacement invalidate
  /// pending provider work. Resume requires a new acknowledged anchor.
  void invalidate() {
    _epoch++;
    _playing = false;
    _anchorUs = _positionUs = _lastCameraUs = null;
    _clockId = null;
  }

  void anchor(
      {required int presentationUs,
      required int mediaUs,
      required String clockId}) {
    invalidate();
    if (presentationUs < 0 ||
        mediaUs < 0 ||
        mediaUs >= durationUs ||
        clockId.isEmpty) {
      throw const FormatException('Invalid presentation anchor');
    }
    _anchorUs = presentationUs;
    _positionUs = mediaUs;
    _clockId = clockId;
    _playing = true;
  }

  DanceTimingObservation observe(
      {required int cameraUs,
      required String cameraClockId,
      required int resultEpoch,
      required int nowPresentationUs,
      required int maxResultAgeUs,
      DanceClockCalibration? calibration}) {
    if (resultEpoch != _epoch) {
      return const DanceTimingObservation(DanceTimingStatus.stale);
    }
    if (!_playing) {
      return const DanceTimingObservation(DanceTimingStatus.paused);
    }
    final c = calibration;
    if (c == null ||
        cameraClockId.isEmpty ||
        c.cameraClockId != cameraClockId ||
        c.presentationClockId != _clockId ||
        c.uncertaintyUs < 0 ||
        c.maxUncertaintyUs < 0 ||
        c.uncertaintyUs > c.maxUncertaintyUs ||
        nowPresentationUs > c.validUntilUs) {
      return const DanceTimingObservation(
          DanceTimingStatus.calibrationRequired);
    }
    final at = cameraUs + c.cameraToPresentationUs;
    if (cameraUs < 0 ||
        maxResultAgeUs < 0 ||
        (_lastCameraUs != null && cameraUs <= _lastCameraUs!) ||
        at < _anchorUs! ||
        at > nowPresentationUs ||
        nowPresentationUs - at > maxResultAgeUs) {
      return const DanceTimingObservation(DanceTimingStatus.stale);
    }
    _lastCameraUs = cameraUs;
    final position = _positionUs! + at - _anchorUs!;
    if (position < beatsUs.first || position >= durationUs) {
      return const DanceTimingObservation(DanceTimingStatus.outOfRange);
    }
    var beat = 0;
    while (beat + 1 < beatsUs.length && beatsUs[beat + 1] <= position) {
      beat++;
    }
    final end = beat + 1 < beatsUs.length ? beatsUs[beat + 1] : durationUs;
    return DanceTimingObservation(DanceTimingStatus.aligned,
        mediaUs: position,
        beat: beat + 1,
        phase: (position - beatsUs[beat]) / (end - beatsUs[beat]));
  }
}
