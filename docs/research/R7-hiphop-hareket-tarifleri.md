# R7 — Hip-Hop 17 Adım: Hareket Tarifi + Gözlemlenebilir Hata Kütüphanesi

**Statü:** 17/17 adım araştırıldı — 14 adım kaynaklı tarif+hata+tier ile tam, 3 adım (Janet Jackson, Gucci, Wu-Tang) yetersiz kaynak nedeniyle kısmi/DOĞRULANAMADI.
**Amaç:** `style.json → stepInventory.needsMovementDescription` ve `G1(c) ölçüm raporu`'nun işaret ettiği boşluğu kapatmak — bu 17 adımın yalnız İSİMLERİ vardı, vücudun beat-beat ne yaptığına dair kaynaklı bilgi yoktu. Bu doküman her adım için `content/SCHEMA.md`'nin ihtiyaç duyduğu üç şeyi üretir: (a) faz-makinesine çevrilebilir hareket tarifi, (b) landmark'a bağlanabilir gözlemlenebilir hata listesi, (c) `measurability.tier` ön-ataması.

## Yöntem ve dürüstlük notu

İki çekirdek kaynak (`iampro.com` kurs sayfası, `learntodance.com` listesi — R1'in bu 17 ismi ürettiği kaynaklar) doğrulandı ve **biyomekanik detay içermediği** teyit edildi (yalnız isim/ders-gruplama). Asıl tarif malzemesi şu kaynaklardan geldi: **DanceWithCeech** (adım-başına özel blog yazıları — bu araştırmanın ana kaynağı, 11 adımda tek kaynak), **STEEZY** ("50+ Dance Move Glossary" + iki adım-özel tutorial), **nextmovedance.com** (Elite Force's Old School Dictionary'den esinli liste), ve **pancocojams** (eski-okul hip-hop video/yorum arşivi — bazı adımlarda gerçek bir gösteri videosunun yorumcu tartışmasını içeriyor, dolaylı ama değerli).

**Sınırlama — açıkça belirtilmeli:** Araştırma ortasında bu oturumun WebSearch kotası tükendi ("200 of 200 WebSearch calls"); kalan araştırma tamamen WebFetch (doğrudan URL) + bir arka-plan ajanının WebFetch-öncelikli taramasıyla yürütüldü. Bu, tarama genişliğini kısıtladı — özellikle Janet Jackson, Gucci, Wu-Tang için ikinci bir arama turu yapılamadı. **DanceWithCeech tek-kaynak olduğu 11 adımda** (Bart Simpson, Smurf, ATL Stomp, Steve Martin, Monastery, Bankhead Bounce, Stomp, Butterfly, BK Bounce + Prep/Reebok'un bazı detayları) bu sitenin tüm yazılarında tekrarlayan bir kalıp var ("omuz genişliğinde ayaklar, dizler hafif bükük" açılışı, "15-20 dakikada öğrenilir" jenerik süre tahminleri, "kişisel stil kat" kapanışı) — bu, sitenin gerçek bir dans-öğretim kaynağı olmadığı anlamına gelmiyor (görevin "eğitmen sitesi/tutorial yazısı" barına uyuyor), ama **tek-kaynaklı** iddiaları çapraz-doğrulanmış iddialardan ayırt etmek gerekiyor. Her adımın Kaynaklar satırı bunu açıkça işaretler.

---

## ÖZET TABLO

| # | Adım | Beat Sayısı | Aksan Beat'i | Tier | Ana Hata # | Kaynak Güveni |
|---|---|---|---|---|---|---|
| 1 | Bart Simpson | ≈2 (yön başına), 4 (tam çevrim) | Tekme + karşı-kol zirvesi | **B** | 5 | Tek kaynak (mekanik) + 1 (köken) |
| 2 | Smurf | 2 (kol başına 1 beat, alternatif) | Kol tam açılma + sıçrama dibi | **A** | 5 | Tek kaynak (mekanik) + 2 (bağlam) |
| 3 | Janet Jackson | BİLİNMİYOR | BİLİNMİYOR | **BİLİNMİYOR** | 0 | **DOĞRULANAMADI** |
| 4 | Wop | 2 (omuz alternation) | Omuz zirvesi + kalça karşı-yönü | **B/C** | 4 | Tek kaynak (mekanik), 2. kaynak yalnız köken |
| 5 | ATL Stomp | 4 (stomp-hop-switch-dönüş) | Stomp vuruş anı | **A** | 5 | Tek kaynak |
| 6 | Prep | ≈8 (4 faz × 2) | Ayna-kontrol anı (eller yüze değince) | **B** | 5 | Tek kaynak (mekanik) + 1 (köken, tutarlı) |
| 7 | Steve Martin | 4 (2 taraf başına) | Yan tekme zirvesi + karşı kol | **A** | 5 | Tek kaynak (mekanik) + 1 (köken) |
| 8 | Monastery | Sürekli/faz-yok (~1/beat osilasyon) | YOK — tek an değil, sürekli illüzyon | **C** ⚠️ | 4 (nominal) | Tek kaynak — **kritik iddia doğrulanamadı** |
| 9 | Bankhead Bounce | 1 (sürekli zıplama) | Zıplama dibi | **A** (küçük genlik notu) | 5 | Tek kaynak (mekanik) + 1 (köken) |
| 10 | Cabbage Patch | ≈2-4 (kol pozisyonu başına) | Kol tam açılma + gövde karşı-eğim | **A** | 6 | **3 bağımsız kaynak** — en sağlam |
| 11 | Reebok | 4 (STEEZY varyantı) | Ağırlık aktarım anı (beat 1) | **A/B** (varyanta bağlı — kurucu kararı) | 5 | **3 kaynak, ÇELİŞKİLİ** |
| 12 | Gucci | BİLİNMİYOR | BİLİNMİYOR | **BİLİNMİYOR** | 0 | **DOĞRULANAMADI** — muhtemelen Reebok ile örtüşüyor |
| 13 | Wu-Tang | BİLİNMİYOR | BİLİNMİYOR | **BİLİNMİYOR** | 0 | **DOĞRULANAMADI** — yalnız "agresif" afekt bilgisi var |
| 14 | Stomp | 2 (alternatif ayak) | Vuruş anı (parmak-ucu→topuk) | **A** | 5 | Tek kaynak |
| 15 | Roger Rabbit | 2 (hop+switch) | İniş + ayak-değişim + kol çırpması | **A** | 6 | **4 bağımsız kaynak** — en sağlam |
| 16 | Butterfly | Sürekli/2 (döngü başına) | Dizler-birleşik + gövde-öne-eğim anı | **A** | 5 | Tek kaynak |
| 17 | BK Bounce | ≈2 (zıplama+yan adım) | Yan adım + kalça kalkışı + karşı kol | **A** | 5 | Tek kaynak (Bankhead Bounce ile karşılaştırmalı) |

**Tier dağılımı:** 9× A · 3× A/B veya B (Bart Simpson, Prep, Reebok-varyanta-bağlı) · 2× B/C sınırında (Wop, ve Reebok'un zayıf varyantı) · 1× C (Monastery) · 3× bilinmiyor (Janet Jackson, Gucci, Wu-Tang).

**En önemli iki bulgu:** (1) **Monastery**, projenin zaten V1-dışı bıraktığı Running Man/Happy Feet ile AYNI risk ailesinde — kaynağın kendi ifadesiyle "illüzyon... görsel sıçrama etkisi yaratmak için parmak-topuk arası hızlı ağırlık kayması" ve "topuklar zeminden zar zor kalkmalı." (2) **Wop**, zaten V1-dışı bırakılmış Harlem Shake ile aynı risk ailesinde — birincil tanımlayıcı unsuru bir OMUZ izolasyonu (düşük-genlikli tek-segment, poz modellerinin belgelenmiş zayıf alanı). İkisi de §C'de detaylandırıldı.

---

## 1. Bart Simpson

**Kaynaklar:** [DanceWithCeech — Bart Simpson](https://dancewithceech.com/blog/bart-simpson) (hareket mekaniği, tek kaynak) · [STEEZY — Dance Move Glossary #6](https://www.steezy.co/posts/the-dance-move-glossary-popular-moves-to-know) (köken doğrulaması: "kol pozisyonu ve kayma hareketi Bart Simpson'ın kaykay sürerken aldığı duruşu taklit eder").

### A) Hareket Tarifi
Ayaklar birleşik ve gövde gevşek başlar. Sağ ayak hafifçe yana tekmelenirken sol ayak onu karşılamak için kayar (yanal bir "gliding" hareketi — ağırlık taşıyan bacak yön değiştirdikçe kayıyor); sonra karşı ayaklarla ters yönde tekrarlanır. Kollar, ayakların TERSİ yönünde ileri-geri sallanır — "tahterevalli" benzeri bir karşıt-hareket (bu, kaykay duruşu kimliğinin ana taşıyıcısı). Karakteristik "sıçramalı caka" (bouncy swagger) eklenir. Beat sayısı kaynakta numaralandırılmamış; **çıkarım (UNVERIFIED — inferred):** yön başına ≈2 beat, tam sağ+sol çevrim ≈4 beat.

Ağırlık, tekme atıp kayan bacağa aktarılıyor; **aksan** = tekme + karşı-kol zirvesinin çakıştığı an (kaykay duruşunun "dondurulmuş kare"si).

### B) Gözlemlenebilir Hatalar
1. Kollar ayaklarla AYNI yönde sallanıyor — tersine değil (tahterevalli/karşıt-hareket imzası kayboluyor; kol-salınım-yönü ile bacak-hareket-yönü arasındaki korelasyon işareti ters olmalı).
2. Yanal ağırlık aktarımı yok — ayaklar kalçanın altında sabit kalıyor, kayma/yer değiştirme genliği ölçülemeyecek kadar küçük.
3. Dizler kilitli/düz — kaymaya eşlik eden diz bükülmesi yok (diz fleksiyon genliği düşük).
4. Kollar dirsekten sıkı bükülü, geniş bir sallanma yerine küçük bir hareket (dirsek açısı genliği düşük).
5. Gövde dik/sert — karakteristik "sıçramalı caka" yok (gövde-salınım/tilt genliği sıfıra yakın).

### C) Ölçülebilirlik Değerlendirmesi
**Tier: B.** Kolların büyük-genlikli karşıt-salınımı (omuzdan itibaren) çok-segmentli ve büyük genlikli — tek başına Tier A adayı. Ancak hareketin kimliğinin bir parçası yanal bir ayak KAYMASI ("gliding") — bu, zaten V1-dışı bırakılan Running Man'in ayak-ucu zemin-temas zamanlamasına kısmen benzer bir bağımlılık taşıyor. Baskın tanınabilir unsur (kol karşıt-salınımı) ayak-ucu zamanlamasına bağlı olmadığından tam Tier C değil, ama kayma bileşeni saf Tier A'yı engelliyor → **B**.

---

## 2. Smurf

**Kaynaklar:** [DanceWithCeech — The Smurf](https://dancewithceech.com/blog/hip-hop-dance-move-smurf) (hareket mekaniği + açık hata, tek kaynak) · [pancocojams — Old School Hip Hop Dance Video](http://pancocojams.blogspot.com/2020/02/old-school-hip-hop-dance-video.html) (bağlam: bir yorumcu "en önemli temel adım" diyor; Buddha Stretch/Mr. Wiggles'a göre "2 farklı versiyonu" olduğu not düşülmüş — DOĞRULANMADI, hangi versiyon aşağıda tarif ediliyor bilinmiyor). **Not:** STEEZY'nin 50+ sözlüğünde klasik Smurf YOK — yalnız "New School Smurf" (#34) var; bu ayrı bir adım, karıştırılmamalı.

### A) Hareket Tarifi
Ayaklar omuz genişliğinde, dizler bükük; parmak ucunda sürekli zıplama (yerinde, yanal kayma YOK — bu önemli, Bart Simpson'dan farklı olarak toe-contact illüzyonuna değil dikey sıçramaya dayanıyor). Her sıçramada bir kol DÜZ tutularak geniş bir daire çizerek dışa savruluyor; bir sonraki sıçramada diğer kol aynısını yapıyor — yani **beat başına bir kol, alternatif** (2 beat'lik tekrarlayan L/R döngüsü). Ağırlık aktarımı yanal değil, iki bacak birlikte dikey (temel Bounce ile aynı mekanik ailesi). **Aksan** = her kolun dairesinin en dış noktasına ulaştığı an, sıçramanın dibiyle senkronize.

### B) Gözlemlenebilir Hatalar
1. Kol sallanırken dirsek bükülüyor — düz kalması gerekirken (kaynağın kendi açık hatası) — dirsek açısı genliği yetersiz.
2. Sıçrama sığ — diz bükülme derinliği yetersiz.
3. Kollar alternatif değil eşzamanlı sallanıyor — sol/sağ kol arasındaki faz farkı ~180° yerine ~0°.
4. Kol salınımı ile sıçrama fazı kilitli değil — kol-zirve anı ile diz-dip anı arasında zamanlama kayması.
5. Sıçrama beat'in üstünde değil arkasında iniyor.

### C) Ölçülebilirlik Değerlendirmesi
**Tier: A.** Büyük genlikli düz-kol daireler + iki dizin birlikte sıçraması = çok-segmentli, büyük genlik, ayak-ucu zemin-temasına bağlı DEĞİL (yerinde dikey sıçrama, kayma yok). Temel `hh_bounce` adımına çok yakın bir varyant — sağlam Tier A örneği.

---

## 3. Janet Jackson

**Kaynaklar:** Hiçbiri yeterli değil. Denenenler: `iampro.com` kurs sayfası (yalnız isim), `learntodance.com` (bahsi yok), STEEZY 50+ sözlüğü (bahsi yok), [FraGue Moser-Kindler listesi](https://www.frague.at/hip-hop-move-list/) (girdi #21, alternatif isimler **"(Janet, Barbie)"**, kaynak "Marcio Ratinho" olarak not düşülmüş — **açıklama YOK**), `nextmovedance.com` (bahsi yok). Arka-plan araştırma ajanı bu adıma özel ek tur yaptı — bulgular aşağıda "Ajan Bulguları" alt-başlığında (bulunamadıysa bu adım tamamen DOĞRULANAMADI kalır).

### A) Hareket Tarifi
**DOĞRULANAMADI.** Hiçbir kaynak vücudun ne yaptığını tarif etmiyor. Tek ipucu: bir YouTube video yorumcusunun (Prep hakkındaki bir pancocojams gönderisinde, bağlam dışı bir yan not olarak) "orijinal pre-Janet-Jackson amigo-kız rutini formunu" görmekten bahsetmesi — bu, "Janet Jackson" adının bir amigo-kız (cheerleader) tarzı rutine ve muhtemelen Prep'e tarihsel/koreografik olarak bağlı olabileceğini düşündürüyor, ama bu tek bir yan-yorumdan öte bir kaynak DEĞİL. **Bu bağlantı doğrulanmamış bir ipucu olarak kaydedilir, gerçek olarak sunulmaz.**

### B) Gözlemlenebilir Hatalar
Üretilemez — kaynaklı bir hareket tarifi olmadan hata listesi yazmak, gözlemlenebilirlik iddiası olmayan bir tahmin üretmek olurdu. **Yazılmadı.**

### C) Ölçülebilirlik Değerlendirmesi
**Tier: BİLİNMİYOR — atanamaz.** Vücut mekaniği bilinmeden tier ataması, kararmış gibi görünen bir tahmin olur (G1(c)'nin kendi ilkesi).

---

## 4. Wop

**Kaynaklar:** [nextmovedance.com — Elite Force's Old School Dictionary](https://www.nextmovedance.com/blog/top-hip-hop-dance-moves-every-kid-should-learn-inspired-by-elite-forces-old-school-dictionary) (TEK mekanik kaynak) · [STEEZY — Dance Move Glossary #59](https://www.steezy.co/posts/the-dance-move-glossary-popular-moves-to-know) (yalnız köken/tarih: "2011'de 'Wop' adlı bir şarkı çıktığında yeniden canlandırılan bir dans, ama adım uzun zamandır var").

### A) Hareket Tarifi
Ayaklar omuz genişliğinde, dizler hafif bükük (sabit taban — kayma/adım yok). Bir omuz kaldırılıp indiriliyor, sonra diğeri — yanal bir sallanma yaratarak (**omuz izolasyonu**). Omuzlar hareket ederken kalçalar TERS yönde hareket ediyor (karşıt-hareket, bu adım setinde tekrarlayan bir motif). **Çıkarım (UNVERIFIED):** omuz başına 1 beat, 2 beat'lik alternatif L/R döngü. **Aksan** = bir omuzun zirve noktası + kalçanın karşı-yöndeki zirvesinin çakıştığı an.

**⚠️ Önemli belirsizlik:** iampro kursu bu adımı Lesson 2'de Bart Simpson/Smurf/Janet Jackson/ATL Stomp ile birlikte gruplamış — yani eski-okul bağlamda öğretiliyor. Ama STEEZY'nin notu iki ayrı dönem/versiyon olasılığını işaret ediyor (1980'ler eski-okul vs. 2011 J. Dash şarkısı sonrası canlanan versiyon, ki bu ikincisinin farklı hareket ettiği düşünülüyor — DOĞRULANAMADI, iki versiyonun gerçekten farklı olup olmadığı teyit edilemedi). `dancewithceech.com`'un blog indeksinde yalnız **"Tone Wop (Harlem Litefeet)"** var — bu FARKLI, daha modern bir adım, klasik Wop ile KARIŞTIRILMAMALI.

### B) Gözlemlenebilir Hatalar
1. Omuzlar birlikte/eşzamanlı hareket ediyor — alternatif değil (izolasyon imzası kayboluyor).
2. Kalçalar omuzlarla AYNI yönde hareket ediyor — ters yönde değil (karşıt-hareket kayboluyor).
3. Omuz kaldırma genliği ölçülemeyecek kadar küçük (bu izolasyonun doğasında var olan risk).
4. Hareket beat'in dışında.

### C) Ölçülebilirlik Değerlendirmesi
**Tier: B/C — muhtemelen V1-dışı aday.** Birincil tanımlayıcı unsur bir OMUZ İZOLASYONU — bu, projenin zaten V1-dışı bıraktığı **Harlem Shake** ile AYNI risk kategorisi ("omuz izolasyonu — düşük genlikli tek-segment, poz modellerinin belgelenmiş zayıf alanı," bkz. `style.json tierC_excluded`). Kalça karşıt-hareketi ikinci bir segment ekliyor ama kaynağın kendi tarifinde birincil/tanımlayıcı unsur omuz kalıyor. **Harlem Shake emsaliyle tutarlı olmak için Tier C'ye yakın B olarak işaretlendi** — kesin karar için ikinci bir kaynakla genlik teyidi önerilir.

---

## 5. ATL Stomp

**Kaynaklar:** [DanceWithCeech — Mastering The ATL Stomp](https://dancewithceech.com/blog/mastering-the-atl-stomp-rhythm-of-the-south) (tek kaynak, ama detaylı ve açık hata + net "Stomp"tan farkı içeriyor).

### A) Hareket Tarifi
Ayaklar omuz genişliğinde başlar. **Beat 1:** sağ ayak yere sertçe vuruluyor (stomp). **Ardından (yarım-beat/"&"):** hafif bir sıçrama ile ağırlık sağ ayağa kayıyor, sol ayak hafifçe geriye tekmeleniyor. **Beat 2:** sol ayak yere iniyor, stomp solla tekrarlanıyor. **Beat 3-4:** çeyrek dönüş eklenerek stomp-hop dizisi tekrarlanıyor (dönüş zamanlaması kaynakta net numaralandırılmamış — **UNVERIFIED, çıkarım**). Ağırlık her stomp'ta tam olarak vuran bacağa aktarılıyor; kaldırılan bacak serbest/ağırlıksız bir aksan. **Aksan** = stomp'un yere değme anı (yüksek, algılanabilir bir "vuruş").

### B) Gözlemlenebilir Hatalar
1. "Zayıf stomp" — ayak yere yavaş/yumuşak iniyor, hızlı-kuvvetli bir vuruş yerine (kaynağın kendi açık hatası; kamboyla ölçülebilir vekil = ayak-bileği dikey hızı temas anında düşük).
2. Ağırlık stomp yapan bacağa tam aktarılmıyor — o bacağın kalça/diz açısı yeterince değişmiyor.
3. Çeyrek dönüş eksik/küçük — gövde/kalça yaw rotasyon genliği düşük.
4. Geri tekmelenen serbest bacak gerçek bir tekme gibi çok yükseğe kalkıyor — hafif bir "flick" yerine (kalça fleksiyon/ekstansiyon genliği aşırı).
5. Stomp beat'in dışında iniyor.

### C) Ölçülebilirlik Değerlendirmesi
**Tier: A.** Büyük genlikli stomp + tam ağırlık aktarımı + isteğe bağlı gövde/kalça dönüşü = çok-segmentli, büyük genlik. Ayak-ucu illüzyonuna DEĞİL, kasıtlı tam-ağırlıklı bir vuruşa dayanıyor (Running Man'in tam tersi bir mekanik) → sağlam **A**.

---

## 6. Prep

**Kaynaklar:** [DanceWithCeech — The Prep](https://dancewithceech.com/blog/hip-hop-dance-move-prep) (hareket mekaniği, tek kaynak) · [STEEZY — Dance Move Glossary #36](https://www.steezy.co/posts/the-dance-move-glossary-popular-moves-to-know) (köken: "1980'lerde kulüplere gitmeye başlayan 'preppy' üniversiteli gençlere atfen adlandırıldı" — bu, aşağıdaki pandomim içeriğiyle TUTARLI: "dışarı çıkmadan önce hazırlanma" pandomimi, isim-kökeni ile hareket-içeriği birbirini destekliyor, bu da güveni artırıyor).

### A) Hareket Tarifi
Temel bir sıçrama/groove üzerine bindirilmiş **4 fazlı bir pandomim dizisi**: **(1) Ayna-kontrolü** — eller yüze kaldırılıyor, sanki aynada kontrol ediyormuş gibi, 2 sıçrama boyunca. **(2) Omuz fırçalama** — omuzlardan toz/kepek silkeleme taklidi, 2 sıçrama. **(3) Kot-fırçalama** — öne eğilip pantolonu silkeleme taklidi, 2 sıçrama (bu fazda gövde ÖNE eğiliyor, diğer fazlarda dik). **(4) Son sıçrama/bop** ile kapanış. **Çıkarım (UNVERIFIED — "2 sıçrama" ifadesinden):** toplam ≈8 beat'lik bir cümle (4 faz × ~2 beat), ama kaynak bunu kesin sayılarla vermiyor. **Aksan** = eller yüze değdiği an (en ikonik/tanımlayıcı pandomim karesi — "aynada kontrol" imgesi).

### B) Gözlemlenebilir Hatalar
1. Pandomim sırasında alttaki sıçrama duruyor/düzleşiyor — groove kayboluyor (diz-fleksiyon osilasyonu faz 2-4'te sıfıra yakın).
2. "Kot-fırçalama" fazında gövde öne eğilmiyor, dik kalıyor (gövde-fleksiyon genliği yetersiz o fazda).
3. Eller "ayna-kontrolü" fazında yüz seviyesine ulaşmıyor — el-baş arası dikey mesafe yeterince kapanmıyor.
4. Fazlar birbirine karışıyor/aceleye geliyor — her fazın kendi ~2-beat payını almaması (faz-süresi, beat ızgarasından sapıyor).
5. Hareketler küçük/çekingen — kaynağın kendi ipucu "ne kadar büyük yaparsan o kadar iyi görünür" (kol uzanımı/gövde fleksiyonu bir minimum genlik eşiğinin altında).

### C) Ölçülebilirlik Değerlendirmesi
**Tier: B.** Çok-fazlı, çok-segmentli (kollar + gövde + sürekli diz sıçraması) ve çoğu fazda genlik iyi (özellikle omuz-fırçalama ve kot-fırçalama fazlarında büyük gövde-eğimi + kol süpürmesi var). Ama "ayna-kontrolü" alt-jesti nispeten küçük ölçekli, büyük bir eklem-açısından çok belirli bir EL-KONUMUNA (yüze yakınlık) dayanıyor — bu, saf bir eklem-genliği ölçümünden biraz farklı ve biraz daha az sağlam bir ölçüm türü. Bu nüans, temiz bir A yerine **B**'yi haklı çıkarıyor.

---

## 7. Steve Martin

**Kaynaklar:** [DanceWithCeech — Steve Martin](https://dancewithceech.com/blog/steve-martin-dance) (hareket mekaniği + yaratıcı atfı + açık hata, tek kaynak) · [STEEZY — Dance Move Glossary #45](https://www.steezy.co/posts/the-dance-move-glossary-popular-moves-to-know) (köken doğrulaması: aktör/komedyen Steve Martin'e atıfla adlandırıldığını teyit ediyor).

### A) Hareket Tarifi
**Yaratıcı atfı:** Stezo (Connecticut'lı rapçi/dansçı), 1980'lerin sonunda; EPMD'nin 1988 "You Gots to Chill" videosunda göründü; komedyen Steve Martin'in enerjik performans tarzına saygı olarak adlandırıldı (komedyenin kendisi YARATMADI). **Hareket:** ayaklar omuz genişliğinde, dizler hafif bükük. **Beat 1-2:** ağırlık sağ ayağa kayıyor, sol bacak dizden bükülerek yana tekmeleniyor (yanal, ileri DEĞİL); sol ayak merkeze dönüyor, ağırlık sola kayıyor. **Beat 3-4:** aynı hareket sağ bacakla tekrarlanıyor. Destekleyici bacakta vurgu için hafif bir sıçrama/hop var. Kollar bacakların TERSİ yönünde sallanıyor (karşıt-hareket — bu setteki tekrarlayan motif). **Aksan** = yan tekmenin zirve noktası + karşı kol salınımının çakıştığı an.

### B) Gözlemlenebilir Hatalar
1. Tekme atan bacak gerçek/karate tekmesi gibi çok yükseğe kalkıyor — diz-şin seviyesinde kontrollü bir yana-uzanım yerine (kaynağın kendi açık hatası; kalça abdüksiyon/fleksiyon açısı beklenen aralığın üstünde).
2. Kollar tekme atan bacakla AYNI yönde sallanıyor — karşıt yönde değil.
3. Destekleyici bacağa ağırlık aktarılmıyor — diğer bacak tekmelese de o bacağın kalça/diz açısı değişmiyor (tekme "grove"suz bir serbest jest haline geliyor).
4. Destekleyici bacağın sıçrama/hop vurgusu eksik — o bacağın diz-fleksiyon osilasyonu sıfıra yakın.
5. Tekme beat'in dışında iniyor.

### C) Ölçülebilirlik Değerlendirmesi
**Tier: A.** Büyük genlikli yanal bacak tekmesi + karşıt kol salınımı + tam ağırlık aktarımı = çok-segmentli, büyük genlik, ayak-ucu kaymasına/illüzyonuna bağlı DEĞİL (net bir tekme-ve-dönüş, tam ağırlık aktarımıyla). Sağlam **A** — bu setin en temiz örneklerinden.

---

## 8. Monastery

**Kaynaklar:** [DanceWithCeech — The Monastery](https://dancewithceech.com/blog/hip-hop-dance-move-monastery) (hareket mekaniği, TEK kaynak — kritik iddia ikinci bir kaynakla doğrulanamadı) · [STEEZY — Dance Move Glossary #31](https://www.steezy.co/posts/the-dance-move-glossary-popular-moves-to-know) (yalnız köken: "St. Louis'te Club Monestary adlı popüler bir dans kulübüne atfen adlandırıldı" — köken bilgisi 2 kaynakla örtüşüyor, ama hareket-mekaniği hâlâ tek-kaynaklı).

### A) Hareket Tarifi
Ayaklar omuz genişliğinde, dizler bükük. Ağırlık hızla parmak-ucuna kayıyor (topuklar zeminden kalkıyor), sonra hızla topuğa geri kayıyor (parmak ucu kalkıyor) — bu parmak-topuk osilasyonu sürekli tekrarlanarak bir "sıçrama illüzyonu" yaratıyor. Kollar aşağı-itme hareketi yapıyor; baş gevşek/sallanıyor. **Bu hareketin ÖZÜ:** kaynağın kendi ifadesiyle *"Monastery illüzyonu topuklar zeminden ZAR ZOR kalktığında çalışır — dikey hareketi GÖRMEKTEN çok ağırlık aktarımını HİSSETMELİSİN."* Yani dikey genlik KASITLI OLARAK küçük. Beat sayısı ayrık bir sayım yerine sürekli bir groove niteliğinde — bu yüzden tek bir "aksan" anı YOK, bu da diğer 16 adımdan farklı bir özellik.

### B) Gözlemlenebilir Hatalar
*(Aşağıdaki hatalar tamamlayıcı amaçla listelendi; §C'deki tier bulgusu bu adımın muhtemelen V1 kapsamına hiç girmeyeceğini gösteriyor.)*
1. Topuklar/parmak uçları beklenenden ÇOK daha fazla genlikle kalkıyor — illüzyonu görünür bir sıçramaya çeviriyor (ters bir hata: burada FAZLA genlik hatalı, çünkü hareketin kimliği küçük-genlikli olmasına dayanıyor).
2. Hiç ağırlık kayması yok — ayaklar tamamen düz/sabit kalıyor (en temel başarısızlık — parmak-topuk alternasyonu hiç gerçekleşmiyor).
3. Sol/sağ ayak parmak-topuk fazında senkron değil.
4. Zamanlama beat ızgarasından kayıyor.

### C) Ölçülebilirlik Değerlendirmesi
**Tier: C — muhtemel V1-dışı aday.** Bu, projenin zaten V1-dışı bıraktığı **Running Man** ve **Happy Feet** ile YAPISAL OLARAK AYNI risk ailesi: kaynağın kendi tanımı doğrudan "illüzyon" diyor ve dikey/görünür hareketi DEĞİL, parmak-ucu/topuk zemin-temas ZAMANLAMASINI birincil mekanizma olarak tarif ediyor — tam olarak `style.json`'daki mevcut dışlama gerekçesiyle örtüşüyor ("ayak-zemin temas zamanlamasına dayalı illüzyon; ayak ucu markerless tek kamerada en düşük güvenli noktalardan"). **Bu doğrudan `content/SCHEMA.md`'nin Tier C tanımına giriyor** ("düşük-genlikli izolasyon VEYA ayak-ucu temas zamanlamasına dayalı"). Tek-kaynaklı olduğu için ikinci bir kaynakla teyit önerilir, ama mevcut kanıt Tier C'yi güçlü şekilde işaret ediyor.

---

## 9. Bankhead Bounce

**Kaynaklar:** [DanceWithCeech — Bankhead Bounce](https://dancewithceech.com/blog/bankhead-bounce) (hareket mekaniği + tarihçe, tek kaynak) · [STEEZY — Dance Move Glossary #5](https://www.steezy.co/posts/the-dance-move-glossary-popular-moves-to-know) (köken doğrulaması: "Bankhead Bounce batı Atlanta'dan geliyor, 'Bankhead' olarak bilinen"). **Tarihsel iddia (DOĞRULANMADI, tek kaynak):** D-Roc'un 1995 "Bankhead Bounce" single'ı ve Michael Jackson'ın 1995 MTV VMA'da bu hareketi yaptığı iddiası — makul ama ikinci bir kaynakla teyit edilmedi, ihtiyatla kullanılmalı.

### A) Hareket Tarifi
Ayaklar omuz genişliğinde, dizler hafif bükük. Sürekli, YUMUŞAK bir diz sıçraması — kaynağın kendi vurgusuyla *"küçük ve sürekli"*, agresif/yüksek-enerjili bir zıplama DEĞİL. Kollar doğal sallanıyor VEYA her sıçramada öne/yanlara itiliyor (isteğe bağlı, stilistik — bu ürünün "freeJoints" felsefesiyle örtüşüyor, bkz. `hh_bounce.json`). Baş sallama/omuz silkme gibi kişisel stil unsurları AÇIKÇA "flair" olarak işaretlenmiş, çekirdek mekanik değil. Ağırlık aktarımı yanal değil, temel Bounce ile aynı ailede iki-bacaklı dikey groove. **Aksan** = her diz-sıçramasının dip noktası (temel Bounce'ın `bounce_bottom` skorlanan anıyla aynı yapı).

### B) Gözlemlenebilir Hatalar
1. Çok sert/agresif sıçrama — küçük ve sürekli olması gerekirken (kaynağın kendi açık hatası: "beat'ten kopararak çok sert sıçrıyorlar" — burada da FAZLA genlik hatalı, diz-fleksiyon genliği beklenen küçük-orta aralığı AŞIYOR).
2. Hiç sıçrama yok — statik duruş (temel Bounce'ın NO_BOUNCE hatasıyla aynı başarısızlık modu).
3. Sıçrama fazı beat ızgarasından kayıyor.
4. Sol/sağ diz bükülmesi asimetrik.
5. Dizler yerine belden bükülüyor (temel Bounce'ın TRUNK_COLLAPSE hatasıyla aynı — Bankhead Bounce açıkça bir bounce-ailesi varyantı olduğu için bu hata devralınabilir).

### C) Ölçülebilirlik Değerlendirmesi
**Tier: A** (küçük-genlik kalibrasyon notuyla). Yapısal olarak projenin zaten yazdığı `hh_bounce` adımına çok yakın — iki dizin birlikte bükülmesi, ayak-ucu zamanlamasına bağlı değil. Ama genlik AÇIKÇA daha küçük/"relaxed" olarak tarif ediliyor — bu, eşik/tolerans kalibrasyonunun ayrıca yapılması gerektiği (muhtemelen Smurf veya Steve Martin gibi büyük-genlikli adımlardan daha dar bir tolerans bandı) anlamına geliyor, ama çok-segmentli yapısı nedeniyle Tier A sınıflandırmasını hak ediyor.

---

## 10. Cabbage Patch

**Kaynaklar (3 bağımsız kaynak — bu setin en sağlam adımı):** [DanceWithCeech — Cabbage Patch](https://dancewithceech.com/blog/cabbage-patch) · [STEEZY — How To Do The Cabbage Patch](https://www.steezy.co/posts/how-to-do-the-cabbage-patch) (en detaylı) · [nextmovedance.com](https://www.nextmovedance.com/blog/top-hip-hop-dance-moves-every-kid-should-learn-inspired-by-elite-forces-old-school-dictionary) · [STEEZY glossary #11](https://www.steezy.co/posts/the-dance-move-glossary-popular-moves-to-know) (köken: Miami rap grubu Gucci Crew II, 1986 aynı-isimli şarkı + 1980'ler Cabbage Patch Kids bebeklerine atıf — iki köken unsuru birbiriyle çelişmiyor, tamamlayıcı).

### A) Hareket Tarifi
Ayaklar omuz genişliğinde, dizler bükük. Eller yumruk yapılıp göğüs önünde DÜZ bir daire çiziyor (dirsekten büküyken başlayıp öne düz uzanarak). **STEEZY'nin daha detaylı versiyonu** ek olarak: gövde/göğüs, kolların o an işaret ettiği yönün TERSİNE yaslanıyor (karşıt-eğim — bu setteki tekrarlayan opozisyon motifi); ve ayaklar "pedallıyor" — her beat'te bir topuk kalkıyor, ağırlık düz bacağa batıyor, kalçalar yana sallanıyor; hangi tarafa kollar işaret ediyorsa AYNI taraf topuğu kalkıyor. **DanceWithCeech'in daha basit versiyonu** yalnız kol-dairesi + kalça-sallanışı tarif ediyor, ayaklar konusunda sessiz (bir yorumcu grubunun "yerinde duruyorsun" demesiyle uyumlu). **⚠️ KAYNAKLAR ÇELİŞİYOR:** ayak katılımının derecesi konusunda — "tamamen sabit + yalnız kalça sallanışı" ile "aktif topuk-kaldırma ağırlık-pedalı" arasında değişiyor; bu muhtemelen öğretim-basitleştirmesi veya bölgesel/kişisel stil farkı, kesin tek "doğru" yok. **Çıkarım (UNVERIFIED):** kol-pozisyonu başına ≈2 beat. **Aksan** = kolların tam açılımı + gövde karşıt-eğimi + (varsa) aynı-taraf topuk-kalkışının çakıştığı an.

### B) Gözlemlenebilir Hatalar
1. Kollar dirsekten sürekli bükülü kalıyor, tam açılan bir daire yerine (kol/dirsek açı genliği yetersiz).
2. Gövde karşıt-eğim yapmıyor — göğüs dik/merkezi kalıyor, kolların tersine yaslanmıyor (gövde-yanal-eğim genliği yetersiz VEYA yanlış yönde — kollarla AYNI yöne eğiliyor).
3. Ayaklar tamamen düz/hareketsiz — hiçbir ağırlık-batışı veya topuk-kalkışı yok (bu, üst-vücut-yalnız bir icra olabilir — hangi varyantın öğretildiğine bağlı olarak hata sayılıp sayılmayacağı değişir, bu yüzden bu hata YALNIZ "pedallı" varyant öğretiliyorsa geçerli).
4. Kollar ve kalça-sallanışı/topuk-kalkışı senkron değil — kollar bir yöne işaret ederken ağırlıklı taraf diğer yönde.
5. Eller açık, yumruk değil (bir el-şekli/poz detayı — **düşük güven notu:** bunu iskelet-eklem takibiyle tespit etmek parmak/el landmark'ları gerektirir, yalnız vücut-eklemleriyle DEĞİL — dürüstçe belirtilmeli).
6. Kol dairesi hızı beat'e uymuyor (çok hızlı/yavaş).

### C) Ölçülebilirlik Değerlendirmesi
**Tier: A.** Çok-segmentli (kollar + gövde-eğimi + isteğe bağlı topuk-kalkışı), kol dairesi ve gövde eğimi büyük genlikli. İsteğe bağlı topuk-kalkışı küçük bir ayak/topuk unsuru içeriyor ama bu, hareketin BİRİNCİL kimliği DEĞİL (kol dairesi birincil) — Monastery'nin tam tersine, burada ayak-ucu/topuk unsuru varsa bile ikincil/destekleyici, tüm kimliği taşımıyor. Bu tam olarak neden Cabbage Patch A iken Monastery C olduğunun iyi bir karşılaştırmalı örneği.

---

## 11. Reebok

**Kaynaklar (3 kaynak, GERÇEKTEN ÇELİŞKİLİ):**
1. [pancocojams — YouTube Instructional Videos of Four Old School Hip-Hop Dances](http://pancocojams.blogspot.com/2020/02/youtube-instructional-videos-of-four.html) (video-transkript tarzı): *"Right leg, your left, my right... üç adım atacaksın. Sağ, sol, sağ. Vücudun biraz sallanıyor... Kollar istediğin gibi."*
2. [nextmovedance.com](https://www.nextmovedance.com/blog/top-hip-hop-dance-moves-every-kid-should-learn-inspired-by-elite-forces-old-school-dictionary): *"Bir ayakla öne adım at, sonra aynı ayakla hızla geri adım at. Geri adım atarken diğer ayağını kaldırıp yana tekmele. Ayak değiştirerek tekrarla."*
3. [STEEZY — How To Do The Reebok](https://www.steezy.co/posts/how-to-do-the-reebok) (en yapılandırılmış, açık beat numaralı): sağ bacak önde/sol arkada başla, gövdeyi beat'e göre ileri-geri salla; beat 1'de ağırlık sağa kayıyor + sol bacak arkaya sallanıyor (abartılı kol salınımıyla); beat 3-4'te omuz-shimmy + ayak-pivot ile yön değiştirme + ilerleme.

**⚠️ ÜÇ KAYNAK ÜÇ FARKLI ADIM TARİF EDİYOR.** Ortak nokta: bacaklar arasında ağırlık alternasyonu + bir adım/tekme/sallanma unsuru + nispeten serbest kol katılımı. Hangisinin "doğru"/kanonik olduğuna dair bir hakem yok — muhtemelen bölgesel/eğitmen-bazlı gerçek varyantlar. **Kurucu kararı gerekiyor:** hangi varyant öğretilecek? Aşağıdaki A/B/C, en yapılandırılmış (STEEZY) varyantı birincil alıyor, diğer ikisini not düşüyor.

### A) Hareket Tarifi (STEEZY varyantı, birincil)
Sağ bacak önde, sol arkada; gövde beat'e göre ileri-geri sallanıyor. Beat 1'in hemen öncesinde ("ve"): sağ bacak + sol kol yukarı, koşar-adım taklidi. **Beat 1:** ağırlık sağ bacağa kayıyor, sol bacak abartılı kol-salınımıyla arkaya sallanıyor. **Beat 2:** sol bacağa geri sallanma. **Beat 3-4:** omuz-shimmy + ayak-pivot ile ters yöne dönüş, ilerleme. Ağırlık her beat'te tam alternatiflenen bacağa aktarılıyor. **Aksan** = beat 1'deki ilk ağırlık-aktarım anı (koşar-adım hazırlığından sonraki "düşüş").

### B) Gözlemlenebilir Hatalar
1. Ön/arka bacaklar arasında net bir ağırlık aktarımı yok — iki ayak eşit yüklü kalıyor, alternatiflenmiyor.
2. Dönüş/yön-değiştirme unsuru eksik (STEEZY varyantı hedefleniyorsa) — gövde/kalça yaw rotasyonu yok.
3. Kollar tamamen hareketsiz — "serbest stil" olsa da HER ÜÇ kaynakta da bir düzeyde kol salınımı evrensel; tam hareketsiz kollar herhangi bir varyanta göre hatalı sayılır.
4. Sallanma/adım beat'in dışında.
5. Omuz-shimmy (STEEZY varyantı) genliği kayda değmeyecek kadar küçük.

### C) Ölçülebilirlik Değerlendirmesi
**Tier: A/B — varyanta bağlı, kurucu kararı gerekiyor.** STEEZY'nin daha yapılandırılmış varyantı (bacak-sallanma + kol-salınımı + omuz-shimmy + dönüş) çok-segmentli ve büyük-orta genlikli → **A**'ya yakın. pancocojams'ın basit "3-adım" varyantı daha küçük/ince (yalnız adımlar + hafif gövde sallanışı) → **B**'ye daha yakın. **Öneri:** uygulama tek bir kanonik varyant seçmeli (faz-makinesine çevrilebilirlik için STEEZY'nin yapılandırılmış versiyonu daha uygun) — bu bir ürün kararı, araştırma bunu tek başına çözemez.

---

## 12. Gucci

**Kaynaklar:** [FraGue Moser-Kindler listesi](https://www.frague.at/hip-hop-move-list/) (girdi #4, kaynak "Buddha Stretch" olarak not düşülmüş, **açıklama YOK**) · pancocojams'daki aynı yorum-tartışması (bkz. Reebok) içinde isim-karışıklığı kanıtı: *"Link ona reebok'un aslında reebok olmadığını, gucci olduğunu söyledi"* ve ayrı bir yorumda *"Reebok aslında Gucci"* (bir atölyeden sonra söylenmiş) ve *"Fila rambo... ve Reebok gucci... sanırım."* Arka-plan araştırma ajanı bu adıma özel ek tur yaptı — bulgular "Ajan Bulguları" alt-başlığında.

### A) Hareket Tarifi
**DOĞRULANAMADI — Gucci'yi Reebok'tan bağımsız tarif eden hiçbir kaynak bulunamadı.** Mevcut kanıt, ayakkabı/marka-adlı danslar ailesinde (Reebok, Gucci, Fila) bölgesel/topluluk-bazlı gerçek bir isim-karışıklığı olduğunu gösteriyor — bazı geleneklerde "Gucci," "Reebok"un bir varyantına verilen ALTERNATİF bir isim olabilir, ayrı bir hareket olmayabilir. Bu belirsizlik daha da karmaşıklaşıyor çünkü Reebok'un KENDİSİ zaten 3 farklı kaynakta 3 farklı şekilde tarif edildi (§11).

### B) Gözlemlenebilir Hatalar
Üretilemez — bağımsız bir kaynaklı tarif olmadan yazılmadı.

### C) Ölçülebilirlik Değerlendirmesi
**Tier: BİLİNMİYOR — atanamaz.** Eğer Gucci gerçekten Reebok'un bir varyantıysa, tier'i Reebok'unkiyle aynı olurdu (§11) — ama bu varsayımı doğrulayacak bağımsız bir kaynak yok.

---

## 13. Wu-Tang

**Kaynaklar:** [STEEZY — Dance Move Glossary #60](https://www.steezy.co/posts/the-dance-move-glossary-popular-moves-to-know) (yalnız afekt: *"Wu Tang hızlı-tempolu, güçlü, agresif bir dans — birisiyle dövüşüyormuş hissi vermeli"*) · [FraGue listesi](https://www.frague.at/hip-hop-move-list/) (İKİ ayrı girdi — #17 ve #41 — ikisi de "Buddha Stretch" kaynaklı, **açıklama YOK**; neden iki kez listelendiği belirsiz, muhtemelen iki varyant/dönem). Denenen `dancewithceech.com/blog/hip-hop-dance-move-wu-tang` ve `steezy.co/posts/how-to-do-the-wu-tang` doğrudan URL'leri 404 döndü. Arka-plan araştırma ajanı bu adıma özel ek tur yaptı — bulgular "Ajan Bulguları" alt-başlığında.

### A) Hareket Tarifi
**DOĞRULANAMADI.** Yalnız enerji/afekt biliniyor ("hızlı, agresif, dövüşür gibi"); ayakların, dizlerin, kolların, kalçanın ne yaptığına dair HİÇBİR kaynak bulunamadı. Wu-Tang Clan'ın ikonik "W" el-işaretiyle bir bağlantısı olup olmadığı **DOĞRULANMADI** — varsayılmadı, kontrol edilemedi.

### B) Gözlemlenebilir Hatalar
Üretilemez — yazılmadı.

### C) Ölçülebilirlik Değerlendirmesi
**Tier: BİLİNMİYOR — atanamaz.**

---

## 14. Stomp

**Kaynaklar:** [DanceWithCeech — Stomping](https://dancewithceech.com/blog/hip-hop-dance-move-stomping) (hareket mekaniği + açık hata + ATL Stomp'tan net ayrım, tek kaynak).

### A) Hareket Tarifi
Ayaklar omuz genişliğinde, dizler hafif bükük. Bir ayak kaldırılıyor (diz bükülerek, topuk kalçaya doğru); ardından KUVVETLE, önce ayağın topu (ball) ile, sonra topuk takip ederek yere vuruluyor — düz-tabanlı DEĞİL, "top-sonra-topuk" sıralı bir vuruş (perküsif ses/his için). Diğer ayakla alternatif tekrarlanıyor (**2 beat'lik alternatif L/R döngü**). Kollar üzerine yumruk/dalga gibi isteğe bağlı hareketler eklenebilir (stil, çekirdek mekanik değil — `hh_bounce.json`'daki `freeJoints` felsefesiyle örtüşüyor). Ağırlık her vuran ayağa tam aktarılıyor. **Aksan** = yere değme anı (top-sonra-topuk vuruşu). **`ATL Stomp`'tan farkı** (aynı kaynağın kendi ifadesiyle): "stomping, perküsif tekniğin kendisi; ATL Stomp ise bu tekniği çekirdek mekanik olarak kullanan, karakteristik kol ve kalça işiyle birlikte Atlanta'dan gelen TAM bir dans hareketi."

### B) Gözlemlenebilir Hatalar
1. Düz-tabanlı vuruş — top-sonra-topuk sıralaması yerine (kaynağın kendi açık hatası). **Düşük güven notu:** top-vs-topuk sıralamasını yalnız iskelet-eklemleriyle (ayak/bilek landmark'ları olmadan) güvenilir tespit etmek zor — bu, ayak-ucu landmark'larına kısmen bağımlı bir hata, dürüstçe belirtilmeli.
2. Vuruştan önce yetersiz diz-kaldırma (topuk kalçaya yeterince yaklaşmıyor — kalça/diz fleksiyon genliği düşük).
3. Vuran bacağa ağırlık tam aktarılmıyor (o bacağın kalça/diz açısı yeterince değişmiyor).
4. Vuruş beat'in dışında.
5. Sol/sağ vuruş genliği asimetrik.

### C) Ölçülebilirlik Değerlendirmesi
**Tier: A.** Büyük diz-kaldırma + tam ağırlık aktarımı + alternasyon = çok-segmentli (döngü boyunca), büyük genlik. Tek bir anda yalnız bir bacak "aktif" olsa da (Smurf'ün eşzamanlı iki-diz hareketinden farklı olarak), döngü genelinde iki bacak da kullanılıyor ve genlik/ağırlık-aktarımı büyük → **A**, ama A/B sınırına Smurf'ten daha yakın.

---

## 15. Roger Rabbit

**Kaynaklar (4 bağımsız kaynak — Cabbage Patch ile birlikte en sağlam adım):** [STEEZY — How To Do The Roger Rabbit](https://www.steezy.co/posts/how-to-do-the-roger-rabbit) (R1'den) · [DanceWithCeech — Roger Rabbit](https://dancewithceech.com/blog/hip-hop-dance-move-roger-rabbit) (R1'den + pancocojams üzerinden) · [pancocojams — YouTube Instructional Videos of Four Old School Hip-Hop Dances](http://pancocojams.blogspot.com/2020/02/youtube-instructional-videos-of-four.html) · [nextmovedance.com](https://www.nextmovedance.com/blog/top-hip-hop-dance-moves-every-kid-should-learn-inspired-by-elite-forces-old-school-dictionary) · [STEEZY glossary #39](https://www.steezy.co/posts/the-dance-move-glossary-popular-moves-to-know).

### A) Hareket Tarifi
Ayaklar birleşik, dizler hafif bükük. Ağırlıklı ayakla GERİYE doğru sıçranıyor (hop) — diğer ayak yerden kalkıp geriye tekmeleniyor; iniş anında ayaklar değişiyor, tekrarlanıyor (**2 beat'lik alternatif döngü, geriye doğru İLERLEYEN bir hareket**). Kollar, sanki askı-pantolon (suspenders) askılarına başparmakları takmış gibi "çırpınan" bir jest yapıyor — 4 bağımsız kaynakta tutarlı, çok spesifik bir tanımlayıcı unsur. Genel afekt: "cıvık ve komik" (floppy and silly) — hem bacaklar hem kollar gevşek/sarkık görünmeli. Ağırlık her sıçramada tam alternatiflenen ayağa aktarılıyor. **Aksan** = iniş + ayak-değişimi + kol-çırpması anının çakıştığı an.

### B) Gözlemlenebilir Hatalar
1. Gerçek bir sıçrama/uçuş fazı yok — ayak sıçramak yerine sadece adım gibi geri gidiyor (her iki ayağın da anlık olarak yerden kesilip kesilmediği kontrolü ile ölçülebilir).
2. Kollar "cıvık çırpma" yapmıyor, sabit kalıyor — karakteristik "askı" jesti kayboluyor (kol-salınım genliği yetersiz).
3. Geriye ilerleme yok — sıçrama yerinde kalıyor (kalçanın yatay yer değiştirmesi cümle boyunca yetersiz).
4. Bacaklar "cıvık" yerine gergin/düz (diz-fleksiyon osilasyonu beklenenden düşük — "cıvıklık" bir NİTELİK olduğu için tam ölçmek zor, minimum bir diz-fleksiyon-osilasyon genliği makul bir vekil, bu nüans not düşülmeli).
5. Sıçrama beat'in dışında.
6. Sol/sağ sıçrama genliği asimetrik.

### C) Ölçülebilirlik Değerlendirmesi
**Tier: A.** Büyük genlikli geri-sıçrama + tam ağırlık aktarımı + büyük kol-çırpması = çok-segmentli, büyük genlik. Bir sıçrama/ilerleme hareketi olması (ayak zaman zaman yerden kesiliyor) kısmen ayak-zemin-temas zamanlamasını gündeme getiriyor, AMA Running Man'in aksine bu bir KAYMA İLLÜZYONU değil — gerçek, büyük, belirgin bir sıçrama + kol çırpması. Kimliğin taşıyıcısı ince ayak-ucu zamanlaması değil, büyük eklem hareketleri → **A**, ayak-teması nüansı ikincil bir not olarak eklendi.

---

## 16. Butterfly

**Kaynaklar:** [DanceWithCeech — Butterfly](https://dancewithceech.com/blog/butterfly) (hareket mekaniği + açık hata, tek kaynak).

### A) Hareket Tarifi
Ayaklar omuz genişliğinde, ağırlık parmak-ucu toplarında. Dizler hafifçe bükülü, birbirine doğru İÇE sallanıyor, sonra DIŞA — akıcı bir içe-dışa hareket (kelebek kanadı benzetmesi). Dizler birbirine yaklaştıkça gövde hafifçe ÖNE eğiliyor; dizler ayrıldıkça gövde nötr/dik pozisyona dönüyor — **dizler ve gövdenin senkronize hareketi bu adımın çekirdek imzası**. Hareket sürekli/döngüsel (kaynak kesin beat numarası vermiyor — **çıkarım (UNVERIFIED):** döngü başına ≈2 beat). **Aksan** = dizlerin en yakın olduğu + gövdenin en öne eğik olduğu an ("kanatların kapandığı" imge).

### B) Gözlemlenebilir Hatalar
1. Gövde hareketi ihmal ediliyor — yalnız dizler hareket ediyor, gövde dik kalıyor (kaynağın kendi açık hatası: "yalnız dizler hareket ederse Butterfly boş/içeriksiz görünür" — gövde-fleksiyon genliği diz-hareketiyle eşleşmiyor).
2. Diz içe-dışa genliği çok küçük (zar zor hareket ediyor).
3. Gövde ve dizler faz-dışı — gövde öne eğilirken dizler ayrık, veya belirgin bir zamanlama gecikmesi var (diz-pozisyonu ile gövde-fleksiyonu arasındaki faz-farkı ölçülebilir).
4. Dikey (yukarı-aşağı) bir sıçrama yapılıyor, diz içe-dışa sıkışması yerine — Butterfly'ı jenerik bir bounce ile karıştırma (baskın hareket ekseninin dikey kalça-yer değiştirmesi mi yoksa diz ab/adduksiyonu mu olduğu kontrol edilerek ayırt edilebilir).
5. Hareket beat'in dışında.

### C) Ölçülebilirlik Değerlendirmesi
**Tier: A.** Dizlerin birlikte hareketi + gövdenin senkronize eğilmesi = çok-segmentli, makul-büyük genlik, ayak-ucu illüzyonuna DEĞİL gerçek diz/gövde açı-değişimine dayanıyor. Monastery ile iyi bir karşıtlık: Monastery yalnız parmak-topuk (küçük, illüzyon), Butterfly diz+gövde (büyük, gerçek eklem hareketi) — aynı "sürekli/döngüsel" yapıda olsalar da tier'leri tamamen farklı.

---

## 17. BK Bounce

**Kaynaklar:** [DanceWithCeech — BK Bounce](https://dancewithceech.com/blog/bk-bounce) (hareket mekaniği + Bankhead Bounce ile doğrudan kaynağın kendi karşılaştırması, tek kaynak).

### A) Hareket Tarifi
Ayaklar omuz genişliğinde, dizler hafif bükük. Temel bir diz-sıçraması (beat'e göre) kuruluyor. Ardından ayaklar alternatif olarak YANA adımlanıyor — önce sağ, sonra sol — ve adım atan tarafın kalçası hafifçe YUKARI kalkıyor (kalça-tilt). Adım atan ayağın TERSİ koldaki kol dışa sallanıyor (sağ ayak dışarı çıkarsa sol kol dışarı sallanıyor — bu setteki tekrarlayan kol-bacak opozisyon motifi). **Çıkarım (UNVERIFIED):** ≈2 beat'lik bir döngü (sıçrama + yan-adım birleşik). **Aksan** = yan-adımın + kalça-kalkışının + karşı-kol zirvesinin çakıştığı an.

**Kaynağın kendi karşılaştırması (önemli, doğrudan alıntı):** *"Her iki hareket de AYNI yan-adım bounce yapısını ve ritmik ağırlık-kayması kalıbını paylaşıyor,"* Bankhead Bounce yalnız Atlanta kökenli olmasıyla ayrılıyor. **Bu, BK Bounce ile Bankhead Bounce'ın gözlemlenebilir mekanik açıdan neredeyse AYNI olduğu anlamına geliyor** — bir skorlama motoru için ayırt edici sinyal çok zayıf olabilir; ayrım büyük ölçüde tarihsel/kültürel, biyomekanik değil. Bu, müfredat tasarımı için kurucuya iletilmesi gereken önemli bir bulgu.

### B) Gözlemlenebilir Hatalar
1. Yanal adım yok — ayaklar merkezi kalıyor, yalnız dikey sıçrama oluyor (BK Bounce'ı düz bir bounce'tan ayıran yana-hareket kayboluyor).
2. Kollar adım atan ayakla AYNI tarafta sallanıyor — ters tarafta değil (opozisyon imzası kayboluyor).
3. Yan-adıma eşlik eden kalça-kalkışı yok (kalça dikey/yanal tilt genliği yetersiz).
4. Adım beat'in dışında.
5. Sol/sağ adım genliği asimetrik.

### C) Ölçülebilirlik Değerlendirmesi
**Tier: A.** Çok-segmentli (sıçrama + kalça-tilt + alternatif kol-salınımı + yanal adım), büyük-orta genlik. Bankhead Bounce ile yapısal olarak eşleştirilmiş — bkz. yukarıdaki kaynak-alıntısı — ikisinin tier/hata profili neredeyse özdeş, yalnız BK Bounce'ın ek yanal-adım bileşeni onu Bankhead Bounce'tan bir adım daha karmaşık kılıyor.

---

## D) ÖĞRETİM SIRASI (yeni başlayan için, gerekçeli)

Sıralama üç kritere dayanıyor: **(1)** kaç vücut segmentinin eşzamanlı koordine edilmesi gerektiği, **(2)** temel `Bounce` adımına olan mesafe (aile-içi adımlar önce), **(3)** ilerleme/dönüş/çok-fazlı-sıralama gibi ek karmaşıklık katmanları. Tier C/bilinmiyor adımlar sona, gerekçeleriyle ayrı not edildi — bunlar `content/SCHEMA.md`'nin bağlayıcı kuralı gereği V1 müfredatına muhtemelen hiç girmeyecek.

1. **Bankhead Bounce** — temel `Bounce`'a en yakın varyant (aynı iki-diz mekaniği, yalnız daha küçük/"relaxed" genlik + isteğe bağlı kol). Yeni koordinasyon deseni yok, en yumuşak giriş.
2. **BK Bounce** — Bankhead Bounce'ın hemen üzerine, TEK yeni eleman ekliyor (yanal adım + kalça-tilt + karşıt kol). Kaynağın kendi ifadesiyle iki adım "aynı yapı"yı paylaşıyor, o yüzden art arda öğretmek doğal.
3. **Smurf** — yeni bir koordinasyon deseni (alternatif düz-kol daireleri) ama yalnız 2 unsur (kollar + sürekli sıçrama); temiz Tier A, bir kaynağın "en önemli temel adım" demesiyle motive edici.
4. **Cabbage Patch** — kol-dairesi + gövde-karşıt-eğimi (+ isteğe bağlı ayak-pedalı), Smurf'ten daha fazla unsur ama hâlâ tek-hücre tekrarlayan bir kalıp; en ikonik/tanınabilir adımlardan biri, 3 kaynakla en sağlam doğrulanmış.
5. **Stomp** — tam ağırlık-aktarımlı, perküsif bir vuruş mekaniği öğretiyor; bir sonraki adımın (ATL Stomp) ön-koşulu ("stomping bu tekniği çekirdek mekanik olarak kullanır" — kaynağın kendi ifadesi).
6. **ATL Stomp** — Stomp'un üzerine dönüş + kalça/kol stilini ekliyor, doğal bir sonraki adım.
7. **Steve Martin** — yeni bir düzlem (yanal bacak tekmesi) + kol-opozisyonu, tam ağırlık aktarımıyla; temiz Tier A.
8. **Bart Simpson** — Steve Martin'in "tekme+kol-opozisyonu" ailesine yakın ama bir kayma/ilerleme unsuru ekliyor (daha zor) — bu yüzden Steve Martin'den SONRA.
9. **Butterfly** — yeni bir düzlem (diz içe-dışa + gövde-senkronu), orta zorluk.
10. **Roger Rabbit** — gerçek bir sıçrama/uçuş-fazı + geriye ilerleme + büyük kol-çırpması gerektiriyor; sıçrama+ilerleme kombinasyonu önceki adımlardan daha talepkâr.
11. **Prep** — çok-fazlı (4 farklı mimik jest, sırayla) — her jest tek başına kolay ama SIRALAMA/HAFIZA yükü bu noktaya kadarki hiçbir adımda yoktu; bu yüzden geç.
12. **Reebok** *(kurucu kararı bekliyor — hangi varyant öğretilecek)* — STEEZY varyantı seçilirse, çok-beat'li + dönüşlü yapısı Prep'e yakın zorlukta veya biraz daha zor.
13. **Wop** *(Tier B/C — Harlem Shake emsaliyle muhtemel V1-dışı)* — eğer kültürel tamlık için yine de öğretilecekse, izolasyonlar gerçek hip-hop pedagojisinde de genelde İLERİ seviye sayılır (büyük-kas hareketlerinden sonra gelir) — hem CV-zorluk hem gerçek pedagojik zorluk aynı yöne işaret ediyor.
14. **Monastery** *(Tier C — muhtemel V1-dışı)* — eğer öğretilecekse, ince motor kontrolü (düşük genlik = aslında İYİ yapması zor, ölçmesi zor olmasından bağımsız bir zorluk) nedeniyle sona.
15-17. **Janet Jackson, Gucci, Wu-Tang** — **sıraya konulamıyor.** Kaynaklı bir hareket tarifi olmadan bu 3 adımı sıralamak, veriye dayanmayan bir tahmin üretmek olurdu. Yeni bir araştırma turu (veya bir eğitmenle doğrudan görüşme) olmadan bu boşluk kapanmaz.

---

## DOĞRULANAMAYANLAR

- **Janet Jackson** — hiçbir kaynakta hareket tarifi yok. Tek ipucu: bir YouTube yorumcusunun Prep bağlamında geçen "pre-Janet-Jackson amigo-kız rutini" yan-notu — bağlantı DOĞRULANMADI, gerçek olarak sunulmadı.
- **Gucci** — bağımsız bir tarif bulunamadı. Reebok ile isim-karışıklığı kanıtı var (pancocojams yorumları) ama bu, Gucci'nin ayrı bir hareket mi yoksa Reebok'un bölgesel bir takma-adı mı olduğunu KANITLAMIYOR, yalnız ihtimal olarak işaret ediyor.
- **Wu-Tang** — yalnız "hızlı/agresif" afekt bilgisi var, vücut mekaniği yok. FraGue listesinde iki kez (girdi #17 ve #41) görünmesi bir iki-varyant ihtimalini düşündürüyor ama açıklanmadı.
- **Wop** — sourced tek açıklama (nextmovedance) hangi döneme/versiyona ait belirsiz: eski-okul (1980'ler, iampro kursunun bağlamı) mı yoksa 2011 J. Dash şarkısı sonrası canlanan versiyon mu? İkisinin gerçekten farklı hareket edip etmediği de DOĞRULANMADI.
- **Monastery'nin tier-kritik iddiası** — "topuklar zar zor kalkar, illüzyon" ifadesi TEK kaynaktan (DanceWithCeech) geliyor; bu, Tier C kararının dayanağı olduğu için ikinci bir bağımsız kaynakla teyit edilmesi özellikle değerli olurdu.
- **Reebok'un "kanonik" versiyonu** — 3 kaynak 3 farklı hareket tarif ediyor; hangisinin öğretileceği bir araştırma sorusu değil, bir ürün/kurucu kararı.
- **Prep ↔ Janet Jackson amigo-kız bağlantısı** — tek bir yan-yorumdan geliyor, doğrulanmadı.
- **Bankhead Bounce'ın Michael Jackson/1995 MTV VMA tarihsel iddiası** — tek kaynaktan (DanceWithCeech), makul ama bağımsız doğrulanmadı; ihtiyatla kullanılmalı, ürün-içi metne "iddiaya göre" gibi bir çekince olmadan yazılmamalı.
- **Genel tek-kaynak uyarısı** — Bart Simpson, Smurf, ATL Stomp, Steve Martin, Monastery, Bankhead Bounce, Stomp, Butterfly, BK Bounce'ın hareket mekaniği yalnız DanceWithCeech'ten geliyor. Bu site gerçek bir dans-öğretim kaynağı (görevin "eğitmen sitesi/tutorial" barına uyuyor) ama yazılarında tekrarlayan bir şablon var (jenerik açılış/kapanış cümleleri, jenerik "15-20 dakika" öğrenme-süresi tahminleri) — bu, içeriğin YANLIŞ olduğu anlamına gelmiyor, ama ikinci bir bağımsız kaynakla çapraz-doğrulanana kadar "yüksek güven" yerine "tek-kaynaklı, makul" olarak ele alınmalı. Referans-take toplama aşamasında (bkz. `G1(c)` raporu, `reference.requiredTakes`) bu adımlar için ≥3 bağımsız eğitmen videosu şartı zaten bu riski azaltacak.
- **Ölçülebilirlik tier'leri genel olarak** — bu doküman bir İLK-GEÇİŞ (first-pass) değerlendirmesidir; `content/SCHEMA.md`'nin kendi diliyle, "insan-uzman turu öncesi ilk-geçiş denetimi" niteliğinde. Nihai tier ataması, referans video toplama + gerçek poz-modeli testiyle kalibre edilmelidir, yalnız bu dokümanla DEĞİL.
