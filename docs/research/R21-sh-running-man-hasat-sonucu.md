---
tur: olcum
proje: choreia
guncelleme: 2026-08-12
---

# R21 — `sh_running_man` hasat turu: SONUÇ

**Ön kayıt:** [R20](R20-shuffle-running-man-adaylar.md), hasat sonuçlarından
**önce** yazıldı ve commit'lendi (`493d8a9`).

> ## 🔴 TURUN SONUCU: TABAN TUTMADI — REFERANS ÜRETİLMEDİ
> **2/5 take hazır**, M-C-04 **≥3** istiyor. Bu bir başarısızlık raporu değil,
> **ölçüm sonucu**: aşağıda hangi aşamanın neyi elediği, sayısıyla.

---

## 1. Hasat — dört ayrı sınıf, tek kovaya konmadı

| video | eğitmen | sınıf | ölçüm |
|---|---|---|---|
| `xapTBLAzP5M` | Tori Nishino | ✅ **indi** | 266,9s · üst-gövde 1,00 · keskinlik 213,9 |
| `HUOjOJvPJc8` | Marbiik | ✅ **indi** | 621,3s · 0,92 · 132,5 |
| `EP3Q3ttFwtU` | Caroline Kay | ✅ **indi** *(403'ten sonra)* | 426,8s · 0,92 · 2909,1 |
| `7g9PH1Qa4LM` | We Dance Hard | ✅ **indi** | 160,8s · 0,75 · 124,2 |
| `sv5-muy8720` | Howcast | ✅ **indi** | 131,5s · 0,67 · 116,5 |
| `a-1rfX4P6nU` | aTrueBelgian | ⛔ **rig triyaj reddi** | üst-gövde **0,33 < 0,60** — malzeme reddi |
| `6m23DNL5idw` | Anna Shuffle | ⚪ **araç arızası** | HTTP 403 — rig reddi **DEĞİL** |

**5 kaynak / 5 ayrı eğitmen indi.** Beşinin de damgası: kanonik rig
`63a0b3ed…` · `dirty=false` · `romMode: active` · `referenceEligible: true`.

📌 `EP3Q3ttFwtU` ilk turda 403 almıştı, yeniden denemede indi ⇒ ***"araç
arızası" sınıflandırması DOĞRUYDU: malzeme uygundu, araç ulaşamamıştı.***

⚠️ **Ön kayıtlı Almanca riski GERÇEKLEŞMEDİ — ama "atlatıldı" da demek
yanlış:** `6m23DNL5idw` hiç inmedi, yani dil riskine **hiç varılmadı**.
***Erken bir aşamada düşen bir kalem, sonraki aşamanın riskini geçmiş
sayılmaz — ULAŞILMAMIŞ sayılır.***

## 2. Hazırlama — 2/5, ve üç eleme AYNI sebeple

| video | durum | segment | periyot |
|---|---|---|---|
| `EP3Q3ttFwtU` | ✓ hazır | 5,96s | 1,84s |
| `7g9PH1Qa4LM` | ✓ hazır | 10,0s | 1,68s |
| `xapTBLAzP5M` | ✗ elendi | — | — |
| `HUOjOJvPJc8` | ✗ elendi | — | — |
| `sv5-muy8720` | ✗ elendi | — | — |

Üçünün sebebi birebir aynı: **"no movement window overlaps a camera-clean
window"**. ⛔ Bu cümleyi *"malzeme kötü"* diye okumadım — kayıt **iki tarafı
da** taşıyor, ölçtüm:

| video | hareket penceresi | kamera penceresi | **en büyük örtüşme** |
|---|---|---|---|
| `xapTBLAzP5M` | 2 | 3 | **0 kare** *(iki liste de tam)* |
| `sv5-muy8720` | 1 | 2 | **0 kare** *(iki liste de tam)* |
| `HUOjOJvPJc8` | 3 | 6 | **121 kare** *(kamera listesi 6'da kırpık ⇒ ALT SINIR)* |

→ Ne hareket yok, ne temiz kamera. İkisi **ayrı yerlerde**.

## 3. 🔴 KÖK SEBEP — ve deponun KENDİ kaydında zaten ölçülmüş

`prepare_take.py` her beş koşumda aynı satırı bastı:

> `[kinematic_unit] 'sh_running_man': cycleUnit dizge ('one lift-and-slide per
> count') — faz-sürücülü seçim ATLANIYOR, eski (ayak-bileği çapa) yol
> kullanılıyor`

**`cycleUnit` yapısal olan tek iki adım, ÇÖZÜLMÜŞ olan ikisi:**

| adım | `cycleUnit` | durum |
|---|---|---|
| `hh_bounce` | **dict** (`driver`+`dipsPerCycle`+`derivedFrom`) | ✅ referansı var |
| `hh_rock` | **dict** | ✅ |
| `sh_running_man` · `sh_t_step` · `dh_bounce` · `sm_samba_no_pe` | **dizge** | ❌ referansı yok |
| `ss_basic` · `ss_shine_footwork` | **null** | — |

Ve yedek yolun bu adım sınıfında **kör olduğu, bu depoda ZATEN ÖLÇÜLMÜŞ** —
`prepare_take.py`ın kendi yorumu (C-207 / M-F-235):

> *"`4BRd2E8vBic`'te 896 saniyelik, **193 nitelikli çöküş** taşıyan bir derste
> tüm-vücut pencereleme **5 aday üretti ve dördü o çöküşlerin HİÇBİRİNİ
> içermiyordu.** Tüm-vücut enerjisi 'adım oluyor mu'nun **VEKİLİDİR** ve
> bounce gibi bedeni yerinde tutan bir adımda vekil adımla anlaşmıyor."*

Ve `sh_running_man` tam o sınıf — adımın **kendi notu**: *"the whole step
stays lower"*.

> ### ⇒ ÜÇ ELEME, DEPONUN KENDİSİNİN YETERSİZ ÖLÇTÜĞÜ BİR YOLDAN ÇIKTI.
> **Sınıf: `ÖLÇÜLEMEDİ`, `KANIT_YOK` DEĞİL.** *Bir sessizlik, aletin
> körlüğüyle açıklanabiliyorsa o bir ölçüm değildir* — ve burada körlük
> **varsayılmadı, deponun kendi kaydından okundu.**

### ⛔ VE DÜZELTMEYİ YAZMIYORUM — çünkü türetim TEK DEĞİL

İki faz zinciri **yapı olarak birebir aynı**: 4 faz · aynı sürücü
(`knee_flexion_mean`) · aynı op dizisi (`>` → `decreasing` → `localMinimum` →
`increasing`). `hh_bounce`ın gerekçesi *"zincir top→drop→bottom→rise, `rise`
terminal, **demek ki çevrimde tam BİR diz çöküşü var**"* diyor ve aynı okuma
`top→lift→bottom→slide` için de yürür.

**AMA sayım birimi aynı değil:**

| | `hh_bounce` | `sh_running_man` |
|---|---|---|
| `beats` | **1** | **2** |
| `countLabels` | `["1"]` | `["1","2"]` |
| dizge `cycleUnit` | — | *"one lift-and-slide **per count**"* |

⇒ Faz zinciri **bir** kaldır-kaydır anlatıyor, adım **iki sayıma** yayılıyor
(running man ayak değiştirir). `dipsPerCycle` **1 mi 2 mi**, *"çevrim"in* ne
demek olduğuna bağlı — ve bu **beyandır, çıkarım değil**.

🪤 Bu, bugün salsa'da düştüğüm tuzağın birebir aynısı: `countLabels`ın
**yapısal düzenini** kural sanmak. ***Düzen ≠ kural.*** `cycleUnit` yazmak
**ölçü tasarımıdır** → koordinatörün. **Yazılmadı.**

## 4. Kimlik okuması — referans yok, ama transkript kanalı KOŞTU

⚠️ `identity_read.TERMS` haritasında `sh_running_man` **kaydı yok** — kanal bu
adım için **kablolu değil**. Haritayı **değiştirmeden**, aracın kendi
`read_lesson(video, terms)` arayüzünden ölçtüm (⛔ elle sayaç **yazmadım** —
bugün üç kez düştüğüm kusur). Terimler adımın **kendi notundan** türetildi
(*"Shuffle's running man is **not hip-hop's**"*): ayırt eden şey **dans adı**,
adım adı değil (*"running man"* iki dansta da geçer, ayırt etmez).

| video | hüküm | own | conf | söz |
|---|---|---|---|---|
| `HUOjOJvPJc8` | **TEYİT** | 13 | 0 | 2222 |
| `xapTBLAzP5M` | **TEYİT** | 4 | 0 | 753 |
| `EP3Q3ttFwtU` | **TEYİT** | 3 | 0 | 1211 |
| `sv5-muy8720` | **TEYİT** | 1 | 0 | 342 |
| `7g9PH1Qa4LM` | **ÖLÇÜLEMEDİ** | 0 | 0 | 232 |

**✅ Ön kayıtlı risk #3 ÖLÇÜMLE KAPANDI:** `EP3Q3ttFwtU` *"dans adlandırılmamış
— hip-hop RM olabilir"* diye işaretlenmişti. Transkript: **shuffl×3,
hip-hop×0** ⇒ TEYİT.

**✅ Ve teyitler ÖLÇÜLMÜŞ bir sıfıra dayanıyor:** karşıtlık terimleri
(`hip hop`, `hip-hop`) ASR-kırılgan **değil** (ölçüldü: çok sözcüklü, parçaları
sözlükte) ⇒ `conf_blind=false` ⇒ dört TEYİT *"çürütme kaçmış olabilir"*
sınıfına düşmüyor.

**🪤 AMA KENDİ TERİM SEÇİMİM BİR HÜKÜM SINIFINI DEĞİŞTİRDİ — ölçüldü:**

| `7g9PH1Qa4LM` terim listesi | hüküm |
|---|---|
| `own=[shuffl, melbourne]` | **ÖLÇÜLEMEDİ** |
| `own=[shuffl]` | **KANIT_YOK** |

Sebep: `melbourne` **sözlükte yok** ⇒ `asr_fragile=true` ⇒ bu satırdaki her
sıfır şüpheli sayılıyor. Araç **doğru** davranıyor (fail-closed), ama sınıf
sınırını çizen şey **benim terim listem**, ve o liste `TERMS`e **kablolu
değil**. ⇒ ***Bir ölçümün sınıfı, ölçüm parametresine bağlıysa, o parametre
hükmün parçasıdır ve kayda geçmelidir.*** Kablolama **ölçü tasarımı** →
koordinatörün.

**🔴 VE EN KESKİNİ:** hazırlamayı geçen **iki** take, `EP3Q3ttFwtU` (TEYİT) ve
`7g9PH1Qa4LM` (**ÖLÇÜLEMEDİ**). Yani taban tutsaydı bile, **hayatta kalan
malzemenin yarısı kimlik bakımından ölçülmemişti.**

## 5. `style.json` — KABLOLANMADI, ve doğru sebeple

Koordinatör hükmü: kablolama yetkili **ama yalnız referansı İNMİŞ stil için**
(*"sahte/boş kurs asla listelenmez"*). **Referans inmedi** ⇒ kablolama
**yapılmadı**. Kısıt kendi işini gördü.

## 6. ③ SÜRE ÜST SINIRI — sevk edilen ölçüm YAPILDI, eşiğe DOKUNULMADI

**Soru:** kabul edilmiş külliyatta uzun-form bir kaynak var mı, ve seçilen
segmenti geçmiş mi?

**Cevap: VAR, ve GEÇMİŞ.**

| kaynak | süre | referans | sevk edildi mi |
|---|---|---|---|
| `DEWpw4n8Lkw` | **1443,7s** | `hh_bounce.json` | ✅ `pubspec.yaml:106` |
| `1IVtcoqMrBA` | **902,3s** | `hh_bounce.json` | ✅ |

`probe_candidates.py` `MAX_SECONDS = 900`. ⇒ **Sevk edilen bir referansın
kaynağı, bugünkü probe'un üst sınırının 1,6 katı** — ve segmenti tüm boru
hattını geçmiş.

> ### ⇒ ÜST SINIR FAZLA FİLTRELİYOR. **Kalem AÇILIR** (koordinatörün kendi ölçütü).
> Vekil (*"uzun video = tam ders = adım izole değil"*) amaçtan **ayrışmış**:
> külliyat 1443,7s'lik bir dersten temiz segment çıkarmış.

⚠️ **AMA BU İKİ ADAYIMI AKLAMAZ — ve bunu ayırmak şart:** elenen ikisi
**1702s** ve **1993s**, yani **en yüksek kabul edilmiş öncülün de üstünde**.
Ölçüm *"900 düşük"* diyor, *"1993 uygun"* **demiyor**. ***Bir eşiğin fazla
filtrelediğini kanıtlamak, o eşiği geçen HER adayı aklamaz*** — ve tabanı
adaylara bakarak yazmak zaten yasak. ⛔ `MAX_SECONDS` **değiştirilmedi**.

---

## Özet — bu tur ne KAPADI, ne AÇTI

| kalem | sonuç |
|---|---|
| `sh_running_man` referansı | 🔴 **üretilmedi** — taban 2/5 < 3 |
| Üç elemenin sınıfı | **ÖLÇÜLEMEDİ** (vekil yol, deponun kendi ölçtüğü körlük) |
| `EP3Q3ttFwtU` kimlik riski | ✅ **kapandı** — TEYİT |
| `7g9PH1Qa4LM` kimlik riski | ⚪ **ÖLÇÜLEMEDİ** |
| `a-1rfX4P6nU` | ⛔ **malzeme reddi** (üst-gövde 0,33) — kapalı |
| `6m23DNL5idw` | ⚪ **araç arızası**, dil riskine **ulaşılmadı** |
| ③ süre üst sınırı | ✅ **ölçüldü — kalem AÇILIR**, eşik değiştirilmedi |
| `style.json` kablolama | ⛔ **yapılmadı** (referans yok) — kısıt işini gördü |
| `cycleUnit` beyanı | ⛔ **yazılmadı** — 1 mi 2 mi belirsiz, ölçü tasarımı |

**Koordinatöre giden iki karar:** ① `sh_running_man.cycleUnit` yapısal beyanı
(`dipsPerCycle` 1 mi 2 mi) ② `identity_read.TERMS`e `sh_running_man` kaydı.
İkisi de bu turun tıkandığı yer, ve ikisi de **ölçü tasarımı**.
