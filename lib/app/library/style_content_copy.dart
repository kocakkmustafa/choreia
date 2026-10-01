import '../course_catalog.dart';
import 'library_catalog.dart';

/// Reviewed TR copy for the currently open style and its lesson cards.
/// A translation is used only when both the content id and the current English
/// source match. An edit to authored content therefore falls back to its source
/// language until the translation is reviewed again.
abstract final class StyleContentCopy {
  static String styleName(LibraryEntry entry, {required bool turkish}) =>
      _choose(entry.id, entry.displayName, _styleNames, turkish: turkish);

  static String? styleDescription(LibraryEntry entry, {required bool turkish}) {
    final String? source = entry.description;
    if (source == null) return null;
    return _choose(entry.id, source, _styleDescriptions, turkish: turkish);
  }

  static String? originAttribution(LibraryEntry entry,
      {required bool turkish}) {
    final String? source = entry.originAttribution;
    if (source == null) return null;
    return _choose(entry.id, source, _originAttributions, turkish: turkish);
  }

  static String lessonName(LessonInfo lesson, {required bool turkish}) =>
      _choose(lesson.id, lesson.displayName, _lessonNames, turkish: turkish);

  static String? lessonReason(LessonInfo lesson, String? source,
      {required bool turkish}) {
    if (source == null) return null;
    return _choose(lesson.id, source, _lessonReasons, turkish: turkish);
  }

  static String? lessonWhyPermanent(LessonInfo lesson,
      {required bool turkish}) {
    final String? source = lesson.whyPermanent;
    if (source == null) return null;
    return _choose(lesson.id, source, _permanenceReasons, turkish: turkish);
  }

  static String? reproductionBoundary(
    String styleId,
    String? source, {
    required bool turkish,
  }) {
    if (source == null) return null;
    return _choose(styleId, source, _reproductionBoundaries, turkish: turkish);
  }

  static String glossaryGloss(
    String styleId,
    GlossaryEntry entry, {
    required bool turkish,
  }) =>
      _choose('$styleId/${entry.name}', entry.gloss, _glossary,
          turkish: turkish);

  static String honestyNotMeasured(
    String styleId,
    String source, {
    required bool turkish,
  }) {
    if (!turkish || styleId != 'hip_hop_foundations') return source;
    return _hipHopNotMeasured[source] ?? source;
  }

  static String _choose(
    String id,
    String source,
    Map<String, _ReviewedCopy> translations, {
    required bool turkish,
  }) {
    final _ReviewedCopy? copy = translations[id];
    return turkish && copy != null && copy.source == source
        ? copy.turkish
        : source;
  }

  static const Map<String, _ReviewedCopy> _styleNames = {
    'hip_hop_foundations': _ReviewedCopy(
      'Hip-Hop Foundations',
      'Hip-Hop Temelleri',
    ),
  };

  static const Map<String, _ReviewedCopy> _styleDescriptions = {
    'hip_hop_foundations': _ReviewedCopy(
      'The party-dance foundations the rest of hip-hop is built on — a '
          'steady bounce, a rock through the chest, and the named steps that '
          'grew out of them. You dance them on the spot, to the count, '
          'before anything gets fancy.',
      'Hip-hop dansının temelindeki parti dansı hareketleri: düzenli bir '
          'Bounce, göğüsten gelen Rock ve bunlardan gelişen adımlar. '
          'Hareketler yerinde, sayarak yapılır.',
    ),
  };

  static const Map<String, _ReviewedCopy> _originAttributions = {
    'hip_hop_foundations': _ReviewedCopy(
      "Hip-hop's foundational party dances were made by Black American young "
          'people at parties, in parks and in clubs from the 1970s onward — '
          'in New York, and, for much of the groove vocabulary, in the funk '
          "scenes of California. What is taught here is social-dance "
          "vocabulary that belongs to those communities, not any one "
          "choreographer's routine.",
      'Hip-hop’ın temelini oluşturan parti danslarını 1970’lerden itibaren '
          'Siyah Amerikalı gençler New York’taki partilerde, parklarda ve '
          'kulüplerde geliştirdi. Groove hareketlerinin önemli bir bölümü '
          'Kaliforniya’daki funk sahnelerinde gelişti. Burada öğretilen '
          'sosyal dans hareketleri bu topluluklara aittir; tek bir '
          'koreografın özgün rutini değildir.',
    ),
  };

  static const Map<String, _ReviewedCopy> _lessonNames = {
    'hh_l1_bounce': _ReviewedCopy(
      'The bounce (not graded)',
      'The Bounce (puanlanmıyor)',
    ),
    'hh_l1_rock': _ReviewedCopy('The rock', 'The Rock'),
    'hh_l1_running_man': _ReviewedCopy(
      'The Running Man (not graded)',
      'The Running Man (puanlanmıyor)',
    ),
    'hh_l1_groove': _ReviewedCopy(
      'Groove and feel (not graded)',
      'Groove ve his (puanlanmıyor)',
    ),
    'hh_l1_roger_rabbit': _ReviewedCopy(
      'The Roger Rabbit (not graded)',
      'The Roger Rabbit (puanlanmıyor)',
    ),
    'hh_bounce_slow': _ReviewedCopy(
      'Bounce, half speed',
      'Yarım hızda Bounce',
    ),
    'hh_bounce_wall': _ReviewedCopy(
      'Bounce against a wall',
      'Duvara dayanarak Bounce',
    ),
  };

  static const Map<String, _ReviewedCopy> _lessonReasons = {
    'hh_l1_bounce': _ReviewedCopy(
      'We measured three teachers doing this step, and the result was not '
          'the one we expected: they move so alike that the differences '
          'between them are smaller than what a phone camera can reliably '
          'resolve. A score here would mostly be measuring our own '
          'uncertainty rather than your bounce. So you get the step, the '
          "count and three teachers' versions of it — the number is the "
          'part we are leaving out, and we would rather say that than hand '
          'you a confident-looking one.',
      'Bu adımı yapan üç eğitmeni ölçtük. Beklediğimizin aksine hareketleri '
          'birbirine o kadar benziyor ki aralarındaki farkı telefon kamerası '
          'güvenilir biçimde ayırt edemiyor. Bu durumda bir puan, senin '
          'hareketinden çok ölçüm belirsizliğimizi yansıtırdı. Adımı ve '
          'tekrar sayısını gösteriyor, eğitmen ölçümlerini referans alıyoruz; '
          'kesinmiş gibi görünen bir puan vermiyoruz.',
    ),
    'hh_l1_rock': _ReviewedCopy(
      'The step is written down now, but no teachers have been measured '
          'doing it. We grade you against what several independent '
          'instructors actually agree on — a written description is not '
          'that, and we are not going to score you against our own writing.',
      'Bu adımın tanımı yazıldı, ancak onu yaparken hiçbir eğitmen ölçülmedi. '
          'Puanlama için bağımsız eğitmenlerin hareket üzerinde gerçekten '
          'uzlaşması gerekir. Yazılı tanım bunun yerini tutmaz; seni kendi '
          'yazdığımız tanıma göre puanlamayacağız.',
    ),
    'hh_l1_running_man': _ReviewedCopy(
      'This one we can teach but not grade, and the reason is specific: the '
          'Running Man works through the timing of your ball and heel '
          'touching the floor — that is what makes it look like running in '
          'place. Toe and heel points are the least reliable thing a phone '
          'camera tracks, so any score we gave you would mostly be measuring '
          "our own uncertainty. You get the step, the count and four teachers' "
          "versions of it; you don't get a number.",
      'The Running Man öğretilebilir ama puanlanamaz. Yerinde koşma görünümünü '
          'ayağın ön bölümünün ve topuğun yere temas zamanlaması oluşturur. '
          'Telefon kamerası ayak ucu ve topuk noktalarını en düşük '
          'güvenilirlikle izler; vereceğimiz puan büyük ölçüde kendi ölçüm '
          'belirsizliğimizi yansıtırdı. Adımı ve sayımı gösteriyoruz; dört '
          'eğitmenin ölçümlerini referans alıyoruz, puan vermiyoruz.',
    ),
    'hh_l1_groove': _ReviewedCopy(
      'Groove is the part of hip-hop a camera is worst at and a mirror is best '
          'at. We teach it and stay out of your way.',
      'Groove, hip-hop içinde kameranın en zor algıladığı; aynada kendini '
          'izleyerek en iyi fark edebileceğin bölümlerden biri. Öğretiyoruz '
          've puanla araya girmiyoruz.',
    ),
    'hh_l1_roger_rabbit': _ReviewedCopy(
      'This one we can teach but not grade, and the reason is different from '
          "our other demo-only steps: it isn't that the camera can't see the "
          "Roger Rabbit clearly, it's that our own teachers don't agree on "
          "which way round it faces. Three instructors' footage should "
          "settle a consistent left-or-right convention and it hasn't, so "
          'we cannot tell a correctly-mirrored performance from a genuinely '
          "backwards one. You get the step and three teachers' versions of "
          "it; the number is missing because our reference isn't settled, "
          'not because your movement is unclear.',
      'The Roger Rabbit öğretilebilir ama puanlanamaz. Sorun kameranın '
          'hareketi görememesi değil; ölçtüğümüz üç eğitmenin sağ ve sol '
          'yönü konusunda ortak bir referans oluşturmaması. Bu yüzden doğru '
          'ayna yansımasını ters yapılmış bir hareketten güvenle ayıramıyoruz. '
          'Adımı gösteriyoruz; puanın olmaması senin hareketinin belirsiz '
          'olduğu anlamına gelmiyor.',
    ),
    'hh_bounce_slow': _ReviewedCopy(
      'The bounce at half tempo, with the count said out loud. Most beginners '
          'either stand still to the music or arrive at the bottom on the '
          "'and' instead of on the beat — both are much easier to feel slowly "
          'than to see at speed. Same movement, more time to notice where the '
          'bottom actually lands, and whether one knee is doing more work '
          'than the other.',
      'Bounce hareketini yarım tempoda, sayımı sesli yaparak dene. Yeni '
          'başlayanlar çoğu zaman müzikte hareketsiz kalır ya da en alt '
          'noktaya vuruşta değil aradaki “ve” sayımında ulaşır. Yavaşlamak, '
          'bu zamanlamayı ve dizlerden birinin diğerinden fazla çalışıp '
          'çalışmadığını fark etmene yardımcı olur.',
    ),
    'hh_bounce_wall': _ReviewedCopy(
      'Stand with your back lightly against a wall and bounce. The wall does '
          'the checking for you: if you are bending at the waist instead of '
          'the knees, your back leaves the wall and you feel it immediately. '
          'A deliberate forward-leaning groove is a real style choice — this '
          'drill is about noticing when the lean is happening by accident.',
      'Sırtını hafifçe duvara yaslayıp Bounce yap. Dizler yerine belden '
          'eğilirsen sırtının duvardan ayrıldığını hemen hissedersin. '
          'Bilerek öne eğilmek bir stil tercihi olabilir; bu alıştırma '
          'istemeden eğildiğin anı fark etmen içindir.',
    ),
  };

  static const Map<String, _ReviewedCopy> _permanenceReasons = {
    'hh_l1_running_man': _ReviewedCopy(
      'What decides whether a Running Man is right is the timing of the ball '
          'and heel of your foot meeting the floor — a few hundredths of a '
          'second, at the two points a phone camera tracks worst. That is not '
          'a limitation we expect to out-wait: more teachers would not move '
          'those landmarks. If we ever score this step it will be because the '
          'measurement changed, not because we got more data.',
      'The Running Man’in doğruluğunu ayağın ön bölümünün ve topuğun yere '
          'temas zamanlaması belirler. Aradaki fark saniyenin yüzde birleri '
          'düzeyindedir ve telefon kamerasının en zor izlediği noktalardadır. '
          'Daha fazla eğitmen ölçmek bu noktaları daha güvenilir kılmaz. '
          'Bu adımı bir gün puanlarsak nedeni daha çok veri değil, ölçüm '
          'yönteminin değişmesi olacaktır.',
    ),
    'hh_l1_groove': _ReviewedCopy(
      'Groove is not a quantity a camera can see. Two dancers can produce '
          'almost the same joint angles and only one of them is grooving; the '
          'difference lives in the music and in you, not in the geometry we '
          'can measure. We teach it throughout and we will not put a number '
          'on it.',
      'Groove kameranın ölçebileceği bir nicelik değildir. İki dansçı '
          'neredeyse aynı eklem açılarını oluşturabilir ama yalnız biri '
          'müziği hareketine yansıtabilir. Bu fark ölçebildiğimiz geometriden '
          'çok müzik ve dansçıyla ilgilidir. Öğretmeye devam ederiz, '
          'puanlamayız.',
    ),
    'hh_bounce_slow': _ReviewedCopy(
      'A drill is a correction, not a performance. There is no such thing as '
          'several teachers agreeing on the right way to do the bounce at '
          'half speed — the slow version exists to let you feel something, '
          'not to be judged. Grading it would mean grading a target we made up.',
      'Alıştırma bir performans değil, düzeltme aracıdır. Yarım hızdaki '
          'Bounce, bir şeyi hissetmen için vardır; eğitmenlerin ortak '
          'belirlediği puanlama hedefi değildir. Puanlamak, kendi '
          'uydurduğumuz bir hedefe göre hüküm vermek olurdu.',
    ),
    'hh_bounce_wall': _ReviewedCopy(
      'The wall is the feedback here, not us. This drill is a way of checking '
          'yourself, and putting a score on it would replace the thing that '
          'actually teaches it — noticing your own back leaving the wall.',
      'Bu alıştırmada geri bildirimi duvar verir. Sırtının duvardan '
          'ayrıldığını kendin fark etmen öğretici kısımdır; buna puan '
          'eklemek o geri bildirimin yerini alırdı.',
    ),
  };

  static const Map<String, _ReviewedCopy> _reproductionBoundaries = {
    'hip_hop_foundations': _ReviewedCopy(
      "Isolated steps are low risk; copying one instructor's original long "
          'sequence verbatim is not. Combos in this style must be our own '
          'arrangement.',
      'Tek tek adımlarda kopyalama riski düşüktür; bir eğitmenin özgün uzun '
          'hareket dizisini aynen almakta risk vardır. Bu stildeki '
          'kombinasyonları kendimiz düzenlemeliyiz.',
    ),
  };

  static const Map<String, _ReviewedCopy> _glossary = {
    'hip_hop_foundations/Bounce': _ReviewedCopy(
      'The steady up-and-down through the knees that most hip-hop grooves sit on.',
      'Çoğu hip-hop groove’unun temelindeki, dizlerden gelen düzenli '
          'yukarı-aşağı hareket.',
    ),
    'hip_hop_foundations/Rock': _ReviewedCopy(
      'A tilt through the chest and hips, driven from the body rather than the feet.',
      'Ayaklardan değil gövdeden başlayan, göğüs ve kalçadan geçen eğilme.',
    ),
    'hip_hop_foundations/Running Man': _ReviewedCopy(
      'Running on the spot without travelling — the feet slide back as the knee lifts.',
      'Yer değiştirmeden koşma hissi: diz yükselirken ayaklar geriye kayar.',
    ),
    'hip_hop_foundations/Roger Rabbit': _ReviewedCopy(
      "The Running Man's mirror image: the leg kicks back as the body leans forward.",
      'The Running Man’in ayna görüntüsü: gövde öne eğilirken bacak geriye uzanır.',
    ),
  };

  static const Map<String, String> _hipHopNotMeasured = {
    'The Running Man — we have measured 4 independent teachers doing it, and '
            'we still will not grade it: what makes this step right or wrong is '
            'the timing of the ball and heel of the foot touching the floor, and '
            'toe landmarks are the least reliable points a single phone camera '
            'produces. We can show you the step; scoring it would be scoring our '
            'own noise.':
        'The Running Man — 4 bağımsız eğitmeni ölçtük, yine de puanlamıyoruz. '
            'Bu adımın doğruluğu ayağın ön bölümü ve topuğunun yere temas '
            'zamanlamasına bağlı. Tek telefon kamerasının en az güvenilir '
            'izlediği noktalar ayak uçlarıdır. Adımı gösterebiliriz; '
            'puanlamak kendi ölçüm gürültümüzü puanlamak olurdu.',
    'The Roger Rabbit — reference built from 3 teachers, but they disagree '
            'about which way round the step is danced (mirrorConfident:false), '
            'so we cannot tell a mirrored performance from a wrong one. Shown, '
            'not graded, until more teachers settle it.':
        'The Roger Rabbit — 3 eğitmenden referans oluşturduk, ancak adımın '
            'sağ ve sol yönü konusunda uzlaşma yok. Doğru ayna yansımasını '
            'hatalı hareketten ayıramıyoruz. Daha fazla eğitmenle bu yön '
            'belirsizliği çözülene kadar gösteriyoruz, puanlamıyoruz.',
    'The Bounce — three independent teachers HAVE now been measured, and the '
            'step is still not graded, for a reason we only learned by measuring: '
            'those teachers agree with each other more closely than our own '
            'camera noise. 83% of the tolerance we would grade you against comes '
            'from that noise floor rather than from anything they actually '
            'disagree about; in the lessons we do grade, that share is 9-28%. '
            "The movement itself is detected fine — every dip clears the step's "
            'own thresholds. What we cannot honestly do is turn that into a '
            'number about you.':
        'The Bounce — 3 bağımsız eğitmeni ölçtük, ancak adımı hâlâ '
            'puanlamıyoruz. Eğitmenlerin hareketleri arasındaki fark kamera '
            'gürültümüzden daha küçük. Puanlamada kullanacağımız toleransın '
            '%83’ü bu gürültü tabanından geliyor; puanladığımız derslerde '
            'bu pay %9–28. Hareketin her alçalma anı kendi eşiklerinden '
            'geçiyor, yani hareketi algılıyoruz. Bunu senin hakkında dürüst '
            'bir sayısal puana çeviremiyoruz.',
    'Groove, feel and musicality — a camera cannot see whether the music is '
            'in you. Taught throughout, never scored (plan §22).':
        'Groove, his ve müzikalite — kamera müziği nasıl hissettiğini '
            'göremez. Bunları öğretiyoruz, puanlamıyoruz.',
    'Rock and Groove — Rock has an authored step definition, but no teacher '
            'has been measured doing it and no grading reference exists; its '
            'lesson stays locked. Groove is taught as feel and musicality, '
            'not authored as a measurable step, so there is no camera check '
            'for it.':
        'Rock ve Groove — Rock adımının tanımı hazır, ancak Rock yapan hiçbir '
            'eğitmen ölçülmedi; puanlama referansı yok ve dersi kilitli. '
            'Groove, his ve müzikalite olarak öğretiliyor; kamerayla '
            'ölçülecek bir adım olarak hazırlanmadı, bu yüzden kamera '
            'kontrolü yok.',
  };
}

final class _ReviewedCopy {
  const _ReviewedCopy(this.source, this.turkish);

  final String source;
  final String turkish;
}
