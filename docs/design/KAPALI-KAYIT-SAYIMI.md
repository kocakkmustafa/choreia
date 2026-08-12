---
tur: olcum
proje: choreia
guncelleme: 2026-08-12
---

# İçerikte KAPALI kayıtlar — ve kaçı bir `shipGates` kalemine bağlı

**Sevk (koordinatör):** bugün **kapalı bir çıkmaz sokağa ikinci kez girdik**
(C-244) ve maliyeti bir turdu. *Kaç tane daha var?*
⛔ Hiçbiri yeniden açılmadı · hüküm verilmedi · yalnız **sayıldı ve
listelendi**.
⚠️ **`.lower()` KULLANILMADI** — C-236: `'İ'.lower()` birleşik nokta üretiyor
ve Türkçe büyük kipte yanlış sıfır verir. `re.IGNORECASE` ölçülüp `İ`yi
katladığı doğrulanmıştı; tarama onunla yapıldı.

---

## Sayım

| | |
|---|---|
| taranan içerik dosyası (**payda**) | **17** |
| içerikte **atıf yapılan** kayıt (payda) | **44** |
| **kapanış ifadesiyle** anılan | **3** — `C-030` · `C-032` · `K10` |
| yalnız atıf (kapanış ifadesi yok) | **41** |
| `shipGates` kalemi (tümü) | **1** — `bpmResolved`, `blocked: true` |
| **bir `shipGates` kalemine bağlı kapalı kayıt** | **0** |

⚠️ **Sınır, adıyla:** *"kapanış ifadesi yok"* ≠ *"kayıt açık"*. 41'in çoğu
**gerekçe atfı** (*"C-xxx uyarınca"*), kapanış iddiası değil. Bu sayım
**kapanışın YAZILDIĞI** yerleri sayar, kapanmış olanları değil — ve ikisi
farklı kümeler.

---

## 🔴 Asıl bulgu: tek engelleyen kapı, kendisini açıklayan kapalı kaydı ANMIYOR

Depodaki **tek** `shipGates` kalemi:

```
gate: bpmResolved · blocked: true
why:  "bpmStatus DISPUTED — two research passes ~2x apart …"
unblockedBy: "tools/beat_annotate.py live tap on one known track (founder, ~10 min)"
atıf: — YOK
```

Ve onu açıklayan kapalı kayıt **başka bir dosyada** duruyor
(`library.json` → `styles[salsa_shines].note`):
> *"C-032 kapandı — **hareket-üzerinden BPM çıkmaz sokaktı, ÖLÇÜLDÜ**"*

**Yani kapı, AÇILIŞ yolunu taşıyor ama KAPALI yolu taşımıyor.**
Bir sonraki oturum kapıyı okuyup *"nasıl açarım"* diye sorduğunda,
*"şu yolu deneme, ölçüldü ve kapandı"* uyarısını **görmez** — ve bugün tam
olarak bu oldu: kapıyı okudum, C-032'yi **tesadüfen**, `countSystem` alanına
bakarken buldum.

> ***BİR KAPI, AÇILIŞ YOLUNU TAŞIYIP KAPALI YOLU TAŞIMIYORSA, ONU OKUYAN
> HERKESİ KAPALI YOLA BİR KEZ DAHA DAVET EDER.***

Ve maliyeti asimetrik: açılış yolunu bulmak **bir okuma**, kapalı yolu
bulmak **bir tur**.

⛔ **Düzeltilmedi** — `shipGates`e atıf eklemek bir içerik/şema kararıdır ve
bende değil. Sayım ve liste teslim; hüküm koordinatörde.
