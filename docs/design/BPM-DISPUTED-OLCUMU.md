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

---

## 🔴 DÜZELTME (aynı gün, sonraki tur) — kendi sonucumu geri alıyorum

Yukarıda *"belirsizliğin TAMAMI tek bir `null` alanda (`ss_shine_footwork.beats`)
toplanıyor"* yazdım ve kurucu kaleminin **küçüldüğünü** raporladım.
**İki ölçüm bunu çürüttü, ikisi de deponun kendi kaydında zaten vardı.**

### ① `countLabels: ["a","b"]` SAYIM DEĞİL, FAZ etiketi

Adımın kendi `phases` dizisi: **`settle_a` · `transfer_ab` · `settle_b`.**
Yani `a`/`b` **müzikal sayım değil**, çevrimin **kinematik fazları**.
→ `beats == len(countLabels)` düzeni (7/7, hepsi **sayısal** etiketli
adımlarda) bu adıma **uzatılamaz**: farklı bir kategori.
*Kısıt, kanıt değildir* — ve burada kısıt bile değilmiş.

### ② C-032 bunu ZATEN ölçmüş, ve benden DAHA KESKİN

DEFTER C-032 (aylar önce):
> *"Muhtemel sebep: iki tur **FARKLI BÜYÜKLÜK** ölçmüş — salsa'nın
> quick-quick-slow'unda **3 adım 4 müzikal vuruşa yayılıyor**, 'adım hissi'
> ile müzikal vuruş **~2× fark eder**."*

Ve `library.json`'ın kendi notu: *"C-032 kapandı — **hareket-üzerinden BPM
çıkmaz sokaktı, ÖLÇÜLDÜ** — ama `beat_annotate` ile müzik-ızgarası kurucunun
canlı tap'ini bekliyor."*

**Yani benim (c) türetimim — hasat çevrim/dk × `beats` — tam olarak
"hareket-üzerinden BPM"dir, ve o yol ölçülüp KAPATILMIŞ.** Sebebi de
kayıtlı: salsa'da adım↔vuruş oranı **3:4**, yani temiz bir tamsayı çarpanı
**yok**; `beats` beyan edilse bile hareketten müziğe geçiş bir çarpma
işlemi değil.

### Geriye ne kalıyor — küçülen şey kalem değil, BELİRSİZLİK

| iddia | durum |
|---|---|
| (a) İki tur 2× ilişkisinde, iki yönde tam kapsama | ✅ **ayakta** — C-032'nin *"muhtemel sebep"* dediğini **hesapla doğruladı** |
| (b) Sayma kuralı var, çözülmüş stilde doğrulandı | ✅ **ayakta** |
| (c) Belirsizliğin tamamı `beats`te, kurucu kalemi küçülüyor | 🔴 **GERİ ALINDI** |

**Kurucu kalemi küçülmedi.** Canlı tap *"beyanı doğrula"* değil, **hâlâ
*"müzik ızgarasını kur"*** — çünkü hareket o ızgarayı veremiyor, ve bu
**ölçülmüş** (C-032), varsayılmış değil.

🪤 **Ve kendi hatamın şekli:** bugün beş kez *"bir aracın/sayının ölçtüğü şey
adının söylediği şey olmayabilir"* dedim. Burada **etiketin adına** güvendim:
`countLabels` **"count"** diyor, ama içindekiler **faz**. Ve deponun kapalı
bir bulgusunu **aramadan** yeni bir yol açtığımı sandım — ***kapalı bir
kaydı okumamak, onu yeniden açmaz; yalnız aynı çıkmaz sokağa ikinci kez
girer.***
