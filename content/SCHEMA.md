# Choreia — İçerik Şeması (v1)

**Bağlayıcı ilke (plan §7):** *Yeni stil = yeni içerik paketi, kod değişimi DEĞİL.* Adım tanımı, faz makinesi, eşikler, sayım metni ve hata kodları burada yaşar; motor bunları yorumlar. Bir stil eklemek derleme gerektirmez.

```
content/
  styles/
    <style_id>/
      style.json          # stil meta + seviyeler + ders sırası
      steps/<step_id>.json
      combos/<combo_id>.json
```

## Ortak alanlar

Her dosya `schemaVersion` taşır. Sürüm yükseltmesi = migration notu + eski sürümün okunabilir kalması.

## `style.json`

| Alan | Anlam |
|---|---|
| `id` | dosya yolu ile aynı, `snake_case` |
| `name` | `{en: ...}` — ürün dili İngilizce, i18n anahtarı baştan |
| `countSystem` | `8count` · `salsa_123_567` — sayım metinlerini ve beat eşlemesini sürer |
| `bpmRange` | `[min, max]` — ders müziği seçimini ve tempo kapısını sınırlar |
| `levels[]` | `{level, name, unlockRule, lessons[]}` |
| `unlockRule` | ölçülebilir kriter; **ders tamamlamak seviye atlatmaz** (plan §7) |

## `steps/<id>.json`

| Alan | Anlam |
|---|---|
| `beats` | adımın kaç beat sürdüğü |
| `countLabels[]` | kullanıcıya söylenen sayım (`"1"`, `"2"`, `"a"`, `"&"`) — sesli koç bunu okur |
| `measurability` | **CV-ölçülebilirlik derecesi** (aşağıda) — hangi adımın V1'e gireceğini bu belirler |
| `scoring.focusJoints[]` | skorlanan eklemler (`motion_core` `StandardJoints` id'leri) |
| `scoring.freeJoints[]` | **bilinçli skorlanmayan** eklemler — stil/ifade alanı |
| `phases[]` | faz makinesi: `{id, enter, exit?, timeoutMs?, minDurationMs?, requiredLandmarks[]}` |
| `scoredMoments[]` | beat-kilitli aksanlar: `{id, phase, beat, label}` — zamanlama YALNIZ bunlarda ölçülür |
| `errors[]` | `{code, severity, detect, evidence, relatedDrill}` |
| `reference` | `{requiredTakes, collectedTakes, status}` — ≥3 (tercihen 6) bağımsız eğitmen (katalog §6.0) |

### `measurability.tier` — V1 kapısı

R1'in CV-risk bulgusuna dayanır: düşük-genlikli tek-segment izolasyonlar poz modellerinin zayıf olduğu alandır; ayak-ucu temas zamanlaması ise markerless tek kamerada **en düşük güvenli** noktalar arasındadır.

| Tier | Tanım | V1 |
|---|---|---|
| **A** | Büyük genlikli, çok-segmentli, ayak-ucu temasına bağlı değil | ✅ girer |
| **B** | Orta genlik veya tek-segment baskın; ölçülebilir ama eşik hassas | ⚠️ pilot ölçümünden sonra |
| **C** | Düşük-genlikli izolasyon veya ayak-ucu temas zamanlamasına dayalı | ❌ V1 dışı |

**Bağlayıcı:** Tier C adım V1 müfredatına alınmaz. Ölçemediğimiz bir şeyi öğretip skorlamak, plan §13.2'nin ("düşük güvende hüküm yok") içerik seviyesindeki karşılığıdır.

### Hata tanımı — gözlemlenebilirlik şartı

**Bir `errors[]` girdisi, landmark'lardan ölçülebilir bir koşula bağlanmak ZORUNDADIR.**

R1'in hip-hop hata listesi bu şartı karşılamıyor: "temelleri atlamak", "sabırsız olmak", "müziği kafayla analiz etmek" pedagojik öğütlerdir — doğru olabilirler ama **kameradan görülemezler**. Bunlar ders metnine girer, hata koduna girmez.

Karşılaştırma için ölçülebilir olan: "ağırlık aktarılmadı" (yük taşıyan bacağın diz/kalça açısı değişmedi), "beat'te yukarı çıkmış" (bounce fazı ters), "gövde çökmüş" (diz yerine gövde bükülüyor).
