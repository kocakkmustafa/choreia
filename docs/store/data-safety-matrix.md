# Data Safety (Play) + Privacy Nutrition Label (Apple) Matrisi — CHO-P0-002

İlk ölçüm 2026-08-19, hesap güncellemesi 2026-09-25. Kaynaklar: `ios/Runner/PrivacyInfo.xcprivacy`
(C-266/A8, ölçülerek dolduruldu) · `ios/Runner/Info.plist` · `android/app/src/main/AndroidManifest.xml`
· `tools/network_dependency_check.py` (yükleyici-izi kapısı, 5 öz-test) · `tools/privacy_manifest_check.py`.
2026-09-25 kaynak durumu: ortak Motion hesabı Core path bağımlılığıyla eklendi;
üretim şeması/işlevleri kuruldu, ancak gerçek kullanıcı uçtan uca kanıtı ve mağaza formu onayı henüz yok. Hesap ve satın alma için dört
alanın ayrıntısı `account-data-safety-draft.md` dosyasında. Aşağıdaki 2026-08-19
notları tarihsel ölçüm olarak tutulur; güncel hüküm yeni satırlardır.

**2026-09-26 kaynak uzlaştırması:** Satışın ertelendiği ilk sürüm için
aşağıdaki güncel tablolar düzeltilmiştir. Çözümlenen `motion_account`
paketinde `motionPaidFeaturesAvailable=false`; üyelik/satış girişleri ve
paid-session yolu kapalıdır. Güncel Apple manifestinde yalnız e-posta,
isteğe bağlı ad ve hesap ID'si collected türü vardır; purchase-history
türü yoktur. 2026-09-25 sağlayıcı/SMTP bilgisi bu tur yeniden ölçülmedi.
Kaynak kontrolü final SDK/network, fiziksel cihaz veya konsol kabulü değildir.
Önceki satın alma beyanı sonraki satış planını mevcut durum gibi gösteriyordu;
tarihsel metnin anlamı §4'te korunur, güncel form adayı aşağıdadır.

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
| App info & performance | HAYIR | — | — | — | Crash/diagnostics SDK'sı yok |
| Device/other IDs | HAYIR | — | — | — | Reklam/tracking ID yok |
| Health & fitness | HAYIR | — | — | — | Sağlık verisi toplanmaz (uygulama tıbbi/sağlık verisi işlemez) |

**Data deletion bölümü:** Ortak hesap silme arayüzü Core'da var; uzak silme
başarılı olursa ilgili kullanıcıya ait yerel JSONL silinir. Gerçek sağlayıcı
ve Play Console beyanı ayrıca doğrulanmalı (`account-data-safety-draft.md`).
2026-09-26 kurs JSON'u da aynı hesabın yerel silme kapsamına dahildir.
**Encryption in transit:** Motion hesap trafiğinin TLS/HTTPS yapılandırması
release öncesi gerçek ortamda doğrulanmalı; fontlar paketlidir.

## 2. Apple Privacy Nutrition Label

| Tip | Beyan | Kaynak |
|---|---|---|
| Contact Info: email, optional name | Collected, linked, app functionality | Motion Auth/profil; `PrivacyInfo.xcprivacy` |
| Health & Fitness | Not collected | Hesap manifestinde sağlık verisi türü yok; kamera/eklem noktaları cihazdan gönderilmiyor |
| Diagnostics | Not collected | Crash/analytics SDK'sı yok |
| Identifiers: account ID | Collected, linked, app functionality | Motion hesabı; reklam/tracking ID yok |
| Purchases: purchase history | Not collected (mevcut ilk sürüm) | Satış/işlem doğrulaması kapalı; güncel `PrivacyInfo.xcprivacy` purchase-history türü içermez. Satış açılırsa yeniden değerlendirilir |
| Usage Data | Not collected | Kurs JSON'u ve seans JSONL'i cihazda kalır; güncel manifest yalnız hesap alanlarını beyan eder. Cihaz dışına çıkma ve SDK davranışı final paketle ayrıca denetlenir |

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
| Camera | iOS + Android | "Choreia watches your dancing to give you feedback on your steps. Video never leaves your phone — we only read the positions of your joints, and no video is recorded or uploaded." | `NSCameraUsageDescription` (Info.plist) — Android'de eşdeğer metin store listing'de |

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
