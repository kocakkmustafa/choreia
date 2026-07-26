# R4 — Müzik-Hareket Senkron Bilimi + Ses Gecikme Kalibrasyonu + Dans Veri Setleri Lisansları

**Tarih:** 2026-07-26
**Amaç:** Choreia'nın "kullanıcının hareketi müziğin beat'ine göre zamanlaman geç/erken" değerlendirmesi için (1) bilimsel eşik referansları, (2) mobil ses gecikmesi mühendislik gerçeği, (3) dans veri seti lisans durumu.
**Yöntem:** Yalnızca web araştırması (WebSearch/WebFetch). Kod tabanı incelenmedi. Her sayısal eşik kaynaklıdır; kaynaksız/zayıf kaynaklı iddialar **DOĞRULANMADI** olarak işaretlenmiştir.
**Kaynak güven katmanları:** 🟢 birincil/resmî (akademik makale, resmî platform dokümanı, GitHub LICENSE) · 🟡 ikincil/endüstri (mühendislik firması ölçümü, geliştirici forumu, community wiki) · 🔴 zayıf/doğrulanamamış (tek kaynaklı anekdot, dolaylı arama özeti).

---

## A) Sensorimotor Senkronizasyon Bilimi

### A1. Negative Mean Asynchrony (NMA) — insan beat'ten ne kadar önce vurur?

İnsanlar bir metronom/beat'e parmakla vurduğunda (senkronizasyon "tapping" görevi), vuruş sistematik olarak beat'ten **önce** gelir — buna "negative mean asynchrony" (NMA) denir.

- **Klasik bulgu:** NMA tipik olarak **birkaç on milisaniye** (few tens of ms) mertebesindedir; literatürde en sık atıfta bulunulan aralık **~20–50 ms**, tempo/efektöre bağlı olarak **~20–100 ms**'ye kadar genişleyebilir. 🟢 Kaynak: Repp, B.H. (2005) "Sensorimotor synchronization: A review of the tapping literature," *Psychonomic Bulletin & Review* 12(6):969-992 (DOI 10.3758/BF03206433) — alan için standart referans inceleme; Repp & Su (2013) takip incelemesi bu bulguyu doğruluyor. [springer link](https://link.springer.com/article/10.3758/BF03206433) · [PubMed](https://pubmed.ncbi.nlm.nih.gov/16615317/)
- **Tempo bağımlılığı:** NMA büyüklüğü tempoyla değişiyor — bir çalışmada 1000 ms inter-onset-interval (IOI, ~60 BPM) için NMA ~**40 ms** ölçülmüş; tempo yavaşladıkça (IOI uzadıkça) NMA küçülme eğiliminde. 🟡 Kaynak: sensorimotor synchronization literatürü özet taraması (Scientific Reports/PMC makaleleri, tekil çalışma numarası doğrudan doğrulanamadı — **KISMEN DOĞRULANMADI**, tek bir birincil makaleye pinlenemedi).
- **Geçerli senkronizasyon aralığı:** Nörotipik yetişkinler ~**200–1800 ms** IOI aralığında (yani ~33–300 BPM) doğru senkronize hareket üretebiliyor; bu aralığın dışında (çok hızlı/çok yavaş) senkronizasyon bozuluyor. 🟢 Kaynak: Repp (2005) inceleme sentezi.
- **Teorik açıklama:** Paillard–Fraisse hipotezi — beyin işitsel ve dokunsal/motor bilgiyi karşılaştırırken bir "anticipatory" (öngörücü) model kullanıyor, bu da sistematik erken-vuruşa yol açıyor. Bu, kullanıcı hatası değil, **insan motor sisteminin normal davranışı**.

### A2. "Beat üstünde" tolerans penceresi — ritim oyunu/müzik eğitimi referansları

Hazır bir "dans için doğru pencere" standardı akademik literatürde yok; ama ritim oyunu endüstrisi onlarca yıldır bu problemi çözüyor ve pencere değerleri **halka açık, resmi**:

| Kaynak | Pencere adı | Değer (ms, ±) | Kaynak türü |
|---|---|---|---|
| **osu!** (OD=Overall Difficulty parametresi) | 300 (Perfect) | `±(80 − 6×OD)` → OD5: ±50 ms, OD10: ±20 ms | 🟢 [osu! resmi wiki](https://github.com/ppy/osu-wiki/blob/master/wiki/Beatmap/Overall_difficulty/en.md) |
| | 100 (Ok) | `±(140 − 8×OD)` → OD5: ±100 ms, OD10: ±60 ms | 🟢 aynı |
| | 50 (Meh) | `±(200 − 10×OD)` → OD5: ±150 ms, OD10: ±100 ms | 🟢 aynı |
| **StepMania/DDR ailesi** | Marvelous | ~16.7–22.5 ms (versiyona göre) | 🟡 StepMania topluluk config değerleri (`TimingWindowSecondsW1` vb., simülatörün kendi resmi ayar dosyası) |
| | Perfect | ~33–45 ms | 🟡 aynı |
| | Great | ~66.7–91.7 ms | 🟡 aynı |
| | Good | ~100–141.7 ms | 🟡 aynı |
| | Boo | ~133–225 ms | 🟡 aynı |
| **Clone Hero** (Guitar Hero klonu) | Kalibrasyon sonrası kabul edilen sapma | Monitör: 0–5 ms · TV: 30–100+ ms | 🟢 [Clone Hero resmi wiki](https://wiki.clonehero.net/books/guides-and-tutorials/page/calibrating-audio-and-video) |
| **Arcaea vs Cytus** (mobil) | En yüksek derece penceresi | Arcaea ~25 ms · Cytus ~70 ms | 🔴 topluluk/oyuncu karşılaştırması — **DOĞRULANMADI** (tek kaynaklı, resmi değil) |

**Çıkarım:** Endüstri, zorluk arttıkça pencereyi ~20 ms'ye kadar daraltıyor (uzman seviye), en gevşek/başlangıç seviyesinde ~100–150 ms civarında tutuyor. Bu, A1'deki NMA aralığıyla (~20–100 ms) dikkat çekici şekilde örtüşüyor — yani oyun tasarımcıları da insan motor sisteminin doğal sınırlarına yakın pencereler seçmiş.

### A3. Amatör vs eğitimli değişkenlik (SD) — yeni başlayana adil pencere ne olmalı?

- **Müzisyenler:** Deneyimli müzisyenlerde asenkroni standart sapması **IOI'nin ~%2'si kadar düşük** olabiliyor (yani 1000ms IOI'de ~20ms SD). Müzisyenler kolej öğrencilerine göre daha küçük asenkroni, daha düşük varyans ve daha yüksek algısal duyarlılık gösteriyor. 🟢 Kaynak: Repp (2005) inceleme sentezi.
- **Dansçılar vs dansçı-olmayanlar (spesifik çalışma):** 41 profesyonel/yarışmacı bale salonu dansçısı ile 41 dansçı-olmayanın karşılaştırıldığı çalışmada, dansçılar tüm uyaran tiplerinde (işitsel/görsel/işitsel-görsel) **daha doğru ve daha kararlı** senkronizasyon gösterdi; 54–300 BPM aralığında dansçı-olmayanların SD'si dansçılardan istatistiksel olarak anlamlı derecede büyüktü (p<0.05). Dansçı grubu için ölçülen SD değerleri: işitsel uyaran **73.72 ± 4.47 ms**, görsel uyaran **114.08 ± 3.34 ms**, işitsel-görsel **69.93 ± 4.47 ms**. 🟢 Kaynak: Miura vd., "Does dance training influence beat sensorimotor synchronization? ... competitive ballroom dancers and nondancers," *Experimental Brain Research* (2018), [DOI 10.1007/s00221-018-5410-4](https://link.springer.com/article/10.1007/s00221-018-5410-4).
- **Çelişen/nüanslı bulgu:** Daha yakın tarihli bir EEG çalışmasında 800ms beat aralığında dansçı vs dansçı-olmayan ortalama asenkroni±SD şöyle: dansçılar **5.07 ± 41.47 ms**, dansçı-olmayanlar **5.93 ± 61.66 ms** — bu çalışmada fark istatistiksel olarak anlamlı bulunmadı (p>0.05). 🟢 Kaynak: PLOS One, "Resonance and beat perception of ballroom dancers: An EEG study" (2024/2025), [PMC11493285](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11493285/).
- **Değerlendirme:** İki çalışma birlikte okunduğunda, eğitilmiş dansçı SD'si kabaca **~40–75 ms**, eğitimsiz/amatör SD'si **~55–115 ms** bandında. Fark bazı koşullarda anlamlı, bazılarında değil — **etkili ama garanti-olmayan bir eğitim etkisi** var.
- ⚠️ **KRİTİK SINIRLAMA — DOĞRULANMADI genişletme:** Yukarıdaki tüm SD sayıları **parmak vuruşu (finger-tapping)** görevlerinden geliyor. Choreia'da ölçülen şey **tüm-vücut hareketi** (pose landmark zamanlaması) — bu, parmak vuruşundan çok daha büyük efektör kütlesi/eylemsizlik nedeniyle **doğal olarak daha değişken** olması beklenir. Tüm-vücut dans hareketi zamanlama SD'sini doğrudan ölçen bir akademik kaynak bu araştırmada bulunamadı — bu spesifik ekstrapolasyon **DOĞRULANMADI** olarak işaretlenmelidir; ürün tasarımı bu farkı hesaba katıp pencereleri parmak-vuruşu SD'lerinden daha geniş tutmalıdır.

### A4. Tempo (BPM) toleransı — pencere göreli mi mutlak mı olmalı?

- **Ölçekli zamanlama (scalar timing / Weber yasası):** Zaman algısı ve üretimindeki değişkenlik, genel olarak zamanlanan aralıkla **orantılı** büyüme eğilimindedir (Weber kesri sabit kalma eğilimi) — yani insanlar mutlak ms değil, **göreli** zamanlama temsili kullanıyor. Ancak bu "skalar özellik" **mükemmel sabit değil**: literatürde Weber kesrinin süreye göre U-şekilli değiştiği ve tam sabit kalmadığı gösterilmiş. 🟢 Kaynak: "Weber's Law and the Scalar Property of Timing" (PMC6826837, 2019); "Variation in the coefficient of variation..." (ScienceDirect, 2021).
- **Pratik kanıt:** Diyadik (eşli) parmak-vuruşu çalışmasında, senkronizasyon performansı **40–160 ms** gecikme koşullarında diğer koşullara göre daha iyi bulunmuş — bu, sabit-olmayan ama sınırlı bir tolerans aralığına işaret ediyor. 🟢 Kaynak: "Effect of time delay on performance and timing control in dyadic rhythm coordination," *Scientific Reports* (2024), [DOI 10.1038/s41598-024-68326-6](https://www.nature.com/articles/s41598-024-68326-6).
- **Ritim oyunu pratiği (A2 ile çapraz kontrol):** osu!'nun OD formülleri **mutlak ms** kullanıyor (BPM'den bağımsız) — yani en yaygın ritim oyunu, göreli değil mutlak pencere tercih ediyor, çünkü motor/algısal hassasiyetin bir alt sınırı var ve bu sınır tempo ile orantılı küçülmüyor (yani 300 BPM'de pencereyi 300 BPM'nin %X'i kadar küçültmek insan için imkânsız hale gelir).
- **Sentez:** Bilim göreli/ölçekli bir bileşene işaret ediyor (Weber yasası), ama saf ölçekli pencere çok hızlı tempoda gerçekçi olmayan derecede dar olur. Endüstri standardı (osu!, DDR) bu yüzden **mutlak ms pencere** kullanıyor. **Öneri: hibrit** — bkz. TASARIMA GİRDİ kutusu.

### A5. İşitsel-görsel senkron algı eşiği — ses-görüntü kayması ne kadarda fark ediliyor?

- **Senkron penceresi (temporal binding window):** İnsanlar ses ve görüntü arasında **~200 ms genişliğinde** bir pencere içindeki asenkroniyi güvenilir şekilde fark edemiyor. Bu pencere **asimetrik**: ses-önce (audio lead) asenkronisi ~**-50 ms**'de fark edilirken, görüntü-önce (video lead) asenkronisi çok daha toleranslı, **+150 ms** ile **+240 ms+** arasında fark ediliyor (uyaran tipine göre değişiyor — konuşma için +258ms, basit çekiç-vurma sahnesi için +188ms). 🟢 Kaynak: "Timing in audiovisual speech perception: A mini review and new psychophysical data," *Attention, Perception, & Psychophysics* (Springer); "Audiovisual simultaneity windows reflect temporal sensory uncertainty," [PubMed 38388825](https://pubmed.ncbi.nlm.nih.gov/38388825/).
- **Yaş/işitme etkisi:** Yaşlı bireylerde ve işitme kaybı olanlarda pencere daha geniş — bir çalışmada ortalama pencere genişliği kontrol grubunda 366 ms iken bazı klinik gruplarda 500 ms'ye çıkmış (%37 daha geniş). 🟢 Kaynak: PMC "Detection and Recognition of Asynchronous Auditory/Visual Speech" (PMC8832148).
- **Choreia'ya anlamı:** Bu, **algısal üst sınır**. Uygulama, telafi edilmemiş gecikmeyi bu pencerenin (~200ms, özellikle ses-gecikme yönünde ~50ms gibi çok daha dar bir eşik) içinde tutamazsa, kullanıcı "bir şeyler yanlış" hissini SKORDAN BAĞIMSIZ olarak fark edecektir — yani B bölümündeki ses gecikme telafisi, A bölümündeki tolerans penceresinden çok daha kritik bir mühendislik gereksinimidir.

---

### 🎯 TASARIMA GİRDİ (A) — Sayısal Öneriler

> **Önerilen tolerans pencereleri (mutlak ms, tek-yönlü ±, whole-body harekete göre parmak-vuruşu SD'lerinden ~1.5–2x genişletilmiş — bkz. A3 sınırlaması):**
> - **Başlangıç (beginner):** **±180–220 ms** — DDR "Good" (100-141ms) ile AV-algı üst sınırının (200ms) arası; amatör SD'nin (~55-115ms parmak-vuruşu) whole-body genişletmesiyle uyumlu.
> - **Orta (intermediate):** **±100–130 ms** — DDR "Great" penceresine (66-91ms) yakın, whole-body payı eklenmiş.
> - **İleri (advanced):** **±60–80 ms** — eğitimli dansçı SD'sinin (~70-75ms parmak-vuruşu, A3) üstünde küçük bir pay; osu! OD5-7 aralığına benzer.
> - **Uzman/mükemmel (opsiyonel üst kademe):** **±40–50 ms** — osu! OD10 (±20-60ms) mertebesinde, yalnızca en iyi kullanıcılar için.
>
> **NMA telafisi (kritik, ayrı madde):** İnsan doğası gereği beat'ten **~20–40 ms önce** hareket eder (A1). Skorlama merkezini tam "0 ms" değil, **~-20 ila -30 ms** offsetine ortalayın (ya da en azından ±20-30ms içindeki erken hareketleri "geç" ile aynı şekilde cezalandırmayın) — aksi halde sistematik olarak normal insanları "hep erken" diye cezalandırırsınız.
>
> **Tempo ölçekleme formülü (hibrit, A4 sentezi):**
> `pencere_ms = clamp(k × beat_interval_ms, min_ms, max_ms)`
> önerilen `k ≈ 0.10–0.15`, `min_ms ≈ 60–80`, `max_ms ≈ 200–220`. Bu, Weber-yasası-uyumlu göreli bileşeni korurken çok hızlı tempoda pencerenin insan-imkansızı seviyede daralmasını engeller.
>
> **Sert üst sınır:** Telafi edilmemiş toplam gecikme + tolerans penceresi toplamı, AV-algı penceresini (~200ms, A5) sistematik olarak aşmamalı — aşarsa kullanıcı oyunu "bozuk" hisseder, skor ne kadar cömert olursa olsun.

---

## B) Mobil Ses Çıkış Gecikmesi (Mühendislik Gerçeği)

### B1. iOS ve Android'de dahili hoparlör ses çıkış gecikmesi

- **iOS:** Roundtrip (gidiş-dönüş) gecikme, konfigürasyona göre **~3–40 ms** arasında değişebiliyor; varsayılan `AVAudioSession` modu geri-besleme azaltma/ön-işleme nedeniyle ek **~30 ms** gecikme ekliyor (bu yüzden minimum gecikme için "measurement" modu öneriliyor). Profesyonel ses uygulamaları için hedef **<10 ms** roundtrip ("doğal" hissedilen eşik). 🟡 Kaynak: [Superpowered Latency Test App](https://superpowered.com/latency) (endüstri ölçüm aracı/firması — iOS/Android'de gerçek roundtrip gecikmeyi mikrofon+hoparlör ile ölçüyor).
- **Android:** Çok daha **cihaz-bağımlı**. Resmi gereksinimler (Android Compatibility Definition Document — CDD, 🟢 [android.googlesource.com](https://android.googlesource.com/platform/compatibility/cdd/+/refs/heads/master/5_multimedia/5_6_audio-latency.md)):
  - **ZORUNLU (MUST):** cold output latency ≤ **500 ms**, input latency ≤ **500 ms**.
  - **ŞİDDETLE TAVSİYE (STRONGLY RECOMMENDED, "low latency" cihazlar için):** cold output ≤ **100 ms**, continuous output ≤ **45 ms**, continuous input ≤ **30 ms**, continuous round-trip ≤ **50 ms**.
  - `AudioTrack.getTimestamp()` / `AAudioStream_getTimestamp()` doğruluğu: zorunlu **±2 ms**, tavsiye edilen **±1 ms**.
  - Gerçek ölçümler (Google'ın kendi WALT aracı, 🟢 [android.googlesource.com/.../walt](https://android.googlesource.com/platform/external/walt/+/HEAD/docs/AudioLatency.md)): Nexus 5 playback 27.6ms, Nexus 5X 14.9ms, Pixel 8.9ms, Nexus 9 9.8ms — ama bunlar **en iyi durum/optimize edilmiş cihazlar**; Google'ın kendi Oboe kütüphanesi teknik notu "çoğu Android uygulaması 100ms'den fazla çıkış gecikmesine ve 200ms'den fazla round-trip gecikmesine sahip" diyor. 🟢 Kaynak: [Google Oboe wiki](https://github.com/google/oboe/wiki/TechNote_BluetoothAudio) / [Superpowered Android Audio Path Latency Explainer](https://superpowered.com/androidaudiopathlatency).
- **Sonuç:** Android'de dahili hoparlör gecikmesi iOS'a göre **çok daha geniş bir dağılıma** sahip (flagship: ~10-30ms optimize edilmiş yolda; bütçe/optimize edilmemiş cihaz: 100-300ms+). Bu, **cihaz bazlı kalibrasyonun Android'de kaçınılmaz** olduğu anlamına gelir.

### B2. Bluetooth kulaklık gecikmesi — codec karşılaştırması

⚠️ **En önemli bulgu: üretici/pazarlama iddiaları ile gerçek ölçüm arasında BÜYÜK fark var.**

| Codec | Üretici/pazarlama iddiası | Gerçek Android ölçümü (SoundGuys, 4 cihaz ortalaması) |
|---|---|---|
| SBC (varsayılan) | ~100–250 ms | **~308 ms** ortalama (varyans ±41.9ms) |
| AAC | ~150–200 ms | **~369 ms** ortalama (en kötü performans; varyans ±45ms, bazı cihazlarda ±90ms) |
| aptX (klasik) | ~100–200 ms | **~316 ms** ortalama (varyans ±25.7ms — SBC'den daha tutarlı ama daha az düşük) |
| aptX Low Latency | ~32–50 ms | ölçülmedi (ayrı test) |
| aptX Adaptive | ~50–80 ms | ölçülmedi |
| LDAC | — | **~324 ms** ortalama (yüksek-kalite 990kbps modunda büyük varyans) |
| LE Audio / LC3 | ~5–15 ms (üretici iddiası) | 🔴 **DOĞRULANMADI** — bağımsız/laboratuvar ölçümü bu araştırmada bulunamadı, yalnızca üretici/pazarlama kaynakları var |

🟡 Kaynak: [SoundGuys "Android's Bluetooth latency needs a serious overhaul"](https://www.soundguys.com/android-bluetooth-latency-22732/) (gerçek cihaz testi) vs. [Feasycom codec karşılaştırma sayfası](https://www.feasycom.com/comparison-of-6-different-bluetooth-audio-codecs-sbc-aac-aptx-ldac-lhdc-lc3/) (üretici-taraflı özet, 🔴 düşük güven).

**Kritik çıkarım:** "Codec X, Yms gecikme destekler" pazarlama iddialarına **güvenmeyin**. Gerçek dünyada Android'de tipik Bluetooth ses gecikmesi **150–370 ms** bandında ölçülmüş — bu, hiçbir sabit-offset varsayımının güvenilir olamayacağı, **kullanıcı-bazlı kalibrasyonun zorunlu** olduğu anlamına gelir.

### B3. Platform API'leri gecikmeyi bildiriyor mu? (KRİTİK SORU)

**Kısa cevap: HAYIR, güvenilir şekilde değil — özellikle Bluetooth üzerinden.**

- **iOS — `AVAudioSession.outputLatency` / `ioBufferDuration`:** Bu API'ler mevcut ve dokümante (🟢 [Apple Developer Docs](https://developer.apple.com/documentation/avfoundation/avaudiosession/1616500-outputlatency)), ama Apple Developer Forums'da doğrulanmış geliştirici raporlarına göre **Bluetooth'ta güvenilir DEĞİL**: "`outputLatency` üzerinden alınan değer, gerçek Bluetooth ses gecikmesinden çok daha küçük" ve gecikme zamanla dinamik değişiyor (**1 dakika içinde 193ms'den 260ms'ye** çıkabiliyor). Resmi bir düzeltme/API yok; geliştiriciler Audio Queue Processing Tap gibi geçici çözümlere başvuruyor. 🟢 Kaynak: [Apple Developer Forums thread 126277](https://developer.apple.com/forums/thread/126277) ("How to get the output latency of Bluetooth audio").
- **Android — `AudioTrack.getTimestamp()` / `AAudio`:** CDD, genel çıkış yolu için ±1-2ms doğruluk gerekliliği koyuyor (B1), ama bu gereksinimlerin Bluetooth A2DP yoluna uygulandığına dair **resmi bir garanti bulunamadı**. Google'ın kendi Oboe kütüphanesi Bluetooth ses teknik notu, timestamp doğruluğundan hiç bahsetmiyor — bunun yerine geliştiricilere "codec'i değiştirmeyi deneyin" veya "Bluetooth A2DP donanım offload'unu kapatın" gibi **deneme-yanılma tavsiyeleri** veriyor, güvenilir bir gecikme-sorgulama API'sine işaret etmiyor. 🟢 Kaynak: [Google Oboe Wiki — TechNote_BluetoothAudio](https://github.com/google/oboe/wiki/TechNote_BluetoothAudio).
- **Bluetooth protokolü seviyesinde bir mekanizma var (AVDTP 1.3 "Delay Reporting"):** Bluetooth cihazları teorik olarak codec gecikmesini karşı tarafa bildirebiliyor, ve Android bunu okuyabiliyor — ama bu (a) hem telefon hem kulaklık firmware'inin desteklemesini gerektiriyor (tutarsız), (b) uygulama-seviyesi `AudioTrack`/`AAudio` timestamp API'siyle **aynı şey değil**. 🔴 Bu alt-detay bir Hacker News yorumundan geliyor, resmi dokümanla teyit edilemedi — **DOĞRULANMADI**.
- **Pratik sonuç:** Choreia hem iOS hem Android'de, Bluetooth çıkışı kullanılıyorsa, **işletim sisteminden gelen gecikme değerine güvenemez**. Kullanıcı kalibrasyonu (B4) tek güvenilir yol.

### B4. Ritim oyunları ses gecikmesini nasıl kalibre ediyor?

Beş farklı oyunun kalibrasyon tasarımı incelendi — hepsi aynı temel deseni paylaşıyor:

1. **osu! "Offset Wizard"** 🟢 [resmi wiki](https://osu.ppy.sh/wiki/en/Client/Options/Offset_Wizard): Ekranda metronom tıklarken dikey çizgiler kaydırılıyor; kullanıcı yukarı/aşağı ok veya fare tekerleğiyle "universal offset" değerini ayarlıyor, çizgi ile ses aynı anda hizalanana kadar. Anlık görsel+işitsel geri bildirim.
2. **Beat Saber** 🟡 [Steam topluluğu + BetterLatencyAdjuster mod](https://github.com/ErisApps/BetterLatencyAdjuster): Yerleşik menüde bir slider; kullanıcı VR başlığı takılıyken, sekip-zıplayan bir top bir çizgiye çarptığında sesi duyana kadar slider'ı ayarlıyor. Topluluk modu, topu titreşen siyah/beyaz kareyle değiştirerek kalibrasyonu kolaylaştırmış (görsel keskinlik daha yüksek).
3. **Clone Hero** 🟢 [resmi wiki](https://wiki.clonehero.net/books/guides-and-tutorials/page/calibrating-audio-and-video): Önce "Get Hardware Latency" ile OS-raporlu gecikmeyi başlangıç noktası olarak alıyor (ama buna "körü körüne güvenme" uyarısı var — B3 ile tutarlı!), sonra kullanıcı bir kalibrasyon aracında tekrar tekrar "strum" (tellere vuruyor), oyun bu denemelerin **ortalamasını** alarak tek bir offset değeri üretiyor ve hem ses hem görüntüye atıyor.
4. **Arcaea / Cytus (mobil dokunmatik ritim oyunları)** 🟡 [Arcaea Wiki — Device Offsets](https://arcaea.fandom.com/wiki/Device_Offsets): Manuel offset slider'ı -2000 ile +2000 ms arası, varsayılan 0. Wiki açıkça "her cihazın kendi ses gecikmesi var, farklı offset gerekir" VE "aynı cihazda bile farklı kullanıcılar reaksiyon-süresi algısı farkı nedeniyle farklı offset isteyebilir" diyor — yani **kişi-bazlı** ince ayar bile öneriliyor.
5. **Rhythm Quest (indie geliştirici devlog'u)** 🟡 [ddrkirbyisq Medium devlog](https://ddrkirbyisq.medium.com/rhythm-quest-devlog-10-latency-calibration-fb6f1a56395c): İki bölümlü tasarım — üst kısımda kullanıcı bir ritme dokunarak kendi girdi gecikmesini/ritmini oluşturuyor; alt kısımda ses-görüntü dengesini ayarlıyor. Tasarımın dayandığı ilke: "insan gözü zamanlama farklarını belirlemede çok keskin" — yani göz ile kulak arasındaki hizalamayı **görsel karşılaştırmayla** kalibre etmek, sayısal bir sayı girmekten daha güvenilir.

**Ortak desen (5 örnekten damıtılmış):**
- OS'ten gelen bir "otomatik" başlangıç değeri varsa kullan (ama B3 nedeniyle özellikle BT'de güvenme).
- **Mutlaka** kullanıcıya perceptüel bir hizalama görevi yaptır (metronom+görsel yanıp-sönme, ya da "bu doğru hissediyor mu" kademeli slider).
- Offset'i **çıkış yoluna göre ayrı ayrı** sakla (kablolu vs BT kulaklık vs hoparlör) — biri diğerinden 100-300ms farklı olabilir (B2).
- Tek denemeye güvenme; **birden fazla deneme ortalaması** al (Clone Hero deseni) gürültüyü azaltmak için.

### B5. Kamera görüntü hattı gecikmesi (frame capture → landmark sonucu)

- **Glass-to-glass (kamera sensöründen ekrana, Android/Pixel 2 ölçümü):** toplam **80 ± 25 ms** (min 57, maks 106 ms), şu şekilde dağılıyor: sensör pozlama 0-33ms, sensörden uygulamaya ~24ms, uygulamadan ekrana (GPU/SurfaceFlinger/VSYNC) ~33ms, ekran taraması 0-16ms. 🟡 Kaynak: [inovex "The Glass-To-Glass Latency on Android"](https://www.inovex.de/de/blog/the-glass-to-glass-latency-on-android/) (bağımsız mühendislik ölçümü, ama cihaz **Pixel 2** — eski; yazar yeni cihazlarda da kontrol ettiğini belirtiyor ama somut sayı vermiyor, **kısmen DOĞRULANMADI** güncel cihazlar için).
- **Kameradan uygulamaya olan kısım** (sensör pozlama + sensörden-uygulamaya, ~24-57ms) Choreia'nın "landmark hesaplamaya başlayabileceğim an" için ilgili kısım — ekrana çizim kısmı (app-to-display, ~33-49ms) landmark hesaplaması için gerekli değil.
- **MediaPipe/BlazePose çıkarım (inference) süresi:** Google Research'ün resmi blog yazısına göre (🟢 [research.google/blog](https://research.google/blog/on-device-real-time-body-pose-tracking-with-mediapipe-blazepose/)): CPU'da Lite model ~25+ FPS (~40ms/kare), Full model ~15+ FPS (~66ms/kare); GPU'da Lite ~50+ FPS (~20ms/kare), Full ~30+ FPS (~33ms/kare). Kesin ms değeri makalede verilmiyor, FPS'den ters hesaplandı.
- ⚠️ **Toplam boru hattı gecikmesi (kamera yakalama + ML çıkarımı) için TEK bir kaynak bulunamadı** — yukarıdaki iki bulgu ayrı ölçümlerden. Bu araştırmanın **kendi kompozit tahmini**: cihaz/model karmaşıklığına göre **~50–150 ms** toplam makul bir aralık, ama bu **doğrudan ölçülmüş bir sayı DEĞİL, iki ayrı kaynağın birleştirilmiş çıkarımıdır** — **DOĞRULANMADI** olarak işaretlenmelidir, üretim öncesi gerçek cihazda ölçülmelidir (ör. yüksek-fps yavaş-çekim kamerayla, glass-to-glass yöntemiyle).
- Referans karşılaştırma noktası (dans-spesifik değil, AR izleme genel): "kamera görüntüsü izleyici tarafından alındığında zaten ~15ms eski, izleyici ~25ms daha ekliyor" → ~40ms motion-to-pose-available. 🟡 Kaynak: [DAQRI Medium "Motion to Photon Latency in Mobile AR and VR"] — analoji olarak verildi, dans-pose-estimation'a doğrudan uygulanabilirliği **DOĞRULANMADI**.

---

### 🎯 TASARIMA GİRDİ (B) — Sayısal Öneriler

> **Kalibrasyon ZORUNLU, tahmine güvenilemez:** Hem iOS hem Android'de, özellikle Bluetooth çıkışında, OS-raporlu gecikme değerleri güvenilmez (B3). Sabit/varsayılan bir gecikme sabiti kullanmayın.
>
> **Önerilen kalibrasyon akışı** (B4'teki 5 örnekten sentezlendi):
> 1. Çıkış yolu tipini tespit et (kablolu/hoparlör vs Bluetooth — `AVAudioSession.currentRoute` / Android `AudioDeviceInfo`).
> 2. Bluetooth ise, kullanıcıyı **mutlaka** kalibrasyon akışından geçir (atlanabilir ama güçlü uyarıyla); kablolu/hoparlörde varsayılan ~0-30ms ile başla ama yine de opsiyonel ince-ayar sun.
> 3. Kalibrasyon UX'i: metronom sesi + senkron yanıp-sönen görsel işaret; kullanıcı offset'i canlı ayarlıyor (osu!/Beat Saber deseni) VEYA birkaç kez "beat'e dokun" yaptırıp ortalama al (Clone Hero deseni). İkisi birlikte en sağlam (Rhythm Quest deseni).
> 4. Sonucu **çıkış-yolu-bazlı** sakla (örn. "bu Bluetooth kulaklık için offset = X ms"), her yeni cihaz/kulaklık bağlandığında tekrar sor.
>
> **Varsayım/güvenlik payı (kalibrasyon öncesi veya atlanırsa):** Bluetooth tespit edilirse ama kalibrasyon yapılmamışsa, **~150–200 ms** tahmini bir ön-telafi uygulayın (0 varsaymaktan çok daha az kötü — B2'deki gerçek-dünya ölçümlerinin merkezine yakın); kablolu/hoparlörde ~0-30ms varsayın.
>
> **Bütçe gerçeği:** Toplam sistem gecikmesi (kamera yakalama + poz çıkarımı + ses çalma ± Bluetooth) cihaza göre **~50ms (en iyi: kablolu/hoparlör + hafif model + amiral gemisi) ile ~400ms+ (en kötü: BT + ağır model + eski cihaz) arasında ~8 kat değişebilir** (B1+B2+B5 toplamı, kompozit tahmin, DOĞRULANMADI ama bileşenleri tek tek kaynaklı). Bu varyans tek başına, sabit bir global gecikme sabitinin neden işe yaramayacağının kanıtı.
>
> **Algısal tavan (A5 ile bağlantı):** Telafi edilmemiş net gecikme ~200ms'yi (ideal olarak ses-gecikme yönünde çok daha az, ~50ms'yi) aşarsa, kullanıcı bunu skor mekaniğinden bağımsız olarak "bozuk" hisseder — kalibrasyon bu yüzden bir "nice-to-have" değil, sert gereksinimdir.

---

## C) Dans Veri Setleri — Lisans Teyidi

### Veri seti detayları (birincil kaynaktan)

#### 1. AIST++ (Google) — anotasyonlar
- **Lisans:** CC BY 4.0 ("The annotations are licensed by Google LLC under CC BY 4.0 license" — bu ifade birden fazla bağımsız arama sonucunda tutarlı şekilde çıktı, ancak doğrudan sayfa taramasıyla (WebFetch, 3 deneme) cümle birebir teyit edilemedi — **kısmen DOĞRULANMADI, kullanmadan önce [factsfigures.html](https://google.github.io/aistplusplus_dataset/factsfigures.html) sayfasını gözle kontrol edin**). Kod/API deposu (`google/aistplusplus_api`) ayrıca **Apache-2.0** rozeti taşıyor (bu kod lisansı, veri lisansı değil).
- **Format:** 🟢 Doğrudan makaleden (AI Choreographer, arXiv 2101.08779) teyit edildi: **60 FPS**; **SMPL formatı** (poz parametreleri + global ölçek + translasyon) + COCO-format 2D/3D keypoint; kamera kalibrasyon parametreleri dahil; **30 dansçı, 9 kamera açısı, 10 dans janrı** (Old School: Break/Pop/Lock/Waack; New School: Middle Hip-hop/LA-style Hip-hop/House/Krump/Street Jazz/Ballet Jazz); 1408 dizi, 5.2 saat.
- **Müzik/beat anotasyonu:** Veri setinde **hazır beat-timestamp anotasyonu YOK** — makale açıkça "müzik beat'leri librosa kullanılarak çıkarılıyor" diyor (yani beat tespiti kullanıcı tarafında audio-processing ile yapılıyor, ground-truth olarak verilmiyor). Bu, fixture altyapısı için önemli: AIST++ üzerinde beat-hizalı test kurmak istiyorsanız **kendi librosa/onset-detection adımınızı** eklemeniz gerekir.
- **Ticari kullanım / shipped model eğitimi:** Anotasyonlar (pose/SMPL) için CC BY 4.0 = evet (atıfla). AMA indirme sayfası açıkça kaynak videoları indirmeden önce AIST Dance DB kullanım şartlarının okunup kabul edilmesini şart koşuyor (#2'ye bakın) — yani orijinal video/ses içeriğine erişim hâlâ AIST'in akademik-only kısıtına tabi olabilir.
- Kaynak: 🟢 [google.github.io/aistplusplus_dataset](https://google.github.io/aistplusplus_dataset/) · [github.com/google/aistplusplus_api](https://github.com/google/aistplusplus_api) · [arXiv 2101.08779](https://arxiv.org/abs/2101.08779)

#### 2. AIST Dance Video Database (kaynak videolar) — AYRI LİSANS
- **Lisans:** AIST'in (Japonya, Ulusal İleri Endüstriyel Bilim ve Teknoloji Enstitüsü) kendi özel şartları — **akademik araştırma DIŞINDA kullanılamaz**.
- **Ticari kullanım:** **HAYIR**, AIST'ten önceden yazılı izin olmadan (`aistdancedb-ml@aist.go.jp` ile iletişim şart).
- **Yeniden dağıtım:** Açıkça yasak ("Unauthorized redistribution of any content of the database is prohibited").
- **Shipped model eğitimi:** **HAYIR**, yazılı ticari izin olmadan.
- 🟢 **BU, BİLİNEN KARIŞTIRMA TUZAĞI:** AIST++ (Google'ın anotasyonları) CC BY 4.0 olsa da, bu anotasyonların türetildiği KAYNAK VİDEOLAR (ve videoların içindeki müzik) hâlâ AIST'in akademik-only lisansına tabi. "AIST++ CC BY, o zaman her şeyi ticari kullanabilirim" demek **YANLIŞ** — video/ses içeriğine dokunuyorsanız hâlâ AIST DB şartları geçerli.
- Kaynak: 🟢 [aistdancedb.ongaaccel.jp/terms_of_use](https://aistdancedb.ongaaccel.jp/terms_of_use/) (birincil, resmi).

#### 3. FineDance
- **Lisans:** Özel/custom akademik lisans. Ticari, pornografik, askeri veya gözetim amaçlı kullanım **açıkça yasak**; ayrıca yazılımı/veriyi bu amaçlarla model/algoritma/sinir-ağı **eğitmek için kullanmak da yasak**.
- **Ticari kullanım / shipped model:** **HAYIR**.
- **Format:** SMPLH, 7.7 saat, müzik özellikleri librosa ile (AIST++ metodolojisini takip ederek) çıkarılmış.
- Kaynak: 🟢 [github.com/li-ronghui/FineDance/LICENSE](https://github.com/li-ronghui/FineDance/blob/main/LICENSE) (birincil).

#### 4. PhantomDance
- **Lisans:** GitHub deposu (`libuyu/PhantomDanceDataset`) **MIT** lisans rozeti taşıyor — MIT ticari kullanıma geniş izin verir.
- ⚠️ **KISMEN DOĞRULANMADI:** Depo koduna MIT uygulanmış olsa da, **gerçek veri dosyalarına erişim e-posta ile talep** gerektiriyor (`research@huiye.tech`, ad/unvan/kurum bilgisi ile). Yazarların e-posta yoluyla dağıttığı gerçek veri için ek/farklı bir kullanım sözleşmesi dayatıp dayatmadığı **halka açık web araştırmasıyla doğrulanamaz** — indirme öncesi yazarlarla teyit edin.
- **Format:** 24-eklemli SMPL-benzeri iskelet, kök pozisyon (3D) + kuaterniyon rotasyonlar (4D), Unity3D koordinatları, JSON @30fps + WAV @16kHz; 260 dans-müzik çifti, 9.5 saat; **motion-capture değil, profesyonel animatörler tarafından elle üretilmiş**.
- Kaynak: 🟡 [github.com/libuyu/PhantomDanceDataset](https://github.com/libuyu/PhantomDanceDataset) (kod lisansı birincil kaynaklı; veri-özel şartlar doğrulanamadı).

#### 5. Motion-X / IDEA-400
- ⚠️ **Kavramsal düzeltme:** Motion-X, çok sayıda alt-kaynaktan (AMASS, GRAB, AIST++'ın kendisi dahil, ve yeni web-video hareketi) oluşan **büyük bir şemsiye veri seti** (15.6M kare, 81.1K dizi, SMPL-X formatı). **IDEA-400, Motion-X'in dans-spesifik bir alt kümesi DEĞİL** — 400 günlük insan eylemini kapsayan, lisans/kalite sorunları nedeniyle NTU-RGBD120'ye alternatif olarak oluşturulmuş genel bir alt küme. Motion-X'in ayrı "AIST" ve "Dance" kategorileri var (Idea400'den farklı).
- **Lisans:** Genel olarak **CC BY-NC-SA** (Attribution-NonCommercial-ShareAlike) altında dağıtılıyor — 🟡 bu karakterizasyon birden fazla bağımsız kaynakta tutarlı, ama README'nin ham lisans metni doğrudan fetch ile teyit edilemedi (ayrı bir PDF'e işaret ediyor) — **kullanmadan önce PDF'i açıp teyit edin**.
- **Önemli katman kuralı:** Alt-veri-setleri (ör. Motion-X'in "AIST" bölümü) için kullanıcıların **orijinal kaynak veri setinin kendi lisansına DA uyması gerekiyor** — yani Motion-X'in AIST bölümünü kullanırsanız hem Motion-X'in NC-SA'sına HEM AIST Dance DB'nin akademik-only kısıtına (madde #2) tabi olursunuz (katmanlı kısıtlama).
- **Ticari kullanım / shipped model:** **HAYIR** (NC-SA açıkça ticari-dışı).
- Kaynak: 🟡 [github.com/IDEA-Research/Motion-X](https://github.com/IDEA-Research/Motion-X) · [arXiv 2307.00818](https://arxiv.org/pdf/2307.00818).

#### 6. Bailando (veri seti olarak)
- ⚠️ **Kavramsal düzeltme:** Bailando (CVPR 2022) kendi orijinal bir veri seti **YAYINLAMIYOR** — mevcut **AIST++'ı** (952 eğitim / 40 değerlendirme dizisi) kullanan bir MODEL/YÖNTEM. Yani "Bailando veri seti"nin lisans durumu = AIST++'ın kendisi (madde #1+#2).
- **Bailando kodu kendi lisansı:** **NTU S-Lab License 1.0** — açıkça **"non-commercial purpose"** ile sınırlı; ticari kullanım/dağıtım için katkıda bulunanlarla (contributors) doğrudan iletişime geçilmesi şart koşuluyor.
- **Ticari kullanım / shipped model:** Bailando kodu için **HAYIR** (özel izin olmadan); altta yatan veri (AIST++) için madde #1+#2'deki katmanlı kısıtlamalar geçerli.
- Kaynak: 🟢 [github.com/lisiyao21/Bailando/LICENSE](https://github.com/lisiyao21/Bailando/blob/main/LICENSE) (birincil).

#### 7. DanceTrack
- ⚠️ **Kavramsal düzeltme (önemli):** DanceTrack, bir **dans hareketi/motion-capture veri seti DEĞİL** — CVPR 2022'de yayınlanan bir **Multi-Object Tracking (MOT) benchmark'ı**. Amaç: aynı-görünümlü (üniform kıyafetli) birden fazla insanı (grup dansçıları) video karesi içinde takip etmek. Veri = video + bounding-box + kimlik anotasyonu; **poz/iskelet/SMPL verisi YOK, müzik/beat anotasyonu YOK**.
- **Lisans:** Anotasyonlar **CC BY 4.0**; video/görsel içerik **yalnızca ticari-olmayan araştırma amaçlı**; kod **MIT**.
- **Ticari kullanım / shipped model:** Karışık — anotasyonlar izin veriyor ama asıl video içeriği izin vermiyor; ayrıca **amaç uyuşmazlığı**: bu veri seti hareket-üretimi/poz-değerlendirme için tasarlanmamış, sadece video-içi takip için.
- **Choreia'ya ilgisi:** muhtemelen **düşük/yanlış eşleşme** — Choreia tek-kullanıcı kamera-tabanlı hareket değerlendirmesi yapıyor (grup video takibi değil); bu veri seti fixture altyapısı için muhtemelen gereksiz, tanımlanan kullanım senaryosuna uymuyor.
- Kaynak: 🟢 [github.com/DanceTrack/DanceTrack/README.md](https://github.com/DanceTrack/DanceTrack/blob/main/README.md) (birincil).

### 📋 Lisans Karar Tablosu

| Veri seti | Lisans (veri) | Ticari kullanım? | Shipped model eğitimi için kullanılabilir mi? | Kaynak güveni |
|---|---|---|---|---|
| **AIST++ (anotasyon)** | CC BY 4.0 | ✅ Evet (atıfla) | ✅ Evet — **ama** kaynak video/ses AIST DB şartına tabi olabilir | 🟡 kısmen doğrulandı |
| **AIST Dance Video DB (kaynak video)** | Özel/akademik-only | ❌ Hayır (yazılı izinsiz) | ❌ Hayır | 🟢 birincil, tam doğrulandı |
| **FineDance** | Özel/non-commercial | ❌ Hayır | ❌ Hayır (model eğitimi de yasak) | 🟢 birincil, tam doğrulandı |
| **PhantomDance** | MIT (kod) | ✅ Kod için evet | ⚠️ Muhtemelen evet ama veri-özel şart **doğrulanamadı** — yazarla teyit şart | 🟡 kısmen doğrulandı |
| **Motion-X (genel)** | CC BY-NC-SA | ❌ Hayır | ❌ Hayır | 🟡 kısmen doğrulandı |
| **Motion-X → "AIST" alt-kümesi** | NC-SA + AIST DB katmanlı | ❌ Hayır (çifte kısıt) | ❌ Hayır | 🟡 |
| **"IDEA-400"** | Motion-X ile aynı (NC-SA) | ❌ Hayır | ❌ Hayır — ayrıca **dans-spesifik değil** (400 günlük eylem) | 🟡 |
| **Bailando (kod)** | NTU S-Lab 1.0 | ❌ Hayır (izinsiz) | ❌ Hayır | 🟢 birincil, tam doğrulandı |
| **Bailando'nun kullandığı veri** | = AIST++ (yukarı bkz.) | (yukarı bkz.) | (yukarı bkz.) | — |
| **DanceTrack (anotasyon)** | CC BY 4.0 | ✅ Evet | ⚠️ Amaç-uyumsuz (MOT verisi, poz/motion değil) | 🟢 birincil |
| **DanceTrack (video)** | Non-commercial research only | ❌ Hayır | ❌ Hayır | 🟢 birincil |

**Genel sonuç:** İncelenen 7 kaynaktan **hiçbiri** kayıtsız-şartsız "ticari shipped-model eğitimi için serbest" değil. En elverişli olan **AIST++'ın Google anotasyonları** (CC BY 4.0) bile kaynak video/ses bağımlılığı nedeniyle dikkatli kullanılmalı. PhantomDance kod-lisansı en gevşek görünüyor (MIT) ama veri-erişim süreci (e-posta ile talep) ek şartlar taşıyabilir ve bu **doğrulanamadı**. Ticari/shipped kullanım için en güvenli yol: (1) yalnızca AIST++ Google-anotasyonlarını (pose/SMPL/kamera) CC BY 4.0 atıfla kullanmak ve kaynak video/sese dokunmamak, VEYA (2) AIST'e doğrudan yazılı ticari izin için başvurmak, VEYA (3) tamamen kendi çekilen/lisanslı fixture verisiyle çalışmak.

---

## Doğrulanamayanlar — Özet Liste

- A1: Tek bir birincil çalışmadan "tempo arttıkça NMA azalır" ilişkisinin kesin sayısal eğrisi (yalnızca tek nokta: 1000ms IOI → ~40ms).
- A3: Tüm-vücut dans hareketi zamanlama SD'si — yalnızca parmak-vuruşu verisi bulundu, whole-body ekstrapolasyonu kaynaksız.
- A2: Arcaea (~25ms) vs Cytus (~70ms) karşılaştırması — tek kaynaklı, resmi değil.
- B2: LE Audio/LC3 gerçek-dünya ölçümü — yalnızca üretici iddiası bulundu, bağımsız laboratuvar testi yok.
- B3: AVDTP 1.3 Delay Reporting'in Android'de app-seviyesinde ne kadar güvenilir okunabildiği — yalnızca forum yorumu kaynaklı.
- B5: Kamera-yakalama + ML-çıkarım toplam boru hattı gecikmesi — uçtan uca ölçen tek kaynak yok, bu doküman kompozit tahmin sunuyor.
- C: AIST++ CC BY 4.0 ifadesinin resmi sayfada birebir konumu — arama sonuçlarında tutarlı ama doğrudan sayfa taramasında bulunamadı.
- C: Motion-X'in ham lisans PDF'inin tam metni — badge/referans doğrulandı, PDF içeriği açılamadı.
- C: PhantomDance'in e-posta-ile-dağıtılan gerçek veri dosyalarına eşlik eden kullanım sözleşmesi — repo MIT ama bu veri-özel sözleşmeyi kapsamayabilir.

---

## Kaynak Listesi (birincil ağırlıklı)

- Repp, B.H. (2005). "Sensorimotor synchronization: A review of the tapping literature." *Psychonomic Bulletin & Review*, 12(6), 969-992. https://link.springer.com/article/10.3758/BF03206433
- Miura vd. (2018). "Does dance training influence beat sensorimotor synchronization?" *Experimental Brain Research*. https://link.springer.com/article/10.1007/s00221-018-5410-4
- "Resonance and beat perception of ballroom dancers: An EEG study." PMC11493285. https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11493285/
- "Audiovisual simultaneity windows reflect temporal sensory uncertainty." PubMed 38388825.
- osu! resmi wiki — Overall Difficulty. https://github.com/ppy/osu-wiki/blob/master/wiki/Beatmap/Overall_difficulty/en.md
- Clone Hero Wiki — Calibrating Audio and Video. https://wiki.clonehero.net/books/guides-and-tutorials/page/calibrating-audio-and-video
- Android CDD — Audio Latency. https://android.googlesource.com/platform/compatibility/cdd/+/refs/heads/master/5_multimedia/5_6_audio-latency.md
- Google WALT — Audio Latency docs. https://android.googlesource.com/platform/external/walt/+/HEAD/docs/AudioLatency.md
- Google Oboe Wiki — TechNote Bluetooth Audio. https://github.com/google/oboe/wiki/TechNote_BluetoothAudio
- Apple Developer Forums thread 126277 — Bluetooth output latency. https://developer.apple.com/forums/thread/126277
- Superpowered — Latency Test App / Android Audio Path Latency Explainer. https://superpowered.com/latency · https://superpowered.com/androidaudiopathlatency
- SoundGuys — Android's Bluetooth latency needs a serious overhaul. https://www.soundguys.com/android-bluetooth-latency-22732/
- inovex — The Glass-To-Glass Latency on Android. https://www.inovex.de/de/blog/the-glass-to-glass-latency-on-android/
- Google Research Blog — BlazePose. https://research.google/blog/on-device-real-time-body-pose-tracking-with-mediapipe-blazepose/
- AIST++ Dataset. https://google.github.io/aistplusplus_dataset/ · https://github.com/google/aistplusplus_api · arXiv 2101.08779
- AIST Dance Video Database — Terms of Use. https://aistdancedb.ongaaccel.jp/terms_of_use/
- FineDance — LICENSE. https://github.com/li-ronghui/FineDance/blob/main/LICENSE
- PhantomDance Dataset. https://github.com/libuyu/PhantomDanceDataset
- Motion-X. https://github.com/IDEA-Research/Motion-X · arXiv 2307.00818
- Bailando — LICENSE. https://github.com/lisiyao21/Bailando/blob/main/LICENSE
- DanceTrack. https://github.com/DanceTrack/DanceTrack/blob/main/README.md
