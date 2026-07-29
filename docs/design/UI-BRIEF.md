# Choreia — UI-BRIEF (claude.ai/design oturumu girdisi)

**Tarih:** 2026-07-29 · **Statü:** tasarım-girdisi (KOD DEĞİL) · **Otorite:** `docs/choreia-plan.md` (kurucu onaylı, M-F-02) + `docs/CHOREIA-BLUEPRINT.md` §2 IA + `content/` (ölçülmüş gerçek)
**Bu belge yeni ürün kararı ÜRETMEZ** — var olan bağlayıcı kararları ve ÖLÇÜLMÜŞ durumu tasarımcının kullanabileceği biçime çevirir. Dayanağı olmayan hiçbir ekran/durum uydurulmadı; dayanak her maddede yazılı.

## 0. Dil — ⚠️ koordinatöre not

Gece paketi "TR+EN" istedi. **Plan §3 ürün dilini `EN` olarak bağlıyor** ("Konumlandırma (EN, ürün dili)") (konumlandırma metni orada İngilizce yazılmış; `content/` içindeki her `name`/`displayName` alanı `{en: ...}` biçiminde ve SCHEMA.md "ürün dili İngilizce, i18n anahtarı baştan" diyor). Bu yüzden:
- **Bu brief Türkçe** (iç doküman konvansiyonu),
- **içindeki tüm kullanıcı-görür metin İngilizce** (ürün dili),
- TR ürün dili V1 kapsamında **DEĞİL** — i18n altyapısı baştan var, çeviri turu sonraki dalga.

Gravita brief'i aynı sapmayı aynı gerekçeyle kaydetti; aile tutarlı. TR'yi V1'e almak kapsam kararıdır, bende değil.

## 1. Ürün tek cümlede (tasarımın çözmesi gereken şey)

> Telefonu karşına koy, bir dans adımını ekrandaki eğitmenlerden öğren, dene; sistem **yalnız gerçekten ölçebildiği şeyi** söylesin, ölçemediğini de açıkça söyleyip sussun.

**Choreia bir "dans oyunu" DEĞİL.** Skor bir eğlence puanı değil, ölçüm iddiasıdır — ve bugün ölçebildiği şey dar: bacak şekli ve hangi ayağın önde olduğu. Değer birimi "yüksek puan" değil **öğrenilmiş adım**.

**Tasarım için asıl sonuç — ve bu brief'in en önemli cümlesi:** bir dans uygulamasında kullanıcının beklediği ilk şey **ritim/zamanlama puanı**, ve Choreia'da bu **YOK** (§6.1). Tasarım bu boşluğu gizlemeye çalışmamalı; dürüstlüğü ürünün karakteri yapmalı.

## 2. Marka tonu

| Boyut | Karar | Kaynak |
|---|---|---|
| Karakter | Sakin, ölçen bir eğitmen. Tezahürat yok, combo-streak-havai fişek yok. | Blueprint §7 |
| Dürüstlük | Ne ölçtüğünü VE ne ölçmediğini söyler. Emin olmadığında **hüküm vermez** — "iyi" demez, susar. | plan §13.2, `content/*/style.json` honesty blokları |
| Otorite kaynağı | "N bağımsız eğitmen şunda anlaştı" — sayı ve kaynak, slogan değil. Tolerans eğitmenlerin ayrışmasından türer. | plan §11 (Referans üretim hattı) |
| Kültürel saygı | Köken-atıf kutuları dekoratif değil, **içeriğin parçası** (Vogue: Black/Latino LGBTQ+ ballroom kültürü; Afrobeats craze'leri; Bhangra). Hula kasıtlı BEKLEMEDE — kumu-hula ortaklığı olmadan yapılmaz. | Blueprint §7, `content/library.json` |
| Yasak dil | "resmî [sanatçı] koreografisi" · marka adları (Zumba) · "profesyonel seviye" · her türlü tıbbi/tedavi dili | Blueprint §7 |
| Görsel yön | İsim *khoreia* (Yunan koro-dansı). Ritim, tekrar, akış duygusu. TikTok-neon değil; sıcak, insani, stüdyo-ışığı. | isim seçimi (PROGRESS 2026-07-25) |

## 3. Ekran envanteri

Alt-tab: **Home · Library · Progress · Profile** (Blueprint §2 IA'sının tab karşılığı; Gravita/Ostinato ile aynı iskelet)

### 3.1 Onboarding (ilk açılış)
Amaç: kurulumu doğrulamak, izin gerekçesini söylemek, **ne ölçmediğimizi baştan söylemek**.
- Kamera izni + **gerekçe metni ekranda açık** (plan §17 Gizlilik): *ham video cihazdan çıkmaz, yalnız landmark türevleri saklanır.*
- Kurulum kontrolü: tek kişi · sabit telefon · **tam vücut kadraj** · ~2×2 m alan (plan §5 Kullanım sınırları). Canlı kamera önizlemesi + kadraj çerçevesi.
- Zemin/ayakkabı sorusu (ayakkabılı/çıplak ayak — plan §5). *Tap/flamenko donanım şartı (ayakkabı+sert zemin) W3+ dalgasının onboarding'i, V1'de yok (plan §6).*
- **Dürüstlük kartı (zorunlu, atlanamaz):** "We score leg shape and which foot leads. We do **not** score your timing yet, your arms, or your groove." — bu bir ayar değil, bir söz.
- ⚠️ Beat kalibrasyonu (plan §9: tap-test, medyan audio offset) **V1'de GÖSTERİLMEZ** — zamanlama skorlanmıyor, kalibre edecek bir hüküm yok. Ekran tasarlanır, BPM çözülünce açılır.

### 3.2 Home
- Devam edilecek ders (tek birincil eylem).
- Bugünün adımı / kısa pratik.
- **"What we can grade today" kutusu** — `honesty.measured` doğrudan buradan okunur; boşsa boş görünür (bugün hip-hop için boş).

### 3.3 Library (⚠️ en zor tasarım problemi — §7 açık kalem 2)
- **34 stil sayfası, 5 dalga** (`content/library.json`). Bugün: **1 `live`** (salsa_shines) · **1 `demoOpen`** (hip_hop_foundations) · gerisi `comingSoon`/`onHold`.
- Her stil kartı: ad · dalga · durum rozeti · varsa `demoOnly` etiketi. **Rozet üç ayrı şey söylemek zorunda** (statü kafesi, M-F-123):
  - `live` = bu stilde skorlanan ders var
  - `demoOpen` = dersleri **açabilirsin ama hiçbiri puan vermez** ⟵ ⚠️ tasarımın yeni ve zor rozeti: "açık" ile "puanlı" aynı şey değil, ve bunu bir rozetle anlatmak gerekiyor
  - `comingSoon` = açılabilir ders yok
- Kapsamın **TAMAMI baştan görünür** (plan §24 Tamamlanma kriterleri: "kütüphanenin TAMAMI gezilebilir") — ama **sahte/boş kurs asla listelenmez** (`library.json` statusValues).
- `onHold` stiller sayfada **gerekçesiyle** görünür (Hula: kültürel ortaklık şartı) — gizlenmez.

### 3.4 Stil sayfası
Blueprint §2'nin birebir karşılığı:
- Tanıtım + **köken/atıf kutusu**
- Adım sözlüğü
- Kurs listesi (Temeller · Kombolar · Rutinler)
- Tempo/BPM bilgisi — ⚠️ salsa için bugün **"disputed"** (`bpmStatus`), sayı gösterilemez
- Kişisel zamanlama-trend grafiği — ⚠️ **V1'de boş/yok** (zamanlama ölçülmüyor)
- **Hukuk/dürüstlük kutusu:** `honesty.measured` + `honesty.notMeasured` listesi, olduğu gibi

### 3.5 Ders (Lesson) — üç GÖRSEL SINIF, karıştırılmamalı
`content/*/style.json` `levels[].lessons[]` üç durumdan birini beyan eder; tasarım üçünü **ayrı ayrı** çözmeli:

| Sınıf | Alan | Kullanıcıya ne der | Görsel gereksinim |
|---|---|---|---|
| **Skorlu** | `scored: true` | "This is graded: leg shape, which foot leads" | Normal ders akışı + skor yüzeyi |
| **Kilitli** | `status: "locked"` + `lockedReason` | "Not enough teachers measured yet" | Kilit **görünür + açılmaz**, sebep kullanıcı dilinde, **eksik ÖLÇÜMÜN adıyla** |
| **Demo-only** | `demoOnly: true` + `demoOnlyReason` | "We teach this, we don't grade it — here's why" | ⚠️ **İkinci sınıf/eksik gibi GÖRÜNMEMELİ.** Bu tam bir ders; yalnız skor yok |

**Demo-only, K10'un (plan §22) tasarım yükü:** *ölçülemeyen hareket elenmez, demo-only işaretlenir ve nedeni kullanıcıya söylenir.* Bugünkü gerçek örnek: Running Man — 4 eğitmen ölçüldü, hareket öğretiliyor, skorlanmıyor (ayak-ucu temas zamanlaması tek kamerada güvenilir değil). Tasarım bunu bir **kusur** değil bir **dürüstlük** olarak sunmalı.

### 3.6 Ders akışı (Blueprint §2 dörtlüsü — bağlayıcı sıra)
1. **Adımı öğren** — yavaş, sayımlı (eğitmen figürü + sayım metni)
2. **Beat'siz dene** — sadece şekil
3. **Beat'le dene** — ⚠️ **V1'de KAPALI** (beat ızgarası yok; BPM disputed). Adım 2'den 4'e geçilir; tasarım bu adımın yerini boş bırakmalı, sahte doldurmamalı
4. **Skor + TEK düzeltme** — en önemli tek hata (plan: tek-hata disiplini)

### 3.7 ⭐ Canlı tur (Live session) — kullanıcının BAKAMADIĞI ekran
Dans ederken kullanıcı telefona bakamaz. Bu, ekranı **sesin etrafında** kurmayı zorunlu kılar.
- Ayna-modu **varsayılan AÇIK** (K6, plan §14): referans figür aynalanmış gösterilir, kullanıcı ayna gibi taklit eder.
- Büyük, uzaktan okunur sayım (`countLabels`).
- Sesli koç (aile §1.1: sesli antrenör-vaadi çekirdek).
- **Hüküm-yok durumları görünür:** `OUT_OF_FRAME` · `LOW_LIGHT` · `LOW_TRACKING_CONFIDENCE` (plan §13 Hata kodları) — "kötü dans ettin" DEĞİL, "göremiyorum" der.
- Müzik kaynağı: **kendi metronomumuz** veya **kullanıcının yerel müziği** (K3, plan §9.1 + §16 Müzik telifi) — app-içi katalog YOK (lisans). Tasarım "kendi müziğini seç" akışını birinci sınıf vatandaş yapmalı, bir ayar dipnotu değil.

### 3.8 Deneme özeti (Attempt summary)
- Şekil skoru (bant/ilerleme — ⚠️ **K8/M-F-04: kalibrasyon kapısı geçilmeden MUTLAK SAYI gösterilmez**; "Alignment: strong" + eğri).
- **TEK** düzeltme cümlesi.
- Skorlanan ↔ skorlanmayan ayrımı ekranda: hangi eklemler hüküm taşıdı, hangileri (kollar) bilinçli serbest.
- Hüküm verilmeyen fazlar **boş** görünür — 0 puan değil, "ölçülmedi".

### 3.9 Progress — İKİ BÖLÜM, karıştırılamaz (M-F-156)

**"Kaydedilenler" (ÖLÇÜM) ile "Değerlendirilenler" (HÜKÜM) ayrı bölümlerdir.** Tek listede karıştırmak, demoOnly derslerin tamamlamalarını puanlanmış gibi okutur.

| Bölüm | İçerik | Hangi dersler |
|---|---|---|
| **Kaydedilenler** | süre · çevrim sayısı · tamamlama işareti | **hepsi** (scored + demoOnly) |
| **Değerlendirilenler** | bant/ilerleme (kalibrasyon kapısından sonra) | **yalnız** `scored` |

**demoOnly ders "öğrenildi" işareti ALIR, bant ASLA almaz.** Gerekçe zinciri: K8 **skoru** kapatır olguyu kapatmaz · "bu dersi baştan sona çalıştım" kameradan bağımsız bir ÖLÇÜMDÜR · "bunu iyi yaptın" bir HÜKÜMDÜR ve demoOnly derste tanım gereği yok · tamamlamayı da esirgemek dersi ikinci sınıf yapardı, tam K10'un engellemek istediği şey. demoOnly satırında hüküm alanı **"—"** + `demoOnlyReason`.

**Ve bugün geçilemeyen kapılar EKRANDA YAZILI** (J-066 disiplini: sessizlik yalandır) — süre retroaktif kredi OLMAZ. Choreia'nın bugünkü listesi: zamanlama hiçbir derste ölçülmüyor (BPM disputed) · `ss_shine_footwork` dışında skorlanan ders yok · `NO_WEIGHT_TRANSFER` gürültü tabanı yüzünden bloklu.

Detay sözleşme: `docs/design/SESSION-STORE-DELTA.md` §4.

### 3.9b Progress — diğer kalemler
- Ders/adım ilerlemesi. ⚠️ Zamanlama-trend grafiği V1'de **yok**.
- Seviye açılma kriteri **görünür**: hangi kriter / gereken / gözlenen (`unlockRule`). Salsa L1: `shapeScore >= 0.75` + `WRONG_FOOT` yok — `onBeatRatio` bilinçli **dışarıda**.

### 3.10 Profile / Settings
- Ayna-modu anahtarı · tempo yavaşlatıcı (kendi beat'imizde) · metronom sesi
- **Gizlilik ekranı:** ham video kaydedilmez · veri silme + dışa aktarma (plan §17 Gizlilik)
- Köken-atıf / künye sayfası (CC-BY müzik kullanılırsa künye şartı — plan §16)

## 4. Akış diyagramı (metin)

```
ilk açılış
  └─ Onboarding: izin+gerekçe → kadraj kontrolü → zemin/ayakkabı → DÜRÜSTLÜK KARTI (atlanamaz)
        └─ Home
             ├─ Library (34 stil, 5 dalga; hepsi gezilebilir)
             │    └─ Stil sayfası (atıf kutusu · adım sözlüğü · honesty kutusu · kurslar)
             │         └─ Kurs → Ders
             │              ├─ [scored]    → ders akışı → CANLI TUR → özet(+skor, tek düzeltme)
             │              ├─ [locked]    → kilit ekranı: sebep + eksik ölçümün adı  ⟂ açılmaz
             │              └─ [demoOnly]  → ders akışı → CANLI TUR (skorsuz) → özet(skor YOK, sebep VAR)
             ├─ Progress (ilerleme + açılma kriteri: kriter/gereken/gözlenen)
             └─ Profile (ayna-modu · gizlilik · künye)

ders akışı = [1] öğren (yavaş+sayım) → [2] beat'siz dene → [3] beat'le dene ⟂ V1'DE KAPALI → [4] skor+tek düzeltme
```

## 5. Her ekranın zorunlu durumları (tasarım kontrol listesi)

Her ekran için: **boş · yükleniyor · hata · izin-reddi**. Choreia-özel olanlar:

| Durum | Nerede | Ne göstermeli |
|---|---|---|
| **İzin reddi (kamera)** | Onboarding, Canlı tur | Ürün kamerasız çalışmaz — ama suçlayıcı değil, ayarlara yol gösteren |
| **Kadraj dışı** (`OUT_OF_FRAME`) | Canlı tur | "Step back, I can't see your feet" — skor değil, uyarı |
| **Az ışık** (`LOW_LIGHT`) | Canlı tur | Aynı sınıf: hüküm yok, sebep var |
| **Düşük izleme güveni** | Canlı tur, özet | ⚠️ **Hüküm YOK durumu** — 0 puan DEĞİL. Bu ayrımı görsel olarak çözmek zorunlu |
| **⭐ ÖLÇÜLEMEDİ ≠ BAŞARISIZLIK** | Özet, Progress, ders kartı | **Kendi başına bir durum.** Üç ayrı kaynağı var ve hepsi aynı yüzeye çıkar: (a) bu faz `scoredPhases:false` — eğitmenler orada anlaşmıyor; (b) bu hata `calibration-blocked` (NO_WEIGHT_TRANSFER: eşik gürültü tabanının altında); (c) izleme güveni düştü. Üçünde de ekran **"yapamadın" demez, "bakmadım/bakamadım" der** — ve hangisi olduğunu söyler. Boş alan, gri "—", 0 puan DEĞİL; ilerleme çubuğuna eksik olarak da yazılmaz |
| **Ders kilitli** | Ders | Kilit + sebep + eksik ölçümün adı (atlanamaz, "premium" gibi görünmez) |
| **Ders demo-only** | Ders, özet | Skor alanı **yok** (0 değil), yerinde sebep |
| **Stil yakında** | Library, Stil sayfası | "coming soon" rozeti; **sahte kurs listesi YOK** |
| **Stil beklemede** (`onHold`) | Library, Stil sayfası | Gerekçe görünür (Hula: kültürel ortaklık) |
| **Müzik seçilmemiş** | Canlı tur girişi | Metronom varsayılan; "kendi müziğini seç" birinci sınıf seçenek |
| **Kalibrasyon yapılmamış** | Özet | Mutlak sayı yerine bant/eğri (K8) |

## 6. Tasarımın ihlal ETMEMESİ gereken ölçülmüş kısıtlar

Bunlar stil tercihi değil; her biri bir ölçümün sonucu. İhlal = ürünün kendi dürüstlük kuralını bozması.

1. **Ritim/zamanlama puanı GÖSTERİLMEZ.** Salsa BPM'i çözülmemiş (iki araştırma turu ~2× ayrı: 89-100 vs 160-220). 2× yanlış ızgara, kullanıcının doğru adımlarının yarısını "kaçırdı" diye işaretler — ürün kendi hatasını kullanıcıya yazar. *Bir dans uygulamasında en beklenen özelliğin yokluğu; tasarımın bunu dürüstçe taşıması gerekiyor.* (`bpmStatus: DISPUTED`)
2. **Kollar skorlanmaz — ölçülmüş sebeple.** Aynı ayak işini yapan eğitmenler kol eklemlerinde 11-58° ayrışıyor: tek doğru kol yok. Gösterilir, öğretilir, **puanlanmaz**. (M-F-102)
3. **Mutlak skor, kalibrasyon kapısından önce gösterilmez** — bant/ilerleme. (K8 / M-F-04)
4. **Hüküm-yok ≠ sıfır puan.** Düşük güven, kadraj dışı, skorlanmayan faz: hepsi **boş**, hiçbiri 0 değil.
5. **Demo-only ders eksik ders değil.** K10'un tasarım yükü: skorsuz ama tam.
6. **Ayna-modu varsayılan AÇIK** ve sol/sağ eşlemesi merkezî — kural içinde `if (mirrored)` dallanması yasak. (K6)
7. **Bazı derslerde "hangi ayak" söylenebilir, bazılarında SÖYLENEMEZ.** `mirrorConfident:true` olan referansta taraf hükmü verilir (salsa: 15,6° marj, gürültü tabanının 2,6 katı); `false` olanda **hiç sorulmaz** (Running Man, Roger Rabbit). Aynı ders şablonu iki farklı hüküm setiyle çalışmalı. (kural-7 / M-F-117)
8. **App-içi müzik kataloğu YOK.** Lisans gerektirir; V1 = kendi metronomumuz + kullanıcının yerel müziği. Tasarım katalog varsaymamalı. (K3 / plan §16)
9. **Ham video cihazdan çıkmaz** ve bu ekranda yazılı. Kayıt/paylaşım özelliği tasarlanacaksa ayrı gizlilik kararı gerekir. (plan §17 Gizlilik)
10. **Köken-atıf kutuları kaldırılamaz.** Dekoratif değil; kültürel sorumluluk. (Blueprint §7)
11. **Statü rozeti içeriğin söylediğinden fazlasını DA azını DA söylemez.** Kafes iki yönlü kapılı: `live` ama skorlanan ders yok = aşırı-iddia; `comingSoon` ama kullanıcı ders açabiliyor = eksik-iddia. İkisi aynı kusur. Tasarım rozeti "pazarlama etiketi" gibi kullanamaz. (M-F-123)

## 7. Açık kalemler (tasarım oturumu ÖNCESİ karar gerekir)

| # | Kalem | Kimde |
|---|---|---|
| 1 | **BPM kilidi** — `beat_annotate` canlı-tap ölçümü. Çözülene kadar ders akışının 3. adımı ve tüm zamanlama yüzeyi kapalı. | **kurucu** (~10 dk manuel) |
| 2 | **34 sayfa / 0 skorlanan** gerilimi: kütüphane sahte-dolu görünmeden nasıl "geniş kapsam" hissi verir? Tasarım oturumunun asıl yaratıcı problemi. | tasarım oturumu |
| 3 | ~~`statusValues` sözlüğü~~ **ÇÖZÜLDÜ (M-F-123):** yeni statü `demoOpen` aile standardı oldu, üçlü kafes iki yönlü kapılı. Tasarıma düşen: `demoOpen` rozetini "açık ama puansız" anlamıyla çizmek. | ✅ kapandı |
| 3b | **YENİ GERİLİM:** statü ≠ ship-hazırlığı. salsa_shines `live` (skorlanan dersi var) ama `bpmStatus: DISPUTED` yüzünden hâlâ yayına çıkamaz. Kafes ders-durumuna bakıyor, ship kapısı ayrı eksende — ikisinin ilişkisi kafes tanımında YOK. Kullanıcı `live` rozeti görüp ders bulamazsa bu bir dürüstlük sorunu olur. | **koordinatör** (soruldu) |
| 4 | Ders akışı 3. adımı (beat'le dene) kapalıyken **yerini boş mu bırakmalı, gizlemeli mi?** Boş bırakmak dürüst ama kırık görünebilir. | tasarım oturumu |
| 5 | TR ürün dili V1 kapsamı dışı (§0) — değişecekse kapsam kararı. | **kurucu** |
| 6 | Kullanıcı kendini canlı turda görmek ister mi (self-view)? Dans pedagojisinde ayna standart, ama kamera önizlemesi dikkat dağıtabilir. Ölçülmüş verimiz YOK. | tasarım oturumu + kullanıcı testi |

## 8. Kaynaklar

- `docs/choreia-plan.md` — kurucu onaylı tam plan (27 bölüm, K1-K10); §3 konumlandırma/ürün dili · §5 kullanım sınırları · §9.1 K3 beat · §11 referans hattı · §13 hata kodları+§13.2 güvenilirlik ilkesi · §14 K6 ayna · §16 müzik telifi K7 · §17 gizlilik · §22 K10/kapsam dışı · §24 tamamlanma kriterleri
- `docs/CHOREIA-BLUEPRINT.md` — §2 bilgi mimarisi (bu brief'in IA iskeleti) · §7 Choreia-özel dürüstlük
- `content/SCHEMA.md` — `honesty` sözleşmesi · ders nesnesi (`scored`/`locked`/`demoOnly`) · measurability tier
- `content/library.json` — 34 stil sayfası, dalgalar, statü sözlüğü, `demoOnly` listeleri
- `content/styles/*/style.json` — `honesty` blokları (ölçülmüş measured/notMeasured), ders listeleri
- `content/references/*.json` — ölçüm gerçeği: `mirrorConfident`, `scoring[].verdict`, tolerans bantları
- Aile: `ventures/motion-core/lib/docs/00-AILE-MIMARISI.md` §1.1 (sesli antrenör çekirdek) · DEFTER M-F-102/109/115/117/119
- Kardeş brief'ler (aynı desen): `ventures/gravita/app/docs/design/UI-BRIEF.md` · `ventures/lissom/app/docs/design/UI-BRIEF.md`
