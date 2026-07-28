# CHOREIA — KAMERA TABANLI DANS ÖĞRETİMİ VE BEAT-SENKRON DEĞERLENDİRME
## Claude Code için Ana Proje Tanımı

**Tarih:** 2026-07-26 · **Kapsam hizalaması:** 2026-07-29 · **Statü:** ✅ **KURUCU ONAYLI** — kapsam `CHOREIA-BLUEPRINT.md` ile onaylandı (M-F-18); C-001 ve aile M-009 KAPANDI.
**Hiyerarşi:** `00-AILE-MIMARISI.md` > `20-URETIM-SURECI.md` > `10-ARAC-KATALOGU.md` > `30-URUN-BLUEPRINT-STANDARDI.md` > **`CHOREIA-BLUEPRINT.md` (kapsam otoritesi)** > `choreia-roadmap.md` > **bu dosya** > ~~`choreia-brief.md`~~ (SÜPERSEDE EDİLDİ).
**Araştırma dayanağı:** `docs/research/R1-stil-katalogu.md` · `R2-rakip-dogrulama.md` · `R3-muzik-lisans.md` · `R4-senkron-ve-veri.md` · `R5a-hiphop-hasat.md` · `R5-hasat-launch.md` · `R7-hiphop-hareket-tarifleri.md` · blueprint korpusları (2026-07-28).

> ⚡ **KAPSAM HİZALAMASI 2026-07-29.** Bu plan ilk yazıldığında V1 = 2 stildi. Kurucu kapsamı blueprint'le **~30 stile** genişletti (5 dalga + 1 beklemede). Aşağıdaki bölümler buna göre revize edildi: §6 (dalga tabloları), §6.3 (perküsif onset skorlaması — yeni), §22 (V1-dışı), §24 (dalga-bazlı tamamlanma). Mimari **değişmedi** — "stil = içerik paketi, kod değil" ilkesi tam da bu genişlemeyi taşımak için kurulmuştu; 30 stil 30 kod yolu değil, 30 config paketidir.

> Bu belge Choreia'nın hedefini, V1 kapsamını, teknik mimarisini ve kritik risklerini tanımlar. Ürün tek kişi, tek sabit kamera, partnersiz ve ev ortamı için tasarlanır. V1'de partner dansı, çoklu kişi takibi, lisanslı müzik kataloğu ve gerçek-zamanlı LLM **yoktur**.

---

## 1. Projenin özeti

Choreia, kullanıcının telefonunu karşısına koyarak gerçek dans adımlarını öğrenmesini sağlayan mobil koçtur.

Sistem:
- Kullanıcıyı tam vücut izler
- Adımı önce yavaş ve sayımla öğretir
- Denemeyi beat'e göre değerlendirir (zamanlama + adım doğruluğu + form)
- Aynı anda **tek** sesli düzeltme verir
- Kombolara ve seviyelere ilerletir
- Gelişimi ölçülebilir biçimde gösterir

Ürün LLM tabanlı canlı kamera yorumlayıcısı **değildir**.

Temel mimari:
> On-device pose estimation + gövde-göreli normalizasyon + eklem-açısı benzerliği + bantlı DTW hizalama + beat ızgarası + deterministik kural motoru.

## 2. Ana hedef

> Evde tek başına dans öğrenirken, videoyu taklit edip "doğru mu yapıyorum?" sorusuyla kalma. Adımının doğru, zamanlamanın beat üstünde olup olmadığını **anında ve açıklanabilir** biçimde öğren.

Ürün gerçek dans eğitmeninin yerini aldığı iddiasında bulunmaz. Yarışma puanı, profesyonel değerlendirme veya "dansçı seviyesi sertifikası" iddiası taşımaz.

## 3. Konumlandırma ve rakip gerçeği

**Konumlandırma (EN, ürün dili):**
> *"A dance teacher in your pocket — learn real steps with live feedback on your timing and moves, to any beat."*

### 3.1 Rakip haritası (R2, 2026-07-26 store taraması)

| Rakip | Kamera feedback | Sesli koçluk | Doğrulanan fiyat |
|---|---|---|---|
| STEEZY (13k değerlendirme) | ❌ yalnız webcam AYNA | ❌ | $9.99–19.99/ay · $59.99–99.99/yıl |
| Everdance (3.5k) | ⚠️ insan eğitmen, **async** | ❌ | $7.99–49.99 |
| DanceFitMe (18k) | ❌ | ❌ | $9.99–49.99 |
| Just Dance Now (63k) / JD 2026 Camera Controller | ✅ gerçek ML skorlama (konsol) | ❌ | $2.99–24.99 |
| Apple Fitness+ / Peloton dans | ❌ (Peloton'da yalnız Strength'te var) | ❌ | — |
| **Dance Buddy: Learn Any Dance** (7 değerlendirme) | ✅ iddia ediyor | ✅ iddia ediyor | doğrulanamadı |

### 3.2 Beyaz alan iddiasının DÜRÜST hali

Önceki tur "kimse bunu yapmıyor" diyordu. **Bu YANLIŞ.** App Store'da *Dance Buddy* aynı kombinasyonu (gerçek-zamanlı poz feedback + sesli/görsel yönlendirme) açıkça iddia ediyor.

Ayakta kalan iddia şudur ve pazarlamada **yalnız bu** kullanılır:
> Kurulu oyuncuların hiçbiri (STEEZY, Everdance, DanceFitMe, Just Dance, Apple, Peloton) kamera-tabanlı gerçek-zamanlı skorlamayı sesli koçlukla birleştirmiyor. Aynı iddiayı taşıyan tek uygulama 7 değerlendirmeyle kanıtlanmamış durumda.

**Bağlayıcı sonuç:** "İlk biz yapıyoruz" denmez. "Bunu güvenilir ve ölçülebilir yapan yok" denir — ve bu iddia G10'da tekrar taranarak doğrulanır. Dance Buddy G0'da elle indirilip incelenir (**manuel liste**); gerçekten çalışıyorsa konumlandırma yeniden yazılır.

## 4. Hedef kullanıcılar

**Birincil:** Evde tek başına dans öğrenmek isteyen, ders videolarını taklit edip geri bildirim alamayan 18-35 yaş yetişkin. Sosyal ortamda (düğün, parti, salsa gecesi) utanmadan dans edebilmek istiyor.

**İkincil:** Ders alan ama derste öğrendiğini evde pekiştiremeyen öğrenci · sosyal medya için dans öğrenmek isteyen içerik üreticisi · ritim/koordinasyon çalışmak isteyen sporcu.

**V1 dışı kitle:** Profesyonel dansçı · yarışmacı · çocuk (ayrı rıza rejimi, D3 dersi) · partner dansı çifti · engelli-uyarlanmış müfredat (saygıyla ve doğru yapılmalı, V1'de yapılamaz).

## 5. Kullanım sınırları

**Desteklenen:** tek kişi · sabit telefon · tam vücut kadraj · ~2×2 m alan · ayakkabılı/çıplak ayak · kullanıcının kendi müziği (yerel) veya dahili beat · ayna modu.

**Desteklenmeyen:** partner · çoklu kişi · yerde çalışma (floorwork) · akrobasi/power move · hızlı çoklu dönüş · ayakkabı/kıyafet tanıma · "profesyonel seviye" hükmü · yaralanma teşhisi · yarışma puanı.

## 6. Kapsam: ~30 stil, 5 dalga — **KARAR K1 (blueprint ile revize)**

> **Kapsam otoritesi `CHOREIA-BLUEPRINT.md`'dir.** Bu bölüm onun plan-içi özetidir; çelişkide blueprint kazanır.

**Nihai ürün ~30 stildir, her biri kendi sayfasında.** Dalgalar **motor rollout'unun** sırasıdır, ürün vaadinin tavanı değil — kullanıcı kütüphanenin tamamını baştan görür, açılmamış stiller "yakında" durumundadır (standart §2: dar app algısı yaratılmaz, ama sahte/boş kurs listelenmez).

**Mimari genişlemeyi zaten taşıyor.** "Stil = içerik paketi, kod değil" ilkesi (§7) tam da bunun için kurulmuştu: 30 stil, 30 kod yolu değil **30 versiyonlu config paketidir**. Genişlemenin maliyeti G6 içerik hattındadır, motorda değil.

### 6.1 Dalga tablosu

| Dalga | Stiller | Neden bu sırada |
|---|---|---|
| **W1 — launch** | Hip-Hop foundations · Latin-fusion fitness dans · Line Dance · Salsa shines · TikTok-format | Hasat fizibilitesi **ölçülmüş** (≥3 bağımsız eğitmen ✓); vokabüler kodifiye; telifi en temiz; yarım-tempo öğretim = doğal slow-mo referansı |
| **W2 — hızlı takip** | K-Pop point-choreo (ayna-modu) · Bachata solo · Afrobeats + **Amapiano döner trend-paketi** · Dancehall · Shuffle · Belly Dance · Bollywood · **Merengue + Cumbia solo** | Merengue/Cumbia bachata-shines deseninin birebir tekrarı — **en ucuz ekleme**. Amapiano sabit müfredat değil, viral döngü |
| **W3 — syllabus-destekli** | **Ballroom/Latin Solo ailesi (7 dans: Cha-Cha, Rumba, Jive, Waltz, Quickstep, Paso Doble, Tango solo)** tek sayfa · **Tap** (onset) · **Funk Styles paketi: Locking + Popping + Waacking + Vogue** · Jazz · **Samba no Pé** · Solo Jazz/Charleston/**Shim Sham** · **Bhangra** | Ballroom ailesi tek IA sayfası altında 7 sekme — ölçek ekonomisi. Popping hit'leri RhythmEngine'e birebir oturuyor. Shim Sham sabit 32-count → DTW-dostu |
| **W4** | Balet/Barre · Contemporary (ayakta alt-küme) · **Flamenco** (onset + palmas) · **Irish** (hard-shoe onset / soft-shoe poz) · Kizomba/Zouk solo · **Garba** (solo footwork; **Dandiya-Raas ❌**) · Twerk + Reggaeton/Perreo | Onset-skorlamalı stiller W3'te kanıtlandıktan sonra. Garba sezonluk (Navratri). Duyusal-kova store-policy turu bu dalgadan ÖNCE |
| **W5** | Heels (ayakkabı-güvenlik onboarding'i) · Breaking (toprock/uprock skorlu; power move demo-only) | Güvenlik çerçevesi en ağır olanlar sona |
| **⏸ Beklemede** | **Hula** | hālau/kumu-hula ortaklığı OLMADAN yapılmaz — yaşayan kültürel-manevi pratik; jenerik kaynakla içerik üretimi yasak |
| **Elendi (sessiz)** | Kuduro · Dabke · Yunan halk/sirtaki · Country two-step | Kanıt ince. "Neden yok?" sayfası gerekmez |

### 6.2 W1 seçiminin gerekçesi (ölçülmüş)

> **Launch = Hip-Hop Foundations + Latin-fusion fitness + Line Dance + Salsa shines + TikTok-format.**

İlk plan W1'i 2 stille açıyordu; blueprint 5'e çıkardı. İkisinin de dayanağı aynı ölçüm: **≥3 bağımsız eğitmen kriteri hip-hop ve salsa'da doğrulandı** (C-030, sonda ile: Cabbage Patch 4 kanal, Roger Rabbit 4, Running Man 3).

- **Hip-Hop Foundations** — 20 çekirdek adımın tamamı yerinde/dönüşsüz; telif adım-seviyesinde temiz (üç mahkeme emsali: *2 Milly*, *Ribeiro/Carlton*, *Hanagami*); en güçlü pazar sinyali.
- **Salsa shines** — dansın kendi içinde adı konmuş **solo** alt-kategorisi; sayım sistemi katı → zamanlama ölçen ürün için en verimli zemin. ⚠️ BPM çelişkili (C-032, ölçümle çözülecek); vokabüler tek-kaynaklı (C-033) → adım hedefi vokabüler-uyarlamalı.
- **Line Dance** — step-sheet formatı kural-motoruna **birebir** oturuyor; CV profili en güvenilir (kaba, büyük genlikli). ⚠️ Yayımlı step-sheet **kopyalanmaz**, orijinal diziler.
- **Latin-fusion fitness** — ⚠️ **"Zumba" adı KULLANILMAZ** (tescilli marka).
- **TikTok-format** — orijinal kombolar; isimli viral koreografi öğretilmez.

### 6.3 Perküsif onset skorlaması — **yeni motor bağlantısı (K9)**

Tap, Flamenco (zapateado) ve Irish hard-shoe'da **ayak sesinin zamanlaması** puanlanır: shuffle/flap/stamp ayrımı + beat'e göre sapma.

**Yeni modül değil, iki mevcut modülün bağlanması:** Ostinato'nun onset motoru + bizim beat-grid'imiz. Mikrofon ve kamera **tek saatte** timestamp'lenir — Ostinato'nun tek-saat sözleşmesi zaten bunu tanımlıyor (§9.4).

Bu, üründeki **benzersiz farkın** kaynağı: kamera bir tap dansçısının ayağını yeterince hassas göremez, ama **sesi duyabilir**. Poz skorlaması ile onset skorlaması birbirinin yerine geçmez, tamamlar.

⚠️ Donanım bağımlılığı onboarding'de açık olmalı: tap ayakkabısı + sert zemin **zorunlu**; flamenko ayakkabısı önerilir. Bu bir kısıt değil, dürüstlük gereği (§7).

**Spike DEFTER'e yazıldı; koordinatörün çekirdek-merge'inden sonra çalışılır** (W3 öncesi).

### 6.4 Elenenlerin revizyonu

İlk plan bazı stilleri elemişti; blueprint çoğunu **dalgaya taşıdı**, çünkü eleme gerekçeleri kapsam değil *sıra* gerekçesiydi:

| Stil | İlk hüküm | Blueprint |
|---|---|---|
| K-Pop / Jazz-Funk | ❌ elendi (telif 1/5) | **W2** — point-choreo + ayna-modu; ajans içeriği yüksek-dikkat, bağımsız eğitmen öncelikli |
| Breaking | ❌ (dönüş pedagojinin özü) | **W5** — toprock/uprock **skorlu**, power move **demo-only** + güvenlik uyarısı |
| House Dance | ❌ ("counts değil feeling") | Blueprint'te W-listesinde **yok** — C-034 ile doğrulanan yapısal gerilim korunuyor |
| Belly Dance | ❌ (shimmy landmark-altı) | **W2** — prop'lar avatar-demo; shimmy skorlanmaz, öğretilir |
| Line Dance · Latin/Cha-Cha | ertelenmişti | **W1** ve **W3** |
| Afrobeats / Dancehall | V2 araştırması | **W2** |

Değişmeyen tek şey: **ölçemediğimizi skorlamayız.** Blueprint bunu eleme yerine *skorlu / demo-only* ayrımıyla çözüyor — daha iyi bir çözüm, çünkü kullanıcı hareketi öğrenebiliyor, biz de ölçemediğimiz şeye puan vermiyoruz.

### 6.5 Hukuk katmanı bayrağı (her stil sayfasında zorunlu)

🟢 sosyal/halk adımı (serbest) · 🟡 stil-temsili **orijinal** kombo · 🔴 adlı ticari koreografi / marka adı / syllabus metni **YASAK**.

ISTD/WDSF gibi syllabus'lardan **yapı ve figür ADLARI** esinlenilir; **müfredat metni telifli**, anlatım daima orijinaldir.

### 6.6 Arşiv: ilk 2-stil gerekçesi

> ~~V1 = Hip-Hop Foundations (32/35) + Salsa Shines (31/35).~~ (2026-07-26 kararı, blueprint ile genişletildi)

**Hip-Hop Foundations — neden:**
- 20 çekirdek adımın tamamı yerinde ve dönüşsüz → tek sabit kamera için ideal.
- Telif: adım-seviyesinde koruma yok; üç mahkeme emsali (*2 Milly*, *Ribeiro/Carlton*, *Hanagami*) tekil adımların korunmadığını, yalnız orijinal dizilimlerin korunabildiğini doğruluyor.
- En güçlü pazar sinyali (13-26M abonelikli öğretici kanallar).
- Orta tempo (~90-110 BPM) → beat penceresi rahat, blur riski düşük.

**Salsa Shines — neden:**
- Dansın kendi içinde zaten adı konmuş **solo** alt-kategorisi ("shines") — partnersizlik bir eksiklik değil, stilin doğal hali.
- Sayım sistemi net ve katı (1-2-3 / 5-6-7; 89-100 BPM) → zamanlama ölçen bir ürün için en verimli zemin.
- Suzy Q gibi temel adımların 1930'lara uzanan kamu-malı geçmişi var.

**İkisi birlikte neden:** biri **en büyük pazar**, diğeri **en yüksek ölçülebilirlik**; pedagojileri farklı (groove-tabanlı vs katı-sayım), bu da "stil = içerik paketi, kod değil" mimarisini V1'de gerçekten sınar. Tek stille bu mimari test edilmemiş kalırdı.

İlk turun 12-stil puanlaması (`R1-stil-katalogu.md`, 7 kriter) **hâlâ geçerli girdi**: dalga sırası büyük ölçüde o puanlamayı izliyor. Değişen, puanı düşük olanın *elenmesi* değil, **daha sonraki bir dalgaya ve uygun skorlama moduna** yerleşmesi (§6.4).

## 7. Müfredat modeli

```text
Style (hip_hop_foundations | salsa_shines)
└── Level (1..4)
    └── Lesson
        ├── Step[]        (atomik hareket, kendi state-machine'i + referans şablonu)
        └── Combo[]       (Step dizilimi + geçiş kuralları)
```

**Bağlayıcı ilke: yeni stil = yeni içerik paketi, kod değişimi DEĞİL.** Adım tanımı, kural seti, eşikler, sayım metni, sesli koç replikleri ve referans şablonu tamamı **versiyonlu JSON**'da yaşar. Motor bunları yorumlar. Bir stil eklemek derleme gerektirmez.

**Ders akışı (her ders aynı iskelet):**
1. **Teach** — referans video + yavaş tempo + sayım ("5-6-7-8, and 1...")
2. **Try slow** — beat yok veya %60 tempo; yalnız şekil ölçülür
3. **Try on beat** — tam tempo; şekil + zamanlama ölçülür
4. **One correction** — tek sesli düzeltme + tekrar
5. **Combo** — adım dizilimi
6. **Session summary** — bileşen skorları + gelişim

**Seviye atlama kriteri ders tamamlamak DEĞİLDİR.** Ölçülebilir eşik: aynı adımda ardışık 3 denemede `onBeatRatio ≥ 0.7` ve `shapeScore ≥ 0.75` (eşikler versiyonlu config; G4'te gerçek fixture'larla kalibre edilir — bkz. §12.4).

## 8. Teknik mimari

```text
Camera (native)
→ Pose Landmarker (MediaPipe Tasks, full/heavy/lite adaptif)
→ Landmark Confidence Gate
→ One Euro Smoothing
→ Body Normalization (torso-relative)
→ Joint Angle Extraction (flexion + trunk-relative orientation)
→ Step State Machines  ──┐
→ Beat Grid / Perceived Timeline ──┤
→ Sequence Comparator (banded DTW + angular similarity)
→ Scoring (shape · timing · consistency · tracking)
→ Feedback Prioritizer (tek cue + cooldown + quiet window)
→ Voice / Visual Feedback
→ Local-first Storage
```

### 8.1 Native ↔ Dart sınırı — **KARAR K2**

| Katman | Nerede | Neden |
|---|---|---|
| Kamera, inference, per-frame landmark tamponu, güven kapısı, smoothing, normalizasyon, adım state-machine'i, beat saati | **Native** (Kotlin/Swift) | Gecikme ve kanal diyeti (katalog §2): 30fps ham landmark Dart'a AKITILMAZ |
| UI, TTS tetikleme, kalıcılık, müfredat/config, seans orkestrasyonu, ilerleme | **Dart/Flutter** | — |
| Dart'a akan | state-machine olayları + skorlar + ~10-15fps desimasyonlu overlay iskeleti | Pigeon event kanalı |

### 8.2 `motion_core` — normatif referans (bu oturumda KURULDU)

Choreia ailenin ilk tetiklenen ürünü olduğu için çekirdeği bu oturum kurdu (`motion-core` CLAUDE.md: "çekirdek kod İLK app'in tetiğiyle yazılır"). Saf Dart, Flutter bağımlılığı yok.

**Rolü kritik:** gerçek-zamanlı döngü native koşar, ama **algoritmanın doğru cevabı tek yerde tanımlıdır**. Native port, paylaşılan fixture'lar replay edilerek bu implementasyonun çıktısına karşı doğrulanır (golden karşılaştırma). İkisi çeliştiğinde `motion_core` tanım gereği haklıdır.

Modüller: `pose/` (landmark topolojisi, güven kapısı, One Euro) · `geometry/` (normalizasyon, açı çıkarımı) · `scoring/` (tolerans, açısal benzerlik, bantlı DTW, dizi karşılaştırıcı) · `rhythm/` (beat ızgarası, algılanan zaman çizelgesi, zamanlama yargısı) · `engine/` (faz state-machine çatısı, geri bildirim önceliklendirici) · `fixture/` (şema, replay harness, sentetik iskelet üreteci).

Durum: **76/76 test yeşil**, `dart analyze` temiz.

## 9. Beat ve senkron mimarisi

### 9.1 Beat kaynağı — **KARAR K3**

Beat ızgarası müzik kaynağından **soyutlanır**; üç kaynak aynı arayüzden akar:

| Sürüm | Kaynak | Risk |
|---|---|---|
| **V1** | Dahili metronom + BPM'i **bilinen** royalty-free beat kütüphanesi | Sıfır tespit riski, sıfır telif riski |
| **V1.5** | Kullanıcının kendi yerel dosyası → **tek seferlik offline** BPM/beat-grid analizi + önbellek | Analiz doğruluğu (G1'de ölçülür) |
| ❌ Asla | Canlı beat takibi; Spotify/Apple Music üzerinden senkron | §16 |

Canlı tespit şart olursa: **Superpowered SDK** (ücretli, temiz lisans) — kurucu onaylı harcama. ❌ aubio/TarsosDSP/Essentia (GPL/AGPL, M-014).

### 9.2 Ses gecikmesi kalibrasyonu — **KARAR K4 (P0 mühendislik kararı)**

R4 bulgusu, ürünün en sinsi hata kaynağını ortaya koydu:

- Bluetooth gerçek ölçümleri üretici iddiasının **2-3 katı** (SBC ~308ms, AAC ~369ms ölçüldü; iddia 100-150ms).
- **Platform API'leri güvenilmez:** iOS `AVAudioSession.outputLatency` BT'de bir dakika içinde 193→260ms dalgalanabiliyor (Apple Developer Forums'ta dokümante). Android `AudioTrack.getTimestamp()` için BT'ye dair resmî garanti yok.

**Bağlayıcı sonuç:** Motor, beat'i *planlandığı* ana göre değil **kullanıcının duyduğu** ana göre yargılar. Telafi edilmezse motor, tam zamanında dans eden kullanıcıya **her beat'te** "geç kaldın" der ve hiçbir tolerans ayarı bunu düzeltmez.

Uygulama:
1. `AudioLatencyProfile` **route başına** saklanır (hoparlör / kablolu / BT ayrı). Route değişince yeniden sorulur.
2. Onboarding'de **tap-test kalibrasyonu**: kullanıcı metronoma vurur, medyan offset kaydedilir. Platform değeri yalnız başlangıç tahminidir.
3. `TimingSummary.suggestsCalibrationIssue` — büyük ama **dar dağılımlı** sapma kalibrasyon imzasıdır. Bu durumda kullanıcıya "acele ediyorsun" DENMEZ; yeniden kalibrasyon önerilir. *Kendi hatamızı kullanıcıya yüklemek, verilebilecek en zararlı geri bildirimdir.*

### 9.3 Tolerans pencereleri — **KARAR K5**

Hibrit: beat'in yüzdesi, mutlak taban ve tavan arasında sıkıştırılmış.

| Seviye | Beat oranı | Taban | Tavan |
|---|---|---|---|
| Başlangıç | %15 | 80 ms | 200 ms |
| Orta | %12 | 60 ms | 130 ms |
| İleri | %10 | 40 ms | 80 ms |

Dayanak: ritim-oyunu yargı pencereleri (osu! OD ±20-150ms; DDR/StepMania 17-225ms) + eğitimli/amatör senkronizasyon değişkenliği.

⚠️ **Dürüstlük notu:** Bu SD değerleri **parmak vuruşu** literatüründen geliyor; tüm-vücut dans değişkenliği daha büyüktür ve **bizim için doğrulanmamıştır** (R4 §A5). Başlangıç penceresi bu yüzden cömert uçta. Kendi değerimizi ölçmek G1 kapı maddesidir.

**NMA (negatif ortalama asenkroni):** İnsan beat'ten ~20-50ms ÖNCE hareket eder ve bunu "tam üstünde" algılar. Sabit `SyncConstants.literatureNegativeMeanAsynchronyUs = 25000` olarak tanımlı ama **varsayılan olarak UYGULANMIYOR** — ödünç bir sayıyı doğrulamadan kullanmak ürünün her zamanlama skoruna sistematik bir yanlılık koymak olurdu. Kendi ölçümümüz G1'de.

### 9.4 Tek saat

Pose ve ses akışları **aynı monotonic saatle** timestamp'lenir (motion-core sözleşmesi). Duvar saati ile monotonic saatin karışması, cihaz uyuduktan sonra ortaya çıkan ve fixture'ların yakalayamayacağı bir hata sınıfıdır.

## 10. Adım durum makineleri

Her adım fazlara ayrılır; **zamanlama metrikleri faz timestamp'lerinden türetilir, kare-arası piksel hızından DEĞİL** (aile kuralı D2, JabLab dersi). 30fps'te hızlı bir hareket 1-2 blurlu kareye sığar ve oradaki piksel hızı gürültüdür; faz sınırı ise duruşla tanımlı olduğu için blur'a dayanır.

Örnek — salsa temel adım (yarım ölçü):
```text
READY (weight centered)
→ WEIGHT_SHIFT_INITIATED
→ STEP_LAND            ← skorlanan an (beat 1)
→ WEIGHT_TRANSFERRED
→ REPLACE
→ READY
```

Örnek — hip-hop bounce:
```text
UP
→ DOWN_DRIVE
→ BOTTOM               ← skorlanan an (beat üstü)
→ REBOUND
→ UP
```

Her fazın tanımı: giriş koşulu · çıkış koşulu · timeout · iptal koşulu · gerekli landmark seti · güven eşiği · teknik metrik · hata kodu. Hepsi versiyonlu config.

⚠️ **Bu oturumda öğrenilen ders (fixture'a yazıldı):** Yumuşatma bilinçli olarak geciktirir. Bir çekim hareket biter bitmez sonlanırsa filtre dinlenme değerine dönemez ve "recovered" eşiği hiç ateşlenmez. **Kural eşikleri kâğıttaki geometriye göre değil, filtrelenmiş sinyale göre yazılır**; referans çekimlerinde kapanış pozu kısaca tutulur.

## 11. Referans üretim hattı — **KURUCU KARARI (aile-geneli bağlayıcı)**

> Kanonik metin: `10-ARAC-KATALOGU.md §6.0` · aile defteri `M-C-01..04`. Bu bölüm o kararın Choreia'ya uygulanışıdır; **yeniden tartışılmaz**.

```text
Kamuya açık gerçek eğitmen videoları (≥3, tercihen 6+ bağımsız kaynak)
→ MediaPipe landmark çıkarımı (mevcut Python hattı — M-017 kararı)
→ KALİTE KAPILARI: aynalama konsensüsü · kamera açısı · plan/kesme sınırı · StructuralValidator
→ ReferenceBuilder: medoid zaman tabanı + DTW hizalama + dairesel ortalama
→ CanonicalReference (açı dizisi + eğitmen-varyansından türetilmiş TOLERANS)
→ Elle: faz etiketleme + beat anotasyonu (videodan GELMEZ)
→ Hatalı fixture'lar: referansın kontrollü bozulması (etiket bedava)
```

**Neden tek video yetmez — iki bağımsız gerekçe:**

1. **Aynalama tek videoda çözülemez.** Eğitmenler izleyiciye göre aynalayarak öğretir ve landmark'ta bunu söyleyen hiçbir şey yoktur. N takede konsensüsle çözülür (her take iki yönde denenir, grup uyumunu en çoklayan atama seçilir). Çözülmezse ürün her kullanıcıya **sistematik olarak ters taraf** öğretir — C-005'in en kötü hâli.
2. **Eğitmenler arası varyans, toleransın kendisidir.** Çoğunluk aynı şeyi yapıyorsa *o* adımdır; ayrıştıkları yer kişisel stildir. Eğitmenlerin kendi aralarında anlaşamadığı bir eklemde kullanıcıyı cezalandırmak dürüstlük ihlali olur. **Tek eğitmenden bu bilgi asla çıkmaz** — çoklu kaynağın asıl gerekçesi hacim değil budur.

**Öğretim görseli ayrı bir artefakttır.** Kullanıcıya gösterilen kısa video, skorlama referansı değildir; **inandırıcı** olması yeter, AI üretimi serbesttir (EU AI Act Art.50 ifşasıyla). **AI videodan landmark çıkarılmaz** — üretken modelin anatomi motoru yoktur.

**Uzman doğrulaması:** eğitmenle sözleşme/anlaşma **gerekmez**. Ship öncesi tek seferlik kural-seti kontrolü yeter — referans parametrik olduğu için uzman "ağırlık 40ms erken aktarılmalı" dediğinde bir sayı değişir, yeniden çekim yoktur.

**Hukuki pozisyon:** YouTube ToS ve türev-eser riski kurucuya sunuldu ve **kurucu kararıyla kabul edildi** (DEFTER C-017). Lansman öncesi IP görüşü manuel listede kalır.

**Bu hat araçlaştırılır.** Her yeni ders elle uğraş istememeli — aksi halde stil eklemenin maliyeti içerik değil emek olur ve "stil = paket" vaadi kâğıt üstünde kalır. `ReferenceBuilder` çekirdekte hazır (94/94 test); kalan (b)(c)(e) kapıları G1 pilotunda ölçülür.

## 12. Skorlama

### 12.1 Bileşenler (tek "doğruluk" skoru YOK)

| Bileşen | Kaynak |
|---|---|
| **Timing** | Beat-kilitli `ScoredMoment`'ların algılanan-beat'e göre sapması |
| **Step accuracy** | Doğru adım, doğru sırada, doğru ayakla |
| **Shape** | Belirginlik-ağırlıklı açısal benzerlik (DTW hizalı) |
| **Flow / consistency** | Zamanlama sapmasının standart sapması (yanlılıktan ayrı) |
| **Tracking confidence** | Ölçülebilen kare/eklem oranı |

**Yanlılık ile dağılım ayrı raporlanır.** Sürekli 120ms erken olan bir dansçının *alışkanlığı* (ya da kalibrasyonu) vardır; dağınık olanın *hassasiyet* sorunu vardır. İkisi farklı ders gerektirir.

### 12.2 Neden ham koordinat DTW YASAK

Açının birimi yoktur → farklı vücut oranlarına yapısı gereği dayanıklıdır. Pozisyon karşılaştırması değildir. Bu, testle kanıtlanmış bir iddiadır: aynı poz, uzun-ince ve kısa-geniş vücutta **ortalama < 3° açı farkı** ama **> 0.04 torso-birimi pozisyon farkı** üretiyor (`scoring_test.dart`).

### 12.3 DTW'nin hile yapması — bu oturumda yakalandı ve kapatıldı

Geniş bir bantta DTW'nin en ucuz yolu **park etmektir**: bir öğrenci karesini tutup referansı en belirgin anlarından geçirmek. Sonuç: hareketsiz duran öğrenci, adımı yapmış gibi yüksek skor alır.

Ölçüm: yanlış hareket (kollar yukarı vs yana adım) **0.938** alıyordu. Diyagonal-dışı adımlara **warp cezası** eklenince **0.775**'e düştü; doğru hareket 1.000'de kaldı (vücut tipi, gürültü ve 1.4× tempo değişimi altında da). Ceza yalnız hizalamayı yönlendirir; **raporlanan skor seçilen yol üzerinde ham mesafeden yeniden hesaplanır** — regülarizasyon terimi skoru şişirmez veya bastırmaz.

Ayrıca **belirginlik ağırlıklandırması**: dinlenme pozuna yakın kareler düşük ağırlık alır. Aksi halde çoğu kare nötre yakın olduğu için tamamen farklı bir hareket bile o karelerden puan toplar.

**Band doygunluğu** dürüst bir başarısızlık sinyalidir: yol koridorun duvarına yaslandıysa hizalamaya güvenilmez ve skor **verilmez** — "seni eşleştiremedim" denir.

### 12.4 Kalibrasyon açık maddesi (G4 kapısı)

Bir denemeye **kullanıcıya gösterilecek sayının ne olması gerektiği** sentetik fixture'la çözülemez; gerçek kayıt + insan yargısı ister. Mekanizma kanıtlandı (doğru 1.000 / yanlış 0.775, ayrım > 0.15, hata doğru uzva atfediliyor); **mutlak eşik kalibrasyonu G4'e açıktır** ve o kapı geçilmeden hiçbir skor kullanıcıya gösterilmez.

## 13. Hata kodları ve geri bildirim

**V1 ilk güvenilir hatalar** (önce az ve kesin, sonra kapsam):
`STEP_LATE` · `STEP_EARLY` · `STEP_MISSED` · `WRONG_FOOT` · `COMBO_ORDER_ERROR` · `WEIGHT_NOT_TRANSFERRED` · `KNEES_LOCKED` · `NO_BOUNCE` (hip-hop) · `ARMS_DEAD` · `TORSO_STIFF` · `MIRROR_SIDE_SWAPPED` · `OUT_OF_FRAME` · `LOW_LIGHT` · `LOW_TRACKING_CONFIDENCE` · `AUDIO_LATENCY_SUSPECTED`

Her hata: severity · confidence · evidence · cooldown · feedback metni (içerikte, kodda değil) · ilgili drill.

### 13.1 Sesli koç kuralları

Telefon uzakta olacağı için ana kanal sestir. Zor olan geri bildirim üretmek değil, **üretmemektir**:
- Aynı anda **tek** hata
- Sayım sırasında **sessizlik** (`requestQuietUntil`) — koçun sayımın üstüne konuşması öğrenmeye aktif zarar verir
- Global cooldown + kod-başına cooldown
- Tekrar sayısına göre ifade değişir (aynı cümleyi altı kez duyan kullanıcı dinlemeyi bırakır)
- Düzeltilince **olumlu kapanış** (`*_RESOLVED`) — neyin yanlış olduğunu söyleyip düzeldiğini söylememek, kullanıcıyı düzeltmesinin işe yarayıp yaramadığını bilmeden bırakır
- Güvenlik uyarısı her şeyi keser
- Düşük güvende **hüküm YOK** → çerçeveleme ipucuna yönlendirilir

### 13.2 Güvenilirlik ilkesi

Sistem şunları ayırmak zorundadır: (1) hareket yanlış · (2) kamera göremiyor · (3) hareket henüz bitmedi · (4) geçerli varyasyon · (5) model emin değil. **Yalnız (1) düzeltme üretir.**

✅ *"I can't see your feet — step back a little."*
❌ *"Your footwork is wrong."* (ayak hiç görünmediğinde)

## 14. Ayna modu — **KARAR K6**

Dansta kritik ve tipik bir hata kaynağı (C-005). Referans **varsayılan olarak aynalanır** (kullanıcı ekrandaki figürü ayna gibi taklit eder). Sol/sağ eşlemesi `LmMirror` ile **merkezî** olarak çözülür; hiçbir kural içinde `if (mirrored)` dallanması olmaz. Aynalama ayrıca lead-side değişimi için de kullanılır.

## 15. Veri modeli

`UserProfile` · `CalibrationProfile` (vücut ölçeği) · `AudioLatencyProfile` (**route başına**) · `StyleTrack` · `Level` · `Lesson` · `StepDefinition` · `ComboDefinition` · `ReferenceSequence` · `ScoredMoment` · `RuleSet` + `RuleSetVersion` · `Attempt` · `AttemptMetric` · `TimingMetric` · `DetectedIssue` · `FeedbackEvent` · `Session` · `ProgressMetric` · `BeatSource` · `ModelVersion`

**Ham video varsayılan olarak kaydedilmez.** `ModelVersion` her kayda yazılır — MediaPipe hâlâ "Solutions Preview" (SLA yok); model yükseltmesi geçmişi sessizce yeniden yorumlayamamalı.

## 16. Müzik telifi ve hukuki sınırlar — **KARAR K7 (kırmızı çizgi)**

R3 birincil kaynak taramasının sonucu:

| Yol | Hüküm |
|---|---|
| Uygulama içi **lisanslı katalog** | ❌ V1'de YOK |
| **Kullanıcının kendi yerel dosyası**, yalnız cihazda çalma | ✅ V1 varsayılanı; en düşük risk (VLC/Ferrite emsali) |
| **Royalty-free, app-içi dağıtım haklı** kütüphane | ✅ Uppbeat (kullanıcı sözleşmesinde "online games or applications" açık) · Envato Elements / AudioJungle (kopya tavanına dikkat) · Pond5 (perpetual) |
| **Spotify SDK** | ❌ Geliştirici Politikası **senkronizasyonu açıkça yasaklıyor**; ham ses erişimi de yok |
| **Apple MusicKit** | ❌ V1'de kullanılmaz. Abonelik şart, paywall arkasına konamaz ve kritik olarak *"belirli bir anda şarkı çalma"* standart iznin ÖTESİNDE — yani beat-senkron tam olarak izin kapsamı dışında kalabilir |
| Artlist / Epidemic / Soundstripe | ⚠️ Standart planlar app-içi dağıtımı KAPSAMIYOR; ayrı Business katmanı ($2.500-25.000/yıl bandı) gerekir |

### 16.0 V1 müzik bütçesi: **$0** (kurucu kararı, C-018)

Çekirdek beat kaynağı **kendi ürettiğimiz metronom** — hiçbir lisans gerektirmiyor. Kullanıcının kendi müziği yerel çalınıyor, o da bedava. Ek parça gerekirse **ücretsiz ve mecra-sınırsız** kaynaklar var: Pixabay Music · Incompetech (CC-BY 4.0, künye ekranı yeter) · Free Music Archive (parça başı lisans kontrolü).

Bedavanın maliyeti para değil, iki şey: **BPM etiketi genelde yok** (tek seferlik ölçeriz — "bilinen BPM" mimarisi zaten bunu gerektiriyor) ve **küratörlük zamanı** (tempo'su sabit, dansa uygun parça ayıklamak). Ücretli kütüphane **bloke edici değil, cila**; G6'ya, "ürün tuttuysa" kararına bırakıldı.

**En büyük tuzak:** "Royalty-free" sözcüğü lineer içerik (YouTube/reklam) senkronizasyonu demektir. Mobil uygulama içinde çalma çoğu lisansta ayrı ve pahalı katmandır. İkinci tuzak: **gizli kopya tavanları** (AudioJungle Standard 10.000, PremiumBeat Enhanced 1.000) — uygulama büyürse lisans aşılır.

### 16.1 Koreografi telifi

Tekil adımlar ve sosyal/halk dansları korunmaz; **orijinal diziler korunur**. Bağlayıcı sonuç:
- ❌ *"Learn [Artist]'s official choreography"* pazarlaması YAPILMAZ
- ✅ Jenerik adım vokabüleri + **kendi orijinal kombolarımız**
- Ders adlandırma süzgeci G9'da `legal-contracts-advisor` turundan geçer

⚠️ Bu araştırma hukuki görüş değildir. Lansman öncesi IP/eğlence hukuku görüşü **manuel listede**.

## 17. Gizlilik

Kamera + vücut analizi = hassas veri. On-device işleme · yüz tanıma yok · **ham video cihazdan çıkmaz** · yalnız landmark türevleri ve skorlar saklanır · kullanıcı müziği yalnız yerel çalınır, hiçbir sunucuya gitmez · silme ve dışa aktarma hakkı. Store beyanları (Apple 5.1.1 / Play Data Safety) kodla birebir eşleşir. EU AI Act Art.50 değerlendirmesi LifeOS şablonundan uyarlanır. Kamera izin gerekçe metni ekranda açık.

## 18. Riskler

| ID | Şiddet | Risk | Azaltma |
|---|---|---|---|
| C-002 | P1 | Ses gecikmesi (BT değişkenliği) tüm zamanlama skorunu kaydırır | §9.2 route-başına kalibrasyon + `suggestsCalibrationIssue` |
| C-003 | P1 | Müzik telifi | §16, V1 = yerel dosya + BPM'i bilinen royalty-free |
| C-004 | P2 | Stil-başına müfredat maliyeti | Araçlaştırılmış referans hattı (§11); G1'de 1 stilin tam maliyeti ölçülür |
| C-005 | P2 | Ayna/yön eşleme hataları | §14 merkezî aynalama |
| C-006 | P2 | Hızlı hareket blur/fps | Faz-süresi metriği (D2); G1 profil ölçümü |
| C-007 | P1 | **Beyaz alan iddiası daraldı** (Dance Buddy) | §3.2 dürüst konumlandırma + G0 elle inceleme |
| C-008 | P2 | Skor mutlak kalibrasyonu yapılmadı | §12.4, G4 kapısı; kalibrasyonsuz skor gösterilmez |
| C-009 | P2 | Groove/musicality öznel — hip-hop'ta "doğru" tartışmalı | V1 yalnız adım+zamanlama skorlar; stil/ifade skorlanmaz, açıkça söylenir |
| C-010 | P1 | Termal/pil: 20-40 dk seans + pose + ses + TTS eşzamanlı | Native termal monitör + kademeli düşürme (çözünürlük→fps→model varyantı); G8 |

## 19. Test stratejisi

**Replay testleri (zorunlu):** her adım için ≥1 doğru + ≥2 hatalı fixture. Ayrıca: düşük ışık · bol kıyafet · farklı vücut tipi · kadraj dışı · occlusion · düşük fps · gecikmeli ses.

**Unit testleri:** normalizasyon · açı çıkarımı · benzerlik · DTW (park etme regresyonu dahil) · beat ızgarası · gecikme telafisi · zamanlama pencereleri · state-machine timeout/tracking-loss · geri bildirim cooldown.

**Değişmezlik testleri:** vücut tipi · kamera mesafesi · tempo · gürültü.

**Native ↔ Dart golden testleri:** aynı fixture, iki implementasyon, aynı çıktı.

**İnsan testi:** farklı vücut tipi · farklı ışık · küçük oda · farklı telefon · **BT kulaklık** (zorunlu senaryo).

**Uzman doğrulaması:** hip-hop ve salsa için birer gerçek eğitmen kural setini onaylamalı (**manuel liste**).

⚠️ **Bu oturumda öğrenilen ders:** Bir fixture, sınadığı toleranstan büyük olmalıdır. İlk sentetik adımım 15° genlikteydi, skorlayıcının serbest bandı ise 12° — her kare her kareye uyuyordu ve hizalama testleri hiçbir şeyi sınamadan geçiyordu.

## 20. Başarı ölçütleri

Kamera kurulum başarı oranı · **geçerli-skor oranı** (kaç deneme yargılanabildi) · kalibrasyon tamamlama oranı · ilk kombonun beat-uyumlu tamamlanma oranı · `onBeatRatio`'nun zaman içinde gelişimi · aynı seans içinde düzeltebilme oranı · yanlış-pozitif hata oranı · D7/D30 · ücretsizden premium'a geçiş · internetsiz kullanım.

**Kuzey yıldızı:** ilk kombosunu beat-uyumlu tamamlayan kullanıcı oranı.

## 21. Fiyatlama girdisi (G9 — nihai fiyat KURUCU)

Koridor: **$9.99-14.99/ay · $59.99-89.99/yıl**. Doğrulanan referans: STEEZY $9.99-19.99/ay, $59.99-99.99/yıl.
Paywall deseni: **assessment-kapılı** — ilk ders + ilk skorlu deneme ücretsiz; değer kanıtlandıktan sonra stil kütüphanesi + ilerleme abonelik.
Trial 7 gün varsayılan; 14 gün ciddi değerlendirilir (beceri gelişimi bir haftada görünmez).
Aile paketi lansmanda YOK.

## 22. Kapsam dışı (dalgadan bağımsız — hiçbir zaman)

Partner dansı · çoklu kişi takibi · sosyal ağ/feed · canlı ders · yarışma puanı iddiası · gerçek-zamanlı LLM · çoklu kamera · uygulama içi lisanslı müzik kataloğu · Spotify/Apple Music entegrasyonu · **isimli sanatçı/ticari koreografi** · koç pazaryeri · medikal/tedavi iddiası · **Dandiya-Raas** (çift-sopa vuruşmalı, solo öğrenilemez) · **Hula** (ortaklık olmadan).

**"Skorlanmaz ama öğretilir" kovası** — kapsam dışı DEĞİL, ölçüm dışı: yer çalışması/floorwork · power move'lar (Breaking) · shimmy (Belly) · prop'lu figürler · groove/musicality/ifade. Bunlar **demo-only** olarak sunulur ve kullanıcıya *neden* skorlanmadığı açıkça söylenir. Eleme yerine bu ayrımı kullanmak, hem hareketi öğretmeyi hem ölçemediğimize puan vermemeyi mümkün kılıyor.

## 23. Claude Code için kurallar

- Kapsam otoritesi `CHOREIA-BLUEPRINT.md`; dalga sırası dışına atlama, ama kapsamı da daraltma.
- Yeni stil = **içerik paketi**. Stil eklemek için motora dokunuyorsan dur — mimari kırılmış demektir.
- Ölçemediğin hareketi elemek yerine **demo-only** işaretle; kullanıcıya nedenini söyle.
- Pose modelini karar motoru sanma; tüm hükümler açıklanabilir kural motorundan çıkar.
- Düşük güvende hüküm verme.
- Ham koordinat DTW yazma; önce normalizasyon/açı.
- Warp cezasını kaldırma — park etme regresyon testi bunu korur.
- Zamanlamayı faz timestamp'inden türet; kare-arası piksel hızından ASLA.
- Beat yargısını **algılanan** zamana karşı ver; ham ızgaraya karşı değil.
- Sol/sağ ve aynalamayı merkezî transformla çöz; kurallara dallanma koyma.
- Hata kodlarını UI metnine gömme; kural setini versiyonla.
- Replay fixture'ı olmayan adım eklenmez.
- Fixture, sınadığı toleranstan büyük olmalı; referans çekimlerine kapanış payı bırak.
- Ham videoyu varsayılan yükleme; gerçek-zamanlı kodu buluta bağlama.
- Ölçemediğin şeyi kesin sunma ("groove", "musicality", "seviye").
- Önce beş çok güvenilir hata, sonra kapsam.

## 24. Tamamlanma kriterleri

Standart §1: *"bitti" = kullanıcı indirir, onboarding'den geçer, **kütüphanenin TAMAMI gezilebilir**, kurs seçer, sesli koçluk alır, ilerlemesini görür, abonelik çalışır, çökmez, offline çalışır.*

### 24.0 Platform katmanı (bir kez, dalgadan bağımsız)

- [ ] IA çatısı: Ana · **Kütüphane (~30 stil sayfası, açılmamışlar "yakında")** · İlerlemede · Profil
- [ ] Kütüphanede arama + filtre (seviye/süre/ekipman) + "tüm kurslar" dizini
- [ ] 2-tık kuralı: ana sayfadan aktif kursa ≤2 dokunuş, kütüphaneden kursa ≤3
- [ ] Her stil sayfasında **"neler ölçülür / ölçülmez" kutusu** + köken-atıf kutusu + hukuk bayrağı (🟢/🟡/🔴)
- [ ] Ortak araçlar: metronom/beat kütüphanesi · **ayna-modu** · tempo yavaşlatıcı (kendi beat'imizde)
- [ ] Paywall (assessment-kapılı) · offline · profil+hesap silme · ilerleme grafikleri

### 24.1 Dalga başına (her stil için aynı çıta)

- [ ] Stil sayfası + kurs listesi (Temeller · Kombolar · Rutinler)
- [ ] Adım sayısı **vokabüler-uyarlamalı** (C-021): stilin gerçek çekirdek vokabüleri neyse o — sayı tutturmak için isim çeşitliliği adım çeşitliliği sayılmaz (C-037, C-039)
- [ ] Her adım: ≥3 **bağımsız** eğitmen konsensüsü + fixture (≥1 doğru + ≥2 türetilmiş hatalı)
- [ ] Tier C adım yok; ölçülemeyenler **demo-only** ve nedeni yazılı
- [ ] Beat anotasyonu (≥16 vuruş, hüküm ≥ usable) + stil-tipik BPM aralığı
- [ ] Hukuk bayrağı atanmış; 🔴 içerik yok

### 24.2 Motor (W1 öncesi)

- [ ] Android/iOS tam vücut takip + kamera sihirbazı + vücut kalibrasyonu
- [ ] **Ses gecikmesi kalibrasyonu** (route başına, BT dahil) ve doğrulanmış telafi
- [ ] **Skor kalibrasyonu** gerçek fixture'larla (C-012 — kalibrasyonsuz skor GÖSTERİLMEZ, aile kuralı M-F-04)
- [ ] En az 10 güvenilir hata kodu (W1 stillerine yayılmış)
- [ ] En az 10 güvenilir hata kodu
- [ ] Ayna modu doğru yön eşlemesiyle
- [ ] Canlı tek sesli düzeltme + sayım sırasında sessizlik
- [ ] Seans özeti + bileşen skorları + ilerleme geçmişi (yerel)
- [ ] Metronom + royalty-free beat seti (lisansı kurucu-onaylı satın alınmış)
- [ ] Kullanıcının kendi yerel müziğiyle çalışma
- [ ] İnternetsiz pratik
- [ ] Ham video gizliliği + store beyanı ↔ kod eşleşmesi
- [ ] Replay testleri + native↔Dart golden testleri yeşil
- [ ] Skor kalibrasyonu gerçek fixture'larla yapılmış (§12.4)
- [ ] Uzman doğrulaması (2 eğitmen)
- [ ] Performans/ısı ölçümü (20-40 dk seans, cihaz matrisi)
- [ ] Abonelik öncesi çalışan ücretsiz çekirdek deneyim

## 25. Uzun vadeli vizyon

Stil-bağımsız müfredat + skorlama motoru üzerinden yeni stiller **içerik paketi** olarak eklenir: Line Dance/Country (V2 birinci aday) · Cha-Cha/Latin Solo · Afrobeats · Dancehall · halk dansları (kültürel danışmanla) · bölgesel sosyal danslar.

Temel vizyon:
> Evde tek başına dans öğrenmeyi, "videoyu taklit edip umut etmek" olmaktan çıkarıp ölçülebilir, açıklanabilir ve güvenilir bir öğrenme sürecine dönüştürmek — karşında bir eğitmen varmış gibi.

---

## 26. Karar kaydı

| # | Karar | Statü |
|---|---|---|
| K1 | ~~V1 = 2 stil~~ → **Kapsam ~30 stil, 5 dalga; W1 = 5 stil** | **Kurucu onaylı** (M-F-18, blueprint) — §6 |
| K9 | **Perküsif onset skorlaması** (tap/flamenco/Irish hard-shoe): Ostinato onset motoru + beat-grid, yeni modül DEĞİL | Blueprint kararı — §6.3, W3 |
| K10 | Ölçülemeyen hareket **elenmez, demo-only işaretlenir** ve nedeni kullanıcıya söylenir | Oturum kararı — §22 |
| K2 | Native/Dart sınırı; `motion_core` normatif referans | Oturum kararı (§8) |
| K3 | Beat kaynağı soyut; V1 metronom + bilinen-BPM royalty-free | Oturum kararı (§9.1) |
| K4 | Route-başına ses gecikmesi kalibrasyonu zorunlu | Oturum kararı (§9.2) |
| K5 | Hibrit tolerans pencereleri; NMA varsayılan UYGULANMAZ | Oturum kararı (§9.3) |
| K6 | Ayna modu varsayılan, merkezî çözüm | Oturum kararı (§14) |
| K7 | Müzik telifi kırmızı çizgileri; Spotify/MusicKit V1'de YOK | Oturum kararı (§16) |
| K8 | Skor mutlak kalibrasyonu G4'e açık; kalibrasyonsuz skor gösterilmez | Oturum kararı (§12.4) |

## 27. Kurucu kapıları

**✅ Kapanan (kurucu kararıyla):**
- ~~**Planın tamamı** (M-009/C-001)~~ → **ONAYLANDI** 2026-07-29, kapsam blueprint'le (M-F-18). Brief süpersede edildi.
- ~~V1 stil seçimi~~ → blueprint dalga tablosu (§6.1).
- ~~Beat kütüphanesi satın alımı~~ → **$0 varsayılan** (metronom + kullanıcı müziği + ücretsiz CC + künye). Ücretli kütüphane cila, W1 öncesi tek harcama onayı (C-018).
- ~~Eğitmen anlaşması~~ → **gerekmez** (kamu-video konsensüsü, M-F-13/C-017).
- ~~Cihaz benchmark'ı erken faz blokajı~~ → **G8'e taşındı**, erken fazlar beklemez (M-F-16).

**⏳ Açık (manuel-sona listesi, akışı durdurmaz):**
1. Dans eğitmeni **doğrulama turları** — stil-ailesi başına, ship öncesi tek seferlik kural kontrolü.
2. Royalty-free beat lisans satın alımı — W1 öncesi tek harcama onayı.
3. **Hula ortaklık kararı** — kumu-hula/hālau ortaklığı isterseniz kapsam açılır.
4. **Duyusal-kova store-policy onayı** — Twerk/Reggaeton kovası, W4 öncesi.
5. Cihaz-benchmark (G8) · nihai fiyat (§21) · IP/eğlence hukuku görüşü · submission.
6. **Domain** — Choreia taraması hiç yapılmadı (M-006).
