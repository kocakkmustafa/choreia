---
tur: olcum
proje: choreia
guncelleme: 2026-08-12
---

# R22 — `cycleUnit` yapısal beyanı + hazırlamanın yeniden koşumu

**Sevk (koordinatör, 2026-08-12):** karar ① `dipsPerCycle = 2` · karar ②
`melbourne` `own`'da kalır. ⛔ **Ön koşulu ölç: `dipsPerCycle`'ın "çevrim"i ile
`beats`in "çevrim"i AYNI ŞEY Mİ?** Farklıysa DUR. ⚠️ *Alan bilgisine dayanma.*
⛔ Aday yeniden indirilmeyecek.

> ## SONUÇ TEK CÜMLEDE
> **Hazırlama 2/5 → 3/5 (taban SAYICA tuttu), ama referans YİNE kurulmadı:
> harmonik çelişki. Ve bağımsız kontrolüm birimin YERLEŞMEDİĞİNİ gösteriyor.**

---

## 1. Ön koşul — ÖLÇÜLDÜ, ve alan bilgisine dayanmadan

⛔ *"Running man ayak değiştirir"* demedim; bu bir **domain iddiası** olurdu.

### (a) İki alanın "çevrim"i kodda aynı şeyi mi gösteriyor?

| alan | **tek** tüketim yeri | ne tanımlıyor |
|---|---|---|
| `dipsPerCycle` | `periodSeconds = çöküşAralığı × dipsPerCycle` (`prepare_take.py:637`) | — |
| `periodSeconds` | **yalnız** take'ler ARASI harmonik-çelişki kapısı (`build_reference.py:822`) | *"faz ekseni take'ler arasında aynı şeyi anlatsın"* |
| `beats` | `bpm = beats × 60 / cycleSeconds` (`measure_tempo.py:231`) | — |
| `cycleSeconds` | `measure_tempo`: **antisimetrik** tepe | aracın kendi cümlesi: *"tam çevrim antisimetrik olan"* |

⇒ İkisi de **tam DÖNÜŞÜMLÜ çevrimi** adlandırıyor. **Birim çatışması YOK.**

### (b) Bu adım gerçekten dönüşümlü mü? — ÖLÇÜLDÜ

`measure_tempo.py`ın yöntemi: antisimetrik kanal (önde-gelen ayak; roller
değişince **işaret değiştirir**) tam çevrimde tekrarlar; simetrik kanal (yalnız
hareket enerjisi, hangi ayak olduğuna **kör**) **yarım** çevrimde. Oran ≈2 ise
adım dönüşümlüdür.

| take | oran | çevrim | karar |
|---|---|---|---|
| `EP3Q3ttFwtU` | **1,955** | 1,793s | **alternating** |
| `7g9PH1Qa4LM` | **2,000** | 1,680s | **alternating** |

⇒ Tam çevrim = 2 yarım çevrim = **2 kaldır-kaydır** = **2 çöküş**.
**`dipsPerCycle = 2` yazıldı**, gerekçesi ve **sınırları** dosyaya kaydedildi.

⚠️ **Kayda geçen sınır (ÖNCEDEN):** dönüşümlülük **5 take'in 2'sinde**
ölçülebildi, birim **beşine** uygulanıyor. *(Bu şerh, aşağıdaki §4'te
gerçekleşti.)*

## 2. 🪤 GİZLİ BİR ÇÖKME — yeni değil, YENİ ERİŞİLEBİLİR

Yapısal `cycleUnit` yazılır yazılmaz **beş take'in beşi de çöktü**:

```
_standing_still_floor → float(det["valueDeg"])
TypeError: float() argument must be ... not 'NoneType'
```

| adım | `knee_flexion_amplitude <` eşiği | |
|---|---|---|
| `hh_bounce` | **12°** | kalibre |
| `sh_running_man` | **`null`** | *"unset until harvest"* — **kasıtlı** |

Fonksiyon metrik+op eşleşmesine bakıp `float(None)` çağırıyordu. **Kendi
belgesi** doğru davranışı zaten yazmış: *"Eşik yoksa 0.0 döner (kapı kapanır,
**uydurulmaz**)."*

> ***BİR ÜST-AKIŞ KUSURU DÜZELTİLDİĞİ ANDA, ONDAN SONRAKİ DENETLENMEMİŞ
> VARSAYIM ERİŞİLEBİLİR HÂLE GELİR.*** C-207'nin şekil kapısı **girişi**
> korudu, **arkasındaki odayı** korumadı — ve oda, ancak giriş açılınca
> görünür oldu.

⛔ **Eşik uydurulmadı:** `null`, yokluğun kendisi olarak okunuyor ve fonksiyon
kendi belgelenmiş `0.0`'ına düşüyor. Kalibre eşik **bozulmadı** (ölçüldü:
`hh_bounce` → **12.0**, `sh_running_man` → **0.0**).

## 3. Yeniden koşum — ÖNCE/SONRA

| take | vekil yol (önce) | faz-sürücülü (sonra) |
|---|---|---|
| `HUOjOJvPJc8` | ✗ elendi | ✅ **hazır** (periyot 3,336) |
| `EP3Q3ttFwtU` | ✓ hazır | ✅ hazır (1,75) |
| `7g9PH1Qa4LM` | ✓ hazır | ✅ hazır (1,20) |
| `xapTBLAzP5M` | ✗ elendi | ✗ elendi — **yeni sebep** |
| `sv5-muy8720` | ✗ elendi | ✗ elendi — **yeni sebep** |

**2/5 → 3/5.** Ve kalan iki elemenin sebebi **değişti**: artık *"hareket
penceresi kamera penceresiyle örtüşmüyor"* (tüm-vücut **vekili**) değil,
*"aday pencerelerin hiçbirinde **nitelikli `knee_flexion` çöküşü** yok"* —
yani **sürücünün kendi ölçüsü**. ⇒ Aynı sayıda eleme, ama **kanıt sınıfı
yükseldi**: vekil sessizliği → doğrudan ölçüm.

## 4. 🔴 REFERANS YİNE KURULMADI — ve sebebi bu kez BİRİMİN KENDİSİ

```
✗ sh_running_man: harmonik çelişki — take'ler AYNI çevrimde kesilmemiş
  (periyot çiftleri ~2x: [[1.75, 3.336]])
```

`HUOjOJvPJc8` (3,336s) diğerinin **1,906 katı**.

📌 *(İlk denemem `--all` ile koştu ve **kütüphanedeki 30 take'i** hazırladı —
çelişki listesi alakasız videolarla doluydu. Rapor edilmeden önce doğru
popülasyonla tekrarlandı. **Bir kapının çıktısı, beslendiği popülasyon kadar
anlamlıdır.**)*

### Bağımsız kontrol — ve birim YERLEŞMEDİ

Aracın **kendi kanallarını** yeni segmentler üzerinde koşturdum:

| take | antisimetrik | çöküş-türevi periyot | uyum |
|---|---|---|---|
| `EP3Q3ttFwtU` | **1,71** | **1,75** | ✅ **%2 içinde — birim DOĞRULANDI** |
| `7g9PH1Qa4LM` | **3,24** | **1,20** | ⚠️ **2,7× ayrışıyor** |
| `HUOjOJvPJc8` | **tepe YOK** | 3,336 | ⚪ **ÖLÇÜLEMEDİ** |

> ### ⇒ `dipsPerCycle = 2`: 3 take'in **1'inde doğrulandı**, **1'inde çelişti**, **1'inde ölçülemedi.**

⚠️ **Aşırı okumayın:** `_best_peak` uzun bir segmentte **daha uzun bir
üst-çevrimi** (müzikal cümle) kilitleyebilir; `7g9PH1Qa4LM`in segmenti 10s'den
**22s'ye** çıktı ve antisimetrik tepesi 1,68 → 3,24'e taşındı. Bu bir
**artefakt olabilir** — *"çelişti"* diyorum, *"yanlış"* demiyorum.

⛔ **VE `dipsPerCycle`'I KAPI GEÇSİN DİYE OYNATMADIM.** Adayları gördükten
sonra birimi ayarlamak, tam olarak *"eşiği, onu geçmesini istediğin adayı
gördükten sonra yazmak"* olurdu.

📌 **Ve §1'de ÖNCEDEN yazdığım şerh gerçekleşti:** birim 2 take'te ölçülüp
5'ine uygulandı; çelişkiyi çıkaran take (`HUOjOJvPJc8`) tam olarak
**dönüşümlülüğü hiç ölçülememiş** olan. *Bir sınırı önceden yazmak onu
önlemez — ama gerçekleştiğinde ne olduğunu ADIYLA bilmeni sağlar.*

---

## Koordinatöre giden tek soru

**`HUOjOJvPJc8`in çevrimi gerçekten iki katı mı, yoksa çöküş algılaması bu
take'te her ikincisini mi kaçırıyor?** Üç sonuç da mümkün ve üçü de farklı
şey yaptırır:

| ihtimal | sonuç |
|---|---|
| take gerçekten yavaş | çelişki **gerçek** → take düşer, taban 2'ye iner |
| algılama yarı-oranda | **algılama** kalemi, birim değil |
| segment 8,88s ile fazla kısa (5 çöküş) | **örneklem** kalemi |

⛔ Üçünü de ben ayıramam: hangisi olduğu **ölçü tasarımı** sorusudur, ve
üçünün cevabı `dipsPerCycle`e **dokunmayı gerektirmiyor**.
