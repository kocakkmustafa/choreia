import 'package:flutter/material.dart';

import '../library/library_catalog.dart';
import '../theme.dart';

/// The first thing a user sees, once.
///
/// What this screen is for
/// -----------------------
/// Until it existed, launching Choreia dropped a person straight into a
/// catalogue of 34 dance names with no statement of what the app does, that a
/// camera would be involved, or how much of the catalogue is actually open.
/// The App Store reads that as an app that does not explain itself; a dancer
/// reads it as a shop with most of the shelves empty and no sign on the door.
///
/// What it refuses to be
/// ---------------------
/// Not a tour, not a carousel, not a sales pitch. One screen, scrollable, four
/// plain statements and a way in. No progress dots implying a journey, no
/// "Let's go!", no illustration of a dancer we did not film. The family's line
/// against cheering applies hardest here, because onboarding is exactly where
/// products lie about themselves most cheaply.
///
/// Why the numbers are DERIVED
/// ---------------------------
/// The "where the app is today" paragraph counts the real catalogue at build
/// time. A hardcoded "one style is open" would be true the day it was typed
/// and quietly false the day a second one opened — the same rot the library
/// tally exists to prevent. Nothing here is a measurement OF THE DANCER, so
/// counting is honest; band language is for judgements, not inventory.
class FirstRunView extends StatelessWidget {
  const FirstRunView({
    super.key,
    required this.tally,
    required this.onContinue,
  });

  final LibraryTally tally;
  final VoidCallback onContinue;

  static const Key continueKey = Key('intro.continue');
  static const Key cameraKey = Key('intro.camera');
  static const Key stateKey = Key('intro.state');

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ChoreiaBackdrop(
          child: SafeArea(
            // The way in is PINNED, the reading scrolls. Measured at 375x812:
            // with the button inside the list it sat below the fold, so the
            // only exit from the first screen a user ever sees was behind a
            // scroll they had no reason to expect. A first-run screen whose
            // exit must be discovered is a dead end with extra steps
            // (M-F-268).
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 40, 22, 20),
                    children: <Widget>[
                      Text(IntroStrings.title,
                          style: ChoreiaType.display(
                              size: 34, color: ChoreiaColors.text(0.92))),
                      const SizedBox(height: 10),
                      Text(IntroStrings.what,
                          style: ChoreiaType.body(
                              size: 15, color: ChoreiaColors.text(0.78))),
                      const SizedBox(height: 26),
                      _panel(
                        key: cameraKey,
                        icon: Icons.videocam_outlined,
                        tone: ChoreiaColors.rose,
                        title: IntroStrings.cameraTitle,
                        body: IntroStrings.camera,
                      ),
                      const SizedBox(height: 14),
                      _panel(
                        icon: Icons.music_note_outlined,
                        tone: ChoreiaColors.amber,
                        title: IntroStrings.musicTitle,
                        body: IntroStrings.music,
                      ),
                      const SizedBox(height: 14),
                      _panel(
                        icon: Icons.straighten_outlined,
                        tone: ChoreiaColors.amber,
                        title: IntroStrings.limitsTitle,
                        body: IntroStrings.limits,
                      ),
                      const SizedBox(height: 14),
                      _panel(
                        key: stateKey,
                        icon: Icons.inventory_2_outlined,
                        tone: ChoreiaColors.roseDeep,
                        title: IntroStrings.todayTitle,
                        body: IntroStrings.today(tally),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: continueKey,
                      onPressed: onContinue,
                      child: const Text(IntroStrings.continueLabel),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _panel({
    Key? key,
    required IconData icon,
    required Color tone,
    required String title,
    required String body,
  }) =>
      GlassPanel(
        key: key,
        tint: tone,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            StatusRing(icon: icon, tone: tone, breathing: false, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: ChoreiaType.label(size: 9.5, color: tone)),
                  const SizedBox(height: 6),
                  Text(body,
                      style: ChoreiaType.body(
                          size: 13, color: ChoreiaColors.text(0.75))),
                ],
              ),
            ),
          ],
        ),
      );
}

/// The intro's copy, in one place — same seam as `ShellStrings`.
abstract final class IntroStrings {
  IntroStrings._();

  static const String title = 'Choreia';

  static const String what =
      'Choreia watches you dance and tells you what it can see about your '
      'steps. It runs on your phone, and it is honest about the parts a '
      'camera cannot judge.';

  static const String cameraTitle = 'THE CAMERA';

  /// **Byte-for-byte the iOS permission string.**
  ///
  /// The sentence a person reads before granting camera access and the
  /// sentence they read here must be the same sentence. Two copies of a
  /// privacy promise drift, and the one that drifts is always the one nobody
  /// is looking at — `content_claims_test` pins them equal so an edit to
  /// either fails the build.
  static const String camera =
      'Choreia watches your dancing to give you feedback on your steps. '
      'Video never leaves your phone — we only read the positions of your '
      'joints, and nothing is recorded or uploaded.';

  static const String musicTitle = 'YOUR OWN MUSIC';

  /// There is no music library inside the app and there will not be one: a
  /// catalogue means licensing. Saying so plainly beats letting someone
  /// discover the silence and assume the app is broken.
  static const String music =
      'There is no music inside Choreia. Put on whatever you like — from any '
      'app, or nothing at all — and dance to that. The steps are counted, not '
      'timed to a track.';

  static const String limitsTitle = 'WHAT IT DOES NOT JUDGE';

  /// The rhythm sentence is load-bearing. The app measures body positions and
  /// has no timing or rhythm score of any kind; a user who assumes otherwise
  /// will read every silence as a bad grade. Stating the absence is the only
  /// way it stays an absence rather than an implied zero.
  static const String limits =
      'Choreia reads where your body is, not whether you are on the beat. '
      'There is no rhythm or timing score here, so nothing on screen is '
      'marking your musicality. Feel, style and expression are yours — a '
      'phone camera has no opinion about them.';

  static const String todayTitle = 'WHERE THIS IS TODAY';

  /// Counted from the real catalogue every time this screen is built.
  static String today(LibraryTally tally) {
    final int openable = tally.scored + tally.openUngraded;
    final String lessons = openable == 1
        ? 'One style has a lesson you can open today'
        : '$openable styles have a lesson you can open today';
    return '$lessons, out of ${tally.total} in the catalogue. The rest have '
        'their own page — where the dance comes from, what its steps are '
        'called, and what a camera can and cannot see of it — but no lesson '
        'yet, and we would rather show you an empty shelf than a fake one. '
        '$_storage';
  }

  /// What happens to a finished session — and it used to say the OPPOSITE.
  ///
  /// 🔴 **THE SENTENCE HERE WAS FALSE, AND IT WAS THE FIRST THING A NEW USER
  /// READ.** It said *"Nothing you do is saved anywhere in this version."*
  /// True when written; `C-268` built the session store, `C-269` measured it
  /// opening and writing on a real simulator, and this line never moved. So
  /// the app told every new learner their practice would be discarded, and
  /// then kept it.
  ///
  /// **Why it survived a gate built for exactly this class.** `C-269 ④` added
  /// the talkative-PRESENCE check — *"the mechanism exists, so the surface may
  /// no longer deny it"* — but it hunted a SYMBOL
  /// (`HistoryIntegrity.notRecorded`) in ONE file (the shell). This screen made
  /// the identical claim in prose, with no symbol to find, so the gate looked
  /// straight past it.
  ///
  /// ⇒ **A CLAIM IS NOT A SYMBOL.** The gate now scans the whole of `lib/` for
  /// the claim family rather than one identifier in one file
  /// (`publication_inventory_test`).
  ///
  /// **And why it was invisible to a reader, too:** it was concatenated onto a
  /// sentence that IS derived live from the catalogue (`tally`). A stale claim
  /// glued to a fresh one borrows its look of freshness — so it is split out
  /// here, as its own named thing that a gate can point at.
  static const String _storage =
      'What you practise is kept on this phone, so the progress tab can show '
      'you what you have actually done. It stays here — nothing about your '
      'practice is sent anywhere.';

  static const String continueLabel = 'Open the catalogue';
}
