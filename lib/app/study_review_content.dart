// Authored reading/recall activities derived from the source references below.
// These do not promote physical instruction, media rights, scoring or mastery.
final class StudyText {
  const StudyText(this.en, this.tr);
  final String en, tr;
}

final class RecallLesson {
  const RecallLesson({
    required this.id,
    required this.title,
    required this.teaching,
    required this.question,
    required this.answer,
  });
  final String id;
  final StudyText title, teaching, question, answer;
}

final class StudyArea {
  const StudyArea({
    required this.id,
    required this.title,
    required this.boundary,
    required this.sourceRefs,
    required this.lessons,
  });
  final String id;
  final StudyText title, boundary;
  final List<String> sourceRefs;
  final List<RecallLesson> lessons;
}

const List<StudyArea> studyAreas = <StudyArea>[
  StudyArea(
    id: "hiphop",
    title: StudyText("HipHop Foundations", "HipHop Temelleri"),
    boundary: StudyText(
      "Reading and written recall only; no movement is needed. Demonstration, personal suitability and physical technique require separate review.",
      "Yalnız okuma ve yazılı hatırlama; hareket gerekmez. Gösterim, kişisel uygunluk ve fiziksel teknik ayrı inceleme gerektirir.",
    ),
    sourceRefs: <String>[
      "content/hip_hop_foundations_skill_course.json#hhs_01",
      "content/hip_hop_foundations_skill_course.json#hhs_02",
    ],
    lessons: <RecallLesson>[
      RecallLesson(
        id: "hiphop.1",
        title: StudyText("Pulse and phrase", "Vuruş ve cümle"),
        teaching: StudyText(
          "A regular pulse, an eight-count and a musical phrase are different ideas. A chosen count 1 is not automatically the start of a phrase. An offbeat divides adjacent beats.",
          "Düzenli vuruş, sekizli sayım ve müzikal cümle farklıdır. Seçilen 1 sayımı otomatik olarak cümle başlangıcı değildir. Ara vuruş, komşu vuruşları böler.",
        ),
        question: StudyText(
          "Explain why counting eight metronome beats alone cannot establish musical phrasing.",
          "Yalnız sekiz metronom vuruşu saymanın müzikal cümleyi neden kanıtlamadığını açıkla.",
        ),
        answer: StudyText(
          "It establishes a count against a pulse. A phrase boundary requires an audible musical reference; if no music was used, leave phrasing unobserved.",
          "Vuruşa karşı sayımı kurar. Cümle sınırı duyulur müzik referansı gerektirir; müzik kullanılmadıysa cümleyi gözlenmedi bırak.",
        ),
      ),
      RecallLesson(
        id: "hiphop.2",
        title: StudyText("Support and direction", "Destek ve yön"),
        teaching: StudyText(
          "The course names the dancer’s own left and right. A step transfers support; a touch does not. A screen image cannot establish the pressure through a foot.",
          "Kurs dansçının kendi sol ve sağını adlandırır. Adım desteği aktarır; dokunuş aktarmaz. Ekran görüntüsü ayaktaki basıncı kanıtlamaz.",
        ),
        question: StudyText(
          "After a right step and a left touch, name the supporting foot on paper.",
          "Sağ adım ve sol dokunuştan sonra destek ayağını kâğıtta adlandır.",
        ),
        answer: StudyText(
          "Right remains the support. If the touch takes weight, this is a different action. Describe the uncertainty rather than reporting a correct weight transfer from appearance.",
          "Destek sağda kalır. Dokunuş ağırlık alırsa farklı eylemdir. Görünüşten doğru ağırlık aktarımı bildirmek yerine belirsizliği açıkla.",
        ),
      ),
    ],
  ),
  StudyArea(
    id: "salsa",
    title: StudyText("Salsa Shines", "Salsa Shines"),
    boundary: StudyText(
      "Reading and written recall only; no movement is needed. Demonstration, personal suitability and physical technique require separate review.",
      "Yalnız okuma ve yazılı hatırlama; hareket gerekmez. Gösterim, kişisel uygunluk ve fiziksel teknik ayrı inceleme gerektirir.",
    ),
    sourceRefs: <String>[
      "content/salsa_on1_course.json#so_04",
      "content/salsa_on1_course.json#so_06",
    ],
    lessons: <RecallLesson>[
      RecallLesson(
        id: "salsa.1",
        title: StudyText("Read the On1 count", "On1 sayımını oku"),
        teaching: StudyText(
          "This course’s basic names left-right-left on 1-2-3 and right-left-right on 5-6-7. Counts 4 and 8 continue without a new primary step. This is a solo course, not partner leading/following.",
          "Bu kursun temeli 1-2-3’te sol-sağ-sol, 5-6-7’de sağ-sol-sağ adlandırır. 4 ve 8’de yeni ana adım olmadan sayım sürer. Bu solo kurstur; eşli liderlik/takip değildir.",
        ),
        question: StudyText(
          "Write the eight counts; distinguish a count from a new step.",
          "Sekiz sayımı yaz; sayıyla yeni adımı ayır.",
        ),
        answer: StudyText(
          "1 L, 2 R, 3 L, 4 count; 5 R, 6 L, 7 R, 8 count. Counting continues through both pauses.",
          "1 sol, 2 sağ, 3 sol, 4 sayım; 5 sağ, 6 sol, 7 sağ, 8 sayım. İki durakta da sayım sürer.",
        ),
      ),
      RecallLesson(
        id: "salsa.2",
        title: StudyText("Compare one location", "Tek noktayı karşılaştır"),
        teaching: StudyText(
          "A useful correction compares the same transition or foot-order location in the same short sequence. Changing arms, direction and count together obscures what changed.",
          "Yararlı düzeltme aynı kısa dizide aynı geçişi veya ayak sırası noktasını karşılaştırır. Kolları, yönü ve sayımı birlikte değiştirmek değişeni gizler.",
        ),
        question: StudyText(
          "Your written sequence has one wrong foot on count 6. What should a second written attempt compare?",
          "Yazılı dizinde 6’da tek yanlış ayak var. İkinci yazılı deneme neyi karşılaştırmalı?",
        ),
        answer: StudyText(
          "Keep the same sequence and examine count 6 only. Rewrite that location, then recall the same passage without the reference; do not infer physical timing from this answer.",
          "Aynı diziyi koru, yalnız 6’yı incele. O noktayı yeniden yaz, aynı kısmı kaynaksız hatırla; bu cevaptan fiziksel zamanlama sonucu çıkarma.",
        ),
      ),
    ],
  ),
  StudyArea(
    id: "line",
    title: StudyText("Line Dance", "Line Dance"),
    boundary: StudyText(
      "Reading and written recall only; no movement is needed. Demonstration, personal suitability and physical technique require separate review.",
      "Yalnız okuma ve yazılı hatırlama; hareket gerekmez. Gösterim, kişisel uygunluk ve fiziksel teknik ayrı inceleme gerektirir.",
    ),
    sourceRefs: <String>[
      "content/line_dance_beginner_course.json#ld_01",
      "content/line_dance_beginner_course.json#ld_02",
    ],
    lessons: <RecallLesson>[
      RecallLesson(
        id: "line.1",
        title: StudyText("Step versus touch", "Adım ve dokunuş"),
        teaching: StudyText(
          "In the lesson’s four-count example: right step, left touch, left step, right touch. Support after each count is right, right, left, left. Touch adds no transfer.",
          "Dersin dört sayımlık örneği: sağ adım, sol dokunuş, sol adım, sağ dokunuş. Her sayı sonrası destek sağ, sağ, sol, sol olur. Dokunuş aktarım eklemez.",
        ),
        question: StudyText(
          "Which foot supports counts 2 and 4? Explain without moving.",
          "2 ve 4’te hangi ayak destekler? Hareket etmeden açıkla.",
        ),
        answer: StudyText(
          "Right on 2; left on 4. The closing foot touches without taking support. If support is unknown, leave it uncertain.",
          "2’de sağ; 4’te sol. Yaklaşan ayak destek almadan dokunur. Destek bilinmiyorsa belirsiz bırak.",
        ),
      ),
      RecallLesson(
        id: "line.2",
        title: StudyText("Dancer-relative directions", "Dansçıya göre yönler"),
        teaching: StudyText(
          "Front follows the dancer’s facing direction. Right means the dancer’s own right, not the viewer’s screen-right. A top-down diagram is a notation aid, not footage of correct technique.",
          "Ön, dansçının baktığı yönü izler. Sağ, ekrana bakanın sağı değil dansçının kendi sağıdır. Üstten şema bir gösterim aracıdır; doğru teknik videosu değildir.",
        ),
        question: StudyText(
          "A dancer turns to a new wall. Does their front stay fixed to the phone?",
          "Dansçı yeni duvara döner. Önü telefona sabit mi kalır?",
        ),
        answer: StudyText(
          "No. Front follows facing. Label your own left/right and the new front on paper before decoding the next row.",
          "Hayır. Ön bakış yönünü izler. Sonraki satırı çözmeden kâğıtta kendi sol/sağını ve yeni önü işaretle.",
        ),
      ),
    ],
  ),
  StudyArea(
    id: "latin",
    title: StudyText("Latin Fusion Fitness", "Latin Fusion Fitness"),
    boundary: StudyText(
      "Reading and written recall only; no movement is needed. Demonstration, personal suitability and physical technique require separate review.",
      "Yalnız okuma ve yazılı hatırlama; hareket gerekmez. Gösterim, kişisel uygunluk ve fiziksel teknik ayrı inceleme gerektirir.",
    ),
    sourceRefs: <String>[
      "content/latin_fusion_beginner_course.json#lf_02",
      "content/latin_fusion_beginner_course.json#lf_03",
    ],
    lessons: <RecallLesson>[
      RecallLesson(
        id: "latin.1",
        title: StudyText("Read W, T and H", "W, T ve H oku"),
        teaching: StudyText(
          "In this course’s notation W transfers weight, T touches without transfer and H holds the existing support. A support ledger distinguishes these actions even when the same foot stays supporting.",
          "Bu kursun gösteriminde W ağırlık aktarır, T aktarmadan dokunur, H mevcut desteği koruyan duraktır. Destek tablosu aynı ayak desteklese bile bu eylemleri ayırır.",
        ),
        question: StudyText(
          "Decode W/L, T/L, W/R, H/R: which foot is available next?",
          "W/sol, T/sol, W/sağ, H/sağ dizisini çöz: sonraki hazır ayak hangisi?",
        ),
        answer: StudyText(
          "Left is available next. If count 2 accidentally takes weight on the right, the planned right step at 3 is no longer free. Revisit the changed row.",
          "Sonraki hazır ayak sol. 2’de sağ yanlışlıkla ağırlık alırsa 3’te planlanan sağ adım artık boş değildir. Değişen satıra dön.",
        ),
      ),
      RecallLesson(
        id: "latin.2",
        title: StudyText(
          "Separate the learning target",
          "Öğrenme hedefini ayır",
        ),
        teaching: StudyText(
          "The authored fusion pathway uses an explicit support/count plan. A travel choice or fitness-style title does not establish salsa technique, calorie expenditure or a complete dance tradition.",
          "Özgün fusion yolu açık destek/sayım planı kullanır. Yol seçimi veya fitness başlığı salsa tekniğini, kalori harcamasını veya tam dans geleneğini kanıtlamaz.",
        ),
        question: StudyText(
          "You explain the count ledger correctly. Which result can you report?",
          "Sayım tablosunu doğru açıklıyorsun. Hangi sonucu bildirebilirsin?",
        ),
        answer: StudyText(
          "A written explanation of this ledger, with any remaining unknowns. Physical execution and style acceptance remain separate.",
          "Kalan bilinmeyenleri içeren bu tablonun yazılı açıklaması. Fiziksel uygulama ve stil kabulü ayrı kalır.",
        ),
      ),
    ],
  ),
  StudyArea(
    id: "shortform",
    title: StudyText(
      "Original short-form combinations",
      "Özgün kısa format kombinasyonları",
    ),
    boundary: StudyText(
      "Reading and written recall only; no movement is needed. Demonstration, personal suitability and physical technique require separate review.",
      "Yalnız okuma ve yazılı hatırlama; hareket gerekmez. Gösterim, kişisel uygunluk ve fiziksel teknik ayrı inceleme gerektirir.",
    ),
    sourceRefs: <String>[
      "content/original_short_form_beginner_course.json#sf_01",
      "content/original_short_form_beginner_course.json#sf_02",
    ],
    lessons: <RecallLesson>[
      RecallLesson(
        id: "shortform.1",
        title: StudyText("Intention before imitation", "Taklitten önce niyet"),
        teaching: StudyText(
          "An authored short phrase can use a simple intention such as open, wait or answer. This course does not import a trending routine, licensed song or another creator’s choreography.",
          "Özgün kısa cümle açıl, bekle veya cevapla gibi yalın niyet kullanabilir. Bu kurs popüler rutin, lisanslı şarkı veya başka üreticinin koreografisini içeri almaz.",
        ),
        question: StudyText(
          "Write one original intention. Does that grant permission to add a song to the app?",
          "Tek özgün niyet yaz. Bu, uygulamaya şarkı ekleme izni verir mi?",
        ),
        answer: StudyText(
          "No. Original intention and music rights are separate. Use the written task without adding media.",
          "Hayır. Özgün niyet ile müzik hakkı ayrıdır. Medya eklemeden yazılı görevi kullan.",
        ),
      ),
      RecallLesson(
        id: "shortform.2",
        title: StudyText("Touch versus hold", "Dokunuş ve durak"),
        teaching: StudyText(
          "In W/H/T/W the middle hold and touch can preserve the same supporting foot while remaining different actions. The course’s example ends right-supported and left-ready.",
          "W/H/T/W dizisinde ortadaki durak ve dokunuş farklı eylemken aynı destek ayağını koruyabilir. Kurs örneği sağ destekli ve sol hazır biter.",
        ),
        question: StudyText(
          "The touch at count 3 takes weight. Why can the planned right step at 4 fail to fit the ledger?",
          "3’teki dokunuş ağırlık alıyor. Planlanan 4’te sağ adım neden tabloya uymayabilir?",
        ),
        answer: StudyText(
          "Right is no longer free for the intended transfer. Revisit counts 2–3; a changed action is not the same plan.",
          "Amaçlanan aktarım için sağ artık boş değildir. 2–3’e dön; değişen eylem aynı plan değildir.",
        ),
      ),
    ],
  ),
];
