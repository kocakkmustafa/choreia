# Data Safety (Play) + Privacy Nutrition Label (Apple) Matrisi — CHO-P0-002

Gerçek koda göre (2026-08-19). Kaynaklar, tek tek: `ios/Runner/PrivacyInfo.xcprivacy`
(C-266/A8, ölçülerek dolduruldu) · `ios/Runner/Info.plist` · `android/app/src/main/AndroidManifest.xml`
· `tools/network_dependency_check.py` (yükleyici-izi kapısı, 5 öz-test) · `tools/privacy_manifest_check.py`.
Bu dosya YENİ bir ölçüm yapmıyor — üçünün KENDİ ölçümünü tek okunur tabloya taşıyor, LifeOS'un
`docs/store/data-safety-matrix.md` biçimini örnek alarak (farklı bir uygulama sınıfı — Choreia'nın
hesabı/backend'i/bulut sync'i YOK, tablo bu yüzden çok daha kısa).

## 0. Baseline — ne VAR, ne YOK (formu doldurmadan önce)

- Hesap/giriş **YOK**. Bulut senkron/backend **YOK** (roadmap §7: standalone launch backend
  gerektirmez; `MOTION-GROWTH-001` kapısı açılmadan optional backend hiç oluşmaz).
- Analytics/reklam/crash-reporting SDK'sı **YOK** (`tools/network_dependency_check.py`
  `NETWORK_DEPS_RECORDED`: yalnız `google_fonts`+transitive `http`/`http_parser`, üçü de
  kullanıcı verisi taşımaz; CHO-P0-002 bu turda `google_fonts`un runtime GET'ini de KAPATTI).
- Kamera karesi/landmark cihazda işlenir, **hiçbir yere yüklenmez** (Info.plist
  `NSCameraUsageDescription`, `content_claims_test` ile çivili).
- Kalıcı yerel depolama (Drift/SQLite tabloları, roadmap §7) **HENÜZ YOK** — `SessionStore`
  yalnız OKUNUYOR, `lib/` genelinde hiçbir yazma yok (`PrivacyInfo.xcprivacy`'nin kendi ölçümü,
  bu turda tekrar doğrulandı: `lib/services/` boş, CHO-P1-004 kapsamı).
- Mikrofon **HENÜZ İMPLEMENTE EDİLMEDİ** — `lib/` içinde mikrofon/ses-kayıt API'sine hiçbir
  referans yok (bu turda grep ile doğrulandı). `NSMicrophoneUsageDescription`/`RECORD_AUDIO`
  bu yüzden BİLEREK yazılmadı — CHO-P1-003 (audio clock/onset) açıldığında GERÇEK davranışla
  birlikte eklenecek; yokken eklemek "kullanılmayan izin" reddini davet ederdi.

## 1. Google Play Data Safety formu

| Veri kategorisi | Toplanıyor? | Paylaşılıyor? | Opsiyonel? | Amaç | Not |
|---|---|---|---|---|---|
| Personal info | HAYIR | — | — | — | Hesap yok |
| Photos/Videos | HAYIR | — | — | — | Kamera karesi cihazda işlenir, kaydedilmez/yüklenmez |
| Audio | HAYIR | — | — | — | Mikrofon henüz implemente edilmedi |
| App activity | HAYIR | — | — | — | Analytics SDK yok, `outbox_events` (roadmap §7 telemetry) henüz yok |
| App info & performance | HAYIR | — | — | — | Crash/diagnostics SDK'sı yok |
| Device/other IDs | HAYIR | — | — | — | Reklam/tracking ID yok |
| Health & fitness | HAYIR | — | — | — | Sağlık verisi toplanmaz (uygulama tıbbi/sağlık verisi işlemez) |

**Data deletion bölümü:** "No data is collected" seçeneği geçerli — silinecek bir veri yok.
**Encryption in transit:** N/A (uygulama içi ağ trafiği yok; `google_fonts` build-time'a taşındı).

## 2. Apple Privacy Nutrition Label

| Tip | Beyan | Kaynak |
|---|---|---|
| Contact Info | Not collected | Hesap yok |
| Health & Fitness | Not collected | `PrivacyInfo.xcprivacy` `NSPrivacyCollectedDataTypes: []` |
| Diagnostics | Not collected | Crash/analytics SDK'sı yok |
| Identifiers | Not collected | Reklam/tracking ID yok |
| Usage Data | Not collected | — |

ATT (App Tracking Transparency): **GEREKMEZ** — `NSPrivacyTracking: false`,
`NSPrivacyTrackingDomains: []` (ölçüldü, `PrivacyInfo.xcprivacy`, C-266/A8).

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
- CHO-P1-004 (local-first progress) açılınca: yedi Drift tablosu gerçek yerel depolama başlatır
  — Play/Apple formunda hâlâ "toplanıyor ama PAYLAŞILMIYOR, cihazda kalıyor" olması beklenir
  (roadmap §7: hesap gerektirmez, export/delete kullanıcı elinde).
  `MOTION-GROWTH-001` açılmadan backend YOK, bu satır o kapı geçmeden değişmez.
