# Data Safety (Play) + Privacy Nutrition Label (Apple) Matrisi — CHO-P0-002

İlk ölçüm 2026-08-19, hesap güncellemesi 2026-09-25. Kaynaklar: `ios/Runner/PrivacyInfo.xcprivacy`
(C-266/A8, ölçülerek dolduruldu) · `ios/Runner/Info.plist` · `android/app/src/main/AndroidManifest.xml`
· `tools/network_dependency_check.py` (yükleyici-izi kapısı, 5 öz-test) · `tools/privacy_manifest_check.py`.
2026-09-25 kaynak durumu: ortak Motion hesabı Core path bağımlılığıyla eklendi;
üretim şeması/işlevleri kuruldu, ancak gerçek kullanıcı uçtan uca kanıtı ve mağaza formu onayı henüz yok. Hesap ve satın alma için dört
alanın ayrıntısı `account-data-safety-draft.md` dosyasında. Aşağıdaki 2026-08-19
notları tarihsel ölçüm olarak tutulur; güncel hüküm yeni satırlardır.

## 0. Baseline — ne VAR, ne YOK (formu doldurmadan önce)

- Ortak Motion hesap/giriş arayüzü **VAR**; Core geçici yerel path bağımlılığı ve
  `MOTION_SUPABASE_URL`/`MOTION_SUPABASE_PUBLISHABLE_KEY` yapılandırması gerekir.
  Ders/seans geçmişi hâlâ yalnız cihazda; hesap servisine senkronize edilmez.
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
- Mikrofon **HENÜZ İMPLEMENTE EDİLMEDİ** — `lib/` içinde mikrofon/ses-kayıt API'sine hiçbir
  referans yok (bu turda grep ile doğrulandı). `NSMicrophoneUsageDescription`/`RECORD_AUDIO`
  bu yüzden BİLEREK yazılmadı — CHO-P1-003 (audio clock/onset) açıldığında GERÇEK davranışla
  birlikte eklenecek; yokken eklemek "kullanılmayan izin" reddini davet ederdi.

## 1. Google Play Data Safety formu

| Veri kategorisi | Toplanıyor? | Paylaşılıyor? | Opsiyonel? | Amaç | Not |
|---|---|---|---|---|---|
| Personal info: e-posta, görünen ad, kullanıcı ID'si | EVET | HAYIR | Görünen ad isteğe bağlı | Hesap/uygulama işlevi | Ortak Motion Auth/profil/üyelik; sağlayıcı uçtan uca ve canlı form onayı bekliyor |
| Financial info: satın alma geçmişi | EVET | HAYIR | Abonelik etkinleşince | Abonelik doğrulama/erişim | Ürün, mağaza, işlem referansı, durum ve süre Motion sunucusunda; ödeme kartı alınmaz |
| Photos/Videos | HAYIR | — | — | — | Kamera karesi cihazda işlenir, kaydedilmez/yüklenmez |
| Audio | HAYIR | — | — | — | Mikrofon henüz implemente edilmedi |
| App activity | HAYIR (mevcut sürüm) | HAYIR | — | Cihaz içi ilerleme | JSONL dosyası kalıcıdır, ancak cihazdan aktarılmaz. Google Play'in [Data safety tanımı](https://support.google.com/googleplay/android-developer/answer/10787469) için “collected” cihaz dışına iletilen veridir; önceki “kalıcı dosya = collected” çıkarımı yanlıştı. Hesap ve satın alma alanları yukarıda ayrı beyan edilir. |
| App info & performance | HAYIR | — | — | — | Crash/diagnostics SDK'sı yok |
| Device/other IDs | HAYIR | — | — | — | Reklam/tracking ID yok |
| Health & fitness | HAYIR | — | — | — | Sağlık verisi toplanmaz (uygulama tıbbi/sağlık verisi işlemez) |

**Data deletion bölümü:** Ortak hesap silme arayüzü Core'da var; uzak silme
başarılı olursa ilgili kullanıcıya ait yerel JSONL silinir. Gerçek sağlayıcı
ve Play Console beyanı ayrıca doğrulanmalı (`account-data-safety-draft.md`).
**Encryption in transit:** Motion hesap trafiğinin TLS/HTTPS yapılandırması
release öncesi gerçek ortamda doğrulanmalı; fontlar paketlidir.

## 2. Apple Privacy Nutrition Label

| Tip | Beyan | Kaynak |
|---|---|---|
| Contact Info: email, optional name | Collected, linked, app functionality | Motion Auth/profil; `PrivacyInfo.xcprivacy` |
| Health & Fitness | Not collected | Hesap manifestinde sağlık verisi türü yok; kamera/eklem noktaları cihazdan gönderilmiyor |
| Diagnostics | Not collected | Crash/analytics SDK'sı yok |
| Identifiers: account ID | Collected, linked, app functionality | Motion hesabı; reklam/tracking ID yok |
| Purchases: purchase history | Collected, linked, app functionality | Mağaza ürünü, işlem referansı ve abonelik durumu/süresi; `PrivacyInfo.xcprivacy` |
| Usage Data | Not collected | Seans JSONL dosyası cihazda kalır; güncel manifest hesap alanlarını beyan eder, usage türünü beyan etmez. Cihaz dışına çıkma davranışı release öncesi yeniden denetlenmeli. |

ATT (App Tracking Transparency): **GEREKMEZ** — `NSPrivacyTracking: false`,
`NSPrivacyTrackingDomains: []` (ölçüldü, `PrivacyInfo.xcprivacy`, C-266/A8 — aynı staleness notu geçerli).

## 3. İzin gerekçe cümleleri (mağaza formlarına)

| İzin | Platform | Gerekçe cümlesi | Kaynak |
|---|---|---|---|
| Camera | iOS + Android | "Choreia watches your dancing to give you feedback on your steps. Video never leaves your phone — we only read the positions of your joints, and no video is recorded or uploaded." | `NSCameraUsageDescription` (Info.plist) — Android'de eşdeğer metin store listing'de |

Android manifest'te yalnız `CAMERA` + `uses-feature android.hardware.camera required=false`
bulunuyor (bu turda okundu, `android/app/src/main/AndroidManifest.xml`) — mikrofon/depolama/konum
izni YOK, gerçek davranışla birebir.

## 4. Bu tablo ne zaman BAYATLAR

- CHO-P1-003 (audio/onset) açılınca: mikrofon satırı `Audio: EVET` olur, `RECORD_AUDIO` +
  `NSMicrophoneUsageDescription` eklenir — ikisi BİRLİKTE, kod-önce-izin-sonra değil.
- **C-325/C-326 düzeltmesi: yerel depolama CHO-P1-004'le "başlamıyor" — zaten BAŞLADI** (JSONL
  `SessionStore`, C-268, 2026-08-13). CHO-P1-004 açılınca değişecek olan roadmap §7'nin "yedi Drift
  tablosu" planı — ama bu plan bugün ŞİLİN JSONL mimarisiyle hiç uzlaştırılmadı (DEFTER C-326).
  Formda yerel geçmiş, cihaz dışına aktarılmadığı sürece "collected" olarak beyan edilmez
  (roadmap §7: hesap gerektirmez, export/delete kullanıcı elinde). Mimari JSONL kalsa da
  Drift'e geçse de ağ davranışı yeniden ölçülmelidir.
  2026-09-24'te hesap backend'i bağlandı; bu eski plan artık güncel değil.
