---
tur: olcum
proje: choreia
guncelleme: 2026-08-12
---

# `salsa_shines` `bpmStatus: DISPUTED` — tartışma mı, BİRİM mi?

**Sevk (koordinatör):** kurucuya *"10 dakikanı ver"* demeden önce ***o 10
dakikanın GEREKLİ olduğunu ölçmek borcumuz.***
⛔ `bpmStatus` **değiştirilmedi** · kapı **açılmadı** · tempo **atanmadı** ·
alan bilgisi **uydurulmadı** — her sayı deponun kendi verisinden.

---

## (a) İki tur 2× ilişkisinde mi? **EVET, ve her iki yönde TAM kapsama**

| | |
|---|---|
| tur 1 | **89–100** |
| tur 1 × 2 | **178–200** |
| tur 2 | **160–220** |
| kesişim | **178–200** — 2× aralığının **%100'ü** |
| ters yön | tur 2 ÷ 2 = **80–110**, ve 89–100 bunun **tamamen içinde** |

→ İki tur **çelişmiyor**. Aynı olgunun **iki nabız düzeyinde** okunması.
`DISPUTED` etiketi bir **veri tartışmasını** değil, bir **SAYMA KURALI**
belirsizliğini adlandırıyor.

## (b) Deponun yerleşmiş bir sayma kuralı var mı? **VAR — ve ölçülerek doğrulandı**

Depoda `style.json` taşıyan **iki** stil var; yalnız biri çözülmüş.

**Yöntem önce ÇÖZÜLMÜŞ stilde doğrulandı** (yoksa salsa'ya uygulamak
gerekçesiz olurdu):

| | hip_hop_foundations |
|---|---|
| hasat çevrim/dk (referansın `sources[].periodSeconds`inden) | **88–103** |
| adım belgesi | `beats: 1` · `countLabels: ["1"]` → 1 çevrim = **1 sayım** |
| ⇒ türetilen BPM | **88–103** |
| **beyan edilen** `bpmRange` | **[85, 105]** |
| sonuç | ✅ **ÖRTÜŞÜYOR — yöntem doğrulandı** |

→ Kural: ***`bpmRange`, adımın `countLabels`ının saydığı nabızda ifade
edilir***, ve hasat ölçümüyle örtüşür. Bu **deponun kendi verisinden**
türetildi, dans bilgisinden değil.

## (c) Kural salsa'yı belirliyor mu? **KISITLIYOR ama BELİRLEMİYOR**

Aynı yöntem salsa'ya uygulandı — **hasat ölçümü elde zaten var:**

| | ss_shine_footwork |
|---|---|
| hasat çevrim/dk | **44–56** |
| adım belgesi | **`beats: null`** · `countLabels: ["a", "b"]` (**2 etiket**) |

| çevrim başına sayım | türetilen BPM | tur 1 (89-100) | tur 2 (160-220) |
|---|---|---|---|
| **2** | **88–112** | ✅ **ÖRTÜŞÜR** | ✗ örtüşmez |
| **4** | **176–224** | ✗ örtüşmez | ✅ **ÖRTÜŞÜR** |

**Yani belirsizliğin tamamı tek bir beyan edilmemiş alanda toplanıyor:
`ss_shine_footwork.beats` (bugün `null`).** İki araştırma turunun hangisinin
doğru olduğu, o alanın değerine **birebir** bağlı — ve o alan `null`
olduğu için hiçbir tur "yanlış" değil.

⚠️ **Aşırı okumayın:** `countLabels`ın **2 etiketi** olması, çevrimin 2 sayım
sürdüğünü **düşündürür** ama **kanıtlamaz** — `beats: null` tam da bunun
henüz beyan edilmediğini söylüyor. Bu bir **kısıt**, kanıt değil.

---

## Sonuç — kurucudan istenen şey DEĞİŞİYOR

**Eski çerçeve:** *"BPM tartışmalı, kurucu ~10 dk canlı tap yapsın, ölçüm
kararı versin."*

**Ölçülen çerçeve:** iki tur **çelişmiyor** (tam 2× kapsama) · deponun sayma
kuralı **var ve doğrulandı** · salsa'nın hasat ölçümü **elde** (44–56
çevrim/dk) · geriye kalan tek bilinmeyen ***bir çevrim kaç sayım sürer***
(`ss_shine_footwork.beats`).

→ Bu bir **ölçüm** değil bir **beyan**: adımın kaç sayıma yayıldığı içerik
yazarlığıdır (`ss_basic` için `8`, `sm_samba_no_pe` için `2` diye zaten
beyan edilmiş). Beyan edilir edilmez BPM **türetilir** — ve türetilen değer
iki araştırma turundan **birini** doğrular.

⛔ **Bu belge hiçbir şey ATAMIYOR.** `beats`i doldurmak içerik kararıdır ve
bende değil. Canlı tap **hâlâ gerekebilir** — ama artık *"tempoyu ölç"* için
değil, *"beyanı doğrula"* için, ve ikisi aynı büyüklükte iş değil.
