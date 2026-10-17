# Choreia · hesap, sandbox ve dağıtım kabulü · 17 Ekim 2026

Durum: modelden bağımsız **yerel hazırlık**. Gerçek hesap, fiziksel cihaz,
provider transaction veya mağaza kabulü değildir. Paket kaynağı
`642a7d0998cc566570b342f4e7054ffe620b2327`; pinli Core
`ef60e346934d7e5d45c87deb81583b263575b208`. Doküman bakımı runtime,
manifest, model, Core pini, ürün veya imza kimliği değiştirmez.

## Mevcut paketler ve kullanım sınırı

| Paket | Doğrulanmış tür | Kullanım/önkoşul |
|---|---|---|
| iOS IPA, `com.yulalab.choreia`, `1.0.0 (3)` | Apple Distribution, team `T5HZGYBWK8`; export `app-store-connect`; `get-task-allow=false`; profile'da cihaz listesi yok; `iphoneos27.0` | App Store Connect/TestFlight dağıtım adayıdır. USB ile doğrudan kurulacak development paketi değildir. Mevcut IPA'nın katı imza/asset/model/dSYM kanıtları korunur. |
| Android AAB, aynı kimlik/sürüm | Release; debuggable=false, testOnly=false; mevcut upload sertifikası, targetSdk37/minSdk24 | Play yükleme adayıdır; AAB doğrudan kurulacak APK değildir. Play Console'daki kayıtlı upload sertifikası henüz bu oturumda eşleştirilmedi. Play kullanıcılara app-signing anahtarıyla üretilmiş APK verir. |

IPA SHA-256: `d5072e4757cd94c23adbb01cb1c07056cbdbefec84575c7fb1ab0321f3996bd8`.
AAB SHA-256: `b2b8321784ab6941fe8d6a324da354b4b0f7b02931b02a5ba6c995c949db6086`.
AAB upload sertifikası SHA-256:
`693daf438fd77daa0335e6dd266b0b0d16d2dd34214b3e11d1f806cae31e6df2`.

Apple yükleme için uygun rol, bundle/version eşliği, kullanılmamış build
numarası ve Apple processing sonucu gerekir. Yerel imza bunları garanti
etmez. Güncel ASC kaydı `6794721329`, sürüm1.0.0 Prepare for Submission;
17 Ekim önceki readback'te seçili build yoktu. Yükleme günü build3'ün hâlâ
kullanılmamış olduğu tekrar okunmalı. Xcode27/iOS27 SDK pakette kayıtlı;
17 Ekim resmî yükleme sayfası iOS uygulamaları için Xcode26 veya sonrası
yapısını listeler; paket Xcode27/SDK27 içerir. Bu kaynak uyumu server
validation sonucu değildir; koşul yükleme günü yeniden okunur.
[Apple yükleme](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/),
[Play imzalama](https://developer.android.com/studio/publish/app-signing).
Yeni anahtar, kayıtlı cihaz veya kalıcı erişim oluşturulmadı.

İlk üç toplu kabul grubu ve ürün kapıları kapanınca **ayrıca son kullanıcı
yükleme onayı** alınacak. Şimdi TestFlight dahil store upload/push/ücretli CI yok.

## Ulaşılabilen güncel hesap akışı

`MotionAccountPage` profil, giriş/kayıt, doğrulama/parola kurtarma, çıkış ve
ortak hesap silmeyi içerir. Üyelik ve geri yükleme girişi
`motionPaidFeaturesAvailable=false` nedeniyle güncel uygulamada kapalıdır.
Bu kapı test kolaylığı için açılmadı. Yazılı kurslar hesapsız kullanılabilir.
Üyelik durumunu sormayan “Hesabı yenile” akışı, restore sayılmaz.

Uzak silme `motion-delete-account` üzerinden yakalanan hesaba gider;
200 + deleted=true + aynı UUID cevabı gerekir. Ardından o UUID'nin seans,
Salsa ve çalışma günlükleri ile `.tmp` dosyaları owner-drain kapsamında
silinir. Uzak hata bunları korur. Onaylı uzak silme sonrası yerel IO hatası
“temizleme bekliyor” olur; çevrimiçi makbuz kontrolü sonraki açılışta dener.
Silme bütün Motion hesabını/beş uygulamanın server haklarını etkiler;
mağaza aboneliğini otomatik iptal etmez. [Apple silme rehberi](https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion).

Supabase'ın daha önce verilmiş JWT'ler için süre sınırı ayrıca geçerlidir;
“bütün tokenlar anında geçersiz” kabulü yapılmadı.
[Supabase kullanıcı silme](https://supabase.com/docs/guides/auth/managing-user-data).

## Gerçek hesap kabulü · sırayla, kullanıcı kontrollü

Önkoşul: seçilmiş fiziksel cihaz ve mevcut kayıtlı cihazı kapsayan izinli
**development** kurulum yolu. iOS için kullanıcı cihazı açar, bilgisayara
güveni ve Developer Mode'u kendi tamamlar. Yeni provisioning/device
registration gerekiyorsa ayrı açık onay gerekir. Önceki devicectl timeout,
adb OS reddi veya runtime HOLD alternatif araçla aşılmaz. Mevcut uygulama
silinmez; kullanıcı verisini etkileyen kurulum öncesi kapsam belirlenir.

| ID | İşlem ve önkoşul | Kanıt / kapanış |
|---|---|---|
| AC-01 | Kullanıcı iki kendisine ait test Motion hesabını A/B olarak belirler; A'nın daha sonra ortak hesaptan kalıcı silinmesine ayrıca açık onay gerekir. Ana/ücretli hesap kullanılmaz. | Gerçek e-posta, parola, OTP veya token rapora girmez. Kullanıcı güvenli girişte kendisi girer. |
| AC-02 | Konukta bir Salsa, bir diğer-alan birimini çalış; A ile giriş/doğrulama, ad kaydı, uygulama yeniden açma ve çıkış yap; sonra B ile giriş. | Konuk/A/B kayıtları karışmaz; kendi kapsamı yeniden açılınca geri gelir. Ağdaki hesap verisi ile yerel günlük ayrılır. |
| AC-03 | A'da e-posta doğrulama/kurtarma linkini kullanıcı açar; yanlış callback ve background/foreground durumlarını kontrol et. | Doğru `com.yulalab.choreia://auth/callback`; recovery eski ders/media/yazmayı emekliye ayırır; doğrulanmamış oturum ders verisine kabul edilmez. |
| AC-04 | A silme diyaloğunda önce Vazgeç; ayrıca onay verilmişse en son A'yı sil. | Vazgeç/uzak hata veri silmez. Başarı sadece A'nın üç günlüğünü ve tmp'lerini temizler; B/guest korunur. Tekrar giriş reddedilir; ham kimlik tutmadan provider doğrulaması yapılır. |
| AC-05 | Silinmiş A'nın mevcut test verisi olan diğer Motion cihaz/uygulamasını kullanıcıyla çevrimiçi aç. | Silme makbuzu kendi yerel kapsamını temizler. Yalnız Choreia sonucu diğer dört uygulama için kanıt sayılmaz. Çevrimdışı/silme sonrası yerel hata ve OS backup/restore ayrı kaydedilir. |

Bunlar henüz çalıştırılmadı. Önceki izole host/widget testleri ve sentetik
A/B kimlikleri gerçek e-posta teslimi, silme veya cihaz kabulü değildir.
Hesap/SMTP/Edge çağrı sayısı ve ücretsiz test kapsamı ana sohbette
netleştirilmeden provider isteği başlatılmaz. Kalıcı silme özel onayı
alınmadan AC-04'ün başarılı silme koluna geçilmez.

## Restore/sandbox hazırlığı · satış kapısı korunur

Mevcut iOS ürün kimlikleri, önceki salt okunur ASC envanterinden:
`com.yulalab.choreia.individual.monthly`,
`com.yulalab.choreia.individual.yearly`,
`com.yulalab.choreia.motionplus.monthly`,
`com.yulalab.choreia.motionplus.yearly`.
Dördü de Prepare for Submission görünüyordu; test edilebilirlik/metadata
ve bölgeler gerçek sandbox öncesi tekrar okunur. Android kodu
`choreia_individual` ve `choreia_motion_plus` ürünlerinde monthly/yearly
base plan bekler; Play Console eşliği bu tur doğrulanmadı.

[Apple sandbox](https://developer.apple.com/help/app-store-connect/test-in-app-purchases/overview-of-testing-in-sandbox/)
ücretsiz test hesabı ve development-signed cihaz yolu sağlar; yerel StoreKit
konfigürasyonu provider makbuzu değildir. [Google license tester](https://developer.android.com/google/play/billing/test)
hesabı ve **test ödeme aracı** ücret almadan denemeye imkân verir; sıradan
internal-track hesabı otomatik ücretsiz değildir.

Gerçek restore, mevcut satış-kapalı kullanıcı yolunda çalıştırılamaz.
Gelecekte satış/restore kabulü açılacaksa kullanıcı ve Core tek yazarı önce
kontrollü QA kapsamını kararlaştırır; üretim kapısını veya server
production/sandbox ayrımını atlamak kabul değildir. Yeni kalıcı tester
hesabı/erişim veya ürün oluşturulacaksa ayrıca özel onay gerekir.

| ID | Gerekli senaryo | Kapanış ölçütü |
|---|---|---|
| SB-01 | Mevcut izinli sandbox/tester, doğru bundle/product/base-plan/storefront, store'un gerçek fiyatı ve test ödeme işareti | Yalnız yerel fixture fiyatı veya fabricated receipt kabul edilmez; ürün/hesap kaynağı belgelenir. |
| SB-02 | Test satın alma, çıkış/yeniden giriş ve Restore | Store olayı server'da mevcut Motion sahibine doğrulanır; aynı hak geri gelir, iki hak/çift satın alma oluşmaz. |
| SB-03 | Başka Motion hesabı; yanlış uygulama/ürün; Individual/Motion+ ayrımı | Başka sahibin veya scope'un hakkı açılmaz; Motion+ ayrı kabul matrisiyle beş uygulamada doğrulanır. |
| SB-04 | Cancel/pending, offline/server hata, expired/refund/revoke ve account-switch | Doğrulanmamış olay hak vermez; terminal red yetkiyi kapatır; mağaza completion/ack yalnız doğrulanmış olaydan sonra olur; yeniden deneme mümkün kalır. |

Hiçbiri bu bakımda çalıştırılmadı. Test sonucu yalnız testi yapılan gerçek
store ortamı/cihazı/ürünü için geçerli olacaktır.

## Mağaza gizlilik formu için kalan kullanıcı adımı

Mevcut [ortak politika](https://yulalab.com/en/privacy/motion) içinde
“Delete a Motion account and its data” bölümü ve e-posta isteği yolu var;
hesap silme isteği gönderilmedi. [Play](https://support.google.com/googleplay/android-developer/answer/13327111)
için bu web resource URL adayını, uygulama içi silme ve saklanan log/makbuz
sınırıyla birlikte formda incelemek gerekir. Form kaydı/yayın izni bu
belgeyle verilmez. Sağlayıcı retention süreleri ve talep sonuçlanma süresi
varsayılmadan gerçek owner readback'iyle tamamlanır.

Son paket kaynakları, 9 privacy manifest ve merged Android izinlerinin
makbuzu: task-16/model-independent-review/package-privacy-and-distribution.json.
