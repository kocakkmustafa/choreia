import 'package:flutter/material.dart';

import '../ui_language.dart';

/// Temporary self-observation notes, independent of every course's progress.
class PracticeComparisonPage extends StatefulWidget {
  const PracticeComparisonPage({required this.styleId, super.key});

  final String styleId;
  static const supportedStyles = <String>{
    'hip_hop_foundations',
    'salsa_shines',
    'line_dance',
    'latin_fusion_fitness',
    'tiktok_format',
  };

  @override
  State<PracticeComparisonPage> createState() => _PracticeComparisonPageState();
}

class _PracticeComparisonPageState extends State<PracticeComparisonPage>
    with WidgetsBindingObserver {
  final _notes = List.generate(7, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final note in _notes) {
      note.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = UiLanguage.isTurkish(context);
    final labels = tr
        ? <String>[
            'Çalışma ve belirli sayı/geçiş',
            'Koşul: mod, uyarlama, taraf, yön ve hareket aralığı',
            'Ses koşulu: dış kaynak veya yalnız yazılı/sessiz çalışma',
            'A: Nerede ne gözledim? Emin değilsem bunu yaz',
            'Tek düzeltme: B için seçeceğim ipucu',
            'B: Aynı noktada ne gözledim? Emin değilsem bunu yaz',
            'Sonraki adım: tekrar, ara veya eğitmenden geri bildirim',
          ]
        : <String>[
            'Study and specific count/transition',
            'Condition: mode, adaptation, side, facing and range',
            'Sound condition: external source or written/silent study only',
            'A: What did I observe, and where? Say if uncertain',
            'One correction: my chosen cue for B',
            'B: What did I observe at that same point? Say if uncertain',
            'Next step: revisit, rest or ask an instructor for feedback',
          ];
    final tips = <String, String>{
      'hip_hop_foundations': tr
          ? 'Giriş veya beceri adayından tek okuma/dinleme sorusu seç. Örneğin step-touch satırında adım ile dokunuşu ayır. Running Man/Roger Rabbit gösterim ve fiziksel incelemesi açıktır.'
          : 'Choose one reading/listening question from the introduction or skill candidate, such as separating step and touch in a step-touch row. Running Man/Roger Rabbit demonstrations and physical review remain open.',
      'salsa_shines': tr
          ? 'Örneğin 3→4 geçişindeki destek ve durak seçimini anlat. Sessiz görsel sayacı müziğin vuruşu sayma. Bu sayfa Salsa ders tamamlama kaydından ayrıdır.'
          : 'For example, describe the support/hold choice at 3→4. Do not treat the silent visual counter as a music beat. This page is separate from Salsa lesson completion records.',
      'line_dance': tr
          ? '24 sayımlı çalışma ile 32 sayımlı yön planını ayrı koşul olarak yaz. Çaprazlamayan seçenek grapevine başarısını, yazılı yön planı gerçek dönüşü kanıtlamaz.'
          : 'Record the 24-count study and 32-count facing plan as different conditions. A no-cross option does not prove grapevine skill; a written facing plan does not prove an actual turn.',
      'latin_fusion_fitness': tr
          ? 'M/S/T/C sırasını ve seçtiğin değiştirmeyi belirt. Ayrı pulse çalışmasını 32 sayıya katma. Değiştirilmiş C ritim taslağı cumbia drag başarısı değildir.'
          : 'Name the M/S/T/C order and any substitution. Keep the separate pulse study outside the 32 counts. The altered C rhythm scaffold is not cumbia drag achievement.',
      'tiktok_format': tr
          ? 'Kendi 16 sayımlı notasyonundan tek geçiş seç; gösterilmiş örneği yeniden adlandırmak yerine kendi seçimlerini kullan. Body roll, sert Hit ve tam Arm run kabulü açıktır.'
          : 'Choose one transition in your own 16-count score; use your choices rather than rename a worked example. Body roll, sharp Hit and full Arm run acceptance remain open.',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(tr ? 'Denemeleri karşılaştır' : 'Compare attempts'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              tr
                  ? 'Öz gözlem notu; değerlendirme değildir. Puan, ustalık, kamera doğrulaması veya kurs tamamlanması verilmez. Notlar yalnız bu açık sayfada tutulur; sayfa kapanınca kaybolur. Choreia bunları kaydetmez veya göndermez.'
                  : 'Self-observation notes, not an assessment. No score, mastery, camera verification or course completion is awarded. Notes exist only while this page is open and are lost when closed. Choreia keeps no persistent copy of these notes and sends none.',
              key: const Key('practiceComparison.boundary'),
            ),
            const SizedBox(height: 16),
            Text(
              tr
                  ? 'Önce mevcut dersin ön koşul ve sınırlarını oku. İncelenmemiş hareketi bu sayfa için uygulama; yalnız oku, dinle veya anlat. Bu form fiziksel öğretim eklemez.'
                  : 'First read the existing lesson prerequisites and boundaries. Do not perform an unreviewed movement for this page; read, listen or describe it. This form adds no physical instruction.',
            ),
            const SizedBox(height: 12),
            Text(tips[widget.styleId] ?? ''),
            const SizedBox(height: 12),
            Text(
              tr
                  ? 'A için tek soru belirle: hangi sayı/geçiş, hangi eylem? Kesin gözlem yoksa “emin değilim” yaz. Aradan sonra tek ipucu değiştirip aynı koşulda B notunu al. Çok şey değiştirdiysen B yeni başlangıçtır; A ile iyileşme kıyası yapma.'
                  : 'Give A one question: which count/transition and which action? If you cannot observe it clearly, write “uncertain”. After a break, change one cue and note B under the same conditions. If you change several conditions, B is a new baseline; do not compare it to A as improvement.',
            ),
            const SizedBox(height: 12),
            Text(
              tr
                  ? 'Zamanlama sorusu için aynı dış ses kaynağı/tempo ve giriş noktasını seç. Yalnız yasal erişimin olan müzik veya kendi metronomunu ayrı kullan; uygulama ses sağlamaz, dinlemez veya vuruşunu ölçmez. Kendi sözlü sayımın/sessiz okuman tek başına dış vuruşla uyum kanıtı değildir.'
                  : 'For a timing question, keep the external sound/tempo and entry point the same. Use only music you can legally access or your own separate metronome; the app supplies no sound, does not listen and does not measure your beat. Self-counting/silent reading alone is not evidence of alignment with an external beat.',
            ),
            for (var i = 0; i < labels.length; i++) ...[
              const SizedBox(height: 20),
              ExcludeSemantics(child: Text(labels[i])),
              const SizedBox(height: 6),
              Semantics(
                label: labels[i],
                child: TextField(
                  key: Key('practiceComparison.note.$i'),
                  controller: _notes[i],
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: tr
                        ? 'Kendi notun; boş bırakabilirsin'
                        : 'Your note; may stay blank',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              tr
                  ? 'Sonuç değişmediyse daha kolay okuma/dinleme sorusuna dön veya ayrı yetkin eğitmen geri bildirimi iste. Bu uygulama notları doğrulamaz ve sessizliğini başarı olarak yorumlamaz.'
                  : 'If the result did not change, revisit an easier reading/listening question or seek separate qualified instructor feedback. The app does not verify your notes or interpret its silence as success.',
            ),
            const SizedBox(height: 20),
            Text(
              tr
                  ? 'Bu özgün çalışma sayfası, prova planlama ve geri bildirime yanıtı ayrı süreçler olarak ele alır. Genel eğitim referansı: AQA Dance Performance. Sınav rutini, notlandırma, müzik veya eğitmen onayı aktarılmamıştır.'
                  : 'This original worksheet treats rehearsal planning and response to feedback as separate processes. General education reference: AQA Dance Performance. No exam routine, grading, music or instructor endorsement is imported.',
            ),
            const SelectableText(
              'https://www.aqa.org.uk/subjects/dance/gcse/dance-8236/specification/subject-content/performance',
            ),
          ],
        ),
      ),
    );
  }
}
