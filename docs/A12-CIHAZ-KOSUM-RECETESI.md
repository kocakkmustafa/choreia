# A12 — CİHAZ KOŞUM REÇETESİ (imzaya kadar hazır)

> **Ne için:** ölçütün `A12` kalemi — *"Cihaz gerçeği — gerçek cihazda en az A1 akışı
> koştu; kanıt: ekran kaydı ya da cihaz logu"*.
> **Bu belge ne DEĞİL:** bir izin talebi değil, bir **ölçüm**. Zincirin hangi
> halkasının eksik olduğu tek tek çalıştırılarak bulundu; kalan tek adım
> kurucunun/koordinatörün kalemi.
>
> Ölçüm tarihi **2026-08-13**, mühür `15e5382`.

---

## 0. ÖNCE: A1 BİTTİ, VE BU BELGE ONUN İÇİN VAR

Cihazda koşturulacak akış artık **var**: ilk açılış → tanıtım (düğmeyle) → stil →
ders → canlı oturum → **sonuç yüzeyi** → **depoya kayıt** (`C-268`). Profil geldiği
an koşu dakikalar sürsün diye reçete önden yazıldı.

---

## 1. ZİNCİR — ÖLÇÜLDÜ, VARSAYILMADI

| # | halka | durum | nasıl ölçüldü |
|---|---|---|---|
| 1 | **App ID** `com.yulalab.choreia` | ✅ **VAR** — `PDRAB4FYBS`, UNIVERSAL, seed `T5HZGYBWK8` | ASC API `bundleIds` (15 kayıt içinde) |
| 2 | **Cihaz kayıtlı** | ✅ **VAR** — `JC47C38DP6` · *Mustafa Kaan iPhone'u* · UDID `00008120-001804D83E13C01E` · ENABLED | ASC API `devices?filter[status]=ENABLED` |
| 3 | **Geliştirme sertifikası** | ✅ **VAR** — `72VHCWMV79` *Apple Development: kocakmkaan@outlook.com (W2BWHNL5L2)*, son kullanma **2027-01-31** | ASC API `certificates` (filtresiz) |
| 4 | **Sertifikanın ÖZEL ANAHTARI bu makinede** | ✅ **VAR** | `security find-identity -v -p codesigning` → `0BBEE7D3…` |
| 5 | **Provizyon profili** (`IOS_APP_DEVELOPMENT`) | ⛔ **YOK — TEK EKSİK HALKA** | bundle id'nin `profiles` ilişkisi **total 0**; makinede kurulu tek profil `BurunFarki AppStore 0623` |

> ### ⛔ Kalan tek engel: **profil**. Diğer dört halka yerinde.

---

## 2. 🪤 BU ÖLÇÜM BENİ YANLIŞ BİR P0'DAN DÖNDÜRDÜ — kaydı dursun

`apple_list_certificates(certificateType: "IOS_DEVELOPMENT")` → **`total: 0`**.
Bu sayıya güvenip *"geliştirme sertifikası hiç yok, engel profilden BİR ADIM ÖNCE"*
diye raporlanmak üzereydi — devir notunun teşhisini de yanlış ilan ederek.

Filtresiz liste **7 sertifika** gösterdi, ikisi geliştirme sertifikası; tipleri
**`DEVELOPMENT`**, `IOS_DEVELOPMENT` **değil**.

> ***BİR EŞLEŞMENİN YOKLUĞU, EŞLEŞENİN YOKLUĞU DEĞİLDİR — filtrenin kelimesi,
> ölçtüğün dizgenin kelimesi olmayabilir.***

Pozitif kontrolün **④ SEMANTİK** katmanı tam bunun için var: *aracın eşleştirmesi,
ölçtüğün DİLDE geçerli mi?* Araç çalışıyordu (①), dizge doğru hatta isabet ediyordu
(②), veri vardı (③) — kırılan yalnız dördüncüydü, ve dördü sorulmasa sıfır
"ölçülmüş" sayılacaktı.

---

## 3. NİYE PROFİLİ BEN OLUŞTURMUYORUM

`apple_create_profile` aracı elimde ve teknik olarak çalışır. Oluşturmuyorum çünkü
bir provizyon profili **hesap düzeyinde kalıcı bir kimlik artefaktıdır** — dışa
dönük, geri alması kurucunun işi olan bir değişiklik. Hattın dokunmadığı beş şeyden
biri olan *lisans/imza sahipliği* sınırının içinde okunur (`M-F-77`, `B1`/`B7`).

⛔ Ve ayrıca **kurucunun telefonuna kurulum yapılmaz** — bu ayrı ve kesin bir sınır.

---

## 4. REÇETE — profil geldiği an, sırayla

### 4a. Profili üretmenin İKİ yolu (biri yeter)

**(A) Xcode, otomatik imza** — proje zaten `CODE_SIGN_STYLE = Automatic`,
`DEVELOPMENT_TEAM = T5HZGYBWK8`. Xcode'da `ios/Runner.xcworkspace` açılıp hesap
girişliyken Runner hedefi seçilirse profil kendiliğinden üretilir ve kurulur.

**(B) ASC API** — `apple_create_profile` ile:

| alan | değer |
|---|---|
| `profileType` | `IOS_APP_DEVELOPMENT` |
| `bundleId` | `PDRAB4FYBS` |
| `certificates` | `72VHCWMV79` |
| `devices` | `JC47C38DP6` |

Sonra dönen `profileContent` (base64) çözülüp
`~/Library/MobileDevice/Provisioning Profiles/` altına `.mobileprovision` olarak
yazılır.

### 4b. Kurulum ve koşu

```bash
cd ventures/choreia/app
flutter build ios --debug --target-platform ios
xcrun devicectl device install app \
  --device 00008120-001804D83E13C01E \
  ~/choreia_buildout/ios/iphoneos/Runner.app
xcrun devicectl device process launch \
  --device 00008120-001804D83E13C01E com.yulalab.choreia
```

### 4c. Cihazda yürünecek akış (A12'nin kanıtı)

1. Uygulama **ilk kez** açılır → tanıtım ekranı → **`Open the catalogue`**
2. `hip_hop_foundations` kartı → `The bounce (not graded)` → **`Start`**
3. Kamera izni **verilir** (bu ekranın metni `Info.plist`'teki
   `NSCameraUsageDescription` ile birebir aynı — ölçüldü)
4. Birkaç bounce yapılır, sayaç dönene kadar beklenir → **`Finish session`**
5. **Sonuç yüzeyi** okunur: kaç tekrar okundu, ne kadar kamera süresi, ve
   *"What we were NOT checking"*
6. Geri → **Progress** sekmesi → pratiğin **içerikteki adıyla** göründüğü doğrulanır

**Kanıt olarak alınacak:** her adımda ekran görüntüsü, ve 4–6 arası **ekran kaydı**
(ölçüt "ekran kaydı ya da cihaz logu" diyor; kayıt tercih edilir çünkü sayaçların
gerçek zamanlı döndüğünü gösterir).

---

## 5. ⚠️ SİMÜLATÖR BU KALEMİ KAPATAMAZ — ve sebebi yapısal

Simülatörde `build → install → launch → ilk açılış ekranı` **koşturuldu ve ekran
görüntüsüyle kanıtlandı** (2026-08-13). Ama akışın **son üç adımı** simülatörde
prensipte imkânsız: iOS simülatöründe `AVCaptureDevice` yok ⇒ `motion_camera`
`noSuchCamera` döner ⇒ `LiveCameraUnavailable` çizilir ⇒ **oturum hiç başlamaz**,
`Finish` düğmesi tanımı gereği görünmez (`LiveView._sessionUnderway`), yazılacak bir
şey oluşmaz.

> ***A1'in "simülatörde elle yürü" şartı, canlı oturumdan SONRASINI simülatörde
> karşılayamaz. O kısım A12'nin kendisidir — ve A12 imzaya bağlıdır.***

Bu, iki kalemin birbirini kilitlediği yer: `A1`'in elle-yürüyüş yarısı `A12`'yi,
`A12` de profili bekliyor.

---

## 6. 🔴 AYRI BİR ARIZA — `flutter run` BU MAKİNEDE KIRIK

```
Xcode build done.                     826,1s
Xcode build is missing expected TARGET_BUILD_DIR build setting.
Could not build the application for the simulator.
```

Derleme **başarılı** bitiyor, `flutter run` sonrasında build ayarlarını okuyamıyor.
`flutter build ios --simulator` **aynı ağaçta sorunsuz** (198,5 s, `Runner.app`
üretildi) ⇒ arıza derlemede değil, `flutter run`'ın **build-settings okuma**
adımında.

⇒ **Cihaz koşumunda `flutter run` yerine `build` + `devicectl` kullanılmalı** (§4b),
yoksa 14 dakikalık bir derlemenin sonunda aynı duvara çıkılır.

⚠️ Ve ölçüm sırasında makinenin **load average'ı 812** idi (dört Motion hattı aynı
anda). Bu koşulda `simctl` çağrıları öldürülüyor ve WebDriverAgent hiç başlamıyor —
*bu arızanın kendisi de o pencerede ölçüldü*, tek başına bir makinede tekrarlanmalı.

---

## 7. ÖLÇEMEDİKLERİM, ADIYLA

1. ~~Cihazın şu an bağlı olduğu~~ → **ÖLÇÜLDÜ, VE DEĞİŞMİŞ.** `xcrun devicectl
   list devices` bugün **`unavailable`** diyor (`Mustafa Kaan iPhone'u` ·
   `iPhone 14 Pro Max (iPhone15,3)` · `882CC2EC-2E73-5B2A-8AA9-AE1A55CAB54F`).
   Devir notu 2026-08-13 00:5x'te **`available (paired)`** ölçmüştü.
   ⇒ ***DONANIMIN VARLIĞI, DONANIMIN ERİŞİLEBİLİRLİĞİ DEĞİLDİR*** — ve aradaki
   fark bir gün değil saatler içinde oluştu. Profil geldiğinde ilk iş cihazın
   yeniden `available` olduğunu **ölçmek**, varsaymak değil.
2. **Profil üretiminin gerçekten yeteceği** — üretilmedi, dolayısıyla imzanın
   uçtan uca tuttuğu **denenmedi**. Zincirin ilk dört halkası ölçüldü; beşincinin
   *yokluğu* ölçüldü, *yeterliliği* değil.
3. **Kameranın gerçek cihazda `motion_camera` ile açıldığı** — bu ailede hiçbir hat
   için ölçülmemiş olabilir; Choreia için kesinlikle ölçülmedi.
