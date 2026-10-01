/// Reviewed Turkish copy for the currently open Bounce lesson's live path.
/// Each translation is tied to the lesson and the exact English sentence or
/// measurement label. A changed source stays visible in English for review.
abstract final class LiveLessonCopy {
  static String identityLimit(String? lessonId, String source,
          {required bool turkish}) =>
      _choose(lessonId, source, _identityLimits, turkish: turkish);

  static String gatedReason(String? lessonId, String code, String source,
          {required bool turkish}) =>
      _choose('$lessonId/$code', source, _gatedReasons, turkish: turkish);

  static String measurementLabel(String? lessonId, String key, String source,
          {required bool turkish}) =>
      lessonId == 'hh_l1_bounce'
          ? _choose(key, source, _measurementLabels, turkish: turkish)
          : source;

  static String _choose(
    String? id,
    String source,
    Map<String, _ReviewedCopy> translations, {
    required bool turkish,
  }) {
    final _ReviewedCopy? copy = translations[id];
    return turkish && copy != null && copy.source == source
        ? copy.turkish
        : source;
  }

  static const Map<String, _ReviewedCopy> _identityLimits = {
    'hh_l1_bounce': _ReviewedCopy(
      'One thing we are not doing: checking that the move you are dancing is '
          'the one this lesson teaches. If you danced something else entirely, '
          'we would not say "wrong step". A reading or a lack of findings here '
          'is not proof that you practiced this step.',
      'Yapmadığımız bir kontrol var: dans ettiğiniz hareketin bu derste '
          'öğretilen adım olup olmadığını doğrulamıyoruz. Bambaşka bir '
          'hareket yapsanız “yanlış adım” demeyiz. Buradaki bir ölçüm veya '
          'hata görülmemesi, bu adımı çalıştığınızın kanıtı değildir.',
    ),
  };

  static const Map<String, _ReviewedCopy> _gatedReasons = {
    'hh_l1_bounce/WRONG_FOOT': _ReviewedCopy(
      'We are not checking which foot you start on. The measured reference '
          'does not distinguish left and right reliably for this movement, '
          'so calling your starting foot wrong would be a coin flip '
          'presented as a judgement.',
      'Hangi ayakla başladığınızı kontrol etmiyoruz. Ölçülmüş referans '
          'bu harekette sağı ve solu güvenilir biçimde ayıramıyor. '
          'Başlangıç ayağınıza “yanlış” demek, rastgele bir kararı '
          'değerlendirme gibi sunmak olurdu.',
    ),
  };

  static const Map<String, _ReviewedCopy> _measurementLabels = {
    'kneeDeltaDeg': _ReviewedCopy('Knee delta', 'Diz açısı değişimi'),
    'thighDeltaDeg': _ReviewedCopy('Thigh delta', 'Uyluk açısı değişimi'),
    'identityShapeDeg': _ReviewedCopy(
      'Identity shape',
      'Referansa göre hareket biçimi farkı',
    ),
    'identityLegShapeDeg': _ReviewedCopy(
      'Identity leg shape',
      'Referansa göre bacak biçimi farkı',
    ),
    'identityWorstJointDeg': _ReviewedCopy(
      'Identity worst joint',
      'Referansa göre en büyük eklem farkı',
    ),
    'sideDirectDeg': _ReviewedCopy(
      'Side direct',
      'Düz yönde eşleşme açısı',
    ),
    'sideMirroredDeg': _ReviewedCopy(
      'Side mirrored',
      'Aynalı yönde eşleşme açısı',
    ),
    'sideMarginDeg': _ReviewedCopy(
      'Side margin',
      'Yönler arası açı farkı',
    ),
  };
}

final class _ReviewedCopy {
  const _ReviewedCopy(this.source, this.turkish);

  final String source;
  final String turkish;
}
