# 27 Ekim 2026 · K-6: 14 mağaza dili (taslak, konsola yazılmadı)

Kurucu kararı K-6 (27 Ekim): beş Motion uygulaması 14 uygulama dilinde listelenir.
EN `listing.json` ve TR `listing.tr-TR.json` açıklaması 1.0.0(6) adayına göre
yenilendi: "abonelik satışı açık değil" cümlesi çıktı (satış 23 Ekim'den beri
açık), canlı kamera ve puanlama kapalı, ücretsiz bölüm koddaki
`CourseAccess.freeLessons` ile birebir: Salsa ilk 18 ders (modül 1–3), Hip-Hop
başlangıç kursu 6/6, Hip-Hop beceri 3/8, Line Dance / Latin Fusion / kısa form
4'er → 94 birimin 39'u. Ad, alt başlık, tanıtım, anahtar kelime ve kısa açıklama
değişmedi. Eski `$` notları tarihseldir (`$k6Revision20261027`).

12 çeviri `listing.<dil>.json`: de, es-419, pt-BR, fr, it, pl, id, ja, ko,
zh-Hans, ar, hi. Her dosya EN olgularını paragraf paragraf taşır; kamera izin
metni o dilin `ios/Runner/<dil>.lproj/InfoPlist.strings` satırından birebir
alınır (1.0.0(6) kamera izni istemez). Konsol kodları 14 dosyanın hepsinde
`$storeLocales` alanında (Ostinato/Gravita ile aynı eşleme):

| Dosya | App Store Connect | Play Console |
|---|---|---|
| listing.json | en-US | en-US |
| listing.tr-TR.json | tr | tr-TR |
| de · fr · pt-BR | de-DE · fr-FR · pt-BR | de-DE · fr-FR · pt-BR |
| es-419 | es-MX | es-419 |
| it · pl · id | it · pl · id | it-IT · pl-PL · id |
| ja · ko · zh-Hans | ja · ko · zh-Hans | ja-JP · ko-KR · zh-CN |
| ar · hi | ar-SA · hi | ar · hi-IN |

`test/store_listing_locales_test.dart`: 14 dosya, kodlar, alan sınırları
(ad/alt başlık 30, tanıtım 170, anahtar kelime 100, kısa açıklama 80, açıklama
4000), paragraf eşliği, sayılı olgular (kurs dosyaları ve `CourseAccess` ile
bağlı), URL'ler ve kamera metni. Ana dil, hukuk ve mağaza incelemesi UNRUN;
konsol girişi Yönetim/kurucuda.

# 23 Ekim 2026 güncellemesi · abonelik satışı açık (taslak, konsola yazılmadı)

Kurucu kararları (23 Ekim): satış ilk sürümde açık, kamera/puanlama kapalı;
paywall A (her kursun ilk modülü/~1/3'ü ücretsiz); fiyat ABD bazı Choreia
$11,99/ay · $69,99/yıl, Motion+ $19,99/ay · $129,99/yıl; 14 gün ücretsiz
deneme. Mevcut yazılı içerik: Salsa On1 48 ders, Hip-Hop 8 beceri ünitesi
(+6 temel), Line Dance 12, Latin Fusion 10, özgün kısa form 10. Aşağıdaki
"abonelik satışı yoktur" cümlesi bu tarihten itibaren geçersizdir.

## Abonelik metadata taslağı

| Ürün | Görünen ad (EN / TR) | Açıklama (EN / TR) |
|---|---|---|
| `com.yulalab.choreia.individual.*` / `choreia_individual` | Choreia Membership / Choreia Üyeliği | Unlocks every lesson in Choreia's five written dance courses. / Choreia'nın beş yazılı dans kursundaki tüm dersleri açar. |
| `com.yulalab.choreia.motionplus.*` / `choreia_motion_plus` | Motion+ / Motion+ | Unlocks every course in all five Yula Motion apps. / Beş Yula Motion uygulamasının tüm kurslarını açar. |

Açıklama metnine eklenecek paragraf (EN): "The first lessons of every course
are free. A Choreia or Motion+ subscription opens the rest; eligible new
members start with a 14-day free trial. Subscriptions renew automatically
unless cancelled at least 24 hours before the end of the period. Terms:
https://yulalab.com/terms · Privacy: https://yulalab.com/privacy/motion"

(TR): "Her kursun ilk dersleri ücretsizdir. Kalanını Choreia veya Motion+
aboneliği açar; uygun yeni üyeler 14 günlük ücretsiz denemeyle başlar.
Abonelik, dönem bitiminden en az 24 saat önce iptal edilmezse otomatik
yenilenir."

Açık: ASC/Play fiyat + deneme güncellemesi ve SKU'ların konsolda varlığı
(kullanıcı girdisi); Android'de deneme Core Play teklif desteğine bağlı;
Schedule 2 (Paid Apps) durumu.

# Güncel mağaza metni girişi · 17 Ekim 2026

Yayıma hazırlanacak TR/EN metinlerin kaynağı [listing.json](listing.json) ve
[listing.tr-TR.json](listing.tr-TR.json) dosyalarıdır. Mevcut yazılı içerik
**beş mevcut yazılı yol / 86 birim** (HipHop 6 temel + 8 beceri; Salsa 48 ders/8 modül; Line Dance 9; Latin Fusion 8; özgün kısa-form 7). Kurs hashleri JSON içindeki `$candidate20261017` kaydındadır. Gerçek gösterim, uzman/öğrenci ve model kabulü açık; tam öğretim hedefi korunur.
Sessiz görsel sayım ve öz kayıt; kamera puanı, müzik temposu doğrulaması veya abonelik satışı yoktur.

Kurs ilerlemesi kullanıcının kendi çalışma kaydıdır; ustalık veya fiziksel öğretim
kabulü değildir. Hesap ve destek/gizlilik metinleri güncel JSON'dan alınır.
Yerel metin, eski ekran görüntüsü veya kaynak testi mağazada kaydedildiği, güncel
imzalı pakette bulunduğu ya da fiziksel cihazda kabul edildiği anlamına gelmez.
Bu bakımda mağaza paneline yazılmadı ve yükleme yapılmadı.

17 Ekim modelden bağımsız bakım: [gizlilik uzlaştırması](account-data-safety-draft.md),
[form matrisi](data-safety-matrix.md) ve [hesap/sandbox/dağıtım kabulü](RELEASE-ACCOUNT-SANDBOX-CHECKLIST.md)
güncellendi. İmzalı paketler `642a7d0` kaynaklı distribution adaylarıdır;
belge commit'i runtime girdilerini değiştirmez ve yeni derleme gerektirmez.
Kullanıcı kapılar kapandıktan sonra ayrıca son yükleme onayı verilmesini seçti.

## Tarihsel araştırma · aşağıdaki metni yayın metni olarak kullanmayın

Aşağıdaki eski katalog/kamera incelemesi kendi tarihinin kanıtıdır. Eski “bugün”,
“sıradaki” ve simge onayı ifadeleri güncel yayın durumu değildir; yukarıdaki iki
JSON ve kaynaklarına bağlı güncel kabul kullanılır.

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
