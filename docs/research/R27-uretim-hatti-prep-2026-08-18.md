> Üretim hattı PREP turunun (2026-08-18 kickoff) dört maddesi tek dosyada. Kaynak zinciri her bölümde ayrı. Bu bir karar belgesi değil, orkestratöre/kurucuya sunulacak bir envanter+öneri paketidir.

# R27 — Üretim hattı PREP envanteri (2026-08-18)

## A. 34 yüzey — W1–W5 + Hula durum envanteri (salt-okuma, `content/library.json` doğrudan okundu)

| Dalga | Stil ID'leri | status | Not |
|---|---|---|---|
| W1 (5) | hip_hop_foundations | **demoOpen** | 7 ders yazılı, yalnız `hh_l1_bounce` başlatılabilir (`step` alanı dolu), skorsuz |
| | salsa_shines | **live** | 9 ders yazılı, 1 skorlu (`ss_l1_footwork`) — ama `shipGates.bpmResolved` KAPALI, kullanıcı hiçbirine ulaşamıyor (bkz §B) |
| | latin_fusion_fitness, line_dance, tiktok_format | comingSoon | disk üzerinde ders yok |
| W2 (9) | kpop_point, bachata_solo, afrobeats, dancehall, shuffle, belly_dance, bollywood, merengue_solo, cumbia_solo | comingSoon | tamamı — Amapiano ayrı ID değil, `afrobeats` altında döner trend paketi (roadmap §4 ile uyumlu) |
| W3 (10) | ballroom_latin_solo, tap, locking, popping, waacking, vogue, jazz, samba_no_pe, solo_jazz_charleston, bhangra | comingSoon | Funk Styles 4 AYRI sayfa (`openDecision IA-1` kararı — tek sayfa değil) |
| W4 (7) | ballet_barre, contemporary, flamenco, irish_dance, kizomba_zouk_solo, garba, twerk_reggaeton | comingSoon | — |
| W5 (2) | heels, breaking | comingSoon | — |
| Hula (1) | hula | **onHold** | `onHoldReason` alanı dolu, kurucu ortaklık kararına bağlı, sessiz silinmemiş |

**Toplam 34** (`pageCountEffect` notu kendi kendini doğruluyor: 33 dalgalı + Hula). **Envanterde sahte/aşırı-iddia YOK** — comingSoon 29 kayıt disk üzerinde gerçekten ders taşımıyor (mekanik doğrulama: `content/styles/` altında yalnız `shuffle, samba_no_pe, dancehall, hip_hop_foundations, salsa_shines` klasörleri var — 5 stil, 34 değil; kalan 29'un `status:comingSoon`u dosya YOKLUĞUYLA tutarlı).

## B. BİLİNEN P0 — yeniden ölçüldü, orijinal çerçeve doğrulanmadı

Kickoff'ta bildirilen P0: *"library.json 'salsa_shines=live' diyor ama runtime'da yalnız Bounce startable, Salsa erişilemez — status/runtime çelişkisi (dürüstlük ihlali sınıfı)."*

**Ölçüm sonucu: sembptom doğru, ama "çelişki/dürüstlük ihlali" çerçevesi yanlış — bu, kasıtlı, test edilmiş, ekran-doğrulanmış bir tasarım.**

Kanıt zinciri (hepsi doğrudan okundu, bu turda):
1. `content/library.json` satır ~155 — `salsa_shines.statusNote` KENDİSİ gerilimi 07-30'dan beri adıyla açıklıyor: içerik-gerçeği (`live`, skorlu ders var) ile ship-kapısı (BPM DISPUTED) İKİ FARKLI eksen, kafes tanımı ikisini birbirine bağlamıyor.
2. `content/styles/salsa_shines/style.json` `shipGatesNote` (satır ~305) — normatif kural M-F-130'u BİREBİR isimlendiriyor: *"this style is honestly BOTH live... AND unshippable... reading one as a proxy for the other is the C-101 defect."*
3. `workspace/DEFTER.md` C-101→C-103→C-138 — bu tam gerilim 2026-07-30 civarında BULUNDU, M-F-130 normatif kararına bağlandı, `style_availability.dart` ile mimariye kilitlendi, testle kapatıldı.
4. `lib/app/style_availability.dart` — `StyleView.derive()` iki ekseni render-anında (never cached) birleştiriyor; salsa için sonuç `Availability.gatedByRelease` + isimli kullanıcı cümlesi: *"Not open — the beat for this style is unconfirmed, and we will not grade your timing against a count we are not sure of."* Sessiz gizleme YOK, "live" rozeti kullanıcıya HİÇ sızmıyor.
5. `docs/store/listing.json` `$salsaExcludedWhy`/`$onlyOneStartableLessonWhy` (2026-08-17, `C-308`) — App Store Connect taslak metni salsa'dan BİLEREK hiç bahsetmiyor; description yalnız Bounce'ı "INTERACTIVE TODAY" sayıyor.
6. `docs/device-day/PAKET.md` + `RECIPE.md` (2026-08-17) — bu KOD OKUMASI değil, GERÇEK simülatör ekranından doğrulandı: *"Salsa Shines — BUILT·NOT OPEN — 9 LESSONS WRITTEN·1 GRADED·NONE OPEN — Not open — the beat for this style is unconfirmed..."* ekranda birebir görüldü.
7. **Bugünkü canlı ölçüm (bu oturum):** `bash tool/gates.sh` → **100% yeşil** — 269 flutter test + 36 engine test + tüm özel doğrulayıcı/self-test (validate_content, template_assets, ledger_freshness, closure_authority, identity_read...) geçti, `flutter analyze` 0 uyarı.

**Sonuç:** Tetikleyen semptom ("Salsa'ya ulaşılamıyor") gerçek ve doğru — ama bu KASITLI davranış, zaten adıyla bilinen bir defect-sınıfının (C-101) TERSİNE çevrilmiş hâli, panelin/kullanıcının önünde yalan söylemiyor. Muhtemel okuma: 2026-08-18 sistemik denetim `library.json`'un ham `status` alanını okuyup runtime'ı deneyip ikisini karşılaştırdı, ama `statusNote`/`shipGatesNote`/DEFTER geçmişini okumadı — yani **denetimin kendisi C-101 sınıfı bir vekil-okuma yapmış olabilir.**

**Gerçekten açık olan, CHO-P0-001'in formal teslimatı:** `docs/evidence/production-line/` HİÇ yok; roadmap'in istediği "catalog diff + state-machine test çıktısı + dört viewport screenshot + iddia matrisi" paketi henüz PAKETLENMEDİ (malzeme var, format yok). Ayrıca **2026-08-17'de YENİ bulunan, hâlâ açık bir sorun**: `choreia-hatti` simülatöründe giriş köprüsü (tap/swipe/HOME) tamamen yanıtsız kaldı — yalnız 1/16 RECIPE.md satırı (STYLES sekmesi) gerçek ekrandan doğrulanabildi, kalan 15 satır hâlâ kod-okuması. Bu, aile-geneli "kamera köprüsü hiç ölçülmedi" sorusunun bir kardeşi ve dört-viewport kanıt paketini bloklayabilir.

**Öneri (orkestratöre, karar bende değil):** CHO-P0-001'i "acil dürüstlük ihlali" değil "formal kanıt paketleme + tazelik denetimi" olarak çerçevele. Erken yazma slotu gerekiyorsa kapsam: (i) 29 comingSoon kaydının TAMAMINI tek tek disk-yokluğuyla çapraz doğrula (bugün yalnız dizin listesiyle örneklendi), (ii) simülatör giriş-köprüsü arızasını gider veya EXTERNAL_GATE olarak adlandır, (iii) dört-viewport ekran kanıtını üret, (iv) evidence paketini `docs/evidence/production-line/CHO-P0-001/` altında biçimlendir.

## C. Hula — kültürel ortaklık kapısı, partner araştırma notu

Ürünün kendi kuralı (`library.json` `onHoldReason`, blueprint §1, roadmap §4 W5): hālau/kumu-hula ortaklığı OLMADAN jenerik kaynaktan içerik üretimi YASAK. Bu not bir ilişki KURMUYOR, yalnız kurucunun/atanacak bir irtibat kişisinin başlayabileceği GERÇEK, DOĞRULANMIŞ adaylar sunuyor (WebSearch, 2026-08-18, birincil kaynak — kuruluşların kendi siteleri).

**En güçlü aday — Hula Preservation Society** (hulapreservation.org, Kaneohe, HI; 2000'den beri faaliyette): Misyonu ZATEN "kumu/elders'ın bilgisini dijital teknolojiyle koruma ve paylaşma" — Choreia'nın ihtiyacıyla doğrudan örtüşüyor. Bilinen kurumsal ortaklıkları var: Hawaii Üniversitesi Kütüphane/Bilgi Bilimi programı arşivi, Native Arts and Cultures Foundation, Lesley Family Foundation. **Niye ilk aday:** dijital-ortaklık PRESEDENTİ zaten mevcut, tek bir kumu değil bir kurum — güvenilirlik ve süreklilik açısından bireysel bir hālau'dan daha düşük risk.

**İkincil adaylar:**
- **Kumu Hula Association of Northern California** (kumuhulaassociation.com) — birden fazla kumu hula'yı TEK çatı altında toplayan bir dernek; anakara-merkezli (Hayward, CA), erişim/iletişim mesafesi Hawaii merkezli hālau'lara göre daha kolay olabilir.
- Bireysel hālau (yalnız isim tespiti, YETERLİLİK/İSTEKLİLİK doğrulanmadı): Hālau Hula Ka Noʻeau (artofhula.com), Hālau Hula Kauluokalā (halauhulakauluokala.org), Kū Mai Ka Hula (kumaikahula.com), Kulia I Ka Punawai (kuliaikapunawai.org).
- **Presedent modeli (ortaklık YAPISI için, doğrudan aday değil):** "HULA: Becoming Kumu" belgeseli — yapımcılar ile Ke Kai O Kahiki hālau'sı arasında ORTAK SAHİPLİK modeliyle çalışılmış; adil-ücret/attribution sözleşmesi tasarlarken referans alınabilecek gerçek bir emsal.

**Sınır, adıyla:** Bu araştırma yalnız KAMUYA AÇIK, kuruluşların kendi sitelerinden toplanan isim/URL bilgisidir — hiçbir kuruluşla temas kurulmadı, yeterlilik/istek/ücret doğrulanmadı. Roadmap §13 ve CHOREIA roadmap §13 açık: *"Hula ortaklığı ve duyusal-ifade policy kararı"* AI'ın tek başına kabul edemeyeceği kalemlerden — ilk temas, görüşme ve sözleşme kurucu kapısıdır (Founder Day CHO-FD2).

Sources:
- [Hula Preservation Society – Hawaii](https://hulapreservation.org/)
- [Hula Preservation Society Archive — UH Library and Information Science Program](https://www.hawaii.edu/lis/hula-preservation-society/)
- [Hula Preservation Society | Native Arts and Cultures Foundation](https://www.nativeartsandcultures.org/hula-preservation-society)
- [Hula Preservation Society | Lesley Family Foundation](https://lesleyfamilyfoundation.org/grants/hula-preservation-society/)
- [Home | Kumu Hula Association of Northern California](https://www.kumuhulaassociation.com/)
- [HULA | BECOMING KUMU](https://www.hulaproject.com/)
- [News — Hālau Hula Ka Noʻeau](https://www.artofhula.com/news)
- [Hālau Hula Kauluokalā](https://halauhulakauluokala.org/)
- [Kū Mai Ka Hula](https://www.kumaikahula.com/)
- [Kulia I Ka Punawai](https://www.kuliaikapunawai.org)

## D. Beat kataloğu müzik hakları — composition/master/sync/territory gap analizi

Mevcut kaynak: `docs/research/R3-muzik-lisans.md` (2026-07-26, ~20 sağlayıcı, birincil-kaynak taramalı, karar tablosu + 12 tuzak + 3 önerilen yol). **Bu doküman güncel ve tekrar üretilmeye gerek yok** — ama roadmap CHO-P1-003'ün istediği tam alan seti (composition/master/sync/territory/platform/süre/renewal) karşısında sistematik değil, üç eksen kapalı:

| Eksen | R3'te durum |
|---|---|
| **Master** (kayıt hakkı) | ✅ Kapsamlı — bu R3'ün ana konusu |
| **Sync** (senkron/app-içi kullanım) | ✅ Kapsamlı — R3'ün "Çekirdek soru"su bizzat bu |
| **Composition** (beste hakkı, kayıttan ayrı) | 🟡 Örtük — taranan sağlayıcıların hepsi ORİJİNAL prodüksiyon müziği (cover değil), yani tek sağlayıcı hem composition hem master'ı kontrol ediyor VARSAYIMI makul ama hiçbir satırda AÇIKÇA doğrulanmadı |
| **Territory** | 🔴 **Sistematik değil** — yalnız 3-4 sağlayıcıda tesadüfen "worldwide" geçiyor (Pond5, Melodie, Incompetech/CC-BY); geri kalanlarda territory hiç sorulmamış. Choreia dünya geneline dağıtılacak (Burun Farkı'nın Türkiye-only kısıtı YOK) — bu alan CHO-P1-003'ün "eksiksiz hak kaydı" şartını karşılamaz |
| **Platform** (App Store + Play ayrı ayrı) | 🔴 Hiç ayrılmamış — "app/game" dili iki mağazayı da örtük kapsıyor ama ayrı doğrulanmadı |
| **Süre/renewal** | ✅ Kapsamlı (perpetual vs abonelik-bağımlı ayrımı, Uppbeat md.6.4 tuzağı dahil) |

**Öneri:** R3'ün "En kaliteli + BPM garantili" yolu (Uppbeat Pro, $27.99/ay) hâlâ en güçlü aday — BPM metadata Choreia'nın beat-grid ihtiyacı için kritik ve R3'ün kendi ölçümünde "en net evet" örneği. Satın alma kararına gitmeden önce (R3 kapısı: kurucu-tek-harcama, blueprint §8) tek bir ek adım gerekiyor: seçilen sağlayıcıya (muhtemelen Uppbeat) DOĞRUDAN yazılı soru — "worldwide distribution + composition-and-master bundled + separately for App Store and Google Play" üçünü tek cümlede teyit ettirmek. Bu, satın alma ONAYI değil, satın alma KARARINI besleyen son doğrulama adımı.

**Rights-ledger şema önerisi** (`MOTION-CONTENT-001`/`CHO-P1-003`'ün istediği alan seti, Uppbeat varsayımıyla doldurulmuş taslak):
`{ provider: "Uppbeat", tier: "Creator|Pro", composition: "bundled (production-music, not cover)", master: "bundled, same provider", sync: "explicit — Permitted Media (iv) online games or applications", territory: "TEYİT GEREKİR", platform: "TEYİT GEREKİR (iOS+Android ayrı ayrı)", duration: "perpetual IF first published while subscription active (md.6.4)", renewal: "N/A (perpetual once published)", bpmMetadata: true, sourceDate: "2026-07-26" }`

Sources: (R3'ün kendi birincil-kaynak listesi; bu bölüm yeni bir web taraması yapmadı, yalnız R3'ü roadmap şemasına karşı denetledi)

## E. 8-cihaz matrisi — EXTERNAL_GATE + `run_device_matrix.sh` raporlama önerisi

**Durum:** `tool/run_device_matrix.sh` HENÜZ YAZILMADI (dosya-yolu denetimi bu turda: `tool/` içinde yalnız `fetch_pose_model.sh`, `gates.sh`, `hooks/` var). CHO-P0-004'ün deliverable'ı, bugün itibariyle mevcut değil — kickoff'un "eksik-hücre exit 1 tasarımı" ifadesi roadmap METNİNE atıfta bulunuyor, henüz yazılmış koda değil. Bu bir SAPMA değil, roadmap henüz uygulanmadığı için beklenen durum.

**Risk (roadmap CHO-P0-004 madde 4'ün birebir metni):** *"script eksik hücrede exit 1 üretsin"* — bu, "cihaz FİZİKSEL OLARAK yok" ile "cihaz vardı, hücre GERÇEKTEN başarısız oldu" arasında ayrım yapmıyor. Choreia'da (ve muhtemelen tüm Motion ailesinde) 8 cihazın hiçbiri şu an oturumda mevcut değil (kurucuda, aile-geneli açık soru) — roadmap'in yazılı hâliyle koşulursa HER koşum exit 1 verir, yani "gerçek bir regresyon" ile "cihaz hiç yok" ekranda AYNI görünür ve gate kalıcı kırmızı kilitlenir.

**Öneri — mevcut `tool/gates.sh`'in KENDİ üçüncü-hâl (exit 2) sözleşmesini yeniden kullan** (C-210 kararı, bu depoda zaten kurulu ve bugün 100% yeşil koşan bir hakem):
- **exit 0**: mevcut TÜM hücreler (flutter devices --machine'de görünenler) koştu VE eşikleri geçti.
- **exit 1**: **YALNIZ** bir hücre koştu (cihaz vardı) VE ölçülen bir eşiği (ilk poz ≤2.5sn, FPS p10, event-to-cue p95, thermal, crash-free) kaçırdı — GERÇEK regresyon.
- **exit 2**: bir veya daha fazla hücre için C1–C8 manifestindeki cihaz sınıfı `flutter devices --machine` çıktısında YOK — `gates.sh`'in "⚪ ORTAM YOK" kalıbıyla birebir aynı anlam: ne yeşil ne kırmızı, commit/PR'ı bloklamaz, ama sessizce "hepsi geçti"ye de karışmaz.
- JSON çıktısı (roadmap zaten `device-matrix.json` istiyor) her 8 hücreyi RAN_PASS / RAN_FAIL / SKIPPED_NO_DEVICE üç durumundan biriyle etiketlesin — sekiz hücrenin sekizi de dosyada GÖRÜNÜR kalsın, eksik hücre sessizce satırdan düşmesin (bu depodaki "template assets" ve "closure authority" kapılarının zaten uyguladığı "no silent cap" disipliniyle aynı).

Bu tasarım roadmap'in "sekiz hücrenin sekizi geçmeden REAL_DEVICE tamamlanmaz" şartını DEĞİŞTİRMİYOR (hâlâ exit 2 varken `REAL_DEVICE`e geçilemez) — yalnız cihazsız bir PREP/CI koşumunun sahte-kırmızı ile oturumu/CI'ı kilitlemesini önlüyor. Uygulama kararı ve roadmap dosyasının güncellenmesi orkestratöre/kurucuya ait; bu yalnız bir tasarım önerisidir.
