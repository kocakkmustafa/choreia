# Mağaza Liste Metni — TASLAK (D6, 2026-08-17, YAYIN-YOLU-CHOREIA madde 2)

**Makine-okur kaynak:** `docs/store/listing.json` — metnin kendisi orada, bu dosya insan-okur
bağlam. Desen: `ostinato/app/docs/store/listing.json` (aile emsali, ailede İLK kapanan D6).

**Gönderim KURUCU kalemi (B7).** Bu yalnız taslak — ASC/Play'e hiçbir şey yüklenmedi,
yüklenmeyecek. Orkestratör **yan yana okuma (H-58)** yapmadan submit yok — bu commit tek
başına yeterli değil, yazıldığını bildirmek gerekiyor.

## Bu turun iki kritik bulgusu (metni bunlar şekillendirdi)

### 1. 🔴 Bugün gerçekten başlatılabilen TEK ders: The Bounce
`hip_hop_foundations`in 7 dersinden yalnız `hh_l1_bounce`nin `step` alanı dolu.
`library_catalog.dart:476` (`_offer`): `stepId == null` → `LessonBlock.noLessonBuilt`,
**başlatılamaz**. Running Man / Groove / Roger Rabbit hepsi `demoOnly:true` ama `step` alanı
YOK — yani kameraya HİÇ bağlanmıyorlar, yalnız bilgilendirici sayfa. Rock zaten `locked`.
Description'ı bu yüzden "INTERACTIVE TODAY" (yalnız Bounce) / "SHOWN, NOT YET INTERACTIVE"
(diğer üçü) diye ikiye ayırdım — hepsini "canlı, kamera-takipli" gibi yazmak yanlış olurdu.

### 2. 🔴 Salsa'nın puanlı dersi VAR ama kullanıcı ona hiç ulaşamıyor
`ss_l1_footwork` gerçekten puanlı (8 bacak eklemi, 1,57-5,76° teyit; hangi ayak önde 15,6°
marj) — ama `salsa_shines`in `shipGates`i `bpmResolved:blocked=true` taşıyor (BPM DISPUTED,
iki ölçüm ~2x farklı). `style_availability.dart`in kendi yorumu: *"A style can honestly be
live... and still be unopenable"* — stil BPM çözülmeden yayına çıkmaz. Description'da
salsa'dan **hiç bahsetmedim** — puanlı-ama-ulaşılamaz bir şeyi mevcutmuş gibi yazmak,
JabLab'ın "ölçülüyor ama gösterilmiyor" hatasının ayna görüntüsü olurdu.

## Neden bu kadar dar (üçüncü, daha küçük bulgu)

Choreia'nın kendi `lib/`inde de pinli `motion_camera` paketinde de (`f13bdc93` pini) **sıfır
kamera-önizleme veya iskelet-çizim widget'ı yok** — grep doğrulandı. `live_view.dart` yalnız
metin/sayaç gösteriyor ("Watching... N read so far", sonra ölçüm kartları). Description'da
"kendi görüntünü/iskeletini izle" türü hiçbir cümle yok — Info.plist'in kendi metni de zaten
yalnız "we read the positions of your joints" diyor, görüntü vaadi taşımıyor.

## Kontrol listesi (her cümle bir kaynağa bağlı)

| İddia | Kaynak |
|---|---|
| Tek etkileşimli ders: Bounce | `content/styles/hip_hop_foundations/style.json` `step` alanı + `library_catalog.dart:476` |
| Bounce puansız, gerekçeli | `style.json` `hh_l1_bounce.demoOnlyReason` |
| Running Man/Groove/Roger Rabbit gösterim-only | `style.json` `step:null` üçünde de |
| Salsa'dan bahsedilmedi | `content/library.json` satır ~150 (`status:live` ama `shipGates.bpmResolved.blocked:true`) + `style_availability.dart` yorumu |
| Kamera görüntüsü hiç gösterilmiyor | `grep CameraPreview\|CustomPainter` → Choreia `lib/` + `motion_camera` paketi, sıfır sonuç |
| Video hiç saklanmaz, özet saklanır | `ios/Runner/Info.plist` NSCameraUsageDescription + `session_store_access.dart` (JSONL, video yok) |
| Mikrofon yok | `grep NSMicrophoneUsageDescription` sıfır + `lib/`de ses-yakalama çağrısı sıfır |
| Web/UGC yok | `grep webview_flutter\|url_launcher\|share_plus` sıfır |
| Tıbbi dil yasak | aile sözleşmesi `00-AILE-MIMARISI.md:56` (kod-doğrulanmış bir Choreia ekranı YOK, bu farkı `$ageRating`de adıyla ayırdım — Ostinato'nun aksine) |

## Ne YAZILMADI (bilerek)

- **Salsa** — puanlı dersi var ama gate-kapalı, kullanıcı hiç göremiyor (yukarıda #2).
- **"Coach" kelimesi** — Ostinato/JabLab'ın deseninde var, Choreia'da bilerek yazılmadı: bugünkü
  tek ders puansız, "coach" bir değerlendirme vaat eder gibi okunurdu.
- **Kamera görüntüsü/iskelet vaadi** — kod bunu göstermiyor (yukarıda #3), yazılmadı.
- **Cihaz-kanıtlı hiçbir cümle** — bu turda cihazda/simülatörde ekran görüntüsü alınmadı,
  yalnız kod okundu; sıradaki madde (3, cihaz günü paketi) bunu üretecek.

## Sıradaki

Orkestratöre bildir (H-58 yan yana okuma) → onay/düzeltme sonrası ekran görüntüleri (madde 3,
cihaz günü paketi) → ikon zaten madde 1'de kapandı (`C-307`).
