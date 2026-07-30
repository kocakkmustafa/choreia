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
