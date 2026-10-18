import 'package:flutter/material.dart';

import 'not_built_tab_body.dart';
import '../onboarding/first_run_view.dart';
import '../theme.dart';
import '../ui_language.dart';

/// Optional shared account entry and licenses for the five written dance paths.
/// Practice journals remain local and scoped to the current guest or account.
/// The unconfigured fallback is used by isolated hosts without an account route.
class ProfileView extends StatelessWidget {
  const ProfileView(
      {super.key,
      this.accountPageBuilder,
      this.cameraSessionsAvailable = false});

  final WidgetBuilder? accountPageBuilder;
  final bool cameraSessionsAvailable;

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
                      en: 'Explore five solo dance paths without an account or camera. Practice records stay on this device within your guest or account scope and reflect your own study. A Motion account is optional. ${IntroStrings.cameraStatus(cameraSessionsAvailable)}',
                      tr: 'Beş solo dans yolunu hesap veya kamera olmadan çalışabilirsiniz. Çalışma kayıtları bu cihazda konuk veya hesabınız kapsamında kalır ve kendi çalışmanızı gösterir. Motion hesabı isteğe bağlıdır. ${IntroStrings.cameraStatus(cameraSessionsAvailable, turkish: true)}',
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
                'are also not available on this screen. '
                '${IntroStrings.cameraStatus(cameraSessionsAvailable)}',
            tr: 'Hesap oluşturma ve üyelik erişimi bağlı değil. Kamera '
                'izinleri ve pratik verisi denetimleri de '
                'bu ekranda kullanılamıyor. '
                '${IntroStrings.cameraStatus(cameraSessionsAvailable, turkish: true)}',
          ),
        )),
        SafeArea(top: false, child: _licensesButton(context)),
      ],
    );
  }
}
