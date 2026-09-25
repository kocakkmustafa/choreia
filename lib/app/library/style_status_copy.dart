import '../style_availability.dart';
import 'library_catalog.dart';

/// Localizes derived availability without translating arbitrary dance prose.
/// The source of truth remains StyleView's status and release gate, so a gate
/// change changes both language surfaces at the same time.
abstract final class StyleStatusCopy {
  static String? reason(StyleCard card, {required bool turkish}) {
    final String? authored = card.entry.onHoldReason;
    if (!turkish) return authored ?? card.view.userFacingReason;

    if (authored != null) {
      // This is an authored cultural decision, not a generic status. Only use
      // the reviewed translation while the source sentence is still exact;
      // changed content stays visible in English until reviewed again.
      if (card.entry.id == 'hula' && authored == _hulaSource) {
        return _hulaTurkish;
      }
      return authored;
    }

    return switch (card.view.availability) {
      Availability.openable || Availability.excluded => null,
      Availability.comingSoon =>
        'Açık değil — bugün burada başlatılabilecek bir ders yok.',
      Availability.onHold =>
        'Bilinçli olarak duraklatıldı. Gerekçe stil sayfasında.',
      Availability.gatedByRelease => card.view.releaseBlockers.isNotEmpty &&
              card.view.releaseBlockers.first.id == 'bpmResolved'
          ? 'Açık değil — bu stilin müzik vuruşu henüz doğrulanmadı. '
              'Emin olmadığımız bir sayımla zamanlamana puan vermiyoruz.'
          : 'Açık değil — stili açmadan önce yaptığımız bir kontrol '
              'henüz tamamlanmadı.',
    };
  }

  static const String _hulaSource =
      'Hula is a living cultural and spiritual practice, taught inside a hālau '
      'under a kumu hula — that relationship is the form, not a framing around '
      'it. We are not going to build lessons for it from general-purpose '
      'sources, and we would rather leave this page empty than do that. It is '
      'on hold until it can be done in partnership with hula practitioners, '
      'and that is a decision rather than a place in a queue.';

  static const String _hulaTurkish =
      'Hula, bir hālau içinde kumu hula rehberliğinde öğretilen yaşayan '
      'kültürel ve manevi bir pratiktir; bu ilişki biçimin kendisinin '
      'parçasıdır. Genel kaynaklardan Hula dersi hazırlamıyoruz. Hula '
      'uygulayıcılarıyla ortaklık kurulmadan bu sayfayı boş bırakmayı '
      'seçiyoruz. Bu stil bilinçli olarak duraklatıldı; bir sırada beklemiyor.';
}
