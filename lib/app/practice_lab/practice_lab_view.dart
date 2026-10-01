import 'package:flutter/material.dart';

import '../shell/not_built_tab_body.dart';
import '../ui_language.dart';

/// The "Practice Lab" tab (roadmap §5.3).
///
/// Every tool the roadmap names for this tab — segment loop, tempo ladder,
/// mirror mode, percussive onset tools — is a capability that does not
/// exist anywhere in the app yet (measured, DEFTER C-321: zero loop/mirror/
/// tempo-control code in `lib/`). "Practice Lab" also has no precedent in
/// any design document in this repo (`CHOREIA-BLUEPRINT.md`, `UI-BRIEF.md`,
/// `DESIGN-AHEAD-OF-CODE.md` — none name it), so there is no spec to build
/// against yet, only the roadmap's one-line description. This tab names the
/// plan without pretending any of it is built.
class PracticeLabView extends StatelessWidget {
  const PracticeLabView({super.key});

  static const Key notBuiltKey = Key('shell.practiceLab.notBuilt');

  @override
  Widget build(BuildContext context) => notBuiltTabBody(
    context,
    key: notBuiltKey,
    title: UiLanguage.text(context, en: 'Practice Lab', tr: 'Pratik Alanı'),
    plannedContent: UiLanguage.text(
      context,
      en:
          'Beat practice, segment looping, tempo controls, and mirror '
          'mode are not available here.',
      tr:
          'Ritim pratiği, bölüm tekrarı, tempo denetimleri ve ayna '
          'modu bu bölümde kullanılamıyor.',
    ),
  );
}
