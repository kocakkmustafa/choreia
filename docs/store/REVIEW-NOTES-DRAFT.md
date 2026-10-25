# İncelemeci notu taslağı — 23 Ekim 2026

Yerel hazırlıktır; ASC/Play alanlarına kaydedilmedi. Paket kimliği
`com.yulalab.choreia`, aday sürüm `1.0.0 (4)` (satış açık ilk imzalı aday;
satış öncesi ayrı imzalı aday üretilmedi). Kurucu kararı (23 Ekim): abonelik satışı ilk
sürümde açık, canlı kamera ve puanlama kapalı. Tam öğretim hedefi korunur.

## English — proposed reviewer notes

Choreia contains five solo dance courses as bundled written lessons with
practice tasks and self-checks: Salsa On1 (48 lessons in 8 modules), Hip-Hop
Foundations (8), Line Dance (12), Latin Fusion (10) and original short-form
dance (10). These are study records and self-checks, not certification of
dance skill. Demonstration videos and an in-app music catalogue are not
included.

1. Complete the first-run introduction and continue without an account.
2. Open STYLES and a course. The first lessons of every course are free
   (Salsa On1 modules 1–3; the first third of the other four courses).
   Open a free lesson, read it and record your own practice. Check PROGRESS.
3. Open a later lesson and tap "Unlock with membership". You are asked to sign
   in or register (Motion account, 13+), then the membership screen shows the
   store's offers: Choreia Individual (monthly / yearly, this app) and Motion+
   (monthly / yearly, all five Yula Motion apps). Prices come from the store
   (US base: Choreia $11.99/month or $69.99/year; Motion+ $19.99/month or
   $129.99/year). Eligible new members start with a 14-day free trial.
   The screen shows the auto-renewal terms, Restore Purchases, Manage
   subscription (opens the store's subscription settings), Terms of Use
   (https://yulalab.com/terms) and Privacy Policy
   (https://yulalab.com/privacy/motion).
4. After a free trial, payment is charged to the store account unless the
   subscription is cancelled at least 24 hours before the trial ends; without
   a trial it is charged at confirmation. Subscriptions renew
   automatically unless cancelled at least 24 hours before the end of the
   current period; manage or cancel in the store's account settings. Deleting
   the Motion account does not cancel a store subscription.
5. PROFILE → Account also offers account deletion with explicit confirmation.
   Live camera practice and scoring are not part of this release; no camera
   permission is requested.

Sandbox reviewer credentials are provided only in the store's private review
fields at submission time. No credentials are stored in this document and no
fabricated entitlement is used.

## Türkçe — karşılık

Hesapsız devam edin; her kursun ilk dersleri ücretsizdir (Salsa modül 1–3,
diğer dört kursun ilk üçte biri). Sonraki bir derste "Üyelikle aç" → Motion
hesabı (13+) → üyelik ekranı: mağazadan gelen Choreia Bireysel ve Motion+
aylık/yıllık teklifleri (ABD bazı: Choreia $11,99/ay · $69,99/yıl; Motion+ $19,99/ay · $129,99/yıl; uygun yeni üyelere 14 gün ücretsiz deneme), otomatik yenileme metni, Satın alımları geri yükle,
Aboneliği yönet, Kullanım Koşulları ve Gizlilik bağlantıları. Hesap silmek
mağaza aboneliğini iptal etmez. Canlı kamera ve puanlama bu sürümde yoktur.

## Yayın öncesi kesin kapılar

- StoreKit sandbox / Play license tester kabulü (SB-01..SB-09,
  `RELEASE-ACCOUNT-SANDBOX-CHECKLIST.md`) çalıştırılmadı.
- Yaş/veli backend'i (migration + `motion-parental-consent` + mail + site onay
  sayfası) canlı değil; Core kuralı gereği yaş akışlı build bu deploy olmadan
  kullanıcıya gitmez.
- ASC abonelik grubu/metadata ve Schedule 2 (Paid Apps) durumu, Play ürünleri
  (DRAFT) gönderimden önce salt okunur doğrulanır.
- `https://yulalab.com/terms` canlı olmalı.
- Gerçek cihaz (iOS/Android) yaşam döngüsü, VoiceOver ve hesap kabulü açık.
- Yükleme ayrı onaydır; bu dosya yükleme onayı değildir.

## 18 Ekim notundan korunan mağaza/gizlilik kapıları

- Play Console salt okunur 18 Ekim 00:31:52 UTC kontrolünde mağaza kurulumu 10/11;
  son adım mağaza girişi. Üretim erişimi için en az 12 test kullanıcısıyla
  kesintisiz 14 gün kapalı test isteniyor, mevcut kayıtlı kullanıcı 0.
- Play yükleme sertifikası ilk AAB yüklenene kadar görünmüyor. Google'ın
  uygulama imza sertifikası yerel yükleme anahtarı yerine karşılaştırılamaz.
- Kayıtlı Play hesap silme URL'si
  `https://yulalab.com/en/privacy/motion#motion-account-deletion`; veri silme
  ve politika URL'si `https://yulalab.com/en/privacy/motion`. URL kaydı
  doğrulandı; gerçek silme talebi/yerine getirme kabulü çalıştırılmadı.
- Kayıtlı Play veri türleri ad/e-posta/kullanıcı kimliği/diğer kişisel bilgi;
  isteğe bağlı, paylaşım yok, aktarım şifreli. Konum ve uygulama tanılama
  grupları seçilmemiş. Apple manifestindeki yaklaşık konum/tanılama ve
  sunucu güvenlik günlükleriyle platform tanımı/fiili saklama karşılaştırması
  tamamlanmalı; otomatik beyan değişikliği yapılmadı.

Alan sınırları [Apple sürüm alanları](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)
ve [Play mağaza alanları](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en)
ile kontrol edildi. `listing.json` ve `listing.tr-TR.json` içindeki `$` ile
başlayan tarihsel araştırmalar dışarı aktarılmamalı. Yalnız appStore alanları,
Play başlık/kısa/tam açıklama, destek ve politika URL'leri form taslağıdır.
Kamera izin gerekçesi mağaza açıklamasına eklenmez.
