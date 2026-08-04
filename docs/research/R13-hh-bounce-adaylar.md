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

---

# SONUÇLAR — ÜÇÜNCÜ TUR (2026-08-04, diz-sürücülü bulucu)

**Ön-kayıt `7bb6936`'da, bu ölçümden ÖNCE commit'lendi.** Aşağısı o kayda karşı
okunmalı. Koordinatör hükmü M-F-226.

## Doğrulama üçlüsü — hüküm ÖNCESİ (şart 3)

### (a) Sentetik: 15/15 — ama ÖNCE İKİ GERÇEK HATA DÜŞÜRDÜ

Bilinen-cevaplı girdi işini yaptı ve **ilk koşumda 6 iddia kırıldı.**

**Hata 1 — sayıcı her seride TAM BİR ÇÖKÜŞ EKSİK sayıyordu.** `_extrema` baştaki
ucu hiç eklemiyordu (yön henüz kurulmamışken ilk nokta düşüyordu): 4/8/12 çöküşlü
sentetik girdiler **3/7/11** dönüyordu. Gerçek take'lerde bu **1 fark** olarak
görünürdü — yani birim hükmünü sessizce bozardı ve hiçbir yerde "hata" gibi
durmazdı. Bilinen-cevaplı girdi olmasaydı yakalanmazdı.

**Hata 2 — test yanlıştı, kod değil.** "±4° gürültü sahte çöküş imal eder"
diye yazmıştım; ölçtüm, **etmiyor**. Testi iddiama göre değil ölçüme göre
yeniden yazdım ve gürültü sınırını ÖLÇTÜM:

| gürültü | ortanca \|Δ\| | sahte çöküş |
|---|---|---|
| ±2° | 1,27° | 0 |
| ±4° | 2,54° | **0** |
| ±6° | 3,81° | **13** |
| ±8° | 5,09° | 20 |
| ±20° | 12,71° | 37 |

Kanarya artık **iki yönlü**: sağlamlık kaybolursa da, kırılma noktası kaybolursa
da düşer (ikincisi eleme fazla agresifleşti = gerçek çöküşleri yiyor demektir).

**Gerçek take'lerin artığı bu sınıra karşı okundu — hepsi GÜVENLİ bölgede:**
`AyzYABnWDEM` 0,21° · `4BRd2E8vBic` 0,32° · `nOR1qEhpssg` 0,41° ·
`1IVtcoqMrBA` 0,52° · `l3r4bPhikGQ` 0,53° (sınır 3,81°). **Yani aşağıdaki
çöküş sayıları gürültü artefaktı DEĞİL.**

### (b) Yapısal genellik — RM, ve sonuç ÖĞRETİCİ çıktı

İkame ön-kayıtta beyan edilmişti (RM'in adım config'i repoda yok). Mekanizma
RM'in **kabul edilmiş** 4 take'inde koşuldu; `prepare_take` RM'in artefakta
kayıtlı periyotlarını birebir yeniden üretti (1,2 · 1,21 · 1,67 · 1,38s).

| RM take | atanan | çöküş aralığı | oran | verdikt |
|---|---|---|---|---|
| `KV-sxd_pQ9w` | 1,20s | 0,601s | **2,00** | two-dip |
| `UO9Ehsdt2IE` | 1,21s | 0,625s | **1,94** | two-dip |
| `Wd29rBfAzkI` | 1,67s | 0,792s | **2,11** | two-dip |
| `ZpTgAZBYNrU` | 1,38s | 0,396s | 3,48 | indeterminate |

**3/4'te oran ≈ 2,0 — ve bu DOĞRU cevap.** Running Man **dönüşümlü** bir adım:
bir tam çevrim = sol bacak + sağ bacak = `knee_flexion_mean`'de **iki** çöküş.
Mekanizma, kabul edilmiş bir referansta fizyolojik olarak doğru çevrim yapısını
2,00/1,94/2,11 hassasiyetinde geri verdi — bounce'a özel ayarlanmadığının kanıtı.
Aykırı `ZpTgAZBYNrU` isimle kayıtlı: dördü içinde **çapası `x` seçen tek take**
(diğer üçü `ankle-y`) ve **kapsamı en düşük olan** (0,694).

**Ve bu doğrulama bir YORUM KURALI üretti:** oran ≈ 2,0 tek başına "yanlış
kesilmiş" demek DEĞİLDİR — dönüşümlü bir adım için çevrim başına iki çöküş
KANONİK birimdir. Aynı sayı, adımın beyan ettiği birime göre farklı şey anlatır.
`hh_bounce` `beats: 1` + terminal `rise` ile tek-çöküş beyan ediyor; RM etmiyor.

### (c) Yarı-bilinen: `1IVtcoqMrBA`

İki aletin uyuştuğu tek take. Sonuç: **one-dip**, oran **1,06** (atanan 1,27s /
çöküş aralığı 1,20s), `topQualified` 10/10. Uyuşan take temiz cevap verdi.

**Üçlü geçti** → itiraz-konulu take'lere hüküm verilebilir.

## Verdikt tablosu — 5 bounce take'i

| take | atanan | segment çöküş | çöküş aralığı | oran | **verdikt** |
|---|---|---|---|---|---|
| `1IVtcoqMrBA` | 1,27s | 10 | 1,200s | 1,06 | **one-dip** |
| `nOR1qEhpssg` | 0,68s | 7 | 0,758s | 0,90 | **one-dip** |
| `AyzYABnWDEM` | 1,37s | 6 | 2,034s | 0,67 | indeterminate |
| `l3r4bPhikGQ` | 1,70s | 18 | 0,400s | 4,25 | indeterminate |
| `4BRd2E8vBic` | 0,71s | **0** | — | — | indeterminate |

**Sayım: 2 one-dip · 3 indeterminate → şart 7-ii eşiği (≥2/5) AŞILDI.**

## Ön-kayda karşı okuma — ve ÖN-KAYDIN KENDİSİ YANLIŞ SORU SORMUŞ OLABİLİR

Ön-kayıt iki uç yazmıştı: **KISA temel** (çevrim = tek çöküş) vs **UZUN temel**
(çevrim = çift çöküş). **İkisi de ilan EDİLEMİYOR** — 3/5 belirsiz. Ama belirli
çıkan ikisi şunu söylüyor, ve bu ikisinin de öngörmediği bir şey:

> `nOR1qEhpssg` (atanan **0,68s**) → **one-dip**
> `1IVtcoqMrBA` (atanan **1,27s**) → **one-dip**

**İkisi de tek-çöküş, ama atanan periyotları 1,87× farklı.** Eğer ikisi de
gerçekten çevrim başına bir çöküş taşıyorsa, aradaki 2× fark bir **BİRİM**
farkı değil **TEMPO** farkıdır — biri ~0,76s/çöküş (~79 BPM), diğeri
~1,20s/çöküş (~50 BPM, yavaş öğretim gösterimi; bir eğitmenin "yavaşça, şöyle"
demesi tam olarak böyle görünür).

Bu doğruysa **harmonik kapı yanlış şeyi yakalamış olur**: kapı 2× periyot
oranını "farklı çevrimde kesilmiş" diye okuyor, ama aynı imzayı *aynı birimde,
farklı tempoda* dans eden iki eğitmen de üretir. Kapı bu ikisini AYIRT ETMİYOR.

**BUNU KANITLANMIŞ SAYMIYORUM — n=2.** Geçen vardiyanın dersi tam da bu:
sayı üreten ama dağılımı yetmeyen ölçü hüküm veremez. Ön-kaydımın ikili
çerçevesi (KISA mı UZUN mu) muhtemelen **yanlış soruydu**, ve bunu "önselim
doğru çıktı" diye okumak da aynı hata olurdu: iki önselim de KISA'yı işaret
ediyordu, ama çıkan şey "KISA doğru" değil **"ikisi de aynı birimde olabilir"**.
Önseller silinmedi, yukarıda duruyorlar.

## Ön-kayıtlı DÖRDÜNCÜ çıkış GERÇEKLEŞMEDİ — ve bu (b)'nin aleyhine

Ön-kayıt "`top` kapısı (>168°) hiç sağlanmazsa bu (b) lehine kanıttır" demişti.
**Sağlanıyor:** `1IVtcoqMrBA` 10/10 · `nOR1qEhpssg` 7/7 · `AyzYABnWDEM` 6/6 ·
`l3r4bPhikGQ` 17/18 · `4BRd2E8vBic` (tüm take) 190/193.

Yani take'lerde **config'in kendi eşiklerini geçen, ≥6° derin, ≥40°/s hızlı,
tam ekstansiyondan başlayan GERÇEK çöküşler var.** R13 açık sorusu **(b)**
("bounce gerçekten ölçülemeyecek kadar taban-yakını") bu ölçümle
**DESTEKLENMİYOR**. `measurability.tier: A` beyanına bu turda karşı kanıt çıkmadı.

## (a) LEHİNE yeni ve daha keskin kanıt: segment-take TUTARSIZLIĞI

Belirsizliğin nereden geldiğini ölçtüm — ve örüntü tek yöne bakıyor:

| take | TÜM take aralığı | SEGMENT aralığı | SEG/TÜM | verdikt |
|---|---|---|---|---|
| `1IVtcoqMrBA` | 0,900s | 1,200s | **1,33** | one-dip |
| `nOR1qEhpssg` | 0,683s | 0,758s | **1,11** | one-dip |
| `AyzYABnWDEM` | 0,967s | 2,034s | **2,10** | indeterminate |
| `l3r4bPhikGQ` | 0,567s | 0,400s | **0,71** | indeterminate |
| `4BRd2E8vBic` | 1,125s | — | **segmentte 0 çöküş** | indeterminate |

**Verdikt belirliliği, segmentin take'in geneliyle tutarlılığını İZLİYOR.**
Belirli çıkan ikisinde segment take'e benziyor (1,33 · 1,11); belirsiz üçünde
ayrışıyor (2,10 · 0,71 · hiç).

En çarpıcısı **`4BRd2E8vBic`**: tüm take'te 1,125s aralıkla **193 çöküş** var,
ama `prepare_take`'in seçtiği **3,0 saniyelik** segmentte **SIFIR** nitelikli
çöküş. Segment 3 çevrim taşıdığını iddia ediyor. Yani ayak-çapalı bulucu, bol
bol bounce içeren bir videoda **bounce İÇERMEYEN bir pencere seçmiş.**

Bu, R13 açık sorusu **(a)** için birinci turdakinden çok daha keskin bir kanıt:
artık "çapa şüpheli" değil, **çapanın seçtiği pencerede aranan olayın olmadığı
ölçülmüş** durumda. n=5, yani örüntü — kanun değil.

## Sonuç: ŞART 7-ii — DÜRÜST DURUŞ

3/5 belirsiz olduğu için **birim ÇÖZÜLMEDİ**, referans yeniden kurulmadı, birim
damgası konulmadı, `low-amplitude-vs-family` temeli **hâlâ sınanmadı** (kurulan
artefakt yok). `hh_bounce` **AÇIK kalıyor**, karar koordinatörde.

**Ama bu tur boş dönmedi** — dört şey kazanıldı:
1. **Doğrulanmış bir ölçü aleti** (11 kapı yeşil, gürültü sınırı ölçülü, RM'de
   genelliği kanıtlı, iki gerçek hatası bilinen-cevaplı girdiyle yakalanmış).
2. **Belirsizliğin ADI kondu:** üçü de segment-seçimi kaynaklı, ikisi tempo
   farkıyla açıklanabilir. "Bilmiyoruz" değil, "şu üç take'te şu sebeple
   bilmiyoruz".
3. **(b) aleyhine ölçüm** — tier-A beyanına karşı kanıt yok, aksine config'in
   kendi eşiklerini geçen gerçek çöküşler var.
4. **(a) lehine keskin kanıt** — çapa, bounce içermeyen pencere seçebiliyor
   (`4BRd2E8vBic`: 193 çöküşlü videoda 0 çöküşlü segment).

**Koordinatöre giden asıl soru DEĞİŞTİ:** artık "birim hangisi" değil,
**"segment bulucu diz-sürücülü hâle getirilmeli mi"** — çünkü belirsizliğin
üçü de birim belirsizliğinden değil, PENCERE seçiminden geliyor. Bu bir ölçü
tasarımı; bende değil.

---

# DÖRDÜNCÜ TUR — faz-sürücülü segment seçimi (2026-08-04, M-F-231)

**Zincir KOŞULMADI.** Şart 4 açıkça "üçlü geçmeden zincir koşulmaz" diyor ve
**(a) kabul testi DÜŞTÜ**. Aşağısı üçlünün sonucu ve düşmenin teşhisidir.
Ön-kayıt da yazılmadı: koşmayacak bir turun iki ucunu yazmak ön-kaydı
törene çevirirdi.

## Değişiklik — ARAMA UZAYINA değil SIRALAMAYA

`prepare_take` artık adım config'i **kinematik çevrim birimi beyan ediyorsa**
segmenti faz-sürücüsüyle seçiyor. Aday üretimi (hareket ∩ kamera-temiz)
**aynen duruyor**; değişen iki şey:

1. **Sıralama:** eski `max(periyodiklik, uzunluk)` yerine **nitelikli çöküş
   sayısı**, sonra uzunluk.
2. **Periyot türetimi:** `çöküş aralığı × beyanEdilenÇöküş/çevrim`.

Config'e `cycleUnit` alanı eklendi (`driver: knee_flexion_mean`,
`dipsPerCycle: 1`, `derivedFrom: phases`, gerekçeli). Birim **BEYAN EDİLİR**,
bulucu tarafından çıkarsanmaz — böylece take'ler arası periyot yayılımı
**TEMPO varyansı** olarak okunur, birim çatışması olarak değil (M-F-231/3).

## Doğrulama üçlüsü

### (b) BİT-DEĞİŞMEZLİK — GEÇTİ 3/3, ama önce GERÇEK bir regresyon yakaladı

Kabul edilmiş üç shine take'i, `git show HEAD:tools/prepare_take.py` ile
çıkarılan ESKİ sürüme karşı koşuldu:

| take | eski sha256 | `--step`siz | `--step ss_shine_footwork` |
|---|---|---|---|
| `SHGkSbJm2Iw` | `3074fdeef6774569` | **AYNI** | **AYNI** |
| `jjP8bKWCg9U` | `6c8a95557b7c46e3` | **AYNI** | **AYNI** |
| `w4opJ2ezmd4` | `20669dae27528c1b` | **AYNI** | **AYNI** |

**İlk koşumda ÜÇÜ DE FARKLIYDI.** Sebep tek satırdı: çıktı sözlüğüne
koşulsuz `"cycleUnit": null` koymuştum. **Yok olan alan ile null olan alan
aynı şey değildir** — bu deponun keyset kapısında (C-114) "boşalma ≠ kayıp"
diye öğrendiği ayrımın aynısı, bu kez üretici tarafında. Alan artık yalnız
faz-sürücülü seçim gerçekten koştuğunda yazılıyor; **yokluğu "segment eski
yolla seçildi" anlamına geliyor.** Bit-değişmezlik iddia değil, regresyon
diff'iyle KANIT.

### (c) SENTETİK — GEÇTİ

`prepare_take --self-test` 0 · `probe_knee_dips --self-test` 15/15 · 11/11
Python kapısı 0.

### (a) `4BRd2E8vBic` KABUL TESTİ — **DÜŞTÜ**

Kriter: yeni pencere nitelikli çöküş İÇERMEK zorundaydı. İçermiyor — take
artık **isimli gerekçeyle eleniyor**: *"aday pencerelerin hiçbirinde nitelikli
`knee_flexion_mean` olayı yok (faz-sürücülü seçim)"*.

**Teşhis: darboğaz SIRALAMADA değil, bir katman YUKARIDA — ADAY ÜRETİMİNDE.**

`4BRd2E8vBic` **896 saniyelik** bir ders ve tüm take'te **193 nitelikli çöküş**
var, **67s ile 860s arasına yayılmış**. Ama `find_movement_windows` bu videoda
yalnız **5 pencere** buluyor, toplamı ~34 saniye (**videonun ~%3,8'i**):

| pencere | süre | periyodiklik | nitelikli çöküş |
|---|---|---|---|
| 190-196s | 6s | 0,741 | **0** |
| 567-575s | 8s | 0,628 | **0** |
| 444-452s | 8s | 0,593 | **1** |
| 282-288s | 6s | 0,586 | **0** |
| 368-374s | 6s | 0,502 | **0** |

Tek çöküş içeren pencerede aralık HESAPLANAMAZ (iki çöküş gerekir), dolayısıyla
aday kalmıyor. **Yani bounce'la dolu bir videoda, aday havuzunun kendisi
bounce'ı içermiyor.** Sıralamayı düzeltmek bu take'i kurtaramaz çünkü sıralanacak
doğru aday hiç üretilmemiş.

## SIRALAMA DÜZELTMESİ ÇALIŞIYOR — ve kanıtı `DEWpw4n8Lkw`

Aynı ölçüm, düzeltmenin gerçek olduğunu da gösteriyor. `DEWpw4n8Lkw` (1434s,
771 çöküş, 29 hareket penceresi):

| pencere | periyodiklik | nitelikli çöküş |
|---|---|---|
| 915-927s | **0,932** (en yüksek) | **0** |
| 654-664s | 0,929 | **0** |
| 263-275s | 0,920 | 1 |
| 321-347s | 0,809 | **18** |

**ESKİ sıralama (max periyodiklik) çöküşü OLMAYAN pencereyi seçerdi.** Yeni
sıralama 18 çöküşlü pencereyi seçiyor. Bu, "düzenlilik doğru olayın orada
olduğunu göstermez" tezinin doğrudan ölçümü.

**Ve `DEWpw4n8Lkw` GERİ KAZANILDI:** ayak-çapası onu *"ankle swing too small
(0,034 torso)"* diyerek TAMAMEN elemişti (C-123). Faz sürücüsüyle artık
**hazır** (17 çöküş, 0,76s aralık, 15/17 topQualified) ve `classify_source`
onu **`lesson`** veriyor — **2468 sözcük, 7 öğretim işareti**, havuzun en
konuşkan kaynağı. Ayak-çapasının çöpe attığı şey, en güçlü ders kaynağıymış.

## Yan sonuç: periyotlar TOPLANDI, tek aykırı R13'ün ön-işaretlediği take

Faz-sürücülü periyotlar (ders-doğrulanmış take'ler):

| take | periyot | not |
|---|---|---|
| `l3r4bPhikGQ` | **0,400s** | ~150 BPM — R13 triyajında **"derleme riskli"** işaretli |
| `nOR1qEhpssg` | 0,725s | |
| `DEWpw4n8Lkw` | 0,760s | **yeni kazanılan** |
| `1IVtcoqMrBA` | 1,200s | |
| `AyzYABnWDEM` | 2,034s | |

**Kalan 2× çatışmaların İKİSİ DE `l3r4bPhikGQ` kaynaklı** (0,4↔0,725 = 1,81 ·
0,4↔0,76 = 1,90). Diğer dördü arasında 2× çatışma **YOK**. Yani faz-sürücülü
periyot türetimi havuzun 4/5'ini harmonik uyuma getirdi, ve tek aykırı R13'ün
hasattan ÖNCE "bounce mu criss-cross mu" diye işaretlediği take.

**Bunu "çözüldü" saymıyorum:** `l3r4bPhikGQ`'nun 0,4s'si gerçek bir hızlı
bounce da olabilir, criss-cross ayak çalışması da. Ayırt etmek için segment
kimliği gerekir, ki o da aday üretimi sorusuna bağlı.

## KOORDİNATÖRE — darboğaz ADLANDIRILDI

Faz sürücüsü **seçim** katmanına indi ve orada işini yapıyor. Kalan sorun
**aday üretimi**: `find_movement_windows` hareket-enerjisi/ayak sürücülü ve
diz-sürücülü bir adımda pencereleri kaçırıyor (`4BRd2E8vBic`: %3,8 kapsam;
`AyzYABnWDEM`: 10 çöküşlü 163-185s penceresi var ama kamera kapısını geçmiyor).

**`movement_isolator.py` VENDORED** (pin `eb28039`, `--drift-check`'li) — yani
orayı diz-sürücülü yapmak aile-düzeyi bir karar, bende değil. App düzeyinde
alternatif bir aday üreteci yazmak da yeni ölçü tasarımıdır. **Karar sende.**

---

# BEŞİNCİ TUR — aday üretimi rig'de faz-sürücülü (2026-08-04, M-F-235)

**Zincir KOŞULMADI:** şart 6 zinciri MERGE SONRASINA bağlıyor. Aşağısı dalın
kanıt dosyası. Rig dalı: `feat/isolator-kinematic-driver` @ **`5054426`**
(motion-core, push'lu, merge kararı koordinatörde).

## Rig değişikliği — alan sözlüğü PARAMETREYLE

`find_movement_windows` iki opsiyonel parametre kazandı:
`driver_series` (çağıranın verdiği kare-başına skaler) ve `min_amplitude`
(sürücünün KENDİ birimindeki genlik tabanı). **Rig hangi eklem, hangi adım,
hangi birim olduğunu öğrenmiyor** — yalnız verilen sinyali pencereliyor.

**Hiçbir ölçünün ikinci uygulaması yazılmadı:** skaler sürücü, 1 boyutlu
vektör serisidir; `_motion_energy` ve `_periodicity` **değiştirilmeden**
yeniden kullanıldı (`dim` zaten çalışma anında okunuyordu).

Choreia tarafında iki değer de **config'ten** geliyor: sürücü
`knee_flexion_mean`, taban **12°** — adımın kendi `NO_BOUNCE` hatasının
eşiği, notu birebir *"öğrenci müziğe kıpırdamadan duruyor"*. İcat edilmedi.

## Doğrulama üçlüsü — rig düzeyi

**Varsayılan yol BİT-DEĞİŞMEZ (5/5 gerçek take, alan alan karşılaştırma):**
`SHGkSbJm2Iw` · `jjP8bKWCg9U` · `AyzYABnWDEM` · `4BRd2E8vBic` ·
`DEWpw4n8Lkw` — eski/yeni pencere listeleri birebir aynı. Parametreler
varsayılanda no-op olduğu için bu "beklenti" değil, **aynı girdilerle aynı kod**.

| test | sonuç |
|---|---|
| **(a)** `4BRd2E8vBic` çöküş-yoğun bölge kapsanıyor | ✓ **5→8 pencere, SEKİZİNİN DE ≥2 çöküşü var** (eskiden dördünde 0, birinde 1 → aralık hesaplanamıyordu) |
| **(b)** `DEWpw4n8Lkw` 321-347s sınıfı pencere havuzda | ✓ 40 pencere, 315-323s örtüşüyor |
| **(c)** pozitif-ikiz | ✓ hareketsiz sürücüde 0 · NaN sürücüde 0 · **gerçek 1s salınımda 1** |

Rig'in KENDİ self-test'i sürücü modunu kapsıyor ve **atıl (inert) gövde
kareleri** besliyor: pencere ancak sürücüden gelebilir. Tabanın gerçekten
uygulandığı da çivilendi — **aynı 20° salınım, 40° taban altında REDDEDİLMELİ**;
o satır olmadan taban tamamen yok sayılabilir ve diğer satırlar yine geçerdi.

## Choreia düzeyi — (a) GEÇTİ, ama İKİ GERİLEME VAR

| take | önce | sonra | çöküş | periyot |
|---|---|---|---|---|
| `4BRd2E8vBic` | **elendi** | **hazır** | 20 (20/20 topQ) | 0,625s |
| `DEWpw4n8Lkw` | hazır | hazır | 16 | 0,680s |
| `1IVtcoqMrBA` | hazır | hazır | 21 | 0,583s |
| `l3r4bPhikGQ` | hazır | hazır | 30 | 0,333s |
| `NWB9Y1_lZDQ` | hazır | hazır | 10 | 1,167s |
| `AyzYABnWDEM` | hazır | **ELENDİ** | — | — |
| `nOR1qEhpssg` | hazır | **ELENDİ** | — | — |

**Kabul testi geçti** (`4BRd2E8vBic`), ama iki take düştü ve sebepleri AYRI:

**`AyzYABnWDEM` — genlik tabanında ölüyor.** Tüm-take diz genliği (p95-p5)
**13,8°**, config'in `NO_BOUNCE` tabanı 12°. Yalnız 1 aday pencere hayatta
kalıyor ve onda nitelikli çöküş yok. Bu take C-117'de sağ diz std'si **1,7°**
(gürültü tabanının ALTINDA) diye zaten işaretlenmişti. Elenmesi tutarlı
görünüyor — ama **davranış değişikliğidir ve gizlenmiyor**.

**`nOR1qEhpssg` — KAMERA KAPISINDA ölüyor.** Gerekçe: *"no movement window
overlaps a camera-clean window"*. Sürücü, dizin çalıştığı FARKLI pencereleri
buluyor ve onlar kamera-temiz bölgelerin dışına düşüyor. **Bu, koordinatörün
şart 4'te önceden adlandırdığı olgunun ta kendisi** (`AyzYABnWDEM` 163-185s
vakası). **Kamera kapısı BU TURDA GEVŞETİLMEDİ** (M-F-200); bulgu isimli olarak
buraya yazıldı, hüküm koordinatörde.

## Havuzun bugünkü hâli (zincir koşulmadan, yalnız ölçüm)

Ders-doğrulanmış **ve** kullanılabilir **4** kaynak:

| take | periyot |
|---|---|
| `l3r4bPhikGQ` | 0,333s |
| `1IVtcoqMrBA` | 0,583s |
| `4BRd2E8vBic` | 0,625s |
| `DEWpw4n8Lkw` | 0,680s |

**Kalan 2× çatışmaların ÜÇÜ DE `l3r4bPhikGQ` kaynaklı** (1,75 · 1,88 · 2,04).
Diğer üçü **birbirine 1,17× içinde** — yani `l3r4bPhikGQ` dışarıda kalırsa
`MIN_TAKES=3` tam olarak sağlanıyor. **Bunu "referans kurulabilir" diye
OKUMUYORUM:** zincir merge sonrasına bağlı, ve `l3r4bPhikGQ`'yu "uyuşmuyor"
diye atmak tam olarak C-124'te reddettiğim hamle — dışlama bağımsız kanıt
ister, ki o da segment kimliği sorusudur (0,333s ≈ 180 BPM: hızlı bounce mu,
criss-cross mu). R13'ün hasattan ÖNCE "derleme riskli" işaretlediği take
olmaya devam ediyor.

## Yan bulgu: `drift_check`'in kendi kör noktası — C-114'ün iddiası YANLIŞMIŞ

Vendored kopya merge EDİLMEMİŞ bir dala pinlendiğinde `drift_check`
**"✓ pin is current with origin/main"** diyordu. Sebep: sayım
`rev-list --count PIN..origin/main` ve pin main'in **ARDILI** olduğunda bu
sayı da 0. C-114 "drift_check pinin main'in atası olup olmadığını sınayıp
yüksek sesle bildiriyor" diye kayıtlıydı — **ölçtüm, bildirmiyordu**, üstelik
tam da bunun için yazıldığı vakada. Soy-ağacı artık DOĞRUDAN soruluyor
(`merge-base --is-ancestor`) ve dal pini yüksek sesle raporlanıyor. Sabotajla
ayırt ediciliği kanıtlandı: main atası olan pinde uyarı SUSUYOR.

---

# ÖN-KAYIT — tur 5 zinciri (2026-08-04, ZİNCİRDEN ÖNCE)

**Ayrı commit'lendi; sıranın kanıtı git geçmişinde.** M-F-238 şart 3-4.

## Havuz (zincire girecek)

4 ders-doğrulanmış + kullanılabilir kaynak, **`l3r4bPhikGQ` İÇERİDE**:

| take | periyot | çöküş |
|---|---|---|
| `l3r4bPhikGQ` | 0,333s | 30 |
| `1IVtcoqMrBA` | 0,583s | 21 |
| `4BRd2E8vBic` | 0,625s | 20 |
| `DEWpw4n8Lkw` | 0,680s | 16 |

Harmonik kapının **ne göreceği önceden biliniyor**: `l3r4bPhikGQ` diğer üçüyle
1,75 / 1,88 / 2,04 oranında çatışıyor; diğer üçü birbirine 1,17× içinde.
Zincir yine de **onu İÇERİDE tutarak** koşulacak — kapı hükmü versin, ben değil.

## İKİ DÜRÜST UÇ — önceden yazılı, hangisi çıkarsa rasyonalize EDİLMEYECEK

**UÇ-1 — `l3r4bPhikGQ` KİMLİĞİ ÇÖZÜLÜR (bileşik kanıtla).** Üç bağımsız
işaretten (transkript · çapa deseni · çöküş şekli) **en az ikisi** aynı yöne
işaret ederse dışlama İSİMLİ ve gerekçeli olur (`excludedWithReason/identity`),
referans kalan **3 kaynakla** kurulur, `cycleUnit: dipsPerCycle=1` damgası
artefakta iner, ve **`low-amplitude-vs-family` temeli NİHAYET sınanır** →
`resolvedBy` okuması + tur-5 sonuç bölümü.

**UÇ-2 — KİMLİK KANITI TOPLANAMAZ.** Üç işaretten ikisi hizalanmazsa dışlama
YAPILMAZ. O zaman referans **kurulamaz** ve dürüst son *"2× çatışma —
`l3r4bPhikGQ` kimliği çözülmedi"* olarak isimle yazılır. **`l3r4bPhikGQ`'yu
"uyuşmuyor" diye atmak bu turda da YASAK** (C-124'te reddettiğim hamle;
uyuşmazlık gerekçe değildir, M-F-47).

**Üçüncü ihtimal ayrıca yazılıyor:** kapı hiç çatışma bildirmezse (ör. birim
damgası oranları farklı okutursa) bu SÜRPRİZDİR ve sürpriz olarak raporlanır —
"beklediğim buydu" diye yazılmaz.

## Kimlik kanıtının ÜÇ ayağı (tek ölçü yetmez, M-F-60/2 emsali)

Soru: `l3r4bPhikGQ`'nun 0,333s'si (≈180 BPM) **hızlı bounce** mu, **criss-cross**
mu? (Başlık zaten "Bounce **w/ Cris Cross**" — R13 triyajında "derleme riskli".)

1. **Transkript:** segmentin zaman aralığında eğitmen hangi hareketi
   adlandırıyor?
2. **Çapa deseni:** criss-cross ayak ÇAPRAZLAMADIR → yatay ayak hareketi
   beklenir; bounce dikey/diz sürücülüdür.
3. **Çöküş şekli:** bounce'ın çöküşü diz sürücülü ve simetriktir; criss-cross'ta
   diz salınımı ayak yerleşiminin YAN ÜRÜNÜDÜR — `identityLegShapeDeg` ve
   çöküş derinliği/asimetrisi diğer üç kaynakla karşılaştırılır.

**Hiçbiri tek başına hüküm vermez.** İkisi hizalanmazsa UÇ-2.

## Ölçüm öncesi ÖNSEL (kanıt değil)

`l3r4bPhikGQ` C-117'de **en GÜÇLÜ** diz sinyalini vermişti (47,2°/55,1°) ve o
zaman "derleme riskli işaretlediğim en güçlü çıktı" diye kaydedilmişti — yani
sinyalin güçlü olması kimliğin doğru olduğunu göstermiyor, sadece bir şeyin
güçlü olduğunu. 0,333s ≈ 180 BPM bir bounce için hızlı; ama yavaş bir
criss-cross da aynı hızda diz salınımı üretebilir. **İki yönde de zayıfım;
ölçüm karar versin.**

---

# SONUÇLAR — TUR 5 (2026-08-04, zincir KOŞULDU)

**Ön-kayıt `17f4522`'de, bu zincirden ÖNCE.** Rig merge'i: motion-core main
**`9620394`** (M-F-238). Vendored kopya `9620394`'e re-pin'lendi ve
`drift_check`'in ⚠ satırı **sustu** (`✓ pin is current with origin/main`);
re-pin sonrası 7 take'in prepared çıktısı **birebir aynı** — merge içerik
değiştirmemiş.

## Zincir

`classify` → 4 `lesson` (`l3r4bPhikGQ` 2062 · `1IVtcoqMrBA` 944 ·
`4BRd2E8vBic` 2070 · `DEWpw4n8Lkw` 2468 sözcük); `NWB9Y1_lZDQ` yine 0 sözcükle
elendi.

`build_reference` **4 kaynakla** koşuldu (ön-kayıt gereği `l3r4bPhikGQ`
İÇERİDE) ve harmonik kapı **ön-kayıtta yazdığım çatışmayı** bildirdi:
0,333 ↔ 0,583 / 0,625 / 0,680.

## `l3r4bPhikGQ` — UÇ-1 GERÇEKLEŞTİ: kimlik ÇÖZÜLDÜ

Ön-kayıt üç ayaklı bileşik kanıt şart koşuyordu; **ikisi hizalandı, üçüncüsü
ayırt etmedi.**

**AYAK 1 — TRANSKRİPT (belirleyici).** Seçilen segment **537-549s**. Dersin
transkripti hareketleri isimleriyle anıyor:

| zaman | söylenen |
|---|---|
| 48,9s | *"we were working on what I call **bounces** or hops"* |
| 51,3s | *"all we did was the **basic bounce side to side**"* |
| **504,5s** | *"This is a one, and two, and **cross, cross, switch**"* |
| 530,8s | *"five, six, and **left, and right**"* (müzikle koşum) |
| 592,5s | *"was **crossing our legs** in front"* (özet) |

**Seçilen segment, 504,5s'te başlayan CRISS-CROSS rutininin içinde.** Temel
bounce dersin başında (48-90s) ve 586-590s'te. Yani bu take `hh_bounce`'ı
değil **komşu hareketi** ölçüyor.

**AYAK 2 — ÇAPA DESENİ: AYIRT ETMEDİ.** `l3r4bPhikGQ` `x` seçti, ama
`1IVtcoqMrBA` ve `4BRd2E8vBic` de `x` seçti (yalnız `DEWpw4n8Lkw` `y`).
**Bu ayak hükme KATILMADI** — ayırt etmeyen ölçü kanıt değildir.

**AYAK 3 — ÇÖKÜŞ ŞEKLİ: ayrıştırdı.**

| take | ort. derinlik | giriş/çıkış asimetrisi | **topQualified** |
|---|---|---|---|
| **`l3r4bPhikGQ`** | 13,3° | **0,33** | **%53** |
| `1IVtcoqMrBA` | 12,9° | 0,10 | %100 |
| `4BRd2E8vBic` | 13,8° | 0,16 | %100 |
| `DEWpw4n8Lkw` | 17,2° | 0,13 | %100 |

Çöküşlerinin ancak **yarısı** tam ekstansiyondan başlıyor (diğer üçünde
**tamamı**), ve giriş/çıkış asimetrisi 2-3× yüksek — diz hareketi ayak
yerleşiminin **yan ürünü** gibi davranıyor.

**Dışlama UYUŞMAZLIKTAN türemedi** (M-F-47): harmonik kapı onu zaten
2×-ailesi diye işaretlemişti ama o tek başına gerekçe sayılmadı. Kayıt
`decisions.json` → `excludedWithReason/identity`, dört kanıt satırıyla —
ayırt etmeyen üçüncü ayak da **açıkça** yazıldı.

## REFERANS KURULDU — ve asıl sınav NİHAYET koşuldu

3 kaynakla kuruldu, birim damgası artefaktta:
`cycleUnit: {driver: knee_flexion_mean, dipsPerCycle: 1, selectedBy: phase-driver}`.

### `resolvedBy` SINAVI — **TEMEL DURUYOR**

| ölçü | değer |
|---|---|
| kaynak | 3 · `mirrorConfident: false` · `status: provisional` |
| **ORTANCA eklem taban%** | **83** |
| kabul edilmiş referanslar | shine **28** · RM **9** · RR **22** |
| `statusBases` | `mirror-ambiguity` · `source-count-below-target` · **`low-amplitude-vs-family`** |

**İlk devirde yazılan iki dürüst sondan İKİNCİSİ çıktı:** toleransın %83'ü
ölçülen eğitmen ayrışmasından değil **6° gürültü tabanından** geliyor. Kabul
edilmiş referanslarda bu oran %9-28; bounce onların **3-9 katı**.

**Sonuç: `hh_bounce`'ın `measurability.tier: A` beyanı VERİYLE
DESTEKLENMİYOR** ve adım K10 demo-only yoluna **ölçülmüş gerekçeyle** aday.

### Bu, "bounce ölçülemiyor" DEMEK DEĞİL — ayrım önemli

Aynı turda `top` kapısının her take'te sağlandığını ölçmüştük (%100 · %100 ·
%100). Yani:

- **"Hareket algılanıyor mu?"** → **EVET.** ≥6° derin, ≥40°/s hızlı, tam
  ekstansiyondan başlayan gerçek çöküşler var.
- **"Öğrenciyi eğitmen uzlaşısına karşı SKORLAYABİLİR miyiz?"** → **HAYIR.**
  Tolerans kendi gürültü tabanımızın hükmü altında; referans "doğru" ile
  "gürültü"yü ayırt edemez.

`tier: A` ikincisini iddia ediyor ("large-amplitude… among the most reliably
tracked angles"). Ölçüm birinciyi doğruluyor, ikinciyi **çürütüyor**.
**Adımın statüsünü DEĞİŞTİRMEDİM** — dürüstlük-metriği hükmü koordinatörde.

## Zincir yol boyu İKİ GERÇEK KUSUR düşürdü

**1. Birim tutarlılık kapısı yanlış-pozitif verdi — ve suçlusu bendim.**
Kapıyı yazarken yorumuna *"yalnız beyan karşılaştırılır, ölçüm değil"* demiş,
sonra **tüm `cycleUnit` sözlüğünü** karşılaştırmıştım — sözlük take-başına
ölçümleri (`dipsInSegment` vb.) de taşıyor ve onların farklı olması normalin
ta kendisi. Kapı ilk koşumda ateşledi ve **kendi yazarını denetledi.**
Düzeltme: yalnız `(driver, dipsPerCycle)` karşılaştırılıyor.

**2. `toleranceSource` etiketi yayımlanan sayıyla çelişebiliyordu.**
`validate_reference` gerçek artefaktta yakaladı: `right_shin[36]` toleransı
**6,0°** ama etiketi `variance`. Sebep: sınıflandırma HAM türetilmiş değerden,
yayımlanan sayı ise YUVARLANMIŞ değerden geliyordu — 6,004° "6.0" diye
yayımlanıp "ölçülmüş ayrışma" diye etiketleniyordu. Artık etiket **yayımlanan
sayıdan** türüyor; yayımlanan çözünürlükte dürüst etiket `floor`'dur, çünkü
AZ iddia eder.

## Havuzun son hâli — dört dışlamanın DÖRDÜ DE isimli ve kanıtlı

| take | reasonCode | gerekçe |
|---|---|---|
| `NWB9Y1_lZDQ` | `no-speech` | 0 sözcük; ses var (−12,8 dB), konuşma yok |
| `AyzYABnWDEM` | `amplitude-floor` | diz genliği 13,8° < config `NO_BOUNCE` 12° eşiğinin marjında; 1 aday, 0 nitelikli çöküş |
| `nOR1qEhpssg` | `camera-driver-disjoint` | kamera-temiz ve diz-aktif pencereler kesişmiyor — **dürüst kayıp**, kapı gevşetilmedi |
| `l3r4bPhikGQ` | `identity` | segment criss-cross rutininin içinde (transkript + çöküş şekli) |

`nOR1qEhpssg` kaybının bedeli **isimli**: C-124'te KESİN `one-dip` hükmü almış
iki take'ten biriydi, yani birim sorusuna en çok ışık tutan kaynaktı.

## EK — re-pin `dde99bd` (koordinatör talimatı, zincir SONRASI)

Zincir `9620394` pinliyken koşulmuştu. Talimat üzerine pin **`dde99bd`**'ye
taşındı. **Zincir yeniden doğrulandı, hiçbir çıktı değişmedi:**

- `movement_isolator.py` **`9620394` → `dde99bd` → `5bbced9` boyunca bit-aynı**
  (git diff ile ölçüldü) — re-pin saf pin yükseltmesi, içerik yükseltmesi değil.
- 6 take'in prepared çıktısı **birebir aynı** · referans yeniden üretimi
  **birebir aynı** · 13/13 kapı 0.

**İKİ NOKTA KOORDİNATÖRE (talimat uygulandı, ama ölçüm iki şey söylüyor):**

1. **`dde99bd` artık main değil** — main `5bbced9`'a ilerledi (D1 kapısı
   merge'i), dolayısıyla kendi `drift_check`'im artık **"pin 2 commit(s)
   behind origin/main"** uyarısı basıyor. Uyarı DOĞRU ama içerik hakkında
   değil pin YAŞI hakkında: izolatör dosyası o iki commit boyunca değişmedi
   (ölçüldü). Sürekli yanan sebepsiz uyarı, C-114'ün *"gürültülü kapı
   kapatılır"* dersinin tam hedefi — **`5bbced9`'a bump önerilir**, ama pin
   değeri senin talimatındı, tek taraflı değiştirmedim.

2. **Soy-nöbeti bu kopyaya ULAŞMIYOR.** `rig_version()`/`onMainLineage`
   `tools/harvest_rig/manifest.py`'de; **Choreia o dosyayı vendor ETMİYOR**,
   yalnız `movement_isolator.py`'yi ediyor. Yani "kendi kopyan da soy-nöbetli
   olur" gerekçesi bu vendored yol için geçerli değil — ama boşluk YOK:
   bu kopyanın kendi `merge-base --is-ancestor` kontrolü (C-126) zaten aynı
   işi yapıyor ve sabotajla ayırt ediciliği kanıtlı.

---

# HÜKÜM UYGULAMASI — `hh_bounce` → demoOnly (2026-08-04, M-F-242)

Koordinatör `measurability.tier: A` beyanını **geri çekti** ve adımı K10
demo-only yoluna aldı — **ölçülmüş gerekçeyle**. Uygulama:

## Adım config'i

`measurability.tier`: **A → B**. `tier: C` seçilemezdi: sözleşme *"tier C
must never ship in V1"* diyor, oysa bu ders **kullanıcıya gösterilecek**.

`measurability.tierWithdrawn` eklendi — **kapı-isimli** (M-F-217):
`resolvedBy: low-amplitude-vs-family` + artefakt-atıflı sayılar (%83 taban
payı vs kabul edilmişlerde %9-28; 6,0° taban) + `promotionPath`.

`reference`: `collectedTakes` 0 → **3**, `status` → `provisional`, ve
**`notConsumedForScoring`** alanı: artefakt YAŞAR ama hiçbir şey ona karşı
puanlamaz — kayıt, tier kararının dayandığı kanıt olduğu için silinmez.

## Ders yüzeyi

`hh_l1_bounce`: `locked` → **`demoOnly`**, `demoOnlyClass:
structural-circular`, ve `promotionPath` **isimli + veri-tetikli**
(≥6 kaynakla yeniden ölçümde eğitmen ayrışması tabanın üstüne çıkarsa tier
yeniden açılır). Başlık: *"The bounce (not graded)"*.

Kullanıcı-dili gerekçe (emir kipi yok, kullanıcıyı suçlamıyor):

> *"We measured three teachers doing this step, and the result was not the one
> we expected: they move so alike that the differences between them are smaller
> than what a phone camera can reliably resolve. A score here would mostly be
> measuring our own uncertainty rather than your bounce. So you get the step,
> the count and three teachers' versions of it — the number is the part we are
> leaving out, and we would rather say that than hand you a confident-looking
> one."*

## `honesty` bloğu — eski satır ARTIK YANLIŞTI

`notMeasured`'daki Bounce satırı *"no teachers have been measured for them
yet (collectedTakes == 0)"* diyordu. **Bu bugün yanlış.** Yerine ölçülmüş
gerekçe yazıldı; Rock/Groove ayrı satıra alındı (onlar hâlâ yazılmamış).
`measuredNote` de güncellendi: **"kurulmuş referans, puanlanabilir referans
demek DEĞİLDİR"** — bu bloğun var olma sebebi tam olarak bu karışıklık.

`stepInventory.tierA_confirmed`'daki `hh_bounce` kaydı **silinmedi**,
etiketlendi: ölçüm-öncesi taramanın ÖNGÖRÜSÜ ile ölçümün HÜKMÜ yan yana
okunabilsin diye.

## Doğrulama

`validate_content` 0 · `validate_reference` 0 · **58 Flutter + 16 engine
testi** · `flutter analyze` + `dart analyze` temiz.

## `drift_check` v2 — yaş uyarısı İÇERİK-DUYARLI (M-F-242/3)

Uyarı artık yalnız `git diff PIN..origin/main -- <vendored yol>` **boş
değilken** yanıyor; boşken tek satırlık bilgi notu (`·`). Gerekçe C-114'ün
kendi dersi: sürekli yanan sebepsiz uyarı okunmaz hâle gelir.

**Sabotaj ikizi, iki yön de ölçüldü:**

| pin | vendored dosya o aralıkta | çıktı |
|---|---|---|
| `dde99bd` (4 geride) | **değişmedi** | `· … UNCHANGED in that range — vendored content is current` |
| `eb28039` (69 geride) | **DEĞİŞTİ** | `⚠ … CHANGED in that range — re-diff and re-vendor` |

Pin **`6fd718f`**'e (güncel main) bump'landı — politikanın "doğal dokunuşta
bump" maddesi; `✓ pin is current with origin/main`.

---

# K10 GENİŞLETMESİ (2026-08-04, M-F-245) — ve yol üstünde 13 KIRIK ATIF

## `demoOnlyClass` sözleşmesi KODA yazıldı — ikiz kapılar

Koordinatörün "VARSAYILAN YOK" sertleştirmesi `validate_content`'e indi:

- **`structural-circular`** ⇒ `promotionPath.blockedBy` + `unblockedBy` ZORUNLU
- **`permanent`** ⇒ `whyPermanent` ZORUNLU **ve** `promotionPath` **YASAK**

İkinci kapı ters yönlüdür ve asıl yenilik odur: permanent bir derse yol
yazmak **eksiklik değil ÇELİŞKİDİR** — ya sınıf yanlıştır ya yol sahtedir, ve
sessiz geçmek kullanıcıya var olmayan bir gelecek vaat eder (M-F-207 zeyli:
en-az-yetkinin aşırı hâli de arızadır).

**Sabotaj sınavı 5/5:** whyPermanent sil → ateşler · permanent'a path ekle →
**ÇELİŞKİ** ateşler · structural-circular'dan path sil → ateşler · sözlük dışı
sınıf → ateşler · geri al → **susar**.

Mevcut dört `permanent` dersin (Running Man · groove · arm styling ·
musicality) **hiçbirinde `whyPermanent` yoktu**; dördü de yazıldı — ve
`demoOnlyReason`'dan farklı bir iş yapıyorlar: birincisi *"ne alırsın,
ne almazsın"*, ikincisi *"ve bu DEĞİŞMEYECEK, çünkü…"*.

## Yol üstünde: `relatedDrill` atıflarının HEPSİ boştaydı

K10 içeriğine ne yazacağımı ararken adım config'lerinin **zaten
isimlendirdiği** ama karşılığı olmayan şeyi buldum: hata taksonomisi
kullanıcıyı 7 ayrı alıştırmaya yönlendiriyor ve **hiçbirinin dersi yoktu** —
**13 kırık atıf**, ve `validate_content` bunu **hiç denetlemiyordu**.

Bu, kullanıcı arayüzünde değil İÇERİKTE ölü-buton sınıfı: *"şu hatayı
yaptıysan şu alıştırmaya bak"* diyen bir vaat, arkasında hiçbir şey yokken.

**Kapı eklendi:** her `relatedDrill` AYNI stildeki bir derse çözülmeli
(farklı stildeki bir drill'e çözülmek de yanlıştır). Sabotajla sınandı:
drill seviyesini kaldır → 9 hata, geri koy → sessiz.

## İçerik: 7 alıştırma, hiçbiri uydurulmadı

| stil | alıştırma | düzelttiği hata |
|---|---|---|
| hip-hop | `hh_bounce_slow` | NO_BOUNCE · BOUNCE_INVERTED · ASYMMETRIC_BOUNCE |
| hip-hop | `hh_bounce_wall` | TRUNK_COLLAPSE |
| salsa | `ss_weight_shift` | NO_WEIGHT_TRANSFER |
| salsa | `ss_count_hold` | STEP_MISSED_ON_4 |
| salsa | `ss_lead_foot` | WRONG_FOOT |
| salsa | `ss_small_steps` | STEP_TOO_LARGE |
| salsa | `ss_slow_tempo` | STEP_LATE |

Metinler hataların **kendi notlarından** türetildi. Hepsi `demoOnly` +
`permanent` + `drillFor: {step, errorCodes}`.

**`permanent` gerekçesi SAHTE KAMERA ARGÜMANI DEĞİL.** Bir alıştırma bir
DÜZELTMEdir, performans değil: kasten yavaşlatılmış ya da duvara yaslanmış
bir versiyonun eğitmen uzlaşısı yoktur ve olamaz — uydurulmuş bir "doğru"ya
karşı puanlamak kendi icadımızı puanlamak olurdu. Bu yüzden `promotionPath`
YASAK, ve yasağı kapı zorluyor.

**"Henüz yazılmamış adım" `locked` KALDI** (`hh_rock`) — demoOnly'ye
taşınmadı; C-096 aynen: locked = geçici/ölçüm-eksik, demoOnly = yapısal.

Yeni seviyelerde `unlockRule: null` + gerekçesi: **puanlanmayan derslerde
kilit kuralı olamaz**, çünkü kural ancak app'in vermeye izinli olduğu bir
hükme dayanabilir (M-F-04) — ve alıştırmalar zaten hata anında elini uzatman
gereken şeyler, baştan açıklar.

## Doğrulama

`validate_content` 0 · `validate_reference` 0 · keyset 0 + self-test + drift ·
liveness 0 · `movement_isolator --drift-check` 0 · **58 Flutter + 16 engine
testi** · `flutter analyze` + `dart analyze` temiz.

Kurs yapısı: hip-hop **L1 4 + L2 2** · salsa **L1 4 + L2 5** ders.
