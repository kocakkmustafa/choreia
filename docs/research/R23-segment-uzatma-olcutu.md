---
tur: olcum
proje: choreia
guncelleme: 2026-08-12
---

# R23 — Segment uzatma ÖLÇÜTÜ (sonuçtan ÖNCE yazıldı)

> ## ⛔ BU BELGE HİÇBİR UZATMA SONUCU GÖRÜLMEDEN YAZILDI VE COMMIT'LENDİ.
> Sevk kısıtı: *"bir segmenti **çelişki ürettiğini gördükten sonra** yeniden
> seçmek, eşiği adayı gördükten sonra yazmaktır."* Ölçüt **kuralla**
> seçiliyor, sonuca bakarak değil.

---

## 1. Soru

`HUOjOJvPJc8`in çöküş-türevi periyodu **3,336s** ve diğer iki take'le
**harmonik çelişki** üretiyor (`[[1.75, 3.336]]`). Bağımsız kanal
(antisimetrik/simetrik) bu take'te **hiç tepe vermedi** ⇒ H1 ile H2 **ayırt
edilemiyor**.

| | hipotez | ayıran şey |
|---|---|---|
| **H1** | take gerçekten yavaş, çevrim **3,336s** | kanal ≈3,336 derse |
| **H2** | çöküş algılaması **her ikinciyi kaçırıyor**, gerçek çevrim **1,668s** | kanal ≈1,668 derse |
| **H3** | segment (**8,88s / 5 çöküş**) kanalın çözülmesi için **fazla kısa** | kanal uzatınca **uyanırsa** |

📌 **Ve bunlar tek eksende değil:** H3 kanalın **niye sustuğunu** açıklar,
H1/H2 çevrimin **ne olduğunu**. İkisi birlikte doğru olabilir — nitekim H3
doğruysa H1/H2 ancak uzatmadan **sonra** ayrılabilir. Sıra bu yüzden zorunlu.

## 2. 🔒 ÖLÇÜT — ve niye bu

### Birincil kural: **`EP3Q3ttFwtU`in segment süresine eşitle — 15,56 s**

**Gerekçe:** `EP3Q3ttFwtU`, bu turda antisimetrik kanalı **çözülen** ve
kanal değeri çöküş-türevi birimle **uyuşan** (**1,71 ↔ 1,75**, %2 içinde)
**tek** take. Yani o süre, bu adımda / bu boru hattında / bugün, kanalın
çözülmesi için **gösterilmiş biçimde yeterli**.

⚠️ **Ve ölçüt, test edilen take'ten BAŞKA bir take'ten alınıyor** —
`HUOjOJvPJc8`in kendi verisine bakarak seçilmiş bir sayı olsaydı, tam olarak
yasaklanan şey olurdu.

### İkincil taban (ikincil, ve birincil zaten karşılıyor)

Take'in **kendi** çöküş-türevi periyodunda **en az 3 tam çevrim**:
3 × 3,336 = **10,0 s**. 15,56 s bunu zaten aşıyor ⇒ **birincil kural
belirleyici**. Yazılıyor ki seçim sessizce iki iş birden yapmasın.

### Sınırlar

- Pencere segmentin **merkezinde** genişletilir (tek yöne kaydırmak, seçimi
  veriye göre yapmak olurdu).
- Take'in kendi kare aralığı dışına **çıkılamaz** (`HUOjOJvPJc8`: 18619 kare,
  segment [8700, 8966] — yer var).
- **Kamera-temiz bölgenin dışına taşarsa RAPOR EDİLİR:** denetlenmemiş
  görüntüye doğru genişlemek, bir körlüğü başka bir körlükle takas etmektir.
- **Popülasyon: yalnız üç shuffle take'i.** *(Bir kapının çıktısı,
  beslendiği popülasyon kadar anlamlıdır — bu turda `--all` ile bir kez
  yanlış popülasyon ölçtüm.)*
- ⛔ **`dipsPerCycle`'a DOKUNULMAYACAK.** Üç hipotezin üçü de birime dokunmayı
  gerektirmiyor.

## 3. 🔒 OKUMA KURALI — sonuç görülmeden bağlanıyor

| kanal ne derse | sınıf |
|---|---|
| **≈ 3,336 s** (±%15) | **H1** — çevrim gerçekten iki katı ⇒ çelişki **GERÇEK**, take düşer, taban **2'ye iner** |
| **≈ 1,668 s** (±%15) | **H2** — algılama yarı oranda ⇒ **algılama kalemi**, birim değil |
| **hâlâ tepe yok** | **ÖLÇÜLEMEDİ** — ve bu **dürüst bir sınıf**, başarısızlık değil |
| **başka bir değer** | ölçüldüğü gibi **raporlanır**, zorla sınıfa sokulmaz |

**Ve ayrıca, hangi değer çıkarsa çıksın:** kanal 8,88 s'de **susup** 15,56
s'de **uyanırsa**, bu **H3'ü** (sessizliğin sebebi = kısa segment)
destekleyen ayrı bir bulgudur ve ayrıca yazılır.

⛔ **%15 bandı da şimdi yazılıyor**, sonucu görünce değil. Gerekçe: bu turda
uyuşan tek çift **%2** ayrışmıştı (1,71 ↔ 1,75) ve ayrışan çift **%170**;
aradaki boşluk bir mertebe genişliğinde, yani band **hangi tarafa düşeceğini
belirlemiyor** — yalnız *"ikisinden birine yakın"* demeyi tanımlıyor.

---

# SONUÇ — ölçüt mühürlendikten (`05570bf`) SONRA koşuldu

## Ölçüm

| take | pencere | süre | anti (acf) | sim (acf) | yarım | aracın hükmü |
|---|---|---|---|---|---|---|
| **`HUOjOJvPJc8`** | [8600, 9066] *(merkezden ±100 kare)* | 15,56s | **3,305** (0,837) | 3,272 (0,439) | — | `non_alternating` |
| `EP3Q3ttFwtU` | [3795, 4168] *(zaten yeterli)* | 15,56s | 1,710 (0,361) | — | 1,001 | `alternating` |
| `7g9PH1Qa4LM` | [975, 1525] *(zaten yeterli)* | 22,00s | 3,240 (0,183) | — | 1,840 | `alternating` |

## Ön kayıtlı okuma kuralının verdiği sınıf

**`HUOjOJvPJc8` antisimetrik tepe = 3,305 s.**
H1 bandı **2,836–3,836** ✅ · H2 bandı 1,418–1,918 ✗

> ## ⇒ **H1 — çevrim GERÇEKTEN iki katı. Harmonik çelişki GERÇEK.**
> Ve doğrulama beklenenden güçlü: çöküş-türevi periyot **3,336** ↔ bağımsız
> kanal **3,305** — **%0,9 içinde**, bu turun en sıkı uyumu.
> **H2 çürütüldü:** 3,305, 1,668'e hiçbir okumayla yakın değil.

**Ve H3 de desteklendi (ayrı eksen, ön kayıtta yazıldığı gibi):** kanal
**8,88 s'de sustu, 15,56 s'de uyandı** ⇒ önceki sessizliğin sebebi
**segment uzunluğuydu**. İki bulgu birlikte doğru: *H3 sessizliği açıklıyor,
H1 değeri.*

## 🔴 Bunun sonucu: taban 2'ye iniyor

Çelişki **gerçek** ⇒ `HUOjOJvPJc8` **düşer** ⇒ kullanılabilir take **2**
(`EP3Q3ttFwtU`, `7g9PH1Qa4LM`) ⇒ **M-C-04 (≥3) TUTMAZ ⇒ referans
ÜRETİLMEZ.** Ön kayıtta yazılan sonuç, ölçülerek geldi.

## ⭐ VE ÖNCEKİ RAPORUMU DÜZELTİYORUM: birim 1/3'te değil, 2/3'te doğrulandı

R22'de *"`dipsPerCycle=2`: 1'de doğrulandı, 1'de çelişti, 1'de ölçülemedi"*
yazmıştım. Uzatılmış pencere `HUOjOJvPJc8`i **ölçülemedi**den
**doğrulandı**ya taşıdı:

| take | çöküş-türevi | bağımsız kanal | ayrışma |
|---|---|---|---|
| `HUOjOJvPJc8` | 3,336 | **3,305** | **%0,9** ✅ |
| `EP3Q3ttFwtU` | 1,750 | **1,710** | **%2,3** ✅ |
| `7g9PH1Qa4LM` | 1,200 | **3,240** | **%170** ⚠️ |

⇒ **Birim 2/3'te doğrulandı.** Ve çelişkiyi çıkaran şey **birim değil, TEMPO**:
iki eğitmen aynı adımı ~1,9× farklı hızda yapıyor, ve harmonik kapı bunu
*"aynı çevrimde kesilmemiş"* diye okuyor.

## ⚠️ İki şeyi ÖLÇTÜM ama SINIFLANDIRMADA KULLANMIYORUM

**① `HUOjOJvPJc8` `non_alternating` okundu**, diğer ikisi `alternating`.
Aracın kendi cümlesi: *"simetrik kanalda yarım-çevrim tepesi YOK → adım
dönüşümlü değil"* — ve gerçekten sim (3,272) ≈ anti (3,305). Bu, take'ler
arasında **ölçülmüş bir fark**, ama **ne anlama geldiğini yorumlamıyorum**:
bir dans açıklaması üretmek (*"eğitmen yavaş gösteriyor"*, *"çift sekme"*)
alan iddiası olurdu ve elimde kaynak yok.
📌 Yine de birimi bozmuyor: çevrim 3,305 s ve çöküş aralığı 1,668 s ⇒ çevrimde
**2 çöküş** — `dipsPerCycle = 2` bu take'te de **tutuyor**.

**② Ayrışan take, en ZAYIF tepeye sahip olan** (`7g9PH1Qa4LM`, acf **0,183**;
diğerleri 0,361 ve 0,837). ⛔ **Bunu sınıflandırmada KULLANMIYORUM:** bir acf
eşiği **ön kayıtta yazılmadı**, ve sonucu gördükten sonra *"zayıftı, saymayalım"*
demek tam olarak yasaklanan hamledir. Sayı **olduğu gibi** raporlanıyor;
eşik yazmak isteyen varsa **başka bir turda, aday görmeden** yazar.
