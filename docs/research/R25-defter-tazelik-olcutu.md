# R25 — DEFTER TAZELİK KAPISI: ölçüt, SONUÇTAN ÖNCE

> **A6** (`YAYIN-HAZIRLIK-OLCUTU.md`): *"DEFTER taze — gedik 0, **iki yönde** ·
> kanıt: tazelik kapısı exit 0"*.
>
> Bu dosya kapıyı **yazmadan önce** yazıldı. Sebebi ölçütün kendi uyarısı:
> ***"aynı kelime, iki katmanda iki birim olabilir"*** — ve A6'nın ön-girdisi
> tam bu yüzden **bir kez zaten yanlış çıktı** (koordinatör `✅` yazmıştı; hattın
> kapısı `closure_authority` **tek yönlüydü** ve **başka bir kapıydı**).

---

## 0. Neyi ölçmüyorum — sınır önce

`closure_authority.py` **kapanış otoritesini** ölçer: *"bir yer 'C-NNN kapandı'
diyorsa, C-NNN'in kendi durum sütunu da öyle demeli."* Bu **tazelik değildir**;
defter bir hafta bayat olsa da o kapı yeşil kalır. A6 başka bir şey istiyor:
**defterin sınırı ile ağacın sınırı arasındaki mesafe.**

⛔ Ve kapı-kurma kısıtı (ölçüt §C): *bir kapı ancak **A tablosundaki bir
kalemin** iddiasını doğruluyorsa kurulur.* Bu kapı **A6'nın kendi iddiasını**
doğruluyor — kapının kapısı değil.

---

## 1. İKİ YÖN — tanım (işlemsel, kelime değil)

| yön | kusurun adı | ne olur |
|---|---|---|
| **① iş → kayıt** | *commit indi, kaydı yazılmadı* | gerekçe **kaybolur**; sonraki oturum aynı çıkmaz sokağa girer |
| **② kayıt → iş** | *kayıt yazıldı, işi inmedi* | defter **fazla-satar**; sonraki oturum inmemiş bir işe güvenir |

⚠️ **İkisi aynı kova DEĞİL** — ve bu turda ölçüldü ki **aynı ceza da almamalı**:

### Ön ölçüm (girdi, bu dosyanın konusu değil ama kararı belirledi)

- **① yönü: 18 kimlik** — `C-183…C-194`, `C-197…C-201`, `C-204`. Commit mesajları
  bunları **anıyor** (18 gerçek commit, mesajları anlamlı), defterde **satırı YOK**.
  `C-183` ve `C-190` ham metinde **0 kez** geçiyor. ⇒ **kayıt hiç yazılmamış**;
  defterin kendi numaralandırması kırık.
- **② yönü: 92 kayıt** hiçbir commit tarafından anılmıyor. Ama bunların çoğunda
  **kayıp yok**: commit araştırma numarası anmış (`C-265` ↔ commit `c54c957` *"(R24)"*).
  Kayıt **var**, iş **inmiş**, yalnız **bağ** kurulmamış.

> ***BİR KAYDIN HİÇ YAZILMAMASI İLE ANILMAMASI AYNI KUSUR DEĞİLDİR — biri
> BİLGİ kaybı, öteki BAĞ kaybı.*** Aynı eşiğe bağlanırsa kapı ya 110 kalemle
> kalıcı kırmızı yanar (*ve kapatılmış kapı hiç olmayandan kötüdür*), ya da
> ikisini birden affeder.

---

## 2. KARAR KURALLARI — sonuç görülmeden yazıldı

### Yön ① — **taban çizgisi YOK, muafiyet YOK**

Commit mesajında anılan **her** `C-NNN` defterde bir satıra sahip olmalı.
Tüm geçmiş üzerinde. **Bugün 18 ihlal var ⇒ kapı doğduğu anda KIRMIZI yanacak.**

Ve bu **kasıtlı**: `closure_authority`'nin kendi yorumu diyor ki *bir kapı
doğduğu anda gerçek bir kusuru göstermelidir, yoksa neyi koruduğu bilinmez.*

**Çare — MEZAR TAŞI, yeniden inşa DEĞİL:** 18 kimliğe defterde birer satır açılır;
içerik **uydurulmaz**. Satır yalnız **köken** taşır: kimlik + commit SHA +
*"kayıt HİÇ yazılmadı, içerik geri getirilemez"*. Precedent aile kaydında var
(`M-F-252`, mezar-taşıyla kaldırılan envanter satırı).

⛔ **Commit KONUSU satıra alıntılanmaz.** Sebep ölçülmüş bir etkileşim:
`f9a1438`in konusu *"(C-143 kapandı)"* içeriyor; alıntılanırsa deftere
**yeni bir kapanış iddiası** enjekte eder ve `closure_authority` haklı olarak
öter. ⇒ SHA işaretçidir, anlatı değil.

### Yön ② — **taban çizgisi `C-266`, ADIYLA**

`C-266`dan **sonraki** her kayıt en az bir commit tarafından anılmalı.
Geçmiş **geriye dönük cezalandırılmaz**, çünkü ölçüldü ki orada **kayıp yok, bağ yok**
— ve olmayan bir konvansiyonu geçmişe uygulamak kusur bulmaz, **gürültü** üretir.
92 kalem **her koşumda sayıyla basılır**: susturulmuyor, **sayılıyor**.

### Uçuştaki kayıt — sınır ÖNCEDEN yazıldı

Kapı `gates.sh`ten **commit'ten ÖNCE** koşar. Turun kaydı deftere yazılmış ama
commit'i henüz inmemişse yön ② tanım gereği öter. Kural:

| ağaç | izin |
|---|---|
| **temiz** | gedik **tam 0**, iki yönde. Ahead-by-one bile **KIRMIZI** — temiz ağaçta uçuşta iş yoktur, o kayıt **inmemiş** demektir |
| **kirli** | defter **en fazla 1** anılmamış kayıt taşıyabilir, **ve o kayıt en büyük kimlik olmalı** |

⚠️ **Ve mühür anı hep temiz ağaçtır** (tur kapanışı: *ağaç temiz + push'lu*)
⇒ **her mühürde gedik 0 zorunlu**. Tolerans turun ortasında yaşar, sonunda ölür.

---

## 3. SABOTAJ PLANI — iki yön **AYRI AYRI** (koordinatör şartı)

Yeşil tek başına kanıt sayılmaz. Kabul için gereken ölçümler:

| # | sabotaj | beklenen |
|---|---|---|
| 1 | sağlam hâl | **yeşil** (kapı kırmızıya sıkışmış değil) |
| 2 | **yön ①**: commit anıyor, defterde yok | kırmızı, **kimlik adıyla** |
| 3 | **yön ②**: defterde var, commit anmıyor, ağaç **temiz** | kırmızı, **kimlik adıyla** |
| 4 | **pozitif ikiz**: aynı kayıt, ağaç **kirli**, ve **en büyük** kimlik | **yeşil** (yoksa kapı denetim değil **yasak** olurdu) |
| 5 | kirli ağaç, **iki** anılmamış kayıt | kırmızı (tolerans **1**) |
| 6 | kirli ağaç, anılmamış kayıt **en büyük değil** | kırmızı (gedik ortada, uçuşta değil) |
| 7 | **vakum**: defter boş / commit yok | kırmızı — ölçecek şey yoksa kapı **yeşil ötmez** |
| 8 | taban çizgisi **altındaki** anılmamış kayıt | yeşil, ama **sayıyla basılır** |

⛔ Çekirdek mantık **saf fonksiyon** olur (girdi: kayıt kümesi, atıf kümesi,
kirlilik) — sabotaj **gerçek deftere dokunmadan** koşsun diye. Gerçek depo
sabotajı ayrıca yapılır ve **geri alındığı bayt-bayt doğrulanır**.

---

## 4. Bu kapının ölçmediği (geri dönüş adresi)

1. **Defter git-dışı** ⇒ mtime'a bakılmıyor; `touch` ile tazelik **taklit
   edilebilir**. Kapı **içerik** ölçer, zaman değil — ve zamanı ölçmediğini
   böyle söylüyor.
2. **Bir kaydın DOĞRULUĞU** ölçülmüyor — yalnız **varlığı** ve **bağı**.
   *(Lissom dersi: 95 yeşil test yanlış-anatomi metnini görmedi.)*
3. **`R` numaraları** (araştırma dosyaları) atıf sayılmıyor. Ölçüldü: `R24`
   commit'i `C-265`i anmıyor ⇒ taban çizgisinden **sonra** bu konvansiyon
   **biter**; commit `C-NNN` anmak zorunda.
4. Mezar taşları **içeriği geri getirmez** — 18 turun gerekçesi **kalıcı olarak
   kayıp**, ve satır bunu **söyleyerek** duruyor.
