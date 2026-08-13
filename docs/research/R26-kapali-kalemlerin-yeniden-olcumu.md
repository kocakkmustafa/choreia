---
tur: olcum
proje: choreia
guncelleme: 2026-08-13
---

# R26 — Kapalı sayılan kalemlerin yeniden ölçümü

> **Niye:** ölçüt *"Beyan `✅` değildir"* diyor, ve devir notu §6 dört kalemi
> **adıyla** ölçülmemiş bırakmıştı. Bu belge onları tek tek çalıştırır.
> Mühür: `282a165`. Ölçüm tarihi **2026-08-13**.
>
> ⚠️ Bu turda hiçbir yeni **iddia** kapatılmadı — kapalı sayılanların
> **kanıtları** üretildi. *`bilinmiyor → ✅` bir kapatma değildir; mesafenin
> doğru ölçülmesidir.*

---

## ① A5 — "kapılar ENGELLİYOR", üç NON-PYTHON koşucuda ayrı ayrı

**Devir §6.2'nin şerhi:** *"A5'in 'engelliyor' kanıtı 16 python koşucusu
üzerinden; `flutter test` · `analyze` · `dart test` AYRI AYRI sabote
edilmedi."* Bir kapının **ötme sebebi** ölçülmeden, ötmesi kanıt değildir.

Her sabotaj **dosya EKLEYEREK** yapıldı, var olanı düzenleyerek değil: eklenen
dosya silinince ağacın eski hâline döndüğü `git status --porcelain` ile
**ölçülebilir** — *"geri koydum" bir iddia, `0` bir ölçüm.*

| sabotaj | `gates.sh` çıkışı | kırmızı koşucu | hangisi | geri dönüş |
|---|---|---|---|---|
| **⓪ TABAN** (sabotajsız) | **0** | **0** | — | — |
| düşen bir `flutter test` | **1** | **1** | `── flutter test` | ağaç **temiz** |
| çözülemeyen tip (`lib/`) | **1** | **1** | `── flutter analyze` | ağaç **temiz** |
| düşen bir motor testi | **1** | **1** | `── engine (dart test)` | ağaç **temiz** |

**⓪ TABAN POZİTİF KONTROLDÜR, süs değil:** o olmadan her kırmızı *"sabotaj işe
yaradı"* diye okunur — oysa ağaç zaten kırmızı olabilir ve sabotajın hiçbir
katkısı olmayabilirdi.

🔎 **VE İZOLASYON ÖLÇÜLDÜ, VARSAYILMADI:** her sabotaj **tam olarak bir**
koşucuyu kırmızıya çevirdi. *İzole olmayan bir sabotaj iki kapıyı birden
kırar ve hangisinin öttüğü bilinmez.*

⭐ **Beklenmedik bulgu, ve ölçütün kendisi hakkında:** `lib/` içine konan
çözülemeyen tip **yalnız `analyze`'ı** kırmızı yaptı; `flutter test` **yeşil
geçti**. Sebebi yapısal — `flutter test` yalnız testlerin **import ettiği**
kodu derler, ve o dosyayı hiçbir test import etmiyor.
> ***İKİ KOŞUCU AYNI ŞEYİ ÖLÇMÜYOR: `analyze`, testlerin göremediği kodu
> görür. Birini "diğeri zaten kapsıyor" diye kaldırmak, kapsanmayanı sessizce
> kapsanmış saymaktır.***

---

## ② A11 — imza zinciri: bir ÇIKARIM, artık bir ÖLÇÜM

**Devir §6.3'ün şerhi:** *"APK'nın hangi anahtarla imzalandığı `apksigner
verify` ile doğrulanmadı; 'debug anahtarı' bir ÇIKARIMDIR."*

Ölçülen APK, devir notundaki **aynı** artefakt (`md5 8dff984cbd8f7e1765129743a923f6b9`):

```
apksigner verify --print-certs -v app-release.apk
  Verified using v1 scheme (JAR signing):            false
  Verified using v2 scheme (APK Signature Scheme v2): true
  Number of signers: 1
  Signer #1 certificate DN: C=US, O=Android, CN=Android Debug
  Signer #1 certificate SHA-256: 99f2db59…95772
  Signer #1 key algorithm: RSA · key size: 2048
```

⇒ **Çıkarım DOĞRUYDU** ve artık çıkarım değil: APK **debug anahtarıyla**
imzalı. A11 ölçütü *"imzasız da olsa"* diyor, dolayısıyla kalem etkilenmiyor.

📌 **Yanında duran, daha önce hiç yazılmamış iki olgu:** imza **yalnız v2**
şemasında; **v1 (JAR) `false`**. Ve bu kimlik (`CN=Android Debug`) **Play'e
asla gitmemeli** — B1 keystore'u geldiğinde değişecek olan tam olarak budur.

---

## ③ A7 — tanık SABOTE EDİLİNCE ÖTÜYOR MU

**Devir §6.5'in şerhi:** *"A7 (b)'nin tanığı — `_RouteSpy` sabote edilince
ötüyor mu, bu turda TEKRAR ÖLÇÜLMEDİ (maddeler metne karşı OKUNARAK
doğrulandı)."*

Sabotaj: `_RouteSpy.didPush` hiçbir şey kaydetmesin.

| test | sonuç | mesaj |
|---|---|---|
| KATI okuma | 🔴 | *"KATI sayı beklenenden farklı. Ölçülen rotalar: `[]`"* |
| GEVŞEK okuma | 🔴 | *"GEVŞEK sayı beklenenden farklı. Rotalar: `[]`"* |
| YÜRÜYÜŞ EKSİK YÜRÜNMEDİ | ✅ **yeşil kaldı** | iddiası tanığa DEĞİL, widget anlık görüntülerine dayanıyor |

Dosya `md5` ile geri döndü (`77f32718…` ↔ `77f32718…`).

⇒ Tanık **ötüyor**, ve **izole**: tanığa dayanmayan test doğru biçimde yeşil
kaldı. *Bir assert'in yeşilliği, ötme yeteneğinin değil komşularının kanıtı
olabilir* — burada komşu ayrıştırıldı.

---

## ④ A7 — hattın KENDİ sayma kuralına ÇAPRAZ OKUMA

**Devir §6.6'nın şerhi:** *"`docs/design/GEZILEBILIRLIK-SAYMA-KURALI.md`
açılmadı — A7 aile sözleşmesinin metnine karşı ölçüldü, hattın kendi sayma
kuralına karşı ÇAPRAZ OKUNMADI."*

Okundu. **Dört sorunun dördü de testle uyuşuyor:** sekme sayımı (KATI 1 /
GEVŞEK 2) · iki bağımsız türetim · taze kurulumdan başlama · tanıtımın
**düğmeyle** geçilmesi · `DeviceBundle`ın cihaz arıza kipini taklit etmesi.
Belgedeki **KATI 3 · GEVŞEK 5** sayıları testin ölçtüğüyle aynı.

### 🔴 AMA ÇAPRAZ OKUMA BİR GEDİK BULDU — ve gediği BEN AÇTIM

Kural KATI'yı tanımlarken tek ölçüt veriyor: **`Navigator.push`**.
`C-268`'de eklenen sonuç yüzeyine **`pushReplacement`** ile gidiliyor ⇒
`didPush` **hiç çağrılmıyor**, `didReplace` çağrılıyor ⇒ kullanıcının
gerçekten vardığı bir yer, KATI sayıda **görünmez**.

Kuralın kendi cümlesi ise şu: *"KATI — ayrı ROTA. Bir yere GİDERSİN ve geri
DÖNEBİLİRSİN."* Sonuç yüzeyi bu tanımı **karşılıyor**: gidilir, ve oradan
(stil sayfasına) dönülür. Karşılamayan şey **vekil**: `Navigator.push`,
*"ayrı rota"* demenin kısayoluydu ve kısayol kırıldı.

> ***BİR ÖLÇÜTÜN KELİMESİ, ÖLÇTÜĞÜ ŞEYİN KELİMESİ OLMAYABİLİR.***
> (Aynı sınıf bugün ikinci kez ısırdı: `certificateType=IOS_DEVELOPMENT`
> filtresi, tipi `DEVELOPMENT` olan sertifikaları **0** saydı — §R26'nın
> kardeş belgesi `A12-CIHAZ-KOSUM-RECETESI.md` §2.)

**İki okuma, ve Choreia için sonuçları:**

| okuma | KATI | gerekçe |
|---|---|---|
| **(a) vekile sadık** — yalnız `didPush` | **3** | değiştirme bir itme değildir |
| **(b) tanıma sadık** — ayrı rota, gidilir ve dönülür | **4** | sonuç yüzeyi ayrı bir rotadır ve kullanıcı oraya varır |

⛔ **KARAR HATTIN DEĞİL.** Bu kural *beş hattın KARŞILAŞTIRILABİLİR sayması*
için koordinatör sevkiyle yazıldı; neyin sayıldığını tek taraflı değiştirmek,
karşılaştırılabilirliği **ölçmek yerine bozmak** olur. Ölçüldü, adıyla yazıldı,
koordinatöre taşındı. ⚠️ Ve mesele Choreia'ya özgü değil: **`pushReplacement`
kullanan her hat** aynı boşluğa sahip olabilir.

📌 Bu arada `test/first_walk_test.dart`in kendi tanığı **`didReplace`'i de
gözlüyor** ve budanmayan bir `trail` tutuyor — yani sonuç yüzeyine varıldığı
**ölçülüyor**; sayılmadığı yer yalnız A7'nin KATI rakamı.

---

## Bu belgenin ölçmediği — adıyla

1. **`motion_camera` gizlilik manifestinin podspec'i** — motion-core alanı,
   koordinatörde (devir §6.7). Dokunulmadı.
2. **Diğer dört hattın sayma kuralı** — kasıtlı okunmadı; koordinatör sınırı
   (*önce görmek, karşılaştırılabilirliği ölçmek yerine ÜRETİR*).
3. **`gates.sh`'in üçüncü hâli (`exit 2`, "ortam yok")** ayrı sabote edilmedi;
   bu turda sabote edilen üç koşucunun hiçbiri o dalı kullanmıyor.
