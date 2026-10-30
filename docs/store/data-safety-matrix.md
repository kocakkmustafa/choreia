# Data Safety (Play) + Privacy Nutrition Label (Apple) Matrisi — CHO-P0-002

## 18 Ekim 2026 · b5ff2c4 final binary karşılaştırması

Paket kaynağı `b5ff2c4fe48745a1fac78103c1fb245a034affc3`, sürüm `1.0.0 (3)`.
Yeni IPA/AAB üretilmedi; mevcut doğrulanmış binary'ler okundu. IPA'daki 9
privacy manifest ve Runner'ın 6 veri tipi önceki doğrulanmış paketten
anlamsal/byte düzeyinde değişmemiştir. Runner plist'i kaynakla parse edilmiş
olarak eşittir; tüm türler Linked=true, App Functionality, Tracking=false;
9 manifestin tamamında tracking=false. Merged Android izinleri mevcut final
makbuzuyla aynı; mikrofon ve konum izni yoktur. BILLING izni satışın açık
olduğu anlamına gelmez. [Makine-okur form adayı](privacy-form-candidate.v1.json).

18 Ekim 00:31:52 UTC Play kontrolünde üretim başvurusu kapalı, kurulum 10/11,
kayıtlı testçi 0; en az 12 kullanıcının kesintisiz 14 gün kapalı teste kayıtlı
olması isteniyor. Yerel paket hazırlamak bu süreyi başlatmaz.

18 Ekim önceki salt okunur veri güvenliği formunda ad/e-posta/kullanıcı ID'si/
diğer kişisel bilgi seçili; konum ve tanılama grupları seçilmemiştir. Hesap silme
URL'si `https://yulalab.com/en/privacy/motion#motion-account-deletion`, kısmi veri
silme ve politika URL'si `https://yulalab.com/en/privacy/motion` kaydedilmiştir.
Bunlar form readback'idir; talebin gerçekten sonuçlandığı kanıtı değildir.
Hesap isteğe bağlı olduğundan Play'de e-posta/ID uygulama düzeyinde opsiyonel
olabilir; seçilen hesap akışında e-posta/ID yine gereklidir. Tanılama/konum ve
diğer bilgi için gerçek sağlayıcı kapsamı/opsiyonellik ayrıca doğrulanmalıdır.

Yerel binary ↔ kaynak ↔ taslak eşliği PASS. Canlı provider güvenlik günlükleri,
saklama/erişim/silme, gerçek ağ/hesap akışı ve OS yedeği kabulü açık. Bu takipte
ASC hedefi `authResult=FAILED` ile resmi giriş sayfasına döndüğünden
privacy değerleri okunamadı. Gerekli tek ortak portal adımı, kullanıcının
mevcut Apple hesabında güvenli giriş/2FA yenilemesidir; alternatif erişim,
sözleşme kabulü veya otomatik giriş denemesi yapılmadı. Play kategorileri Apple tiplerinden otomatik
üretilip konsola yazılmadı; hiçbir provider/portal değeri değiştirilmedi.


İlk ölçüm 2026-08-19, hesap güncellemesi 2026-09-25. Kaynaklar: `ios/Runner/PrivacyInfo.xcprivacy`
(C-266/A8, ölçülerek dolduruldu) · `ios/Runner/Info.plist` · `android/app/src/main/AndroidManifest.xml`
· `tools/network_dependency_check.py` (yükleyici-izi kapısı, 5 öz-test) · `tools/privacy_manifest_check.py`.
2026-09-25 kaynak durumu: ortak Motion hesabı Core path bağımlılığıyla eklendi;
üretim şeması/işlevleri kuruldu, ancak gerçek kullanıcı uçtan uca kanıtı ve mağaza formu onayı henüz yok. Hesap ve sağlayıcı alanlarının
ayrıntısı `account-data-safety-draft.md` dosyasında. Aşağıdaki 2026-08-19
notları tarihsel ölçüm olarak tutulur; güncel hüküm yeni satırlardır.

**2026-09-26 kaynak uzlaştırması:** Satışın ertelendiği ilk sürüm için
aşağıdaki güncel tablolar düzeltilmiştir. Çözümlenen `motion_account`
paketinde `motionPaidFeaturesAvailable=false`; üyelik/satış girişleri ve
paid-session yolu kapalıdır. O tarihteki üç hesap türü açıklaması,
2026-09-27 sağlayıcı günlükleri uzlaştırmasıyla genişletildi;
purchase-history türü yoktur. 2026-09-25 sağlayıcı/SMTP bilgisi bu tur yeniden ölçülmedi.
Kaynak kontrolü final SDK/network, fiziksel cihaz veya konsol kabulü değildir.
Önceki satın alma beyanı sonraki satış planını mevcut durum gibi gösteriyordu;
tarihsel metnin anlamı §4'te korunur, güncel form adayı aşağıdadır.

**2026-10-02 kaynak uzlaştırması:** `PrivacyInfo.xcprivacy` yeniden okundu:
e-posta, isteğe bağlı ad, kullanıcı ID'si, Other Diagnostic Data,
Coarse Location ve Other Data Types olmak üzere altı tür var; hepsi
hesaba bağlı, uygulama işlevi için ve tracking=false. Son üç türün
2026-09-26 tarihli ortak sağlayıcı makbuzu ve sınıflandırma gerekçesi
`account-data-safety-draft.md` içindedir. Reklam/analytics SDK'sı olmaması
sunucudaki IP/user-agent güvenlik günlüklerini yok saydırmaz. Aşağıdaki
Play eşlemeleri form adayıdır; güncel sağlayıcı saklama/SDK trafiği ve
konsol readback'iyle finalleştirilir. Bu kaynak onarımı yeni canlı veri
ölçümü veya mağaza formu değişikliği değildir.

## 17 Ekim 2026 · final adayın gerçek kapsamı

`642a7d0` kaynaklı `1.0.0 (3)` IPA/AAB okundu; paketler yeniden üretilmedi.
[Hesap gizlilik taslağı](account-data-safety-draft.md) artık Salsa'nın
48 ders kaydı yanında diğer 38 birimin ayrı çalışma günlüğünü, SDK oturum
saklamasını, altı yerel dosya yolunun silinmesini ve OS yedek sınırını içerir.
Bunlar yerel kayıt/hesap ayrımıdır; yeni sunucu collection türü değildir.

IPA'daki 9 privacy manifestin tamamında tracking=false. Runner'ın 6
collected-data beyanı kaynak plist ile anlamsal olarak aynı; SDK required-reason
kayıtları da paket içinden okundu. Android merged manifestte INTERNET/CAMERA'ya
SDK'ların ACCESS_NETWORK_STATE, WAKE_LOCK ve BILLING izinleri ile uygulamanın
receiver izni eklenir; mikrofon/konum izni yoktur. Aşağıdaki kaynak manifest
satırları bu nedenle birleşik paket envanteri diye okunmamalı.

Apple/Play tabloları hâlâ **yerel form adayıdır**. Paylaşım/retention, gerçek
hesap ve provider trafiği, konsol readback'i veya OS yedek kabulü kapanmadı.
Play dış silme URL adayı mevcut https://yulalab.com/en/privacy/motion sayfasıdır;
silme bölümü support@yulalab.com isteğini ve uygulama içi yolu açıklar.
Form alanına yazılmadı; talep gönderilmedi. [Google'ın gereksinimi](https://support.google.com/googleplay/android-developer/answer/13327111),
uygulama içi silmeye ek olarak uygulamayı tekrar yükletmeden istek alabilen
çalışır web yolu ister; mevcut politika/support yolu final form incelemesine
hazırdır. [Kabul adımları](RELEASE-ACCOUNT-SANDBOX-CHECKLIST.md).

## 0. Baseline — ne VAR, ne YOK (formu doldurmadan önce)

- Ortak Motion hesap/giriş arayüzü **VAR**; 2026-09-25 yerel path açıklaması
  tarihseldir. 2026-09-26 `package_config.json` pinli git Core'un pub-cache
  paketini çözümler; `MOTION_SUPABASE_URL`/`MOTION_SUPABASE_PUBLISHABLE_KEY`
  yapılandırması gerekir.
  Ders/seans geçmişi hâlâ yalnız cihazda; hesap servisine senkronize edilmez.
- İlk Salsa kursunun görüldü/çalışıldı/öz beyan kayıtları
  `lib/app/course/salsa_progress.dart` ile konuk/hesap kapsamına ayrılmış
  JSON'a yazılır. Eski canlı seans geçmişi JSONL olarak kalır; bu iki dosya
  biçimi ayrı yollardır. Hesap silme `lib/app/account_bridge.dart` ile ilgili
  hesabın kurs ve seans dosyalarını kapsar; konuk kaydı devralınmaz.
- Analytics/reklam/crash-reporting SDK'sı **YOK**; Motion hesabı için Supabase
  ağı **VAR**. `tools/network_dependency_check.py` hesap ağ bağımlılıklarını
  kaydeder; fontların çalışma zamanı GET'i kapalıdır.
- Kamera karesi/landmark cihazda işlenir, **hiçbir yere yüklenmez** (Info.plist
  `NSCameraUsageDescription`, `content_claims_test` ile çivili).
- **DÜZELTME (C-325, 2026-08-19 aynı gün, ikinci tur): bu satır YANLIŞTI, yazıldığı anda bile.**
  `SessionStore` (`motion_core` pinli paket, JSONL) **YAZIYOR** — `lib/app/live/live_lesson_page.dart`
  (`_writeRecord()`), her ders tamamlanışında `lessonId`/`completedAt`/`workedSeconds`/
  `unitsCompleted`/`plannedUnits`/`lessonClass` alanlarını `<app-support-dir>/sessions.jsonl`'a
  ekliyor (append-only, atomik tmp+rename). Bu yazma yolu **C-268/A1 ile 2026-08-13'te** açıldı —
  bu dosyanın ilk yazıldığı 2026-08-19'dan ALTI GÜN önce; ilk metin muhtemelen daha eski bir
  ölçümden (C-266/A8, yazma yolu açılmadan önce) kopyalanmış, bu turda yeniden doğrulanmamıştı.
  Kalıcı depolama BİÇİMİ hâlâ JSONL'dir (Drift/SQLite roadmap §7'nin "yedi tablo" planı DEĞİL —
  bu ikisi hiç uzlaştırılmadı, bkz. DEFTER C-326); ama "hiç yazma yok" iddiası KESİN yanlıştı.
- Mikrofonun implemente edilmediği açıklama 2026-08-19 tarihsel ölçümüdür.
  2026-09-26 kontrolde de Choreia ilk kursu mikrofon kullanmaz;
  `NSMicrophoneUsageDescription`/`RECORD_AUDIO` yoktur. Ostinato'nun yeni
  isteğe bağlı cihaz üstü tek nota kararı Choreia'ya mikrofon eklemez.

## 1. Google Play Data Safety formu

| Veri kategorisi | Toplanıyor? | Paylaşılıyor? | Opsiyonel? | Amaç | Not |
|---|---|---|---|---|---|
| Personal info: e-posta, görünen ad, kullanıcı ID'si | EVET | HAYIR | Görünen ad isteğe bağlı | Hesap/uygulama işlevi | Ortak Motion Auth/profil/üyelik; sağlayıcı uçtan uca ve canlı form onayı bekliyor |
| Financial info: satın alma geçmişi | HAYIR (mevcut ilk sürüm) | HAYIR | — | Bu sürümde kullanılmaz | Satış ve satın alma doğrulaması kapalı; mevcut akış işlem geçmişi göndermez. İleride satış açılırsa form, manifest ve bu matris gerçek davranışla yeniden değerlendirilir |
| Photos/Videos | HAYIR | — | — | — | Kamera karesi cihazda işlenir, kaydedilmez/yüklenmez |
| Audio | HAYIR | — | — | — | Choreia ilk kursu mikrofon kullanmaz; native mikrofon izni yoktur |
| App activity | HAYIR (mevcut sürüm) | HAYIR | — | Cihaz içi ilerleme | Kurs JSON'u ve seans JSONL'i kalıcıdır, ancak cihazdan aktarılmaz. Google Play'in [Data safety tanımı](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en) için yalnız cihazda kalan işleme collection değildir; önceki “kalıcı dosya = collected” çıkarımı yanlıştı. Hesap verisi ve kapalı satış durumu yukarıda ayrı beyan edilir. |
| App info & performance: Diagnostics | EVET (beyan adayı) | Servis sağlayıcı istisnası doğrulanacak | Hesap yolu için gerekli | App functionality / security | Sunucuda saklanan IP/user-agent/platform güvenlik günlükleri var; crash/analytics SDK'sı yok. Play formundaki exact alt tür ve sharing istisnası final sağlayıcı kapsamıyla doğrulanır |
| Location: Approximate location | EVET (beyan adayı) | Servis sağlayıcı istisnası doğrulanacak | Hesap yolu için gerekli | App functionality / security | Ortak edge günlüklerinde IP tabanlı ülke/bölge/şehir; GPS/konum izni yok |
| Personal info: Other info | EVET (eşleme adayı) | Servis sağlayıcı istisnası doğrulanacak | Parolalı hesap için gerekli | Account management / security | Parola doğrulama/hash ve silme makbuzunun kimlik bağı; Play kategorisi ayrıca doğrulanmalı, Apple Other Data Types satırından otomatik türetilmez |
| Device/other IDs | Final IP/SDK eşlemesi açık | — | — | — | Reklam/tracking ID yok; sunucu IP/user-agent bilgisinin bu alt türe girip girmediği final form tanımıyla doğrulanır. Ayrı provider günlükleri yukarıda beyan adayına dahildir |
| Health & fitness | HAYIR | — | — | — | Sağlık verisi toplanmaz (uygulama tıbbi/sağlık verisi işlemez) |

**Data deletion bölümü:** Ortak hesap silme arayüzü Core'da var; uzak silme
doğrulanırsa ilgili hesabın seans JSONL, Salsa JSON ve çalışma JSON günlükleri ile kendi `.tmp` dosyaları temizlenir. Gerçek sağlayıcı
ve Play Console beyanı ayrıca doğrulanmalı (`account-data-safety-draft.md`).
2026-09-26 kurs JSON'u da aynı hesabın yerel silme kapsamına dahildir.
**Encryption in transit:** Motion hesap trafiğinin TLS/HTTPS yapılandırması
release öncesi gerçek ortamda doğrulanmalı; fontlar paketlidir.

## 2. Apple Privacy Nutrition Label

| Tip | Beyan | Kaynak |
|---|---|---|
| Contact Info: email, optional name | Collected, linked, app functionality | Motion Auth/profil; `PrivacyInfo.xcprivacy` |
| Health & Fitness | Not collected | Hesap manifestinde sağlık verisi türü yok; kamera/eklem noktaları cihazdan gönderilmiyor |
| Diagnostics: Other Diagnostic Data | Collected, linked, app functionality | Provider IP/user-agent/platform güvenlik günlükleri; crash/analytics SDK'sı yok |
| Location: Coarse Location | Collected, linked, app functionality | Provider edge günlüklerinde IP tabanlı yaklaşık konum; GPS izni/kesin konum yok |
| Other Data Types | Collected, linked, app functionality | Parola doğrulama/hash ve hesap silme makbuzu kimlik bağı; Apple parola eşlemesi proje çıkarımı olarak `account-data-safety-draft.md` içinde açıklanır |
| Identifiers: account ID | Collected, linked, app functionality | Motion hesabı; reklam/tracking ID yok |
| Purchases: purchase history | Collected, linked, app functionality (satış açık, 26 Ekim 2026) | Mağaza satın alma kanıtı `motion-verify-purchase` ile Motion sunucusunda doğrulanır ve hesaba bağlı hak (entitlement) olarak tutulur; Motion+ deneme defteri hesap başına (Core R3). `PrivacyInfo.xcprivacy` `NSPrivacyCollectedDataTypePurchaseHistory` içerir. Play: Financial info → Purchase history (collected, not shared). Konsol formları Yönetim'de |
| Usage Data | Not collected (yerel kurs/seans yolu) | Kurs JSON'u ve seans JSONL'i cihazda kalır; sunucudaki hesap/güvenlik günlükleri yukarıdaki ayrı türlerde değerlendirilir. Final paket/SDK davranışı ayrıca denetlenir |

[Apple App Privacy](https://developer.apple.com/app-store/app-privacy-details/)
yalnız cihazda işlenip dışarı gönderilmeyen veriyi collected saymaz.
[Google Play](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
de cihaz içi işleme/kaydını collection kapsamı dışında tutar. İzin veya
yerel kalıcı dosya tek başına sunucuya toplama değildir. Cihaz dışına giden
türetilmiş veri ayrı değerlendirilir; Google'ın sunucu tarafındaki geçici
işleme kuralı cihaz içi RAM kullanımından farklıdır. Supabase hesap
e-posta/ID'si ve isteğe bağlı ad, cihaz dışına giden hesap verisi olarak kalır.

ATT (App Tracking Transparency): **GEREKMEZ** — `NSPrivacyTracking: false`,
`NSPrivacyTrackingDomains: []` (ölçüldü, `PrivacyInfo.xcprivacy`, C-266/A8 — aynı staleness notu geçerli).

## 3. İzin gerekçe cümleleri (mağaza formlarına)

| İzin | Platform | Gerekçe cümlesi | Kaynak |
|---|---|---|---|
| Camera | iOS + Android | "Live camera practice is closed in this release. If it is separately enabled in a later release, Choreia uses the camera only to read the positions of your joints on this device. Video never leaves your phone and is not recorded or uploaded." | `NSCameraUsageDescription` (Info.plist) — Android'de eşdeğer metin store listing'de |

2026-08-19 “yalnız CAMERA” açıklaması hesap öncesi tarihsel durumdur.
2026-09-26 manifestte `CAMERA`, hesap ağı için `INTERNET` ve optional camera
feature vardır; mikrofon/depolama/konum izni yoktur. Native izin kaynağı
`android/app/src/main/AndroidManifest.xml` bu tur tekrar okundu.

## 4. Bu tablo ne zaman BAYATLAR

- **Tarihsel satın alma planı:** Önceki tablo “Financial info: EVET” ve
  “Purchases: Collected, linked” yazıyordu; ürün/işlem/abonelik doğrulaması
  açılan sonraki sürümün tasarımıydı. 2026-09-25 satış ertelemesi ve
  2026-09-26 kaynak kontrolüyle mevcut ilk sürüm satırları HAYIR olarak
  düzeltildi. Tarihsel provider ürün hazırlığı, bu uygulamanın işlem verisi
  topladığı veya gerçek satın alma kabulü aldığı anlamına gelmez.
- **Tarihsel CHO-P1-003 planı:** Eski not mikrofon eklenince otomatik
  “Audio: EVET” öneriyordu. Bu varsayım kullanılmaz: izinler gerçek kodla
  birlikte değerlendirilir, collection yanıtı ise sesin cihaz dışına
  gönderilip gönderilmediğine ve SDK davranışına bağlıdır. Yeni mikrofon
  yolu eklenirse source/manifest, form ve gerçek davranış birlikte denetlenir.
- **C-325/C-326 düzeltmesi: yerel depolama CHO-P1-004'le "başlamıyor" — zaten BAŞLADI** (JSONL
  `SessionStore`, C-268, 2026-08-13). CHO-P1-004 açılınca değişecek olan roadmap §7'nin "yedi Drift
  tablosu" planı — ama bu plan bugün ŞİLİN JSONL mimarisiyle hiç uzlaştırılmadı (DEFTER C-326).
  Formda yerel geçmiş, cihaz dışına aktarılmadığı sürece "collected" olarak beyan edilmez
  (roadmap §7: hesap gerektirmez, export/delete kullanıcı elinde). Mimari JSONL kalsa da
  Drift'e geçse de ağ davranışı yeniden ölçülmelidir.
  2026-09-24'te hesap backend'i bağlandı; bu eski plan artık güncel değil.
