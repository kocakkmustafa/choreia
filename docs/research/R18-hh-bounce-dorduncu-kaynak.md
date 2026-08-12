---
tur: olcum
proje: choreia
guncelleme: 2026-08-12
---

# R18 — `hh_bounce` dördüncü kaynak: arama + triyaj

**Bu not hasat SONUÇLARINDAN ÖNCE yazıldı** (R13/R14'ün disiplini): hangi
adayın hangi riski taşıdığı burada ÖNCEDEN kayıtlı; hasat bitince bu tabloya
karşı okunacak. Gerekçeyi sonucu gördükten sonra aramak post-hoc olurdu.

**Sevk (koordinatör):** `hh_bounce`e dördüncü kaynak — çünkü üç yayınlanmış
referans içinde **hipotezi VAR olan tek** referans o (iki tane: `dh_bounce`
→ DİZ, `hh_rock` → GÖVDE/KALÇA) ve engeli **yalnız taban**. Dördüncü kaynak
inince hem `provisional` hem kimlik sorusu tek hamlede cevaplanabilir hâle
gelir.
**Durma kuralı MALZEME, sayı değil:** *"4'e ulaşmak için 1 aday bul"* değil,
*"malzemeyi düzgün tara ve NE VARSA raporla"*. Uygun kaynak çıkmazsa o da
sonuçtur.

---

## 1. Önce ELDEKİ malzeme tarandı — ve tükenmiş çıktı

`hh_bounce` havuzunda **7 fixture** var ama referans **3** kullanıyor.
Dördünün niçin dışarıda olduğu ölçüldü — hepsi **isimli ve ölçülmüş**:

| take | kod | gerekçe |
|---|---|---|
| `NWB9Y1_lZDQ` | `no-speech` | 0 sözcük konuşulmuş; ses var (−12,8 dB), konuşma yok — kaynak-uygunluk kapısı (fail-closed) |
| `AyzYABnWDEM` | `amplitude-floor` | diz genliği p95−p5 = **13,8°**, adımın kendi `NO_BOUNCE` eşiği **12°** — kendi "yerinde duruyor" tabanının marjında |
| `nOR1qEhpssg` | `camera-driver-disjoint` | kamera-temiz pencereler ile diz-aktif pencereler **kesişmiyor** (M-C-16) — dürüst kayıp, kapı gevşetilmedi |
| `l3r4bPhikGQ` | **`identity`** | seçilen segment (537-549s) **criss-cross rutininin İÇİNDE**; temel bounce 48-90s ve 586-590s'te |

R13'ün aday listesindeki kalan ikisi (`OPJKTQ0blc8`, `ltLE-Mya6fE`) **"kanal
zaten sayıldı"** ile reddedilmiş (sayım birimi EĞİTMEN, M-F-32/M-F-54).
→ **9 adayın hepsi hesapta: 3 kabul · 4 ölçülmüş dışlama · 2 kanal-tekrarı.**

### `l3r4bPhikGQ` kurtarılabilir mi — ölçüldü, HAYIR

Dışlama notu temel bounce'un **nerede öğretildiğini adıyla veriyor** (48-90s,
586-590s), yani "yanlış pencere seçildi" okuması akla geliyor. İki ölçüm bunu
kapattı:
1. **`prepare_take` pencere argümanı TAŞIMIYOR** (`--video --step --out --all
   --self-test`); segment seçimi faz-sürücülü ve otomatik. Pencereyi elle
   seçmek aracı değiştirmeyi ya da elle kesmeyi gerektirirdi — ikisi de
   *sonucu ölçmeden şekillendirmek* olurdu.
2. **Dışlama yalnız pencereye dayanmıyor — ÜÇ bağımsız sinyal var:**
   transkript (504,5s'te criss-cross rutini başlıyor, seçilen segment içinde)
   · **çöküş şekli** topQualified **%53**, kabul edilen üçünde **%100**
   (çöküşlerin ancak yarısı tam ekstansiyondan başlıyor — diz hareketi ayak
   yerleşiminin yan ürünü gibi davranıyor) · **çöküş asimetrisi 0,33**,
   diğerleri 0,10/0,16/0,13 (**2-3× ayrışma**).

→ **Dördüncü kaynak YENİ BİR KANALDAN gelmek zorunda.** Harcanmış 7 kanal:
Versa-Style · Thilanka Rathnayake · O G Here · JoeyTheJAM · Darren R. Wong ·
HipHopeace · FitLara Dance.

---

## 2. Arama turu — metadata triyajı (`probe_candidates.py`, GERÇEK ölçüm)

Kurucu yetkisi M-F-507 (internet-video referans hasadı) kapsamında; §50 altında
yalnız açı/landmark verisi, video yeniden dağıtılmaz, kaynak kaydedilir.

6 aday, **6 ayrı yeni eğitmen**, hepsi yatay ve adım-uzunluğunda:

| video | çözünürlük | süre | kanal | metadata kararı |
|---|---|---|---|---|
| `ovIZAyDuJSg` | 1920x1080 | 759s | DTC | ADAY |
| `lRbEjAar9yQ` | 1920x1080 | 681s | The Shed | ADAY |
| `8TuimkcTqPk` | 1920x1080 | 854s | Tiana Shern | ADAY |
| `-WRrIQHifk4` | 1920x1080 | 656s | Ethan Guzman | ADAY |
| `u_QCqOFIfto` | 1920x1080 | 620s | Planet Calypso | ADAY |
| `RkoJ3Xz4Rig` | 3840x2160 | 364s | FRONTROW | ADAY |

## 3. ÖNCEDEN kaydedilen kimlik/varyant riskleri (M-F-175 sınıfı)

Metadata hepsini geçirdi; **başlık düzeyinde riskler ayrı** ve hasattan önce
yazılıyor. Bu turun kendi dersi burada uygulanıyor: *`l3r4bPhikGQ`'nun
"derleme riski" R13'te hasattan ÖNCE işaretlenmişti ve GERÇEKLEŞTİ.*

| video | başlığın iddiası | risk sınıfı | hasat sonrası kontrol |
|---|---|---|---|
| `ovIZAyDuJSg` | "HIP HOP - **Basic Bounce** (Follow Along) Beginner" | **saf** — en düşük kimlik riski | "Follow Along" ders değil eşlik-videosu olabilir → `no-speech` kapısı (`NWB9Y1_lZDQ`'nun elendiği kapı) |
| `lRbEjAar9yQ` | "**3 Bounce Drills** To Improve Your Foundation" | **çoklu-drill** | segment üç drill'den hangisine düşüyor; temel bounce mı bir varyasyon mu — `l3r4bPhikGQ`'nun gerçekleşen riski. ⚠️ Ayrıca The Shed **başka adımlarda** kullanılmış (roger_rabbit + running_man) — R8 emsaline göre not, diskalifiye değil |
| `8TuimkcTqPk` | "Fundamentals: **Bounce, Rock & Skate**" | **derleme** | tam olarak `4BRd2E8vBic` (kabul, işaretli) ve `l3r4bPhikGQ` (dışlandı, risk gerçekleşti) sınıfı — segment bounce mı rock mu skate mi |
| `-WRrIQHifk4` | "HOW TO DANCE WITHOUT LOOKING STIFF (**GROOVE** TUTORIAL)" | **kimlik riski** | başlık bounce'u HİÇ adlandırmıyor; groove bounce'u KAPSAYAN daha geniş bir terim |
| `u_QCqOFIfto` | "Bounce - Hip Hop Dance **Workout**" | **ders değil** riski | workout formatı gösterim olabilir ama öğretim dili taşımayabilir → `no-speech`/kaynak-uygunluk |
| `RkoJ3Xz4Rig` | "**K-Pop** first basic training - Bounce training by Hybe dance trainer" | **farklı dans bağlamı** | `ZpTgAZBYNrU`'nun tam sınıfı: başlık **başka bir dansı** adlandırıyor. K-pop bounce ile hip-hop bounce aynı adı taşıyıp aynı adım olmayabilir |

**Hasat sırası, riske göre (en düşükten):** `ovIZAyDuJSg` → `lRbEjAar9yQ` →
`8TuimkcTqPk` → kalanlar. **Sıra sonuca göre değil, ÖNCEDEN yazılan riske
göre belirlendi.**

---

## 4. HASAT SONUCU — dördüncü kaynak İNDİ

`ovIZAyDuJSg` (DTC) kanonik rig'le çekildi: `harvestRig.sha=63a0b3ed…`,
`dirty=false`, `onMainLineage=true`, `romMode=active`,
`referenceEligible=True`, 18187 kare @23,976fps. Hazırlık: **38,58s segment**
(mevcut dördün en uzunu), periyot 0,625s.

### ⚪ Önce bir ORTAM tuzağı — ve "red" sanılabilirdi

İlk kurulumda kaynak-uygunluk kapısı `ovIZAyDuJSg`yi **dışladı**:
`verdict: unknown`, `spokenWords: **-1**`, *"transkript yok — başlıktan hüküm
verilmez (fail-closed)"*.

Bu **kaynağın kusuru DEĞİLDİ.** `spokenWords: -1` "konuşma yok" demek değil
"transkript yok" demek; rig'in transkript aşaması `faster-whisper kurulu
değil` diye **atlanmıştı** (scratchpad venv'inde paket yoktu). Önceden
kaydettiğim *"Follow Along ders değil olabilir"* riskiyle **aynı görünüyordu**
ama sebebi başkaydı — ve o riski doğrulanmış saysaydım **ortam eksikliğini
malzeme hükmü diye raporlamış** olurdum.

Paket kuruldu, **yalnız transkript aşaması** yeniden koşuldu (indirme/çıkarım
tekrarlanmadı, rig'in kendi `transcribe()`'ı çağrıldı, manifest **diskten
yüklendi** — alanları elle doldurmak provenance uydurmak olurdu):
**53 segment, 900 sözcük.** Yani video öğretim dili TAŞIYOR; önceden
kaydettiğim risk **gerçekleşmedi**.

### Referans: 3 kaynak → 4 kaynak

| ölçü | 3 kaynak | 4 kaynak |
|---|---|---|
| `takeCount` | 3 | **4** |
| çevrim toplamı | 83 | **144** (+%73) |
| `thinTakes` | — | **boş** |
| toleransın **gürültü tabanından** gelen payı (ortalama) | **%59,1** | **%30,4** |
| `statusBases` | 3 | **2** — `low-amplitude-vs-family` **ÇÖZÜLDÜ** |
| medyan dispersiyon | 5,72° | **7,91°** |
| `status` | provisional | provisional (mirror-ambiguity · source-count-below-target) |

**İki sayı birlikte okunmalı, tek başına ikisi de yanıltır:** dispersiyon
YÜKSELDİ ama gürültü-tabanı payı **yarıya indi**. Bu bir gerileme değil,
beklenen sonuç — dördüncü eğitmenle birlikte **gerçek** eğitmen ayrışması
ölçülebilir hâle geldi; önceden bandın çoğu 6,0°'lik gürültü tabanından
geliyordu. Bant artık **ölçümden** yapılmış, gürültüden değil.

`provisional` sürüyor çünkü kalan iki gerekçe kaynak sayısıyla çözülmüyor:
ayna belirsizliği, ve §6.0'ın **tercih ettiği 6** eğitmene hâlâ uzak (4).

### Kimlik probu — artık KOŞABİLİR (≥4 kaynak)

⚠️ **Ölçüm alanı düzeltildi:** ilk koşumda `disagreement` listesi kullanıldı ve
sonuç **artefakt** çıktı (`nan`, eklem sayısı 16↔10 arası oynuyor) — o liste
**eşikli**, yani her kurulum farklı eklem KÜMESİ bildiriyor ve medyanları
kıyaslamak farklı şeyleri kıyaslamak olur. `toleranceDeg` her kurulumda
**17/17** eklem taşıyor; ölçüm ona taşındı.

| çıkarılan | tüm eklemler Δ° | **DİZ** Δ° (`dh_bounce` hipotezi) | **GÖVDE/KALÇA** Δ° (`hh_rock` hipotezi) |
|---|---|---|---|
| `1IVtcoqMrBA` | −1,17 | **+0,00** | −0,72 |
| `4BRd2E8vBic` | +0,62 | **+0,00** | −0,85 |
| `DEWpw4n8Lkw` | −0,16 | **+0,00** | −0,51 |
| **`ovIZAyDuJSg` ★** | **−5,06** | **+0,00** | −0,84 |

**Hüküm — `ovIZAyDuJSg` ayrışmıyor, TUTULUR:**
- **GÖVDE/KALÇA** (`hh_rock` hipotezi): dördü de −0,51…−0,85 aralığında;
  yeni kaynak (−0,84) aykırı değil, `4BRd2E8vBic` (−0,85) ondan da büyük.
  **Ayrışma yok.**
- **Tüm eklemler** Δ −5,06 dördün en büyüğü, **ama bu kimlik kanıtı DEĞİL**:
  bu take 144 çevrimin **61'ini** (%42) taşıyor; en kalın kaynağı çıkarmak
  bandı en çok değiştirir. `hh_running_man`de `Wd29rBfAzkI`'nin −9,25'i için
  yazdığım aynı ayrım: *iyileşmenin boyu, dışlamanın gerekçesi değil.*

### 🔴 Üçüncü bir "cevaplanamaz" sınıfı bulundu: **bölge ölçüm TAŞIMIYOR**

**DİZ sütunu dört take'te de tam olarak +0,00.** Sebep ölçüldü: `left_knee`
ve `right_knee` toleransının **%100'ü** hem 3- hem 4-kaynaklı kurulumda
gürültü tabanından geliyor (`toleranceSourceFloorPct`). Yani diz bandı hangi
take'in çıkarıldığından **bağımsız** — çünkü hiç ölçümden yapılmamış.

→ **`dh_bounce` hipotezi (dip daha uzun/alçalış daha yavaş → DİZ) bu
referansta MEKANİK OLARAK SORULAMAZ**, ve sebebi ne "hipotez yok" ne "taban
altı": **öngörülen bölge ölçüm taşımıyor.** Koordinatörün çerçevesine
**üçüncü** bir cevaplanamazlık sınıfı.
`hh_rock` hipotezi (GÖVDE/KALÇA) ise sorulabildi ve cevaplandı.
