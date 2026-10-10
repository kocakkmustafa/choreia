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
  static const Key licensesEntryKey = Key('shell.profile.licensesEntry');

  Widget _licensesButton(BuildContext context) => TextButton(
        key: licensesEntryKey,
        onPressed: () =>
            showLicensePage(context: context, applicationName: 'Choreia'),
        child: Text(UiLanguage.text(context, en: 'Licenses', tr: 'Lisanslar')),
      );

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
                      en: 'Learn Salsa On1 without an account or camera. Course progress stays on this device and reflects your own practice record. A Motion account is optional. Live camera practice and subscription sales are closed in this release.',
                      tr: 'Salsa On1 kursunu hesap veya kamera olmadan çalışabilirsiniz. Kurs ilerlemesi bu cihazda kalır ve kendi çalışma kaydınızı gösterir. Motion hesabı isteğe bağlıdır. Bu sürümde canlı kamera pratiği ve abonelik satışı kapalıdır.',
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
                  _licensesButton(context),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Column(
      children: <Widget>[
        Expanded(
            child: notBuiltTabBody(
          context,
          key: notBuiltKey,
          title: UiLanguage.text(context, en: 'Profile', tr: 'Profil'),
          plannedContent: UiLanguage.text(
            context,
            en: 'Account creation and membership access are not connected. '
                'Camera permissions and practice data controls '
                'are also not available on this screen.',
            tr: 'Hesap oluşturma ve üyelik erişimi bağlı değil. Kamera '
                'izinleri ve pratik verisi denetimleri de '
                'bu ekranda kullanılamıyor.',
          ),
        )),
        SafeArea(top: false, child: _licensesButton(context)),
      ],
    );
  }
}
