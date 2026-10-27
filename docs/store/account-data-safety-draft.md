# Motion hesabı bağlanınca mağaza gizlilik beyanı taslağı — Choreia

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


Durum (2026-09-25): Motion üretim şeması ve SMTP kuruldu; gerçek
e-posta teslimi gözlendi. Kurucu ilk sürümde ücretli kamera oturumlarını ve
abonelik satışını erteledi. Mağaza veri formları ve iPhone kabulü ayrıca
doğrulanacak; bu dosya konsolda onaylanmış nihai beyan değildir.

**2026-09-26 kaynak uzlaştırması:** Yukarıdaki sağlayıcı/SMTP satırları
2026-09-25 tarihli kayıttır; bu tur canlı sağlayıcı sonucu yeniden ölçülmedi.
Mevcut ilk kurs, yerel ilerleme ve native izin dosyaları kontrol edildi.
Mağaza formlarının final paket/SDK ve sağlayıcı kabulü ayrıca yapılır.

## 17 Ekim 2026 · mevcut paket ve beş alan uzlaştırması

Paket kaynağı `642a7d0998cc566570b342f4e7054ffe620b2327`, sürüm
`1.0.0 (3)`. Bu güncelleme belge bakımıdır; yeni paket, sağlayıcı sorgusu,
satın alma veya gerçek hesap silme yapılmadı. Ayrıntılı kabul adımları
[hesap/sandbox kontrol listesinde](RELEASE-ACCOUNT-SANDBOX-CHECKLIST.md).

- Salsa'nın 48 dersi `course-choreia-<owner>.json` günlüğünü kullanır.
  Diğer 38 birim, iki HipHop yolu, Line Dance, Latin Fusion ve kısa-form
  için `study-choreia-<owner>.json` dosyasına yalnız açıkça istenen
  “çalıştım” kaydını ekler. Tekrarlar korunur; sensör/ustalık puanı verilmez.
- Seans JSONL'i, Salsa JSON'u ve yeni çalışma JSON'u konuk/hesap kapsamında
  ayrıdır. Kayıtlar Motion hesabına senkronize edilmez. Normal çıkış bunları
  silmez; konuk kaydı girişte hesaba taşınmaz. Yazılı hatırlama cevapları
  geçicidir; bu cevaplar çalışma günlüğüne eklenmez.
- Uzak silme yalnız yakalanan hesaba ait doğrulanmış UUID cevabıyla kabul
  edilir. `clearLocalHistoryFor` o hesabın üç günlüğünü ve bunların `.tmp`
  dosyalarını owner fence/drain sonrası temizler. Başarısız uzak istek yerel
  geçmişi silmez; onaylanmış uzak silme sonrası yerel hata ayrı
  “temizleme bekliyor” durumudur. Diğer uygulama/cihaz, çevrimiçi silme
  makbuzunu okuyunca kendi kapsamını temizler. Bu bir gerçek cihaz kanıtı değildir.
- Pinli Supabase Flutter SDK'sı oturumu varsayılan yerel
  SharedPreferences depolamasında kalıcılaştırır; parola bu ders günlüklerine
  yazılmaz. OS yedekleri veya bütün cihazlardaki erişim tokenlarının anında
  yok olduğu söylenmez. [Supabase](https://supabase.com/docs/guides/auth/managing-user-data)
  daha önce verilmiş JWT'nin süresine kadar geçerli kalabileceğini açıklar;
  canlı servis/session-revocation kabulü ayrıca gereklidir.
- IPA içinde **9** privacy manifest var. Runner'ın altı collected-data tipi
  kaynakla parse edilmiş plist düzeyinde aynıdır; Xcode XML'i binary pliste
  dönüştürdüğünden dosya hashlerinin aynı olması beklenmez. Bütün paket
  manifestlerinde tracking=false; SDK required-reason API kayıtları ayrıca
  envanterlenmiştir. Bu liste ağ trafiği veya Apple birleşik privacy raporu değildir.
- Android birleştirilmiş pakette INTERNET, CAMERA, ACCESS_NETWORK_STATE,
  WAKE_LOCK, BILLING ve uygulamanın DYNAMIC_RECEIVER_NOT_EXPORTED izni var.
  Mikrofon ve konum izni yok. BILLING varlığı satış/restore yolunun açık
  olduğunu göstermez; `motionPaidFeaturesAvailable=false` kalır.
- Android'de açık `allowBackup`/data-extraction kuralı yok; iOS için app-owned
  backup exclusion kanıtlanmadı. “Motion'a senkronize edilmez” uygulama ağ
  davranışını anlatır; OS bulut yedeği hiç oluşmaz veya hesap silme eski
  OS yedeklerini de yok eder iddiası değildir. Gerçek yedek/geri yükleme
  ve sağlayıcı saklama süreleri final gizlilik kabulünde doğrulanır.

[Canlı ortak politika](https://yulalab.com/en/privacy/motion), uygulama içi
silme yolunun yanında uygulamayı kaldıran kullanıcı için
support@yulalab.com'a silme isteği bağlantısı içerir. İstek göndermedik.
Bu sayfa Play Data deletion URL alanı için mevcut yerel adaydır; formda
kaydedildiği veya taleplerin uçtan uca sonuçlandığı kanıtlanmadı. Politika,
silme makbuzu ile sağlayıcı log/yedek döngülerini ayrı açıklar; sayısal bir
saklama süresi bu kaynak kontrolünden türetilmez.

**2026-10-27 güncellemesi:** beş Motion app'i için ortak hesap silme sayfası
hazırlandı (YUL-14): `https://yulalab.com/en/delete-account/motion` (14 dil;
TR kökü `/delete-account/motion`). Sayfa uygulamasız silme talebini (3 adım,
support@yulalab.com, konu "Motion account deletion"), uygulama içi yolu
(Hesap > Hesabı sil), silinen ve saklanan verileri süreleriyle ve aboneliğin
ayrıca iptal edildiğini anlatır. Durum **pending_live**: YUL-09 site
deploy'uyla canlıya çıkar; o zamana kadar Play'de kayıtlı URL değişmez. Canlı
teyitten sonra Play Data deletion alanı bu URL ile güncellenir.

## Sağlayıcı günlükleri ve kimlik doğrulama — 2026-09-27

Üretim sağlayıcısının 2026-09-26 21:36 UTC tarihli salt okunur alan/sayı
makbuzu, cihaz dışındaki Auth ve edge günlüklerinin saklandığını doğrular.
Ölçüm anına kadar dönen örnekte edge günlüklerinin 6/6 kaydında IP, user-agent ve
ülke/bölge/şehir alanları; Auth günlüklerinin 6/6 kaydında IP ve 2/6 kaydında
hesap kimliği; ayrı Auth audit deposunun 1/1 kaydında kimlik ve user-agent
vardır. Veritabanındaki `auth.audit_log_entries` satır sayısının sıfır olması,
[ayrı Auth günlük deposunun](https://supabase.com/docs/guides/auth/audit-logs)
boş olduğu anlamına gelmez. Ham IP, kimlik, parola veya günlük içeriği bu
belgeye alınmamıştır. Makbuz ortak servise aittir; her uygulamada yeni bir
canlı ağ oturumu ölçüldüğü iddiası değildir.

| Sunucuda saklanan veri | Apple manifest türü | Amaç ve bağlantı |
|---|---|---|
| IP, user-agent, istemci platform/sürüm bilgisi ve Auth/istek güvenlik günlükleri | `NSPrivacyCollectedDataTypeOtherDiagnosticData` | İşletim, güvenlik ve teknik tanılama; App Functionality, kullanıcıya bağlı, tracking yok |
| Edge isteğine eklenen IP tabanlı ülke/bölge/şehir | `NSPrivacyCollectedDataTypeCoarseLocation` | Aynı hizmetin işletim/güvenlik kaydı; App Functionality, kullanıcıya bağlı, tracking yok; GPS veya kesin konum izni değildir |
| Parola kimlik doğrulama verisi ve saklanan parola hash'i | `NSPrivacyCollectedDataTypeOtherDataTypes` | Hesap doğrulama; App Functionality, kullanıcıya bağlı, tracking yok |

[Supabase Auth](https://supabase.com/docs/guides/auth/password-security)
parolanın bcrypt hash'ini `auth.users.encrypted_password` alanında tutar;
parola uygulamanın kurs/seans geçmişine yazılmaz. Apple parola için ayrı
bir tür adlandırmadığından **Other Data Types eşlemesi bu projede yapılan
bir sınıflandırma çıkarımıdır**. Kullanıcı kimliğinin tek yönlü özetiyle
tutulan hesap silme makbuzu da güvenlik/hesap verisidir; hash olması tek
başına anonim veri olduğu anlamına gelmez. IP ve hesap ilişkisinin toplama
öncesinde kaldırıldığı kanıtlanmadığından bu üç tür `Linked=true` beyan edilir.

Manifest artık e-posta, isteğe bağlı ad, kullanıcı ID'si ve bu üç türden
oluşan **altı** collected-data kaydı taşır. Hepsinde
`NSPrivacyCollectedDataTypePurposeAppFunctionality`, `Linked=true` ve
`Tracking=false` vardır. Bu, davranış analitiği veya reklam amacı eklendiği
anlamına gelmez. Kamera/kareler, cihazda kalan kurs ilerlemesi ve seans
geçmişi için collection beyanı eklenmez; Ostinato'nun isteğe bağlı ham sesi
de yalnız cihazdaki sınırlı RAM'de kalır. Diğer dört uygulama mikrofon
kullanmaz. Sunucu günlükleri, cihaz içi geçici işleme ile aynı şey değildir.

[Apple collection ve kullanım tanımları](https://developer.apple.com/app-store/app-privacy-details/)
ve [manifest tür/anahtarları](https://developer.apple.com/documentation/bundleresources/describing-data-use-in-privacy-manifests)
bu ayrımın temelidir. Apple manifestinin güncellenmesi App Store Connect
veya Play Data safety formunun girildiği/onaylandığı anlamına gelmez.
Play kategorileri kendi form tanımlarıyla ayrıca eşleştirilir. Sağlayıcı
saklama süreleri, günlüklerin silme/erişim politikası, gerçek hesap silme
akışı ve son paket/SDK gizlilik raporu ayrı kabul kapılarıdır.

| Veri | Mevcut hesap tasarımı | Beyan adayı |
|---|---|---|
| E-posta | Kayıt, giriş, doğrulama ve parola kurtarma için Supabase Auth'a gönderilir | Apple: `NSPrivacyCollectedDataTypeEmailAddress`; Play: Personal info / Email address; hesaba bağlı, uygulama işlevi |
| Görünen ad | Kullanıcı isteğe bağlı kaydeder; Motion profilinde sunucuya gönderilir | Apple: `NSPrivacyCollectedDataTypeName`; Play: Personal info / Name; isteğe bağlı, hesaba bağlı, uygulama işlevi |
| Ortak hesap ID'si | Oturum ve uygulamaya özel yerel veri ayrımı için kullanılır | Apple: `NSPrivacyCollectedDataTypeUserID`; Play: Personal info / User IDs; hesaba bağlı, uygulama işlevi |
| Satın alma geçmişi | İlk sürümde satış ve satın alma doğrulaması kapalı; uygulama işlem geçmişi göndermez | İlk sürüm Apple/Play veri beyanına girmez; satış açılırsa yeniden değerlendirilir |
| Kamera görüntüsü ve eklem noktaları | Cihazda işlenir; hesap servisine gönderilmez | Görüntü yükleme beyanı yok; canlı SDK ve ağ trafiği release öncesi tekrar denetlenmeli |
| Salsa kursu ilerlemesi | `salsa_progress.dart` konuk/hesap kapsamına ayrılmış yerel JSON yazar; görüntüleme, çalışma ve öz beyan kayıtları Motion hesabına senkronize edilmez | Cihaz dışına gönderilmediği için Apple/Play “collected” beyanına girmez; ders bitirme ustalık puanı değildir |
| Diğer dört alanın çalışma kaydı | `study-choreia-<owner>.json` dosyasında yalnız açık “çalıştım” eylemi ve tekrarı saklanır; hesap servisine gönderilmez | Cihaz dışına aktarılmadığı için collection beyanı eklenmez; fiziksel başarı/ustalık değildir |
| Seans geçmişi | Kullanıcıya ayrılmış yerel JSONL dosyasında kalır; guest geçmişi girişte devralınmaz | Sunucuya aktarılmadığı sürece Apple/Play “collected” tanımına girmez; eski yerel dosya = collected varsayımı `data-safety-matrix.md` içinde tarihsel düzeltme olarak tutulur |
| Mikrofon/ses | İlk kurs mikrofon kullanmaz; iOS mikrofon gerekçesi ve Android `RECORD_AUDIO` yoktur | Ses collected beyanı yoktur; Ostinato'nun isteğe bağlı mikrofon kararı Choreia'ya uygulanmaz |

Kaynakta iOS `PrivacyInfo.xcprivacy` yedi hesap/sağlayıcı veri tipini (26 Ekim 2026'dan beri satın alma geçmişi dahil) `Linked=true`, `Tracking=false`, `PurposeAppFunctionality` ile beyan eder; Android INTERNET ve exact `com.yulalab.choreia://auth/callback` kaydı var. Tracking false kalır. Mikrofon API'si kullanılmadığı sürece mikrofon izni eklenmez. Supabase ve native eklentilerin birleşik Xcode privacy raporu, Android manifest merge ve gerçek mağaza formları ayrı release kapısıdır. Hesap silme uzakta doğrulandıktan sonra ilgili hesabın seans, Salsa ve çalışma günlükleri ile kendi `.tmp` dosyaları temizlenir; uzak hata halinde bu geçmiş korunur.

2026-09-26 kontrolde hesap silme yerel kurs JSON'u ve seans JSONL'i için
`account_bridge.dart` kapsamını kullanır. Çözümlenen `motion_account`
paketindeki `motion_release_policy.dart` değeri
`motionPaidFeaturesAvailable=false`; hesap/üyelik ve paid-session yolları
bu kapıyla satışa açılmaz. Apple manifestinde purchase-history türü yoktur.
Matristeki eski satın alma “collected” satırı sonraki satış planıydı;
mevcut ilk sürümde toplanmıyor olarak uzlaştırıldı.
**26 Ekim 2026 güncellemesi:** satış ilk sürümde açık (kurucu kararı 23 Ekim)
ve Core R3 pin'i `motionSubscriptionSalesAvailable=true` kullanır; satın alma
kanıtı `motion-verify-purchase` ile sunucuda doğrulanıp hesaba bağlı hak olarak
tutulur. Bu yüzden manifest `NSPrivacyCollectedDataTypePurchaseHistory`
(linked, tracking yok, app functionality) beyan eder; Play karşılığı Financial
info → Purchase history. Yukarıdaki 26 Eylül paragrafı tarihsel kayıttır. Hesap e-posta/ID'si ve
isteğe bağlı görünen adın sağlayıcıya gönderimi bundan ayrı kalır.

[Apple](https://developer.apple.com/app-store/app-privacy-details/) ve
[Google Play](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
yalnız cihazda kalan işlem/kaydın collection beyanı gerektirmediğini açıklar.
Cihaz dışına gönderilen türetilmiş veri veya SDK trafiği ayrı değerlendirilir.
Kaynaklar: `lib/main.dart`, `lib/app/course/salsa_progress.dart`,
`lib/app/account_bridge.dart`, native izin dosyaları ve gizlilik manifesti.

Kaynak: [Apple privacy manifest](https://developer.apple.com/documentation/BundleResources/describing-data-use-in-privacy-manifests), [Apple App Privacy](https://developer.apple.com/app-store/app-privacy-details/), [Google Play Data safety](https://support.google.com/googleplay/android-developer/answer/10787469).
