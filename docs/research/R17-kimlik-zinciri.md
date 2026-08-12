---
tur: olcum
proje: choreia
guncelleme: 2026-08-12
---

# R17 — Kimlik zinciri: leave-one-out + kabul edilmiş kaynaklarda kimlik sorusu

C-220'nin devamı. Koordinatör hükmü: *"hiçbiri (izle/çıkar/bırak) — ÖNCE
LEAVE-ONE-OUT, sonra karar"*, Ostinato O-095 emsaliyle (3× iyileşme elindeyken
ayrışma bulunamadı ve dışlama YAPILMADI).

---

## 0. Önce bir düzeltme: "koşulamıyor" dediğim engel YOKMUŞ

C-220'de *"kinematik karşılaştırma koşulamıyor, çünkü `hh_running_man`in step
config'i yok"* diye raporlamıştım. **Yanlıştı, ve hatanın şekli önemli:**
`probe_knee_dips --step hh_running_man` gerçekten `adım config'i bulunamadı`
diyor — ama `prepare_take.py --step hh_running_man --video …` **çalışıyor**
(ölçüldü: `ZpTgAZBYNrU` → 17,0s segment, periyot 1,38s). Tek aracın isimli
reddini "bu ölçüm yapılamaz"a genelledim. *Bir aracın duvarı, sorunun duvarı
değildir.*

---

## 1. Leave-one-out — 4 take, 5 bağımsız eksen

Yöntem: 4 kaynağın hepsi `prepare_take` ile hazırlandı, sonra **beş referans**
kuruldu — tümü (4) + her birinin dışarıda bırakıldığı dört küme. Karşılaştırma
`build_reference`ın **kendi konsensüs/dispersiyon matematiğiyle** yapıldı;
hizalayıcı İCAT EDİLMEDİ. Dört take de **aynı işlemden** geçti (şüpheliye özel
muamele yok — O-095'in ilkesi).

### Eksen 1 — medyan dispersiyon (tüm eklemler)

| küme | takeCount | medyan | Δ (4'lüye göre) |
|---|---|---|---|
| TÜMÜ | 4 | 7,33° | — |
| KV hariç | 3 | 6,53° | −0,80 |
| UO hariç | 3 | 11,88° | **+4,55** |
| Wd hariç | 3 | 6,58° | −0,75 |
| **Zp hariç ★** | 3 | 6,67° | **−0,66 (dördün EN KÜÇÜĞÜ)** |

### Eksen 2 — take çıkarılınca kaç eklem iyileşiyor

| çıkarılan | iyileşen | kötüleşen | ortalama Δ |
|---|---|---|---|
| KV | 8/17 | 9/17 | +0,01 |
| UO | 9/16 | 7/16 | −0,03 |
| **Wd** | **17/17** | **0/17** | **−9,25** |
| Zp ★ | 15/17 | 2/17 | −1,04 |

### Eksen 3 — periyot · Eksen 4 — ayna güveni

| take | periyot | çevrim | ayna |
|---|---|---|---|
| KV-sxd_pQ9w | 1,20s | 5 | flipped=False, **confident=False** |
| UO9Ehsdt2IE | 1,21s | 5 | flipped=True, confident=True |
| **Wd29rBfAzkI** | **1,67s** | **2** | flipped=False, **confident=False** |
| ZpTgAZBYNrU ★ | 1,38s | 12 | flipped=False, **confident=True** |

### Eksen 5 — içeriğin KENDİ hipotezi (en keskin sınama)

`sh_running_man.json`ın notu shuffle'ın running man'ini şöyle ayırıyor:
*"the slide is longer and the whole step stays lower"* → öyleyse Zp gerçekten
shuffle'sa, çıkarılınca **BACAK** eklemleri belirgin iyileşmeli.

Bacak eklemleri (hip·knee·thigh·shin, 8 eklem) ortalama Δ:
**Zp hariç −0,92°** · Wd hariç −0,82°. **Ayrım YOK** — ve 7,33°'lik küme
dispersiyonu ile onlarca derecelik tolerans bantları yanında bu gürültü
düzeyi.

### Hüküm (koordinatörün karar kuralı uygulanarak)

> *"Ayrışmıyorsa: başlık yanıltıcı ama hareket uyuşuyor → **tut**, ve
> 'başlık ≠ içerik, ölçüldü' diye kaydet."*

**`ZpTgAZBYNrU` BEŞ eksende de ayrışmıyor → TUTULUYOR.** Referans
değiştirilmedi. Başlığı yanıltıcı; hareketi, ölçülebilen her eksende diğer
üçüyle uyuşuyor.

**⚠️ Ölçümün sınırı, adıyla:** dispersiyon, faz ekseninde eklem-açısı UYUMUNU
ölçer; tek başına adım KİMLİĞİNİ belgeleyemez. Ölçebildiği şey, içeriğin
**öngördüğü farkın** (bacak geometrisi) var olup olmadığıdır — ve yok. Bu,
aracın destekleyebileceği en güçlü ifadedir; *"videoyu izledim"* değildir.

### Yan bulgu — ayrışan take BAŞKASI (hüküm koordinatörde)

`Wd29rBfAzkI` üç eksende sistematik aykırı: **17/17 eklem** onu çıkarınca
iyileşiyor (ort. −9,25°), periyodu 1,67s (diğerleri 1,20/1,21/1,38), ve yalnız
**2 çevrim** taşıyor. Referans bunu ZATEN biliyor: `thinTakes: ["Wd29rBfAzkI"]`
ve `provisionalReason` onu adıyla anıyor.
**Ama −9,25°'lik iyileşme KOL eklemlerinden geliyor** — bacaklarda katkısı
yalnız −0,82°. Bir bacak adımında kol farkı eğitmen üslubudur, adım kimliği
değil. **Karar bende değil:** bu bir referans-bileşimi hükmü.

---

## 2. Kabul edilmiş kaynaklarda "kimlik sorusu soruldu mu" süpürmesi

Koordinatör sevki: *"yayınlanmış referansların kabul edilmiş kaynaklarını tara
— hangilerine kimlik sorusu hiç sorulmadı? Sayıyı ve listeyi raporla; hüküm
verme, düzeltme yapma."* Gerekçe: ***sorulmamış bir soru, kayıtta geçmiş bir
sorudan ayırt edilemez.***

**Kapsam:** `pubspec.yaml`da bildirilen 4 referansın `sources` dizisindeki
**13 kabul edilmiş kaynak** (dışlananlar değil).

| referans | kaynak | kimlik sorusu kayıtta |
|---|---|---|
| hh_bounce | `1IVtcoqMrBA` | 🔴 yok |
| hh_bounce | **`4BRd2E8vBic`** | ✅ **VAR** — R13: *"derleme · segment bounce mı, rock mu"* |
| hh_bounce | `DEWpw4n8Lkw` | 🔴 yok |
| hh_roger_rabbit | `35sk_G8Vf9o` | 🔴 yok — yalnız R15 (rig indeksi), triyaj notu HİÇ yok |
| hh_roger_rabbit | `5MQEtoEKdEw` | 🔴 yok — aynı |
| hh_roger_rabbit | `selXuuAWI64` | 🔴 yok — aynı |
| hh_running_man | `KV-sxd_pQ9w` | 🔴 yok (⚠️ aşağıya bak) |
| hh_running_man | `UO9Ehsdt2IE` | 🔴 yok |
| hh_running_man | `Wd29rBfAzkI` | 🔴 yok |
| hh_running_man | `ZpTgAZBYNrU` | 🔴 yok — C-220'nin kaynağı |
| ss_shine_footwork | `SHGkSbJm2Iw` | 🔴 yok |
| ss_shine_footwork | `jjP8bKWCg9U` | 🔴 yok |
| ss_shine_footwork | `w4opJ2ezmd4` | 🔴 yok |

### **12 / 13.** Ve bu sayı ikinci katman pozitif kontrolle DÜZELDİ

**Katman 1 — süpürge ötebiliyor mu:** kimlik sorusunun sorulduğu BİLİNEN 4
id'de (R8'in `HUOjOJvPJc8`/`sv5-muy8720`, R14'ün `wwXH3fFdtog`/`I3aP1J-xH7c`)
dördünde de ✅ öttü. Kanal kör değil.

**Katman 2 — ötenler GERÇEKTEN kimlik sorusu mu:** ilk sayım 11/13 demişti.
`KV-sxd_pQ9w`nin eşleşmesi okununca **yanlış pozitif** çıktı — eşleşen metin
*"aynı kanal — James Deane zaten Roger Rabbit'te kullanılmış (farklı adım,
farklı video)"*, yani **kanal tekrarı** hakkında, bu videonun kimliği hakkında
değil. Gerçek sayı **12/13**. *Bir süpürgenin ötmesi, doğru şeye ötmesi
demek değildir.*

### Süpürmenin sınırı, adıyla

Bu bir **metin vekilidir**: araştırma notlarında o video id'sinin geçtiği
satırlarda kimlik/varyant sorusu aranıyor. "Kayıtta yok", sorunun
**sorulmadığını** kanıtlamaz — **yazılmadığını** kanıtlar. Koordinatörün
noktası tam da bu: ikisi ayırt edilemez, ve ayırt edilemiyorsa ikisi de aynı
şekilde güvenilmezdir.

⛔ Hüküm verilmedi, düzeltme yapılmadı — sevk öyle diyordu.

---

## 3. Kimlik probu YAYINLANMIŞ referanslara uygulandı — iki liste

Koordinatör sevki: leave-one-out probunu yayınlanmış referansların kaynaklarına
uygula; **yalnız içeriğinde ayırt edici hipotez BEYAN EDİLMİŞ** olanlara.
Hipotez yoksa prob soruyu soramaz → o kalemler *"mekanik olarak sorulamaz"*
diye adıyla listelenir, **uydurma hipotez kurulmaz**.

### 🔴 Sevkin öngörmediği YAPISAL ön koşul: prob **≥4 kaynak** ister

Leave-one-out, bir take'i çıkarıp kalanların konsensüsünü kurmaktır. 3 kaynaklı
bir referansta kalan **2**'dir ve `build_reference` kendi kapısıyla **reddeder**:

```
✗ hh_bounce: 2 kullanılabilir take — >=3 gerekli (M-C-04)
```

**`hh_running_man` cevaplanabilirdi çünkü 4 kaynağı vardı.** Yayınlanmış
diğer üç referansın **üçü de tam 3 kaynaklı** → hipotez olsa bile prob koşmaz.
Bu, 12/13 borcunun maliyetini değiştirir: borcun **9'u**, o referanslara
4'üncü bir kaynak inene kadar **proba açık değil**.

### LİSTE 1 — mekanik olarak CEVAPLANAN (1 referans · 4 kaynak)

| referans | kaynak | hipotez | sonuç |
|---|---|---|---|
| hh_running_man | `KV-sxd_pQ9w` | `sh_running_man.json` → bacak | ayrışma yok |
| hh_running_man | `UO9Ehsdt2IE` | aynı | ayrışma yok (çıkarılınca dispersiyon **artıyor**) |
| hh_running_man | `Wd29rBfAzkI` | aynı | **ayrışıyor — ama KOL eklemlerinde** (bacak −0,82°) → koordinatör hükmü: TUTULUR |
| hh_running_man | `ZpTgAZBYNrU` | aynı | ayrışma yok (§1, beş eksen) |

### LİSTE 2 — mekanik olarak CEVAPLANAMAYAN (3 referans · 9 kaynak)

| referans | kaynak sayısı | beyan edilmiş hipotez | niçin sorulamıyor |
|---|---|---|---|
| **hh_bounce** | 3 | ✅ **İKİ tane** — `dh_bounce.json`: *"dip daha uzun oturur, alçalış daha yavaştır"* (→ DİZ) · `hh_rock.json`: *"bounce dizden, rock GÖĞÜS ve KALÇADAN sürülür"* (→ GÖVDE/KALÇA) | **yalnız taban:** 3 kaynak → LOO 2'ye düşer, araç reddeder |
| **hh_roger_rabbit** | 3 | ❌ **YOK** — hiçbir adım notu onu karıştırılabilir bir adımdan ayırt etmiyor | **iki sebep:** hipotez yok **ve** taban |
| **ss_shine_footwork** | 3 | ⚠️ **yalnız RİTİM** — en yakın ayrım `ss_basic.json`: *"4 ve 8 sayıları TUTULUR, basılmaz"* | **iki sebep:** ritim sözleşmeyle **daima kapsam dışı** (`timing_verdict`/`bottom_beat_phase`) **ve** taban |

🪤 **Adıyla anılmaya değer:** kayıtta kimlik sorusu YAZILI olan **tek** kaynak
(`4BRd2E8vBic`, R13: *"segment bounce mı rock mu"*) tam da mekanik olarak
**sorulamayan** referansta duruyor.

### `hh_bounce` için TARAMA (prob DEĞİL) — sınırı adıyla

Prob koşamıyor ama 3'lü kümenin **kendi** dispersiyon çıktısı okunabilir. Bu,
take'e **ATFEDEMEZ**; yalnız *"bu referansta hipotez-ŞEKLİNDE bir uyuşmazlık
var mı"* der.

`disagreement` listesi 17 eklemden **10**'unu taşıyor; **listede OLMAYANLAR**
(= raporlanacak kadar uyuşmazlık göstermeyenler): `left_knee` · `right_knee` ·
`trunk_tilt` · `right_hip` · `right_thigh` · `right_shoulder` ·
`right_upper_arm`. Yani **her iki hipotezin öngördüğü bölge de** (diz · gövde/
kalça) listede yok; mevcut tek kalça girdisi `left_hip` = 3,0°, küme medyanının
(6,02°) altında. Listeye hâkim olanlar **kollar**: `left_elbow` 12,0 ·
`right_elbow` 12,0 · `left_forearm` 9,7 · `right_forearm` 8,4.

**POZİTİF KONTROL:** bu kanal diz/gövdeyi bildirebiliyor — `hh_running_man`in
listesi **17/17 eklemi** taşıyor (`left_knee`, `trunk_tilt` dahil). `hh_bounce`ta
bildirmemiş olması ölçülmüş bir sessizlik, kanal körlüğü değil.

**Okunuşu:** `hh_bounce`ta hipotez-şeklinde bir uyuşmazlık **görünmüyor**;
uyuşmazlık kol üslubunda toplanmış — bir diz-sürücülü adımda beklenen yer.
Bu bir **tarama sonucudur, hüküm değil**: hangi take'ten geldiğini söyleyemez.

---

## 4. DÖRDÜNCÜ KANAL — kimlik sorusu TRANSKRİPTTEN sorulabiliyor

`ballroom_latin_solo` hasadı sırasında tesadüfen ölçüldü: yeni inen kaynağın
kimliğini **eğitmenin kendi sözlerinden** doğruladım ("cha-cha" 19, rumba/
samba/salsa **0**). Sonra genelleştirildi.

**Ön koşul yok denecek kadar az:** transkript. Ve ölçüldü —
**kabul edilmiş 14 kaynağın 14'ünde de transkript VAR.**
Yani bu kanal, leave-one-out probunun üç ön koşulunun (≥4 kaynak · beyan
edilmiş hipotez · ölçüm taşıyan bölge) **hiçbirini** gerektirmiyor.

**Karşıtlık terimleri içeriğin KENDİ notlarından türetildi**, uydurulmadı:
`dh_bounce.json` (dancehall ≠ hip-hop bounce) · `hh_rock.json` (rock göğüs/
kalçadan, bounce dizden) · `sh_running_man.json` (shuffle ≠ hip-hop running
man).

### 🪤 Önce kendi sayacım YANLIŞTI — ve onu çıktıyı OKUYARAK yakaladım

İlk koşumda tam-sözcük sayımı kullandım. `ZpTgAZBYNrU`nun segmentinde
183,8s'de eğitmen *"same thing when you're **shuffling**"* diyor ama sayacım
`shuffle=0` raporladı: **"shuffling" içinde "shuffle" geçmiyor.** Çekimli
biçimler sessizce düşüyordu. Kök eşlemeye (`shuffl`, `bounc`) geçildi.
*Bir sayacın sıfırı, saydığı biçimin kapsamı kadar iyidir.*

### Tüm-video sonucu (14 kabul edilmiş kaynak)

| hüküm | sayı | kaynaklar |
|---|---|---|
| ✅ kendi adımı **baskın** | **11** | 1IV · DEW · ovIZ · 35sk · selX · KV · UO · Wd · **ZpT** · SHG · w4op |
| ⚠️ ikisi de zayıf/eşit | 2 | `5MQEtoEKdEw` (4↔4) · `jjP8bKWCg9U` (0↔0) |
| 🔴 karıştırılabilir **baskın** | 1 | `4BRd2E8vBic` (bounce 32 ↔ rock **50**) |

### Segment düzeyi — asıl soru, ve iki sonucu da değiştiriyor

Tüm-video sayımı **dersin konusunu** ölçer, **seçilen segmenti** değil.
`l3r4bPhikGQ`'nun dışlaması zaten segment düzeyinde yapılmıştı; aynısı
uygulandı (transkript zaman damgaları × hazırlanan segment penceresi):

- **`4BRd2E8vBic`** — segment 628–649s. Pencerede **bounce 0 · rock 0**;
  tek yakın replik 612,5s *"Teaching these things separate"*.
  → **Tüm-video kırmızısı segmente TAŞINMIYOR.** Hüküm: *"rock çıktı"*
  DEĞİL, **"segment kimlik konuşması taşımıyor"** — ne aklandı ne mahkûm.
  Kendi 🔴 okumamı düzeltmem gereken yer burasıydı.
- **`ZpTgAZBYNrU`** — segment 177–194s. Pencerede **running man 2 · shuffl 1**.
  Kendi adımı baskın. → **C-220'nin ÜÇÜNCÜ bağımsız kanıtı** (leave-one-out'un
  beş ekseni · tüm-video sayımı · segment sayımı). Koordinatörün TUT hükmü
  üçüncü kez, bağımsız bir aletle doğrulandı.

### Ne değişti: borcun ŞEKLİ

12/13'lük *"kimlik sorusu kayıtta yok"* borcu, prob için **9/12 kapalıydı**
(≥4 kaynak ön koşulu). Bu kanal onu **14/14 açık** hâle getiriyor — çünkü
transkript zaten var. **Kalan iş bir ARAMA turu değil, bir OKUMA turu.**

⛔ **Sınırı adıyla:** transkript eğitmenin **söylediğini** ölçer, **yaptığını**
değil. Segment düzeyinde bile bu bir *ders konusu* kanıtıdır, hareket kanıtı
değil — leave-one-out'un yerine geçmez, **onun ulaşamadığı yerde** konuşur.
Ve sessiz bir segment (`4BRd2E8vBic`) hiçbir şey söylemez: **sessizlik
aklanma değildir.**
