# Referans Hasadı — Provenance Şeması ve Beat Anotasyon Akışı

**Tarih:** 2026-07-26 · **Statü:** şema bağlayıcı, anotasyon eşikleri ÖLÇÜLDÜ
**Dayanak:** kurucu direktifi M-F-13..16 · katalog §6.0 (M-C-01..04) · C-019

---

## 1. Neden provenance zorunlu

Referans, ürünün kullanıcıya "doğru" diye gösterdiği şey. Bir eşiğin nereden geldiği sorulduğunda cevabın **"şu altı eğitmenin şu videolarındaki şu segmentlerden, şu modelle, şu tarihte"** olması gerekiyor. İzi olmayan referans, denetlenemez bir iddiadır.

İkinci gerekçe pratik: model sürümü değişince (MediaPipe hâlâ "Preview", `latest` etiketi sessizce değişiyor — M-L-01) hangi referansların yeniden çıkarılması gerektiği yalnız provenance'tan bilinir.

## 2. Saklama sınırı — bağlayıcı

**Yalnız türetilmiş veri saklanır.** Ürüne ve depoya giren şey:

✅ landmark dizileri · açı dizileri · kanonik referans + dispersiyon · beat ızgarası (BPM + downbeat) · provenance kaydı
❌ video dosyası · ses dosyası · videodan çıkarılmış ses parçası · kare görüntüleri

Bu hem hukuki duruş hem depo kararı. Çıkarım yapıldıktan sonra kaynak medya **silinir**; kalan tek şey sayılardır.

## 3. Provenance kaydı (her take için zorunlu)

```json
{
  "schemaVersion": 1,
  "takeId": "hh_bounce_t01",
  "step": "hh_bounce",
  "style": "hip_hop_foundations",

  "source": {
    "platform": "youtube",
    "videoId": "<id>",
    "url": "<url>",
    "channel": { "name": "<kanal>", "id": "<id>", "independent": true },
    "title": "<başlık>",
    "license": "cc_by | youtube_standard | unknown",
    "uploadDate": "YYYY-MM-DD",
    "harvestedAt": "YYYY-MM-DDTHH:MM:SSZ",
    "harvestTool": "yt-dlp <sürüm>"
  },

  "segment": {
    "startMs": 0, "endMs": 0,
    "reason": "tek plan, yavaş tempo demo, tam vücut"
  },

  "extraction": {
    "model": "pose_landmarker_heavy",
    "modelSha256": "<hash>",
    "variant": "heavy",
    "fps": 30
  },

  "qualityGates": {
    "mirrorDecision": "as-is | flipped | undetermined",
    "cameraAngle": { "verdict": "ok | oblique | reject", "estimatedYawDeg": 0 },
    "shotBoundaries": [],
    "structuralFaults": [],
    "judgeableRatio": 0.0
  },

  "beatAnnotation": {
    "method": "manual_tap",
    "annotator": "<kim>",
    "tapCount": 0,
    "bpm": 0.0,
    "firstBeatS": 0.0,
    "residualSdMs": 0.0,
    "verdict": "good | usable | reject"
  },

  "usage": { "role": "reference_take", "includedInReference": true },
  "mediaRetained": false
}
```

`mediaRetained` her zaman `false` olmalı; `true` bir kayıt denetimde hata sayılır.

**Bağımsızlık alanı (`channel.independent`) kritik:** ≥3-eğitmen kuralı *bağımsız* eğitmen sayar. Aynı stüdyonun üç eğitmeni aynı evi öğretir — konsensüs sahte çıkar, aynalama kararı da varyanstan türeyen tolerans da bozulur. Aynı kanaldan/kurumdan gelen takeler tek kaynak sayılır.

## 4. Beat anotasyon akışı

Beat ızgarası videodan **alınamaz** (sesi bize ait değil). Kaynak: insanın videoya vurması.

```
Video oynatılır (yerel, geçici)
→ Anotatör beat'e vurur (≥16 vuruş)
→ beat_annotate.py: medyan IBI ile başlangıç tempo → en küçük kareler ızgara oturtma (iteratif indeks yeniden atama)
→ Kalite hükmü: good / usable / reject
→ Yalnız {bpm, firstBeatS, residualSdMs} saklanır — ses ASLA
```

### 4.1 Ölçülen doğruluk (`beat_annotate.py --self-test`)

| Senaryo | BPM hatası | Downbeat hatası | Hüküm |
|---|---|---|---|
| 16 vuruş, tight (10 ms) | 0.08 | 2.3 ms | good |
| 16 vuruş, tipik (25 ms) | 0.54 | 16.3 ms | good |
| 32 vuruş, tipik | 0.19 | 13.1 ms | good |
| 8 vuruş, tipik | 0.10 | 5.3 ms | good |
| 4 vuruş, tipik | 0.59 | 19.0 ms | usable |
| 16 vuruş, özensiz (70 ms) | 9.20 | 146.2 ms | **reject** |
| 32 vuruş + 2 **kaçırılmış** beat | 0.009 | 0.7 ms | good |
| 32 vuruş + 2 **çift** vuruş | 0.087 | 20.0 ms | usable |
| 150 BPM, 32 vuruş | 0.18 | 4.3 ms | good |
| 70 BPM, 32 vuruş | 0.06 | 11.4 ms | good |

### 4.2 Akıştan çıkan gereksinimler

1. **≥16 vuruş.** Tipik insan hassasiyetinde downbeat hatası ~16 ms — başlangıç seviyesi beat penceresinin (80 ms) beşte biri. Yeterli.
2. **Kaçırılan beat zararsız.** En küçük kareler beat indekslerini yeniden atadığı için 32 vuruşta 2 kaçırma hatayı **artırmıyor**, azaltıyor. Anotatöre "kaçırırsan devam et" denebilir.
3. **Çift vuruş daha zararlı.** Aynı koşulda hükmü `usable`'a düşürüyor. **Araç çift-vuruşu (< ~100 ms aralık) anında uyarmalı** — bu, arayüzün tek zorunlu davranışı.
4. **Özensiz anotasyon reddediliyor** ve bu doğru: 146 ms'lik bir downbeat hatası, kendi hatasını ürünün her zamanlama skoruna koyardı.

### 4.3 Hacim

8 adım × 6 take = **48 anotasyon/stil**, iki stil için **96**. Take başına ~1 dk vuruş + kalite kontrolü. Asıl yük vuruş değil, **segment seçimi** (hangi 10 saniye tek plan, tam vücut, yavaş tempo) — araç bunu kolaylaştırmazsa maliyet buradan patlar.

## 5. Kalite kapıları sırası

```
1. Segment seçimi (elle)      → tek plan, tam vücut, mümkünse yavaş tempo
2. Landmark çıkarımı          → mevcut Python hattı, model pinli
3. StructuralValidator        → anatomik imkânsızlık reddi (M-019)
4. Kamera açısı               → fronto-paralel değilse açılar bozulur (C-019b)
5. Plan/kesme sınırı          → segment içinde kesme varsa reddet (C-019c)
6. Beat anotasyonu            → ≥16 vuruş, hüküm ≥ usable (C-019e)
7. Aynalama konsensüsü        → ReferenceBuilder, ≥3 bağımsız take gerektirir
8. Kanonik referans + tolerans → eğitmen varyansından türetilir
```

3 ve 7 kodlandı ve testli. 4, 5 pilotta ölçülecek. 1 ve 6 elle + araç destekli.
