import 'package:flutter/material.dart';
import '../ui_language.dart';

/// Original symbolic teaching aid; no human motion, sound, sensing or scoring.
class SupportHoldDemo extends StatefulWidget {
  const SupportHoldDemo({this.turkish, super.key});
  /// A lesson's in-page language choice can differ from the device locale.
  final bool? turkish;
  @override
  State<SupportHoldDemo> createState() => _SupportHoldDemoState();
}

class _SupportHoldDemoState extends State<SupportHoldDemo>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController clock;
  int slot = 0;
  bool extraTransfer = false;
  bool reducedMotion = false;
  // Symbolic support states, NOT a foot-placement or movement prescription.
  static const normal = ['A', 'B', 'A', 'A', 'B', 'A', 'B', 'B'];
  static const altered = ['A', 'B', 'A', 'B', 'A', 'B', 'A', 'B'];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    clock = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..addListener(() {
        final next = (clock.value * 8).floor().clamp(0, 7);
        if (next != slot) setState(() => slot = next);
      });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion) clock.stop();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) clock.stop();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    clock.dispose();
    super.dispose();
  }
  void select(int value) {
    clock.stop();
    clock.value = value / 8;
    setState(() => slot = value);
  }
  @override
  Widget build(BuildContext context) {
    final tr = widget.turkish ?? UiLanguage.isTurkish(context);
    final states = extraTransfer ? altered : normal;
    final hold = !extraTransfer && (slot == 3 || slot == 7);
    return Scaffold(
      appBar: AppBar(title: Text(tr ? 'Destek ve durak şeması' : 'Support and hold diagram')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
        Text(tr
            ? 'Özgün sembolik zaman örneği. A/B iki destek durumunu gösterir; ayak konumu, gerçek ağırlık aktarımı veya dansçı videosu değildir. Önce oku ve anlat. Fiziksel gösterim/inceleme hâlâ eksiktir.'
            : 'Original symbolic timing example. A/B represent two support states; this is not foot placement, real weight transfer or dancer video. Read and describe first. Physical demonstration/review is still missing.'),
        Text(tr
            ? 'Sekiz görsel aralık, her biri bir saniye. 4 ve 8’de zaman devam ederken destek aynı kalır. Bu sessiz model müziğin vuruşunu veya tempo eşleşmesini doğrulamaz.'
            : 'Eight visual intervals, one second each. At 4 and 8 time continues while support stays the same. This silent model does not verify a music beat or tempo matching.'),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (var i = 0; i < 8; i++)
            ChoiceChip(key: Key('supportHold.count.${i + 1}'),
              label: Text('${i + 1}: ${states[i]}'), selected: slot == i,
              onSelected: (_) => select(i)),
        ]),
        Semantics(liveRegion: false, child: Text(
          '${slot + 1}/8 — ${states[slot]} — ${hold ? (tr ? "aynı destek / durak" : "same support / hold") : (tr ? "destek durumu" : "support state")}',
          key: const Key('supportHold.current'))),
        Text(tr
            ? '3→4 ve 7→8’i tek tek seç: sayı ilerler, sembol değişmez. Durağı yeni aktarım gibi sayarsan sonraki destek planı değişir. “Durak” zamanın durması demek değildir.'
            : 'Select 3→4 and 7→8 individually: the count advances, the symbol does not. Treating a hold as a new transfer changes the next support plan. A hold does not mean time stops.'),
        SwitchListTile(key: const Key('supportHold.compare'), value: extraTransfer,
          title: Text(tr ? 'Karşı örnek: 4 ve 8’de de desteği değiştir' : 'Counterexample: change support at 4 and 8 too'),
          onChanged: (value) {
            clock.stop();
            setState(() => extraTransfer = value);
          }),
        Wrap(spacing: 8, children: [
          TextButton(key: const Key('supportHold.play'), onPressed: reducedMotion ? null : () {
            select(0);
            clock.forward(from: 0);
          }, child: Text(tr ? 'Bir kez göster' : 'Show once')),
          TextButton(key: const Key('supportHold.pause'), onPressed: clock.stop,
              child: Text(tr ? 'Duraklat' : 'Pause')),
          TextButton(onPressed: () => select(0), child: Text(tr ? 'Başa dön' : 'Reset')),
        ]),
        if (reducedMotion) Text(tr
            ? 'Hareket azaltma açık: sayıları elle seç.'
            : 'Reduced motion is on: select counts manually.'),
        Text(tr
            ? 'Kontrol sorusu: 3→4’te ne değişti, ne aynı kaldı? Karşı örnekte 5’in sembolü neden değişti? Yanıtı anlat; uygulama puanlamaz veya kurs tamamlamaz. Bu örnek groove, musicality veya hareket ustalığı kanıtı değildir.'
            : 'Check: at 3→4 what changed and what stayed? Why did the symbol at 5 change in the counterexample? Describe your answer; the app does not score or complete a course. This example is not evidence of groove, musicality or movement mastery.'),
        Text(tr
            ? 'Açıklama: normal örnekte 4’te A korunur; sonraki değişim 5’te B olur. Karşı örnekte 4’te B’ye geçilir; sonraki değişim 5’te A olur. A/B yalnız sembolik destek durumlarıdır.'
            : 'Explanation: normally 4 keeps A; the next change at 5 is B. In the counterexample 4 changes to B, so the next change at 5 is A. A/B are symbolic support states only.'),
      ])),
    );
  }
}
