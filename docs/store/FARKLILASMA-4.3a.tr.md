# Choreia — App Store 4.3(a) farklılaşma dosyası (hazırlık, gönderim YOK)

Bilet: CHO-P1-01 · Tarih: 2026-11-14 · Kapsam: yalnız belge. Resolution Center'a hiçbir şey gönderilmez; mağazaya dokunulmaz.

**Önemli:** Choreia 1.0.0 ret gerekçesi (ASC'de `REJECTED`) henüz okunmadı. Bu belge gerekçeden bağımsız bir hazırlıktır; ret metni okununca §3-§4 yeniden gözden geçirilmelidir. Resmî 4.3(a) metni bu repoda yok (`DOĞRULANMADI`).

Kaynak kuralı: yollar bu depo köküne göredir; `../../motion-core/…` Core deposudur (salt-okur). Satırlar 2026-11-14'te `main@07b2315` üzerinde `grep -n`/`sed -n` ile okundu; reviewer bulguları sonrası 2026-11-14'te `course_access.dart`, `hip_hop_course_page.dart` ve `STORE-LISTING-TASLAK.md` atıfları yeniden doğrulandı. Emsal: `ventures/lissom/app/docs/store/FARKLILASMA-4.3a.tr.md` (LIS-P1-10); ortak şablon tablosu orada **§2**'dedir, burada yeniden yapılmadı.

## 1. Choreia'ya özgü olanların kanıtlı envanteri

| # | Özgü öğe | Kanıt (dosya:satır) |
|---|---|---|
| 1 | Beş solo dans kursu (yazılı ders): Salsa On1 8 modül / 48 ders; Hip-Hop: 6 ünitelik temel kurs + 8 ünitelik beceri kursu (toplam 14); Line Dance 12; Latin Fusion 10; özgün kısa-form 10 = toplam 94 yazılı ünite (`docs/store/listing.json:16`: 48+6+8+12+10+10) | `lib/app/course/salsa_course.dart:143-144`; `hip_hop_course.dart:63-65` (beceri kursu 8; temel kurs 6 JSON'da sayıldı, kodda sabit sayı denetimi yok); `line_dance_course.dart:41`; `latin_fusion_course.dart:56`; `short_form_course.dart:35`; veri: `content/salsa_on1_course.json`, `hip_hop_foundations_course.json` (6 ünite), `hip_hop_foundations_skill_course.json` (8), `line_dance_beginner_course.json`, `latin_fusion_beginner_course.json`, `original_short_form_beginner_course.json`; mağaza anlatımı `docs/store/REVIEW-NOTES-DRAFT.md:10-14` |
| 2 | Hip-Hop için iki içerik sürümü (temel kurs `hip_hop_foundations_course.json` 6 ünite, beceri kursu `hip_hop_foundations_skill_course.json` 8 ünite) | `lib/app/course/hip_hop_course_page.dart:14,48-55`; `REVIEW-NOTES-DRAFT.md:10-14` yalnız "Hip-Hop Foundations (8)" diyor, temel kursu saymıyor (listing.json:16 ile tutarsız, not edildi, bu bilette düzeltilmedi) |
| 3 | Salsa ders yapısı: `teaching`, `practice`, `selfCheck`, `adaptation`, `mediaBrief`, `minutes`; sayım/müzik sınırı (`music.provided=false`, `assessment=selfCheck`) | `content/salsa_on1_course.json` (ders anahtarları okundu); `lib/app/course/salsa_course.dart:140-144` |
| 4 | Yazılı birim pratiği: kendi bildirimli çalışma, kurs tamamlama/ölçüm/ustalık vermez | `lib/app/course/written_unit_practice.dart:9-11` |
| 5 | Salsa öz-kontrol politikası (mevcut ölçüt dizinleri seçilir, yeni metin yok) | `lib/app/course/salsa_self_check_policy.dart:5` |
| 6 | Yazılı hatırlama (recall) akışı, yanıtlar kursa/hesaba girmez | `lib/app/study_review.dart:17,125`; içerik `lib/app/study_review_content.dart` |
| 7 | Geçici öz-gözlem karşılaştırma sayfası | `lib/app/course/practice_comparison_page.dart:5-6` |
| 8 | Sembolik öğretim yardımcıları: Line Dance yön haritası ("hareket gösterimi değildir"), destek-tutuş gösterimi | `lib/app/course/line_dance_direction_diagram.dart:4`; `support_hold_demo.dart:4` |
| 9 | Dinleme/paylaşım sınırı bildirimi (uygulama içi müzik yok) | `lib/app/course/practice_music_notice.dart:4` |
| 10 | 14 dil: arayüz ve ders (13 yerel + zh-Hans) | `lib/app/localization/choreia_locale.dart:33-47`; mağaza metni 14 dosya: `docs/store/listing.json` + 13 `listing.<dil>.json` |
| 11 | Ücretsiz bölüm: Salsa ilk 18/48 ders (3/8 modül), Hip-Hop temel kurs 6 ünitenin tamamı ücretsiz (kapı yalnız beceri kursunda: `hip_hop_course_page.dart:174-176`), Hip-Hop beceri 3, Line Dance 4, Latin Fusion 4, kısa-form 4 = toplam 39/94 ünite ücretsiz (6+18+3+4+4+4; `docs/store/listing.json:16`) | `lib/app/course/course_access.dart:36-42`; kilit metni `paid_lesson_lock.dart:20-21` |
| 12 | Ana düzen: 3 sekme STİLLER / İLERLEME / PROFİL (Bugün ve Practice Lab hedef değil) | `lib/app/shell/choreia_shell.dart:523,533,543`; gerekçe `:52-56` |
| 13 | Mağaza kimliği: "Choreia: Learn to Dance" / "Five solo dance practice paths" | `docs/store/listing.json:8-9` |
| 14 | İkon: koyu bordo zemin, krem/pembe sıçrayan dansçı figürü (görsel okundu) | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` |

Not: istenen "dikte" akışı Choreia'da bulunmadı (aranmadı değil; envantere girecek kod yok). Diğer uygulamaların ders şeması okunmadı; JSON alan kümesinin Choreia'ya özgü olduğu iddia EDİLMEZ.

**Kamera "yok" sayılır (bayrak kapalı).** Core bayrağı `motionCameraCoachingAvailable = false` (`../../motion-core/lib/packages/motion_account/lib/src/motion_release_policy.dart:6`), Choreia'ya `lib/main.dart:394` ile geçer. Canlı kamera bölümü ve izin bildirimi yalnız bayrak açıkken çizilir (`lib/app/library/style_detail_view.dart:737`); `Permission.camera.request()` yalnız canlı ders sayfasındadır (`lib/app/live/live_lesson_page.dart:465`). Bu yüzden kamera 4.3(a) için farklılaştırıcı değildir.

## 2. Lissom §2 ortak şablon tablosuna atıf — Choreia sütunu doğrulaması

Atıf: Lissom `docs/store/FARKLILASMA-4.3a.tr.md` §2. Choreia sütununun her hücresi:

| Hücre | Lissom §2'deki değer | Doğrulama | Kaynak |
|---|---|---|---|
| İkon | koyu bordo, krem/pembe dansçı | DOĞRU | ikon dosyası, §1-14 |
| Ana düzen | `NavigationBar`, 3 sekme, `choreia_shell.dart:498` | DOĞRU (`NavigationBar` bu dosyada :498 civarı; sekmeler 523/533/543) | `lib/app/shell/choreia_shell.dart:498,523-547` |
| Onboarding | "ayrı dosya bulunamadı" | **DÜZELTME:** dosya var | `lib/app/onboarding/first_run_view.dart:33`, `first_run_flag.dart`; adım yapısı bu bilette okunmadı (`DOĞRULANMADI`) |
| Paywall / erişim | `course_access.dart:20-29` | **SATIR DÜZELTME:** ücretsiz kural `:29-42` (`freeLessons` :32-38, `isFree` :41-42); teen politikası `:11-18`, `:20-25` yalnız doc yorumu | `lib/app/course/course_access.dart:36-42`, `paid_lesson_lock.dart:20-21` |
| Abonelik düzeni | ~ilk üçte bir ücretsiz; Choreia ya da Motion+ | DOĞRU | `course_access.dart:22-26`; `paid_lesson_lock.dart:20-21` |
| ASC metni | "Choreia: Learn to Dance" / "Five solo dance practice paths" | DOĞRU | `docs/store/listing.json:8-9` |
| Core | 13 dosya | DOĞRU (`grep -rl "package:motion_core/motion_core.dart" lib` = 13) | `lib/` |

Ortak kalan: Core çatısı, ücretsiz-önce erişim kalıbı, hesap/abonelik grubu. Paywall plan/fiyat ekran düzeni ekran olarak okunmadı (`DOĞRULANMADI`).

## 3. Boşluk listesi ve düzeltme tahmini

Beden: S ≈ metin/not, M ≈ küçük kod+mağaza varlığı, L ≈ ürün farklılığı. Hiçbiri bu bilette uygulanmaz. Toplam: **S=4, M=1, L=1 (6 boşluk).**

| # | Boşluk | Kanıt | Önerilen düzeltme | Beden |
|---|---|---|---|---|
| G1 | Beş Motion uygulaması aynı dönemde gönderildi; çatı ve erişim kalıbı ortak | §2; Lissom G1 | Gönderimleri zamana yay; Resolution Center'da olgusal açıklama | S |
| G2 | Android bildirimi `CAMERA` iznini ve kamera özelliğini bildiriyor, oysa kamera kapalı ve notlar "kamera izni istenmez" diyor | `android/app/src/main/AndroidManifest.xml:3-4`; `REVIEW-NOTES-DRAFT.md:38-39`; iOS `Info.plist:14-15` açıklaması "bu sürümde kapalı" | Bildirimden izni kaldırmak ya da notu "çalışma zamanında istenmez" diye daraltmak; kod/manifest değişikliği ayrı bilet (bu bilette yapılmadı) | M |
| G3 | Choreia'nın tek gerçek farklılaştırıcısı olan kamera kapalı; canlı ders kodu bayrak arkasında | §1 kamera notu | Kamerayı gerekçe gösterme; bayrağı açmak kurucu kararı | L (karar kurucuda) |
| G4 | Mağaza metni ve ekran görüntüleri ortak kabuğu gösterebilir; dansa özgü içerik öne çıkmalı | `docs/store/listing.json:8-9`; `docs/store/feature-graphics`, `icon-candidates` | Ekran görüntülerinde 5 farklı dans stilinin yazılı ders sayfaları, 48 ders/14 dil vurgusu | S |
| G5 | İçeriğin özgünlüğü/kaynağı hakem için kanıtlanmalı | `content/*_course.json` (`provenance`, `sources`); `REVIEW-NOTES-DRAFT.md:10-14` | Reviewer notuna kaynak kapsamı ve yazılı ders yapısı cümlesi; üretim yöntemi kanıtı gelmeden iddia yok | S |
| G6 | `STORE-LISTING-TASLAK.md` içinde eski kamera/canlı iddia kayıtları (tarihsel) ve `listing*.json` `cameraPermissionRationale` blokları kapalı özellik izi taşıyor | `docs/store/STORE-LISTING-TASLAK.md:84-88` (zaten "yayın metni olarak kullanmayın" etiketli), eski içerik `:90-146`; `docs/store/listing.json:21-23` | Dışa aktarılan alanlarda olmadığını doğrula (`REVIEW-NOTES-DRAFT.md:91` "mağaza açıklamasına eklenmez"); etiket zaten var, ek işlem gerekmez; yalnız `cameraPermissionRationale` blokları dışa aktarılan alana girmesin | S |

## 4. Resolution Center yanıt taslağı (TASLAK — GÖNDERİLMEZ)

> Merhaba,
> Choreia, beş Motion uygulamasından biri olarak benzer dönemde incelemeye gönderildi; bu yüzden benzer bir paket gibi göründüğünü anlıyoruz. Gönderimleri artık zamana yayıyoruz.
> Choreia yalnız solo dansa yöneliktir: 14 dilde yazılı derslerle beş kurs (Salsa On1 48 ders, Hip-Hop 6 temel + 8 beceri, Line Dance 12, Latin Fusion 10, özgün kısa-form 10). Her derste uygulama görevi ve öz-kontrol vardır; sonuçlar kendi bildirimli çalışma kaydıdır, beceri belgelemesi değildir. Diğer Motion uygulamaları başka alanlara (gitar, yoga, calisthenics, boks) aittir.
> Hesap, abonelik ve güvenlik altyapısı ile ücretsiz-önce erişim kalıbı ortaktır; içerik, ad, ikon ve alan ayrıdır. Bu sürümde canlı kamera kapalıdır ve farklılık olarak öne sürülmemektedir.
> Ek bilgi isterseniz memnuniyetle sağlarız.

Notlar: (a) Ret metni okununca yeniden yazılmalı. (b) "Diğer uygulamalarda dans içeriği bulunmaz" Core'un alan içeriği taşımadığı varsayımına dayanır; Motion orchestration doğrulasın. (c) Gönderim kurucu/Motion orchestration işidir.

## 5. İnceleme notu (REVIEW-NOTES-DRAFT) denetimi

Sonuç: **TEMİZ.** Taslak kapalı kamerayı doğru anlatıyor; hiçbir kamera özelliğine "var" diye atıf yok.
- `docs/store/REVIEW-NOTES-DRAFT.md:5-6` ("canlı kamera ve puanlama kapalı"), `:38-39` ("Live camera practice and scoring are not part of this release; no camera permission is requested"), `:52` (TR karşılığı "…bu sürümde yoktur"), `:91` ("Kamera izin gerekçesi mağaza açıklamasına eklenmez").
- Ayrı reviewer-notes dosyası yok (`find` ile `*reviewer*`, `*review-notes*`, `release-review*` yalnız bu dosyayı verdi); değişiklik yapılmadı.
- Dikkat: `:38-39` "kamera izni istenmez" çalışma zamanı için doğrudur; Android bildiriminde izin satırı durduğu için G2'ye bakın.

## 6. Doğrulanmayanlar

- Resmî ret metni ve güncel 4.3(a) yönerge metni.
- İlk-çalıştırma (onboarding) adım yapısı; paywall ekran düzeni; Core `motion_account` pin'inin Choreia derlemesindeki değeri (bayrak değeri Core deposunda okundu).
- Diğer uygulamaların ders şeması ve metinleri; ders JSON'larında alan kümesi farkı.
- Android `CAMERA` izninin derlenmiş pakette fiilen görünüp görünmediği (yalnız manifest kaynağı okundu).
