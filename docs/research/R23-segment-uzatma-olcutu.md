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
