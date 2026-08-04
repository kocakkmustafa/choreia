# R13 — `hh_bounce` aday havuzu + varyant-kimliği taraması (2026-07-30)

**Bu not hasat SONUÇLARINDAN ÖNCE yazıldı.** Sebebi R12'de kendi aleyhime
işaretlediğim şey: gerekçeyi sonucu gördükten sonra aramak post-hoc'tur. Hangi
adayın hangi riski taşıdığı burada ÖNCEDEN kayıtlı; hasat bitince bu tabloya
karşı okunacak.

## Neden bu adım

`hh_bounce` bugün **0 kanal** taşıyor — hip-hop'un tek referanssız temel adımı, ve
stilin `status`'ünü `comingSoon`'dan çıkaracak olan da bu. Adım `measurability.tier: A`
(diz fleksiyonu, hattın en güvenilir izlediği açı; ayak-ucu temas zamanlamasına
bağımlılık YOK) — yani ölçülebilirlik tarafında bilinen bir engel yok, eksik olan
tek şey eğitmen kanıtı. Adım config'i `requiredTakes: 6` istiyor (katalog §6.0:
minimum 3, tercih 6).

## Metadata triyajı (indirme ÖNCESİ)

`probe_candidates --step hh_bounce`, 9 aday:

| video | karar | kanal | süre | not |
|---|---|---|---|---|
| `AyzYABnWDEM` | ADAY | Versa-Style Street Dance | 250s | |
| `NWB9Y1_lZDQ` | ADAY | Thilanka Rathnayake | 294s | |
| `nOR1qEhpssg` | ADAY | O G Here | 312s | |
| `4BRd2E8vBic` | ADAY | JoeyTheJAM | 898s | |
| `l3r4bPhikGQ` | ADAY | Darren R. Wong | 684s | |
| `1IVtcoqMrBA` | GÖZDEN_GEÇİR | HipHopeace | 902s | uzun ders, segment seçimi ister |
| `DEWpw4n8Lkw` | GÖZDEN_GEÇİR | FitLara Dance | 1444s | uzun ders |
| `OPJKTQ0blc8` | RED | Darren R. Wong | 393s | kanal zaten sayıldı |
| `ltLE-Mya6fE` | RED | Versa-Style | 423s | kanal zaten sayıldı |

**5 aday / 5 AYRI kanal.** Sayım birimi eğitmen; aynı kanalın ikinci videosu
tekrar katar, kaynak katmaz (M-F-32/54) — iki RED tam olarak bu yüzden.

## Varyant-kimliği taraması (M-F-175) — ÖNCEDEN kaydedilen risk

Başlıklar üç adayın bounce'ı **tek başına öğretmediğini** söylüyor. Bu, salsa'da
`bqoNqA2hmE4`'ü yakan derleme riskinin aynısı: çok-hareketli bir videoda segment
bulucu, bounce yerine yanındaki hareketi seçebilir ve uzlaşmaya yabancı bir şekil
sokabilir.

| video | başlığın iddiası | risk sınıfı | hasat sonrası ne kontrol edilecek |
|---|---|---|---|
| `AyzYABnWDEM` | "Hip Hop Dance Basics — THE BOUNCE" | **saf** | — |
| `NWB9Y1_lZDQ` | "How to do Hip-hop Bounce?" | **saf** | — |
| `nOR1qEhpssg` | "Learn Bounce … **ve cool variations**" | **varyant** | seçilen segment temel bounce mı, varyasyon mı |
| `4BRd2E8vBic` | "How to **BOUNCE & ROCK**" | **derleme** | segment bounce mı, rock mu (rock = ağırlık aktarımı, diz sürücüsü DEĞİL) |
| `l3r4bPhikGQ` | "Bounce **w/ Cris Cross**" | **derleme** | segment bounce mı, criss-cross mu (ayak çaprazlama) |

**Hasat sırası bu tabloya göre seçildi:** saf olanlar önce (`AyzYABnWDEM` →
`NWB9Y1_lZDQ` → `nOR1qEhpssg`), derleme-riskliler sonra. Gerekçe: parti yarıda
kesilirse elde kalan ilk üç yine **≥3 bağımsız eğitmen** eder ve hiçbiri kimlik
şüphesi taşımaz — yani kesinti, referansı kurulamaz değil yalnız daha ince yapar.

## Kimlik doğrulaması nasıl yapılacak (ölçü, izlenim değil)

Adımın kendi faz tanımı bir kimlik testi veriyor: bounce `knee_flexion_mean`
tarafından sürülüyor (`top` >168°, `drop` azalan ≥40°/s, `bottom` …). Yani
seçilen segment gerçekten bounce ise **diz fleksiyonu baskın değişken** olmalı.
Rock ağırlık aktarımıdır, criss-cross ayak yerleşimidir — ikisi de bu imzayı
üretmez. Hasat sonrası her take için sorulacak:

1. `prepare_take` hangi pencereyi seçti, periyodu makul mü?
2. Seçilen pencerede diz fleksiyonu salınımı, uzlaşmadaki diğer take'lerle
   aynı büyüklük sınıfında mı?
3. Derleme-riskli iki aday, saf üçlünün kurduğu uzlaşmaya karşı **`bestDeg`**
   olarak aykırı mı? (R12'nin dersi: bu sayı zaten artefaktta yazılıyor ve
   OKUNMASI gerekiyor.)

**Aykırılık tek başına dışlama gerekçesi DEĞİLDİR** (uyuşmazlık gerekçe değildir,
M-F-47). Aykırı çıkarsa gereken şey bağımsız kanıt: başlığın kendi iddiası +
seçilen segmentin faz imzası. İkisi birlikte varsa dışlama isimli ve gerekçeli
olur; yoksa kaynak kalır ve tolerans genişler.

## Kapsam notu

Bu tur RM ve RR'yi de kapsıyordu. **RM'nin havuzu tükendi** (8 kanal: 4 referansta,
4'ü ölçülmüş gerekçeyle dışarıda — bkz. C-116), yani RM için de yeni arama
gerekiyor; bu notta yalnız `hh_bounce` var çünkü sıfırdan başlayan ve en yüksek
getirisi olan o. RR ayrı aramayı bekliyor (yapısal olarak yalnız hasatla çözülür,
C-116/R12).

---

# SONUÇLAR (2026-07-30, hasat sonrası)

**Yukarıdaki risk tablosu sonuçlardan ÖNCE yazıldı. Öngörüsü TERSİNE ÇIKTI, ve
bunu rasyonalize etmek yerine yazıyorum — ön-kaydın bütün değeri bu.**

## Hasat

| aday | indirme | çıkarım |
|---|---|---|
| `AyzYABnWDEM` | ✓ | ✓ |
| `NWB9Y1_lZDQ` | ✓ | ✓ |
| `l3r4bPhikGQ` | ✓ | ✓ |
| `nOR1qEhpssg` | ✗ HTTP 403 | — |
| `4BRd2E8vBic` | ✗ HTTP 403 | — |

403'ler ilk iki indirmeden SONRA başladı → içerik değil hız-sınırı imzası.
Üst üste zorlanmadı; sonraki turda gecikmeli yeniden denenir.

## Ölçüm — ve öngörünün tersine dönüşü

| take | R13 öngörüsü | seçilen segmentte diz aralığı | kalça-y 3sn MEDYAN | çapa |
|---|---|---|---|---|
| `AyzYABnWDEM` | **saf** | 14,5° / **10,9°** (std **1,7°**) | **0,029** | ankle-x |
| `NWB9Y1_lZDQ` | **saf** | 16,7° / 29,5° | 0,081 | ankle-x |
| `l3r4bPhikGQ` | **derleme riskli** | **47,2° / 55,1°** | 0,057 | ankle-x |
| *ZpTgAZBYNrU (RM, çalışan referans)* | — | *84,8° / 41,2°* | *0,086* | *ankle-y* |

**"Saf" dediklerim en ZAYIF sinyali, "derleme riskli" dediğim en GÜÇLÜ sinyali
verdi.** Öngörü başlıklara dayanıyordu; ölçüm başlığı doğrulamadı.

## Neden bu havuzdan referans KURULMADI

Üç kullanılabilir take var, `MIN_TAKES=3` sağlanıyor — ve buna rağmen referans
üretilmedi. Gerekçe üç ölçüm:

1. **Gürültü tabanı.** `AyzYABnWDEM`'in sağ diz std'si **1,7°**, hattın
   `MIN_TOLERANCE_DEG = 6,0°` tabanının altında. Bir karar ölçüsü kendi gürültü
   tabanının altında soru soramaz — bu take'in taşıdığı bilgi, taşıdığı
   gürültüden küçük.
2. **İki alet anlaşmıyor.** `measure_tempo` her üç take için de **`no_peak`**
   diyor; `prepare_take` ise periyot buluyor (1,37 / 0,9 / 1,7s). Bu tam olarak
   `-8W2bnjrhE0`'ı eleyen `tool-disagreement` sınıfı — kendi kovamızı yeni
   açtığımız sınıf.
3. **Adımın kendi faz tanımı karşılanmıyor.** `hh_bounce` fazları
   `knee_flexion_mean > 168°` (top) + azalan **≥40°/s** (drop) istiyor. Toplam
   diz aralığı 10,9-16,7° olan bir pencerede bu eşikler anlamlı ayrım üretmez.

**Bu havuzdan referans kurmak C-071'in tekrarı olurdu:** "araçlar başarılı çıktı
üretti ama referans kapanmamıştı."

## Açık soru — KOORDİNATÖRDE (ölçü tasarımı)

Ölçüm iki açıklamayı ayırt ETMİYOR:

- **(a) Çapa modeli bounce'a uymuyor.** Hattın çapası ayak bileğine bakıyor ve üç
  take'te de eksen **x** seçildi. Bounce ayaklar YERDE, hareket DİKEY ve diz
  sürücülü — RM'de çapa `ankle-y`. Yatay ayak hareketi için kurulmuş bir çapa,
  ayağı sabit bir harekette gürültüye kilitlenmiş olabilir; `AyzYABnWDEM`'in
  27 saniyelik, 0,976 periyodiklikli ama 10,9° genlikli penceresi buna benziyor
  (çok düzenli, çok küçük — konuşan eğitmenin hafif salınımı gibi).
- **(b) Bounce gerçekten küçük genlikli** ve tek-kamerada ölçülemeyecek kadar
  taban-yakını bir hareket.

İkisi farklı sonuçlar doğurur: (a) düzeltilebilir bir araç sınırı, (b)
`hh_bounce`'ın `measurability.tier: A` beyanının YANLIŞ olduğu anlamına gelir ve
adımın demo-only'ye taşınmasını gerektirir. **Ayırt etmenin yolu diz-sürücülü bir
segment bulucu denemek** (mevcut ayak-çapası yerine `knee_flexion_mean`) — bu bir
ölçü TASARIMI, yükseltme kuralı gereği bende değil.

`l3r4bPhikGQ`'nun güçlü sinyalinin bounce mi criss-cross mu olduğu da aynı
soruya bağlı: doğru segment bulucu olmadan hangi pencereyi ölçtüğümüzden emin
olamayız.

---

# SONUÇLAR — İKİNCİ TUR (2026-08-04, tam havuz)

**Ön-kayıt disiplini burada da geçerli:** devir promptunda İKİ dürüst son
ÖNCEDEN yazılıydı (temel *temizlendi* / temel *duruyor*). **Çıkan sonuç
ikisinden de değil** — ve bunu ikisinden birine yamamak, ön-kaydın engellemek
için var olduğu şeyin ta kendisi olurdu. Üçüncü son ayrıca yazılıyor.

Bir öncekinden farkı: 403'ler geçici çıktı, havuz **2 kullanılabilirden 5
ders-doğrulanmış kaynağa** yükseldi — yani `MIN_TAKES=3` bu adımda **ilk kez**
sağlandı. Referans yine kurulmadı, ama **gerekçe DEĞİŞTİ**.

## Zincir (prepare → classify → build → resolvedBy)

`prepare_take` — 7 aday, 6 hazır:

| take | durum | segment | periyot | çapa | not |
|---|---|---|---|---|---|
| `AyzYABnWDEM` | hazır | 27,0s | **1,37s** | x | |
| `NWB9Y1_lZDQ` | hazır | 6,0s | 0,90s | x | classify'da elendi |
| `l3r4bPhikGQ` | hazır | 9,0s | **1,70s** | x | |
| `nOR1qEhpssg` | hazır | 7,0s | **0,68s** | x | |
| `4BRd2E8vBic` | hazır | 3,0s | **0,71s** | x | |
| `1IVtcoqMrBA` | hazır | 14,0s | **1,27s** | x | |
| `DEWpw4n8Lkw` | **elendi** | 12,0s | 1,28s | — | *ankle swing too small (0,034 torso)* |

`classify_source` (fail-closed) — 6 hazırdan **5 `lesson`**:
`AyzYABnWDEM` 449 sözcük · `l3r4bPhikGQ` 2062 · `nOR1qEhpssg` 421 ·
`4BRd2E8vBic` 2070 · `1IVtcoqMrBA` 944. Elenen: **`NWB9Y1_lZDQ`**,
`performance`/`silence`, **0 sözcük** — C-119'daki ölçümün (transkript var
0 segment + volumedetect −12,8 dB: ses var, konuşma yok) bağımsız tekrarı.

## Referans NEDEN kurulmadı — bu kez ÜÇÜNCÜ gerekçe

`build_reference` **harmonik çelişki** kapısında durdu (C-032'nin iki-kat
tuzağının referans kurucuya ulaşmış hâli). Faz ekseni ancak her take AYNI
çevrimde kesilmişse take'ler arasında aynı şeyi anlatır:

| çift | oran |
|---|---|
| `nOR1qEhpssg` 0,68 ↔ `AyzYABnWDEM` 1,37 | **2,01×** |
| `4BRd2E8vBic` 0,71 ↔ `1IVtcoqMrBA` 1,27 | **1,79×** |
| `nOR1qEhpssg` 0,68 ↔ `1IVtcoqMrBA` 1,27 | **1,87×** |
| `4BRd2E8vBic` 0,71 ↔ `AyzYABnWDEM` 1,37 | **1,93×** |

Havuz iki harmonik aileye ayrılıyor: **UZUN** {1,27 · 1,37 · 1,70} ve
**KISA** {0,68 · 0,71}. Bu bir genlik sorunu DEĞİL, bir *birim* sorunu:
"bir çevrim" tek diz çöküşü mü, yoksa çöküş-çifti (2-count) mi?

**`low-amplitude-vs-family` temeli bu turda SINANMADI.** Sınanamaz da:
`statusBases` ancak kurulan bir artefakt üzerinde türetilir, kapı ondan
ÖNCE ateşledi. Devirdeki iki dürüst sonun ikisi de kurulmuş bir artefakt
varsayıyordu; o yüzden ikisi de bugün uygulanamaz. **Soru açık kalıyor.**

## Kapının kendi çaresi ÖLÇÜLDÜ — ve KAPALI çıktı

Kapı çareyi kendisi adlandırıyor: *"`measure_tempo` ile her take'in dönüşümlü
olup olmadığını belirle; yarım çevrime kilitlenenleri havuzdan çıkar."*
Çarenin **mevcut olup olmadığını varsaymadım, ölçtüm:**

| take | `measure_tempo` | çevrim | `prepare_take` | uyum |
|---|---|---|---|---|
| `AyzYABnWDEM` | `no_peak` | — | 1,37s | **hüküm YOK** |
| `4BRd2E8vBic` | `no_peak` | — | 0,71s | **hüküm YOK** |
| `l3r4bPhikGQ` | `non_alternating` | 0,867s | 1,70s | **~2× ÇELİŞKİ** |
| `nOR1qEhpssg` | `non_alternating` | 2,05s | 0,68s | **~3× ÇELİŞKİ** |
| `1IVtcoqMrBA` | `alternating` | 1,30s | 1,27s | ✓ uyuşuyor |

**5 take'in yalnız 1'inde iki alet aynı şeyi söylüyor.** İkisinde hakem
hüküm veremiyor, ikisinde hakem 2-3× farkla çelişiyor. Yani harmonik çelişki
"bazı take'ler yanlış kesilmiş" diye tekil bir arıza değil: **iki periyot
kestiricisi bu harekette birbirini doğrulamıyor**, ve hangisinin haklı
olduğunu söyleyecek üçüncü bir ölçü havuzda yok. C-116'da `-8W2bnjrhE0`
için açılan `tool-disagreement` sınıfı, bounce havuzunun **5'te 4'ünü**
kapsıyor.

## Kurulabilecek ALT KÜME VAR — ve bilerek KURULMADI

Aritmetik kontrol edildi (elle değil, betikle): UZUN grup
{`AyzYABnWDEM` 1,37 · `l3r4bPhikGQ` 1,70 · `1IVtcoqMrBA` 1,27} **n=3**,
kendi içinde harmonik çelişki **YOK**, üçü de `lesson` — yani
`MIN_TAKES=3`'ü sağlıyor ve **kapıdan geçerdi**.

**Kurmadım.** Gerekçe, geçen vardiyanın en pahalı dersinin doğrudan
uygulanması: kapıdan geçen alt kümeyi seçmek, *cevap veren grubu* seçmektir
— "N'in en uçtakini al" tuzağının kılık değiştirmiş hâli. Bir take'i
"yarım çevrime kilitlenmiş" diye atmak, hangi harmoniğin GERÇEK çevrim
olduğuna dair **bağımsız kanıt** ister; bugün o kanıt yok (yukarıdaki
tablo tam olarak bunu gösteriyor). Dışlama isimli VE bağımsız gerekçeli
olmalı (M-F-47); "kalanların uyuşması" bir gerekçe değildir.

**Üstelik elimdeki tek sezgi ters yöne işaret ediyor:** hip-hop bounce
tipik olarak vuruş-başına bir çöküştür; ~90-100 BPM'lik bir müzikte bu
0,60-0,67s eder — yani **KISA gruba** yakın, kurulabilecek alt kümeye
değil. Bunu ÖLÇMEDİM ve ölçüm yerine geçirmiyorum; buraya yazılma sebebi,
uygun alt kümeyi kurmanın neden özellikle riskli olduğunu göstermesi:
kolay yol, elimdeki tek bağımsız ipucuyla **çelişiyor**.

## R13'ün açık sorusu (a) GÜÇLENDİ — ama kanıtlanmadı

Birinci tur (a) "çapa modeli bounce'a uymuyor" ile (b) "bounce gerçekten
küçük genlikli" arasında ayrım yapamamıştı. Bu turda (a) lehine **üç
bağımsız işaret** birikti:

1. **`DEWpw4n8Lkw` tam çapa gerekçesiyle elendi:** *"ankle swing too small
   (0,034 torso)"*. Çapa ayak bileği AYRILMASI istiyor; bounce ayakları
   YERDE tutar. Çapa, hareketin tanımlayıcı özelliğini gürültü sayıyor.
2. **6 hazır take'in 6'sı da `x` ekseni seçti** — yatay. Bounce dikey ve
   diz sürücülü; çalışan RM referansı `ankle-y` seçiyor.
3. **İki periyot kestiricisi 5'te 4 take'te uyuşmuyor** — dikey bir
   hareketi yatay ayak yolculuğundan okumaya çalışan bir hattın
   üreteceği imza budur.

Üçü de aynı yöne bakıyor, ama hiçbiri (b)'yi ÇÜRÜTMÜYOR: gerçekten
taban-yakını bir hareket de kararsız periyot üretebilir. **Ayırt edecek
ölçü hâlâ aynı: adımın kendi faz tanımına (`knee_flexion_mean` top >168°,
drop ≥40°/s) dayanan diz-sürücülü bir segment bulucu** — bir çevrimde KAÇ
diz çöküşü olduğunu saymak harmonik soruyu da doğrudan keserdi. Bu bir
ölçü TASARIMI; yükseltme kuralı gereği bende değil, **koordinatörde**.

## Yan bulgular (kayda geçsin)

- **8. fixture `Ns5TaVGv6uY` zincire ALINMADI.** Provenans sınavı:
  *"10 Minute Salsa Basic Steps Practice Routine"* (Dance Dojo) — `hh_bounce`
  adayı değil, R13 triyaj tablosunda da yok. **Manifest'i `reference_eligible:
  true` diyor** — ve tam bu yüzden o alan girdi olarak kullanılamaz:
  bayrak adım-agnostik, hip-hop bir referansa salsa kaynağı sokardı
  (M-F-218/221'in somut kanıtı, artık varsayım değil).
- **Zincir manifest-BAĞIMSIZ olduğu ÖLÇÜLDÜ:** `prepare_take`,
  `build_reference`, `classify_source`, `movement_isolator`,
  `camera_angle_gate` dosyalarında `manifest|rom_mode|reference_eligible`
  taraması **tek isabet** verdi, o da bir YORUM satırı. Vendored-rig
  dönemi karar-alanları bu hattan yapısal olarak erişilemez.
  *(Küçük bakım notu: `build_reference.py:1013` yorumu `classify_source`
  için "manifest/transcript okur" diyor; gerçekte `transcripts/` +
  `raw/*.info.json` okuyor — yorum bayat, kod doğru.)*
- **`1IVtcoqMrBA` `lesson` hükmünü tek öğretim işaretiyle aldı** (944
  sözcük içinde 1 marker). Kapının kendi kuralı bu ve ezmedim; yalnız
  havuzun en ince kanıtlı `lesson` kaydı olduğu kayda geçiyor.
- İndirme YAPILMADI — zincir tamamen disk işiydi (hasat slotu JabLab'da).

## Sonuç cümlesi

`hh_bounce` bugün de kurulmadı, ama **üçüncü kez farklı bir duvarda**:
C-117 gürültü tabanı · C-119 kaynak sayısı · **bugün harmonik birim
belirsizliği**. Kaynak sayısı artık engel DEĞİL (5 ders-doğrulanmış kanal).
Kalan tek engel bir ölçü sorusu, ve o soru koordinatörde.

---

# ÖN-KAYIT — diz-sürücülü bulucu (2026-08-04, ÖLÇÜMDEN ÖNCE)

**Bu bölüm bulucu KOŞULMADAN önce yazıldı ve AYRI commit'lendi** — sıranın
kanıtı git geçmişinde, benim beyanımda değil (M-F-191). Koordinatör hükmü
M-F-226, şart 4.

## Ölçülecek soru

Harmonik BİRİM: `hh_bounce`'ta bir çevrim **tek diz çöküşü** mü, **çöküş çifti**
mi? Havuz ikiye ayrılmıştı — KISA {0,68 · 0,71s} ↔ UZUN {1,27 · 1,37 · 1,70s}.

## İki uç — ÖNCEDEN yazılı, hangisi çıkarsa rasyonalize EDİLMEYECEK

- **KISA temel:** kanonik çevrim = tek çöküş. UZUN take'ler çevrim başına **2**
  çöküş taşır → çift-birime kilitlenmişlerdir, birim damgası "tek çöküş" olur.
- **UZUN temel:** kanonik çevrim = çöküş çifti. KISA take'ler çevrim başına **1**
  çöküş taşır → yarım-birime kilitlenmişlerdir, birim damgası "çift çöküş" olur.

**Üçüncü çıkış (dürüst duruş, şart 7-ii):** ≥2/5 take `indeterminate` çıkarsa
birim ÇÖZÜLMEZ, `hh_bounce` açık kalır, koordinatöre dönülür.

**Dördüncü çıkış (ayrıca ön-kayıtlı):** config'in `top` kapısı (>168°) hiçbir
take'te sağlanmazsa, bu "çöküş yok" demek DEĞİL — "tam ekstansiyona hiç
çıkılmıyor" demektir ve R13 açık sorusu **(b)** lehine (tier-A beyanı yanlış,
K10 demo-only yolu) ölçülmüş kanıt olur. Bu ihtimal şimdi yazılıyor ki çıkarsa
sonradan icat edilmiş görünmesin.

## ÖNSEL — ölçüm DEĞİL, ve ölçüm yerine GEÇMEZ

Bir önceki tur BPM ipucunu kaydetmiştim (vuruş-başına çöküş ~0,60-0,67s →
KISA). Bugün buna **config-kaynaklı ikinci bir önsel** eklendi:

> `hh_bounce.json` → **`beats: 1`**, **`countLabels: ["1"]`**, ve faz zinciri
> `top → drop → bottom → rise` (`rise` **terminal**) = **çevrim başına TEK
> çöküş.**

Yani adımın KENDİ sözleşmesi kanonik birimi zaten tek-çöküş olarak tanımlıyor.
**Bu, hangi take'lerin o birimde KESİLDİĞİNİ söylemez** — ölçülecek olan tam
olarak budur. İki önsel de KISA'yı işaret ediyor; **ikisi de kanıt sayılmayacak**
ve sonuç UZUN çıkarsa öndeki bu satırlar SİLİNMEYECEK, yanlış çıkmış önsel
olarak kalacak.

## Doğrulama üçlüsü (şart 3) — hüküm ÖNCESİ geçilmesi zorunlu

- **(a) Sentetik:** bilinen çöküş sayısı · **çöküşsüz** kontrol · gürültülü
  kontrol · **dropout/NaN kontrolü** (sahte, ARIZA KİPİNİ taklit eder — imzayı
  değil; C-115 dersi).
- **(b) Yapısal genellik — İKAME BEYANI:** hüküm "RM'nin KENDİ sürücüsü" diyor,
  ama **RM'nin adım config'i repoda YOK** (`content/styles/*/steps/` altında
  yalnız `hh_bounce.json` var; RM'in yalnız referans artefaktı mevcut). Tek
  diğer config'li adım `ss_shine_footwork` **`cyclePhaseNear`** ile sürülüyor —
  kinematik metrik değil, faz-bin. Yani **`hh_bounce` repodaki TEK
  kinematik-sürücülü adım**; M-F-195'in burada ısırmasının sebebi de bu.
  İkame: mekanizma RM'nin **kabul edilmiş take'lerinde** koşulur ve RM'nin
  **artefakta kayıtlı** çevrim yapısını (periyot 1,2 · 1,21 · 1,67 · 1,38s)
  geri verip vermediğine bakılır. **Sınırı yazılı:** bu periyotlar
  `prepare_take`'in ayak-çapasından gelir, yani "bağımsız hakikat" değil
  *hattın kendi kabul ettiği doğru*; test, mekanizmanın bounce'a özel
  ayarlanmadığını gösterir, mutlak doğruluğu değil.
- **(c) Yarı-bilinen:** `1IVtcoqMrBA` — iki aletin uyuştuğu TEK take
  (`measure_tempo` 1,30 ↔ `prepare_take` 1,27s).

**Bu üçlü geçmeden itiraz-konulu take'lere verdikt YOK.**

## Parametre kaynakları (şart 1) — hangi sayı nereden

| parametre | değer | kaynak | damga |
|---|---|---|---|
| `top` giriş açısı | >168° | `hh_bounce.json` faz `top` | **config** |
| çöküş/yükseliş hız eşiği | ≥40°/s | `hh_bounce.json` fazlar `drop`/`rise` | **config** |
| dip = yerel minimum | — | `hh_bounce.json` faz `bottom` (`localMinimum`) | **config** |
| minimum çöküş derinliği | 6,0° | `build_reference.MIN_TOLERANCE_DEG` | **hat sabiti** — uydurulmadı; sert kural gereği bir karar ölçüsü kendi gürültü tabanının altında soru soramaz |
| açı tanımı | — | `prepare_take.joint_series` (İÇE AKTARILIR) | **tek kaynak** (M-F-03) |

Config'te olmayan hiçbir eşik icat edilmedi; tek hat-sabiti yukarıda isimle
ve gerekçesiyle beyan edildi.
