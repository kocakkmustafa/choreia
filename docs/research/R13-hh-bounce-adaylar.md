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
