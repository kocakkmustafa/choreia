import 'course_catalog.dart';

/// What a style looks like to a user RIGHT NOW.
///
/// Derived from two independent axes and **never stored** — see
/// [StyleView.derive] for why that is the whole point of this file.
enum Availability {
  /// The user can open lessons today.
  openable,

  /// Content exists and may even be scored, but a RELEASE gate is closed, so
  /// nothing here can be opened yet. Distinct from [comingSoon]: the work is
  /// done, the gate is not.
  gatedByRelease,

  /// No openable lesson exists yet.
  comingSoon,

  /// Deliberately parked, with a reason shown on the page.
  onHold,

  /// Out of scope. Rendered silently — no "why not" page.
  excluded,
}

/// One style as a surface should present it.
///
/// **The two axes stay separate all the way down** (M-F-130): `contentStatus`
/// is the library's own lattice value (does an openable/scored lesson exist),
/// `releaseBlockers` come from the style's `shipGates`. Neither is derived from
/// the other, and the lattice deliberately does NOT define their relationship —
/// that relationship lives HERE, in the surface derivation, and nowhere else.
final class StyleView {
  const StyleView({
    required this.styleId,
    required this.contentStatus,
    required this.releaseBlockers,
    required this.availability,
    required this.userFacingReason,
  });

  /// Computes availability from the two axes. **Call at render time.**
  ///
  /// Why this is a function and not a field on content: a stored
  /// "isAvailable" would be a third copy of a truth that already exists in two
  /// places, and two copies of a truth drift (C-091). The moment a ship gate
  /// opens, every surface must change together — that only happens if nobody
  /// cached the answer.
  ///
  /// **A closed release gate outranks a healthy content status.** A style can
  /// honestly be `live` (it has a scored lesson) and still be unopenable
  /// (`salsa_shines` today: BPM disputed). Presenting it as openable would
  /// promise something gated — the mirror image of the coming-soon ban.
  factory StyleView.derive({
    required String styleId,
    required String? contentStatus,
    required List<BlockedGate> blockedGates,
  }) {
    final List<BlockedGate> release = blockedGates
        .where((BlockedGate g) => g.scope == GateScope.style)
        .toList(growable: false);

    // Order matters. `excluded` and `onHold` are declarations about the style
    // itself and are not overridden by gates: a style nobody is building has
    // no meaningful release state.
    if (contentStatus == 'excluded') {
      return StyleView._(styleId, contentStatus, release, Availability.excluded,
          null);
    }
    if (contentStatus == 'onHold') {
      return StyleView._(styleId, contentStatus, release, Availability.onHold,
          AvailabilityStrings.onHold);
    }
    if (release.isNotEmpty) {
      return StyleView._(styleId, contentStatus, release,
          Availability.gatedByRelease, AvailabilityStrings.gate(release.first));
    }
    if (contentStatus == 'live' || contentStatus == 'demoOpen') {
      return StyleView._(
          styleId, contentStatus, release, Availability.openable, null);
    }
    return StyleView._(styleId, contentStatus, release, Availability.comingSoon,
        AvailabilityStrings.comingSoon);
  }

  const StyleView._(this.styleId, this.contentStatus, this.releaseBlockers,
      this.availability, this.userFacingReason);

  final String styleId;

  /// The library lattice value — CONTENT reality, untouched by release state.
  final String? contentStatus;

  /// Style-scope gates that are closed today — RELEASE reality.
  final List<BlockedGate> releaseBlockers;

  /// The single question a surface actually asks. Derived, never stored.
  final Availability availability;

  /// What to tell the user, in their words. Null when nothing needs saying.
  final String? userFacingReason;

  bool get isOpenable => availability == Availability.openable;
}

/// User-facing wording for gates.
///
/// The map is keyed by gate id and **falls back to a generic sentence** for a
/// gate it does not know. That fallback is the safety property: a gate added to
/// content tomorrow renders as a plain "we are finishing a check", never as the
/// raw `blockedBy` string — which reads like `beatsStatus:PENDING` and tells a
/// dancer nothing.
abstract final class AvailabilityStrings {
  static const String comingSoon = 'Not open yet — no lesson here can be '
      'started today.';

  static const String onHold =
      'Deliberately on hold. The reason is on the style page.';

  /// Deliberately vague, deliberately non-technical.
  static const String genericGate =
      'Not open yet — we are finishing a check on this style.';

  static const Map<String, String> _byGate = <String, String>{
    'bpmResolved': 'Not open yet — we are still confirming the beat for this '
        'style, and we will not grade your timing against a count we are not '
        'sure of.',
  };

  static String gate(BlockedGate g) => _byGate[g.id] ?? genericGate;
}
