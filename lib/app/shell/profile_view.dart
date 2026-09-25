import 'package:flutter/material.dart';

import 'not_built_tab_body.dart';
import '../theme.dart';
import '../ui_language.dart';

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
  const ProfileView({super.key, this.accountPageBuilder});

  final WidgetBuilder? accountPageBuilder;

  static const Key notBuiltKey = Key('shell.profile.notBuilt');
  static const Key accountEntryKey = Key('shell.profile.accountEntry');

  @override
  Widget build(BuildContext context) {
    final WidgetBuilder? accountPage = accountPageBuilder;
    if (accountPage != null) {
      return ChoreiaBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(UiLanguage.text(context, en: 'Profile', tr: 'Profil'),
                      style: ChoreiaType.display(size: 24)),
                  const SizedBox(height: 12),
                  Text(
                    UiLanguage.text(
                      context,
                      en: 'Browse dance styles without an account. Live The Bounce practice requires a Motion account and Choreia or Motion+ membership.',
                      tr: 'Dans türlerine hesap açmadan göz atabilirsiniz. Canlı The Bounce pratiği için Motion hesabı ve Choreia veya Motion+ üyeliği gerekir.',
                    ),
                    style: ChoreiaType.body(size: 13.5),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    key: accountEntryKey,
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(builder: accountPage),
                    ),
                    child: Text(
                        UiLanguage.text(context, en: 'Account', tr: 'Hesap')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return notBuiltTabBody(
      context,
      key: notBuiltKey,
      title: UiLanguage.text(context, en: 'Profile', tr: 'Profil'),
      plannedContent: UiLanguage.text(
        context,
        en: 'Account creation and membership access are not connected. '
            'Camera permissions, practice data controls, and legal links '
            'are also not available on this screen.',
        tr: 'Hesap oluşturma ve üyelik erişimi bağlı değil. Kamera '
            'izinleri, pratik verisi denetimleri ve yasal bağlantılar da '
            'bu ekranda kullanılamıyor.',
      ),
    );
  }
}
