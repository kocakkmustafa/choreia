# Cihaz günü reçetesi (F5, 2026-08-17)

**Amaç:** kurucu telefonunu bağladığında beş dakikada yürünecek, üç adımlı bir akış.
**Kurulum** (adım 2) otomatik/betiklenebilir — **yürüyüş** (adım 3) kurucunun elini ister
(`H-9`: fiziksel cihazda dokunuş MCP ile sürülemez, simülatör araçları yalnız simülatör
listeler).

Şema Ostinato'dan alındı (`docs/device-day/RECIPE.md`, O-160, aile-geneli emsal); dağıtım-
profili gölgeleme düzeltmesi Gravita'dan (G-253, v2) — adımların içeriği Choreia'nın kendisi.

📌 **Aile-geneli tuzaklar** (§0'ın kaynağı, dört hat ortak) tek yerde:
`motion-core/workspace/CIHAZ-GUNU-AILE-RECETESI.md` — bu dosya yalnız Choreia'nın kendi
yürüyüş tablosunu taşır.

---

## 0 — "Eşleşmiş" ≠ "bağlı"

`devicectl list devices` bir telefonu `available (paired)` gösterebilir USB'ye hiç takılı
olmadan — eşleşme kalıcı bir durumdur, canlı bağlantı değil. Cihaz gününe başlamadan önce
ikinci kaynaktan doğrula: `system_profiler SPUSBDataType | grep -i iphone`. Boş dönerse
telefon USB'de DEĞİL — yalnız eşleşmiş.

## 1 — Ön-uçuş (30 saniye, komut satırından)

```bash
python3 tools/device_day_preflight.py
```

**Bugün gerçekten çalıştırıldı (2026-08-17), canlı sonuç:**
```
✅ [imza] 4 geçerli codesign kimliği bulundu.
✅ [profil] bulundu (cihaz-kapsamlı): iOS Team Provisioning Profile:
   com.yulalab.choreia (bitiş 2027-08-13 22:30:14)
✅ [cihaz] 00008120-001804D83E13C01E PROFİLDE KAYITLI — kurulum tazeleme
   GEREKTİRMEMELİ.
✅ ÖN-UÇUŞ TEMİZ — kuruluma geçilebilir.
```
Choreia için Gravita'nın çarptığı dağıtım-profili gölgeleme durumu (§0c, aile reçetesi)
**henüz oluşmamış** — Choreia'da bugüne kadar yalnız bir geliştirme profili var, ikinci
(Store) bir profil henüz üretilmedi. Betik yine de v2 düzeltmesiyle yazıldı (`_no_device_scoped`
ayrımı, `ProvisionedDevices`-taşıyanlara önce daraltma) — bu durum ileride bir yayın provası
turundan sonra kendiliğinden ortaya çıkabilir, o zaman betik zaten hazır.

⚠️ Betik `✅ ÖN-UÇUŞ TEMİZ` DEMEZSE, aşağıdaki adım 2'ye geçme — önce profili tazele:
```bash
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
  -configuration Release -destination "id=<GERÇEK-UDID>" \
  -allowProvisioningUpdates build
```

## 2 — Kurulum (tek komut)

```bash
flutter install --release -d <cihaz-adı-veya-id-öneki>
```

**Neden `--release`, `--debug` DEĞİL** (`H-9`/aile ölçümü): Flutter debug motoru cihazda
JIT ister, iOS onu engelliyor — paket kurulur, süreç başlatılabilir bile görünebilir, ama
anında `signal 11` ile ölür. Yalnız `--release` (AOT derleme) cihazda GERÇEKTEN çalışır.

## 3 — Yürüyüş (kurucu eli ister — beklenen kanıt listesi)

🟡 **GÜNCELLEME (aynı gün, ikinci deneme) — erişim bu kez VERİLDİ, madde 9 GERÇEKTEN
GÖRÜLDÜ, ama giriş (tap/swipe/HOME) köprüsü bu oturumda YANITSIZ.** `choreia-hatti`
simülatörüne ilk denemede erişim reddedilmişti; ikinci denemede (`ListAgents` eş-oturum
sayısı 8'den 5'e düşmüştü) `screenshot` GERÇEKTEN çalıştı ve uygulama zaten kurulu+açık
çıktı (STYLES sekmesi, aşağıda madde 9 — metnin BİREBİR AYNISI ekranda görüldü, tahmin
değil). Ardından `tap` (Hip-Hop Foundations kartı, iki farklı koordinat), `swipe` (yukarı
kaydırma) ve son olarak sistem-seviyeli `button:HOME` denendi — **DÖRDÜ DE ekranı hiç
değiştirmedi** (saat 07:17→07:18 ilerledi, içerik birebir aynı kaldı). HOME düğmesinin bile
yanıtsız kalması giriş köprüsünün bu oturumda TAMAMEN kapalı olduğunun kesin kanıtı —
izin sorunu değil (erişim verilmişti), ekran-yakalama çalışıyor ama dokunuş/tuş hiçbir yere
ulaşmıyor. Araç talimatı aynı çağrıyı döngüde tekrarlamamayı söylüyor, daha fazla denenmedi.

**Sonuç, madde bazında ayrıldı:** madde 9 (STYLES sekmesi) 🟢 GERÇEKTEN GÖRÜLDÜ — aşağıdaki
metin ekrandan birebir. Diğer tüm satırlar hâlâ 🔴 KOD-OKUMASI (Gravita'nın tablosunun
aksine, simülatör ekran görüntüsüyle doğrulanmadı) — giriş köprüsü çalışmadığı için
ötesine geçilemedi.

| # | Ekran/eylem | Beklenen (kod kaynağı) | Kaynak |
|---|---|---|---|
| 1 | Uygulama açılışı | Açılış ekranı: `#0A0508` zemin + rose halka/nokta glifi (3 boyutta üretildi, `C-307`) bir an görünür | `ios/…/LaunchImage.imageset` (bu turda üretildi) |
| 2 | Onboarding — "Choreia" kartı | "Choreia watches you dance and tells you what it can see about your steps. It runs on your phone, and it is honest about the parts a camera cannot judge." | `first_run_view.dart:156-159` `IntroStrings.what` |
| 3 | Onboarding — "THE CAMERA" kartı | "Choreia watches your dancing to give you feedback on your steps. Video never leaves your phone — we only read the positions of your joints, and no video is recorded or uploaded." (Info.plist'in kendi metniyle BİREBİR AYNI — `content_claims_test` bunu pinliyor) | `first_run_view.dart:188-191` |
| 4 | Onboarding — "YOUR OWN MUSIC" kartı | "There is no music inside Choreia. Put on whatever you like... The steps are counted, not timed to a track." | `first_run_view.dart:198-201` |
| 5 | Onboarding — "WHAT IT DOES NOT JUDGE" kartı | "Choreia reads where your body is, not whether you are on the beat. There is no rhythm or timing score here..." | `first_run_view.dart:209-213` |
| 6 | Onboarding — "WHERE THIS IS TODAY" kartı | Katalogdan CANLI türetilir: "One style has a lesson you can open today, out of N in the catalogue..." — bu turda `N` ölçülmedi (kod, `content/library.json`den çalışma-zamanında sayıyor) | `first_run_view.dart:218-227` `IntroStrings.today()` |
| 7 | "Open the catalogue" düğmesi | STYLES sekmesine geçer | `first_run_view.dart:259` + `choreia_shell.dart:382` |
| 8 | Kamera izni | Sistem izin diyaloğu (uygulamanın kendi ekranı DEĞİL) — metin adım 3'teki ile birebir aynı olmalı | `ios/Runner/Info.plist` `NSCameraUsageDescription` |
| 9 | STYLES sekmesi | 🟢 **GERÇEKTEN GÖRÜLDÜ** (2026-08-17, `choreia-hatti`): "34 styles are in the catalogue. One of them is open to practise right now, and none of the open ones is graded." · filtreler "ALL·34 / OPEN NOW·1 / NOT OPEN·33" · **"Hip-Hop Foundations — OPEN·NOT SCORED — 7 LESSONS WRITTEN·NONE GRADED·1 OPEN"** · **"Salsa Shines — BUILT·NOT OPEN — 9 LESSONS WRITTEN·1 GRADED·NONE OPEN — Not open — the beat for this style is unconfirmed, and we will not grade your timing against a count we are not sure of."** — `C-308`nin iki kritik bulgusunu (yalnız Bounce açılabilir; salsa'nın puanlı dersi var ama erişilemez) BİREBİR, koddan değil EKRANDAN doğruluyor | Ekran görüntüsü (bu oturumda görüldü, dosya olarak kaydedilmedi) + `content/library.json` + `library_catalog.dart` `StyleBadge` |
| 10 | hip_hop_foundations'a gir | Level 1: Bounce (açılabilir, "not graded"), Rock (kilitli), Running Man/Groove/Roger Rabbit (bilgilendirici sayfa — `step` yok, "Start" düğmesi YOK); Level 2: iki drill (bilgilendirici) | `content/styles/hip_hop_foundations/style.json` + `library_catalog.dart:476` `_offer()` |
| 11 | Bounce'a gir, "Start" | Kamera izni zaten verildiyse doğrudan canlı ekrana geçer | `live_view.dart` |
| 12 | Canlı ekran | Kamera görüntüsü/iskelet ÇİZİLMEZ (grep doğrulandı, sıfır `CameraPreview`/`CustomPainter`) — yalnız metin: "Watching. Keep going — we read a full repetition at a time." + sayaç "N read so far" | `live_view.dart` `LiveStrings.watching`/`cycles()` |
| 13 | Bir bounce tekrarı yap | Sayaç artar (`null` iken "No full repetition read so far", sonra "1 read so far"...) | `live_view.dart:48-49` |
| 14 | Seansı bitir | "What we measured" / "What we are NOT checking" / "What we noticed" kartları — bir SKOR YOK, yalnız ölçüm etiketleri (ör. "Knee delta") | `live_view.dart:58-73`, `_measurementLabel()` |
| 15 | PROGRESS sekmesi | Bu oturumun özeti görünür (yerel JSONL'den) | `progress_summary.dart` + `session_store_access.dart` |
| 16 | Uygulamayı tamamen kapat, yeniden aç | Onboarding TEKRAR ÇIKMAZ, doğrudan STYLES'a düşer | (kod okunmadı bu turda — `FirstRunFlag` deseni var, `session_store_access.dart` yorumunda anılıyor, ayrı doğrulama gerektirir) |

**Bu turda YAPILMAYAN, cihaz günü İLK KEZ ölçülecek olanlar (adıyla, belirsizlik
gizlenmedi):**
- **Tüm tablo GÖRSEL olarak** — simülatör erişimi bu oturumda reddedildi/bekliyordu.
- **Kamera köprüsünün canlılığı** (madde 11-13) — gerçek bir telefon kamerasının gerçek bir
  insan gövdesini okuyup okumadığı bu proje için hiç ölçülmedi (aile-geneli açık soru,
  `motion-ailesi-2026-07-25` notu: "en ağır soru: kamera köprüsü canlılığı HİÇ ölçülmedi").
- Madde 16 (onboarding kalıcılığı) — kod bu turda okunmadı, yalnız var olduğu biliniyor.

---

## Kaynaklar

- Ön-uçuş betiği: `tools/device_day_preflight.py` (bu turda yazıldı+koşturuldu)
- İmza/kurulum dersi: `feedback-ios-cihaz-kurulum-imza.md` (aile çapında `H-9`)
- Aile-geneli tuzaklar: `motion-core/workspace/CIHAZ-GUNU-AILE-RECETESI.md`
- Yürüyüş tablosunun kaynağı: yukarıdaki satırlar, `lib/` doğrudan okuması — simülatör
  DEĞİL (bkz yukarıdaki uyarı)
