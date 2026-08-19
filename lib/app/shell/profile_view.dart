import 'package:flutter/material.dart';

import 'not_built_tab_body.dart';

/// The "Profil" (Profile) tab (roadmap §5.5).
///
/// Unlike Today and Practice Lab, some of what this tab should eventually
/// show already exists in code form — `permission_handler` is a real
/// dependency and camera permission state is real and readable today. That
/// makes a fully-honest Profile screen a genuinely smaller lift than the
/// other two, and a reasonable NEXT increment — but calibration, export/
/// delete, and subscription all still name capabilities with zero
/// implementation (`lib/services/entitlements/`, `lib/data/local/` do not
/// exist), so a screen mixing real permission state with placeholder
/// sections for the rest was judged a bigger, less reviewable change than
/// keeping this tab uniformly honest for now, same as its two siblings.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  static const Key notBuiltKey = Key('shell.profile.notBuilt');

  @override
  Widget build(BuildContext context) => notBuiltTabBody(
        context,
        key: notBuiltKey,
        title: 'Profile',
        plannedContent:
            'Permissions, camera and audio calibration, accessibility '
            'settings, your subscription, exporting or deleting your data, '
            'and the legal links — most of the pieces this needs (a '
            'calibration flow, export/delete, subscription) are not built '
            'yet, so this tab is not either.',
      );
}
