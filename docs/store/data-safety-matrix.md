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
| Personal info | HAYIR | — | — | — | Hesap yok |
| Photos/Videos | HAYIR | — | — | — | Kamera karesi cihazda işlenir, kaydedilmez/yüklenmez |
| Audio | HAYIR | — | — | — | Mikrofon henüz implemente edilmedi |
| App activity | **EVET (muhtemelen — aşağıya bak)** | HAYIR | — | Uygulama işlevi | **C-325 düzeltmesi:** hangi ders/ne zaman/ne kadar süre/kaç çevrim tamamlandığı `sessions.jsonl`'a cihazda kalıcı yazılıyor (yukarı bak). Aktarım/paylaşım YOK (`network_dependency_check.py` doğruluyor). Play'in "ephemeral, cihazda işlenip saklanmıyor" muafiyeti kalıcı dosyaya UYMAZ — bu okumaya göre "Collected: Evet, Shared: Hayır" olması beklenir. ⚠️ Gerçek Play form metniyle submit öncesi doğrulanmalı (store-policy-officer), burada hafızadan çıkarım yapıldı, canlı konsoldan teyit edilmedi. `outbox_events` (roadmap §7 telemetry) hâlâ yok, ayrı konu. |
| App info & performance | HAYIR | — | — | — | Crash/diagnostics SDK'sı yok |
| Device/other IDs | HAYIR | — | — | — | Reklam/tracking ID yok |
| Health & fitness | HAYIR | — | — | — | Sağlık verisi toplanmaz (uygulama tıbbi/sağlık verisi işlemez) |

**Data deletion bölümü:** **C-325 düzeltmesi — "No data is collected" ARTIK doğru olmayabilir**
(App activity satırına bak). Muhtemel doğru cevap: veri hesapsız/cihazda-yalnız tutulduğu için
"kullanıcı uygulamayı silerek kendi verisini siler" yolu — ama gerçek Play form seçenekleriyle
submit öncesi teyit edilmeli, burada varsayılmadı.
**Encryption in transit:** N/A (uygulama içi ağ trafiği yok; `google_fonts` build-time'a taşındı).

## 2. Apple Privacy Nutrition Label

| Tip | Beyan | Kaynak |
|---|---|---|
| Contact Info | Not collected | Hesap yok |
| Health & Fitness | Not collected | `PrivacyInfo.xcprivacy` `NSPrivacyCollectedDataTypes: []` |
| Diagnostics | Not collected | Crash/analytics SDK'sı yok |
| Identifiers | Not collected | Reklam/tracking ID yok |
| Usage Data | Not collected (⚠️ re-check, see note) | `PrivacyInfo.xcprivacy` `NSPrivacyCollectedDataTypes: []` — **ölçüldü 2026-08-13 00:33 (C-266/A8), session-write yolu (C-268) AYNI GÜN 13:51'de açıldı, manifest o zamandan beri yeniden doğrulanmadı** (git tarihiyle kanıtlı, C-325). Apple'ın "on-device, aktarılmayan, kimliğe bağlanmayan veri" muafiyeti Play'den farklı ve muhtemelen daha geniş — bu satırın YANLIŞ olduğu iddia edilmiyor, yalnız C-268'den beri hiç yeniden ölçülmediği kayda geçiyor |

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
  Form hâlâ "toplanıyor ama PAYLAŞILMIYOR, cihazda kalıyor" kalması beklenir (roadmap §7: hesap
  gerektirmez, export/delete kullanıcı elinde) — mimari JSONL kalsa da Drift'e geçse de bu satır
  muhtemelen değişmez, ama bu bir varsayım, ölçülmedi.
  `MOTION-GROWTH-001` açılmadan backend YOK, bu satır o kapı geçmeden değişmez.
