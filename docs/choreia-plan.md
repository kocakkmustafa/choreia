# CHOREIA — KAMERA TABANLI DANS ÖĞRETİMİ VE BEAT-SENKRON DEĞERLENDİRME
## Claude Code için Ana Proje Tanımı

**Tarih:** 2026-07-26 · **Statü:** 🟡 **ONAY BEKLİYOR (kurucu kapısı — M-009/C-001)**
**Hiyerarşi:** `00-AILE-MIMARISI.md` > `20-URETIM-SURECI.md` > `10-ARAC-KATALOGU.md` > `choreia-roadmap.md` > **bu dosya** > ~~`choreia-brief.md`~~ (bu plan onaylandığında süpersede edilir).
**Araştırma dayanağı:** `docs/research/R1-stil-katalogu.md` · `R2-rakip-dogrulama.md` · `R3-muzik-lisans.md` · `R4-senkron-ve-veri.md` (hepsi 2026-07-26, URL'li).

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

## 6. V1 stil seçimi — **KARAR K1**

Aday 12 stil `R1-stil-katalogu.md`'de 7 kriterle puanlandı (solo-yapılabilirlik, adım vokabüleri, sayım sistemi, hata taksonomisi, telif temizliği, pazar hacmi, CV-ölçülebilirlik).

### 6.1 Seçim

> **V1 = Hip-Hop Foundations (32/35) + Salsa Shines (31/35).**

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

### 6.2 Elenenler ve gerekçeleri (kayda geçer)

| Stil | Neden elendi |
|---|---|
| **K-pop / Jazz-Funk** | Telif 1/5. Piyasadaki dersler başlangıçta bile spesifik şarkı koreografisi öğretiyor + Kore'de aktif ajans/ihbar kültürü. Ürünün kırmızı çizgisiyle doğrudan çakışıyor. **Toplam puanı yüksek olsa da alınamaz.** |
| **Breaking Toprock** | Dönüş, pedagojinin özü — edge-case değil. Tek kameranın en zayıf olduğu yer. |
| **House Dance** | "Counts değil feeling" öğretiliyor. Zamanlama ölçen ürünle yapısal uyumsuz; ölçmek stile saygısızlık olur. |
| **Belly Dance** (19/35) | En iyi durağan-oran profili ama CV riski en yüksek: stilin özü shimmy/mikro-pelvis rotasyonu — landmark çözünürlüğünün altında. |
| **Line Dance / Country Two-Step** (30/35) | **Elenmedi, ertelendi.** Telif en açık, CV profili en güvenilir. V2'nin ilk adayı; V1'e girmemesinin tek sebebi pazar aspirasyonunun düşüklüğü. |
| **Latin Solo / Cha-Cha** (31/35) | Salsa Shines'a eşit puan; "iki Latin stili birden olmasın" çeşitlilik tercihiyle V2'ye bırakıldı. |
| Afrobeats / Dancehall | Vokabüler kodifikasyonu zayıf, 8-count geleneği doğrulanamadı. V2 araştırması. |

**Kurucu notu:** Bu seçim oturumun yetkisindedir (kickoff promptu: "V1 stil seçimi DAHİL"). Ancak planın tamamı gibi bu bölüm de onaya tabidir; kurucu farklı bir çift isterse müfredat mimarisi değişmez, yalnız içerik paketi değişir — maliyeti G6'ya sınırlıdır.

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

## 22. V1 dışı

Partner dansı · çoklu kişi · yerde çalışma/akrobasi · sosyal ağ/feed · canlı ders · yarışma puanı iddiası · gerçek-zamanlı LLM · avatar · çoklu kamera · uygulama içi lisanslı müzik kataloğu · Spotify/Apple Music entegrasyonu · isimli sanatçı koreografisi · çocuk modu · koç pazaryeri · medikal/tedavi iddiası.

## 23. Claude Code için kurallar

- V1'i seçilen iki stilin dışına genişletme.
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

## 24. V1 tamamlanma kriterleri

- [ ] Android/iOS tam vücut takip + kamera kurulum sihirbazı + vücut kalibrasyonu
- [ ] **Ses gecikmesi kalibrasyonu** (route başına, BT dahil) ve doğrulanmış telafi
- [ ] 2 stil × 4 seviye müfredat, versiyonlu config'te
- [ ] Stil başına ≥8 adım + ≥4 kombo, her biri fixture'lı
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
| K1 | V1 stilleri: **Hip-Hop Foundations + Salsa Shines** | Oturum kararı (§6) |
| K2 | Native/Dart sınırı; `motion_core` normatif referans | Oturum kararı (§8) |
| K3 | Beat kaynağı soyut; V1 metronom + bilinen-BPM royalty-free | Oturum kararı (§9.1) |
| K4 | Route-başına ses gecikmesi kalibrasyonu zorunlu | Oturum kararı (§9.2) |
| K5 | Hibrit tolerans pencereleri; NMA varsayılan UYGULANMAZ | Oturum kararı (§9.3) |
| K6 | Ayna modu varsayılan, merkezî çözüm | Oturum kararı (§14) |
| K7 | Müzik telifi kırmızı çizgileri; Spotify/MusicKit V1'de YOK | Oturum kararı (§16) |
| K8 | Skor mutlak kalibrasyonu G4'e açık; kalibrasyonsuz skor gösterilmez | Oturum kararı (§12.4) |

## 27. Kurucu onayı bekleyenler

1. **Bu planın tamamı** (M-009/C-001 kapısı) — onaysız koda geçilmez.
2. **V1 stil çifti** (§6) — farklı bir çift isterseniz mimari değişmez, yalnız içerik paketi.
3. **Nihai fiyat** (§21).
4. **IP/eğlence hukuku görüşü** — lansman öncesi (referans kaynağı kararı zaten alındı, C-017).
5. **Domain** — Choreia taraması hiç yapılmadı (M-006).

**Kapanan onay kalemleri (kurucu kararıyla, 2026-07-26):**
- ~~Beat kütüphanesi satın alımı~~ → **$0 varsayılan** (metronom + kullanıcı müziği + ücretsiz CC + künye ekranı). Ücretli kütüphane bloke edici değil, cila — G6'ya bırakıldı (C-018).
- ~~Eğitmen anlaşması~~ → **gerekmez.** Referans kamuya açık eğitmen videolarından çıkarılır; ship öncesi tek seferlik kural kontrolü yeter (§11, C-017).
