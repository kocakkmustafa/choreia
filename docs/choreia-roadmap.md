# Choreia — Ürün Yol Haritası (G-1→G10)

**Tarih:** 2026-07-26 · **Statü:** Kurucu-onaylı çerçeve; oturumlar bu haritayı işler, sapmalar DEFTER'e.
**Hiyerarşi:** `00-AILE-MIMARISI.md` > `20-URETIM-SURECI.md` > `10-ARAC-KATALOGU.md` > bu dosya > (yazılınca) `choreia-plan.md` > `choreia-brief.md`.
**Ürün dili: İNGİLİZCE.** Aile sırası **5**. ⚠️ TEK FARK: **tam ürün planı YOK (M-009/C-001, P0)** — bu haritada G-1 fazı var: önce plan.

> ⚡ **REVİZYON 2026-07-26 (kurucu direktifi — KURUCUSUZ VERİ FABRİKASI + GENİŞ KÜTÜPHANE, M-F-13..16):** Bu haritadaki "kurucu çekimi / fixture çekim listesi kurucuya" varsayımları KALDIRILDI — kurucu çekim YAPMAZ. Birincil veri = kamu-video hasadı + sentetik + gerekirse ücretli klip (katalog §6.2); doğrulama = §6.3 merdiveni; öğretim görselleri = §6.4 katmanlı AI-eğitmen hattı (T1 = iskelet-sürümlü uygulama-içi avatar, $0 ve form-garantili). Kurucudan yalnız cihaz-benchmark'ı + onay/kapı kararları beklenir. **Geniş kütüphane:** Hip-Hop+Salsa launch, House/Afrobeats hemen ardından hasat, Bachata ek tarama, K-Pop ajans içeriği yüksek-dikkat — 12-stil kataloğu hasat hedefi; referans koreografi çekimi YOK (kamu-video konsensüsü, M-C-01); yarım-tempo öğretim videoları doğal slow-mo kaynağı. Sorularını bu çerçevede kendin karara bağla — kurucuya soru YOK.

## 1. Kimlik ve Kuzey Yıldızı

**Choreia: Learn to Dance** — global dansların temel adım ve tekniklerini, tam-vücut kamera takibi ve **dans eğitmeni yanındaymış gibi sesli yönlendirmeyle** öğreten koç: adım öğret → dene → beat'e göre ölç → tek düzeltme → tekrar.
**Kuzey Yıldızı:** ilk kombosunu beat-uyumlu tamamlayan kullanıcı oranı + haftalık pratik dönüşü. İkincil: geçerli-skor oranı, D7/D30.
**Fark (kanıtlı):** gerçek-zamanlı on-device pose skorlama + sesli koçluk BİRLEŞİMİ dans pazarında YOK — STEEZY video+ayna (feedback yok), Everdance feedback'i insan-async, Just Dance Camera Controller ML skorluyor ama konsol+sessiz+oyun.

## 2. Konumlandırma ve rakipler

| Rakip | Ne yapıyor | Boşluk |
|---|---|---|
| STEEZY (~$99-149/yıl) | 750+ ders videosu, webcam ayna | SKORLAMA/FEEDBACK YOK |
| Everdance | Dans dersi + insan eğitmen video-inceleme | Async insan; gerçek-zamanlı değil, ölçeklenmez |
| Just Dance (+Camera Controller 2025-26) | ML hareket skorlama (konsol) | Oyun; öğretim/sesli koçluk yok; mobil-önü değil |
| DanceFitMe & benzeri | Takip-et kardiyo | CV yok |
| Apple Fitness+/Peloton dance | Video içerik | Form feedback yok |
**Konumlandırma (EN):** *"A dance teacher in your pocket — learn real steps with live feedback on your timing and moves, to any beat."*

## 3. Bağlayıcı teknik kararlar (plan yazımına girdi)

- **Skorlama (katalog §9):** HAM koordinat DTW YASAK — önce normalizasyon (kemik-boyu/gövde ölçeği veya eklem açıları; JPSS/JASS formülleri), sonra pencereli/bantlı DTW; anomaly-aware DTW (QAQA) algoritmik referans. Native (Kotlin/Swift) in-house implementasyon — hazır repo yok (hepsi araştırma-sınıfı).
- **Beat mimarisi (katalog §4):** V1 = dahili metronom + BPM'i bilinen royalty-free beat kütüphanesi (sıfır tespit + sıfır telif riski). V1.5 = kullanıcının kendi müziğinde TEK-SEFERLİK offline BPM/beat-grid analizi + önbellek (canlı takip DEĞİL). Canlı tespit şartsa Superpowered (ücretli, kurucu onayı). ❌ aubio/TarsosDSP/Essentia (GPL/AGPL).
- **Zamanlama metriği:** beat-hizalama + faz-süresi (JabLab D2 dersi) — kare-arası piksel hızı değil. Skor pencereleri beat-grid'e kilitlenir.
- **Referans hattı (M-C-01, katalog §6.0):** ≥3 (tercihen 6+) **bağımsız kamu eğitmen videosu** → landmark çıkarımı → kalite kapıları (aynalama konsensüsü · kamera açısı · plan/kesme · `StructuralValidator`) → `ReferenceBuilder` (medoid zaman tabanı + dairesel ortalama) → `CanonicalReference` + **eğitmen-varyansından türetilmiş tolerans** → adım/kombo state-machine + DTW şablonu çifti. **Kendi çekimimiz YOK.** Beat anotasyonu videodan gelmez → elle anotasyon akışı (C-019e).
- **Telif kırmızı çizgileri (katalog §9):** uygulama-içi lisanslı müzik kataloğu YOK; kullanıcı müziği yalnız yerel çalma; "learn [Artist]'s official choreography" PAZARLANMAZ — jenerik adım müfredatı (salsa temel adımı, two-step, body roll...) + kendi orijinal kombolarımız. Sosyal/halk dansı adımları telif-dışı; orijinal dizilimler korunur — stil kataloğu plan yazımında hukuk-süzgeçli.
- Pose: MediaPipe full; hızlı hareket fps/blur profili V0'da (JabLab bulgularını devral). AIST++ (CC BY 4.0) = fixture + beat-senkron test altyapısının bel kemiği.

## 4. Faz planı

### G-1 — TAM ÜRÜN PLANI (M-009 — P0, HER ŞEYDEN ÖNCE)
Diğer 4 planın şablonunda (bölüm yapısı: özet→konum→hedef kullanıcı→döngü→V1 kapsam→teknik mimari→state-machine'ler→hata/geri bildirim→skor→müfredat→veri modeli→riskler→gizlilik→test→başarı ölçütleri→V1-dışı→Claude kuralları→tamamlanma kriterleri→vizyon) `choreia-plan.md` yazılır:
- Stil kataloğu araştırması + **V1 stil seçimi (2 stil önerisi: gerekçeli — ör. hip-hop temelleri + salsa solo temelleri; kriter: solo-yapılabilirlik, adım-vokabüler netliği, pazar hacmi, telif temizliği)**.
- Müfredat modeli: stil→seviye→ders→adım/kombo grafı; adım state-machine yaklaşımı; beat-hizalı skorlama tanımı.
- V1-dışı: partner dansı/çoklu kişi, sosyal ağ, canlı ders, yarışma-puanı iddiası, gerçek-zamanlı LLM (brief + aile standardı).
**Kapı: plan kurucu onayına gider; onaysız koda geçilmez** (brief süpersede edilir, C-001 kapanır).

### G0 — Derin araştırma & bilgi kütüphanesi
1. Rakip elle-doğrulama: STEEZY/everdance/Just Dance Now güncel fiyat+özellik store taraması; TikTok-tutorial ekosistem taraması (organik kanal fırsatı).
2. Seçilen 2 stilin pedagoji kütüphanesi: adım envanteri, sayım (count) sistemleri, yaygın hata taksonomisi, eğitmen müfredat yapıları — ORİJİNAL sentez.
3. AIST++ indirme + lisans dosyası teyidi (Google türevi CC BY 4.0 artefaktı — kaynak AIST videolarıyla KARIŞTIRMA); FineDance/PhantomDance LICENSE kontrol.
4. Royalty-free beat kütüphanesi tedarik araştırması (lisans + maliyet listesi kurucuya).

### G1 — V0 fizibilite kapısı
1. **Beat-senkron zinciri ölçümü:** bilinen-BPM parçada metronom/beat-grid ↔ pose timestamp hizalama gecikmesi; ses çıkış gecikmesi (BT kulaklık senaryosu dahil!) kalibrasyonu tasarımı.
2. **Hızlı hareket profili:** temel adımlar + hızlı kombolarda fps/blur/landmark güveni (JabLab D2 raporu varsa devral, dans-özgü ek çekimler).
3. **Offline BPM analizi doğruluğu:** aday yöntemin (kendi onset+otokorelasyon implementasyonu vb. — GPL'siz) 20-30 parçalık test setinde doğruluğu.
4. **Stil-başına maliyet analizi:** 1 stilin tam müfredatını (adım+referans çekim+kural) üretme eforu ölçümü → 2-stil V1 bütçesi gerçekçi mi kararı.
**Kapı çıktısı (kurucuya):** senkron gecikme raporu + fps profili + BPM doğruluk + içerik-maliyet tablosu.

### G2 — PRD + teknik tasarım
Akışlar (onboarding→kalibrasyon→stil/ders seçimi→adım öğretimi (yavaş, sayımlı)→deneme→beat'li deneme→skor+tek düzeltme→kombo→seans özeti→ilerleme), veri modeli (aile deseninden: StyleTrack, Lesson, StepDefinition, ComboDefinition, ReferenceSequence, Attempt, TimingMetric, DetectedIssue...), referans-koreografi üretim hattı ADR'i, ses-gecikme kalibrasyon ADR'i.

### G3 — Veri & fixture kütüphanesi
AIST++ (CC-BY anotasyon) doğrulama bel kemiği + §6.3 merdiveni; ❌ MPG setleri yazılı izinsiz girmez. Referanslar **kamu-video hasadından** konsensüsle üretilir (≥3 eğitmen/adım), provenance JSON zorunlu. Öğrenci-hata fixture'ları **çekilmez, türetilir**: kanonik referansın kontrollü bozulmasıyla (geç kalma, ayna-yanlışı, eksik adım, ağırlık aktarılmaması) — hatanın büyüklüğünü biz koyduğumuz için etiket bedava. Replay harness motion-core'dan pinli.

### G4 — Motor inşası
Normalizasyon + JPSS/JASS açı-skoru → adım state-machine'leri → beat-grid motoru (metronom + önbellekli grid) → DTW hizalayıcı (pencereli, beat-kilitli) → kombo değerlendirici → tek-düzeltme önceliklendirici (zamanlama > sıra > form) → skor bileşenleri (timing, step accuracy, flow/consistency, tracking confidence).
**Kapı:** AIST++ ve kendi fixture'larında replay yeşil; skorun vücut-tipi değişmezliği testi (farklı oranlarla aynı doğru hareket ≈ aynı skor).

### G5 — İskelet uygulama (alpha, İngilizce)
Akışlar cilasız: ders oynatıcı (referans video + sayım), canlı deneme (overlay + beat göstergesi + sesli sayım/düzeltme), skor ekranı, ilerleme. Ayna-modu (ekran karşında — dansta kritik) doğru el/yön eşlemesi. Impeller benchmark + `mobile-runtime-tester` sweep.

### G6 — İçerik üretimi
2 stilin müfredat config'leri + referans çekim prodüksiyonu + royalty-free beat seti lisanslı tedarik (harcama onayı) · sesli koç replikleri (EN; sayım-tabanlı: "5-6-7-8", "on the beat", tek düzeltme; ~300-500 satır) → aile voice-pack hattı · kutlama/başarı anları (`game-design-architect` + `motion-interaction-designer`). Dans eğitmeni doğrulaması manuel listeye.

### G7 — UI giydirme (Claude Design)
"Stüdyo + sahne" estetiği: canlı deneme ekranı + skor anı = vitrin; enerjik ama okunabilir. Token + polish turu; dark/light.

### G8 — Sertleştirme
Uzun seans termal/pil (20-40dk) · ses-gecikme kalibrasyonunun cihaz matrisinde doğrulanması (BT kulaklık!) · a11y (sesli sayım + reduce-motion) · analytics (geçerli-skor oranı, beat-uyum gelişimi) · offline (metronom+indirilen dersler).

### G9 — Monetizasyon + uyum
Paywall: ilk ders + ilk skorlu deneme ücretsiz (assessment-kapılı desen) → stil kütüphanesi + ilerleme abonelik. Koridor katalog §8 (STEEZY $99-149/yıl referans; platform-fiyat ayrışması notu) → öneri → kurucu. IAP sandbox + Opus. Uyum: privacy + store-policy; müzik-telif beyan netliği (kullanıcı müziği yalnız yerel çalınır); koreografi-adlandırma süzgeci.

### G10 — Pazarlama & lansman
ASO: "learn to dance, dance tutorial, salsa/hip hop basics" seti; ekran görüntüsü anlatısı: adım öğren→beat'le dene→skor→kombo. Organik kanal: kısa-video (TikTok/Reels) doğal uyum — `content-video-producer` + `build-in-public-storyteller`; "AI scores your dance" demo klipleri (izinli). Submission kurucu.

## 5. Riskler / DEFTER tohumları
C-001 (mevcut): tam plan yok (G-1 kapatır). Yeni: C-002 ses-gecikme kalibrasyonu (BT kulaklık değişkenliği) · C-003 stil-içerik maliyeti (Ostinato dersi: çalgı-başına-motor ≈ stil-başına-müfredat) · C-004 telif dili disiplini · C-005 ayna/yön eşleme hataları · C-006 hızlı hareket blur (D2 devralımı).

## 6. Manuel / kurucu görevleri
~~Plan onayı~~ ✅ (M-F-02) · ~~referans koreografi çekimleri~~ **KALDIRILDI** (kurucu çekim yapmaz — kamu-video konsensüsü, M-C-01/M-F-13) · ~~beat lisans satın alımı~~ → müzik $0 varsayılan, ücretli kütüphane G6'da opsiyonel (C-018) · dans eğitmeni **doğrulaması** (çekim değil, ship öncesi tek seferlik kural kontrolü) · voice-pack harcaması · fiyat onayı · submission · domain (M-006 taramasında Choreia yok) · **cihaz benchmark'ı** (fps + 20-40 dk termal) · C-007 Dance Buddy elle incelemesi.

## 7. Oturum örgütlenmesi
Fable/high (plan yazımı ailenin en geniş sentezi — Workflow fan-out'la tazele, planı ana oturum yazsın); `motion-cv-engineer` + `game-design-architect` + `legal-contracts-advisor` (telif okuması); fan-out sonnet; IAP Opus; /loop. Başlangıç promptu: vault `🚀 Başlangıç Promptu — Choreia`.
