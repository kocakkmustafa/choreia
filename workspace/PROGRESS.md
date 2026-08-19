# Choreia — İlerleme Kaydı

## 2026-07-25 — Venture AÇILDI (5. aile üyesi; kod YOK)
- Kurucu 5. ürünü teyit etti (dans eğitmeni — planlardaki 'Solo Dance' atfının gerçek karşılığı); isim App Store taramasıyla **Choreia** (0/0 temiz) seçildi.
- Kurulum: repo + bundle-id `com.yulalab.choreia` + ASC kaydı + site kartı + registry + Obsidian.
- Tam plan YOK — M-009 açıldı (kod öncesi zorunlu kapı).

## 2026-07-26 (gece) — KOD KİLİDİ AÇILDI · G0 + G-1 + çekirdek

**Tetik:** kurucu "Choreia'ya başlayalım". Sıralama sonucu: aile tavsiyesi Lissom'du, dolayısıyla **Choreia ilk tetiklenen app oldu ve `motion-core` çekirdeğini bu oturum kurdu** (motion-core CLAUDE.md: "çekirdek kod İLK app'in tetiğiyle yazılır").

### G0 — Araştırma kütüphanesi ✅
4 kollu paralel araştırma, hepsi URL'li ve "DOĞRULANMADI" işaretli. Çıktı: `app/docs/research/`
- **R1 stil kataloğu** (625 satır) — 12 stil × 7 kriter puanlaması
- **R2 rakip elle-doğrulama** (225 satır) — birincil store kaynakları
- **R3 müzik lisansı** (21 sağlayıcı) — app-içi dağıtım hakkı taraması
- **R4 senkron bilimi + veri setleri** — tolerans, gecikme, lisans teyidi

### G-1 — TAM ÜRÜN PLANI 🟡 ONAY BEKLİYOR
`app/docs/choreia-plan.md` — 27 bölüm, 8 karar (K1-K8), 16 DEFTER maddesi, 7 kurucu-onay kalemi.
**C-001/M-009 kapısı: kurucuda.** Onaysız G2'ye geçilmez; brief süpersede edilmedi.

### Çekirdek — `motion-core/packages/motion_core` ✅ (84/84 test, analiz temiz)
Saf Dart, Flutter bağımlılığı yok; native portun doğrulanacağı **normatif referans**.
`pose/` (landmark topolojisi · güven kapısı · One Euro yumuşatma · **yapısal doğrulayıcı**) ·
`geometry/` (torso-göreli normalizasyon · eklem açısı çıkarımı) ·
`scoring/` (tolerans bandı · açısal benzerlik · bantlı DTW · dizi karşılaştırıcı) ·
`rhythm/` (beat ızgarası · algılanan-zaman çizelgesi · zamanlama yargısı) ·
`engine/` (faz state-machine çatısı · geri bildirim önceliklendirici) ·
`fixture/` (şema · replay harness · sentetik iskelet üreteci)

**Ölçülen ayrım gücü** (`SequenceComparator`, sentetik fixture):

| Senaryo | Şekil skoru |
|---|---|
| Aynı hareket, aynı vücut | 1.000 |
| Aynı hareket, farklı vücut tipi | 1.000 |
| Aynı hareket, tracker gürültüsü | 1.000 |
| Aynı hareket, 1.4× tempo | 1.000 |
| **Yanlış hareket** | **0.775** |

### Bu turda yakalanan gerçek hatalar (hepsi testle kapatıldı)
1. **DTW park etme (C-009, P1):** yanlış hareket 0.938 alıyordu → warp cezası → 0.775.
2. **Yönelim açısı çift-sayımı:** `translateScaleRotate` modunda gövde ekseni döndürme öncesi saklanıyordu.
3. **Band doygunluğu yanlış-pozitifi:** dizi köşelerinde kırpılmış sınır her hizalamayı "duvarda" gösteriyordu.
4. **Fixture toleranstan küçüktü (C-011):** 15° genlikli sentetik adım, 12° serbest bandın içinde kalıyordu — hizalama testleri hiçbir şeyi sınamıyordu.
5. **Filtre gecikmesi vs kural eşiği (C-013):** oturma payı olmayan çekimde "recovered" eşiği hiç ateşlenmiyordu.

### Aile kurallarının çekirdeğe işlenmesi
Paralel Gravita/JabLab oturumlarının kurduğu iki bağlayıcı kural aynı gece uygulandı:
- **M-019** `StructuralValidator` — güven kapısı uzuv terslemesini yakalamıyor (Gravita D1: model ters vücudu dik sanıp kol↔bacak takas ediyor, **yüksek güvenle**). Testte kanıtlandı: güven kapısı takası KAÇIRIYOR, yapısal denetim yakalıyor.
- **M-018** `PoseModelVariant` + `ConfidenceGate.forVariant` — `visibility` varyantlar arası kıyaslanamaz.

### Commit'ler (feat dalı, YEREL — push YOK)
`motion-core` dalı `feat/motion-core-bootstrap`:
- `8950c03` çekirdek (normalizasyon · açı-skoru · bantlı DTW · beat ızgarası)
- `914a856` M-019 yapısal denetim + M-018 varyant eşikleri

### Kurucu kararı bekleyen ⛔
- **M-017 (P0):** çekirdek **iki kez** üretiliyor — bu oturumun Dart paketi + paralel Python fixture hattı. **Tek taraflı birleştirme yapılmadı**, karşı tarafın dosyalarına dokunulmadı.
- ~~Plan onayı (C-001)~~ ✅ · ~~remote push~~ ✅ · ~~beat kütüphanesi satın alımı~~ → $0 varsayılan · ~~eğitmen anlaşması~~ → **kaldırıldı** (kurucu çekim yapmaz, M-F-13) · nihai fiyat · IP hukuk görüşü · domain · cihaz benchmark'ı.

## 2026-07-26 (sabah) — plan ONAYLANDI, veri fabrikası direktifi

**Kurucu paketi (M-F-01..16):** plan onaylı (C-001+M-009 kapandı) · gece kararları retrospektif onaylı · K8 aile kuralı oldu · push yapıldı · **Dart `motion_core` KANONİK** ilan edildi, bakım/merge sahibi koordinatör → bu oturum core'a artık YAZMAZ, ihtiyaçları `M-C-*` ile bildirir · **kurucu çekim YAPMAYACAK** → kamu-video konsensüsü tek birincil kaynak · **geniş kütüphane**: 12-stil hasat haritası, launch Hip-Hop+Salsa, ardından House+Afrobeats.

**Üretilenler:** müfredat şeması (`content/SCHEMA.md`) · 2 uçtan uca adım (`hh_bounce`, `ss_basic`) · 2 `style.json` · içerik doğrulayıcı (4 dosya, 0 hata) · G1(c) maliyet ölçüm raporu · `ReferenceBuilder` (çoklu-eğitmen konsensüsü, 94/94 test).

**Bulgular:** C-020 hip-hop hata taksonomisi kullanılamaz (pedagojik öğüt, kameradan görülemez) · C-021 salsa vokabüleri ≥8 hedefini karşılamıyor → **karara bağlandı: tamamlanma kriteri vokabüler-uyarlamalı, genişlik stil sayısından gelir** · C-022 ölçülebilirlik filtresi bağlayıcı (3 adım Tier C) · C-023 darboğaz adım yazmak değil, hareket tarifi + 96 elle anotasyon.

---

## Tur: REFERANS ÜRETİMİ — 2026-07-29 (gece oturumu)

**Üretilenler:** **ÜÇ REFERANS ARTEFAKTI** (`content/references/`) — `hh_running_man` (aile ilk dans referansı, M-F-41) · `hh_roger_rabbit` · `salsa_shines`. Hepsi `provisional`, hepsi 17/17 çekirdek eklemi taşıyor, sözleşme denetimi 3/3 (1790-1912 kontrol). Yeni araçlar: `probe_candidates` (indirme-öncesi triyaj) · `prepare_take` (izotropik+çapalı segment) · `build_reference` (uzlaşma+tolerans) · `measure_tempo` (2× tuzağı silahsız) · `classify_source` (ders↔performans) · `validate_reference` (tüketici-rolü sözleşme denetimi).

**Hasat:** 39 take çıkarıldı, 13 kullanılabilir. Eğitmen bazında: RR 15 hasat/3 ders-kaynağı · RM 8/3 · Salsa 23/4. Ölçülen verim %17-29 (C-066'daki %50 tahmini iyimserdi).

**En pahalı dersler:**
- **Araçlar başarılı çıktı üretti ama referans kapanmamıştı** (C-071) — periyot tespiti tekrarı değil sürekliliği ölçüyordu, raporlanan periyot ölçüm değil arama tabanıydı. Diz toleransı 61.8° bunun dürüst semptomuydu.
- **Dosya sırasına bağlı uzlaşma uzlaşma değildir** (C-075) — açgözlü yönlendirme tohuma bağlıydı; global atamayla çözüldü, yayımlanmış referans geri açılıp yeniden kuruldu.
- **MAD n=3'te aykırıyı tamamen yok sayıyor** (C-070, P0) — tolerans oradan türediği için bir eğitmen 25° farklı çalışsa öğrencisi sessizce hatalı skorlanacaktı.
- **8 eklem yerine 17** (C-086) — fleksiyon tek başına yana açılmış kolu önde tutulandan ayıramaz; dansta uzuv yerleşimi içeriğin kendisi.
- **Kendi ölçümlerimin kapsamını abartmışım** (C-089) — 9 sözcüklük bir PERFORMANS klibi tüm hareket testlerimi geçip Roger Rabbit referansına girmişti. "Bu hareket tekrarlanıyor mu" ile "bu bir öğretim mi" farklı sorular; ikincisi için konuşma kanıtı gerekiyor.

**AÇIK (yeni oturum):**
1. **`beat_annotate` pivotu** — C-032 hareket üzerinden ÇÖZÜLEMEZ (ölçüldü: 379/306/222 BPM, hiçbiri makul aralıkta, dönüşümlülük kararı bulanık). Doğru yol müziği vurmak, hareketi değil. **Yeni oturumun İLK işi.**
2. **RM 3-eğitmen kuyruğu yarım** — 2 aday koşmadı; düzen `~/motion-harvest/choreia/PARK-DURUMU.md`'de.
3. **Yön belirsizliği** — üç referansta da `mirrorConfident=false`; bir take çevrilirse hücrelerin %10-22'si bandını aşıyor. Çözüm: daha çok take veya dış öncül (çapa mirror-invariant, ondan çıkmaz).
4. **Beşinci soru açık kalıyor** — ürettiğim bayrakların gerçek tüketicisi SIFIR (Choreia'nın skorlayıcısı yok). `validate_reference` tüketici rolünü oynuyor ama gerçek bağlama yapılmadı.
5. **Salsa `ss_basic` config'i referansla bağlanmadı** — config `salsa_shines` stilinde ama adım eşleşmesi yok; adım-config ↔ referans bağı hiç kurulmadı.

---

## Tur: BAĞLAMA + GECE VARDİYASI — 2026-07-29/30

**Bu turun tek cümlesi:** üç referans artefaktı vardı ve **hiçbirinin tüketicisi yoktu**; tur sonunda `ss_shine_footwork` ailenin **ikinci tam-zinciri** oldu (referans → config → ölçüm → hüküm → canlılık kanıtı), ve önceki turun 5 açık maddesinin 4'ü kapandı.

### Kapananlar (push'lu: `92ff8f2` → `3fd0835`, 8 commit)

| # (önceki tur) | Sonuç |
|---|---|
| 2 — RM 3-eğitmen kuyruğu | **KAPANDI.** `ZpTgAZBYNrU` eklendi (12 çevrim, en zengin RM kaynağı) → 4 kaynak. `-8W2bnjrhE0` DIŞLANDI: 2× harmonik-çelişki + `measure_tempo` ile `prepare_take` periyotları uyuşmadı (1,033s vs 0,7s) — iki araç birbirini doğrulamadığı için havuza alınmadı. `0UDxiThjwG8` prepare aşamasında elendi. |
| 3 — yön belirsizliği | **salsa'da ÇÖZÜLDÜ, RM/RR'de duruyor.** Belirsizlik havuzun değil TEK kaynağın ithalatıymış: `bqoNqA2hmE4` dışlanınca `mirrorConfident: TRUE` (Choreia'da ilk). |
| 4 — beşinci soru | **KAPANDI.** ss_shine_footwork step-config + `tools/ss_shine_footwork_liveness.py`: gerçek klip + M-C-01 kontrollü bozulmalar + kural-7 runtime teyidi + BPM-kapısı-kapalı kanıtı. |
| 5 — adım-config ↔ referans bağı | **KAPANDI.** step-id stil-adından ayrıldı (`ss_shine_footwork`), Suzy Q kaynak-düzeyi `namedVariant` tag'i korundu. |
| 1 — `beat_annotate` | **AÇIK, kurucu-bekleyen** (canlı tap ~10 dk). Ürün-bağlamayı buna kilitlemedim; faz-ekseniyle BPM'siz kuruldu. |

### En pahalı dersler (bu tur)

- **Kendi kuralımı kendi eşiğimde ihlal ettim (M-F-117).** NO_WEIGHT_TRANSFER eşiğini temiz 3-kaynaktan 1,0°'ye türettim — ama bu, hattın kendi gürültü tabanının (`MIN_TOLERANCE_DEG` 6°) ALTINDA. Choreia'nın kendi önceki dersi ("karar ölçüsü kendi gürültü tabanının altında soru soramaz") burada uygulanmamıştı. Kod artık `calibration-blocked` ve `judge()` onu HİÇ hesaplamıyor.
- **İlk leading_side ölçüm denemem YAPISAL olarak çalışamazdı — canlılık testi yakaladı.** Tek-bin sol-eksi-sağ uyluk farkı **aynalamaya karşı DEĞİŞMEZ** (`mirrored()` hem takas hem işaret-negatifleme yapıyor → `ang_diff` korunuyor); bozulmuş klip birebir aynı −6,43°'yi döndürdü. `prepare_take`'in kendi çapası için kaydettiği tuzağın bir üst katmanda nüksü. Doğru ölçü tam eklem vektörünün iki yönelimde karşılaştırılması (`side_agreement`, `orient()` mantığı) — 15,6° marj, tabanın 2,6 katı.
- **"Ölçtüm" ≠ "skorluyorum".** `library.json` hip-hop'u `status:"live"` (= "kursları açık, SKORLANIYOR") listeliyordu; o stilin skorlanan tek dersi yok. Not "≥3 bağımsız eğitmen ÖLÇÜLDÜ" doğruydu ama ölçüm skorlanan derse hiç dönüşmedi. Choreia artık dürüstçe **0 live**; `validate_content` bunu kapı olarak yakalıyor.
- **"Hiç oluşmadı" ≠ "ateşlenmedi"** (aile sözlüğüne girdi) — tüketicinin okuyamayacağı anahtar, kapatılmış değil VAR OLMAYAN anahtardır.
- **Satır numarasını bölüm numarası sanmak.** UI-BRIEF ilk taslağında plan'a yaptığım referansların bir kısmı satır no'suydu (§39/§72/§468/§491). Gerçek bölümlerle değiştirildi; `§12.4`/`§13.2` doğrulandı ve gerçekten var.

### Üretilenler

- **`side_agreement`** (`build_reference.py`) — taraf-uyumu ölçümü, mirror-invariance tuzağının gerekçesi docstring'e gömülü.
- **Görünürlük kapısı** (`prepare_take.py`) — J-056'nın Python ayağı: `vis < 0.5` eklemde açı NaN (önce 4238 NaN, sonra 0'dı). + NaN→null JSON sanitizasyonu (`allow_nan=False`), 0.8.4 dersi proaktif.
- **Vendoring + `--drift-check`** (`movement_isolator.py`) — pin `eb28039`, `ast` ile fonksiyon-bazlı karşılaştırma; sentetik-drift kanıtıyla doğrulandı. Rig'in per-saniye enerji düzeltmesi port edildi.
- **K10 kurs iskeletleri** — `honesty{measured,notMeasured}` her stile zorunlu; ders nesnesi `scored`/`locked`/`demoOnly` beyan ediyor. **Running Man artık demo-only DERS** (K10'un amacı): "üründen atıldı" değil, "skorlamadan atıldı" — 4 eğitmenlik hasat emeği kullanıcı-yüzü içerik.
- **`docs/design/UI-BRIEF.md`** — claude.ai/design girdisi; omurgası iki gerilim: dans app'inde ritim puanı YOK, 34 sayfa/0 skorlanan.
- **`validate_content` 5 yeni kapı** (honesty · ders-durum · live-statüsü · unlockRule:null · beats:null), 9/9 sentetik-ihlal probunda kırıldı.

### AÇIK (sıradaki oturum)

1. **`beat_annotate` canlı tap — KURUCU** (~10 dk). Açılınca: ders akışı 3. adımı + STEP_LATE + `beats`/`countLabels` + salsa BPM.
2. **NO_WEIGHT_TRANSFER gürültü-tabanı** — çok-kare pencereleme ya da taban-üstü eşik türetimi.
3. **RM/RR `mirrorConfident:false`** — salsa'daki çözüm yolu (belirsiz kaynağı isimle dışla) burada da denenebilir.
4. **`statusValues` sözlüğü** — `comingSoon` = "kurs yok" ama demo-only ders diskte var; yeni statü mü, tanım genişletme mi? Koordinatörde, aile-geneli olabilir.
5. **`hh_bounce` referansı** — hip-hop'un skorlanan ilk dersi için hasat gerekiyor.
6. **movement-science-advisor insan-uzman turu** — danışman kendi sınırını beyan etti (settle noktaları video-gözlem istiyor).

---

## VARDİYA KAPANIŞI — 2026-07-30 (kurucu direktifi: tüm oturumlar sonlandırılıyor)

**Bu turun tek cümlesi:** dört adım (RM/RR kuyruğu, uçtan-uca replay, aile-hizalama paketi, hasat)
tamamı kapandı; bounce ekstraksiyonu da mühürden HEMEN SONRA 4/4 tamamlandı (arka-plan
bildirimiyle doğrulandı, mühür buna göre düzeltildi). Devir kaynağı
`ventures/choreia/workspace/YENI-OTURUM-PROMPT.md`.

### Kapananlar (11 vaka, C-111→C-122, hepsi push'lu)

| # | Sonuç |
|---|---|
| C-111/C-113 | `statusBases` (M-F-166) — status TEK temelden değil isimli temeller listesinden türer |
| C-114 | Keyset kapısı AİLEYE taşındı, vendor edildi, merge'lendi |
| C-115 | İlerleme yüzeyi: iki-bölüm veri katmanı + ince yapı-widget'ı, testli |
| C-116/C-117 | RM Howcast dışlaması artefakta geri kazandırıldı; bounce turu — referans kurulamadı (gerekçeli) |
| C-118 | Adım 4: uçtan-uca replay — motorun bayat dokümanı düzeltildi, fixture ikiye çıkarıldı |
| C-119 | Bounce üçüncü-yol denemesi — kaynak sayısı yetmedi (genlik değil) |
| C-120 | SessionStore v0.9.0 adopsiyonu + fallback canlılığı (AYIRT ETMİYOR, adım-kimliği yok) + pozitif-ikiz taraması |
| C-121 | Motor pini düşürüldü + kimlik enstrümantasyonu rapor-önce |
| C-122 | Vardiya kapanışı |

### En pahalı ders (bu tur — beş kez tekrarlandı)

**"Ölçü bir sayı üretiyor ama sorulan soruyu cevaplamıyor."** Beş ayrı vakada:
- diz-pencere probe'unda `max-min` fizyolojik olarak imkânsız sayı üretti (3031°/s)
- fallback testinde `errors>0 || fallback>0` her koşulda doğruydu, hiçbir şey ölçmedi
- ayrışma testinde `expect(x, isA<bool>())` — kırılamaz iddia
- pozitif-ikiz taramasında oran-vekili sorulan soruyu cevaplayamadı
- `low-amplitude-vs-family` ilk türetmesi sıralama ölçtü, genliği değil

**Panzehir hep aynıydı: ölçüyü bilinen-cevaplı bir girdiye (kontrol koşulu / bilinen-iyi referans)
koşturmak.** Beşinde de yakalayan test/ölçüm oldu, ben değil.

### AÇIK (yeni oturumun devralacağı — sıralı)

1. ~~Bounce ekstraksiyonu~~ — **4/4 TAMAMLANDI** (mühürden sonra doğrulandı). Adım atlanır.
2. **`bounce_chain.py` koştur** (prepare→classify→build→`resolvedBy` sınavı) — betik hazır,
   scratchpad'de, koşulmadı. Bu artık YENİ OTURUMUN İLK İŞİ.
3. **R13'e sonuç ekle** — `resolvedBy` ölçümü iki dürüst sondan hangisine çıktı.
4. **`ss_basic` / `FtZzjGsPxjg`** — kurucu-göz bekliyor, havuza ALINMADI (kimlik doğrulanmadan
   alınmaz). Çapa-Y gözlemi kimlik-lehine zayıf ipucu, karar kurucuda.
5. **Adım-kimliği bileşik kapı** — enstrümantasyon canlı, n=2/taraf; dağılım birikince
   bileşik eşik türetilecek (kalem-2 formülü).
6. **Çoğul-yönerge portu** — ERTELENDİ, isimli tetik: gelecek bir turda çoğul-desenin
   yakalayacağı gerçek bir kaynak `classify_source`'tan kaçarsa (ölçülmüş ıskalama) o gün gelir.
7. RR aday araması, RM 5. kaynak arama — hâlâ açık, hasat gerektirir.

---

## VARDİYA 2026-08-04 — bounce zinciri koşuldu (C-123)

**Koordinatör görevi (M-F-222 delegasyonu altında) tamamlandı:** devir promptunun
İLK İŞİ olan `bounce_chain.py` yazıldı, gotcha doğrulandı, koşuldu; sonuç R13'ün
İKİNCİ SONUÇLAR bölümüne rasyonalize edilmeden yazıldı.

### Tek cümle

`hh_bounce` **üçüncü kez** kurulmadı — ama **üçüncü kez FARKLI bir duvarda**:
C-117 gürültü tabanı · C-119 kaynak sayısı · **bugün harmonik BİRİM belirsizliği**.
**Kaynak sayısı artık engel DEĞİL** (5 ders-doğrulanmış kanal, ilk kez `MIN_TAKES`
aşıldı). Kalan tek engel bir ÖLÇÜ sorusu, ve o soru koordinatörde.

### Ölçülenler

- 7 aday → 6 hazır → **5 `lesson`** (fail-closed kapı)
- `build_reference` **harmonik çelişki** kapısında durdu: UZUN {1,27·1,37·1,70s}
  ↔ KISA {0,68·0,71s}, dört çift 1,79-2,01×
- Kapının kendi çaresi (`measure_tempo`) **ölçüldü ve kapalı çıktı**: 5 take'in
  2'sinde `no_peak`, 2'sinde `prepare_take` ile 2-3× çelişki, 1'inde uyum
- **`low-amplitude-vs-family` SINANMADI** — kapı ondan önce ateşledi; devirdeki
  iki dürüst sonun ikisi de kurulmuş artefakt varsayıyordu, ikisi de uygulanamaz

### Kayda değer karar

**Kurulabilecek alt küme (UZUN grup, n=3, çelişkisiz, üçü `lesson`) BİLEREK
KURULMADI.** Kapıdan geçen alt kümeyi seçmek = cevap veren grubu seçmek; hangi
harmoniğin gerçek çevrim olduğuna dair bağımsız kanıt yok. Tek bağımsız ipucu
(vuruş-başına çöküş ≈ 0,60-0,67s) **ters yöne**, KISA gruba bakıyor.

### KOORDİNATÖRE TAŞINAN (tek kalem)

**Diz-sürücülü segment bulucu** — adımın kendi faz tanımına (`knee_flexion_mean`
top >168°, drop ≥40°/s) dayanan bir bulucu, "bir çevrimde kaç çöküş var" sorusunu
cevaplayarak harmonik belirsizliği de doğrudan keserdi. R13 açık sorusu (a) bu
turda üç bağımsız işaretle güçlendi (çapa elemesi · 6/6 `x` ekseni · iki-kestirici
uyumsuzluğu) ama (b) çürütülmedi. **Ölçü TASARIMI = yükseltme kuralı.**

### Değişmeyenler

Çalışma ağacı temiz · 5 Python kapısı 0 · indirme YOK (hasat slotu JabLab'da) ·
`ss_basic`/`FtZzjGsPxjg` havuza ALINMADI (kurucu-göz, manuel-sona) ·
8. fixture `Ns5TaVGv6uY` provenans sınavıyla dışarıda (salsa, `hh_bounce` değil).

---

## VARDİYA 2026-08-04 (ikinci blok) — diz-sürücülü bulucu (C-124)

**Koordinatör hükmü M-F-226 icra edildi.** Ön-kayıt ölçümden ÖNCE ayrı
commit'lendi (`7bb6936`).

### Tek cümle

Bulucu **kuruldu ve doğrulandı**; birim **çözülmedi** (3/5 belirsiz → şart 7-ii
dürüst duruş) — ama belirsizliğin **adı kondu** ve asıl soru **değişti**.

### Doğrulama üçlüsü

- **(a) sentetik 15/15** — ama önce **iki gerçek hata** düşürdü: sayıcı her
  seride bir çöküş eksik sayıyordu (`_extrema` baştaki ucu kaybediyordu);
  gürültü testim yanlıştı, sınır ÖLÇÜLDÜ (±4°→0 · ±6°→13 sahte çöküş).
  Gerçek take artıkları 0,21-0,53° = güvenli bölge.
- **(b) RM genelliği** — 3/4 oran 2,00/1,94/2,11 = **doğru cevap** (RM
  dönüşümlü: çevrim = iki çöküş). Mekanizma bounce'a ayarlı değil.
- **(c) `1IVtcoqMrBA`** — one-dip, oran 1,06, topQualified 10/10.

### Verdiktler

`1IVtcoqMrBA` **one-dip** (1,06) · `nOR1qEhpssg` **one-dip** (0,90) ·
`AyzYABnWDEM` belirsiz (0,67) · `l3r4bPhikGQ` belirsiz (4,25) ·
`4BRd2E8vBic` belirsiz (segmentte **0 çöküş**).

### İki ölçülmüş sonuç

1. **(b) DESTEKLENMİYOR:** `top`>168° kapısı her take'te sağlanıyor
   (10/10 · 7/7 · 6/6 · 17/18 · 190/193) — gerçek, derin, hızlı çöküşler var.
   `tier: A`'ya karşı kanıt çıkmadı. *(Ön-kayıtlı dördüncü çıkış gerçekleşmedi.)*
2. **(a) LEHİNE keskin kanıt:** verdikt belirliliği, segmentin take geneliyle
   tutarlılığını izliyor. `4BRd2E8vBic`: tüm take'te **193 çöküş**, seçilen
   3,0s segmentte **SIFIR** — çapa, bounce dolu videoda bounce'suz pencere seçmiş.

### KOORDİNATÖRE — soru DEĞİŞTİ

Artık "birim hangisi" değil **"segment bulucu diz-sürücülü olmalı mı"**:
belirsizliğin üçü de birimden değil **pencere seçiminden** geliyor. Ayrıca n=2
ile şu ihtimal açıldı (KANITLANMADI): belirli iki take'in ikisi de one-dip ama
periyotları 1,87× farklı → 2× fark **birim değil TEMPO** olabilir, ve harmonik
kapı ikisini ayırt etmiyor.

### Değişmeyenler

`hh_bounce` AÇIK · referans kurulmadı · `low-amplitude-vs-family` hâlâ SINANMADI
(kurulan artefakt yok) · birim damgası YOK · indirme YOK · `ss_basic` havuza
alınmadı · 11/11 Python kapısı 0 · rig'e terfi YOK (üçler-kuralı).

---

## VARDİYA 2026-08-04 (üçüncü blok) — faz-sürücülü segment seçimi (C-125)

**M-F-231 icra edildi.** Zincir KOŞULMADI: şart 4 gereği (a) kabul testi düştü.

### Üçlü sonucu

- **(b) bit-değişmezlik GEÇTİ 3/3** — ama önce gerçek bir regresyon yakaladı:
  koşulsuz `"cycleUnit": null` üç shine take'inin çıktısını değiştiriyordu.
  **Yok olan alan ≠ null olan alan** (C-114'ün üretici tarafındaki hâli).
- **(c) sentetik GEÇTİ** — 11/11 kapı 0.
- **(a) `4BRd2E8vBic` kabul testi DÜŞTÜ** → zincir koşulmadı, ön-kayıt yazılmadı.

### Teşhis: darboğaz bir katman YUKARIDA

`4BRd2E8vBic` 896s, **193 nitelikli çöküş** (67-860s), ama `find_movement_windows`
**5 pencere** buluyor (~34s = videonun **%3,8'i**), dördünde 0 çöküş, birinde 1.
**Aday havuzunun kendisi bounce'ı içermiyor** — sıralama düzeltmesi kurtaramaz.

### Ama sıralama düzeltmesi ÇALIŞIYOR (kanıtlı)

`DEWpw4n8Lkw`: en yüksek periyodiklikli iki pencere (0,932 · 0,929) **0 çöküş**;
18 çöküşlü pencere 0,809. **Eski sıralama bounce'suz pencereyi seçerdi.**

### İki kazanç

1. **`DEWpw4n8Lkw` GERİ KAZANILDI** — ayak-çapası "ankle swing too small" diye
   tamamen elemişti; şimdi hazır + **`lesson` (2468 sözcük, 7 işaret)**, havuzun
   en konuşkan kaynağı.
2. **Periyotlar toplandı:** 0,400 · 0,725 · 0,760 · 1,200 · 2,034 → kalan 2×
   çatışmaların ikisi de `l3r4bPhikGQ` (0,4s) kaynaklı; diğer dördü uyumlu.
   Ve o take R13'ün ÖNCEDEN "derleme riskli" işaretlediği take.

### KOORDİNATÖRE

`find_movement_windows` diz-sürücülü adımda pencere kaçırıyor. **VENDORED**
(pin `eb28039`) → aile-düzeyi karar. App-düzeyi alternatif aday üreteci de yeni
ölçü tasarımı. `hh_bounce` AÇIK.

---

## VARDİYA 2026-08-04 (dördüncü blok) — aday üretimi rig'de (C-126)

**M-F-235 icra.** Rig dalı **`feat/isolator-kinematic-driver` @ `5054426`**
(push'lu). Zincir KOŞULMADI — şart 6 merge sonrasına bağlıyor.

### Rig üçlüsü GEÇTİ

- **(a)** `4BRd2E8vBic` **5→8 pencere, sekizinin de ≥2 çöküşü var**
- **(b)** `DEWpw4n8Lkw` 321-347s sınıfı pencere havuzda
- **(c)** pozitif-ikiz: hareketsiz 0 · NaN 0 · **gerçek salınım 1**
- **Varsayılan yol bit-değişmez 5/5** (parametreler no-op → aynı kod)

### Choreia (a) KABUL TESTİ GEÇTİ — ama iki gerileme isimli

`4BRd2E8vBic` artık **hazır** (20 çöküş, 20/20 topQ). Buna karşılık:
- **`AyzYABnWDEM`** genlik tabanında öldü (13,8° vs config 12°) — C-117'de
  zaten "std 1,7°, gürültü tabanı altında" diye işaretliydi.
- **`nOR1qEhpssg`** **kamera kapısında** öldü — koordinatörün şart 4'te
  önceden adlandırdığı olgu. **Kamera kapısı GEVŞETİLMEDİ** (M-F-200).

### Havuz

4 ders-doğrulanmış + kullanılabilir. Kalan 2× çatışmaların **üçü de
`l3r4bPhikGQ`** kaynaklı; diğer üçü birbirine 1,17× içinde. **"Kurulabilir"
demiyorum** — merge bekliyor ve `l3r4bPhikGQ`'yu uyuşmazlık gerekçesiyle atmak
C-124'te reddettiğim hamle.

### Yan bulgu

**`drift_check`'in C-114'te kayıtlı iddiası yanlışmış:** dal pininde "current
with main" diyordu (`PIN..main` sayımı ardıl pinde de 0). Artık
`merge-base --is-ancestor` ile doğrudan soruluyor, sabotajla ayırt edici.

**11/11 kapı 0. Merge kararı koordinatörde.**

---

## VARDİYA 2026-08-04 (beşinci blok) — ZİNCİR KOŞULDU, referans KURULDU (C-127)

### Tek cümle

**`hh_bounce` referansı KURULDU** ve ilk devirden beri bekleyen asıl soru
cevaplandı: **`low-amplitude-vs-family` temeli DURUYOR** (%83 vs kabul
edilmişlerde %9-28) → **`tier: A` VERİYLE desteklenmiyor.**

### `l3r4bPhikGQ` — UÇ-1, kimlik çözüldü

Transkript **belirleyici**: seçilen segment (537-549s) 504,5s'te başlayan
*"cross, cross, switch"* rutininin **içinde**; temel bounce 48-90s'te.
Çöküş şekli doğruladı (topQ **%53** vs %100 · asimetri **0,33** vs 0,10-0,16).
Çapa deseni **ayırt etmedi ve hükme katılmadı**. Dışlama uyuşmazlıktan değil,
bağımsız kimlik kanıtından türedi.

### resolvedBy sınavı

3 kaynak · `provisional` · **ortanca taban %83** · `statusBases` =
mirror-ambiguity + source-count-below-target + **low-amplitude-vs-family**.

### KRİTİK AYRIM (koordinatöre)

Bu **"bounce ölçülemiyor" demek değil**: `top` kapısı her take'te %100.
"Hareket algılanıyor mu?" **EVET**. "Eğitmen uzlaşısına karşı skorlayabilir
miyiz?" **HAYIR**. `tier: A` ikincisini iddia ediyor. **Statüyü
değiştirmedim** — dürüstlük-metriği hükmü koordinatörde.

### İki kusur düştü

1. Birim kapısı yanlış-pozitif — **suçlusu bendim** (yorumda "yalnız beyan"
   yazıp tüm sözlüğü karşılaştırdım); kapı kendi yazarını denetledi.
2. `toleranceSource` etiketi yayımlanan sayıyla çelişebiliyordu
   (`right_shin[36]`: 6,0° ama `variance`) — etiket artık yayımlanan sayıdan.

**13/13 kapı 0. Dört dışlamanın dördü de isimli+kanıtlı.**

---

## VARDİYA 2026-08-04 (altıncı blok) — hh_bounce demoOnly (C-128)

**M-F-242 HÜKÜM 1 + 3 uygulandı.** SHA `44934fc`.

### hh_bounce → demoOnly, ölçülmüş gerekçeyle

- `measurability.tier` **A → B** (`C` seçilemezdi: "tier C must never ship").
- `tierWithdrawn` kapı-isimli: `resolvedBy: low-amplitude-vs-family` +
  %83/%9-28/6,0° sayıları artefakt-atıflı + `promotionPath`.
- `reference`: 0→**3** kaynak, provisional, **`notConsumedForScoring`** —
  artefakt yaşar, hiçbir şey ona karşı puanlamaz.
- Ders: `demoOnly` + `structural-circular` + isimli/veri-tetikli
  `promotionPath` (≥6 kaynakta ayrışma taban üstüne çıkarsa tier açılır).

### honesty bloğu: eski satır artık YANLIŞTI

*"no teachers measured yet (collectedTakes == 0)"* → ölçülmüş gerekçe.
`measuredNote`: **"kurulmuş referans, puanlanabilir referans demek DEĞİLDİR"**.
`tierA_confirmed` kaydı silinmedi, etiketlendi (öngörü ↔ hüküm yan yana).

### drift_check v2 (HÜKÜM 3)

Yaş uyarısı **içerik-duyarlı**: yalnız vendored yol değiştiyse yanar.
Sabotaj ikizi: `dde99bd`/değişmedi → susuyor · `eb28039`/DEĞİŞTİ → yanıyor.
Pin `6fd718f`'e bump.

### Doğrulama

`validate_content` 0 · `validate_reference` 0 · **58 Flutter + 16 engine** ·
analyze temiz.

### SIRADAKİ (HÜKÜM 2)

K10 içerik genişletmesi: `hip_hop_foundations` + `salsa_shines`
"skorlanmaz-ama-öğretilir" kurs iskeletleri (referans beklemeyen dersler).
Bounce hasadı DÜŞÜK ÖNCELİK, slot ayrılmadı.

---

## VARDİYA 2026-08-04 (yedinci blok) — K10 genişletmesi (C-129)

**M-F-245 uygulandı.** SHA `836e21c`.

### demoOnlyClass ikiz kapıları ("VARSAYILAN YOK")

- `structural-circular` ⇒ `promotionPath` ZORUNLU
- **`permanent` ⇒ `whyPermanent` ZORUNLU VE `promotionPath` YASAK**

İkinci kapı ters yönlü: permanent'a yol yazmak **eksiklik değil ÇELİŞKİ**.
Sabotaj **5/5** ateşledi, geri alınca sustu. Mevcut dört permanent dersin
hiçbirinde `whyPermanent` yoktu — dördü de yazıldı.

### Yol üstünde: 13 KIRIK ATIF

`relatedDrill` hedeflerinin **hepsi** boştaydı — hata taksonomisi 7
alıştırmaya yönlendiriyor, hiçbirinin dersi yok, `validate_content` hiç
denetlemiyordu. **İçerikte ölü-buton sınıfı.** Kapı eklendi + sabotajla
sınandı (kaldır → 9 hata, geri koy → sessiz).

### 7 alıştırma, hiçbiri uydurulmadı

Hepsi config'lerin `relatedDrill` alanında zaten isimliydi; metinler
hataların kendi notlarından. `demoOnly` + `permanent` + `drillFor`.
Gerekçe sahte kamera argümanı değil: **alıştırma bir düzeltmedir,
performans değil** — yavaşlatılmış versiyonun eğitmen uzlaşısı olamaz.

`hh_rock` **locked kaldı** (C-096). Yeni seviyeler `unlockRule: null` +
gerekçe (puanlanmayan derste kilit kuralı olamaz, M-F-04).

### Doğrulama

Kurs yapısı: hip-hop **L1 4 + L2 2** · salsa **L1 4 + L2 5**.
Tüm Python kapıları 0 · **58 Flutter + 16 engine** · analyze temiz.

---

## VARDİYA 2026-08-04 (sekizinci blok) — Paket A + B (C-130, C-131)

### A) SessionStore 0.10.0 — `7d6dd9c`

Pin 0.9.0→0.10.0. **Adopsiyonun asıl işi pin değil OKUMAKTI:** bump sonrası
analyze temizdi (çekirdeğin store'u zorunlu üyeyi karşılıyor), yüzey ise
`unreadableRecords()`'a bakmıyordu — "yazılmış ama OKUNMAMIŞ alan" sınıfı.

`HistoryIntegrity`: `ok` / `partial(n)` (totals TABAN) / `unavailable`
(totals **YOK** — `totals` nullable yapıldı, sıfır render edilemesin).
"Hiç okunamadı" ucu ayrı cümle. 7 yeni test, hepsi ikizli + e2e kanıtı.

İki kusur testlerle yakalandı: **Dart interpolasyonu kırıktı** (kullanıcıya
ham `$unreadable` gidecekti) · doküman bloğu yanlış sınıfa yapışmıştı.

### B) rock/groove — `327f849`

**Envanterdeki "described" iddiası dayanaksız çıktı:** R7'nin 17 adımında
ikisi de yok, R1 bir kez kurs-temeli olarak anıyor.

**`hh_rock` YAZILDI**, kaynak havuzdan (`4BRd2E8vBic`, JoeyTheJAM). Ayırt
edici cümle 480,4s: rock gövdeden sürülür, **dizler dengeler** — bounce'ın
tersi. `cycleUnit: trunk_tilt`, `predictionOnly: true`, tier **B**,
**ders locked KALDI** (tanım yazmak ölçmek değildir).

**`hh_groove` YAZILMADI** — envanter, stilin kendi honesty bloğuyla
çelişiyor ve honesty haklı (kamera groove'u göremez; ders zaten
`permanent`). Kayıt silinmedi, çelişki notuyla etiketlendi.

**Çivi testi tasarlandığı gibi kırıldı**, yeniden nişanlandı ve güçlendi:
eksik belge artık test içinde üretiliyor + pozitif ikiz.

**65 Flutter + 16 engine · analyze temiz · tüm Python kapıları 0.**

---

## VARDİYA 2026-08-04 (kapanış) — mezar-taşı + BEKLEME-DURUMU (C-132)

`hh_groove` envanter satırı kaldırıldı, tarihli mezar-taşıyla (`b3c5954`).
**Ürün yüzeyi değişmedi** — ders zaten `demoOnly`/`permanent` yayınlanıyordu;
değişen, kataloğun aksini iddia etmeyi bırakması. `tierA_confirmed` artık
`hh_bounce` + `hh_rock`.

### VARDİYA HEDEFLERİ KAPANDI

bounce dosyası (referans KURULDU, `low-amplitude` temeli DURUYOR, tier A
GERİ ÇEKİLDİ) · demoOnly yüzeyi · K10 genişletmesi (7 alıştırma + ikiz
kapılar + 13 kırık atıf) · rock yazıldı / groove mezar-taşlandı ·
SessionStore 0.10.0 · drift_check v2.

### BEKLEME-DURUMU — isimli tetikler

1. **`ss_basic` / `FtZzjGsPxjg` kurucu-göz** gerçekleşirse → kimlik kararı
   bende başlar (havuza kimliksiz ALINMAZ, kural aynen).
2. **Hasat slotu yeniden önceliklenirse** → bounce (3/6 kaynak,
   `mirror-ambiguity`) + rock (0 kaynak) referans turu.
3. **Çoğul-yönerge portu** → ölçülmüş ıskalama tetiği (varsayım değil).
4. Koordinatörden yeni paket.

**Açık kırmızı kapı YOK · bekleyen merge YOK · ağaç temiz · senkron.**

---

## VARDİYA 2026-08-05 — kamera canlı yolu KISIM 1 (C-133)

**SHA `90c3f59`** · 74 Flutter + 16 engine · analyze temiz · Python kapıları 0.

### Yapıldı

- **Pin çifti** `motion_core` 0.11.0 + `motion_camera` 0.1.2, tek ref
  `f13bdc9`; eşitlik testi + sabotaj kanıtı. Motor pininin isimli geri-giriş
  tetiği ateşledi (C-121).
- **Pub tuzağı ölçüldü:** eşitlik aynı commit değil **aynı DİZE** meselesi;
  kısa SHA çözümü reddettiriyor.
- **Canlı yol:** `LiveSession` (Stream<PoseFrame> alır, kamera açmaz) +
  `CameraPoseSource` (CameraException → tipli hâl).
- **Beat kapısı config'ten türetiliyor** + ikinci gerekçe (ClockDomain).
- **demoOnly TİP düzeyinde korunuyor** (`LiveMeasured`'da band alanı yok).
- 7 canlı-yol testi, hepsi ikizli.

### YAPILMADI — kısım 2 (dürüst kayıt)

`ios/`+`android/` iskeletleri · iOS sim + Android debug **derlemeleri** ·
simülatör **ekran kanıtı** · canlı ders **EKRANI** (veri katmanı var, widget
yok) · Obsidian devir notu · YENI-OTURUM-PROMPT · **merge**.

Sebep: bütçe. Kısım 1 tam ve mühürlü; kısım 2 hiç başlanmadı — yarım
bırakılmış bir şey YOK.

---

## VARDİYA 2026-08-05 (kısım 2) — kamera entegrasyonu KAPANDI (C-134)

**SHA `b9e448e`** · 80 Flutter + 16 engine · analyze temiz · kapılar 0.

- **C-112 kararı İSİMLE devrildi**: platform iskeletleri kuruldu (plugin
  yerel kod taşıyor).
- **Gravita'nın üç iOS duvarı önden kapatıldı** (target 14 · statik linkage ·
  LANG) — çarpmayı beklemedim.
- **Canlı ekran:** yedi hâl, derleyici zorunlu. JabLab'ın üç deseni uygulandı
  (çıkmaz-sokak yok · izin iki hâlli · "hiç başlamadı ≠ sıfır").
- **Derlemeler: iOS sim 22,1s · Android debug 25,4s.**
- **Ekran kanıtı:** gerçek `LivePermissionDenied`; kapılı kontroller kullanıcı
  dilinde, `beatsStatus` sızmamış, kimlik sınırı ekranda.

### Dürüst eksik

"Try again" sonrası **kalıcı-ret hâline geçiş simülatörde teyit edilmedi**
(dokunuş mu mantık mı ayırt edilmedi). Widget testinde kanıtlı; sim'de değil.

### SIRADAKİ

**Design turu** — `docs/design/UI-BRIEF.md`. Ekran YAPI'dır, görünüm design'a
aittir.

---

## VARDİYA 2026-08-06 — GİYDİRME TURU, aile İLK'i (C-135)

**Tek cümle:** `LiveView` + `ProgressView` claude.ai/design'ın `Choreia.dc.html`
yanıtına göre restyled — yedi hâl, tüm Key'ler, tüm `LiveStrings`/`ProgressStrings`
değerleri, `demoOnly`/blocked-gate/two-section honesty kuralları birebir korundu;
**Library/Style/Flow inşasına GEÇİLMEDİ** (koordinatör hükmü: giydirme ≠ inşa,
kalan dört hattın brief'i bu turun çatışma-bulgularını bekliyor).

### Yapılanlar

- **`lib/app/theme.dart`** (yeni): palet (stage `#0A0508` · oxblood · rose=hüküm
  · amber=açık-puansız — iki ton bir elemanda KARIŞMAZ) · üç yazı ailesi
  (Instrument Serif/Manrope/IBM Plex Mono via `google_fonts` — Motion ailesinde
  emsal yoktu, LifeOS+Burun Farkı'nda vardı, o yolu izledim) · `GlassPanel`
  (blur ≤3px, JabLab'ın buzlu-camıyla karışmama şartı §1) · `SlowBreath`/
  `SlowSpin`/`ChoreiaBackdrop` (akan/döngüsel hareket, snap/bounce/shake YASAK).
- **`LiveView`**: 7 hâl tek tek restyled — izin (iki bayrak aynı buton/key,
  farklı etiket) · kamera-arızası · kişi-yok (tasarımın frame/light/conf
  desenine en yakın eşleme — **light'ın motor karşılığı yok, uydurulmadı**) ·
  watching (nefes alan büyük sayaç + döngüsel halka) · measured (mono ölçüm
  dili) · judged (bulgular artık KENDİ `verdict` alanına göre renkli — fired=
  rose/ok=nötr/noVerdict=amber; önceki kod bu alanı okuyup hiç kullanmıyordu).
- **`ProgressView`**: üç bölüm (Recorded/Evaluated/Blocked) hep-bağlı kaldı —
  tasarımın 2-tab'ı **BİLEREK** alınmadı (testlerin bir kısmı tek pump'ta
  "bu bölümde var, şu bölümde yok" iddiası yapıyor; tab mount/unmount aynı
  sonucu farklı bir iddiayla üretirdi — isimli, dosyanın kendi doc-comment'inde).
- **15 maddelik uyum listesi tarandı** (koordinatörün verdiği liste, tam
  metin): 13/15 net uyumlu. 2 isimli çözüm — düşük-ışık hâli (yapı kazandı,
  koordinatör onayladı) · Attempt Summary ayrı ekran mı (UI-BRIEF §3.8 öyle
  sayıyor, bu turda inline kaldı, ürün-kararı koordinatörde).

### 🎓 Bulunan gerçek arıza — aile dersi olarak dağıtıldı

`progress_test.dart`'ın real-content testi `RenderFlex` taştı: gerçek
demoOnly-gerekçe metni synthetic fixture'dan uzundu, `Row`'da `Expanded`
yoktu. **"Testler yeşil ≠ kullanıcı doğru şeyi görüyor" sınıfının giydirme-turu
hâli** — aynı sınıftan üç savunmasız `Row` daha (progress section başlıkları +
live ölçüm satırı) taranıp düzeltildi (tuzak-düzeltmesi DESENE yazıldı).
Koordinatör bunu kalan üç hatta hemen dağıttı.

### 📌 Placeholder mekanizması — aile standardı oldu

Koordinatör direktifi (üç hatta birden): `// PLACEHOLDER(kategori): eksik —
unblocked by: ne bekliyor` + `tools/generate_placeholder_register.py`
(`docs/design/PLACEHOLDER-REGISTER.md`'yi ÜRETİYOR — elle liste YASAK; kayıtta
`unblocked by` yoksa script exit 1 ile FAIL eder, kaydın kendisi kapı oldu).
Bu turda **1 kayıt**: `live_view.dart` — `LiveWatching`'in planlı-çevrim
toplamı yok, tasarımın "cycle 3 of 8"i bu yüzden hiç render edilmedi (sahte
sayı değil, gösterilmeme).

### `docs/design/DESIGN-AHEAD-OF-CODE.md` — sonraki turun kapsam belgesi

Koordinatör talebiyle yazıldı (design MCP'den yüklüyken çıkarmak ucuz, sonra
pahalı). **12 kalem:** navigasyon kabuğu (hiç yok) · Library (34 stil, 32'si
content'te hiç yok, tasarımın kendi mock verisi) · Stil sayfası (atıf/glossary
content'te var mı DOĞRULANMADI) · Ders-sınıfları ekranı (veri modeli tam,
widget yok) · Ders akışı 4-adım (3.adım kapalı — **koordinatörün isimle
istediği kalem**; 1.adımın "sayımlı öğretmen figürü" mekanizması belirsiz) ·
ayna-modu+öğretmen-figürü asset'i · Attempt Summary ayrı ekran mı (§yukarı) ·
Müzik seçici (politika var, ekran yok) · Kalibrasyon adımı · kayıt-hata hâli
(SessionStore hiç bağlı değil) · Progress tab-vs-bölüm (stil notu, gerçek
kalem değil) · düşük-ışık hâli (§yukarı). **Ek:** UI-BRIEF §3.1(Onboarding)/
§3.2(Home) design panelinin v1 çıktısında hiç yok — brief-vs-design farkı,
kod-vs-design farkından ayrı bir bulgu.

### Doğrulama

`flutter analyze` temiz · **80 Flutter + 16 engine** · Python `validate_content`/
`validate_reference` 2 kapı 0 (içerik dokunulmadı) · **iOS sim + Android APK
derlemeleri GEÇTİ** — ikisi de İLK denemede iCloud G/Ç zaman aşımına çarptı
(`errno=60`, `FileSystemException`; `analysis_options.yaml` okumasında da
görülen aynı sınıf — makine/senkron kaynaklı, kod-kaynaklı DEĞİL), retry ile
geçti · ekran kanıtı `docs/evidence/live-permission-denied-ios-sim-giydirme.png`.

### AÇIK — isimli, sonraki tur

**Library/Style/Flow inşası + navigasyon kabuğu.** Koordinatör hükmü: giydirme
turu ile inşa turu KARIŞTIRILMAZ (arıza kaynağı ayrışması bozulur) + bu turun
çatışma-bulguları kalan dört hatta ŞİMDİ lazım. Kapsam belgesi hazır
(`DESIGN-AHEAD-OF-CODE.md`), karar koordinatörde.

---

## DÜZELTME — koordinatör hükmü, aynı gün (C-136)

Yukarıdaki raporun bir kalemi **yanlış sınıflandırılmıştı**: "deneme özeti
tek-düzeltme" maddesi "belirsiz (ekran yok)" değil, **P1 önceden-var-olan
isimli açık bulgu** — kural (skor + TEK düzeltme) `LiveJudged`'a bugün
uygulanıyor ve uygulanmıyor, ayrı ekran olmasından bağımsız. **Tek iş, üç
adım:** öncelik sırası türet (icat etme) → tek-düzeltme uygula → ancak o
zaman ayrı ekrana çıkar. Ayrıca izin kalıcı-ret ölçümünün "doğrulandı"
denerek yanlışlıkla daraltılmaması gerekiyordu — kayıt **"hâlâ ayırt
edilmedi"** olarak duruyor. Progress'in tab yerine hep-bağlı üç bölüm seçimi
ise RATİFİYE edildi (düzeltme değil, onay). Tam gerekçe: DEFTER C-136 +
`docs/design/DESIGN-AHEAD-OF-CODE.md` §7/§11.

---

# 2026-08-07 gece vardiyası — İNŞA TURU: uygulama gezilebilir oldu

**SHA zinciri:** `68dfe31` → `f0fd36e` → `d6b72d3` → `5be282e` (main, 0/0, temiz)
**Kapılar:** `flutter analyze` temiz · **116 Flutter** (80'den) · **16 engine** · hepsi yeşil
**Ekran kanıtı:** `docs/evidence/library-ios-sim.png` · `style-salsa-ios-sim.png`

## Ne yapıldı
Navigasyon kabuğu (2 sekme: STYLES/PROGRESS) → Library (34 stil) → stil sayfası
→ ders kartları. `LiveView`/`ProgressView` KIRILMADI; `LiveLessonPage` `main.dart`'tan
davranışı değişmeden çıkarıldı. `ProgressView` ilk kez erişilebilir.
34 stilin köken/atıf metni yazıldı.

## Ne ölçüldü (üçü de belgeyi/beyanı çürüttü)
1. **`content/library.json` VAR** — `DESIGN-AHEAD-OF-CODE.md` iki yerde yok diyor.
   34 stil, tam metadata. §2'nin açık ürün sorusu kendiliğinden kapandı (C-137).
2. **Açılabilir SKORLU stil = 0** — salsa hem `live` hem `gatedByRelease`.
   Tasarımın "1 scored" paneli içerik sayımı; yüzeyde tekrarlamak C-101 vekil
   kusuru olurdu. Dördüncü rozet doğdu: `builtButGated` (C-138).
3. **Başlatılabilir ders = 0** — 15 dersin 4'ü step adlandırıyor, birinin referansı
   sunuluyor, o da kapalı stilde. `LiveLessonPage._start` referansı hatasız
   yüklüyor → saf "Başla" düğmesi = düğme arkasında ÇÖKME (C-139).

## Açık kalanlar (hepsi koordinatör hükmü bekliyor)
- **C-143:** `hh_bounce.json` diskte 74 KB, pubspec'te beyansız. `mirrorConfident:false`
  taşıdığı için kasıtlı olabilir → demo-only derse sevk edilir mi?
- **C-145:** yayınlanan metinde "Not open **yet**" — M-F-186 "yet"i isimle yasaklıyor.
  Yasak sözcüğe mi, gerekçesiz vaat kalıbına mı? (7 kullanım yeri)
- **C-140:** izin kalıcı-ret düğmesi eylemsiz (`permission_handler` bağımlılık kararı)
- **C-146:** stil sayfasına DOKUNARAK gidilmedi (simülatör dokunma yolu yok)
- **IA:** sekme çubuğu seçildi ve `_destinations`'a izole edildi — onay/ret kolay
- **İçerik:** adım sözlüğü 34 stilde YOK; C-136 üçlüsü (öncelik sırası → tek-düzeltme
  → ayrı ekran) bu turda AÇILMADI

## Aile-geneli tuzaklar (desene yazıldı, dosyaya değil)
- **C-142 (P0):** `testWidgets` içinde **≥50 KB varlık** = kalıcı kilit (`compute()`
  gerçek isolate, sahte saat ilerletmiyor). Panzehir: `setUpAll`. Cihaz etkilenmiyor.
  **Eşik veri boyutunda — fixture aylarca geçer, içerik büyüdüğü gün kilitlenir.**
- **C-141:** `scrollUntilVisible`/`pumpAndSettle`, sonsuz `..repeat()` ambiyans
  animasyonuyla ASLA dönmez → sınırlı manuel `drag` + düz `pump()`.
- **C-143 ikinci yarısı:** pubspec dizin girdisi **özyinelemeli DEĞİL**; `startsWith`
  önek kontrolü yazınca yeni kapı hiçbir şey ölçmeden yeşil geçti (aile dersi 4).

---

# 🔒 OTURUM MÜHRÜ — 2026-08-12

**`HEAD` = `c54c957`** · `HEAD == @{u}` ✅ · ağaç **temiz** · **42 commit** (bugün)
**Kapılar:** 19 koşucu, **hepsi yeşil** · flutter **237** + engine **36** = **273 test**
**DEFTER:** **247 kayıt**, bunun **48'i bu oturumdan** (`C-218`…`C-265`, **numara
boşluğu YOK**) · kapanış-otoritesi gediği **0** (15 kapanış iddiasının 15'i kendi
durum sütununda da kapalı)

## Bir cümlede: ne kapandı, ne kapanmadı, ve kapanmayanın sebebi ölçüldü mü?

**Kapandı:** onboarding ölçüldü ve gerçek gedik izin dalında bulunup `C-140`
gerçek `openAppSettings` çağrısıyla kapatıldı · model damgası uçtan uca geri
geldi · `hh_bounce` **4 kaynağa** çıktı · gezilebilirlik sözleşmesi metne karşı
**5/5** · üç kapanış-otoritesi ayrışması düzeltildi (taşınan **3 → 0**) ·
`4BRd2E8vBic` **geri dönüş adresiyle** kapandı.
**Kapanmadı:** `sh_running_man` referansı · üç A′ stilinin açılabilirliği ·
`ss_shine_footwork` ve `cc_cucaracha` tabanı · BPM ızgarası.
**Ve kapanmayanların HEPSİNİN sebebi ölçüldü** — hiçbiri *"denendi olmadı"*
değil; her biri **sayıyla** aşağıda.

## Açık kalemler — ÜÇ KOVA, her biri NEREDE + SIRADAKİ ADIM

### ⓐ HAT-YERELİNDE yapılabilir (izin var, ölçüm yeter)

| kalem | NEREDE durduğu (ölçülmüş) | SIRADAKİ ADIM |
|---|---|---|
| **`sh_running_man` referansı** | 5 kaynak indi · hazırlama **3/5** · `HUOjOJvPJc8` **H1 ile düştü** (kanal 3,305 ↔ çöküş-türevi 3,336, %0,9) ⇒ **2 take** · M-C-04 (≥3) tutmuyor. **Tempo engel DEĞİL:** kalan ikisi **1,458×** ayrışıyor, sevk edilen külliyatın en genişi **1,496×** | **Üçüncü take hasat et.** Hedef **ölçülmüş**: periyodu **1,20–1,75 s** civarında olsun. Elde bekleyen: `6m23DNL5idw` (**403 — araç arızası, malzeme hiç denenmedi**), ve süre üst sınırından düşen `b6075roLFmo` (1702s) · `CKWGXKj900Y` (1993s) |
| **`7g9PH1Qa4LM` kanal ayrışması** | çöküş-türevi **1,20** ↔ bağımsız kanal **3,240** = **%170**. acf **0,183** (en zayıf tepe) — ama bu **sınıflandırmada KULLANILMADI**, çünkü eşik ön kayıtta yoktu | Segment/pencere duyarlılığı `HUOjOJvPJc8`de **kanıtlandı** (8,88s sustu → 15,56s uyandı). **Aynı ön-kayıtlı yöntemle** bu take için de bir ölçüt yaz (**sonucu görmeden**) ve tekrarla |
| **`dancehall` · `samba_no_pe` aday havuzu** | aday listesi **0** (ölçüldü, C-219 doğrulandı; `dance` alt-dizgesi sayacı **42**'ye şişirmişti, düzeltildi) | Arama turu — bu turda **açılmadı** (⛔ *bir turda bir kalem*) |
| **`style.json` kablolaması** *(YETKİ VAR, referansa bağlı)* | Üç A′ stilinin (`shuffle` · `dancehall` · `samba_no_pe`) **hiçbirinde `style.json` yok** ⇒ bir hasat turu referans gediğini kapatır ama stili **AÇILABİLİR yapmaz**. Koordinatör **yetki verdi** (2026-08-12) — ama **yalnız referansı İNMİŞ stil için**; kısıtın gerekçesi standardın kendi cümlesi: ***"sahte/boş kurs asla listelenmez"***. Referans inmediği için **bu turda yapılmadı, ve kısıt işini gördü** | **Referans indiği gün, aynı turda yaz.** ⛔ Öncesinde **DEĞİL** — boş bir açılabilir stil yaratır. 📌 Ve taksonomiye not: bu üç kalem `A′`dan **`B`'ye** (*içerik var, bağlı değil*) o gün geçer; `B` bugün **0** ölçülmüştü |

### ⓑ KOORDİNATÖRDE bekleyen (ölçü/kapı/eşik tasarımı)

| kalem | NEREDE durduğu | ne bekliyor |
|---|---|---|
| **Süre üst sınırı `MAX_SECONDS = 900`** | **Ölçüldü ve çürütüldü:** sevk edilen `hh_bounce`ın kaynağı **1443,7 s** (`DEWpw4n8Lkw`), sınırın **1,6 katı** ⇒ vekil amaçtan ayrışmış, **kalem AÇIK** | Eşik kararı. ⚠️ Ve *"fazla filtreliyor"* **1702s/1993s'i aklamaz** — ikisi de en yüksek öncülün (1443,7s) üstünde |
| **`sh_t_step` açılabilirliği** | İki ön koşul birden düşük: `thigh_rotation` sözlükte `family`/`jointRef` **taşımıyor**, `valueDeg` **null** | Metrik sözlüğü kararı |
| **`sh_running_man.beats: 2`** | **Doğrulanmadı** — `shuffle`ın `style.json`u yok, karşılaştırılacak `bpmRange` de yok. ⚠️ `dipsPerCycle` bundan **bağımsız** ve **2/3 take'te doğrulandı** | `style.json` (⇒ ⓐ'ya döner, ama **yalnız referans indikten sonra**) |
| **`7g9PH1Qa4LM` acf zayıflığı** | acf **0,183** ölçüldü, **kullanılmadı** | Bir acf eşiği istenirse: **başka bir turda, aday görmeden** |

### ⓒ KURUCUDA bekleyen

| kalem | NEREDE durduğu | ne bekliyor |
|---|---|---|
| **`A = 29` içerik kalemi** | koordinatörde tutuluyor, hat-yerelinde iş yok | kurucu |
| **`D = 1`: BPM müzik ızgarası** | **C-032 ölçtü:** hareket-üzerinden BPM **çıkmaz sokak** (adım↔vuruş **3:4**, temiz tamsayı çarpan yok). `ss_shine_footwork.beats` **null**, ve `countLabels:["a","b"]` **sayım değil FAZ** etiketi (`settle_a`/`transfer_ab`/`settle_b`) | `beat_annotate` ile **canlı tap** — kalem **küçülmedi** (kendi karşıt iddiamı geri aldım) |
| **`salsa_shines` adlandırma** · **`garba` + `twerk_reggaeton` kültürel inceleme** | `culturalReviewLedger: open` | kurucu |

## Bugün açık bırakılan ÖLÇÜLEMEZLER (üçü de dürüst sınıf, başarısızlık değil)

- **`4BRd2E8vBic` → `ÖLÇÜLEMEDİ`**, ve **geri dönüş adresi sayıyla yazılı**:
  `trunk_tilt` taban payı **%100** (tolerans min=max=6,00°), `right_hip` **%95**,
  ölçüm taşıyan tek eklem `left_hip`; dört take'in tüm yayılımı **0,34°**,
  tabanın **~18 katı altında**. 4. kaynak inince taban payı **%59 → %30** düşmüştü
  ⇒ bant taban-baskın olmaktan çıkınca **soru yeniden sorulabilir**.
- **`ss_shine_footwork` · `cc_cucaracha`** — taban-altı.
- **`7g9PH1Qa4LM` kimlik okuması → `ÖLÇÜLEMEDİ`** (own 0 · conf 0 · 232 söz).
  ⚠️ Ve sınıfı **ölçüm parametresi** belirliyor, kayda geçti:
  `own=[shuffl,melbourne]` → `ÖLÇÜLEMEDİ`; `own=[shuffl]` → `KANIT_YOK`.
  Koordinatör hükmü: `melbourne` **`own`da kalır** (ölçüt **üyelik**, kırılganlık
  değil), ve `ÖLÇÜLEMEDİ` **dürüst sınıftır**.

## Bu oturumda kurulan kapılar (dördü de kendi öz-testiyle)

`identity_read` (8 kontrol) · `closedPaths` şema kapısı · `closure_authority`
(5 kontrol) · `validate_content` şema genişlemesi. **Hepsi `gates.sh`e bağlı**,
ve her biri **sabotajla ötebildiği ayrı ayrı ölçülerek** kabul edildi.

---

# 🔒 A6 KAPANDI — iki yönlü defter tazelik kapısı (2026-08-13)

**`HEAD` = `28826f9`** · `HEAD == @{u}` ✅ · ağaç **temiz** · **22 koşucu** (20→22),
hepsi yeşil · **237 flutter + 36 engine = 273 test** · analyze temiz
**DEFTER:** `C-267` + **18 mezar taşı** (248 → **267 kayıt**)

## Durma koşulu (C) — bu turun cevabı

> *"Bu tur, A tablosundaki hangi kalemi `⛔` → `✅` yaptı?"*

**`A6`.** ⇒ sayaç sıfırlandı. **Kalan ⛔: `A1` · `A12`** (`A10` → koordinatör
hükmüyle **B8**'e taşındı, artık hattın kalemi değil).
**Mesafe: ✅8 · ⛔2 · bilinmiyor 0.**

## Ne kuruldu — ve niye `closure_authority` değildi

A6'nın ön-girdisi `✅` yazılmıştı; ölçüm çürüttü. `closure_authority` **kapanış
otoritesine** bakar — *defter bir hafta bayat olsa da yeşil kalır*. A6 **sınıra**
bakar. ⇒ ***aynı kelime, iki katmanda iki birim.***

Ölçüt **koddan önce** mühürlendi: `app/docs/research/R25-defter-tazelik-olcutu.md`
(iki yönün tanımı · taban çizgisi · uçuşta-kayıt kuralı · 8 sabotaj senaryosu).

## 🔴 Kapı doğduğu anda 18 GERÇEK kayıp buldu

`C-183…C-194` · `C-197…C-201` · `C-204` commit mesajlarında **anılıyor**,
defterde **satırları yoktu** (`C-183`/`C-190` ham metinde **0 kez**).
**Kurtarma arandı, YOK:** üç workspace yedeğinin (08-07 · 08-11 · 08-12)
hiçbirinde satır yok.

**🪤 Ve kayıp ARALIKLI:** 18/18'i **tek gün** (2026-08-07 gece vardiyası), ve aynı
gecede `C-195/196` ile `C-202/203` **yazılmış** ⇒ **çökme/kesilme DEĞİL, kayıt
başına sessiz atlama** — tam da bir kapının yakalayıp insanın yakalayamadığı biçim.

**Çare: mezar taşı, yeniden inşa DEĞİL.** İçerik uydurulmadı; satır yalnız köken
taşır. ⛔ Commit **konusu** da alıntılanmadı: bir konu başka bir kaydın kapanışını
ilan ediyor, alıntılansa deftere **yeni bir kapanış iddiası enjekte ederdi.**

## İki yön aynı cezayı almadı — çünkü aynı kusur değil

| yön | ne | ceza |
|---|---|---|
| **① iş→kayıt** | kayıt **hiç yok** = **BİLGİ kaybı** | muafiyetsiz, **tüm geçmiş** |
| **② kayıt→iş** | kayıt var, atıf yok = **BAĞ kaybı** (commit `R24` anmış, `C-265` değil) | taban `C-266`; öncesi **92 kalem her koşumda sayılır** |

> ***BİR KAYDIN HİÇ YAZILMAMASI İLE ANILMAMASI AYNI KUSUR DEĞİLDİR.***
> Tek eşiğe bağlansa kapı **110 kalemle kalıcı kırmızı** yanardı — *ve kapatılmış
> kapı hiç olmayandan kötüdür.*

**Uçuştaki kayıt:** ağaç **temizse gedik TAM 0**; kirliyse **en fazla 1**, **ve en
büyük kimlik**. ⚠️ Mühür anı hep temiz ağaçtır ⇒ **her mühürde gedik 0 zorunlu.**

## Sabotaj — gerçek depoda BEŞ ölçüm, iki yön ayrı ayrı

① yön① `C-190` kaldırıldı → **exit 1, kimliğiyle** · ② yön② kirli+iki kayıt →
**exit 1** (tolerans 1) · ③ **pozitif ikiz** tek kayıt+en büyük+kirli → **yeşil**
· ④ **yön② temiz-ağaç** (en keskin) → **exit 1, kimliğiyle** · ⑤ her geri alma
**md5 birebir aynı**. Öz-test **9/9**, **2'si pozitif kontrol** — *ikincisi olmasa
kapı bir denetim değil bir **yasak** olurdu.*

## Ölçmediklerim, adıyla

1. **mtime'a bakılmıyor** — defter git-dışı, `touch` tazeliği taklit ederdi ⇒ kapı
   **içerik** ölçer, zaman değil (ve ölçmediğini böyle söylüyor).
2. Bir kaydın **DOĞRULUĞU** ölçülmüyor — yalnız **varlığı** ve **bağı**.
3. **18 turun gerekçesi kalıcı olarak KAYIP** — satır bunu **söyleyerek** duruyor.
4. 🔴 **Aile sorusu, hattın dışında:** *aynısından kaç tane daha var?* Bu sınıf
   (commit kimlik anıyor, defterde satır yok) **beş hatta da taranmadı** —
   koordinatöre.

---

# 🔒 A1 KAPANDI — canlı yolun TERMİNALİ (2026-08-13, mühür `0f0db2a`)

**Mühür:** `0f0db2a` · 209 commit · ağaç temiz · push-bekleyen 0 ·
`tool/gates.sh` **exit 0, 22 koşucu, borusuz** · **255 flutter + 36 engine**.
Beş commit: `15e5382` `06bd910` `282a165` `3245c46` `0f0db2a` — DEFTER
`C-268`…`C-272`.

## Durma koşulu (C) — bu turun cevabı

> *"Bu tur, A tablosundaki hangi kalemi `⛔` → `✅` yaptı?"*

**`A1`** (şerhli — aşağıda). Sayaç sıfırlandı.
Kalan tek `⛔`: **`A12`**, ve o profile bağlı — kurucuda.

## Teşhis devir notundan BİR KATMAN derindi

Devir §3 *"önce YAZMA, sonra YÜZEY"* diyordu: `SessionStore`a hiçbir yazma
yoktu. Ölçüm bunu bir katman derine indirdi: **eksik olan yazma değil,
oturumu BİTİREN kontroldü.** Canlı ekranın tek çıkışı AppBar geri okuydu ve o
her şeyi atıyordu ⇒ yazılacak bir şey hiç **oluşmuyordu**, `ProgressView` de
bu yüzden `notRecorded`a çivilenmişti. Zincir eksik değildi — **ucu yoktu.**

## Ne kuruldu

`session_store_access` (depo konumu, `FirstRunFlag` deseni) ·
`session_tally` (oturumun NE İDDİA EDEBİLECEĞİ, saf) ·
`session_result_view` (`sealed`, üç dal) ·
`live_environment` (cihaz-özel **beş** dikiş TEK nesnede — üç ayrı alan
olsaydı iki aracı widget altı alan taşırdı ve dördüncü dikiş geldiği gün
iletmeyi unutan widget **sessizce** cihaz varsayılanına düşerdi) ·
`first_walk_test` (yürüyüş + iki izole sabotaj) · `session_tally_test` ·
`excluded_style_test`.

## Bu turda BENİM açtığım iki kusur — ikisini de başkası buldu

1. **Ölü-son:** depoyu bağlayınca, CEVAPSIZ kalan bir depo ilerleme sekmesini
   sonsuza kadar bekletiyordu. `catch` göremez — **askıda kalmak bir istisna
   değildir.** Bulan: **mevcut A7 kapısı.**
2. **`lessonId` yerine `stepId`:** kayıt DERSİ değil ADIMI taşıyordu ⇒
   ilerleme ekranında satır ham kimlikle görünürdü (*dolu görünen, hiçbir şey
   adlandırmayan satır*). Bulan: **bir rota adının uyuşmazlığı**, bir assert
   değil.

> ### ***TEŞHİS BAĞIŞIKLIK DEĞİLDİR.***
> Aynı turda `LiveView`de ölü-son yasağını uygulayan kişi, üç ekran ötede bir
> tane açtı.

## GERÇEĞİ DENEDİM — ve yüzey bir yalan söylüyordu

Simülatörde elle yürüdüm. Progress → *Evaluated* hâlâ *"grading needs the
camera check, and that is not wired up in this build"* diyordu. **Kamera
kontrolü BAĞLI.** Saklanmayan şey **HÜKÜM** (`SessionRecord`ta kasıtlı olarak
puan alanı yok). Cümle **yanlış yokluğu** adlandırıyordu — ve **yazıldığında
doğruydu.**

> ### ***BİR YOKLUK CÜMLESİ, YOKLUK BİTTİĞİ GÜN BAYATLAR — VE HİÇBİR YERİ YANLIŞ GÖRÜNMEZ.***

Yalnız kodu okuyarak bulunamazdı. Düzeltme cümleye **ve kapıya** yapıldı.

## Kapılar susturulmadı, ÇEVRİLDİ

- `publication_inventory`in *"hiçbir şey yazmıyor"* assert'i **tersine
  çevrildi** — o assert'in kendi gerekçesi bunu emrediyordu (*"stops being
  true the moment anything is written"*). Yanına **ikizi** eklendi:
  *mekanizma VAR ama yüzey yok diyor.*
- Aynı dosyada **yorum körlüğünün TERS yönü** ısırdı (kod temiz, yorum
  kırmızı yapıyor) ⇒ panzehir vakaya değil **OKUYUCUYA** uygulandı.
- `reachability`nin dışlama gerekçeleri **bayatladı** ve bunu kapının kendi
  probu söyledi. Yeni şart: *dışlamanın DAYANDIĞI yürüyüşün varlığı da
  ölçülür* — çünkü "burada değil, şurada yürünüyor", ŞURASI silindiği gün
  sessizce "hiçbir yerde yürünmüyor"a döner **ve hâlâ ikna edici görünür.**

## Devir §6'nın dört "ölçemedim" kalemi kapandı

`A5`'in engelleme kanıtı üç non-python koşucuda **ayrı ayrı** (taban 0 kırmızı
→ her sabotaj **tam 1** kırmızı, doğru olan; ağaç `porcelain=0` ile geri
döndü) · `A11`'in imza zinciri **ölçüldü** (`CN=Android Debug`, yalnız v2, v1
false — çıkarım doğruymuş) · `A7`'nin tanığı **ötüyor** · sayma kuralına
çapraz okuma.

⭐ Yan bulgu: `lib/`e konan çözülemeyen tip **yalnız `analyze`**'ı kırmızı
yaptı; `flutter test` yeşil geçti (yalnız import edilen kodu derler).
***İKİ KOŞUCU AYNI ŞEYİ ÖLÇMÜYOR.***

## Açık kalanlar — hepsi koordinatör/kurucu hükmü

1. **Sayma kuralında gedik, ve gediği BEN açtım.** KATI'nın ölçütü
   `Navigator.push`; sonuç yüzeyine `pushReplacement` ile gidiliyor ⇒ vardığın
   bir yer sayıda **görünmüyor**. Kuralın kendi tanımını (*ayrı rota: gidersin
   ve dönersin*) sonuç yüzeyi **karşılıyor**; karşılamayan şey **vekil**.
   (a) vekile sadık ⇒ KATI **3** · (b) tanıma sadık ⇒ KATI **4**.
   ⛔ Beş hattın karşılaştırılabilirliği için yazılmış bir kuralı tek taraflı
   değiştirmek, ölçmek yerine **bozmak** olur. ⚠️ `pushReplacement` kullanan
   her hat aynı boşluğa sahip olabilir.
2. **Hiçbir ders döngü HEDEFİ ilan etmiyor**, şema "hedef yok" diyemiyor ⇒
   yazılabilecek her değer yüzeyde bir yalan. Geçici: `noDeclaredTarget = 0` +
   yüzeyin hedefsizliği ifade edebilmesi. **Tek sabitte geri alınabilir.**
3. **`A12`** — reçete imzaya kadar hazır; zincirin dört halkası VAR, eksik
   **yalnız profil**. ⚠️ Cihaz bugün `unavailable`. ⚠️ `flutter run` bu
   makinede **kırık** (`TARGET_BUILD_DIR`).
4. **C-143'ün ürün hükmü** — beyan mekaniği çalışıyor, kaydın sorduğu soru
   (`mirrorConfident:false` taşıyan referans sevk edilmeli mi) hâlâ açık, ve
   bu turda ölçülen **156 KB ölü referans** onun kardeşi.

## Aile-geneli, koordinatöre taşındı

🪤 **`DiskBundle` tuzağı 50 KB'tı, `rootBundle` değil.** `loadString` 50 KB
üstünü `compute()`a veriyor; izole sahte saat altında hiç koşmuyor. Tuzaktan
kaçınmak için yazılmış sahte, **tuzağı miras alarak yeniden üretiyordu** — ve
yalnız eşiği aşan iki dosyada, bu yüzden "bundle sorunu" gibi göründü.
Önbellek ısıtması **çözmedi**; senkron decode çözdü.
⇒ ***BİR SAHTE, GERÇEĞİN BAŞARISIZLIK KİPİNİ TAKLİT EDER; UYGULAMA AYRINTISINI DEĞİL.***

## Ölçmediklerim, adıyla

1. **Sonuç yüzeyini hiçbir insan gözü görmedi** — yalnız widget testi. Cihaz
   kamerası olmadan simülatörde **yapısal olarak** görülemez (`AVCaptureDevice`
   yok ⇒ oturum başlamaz ⇒ `Finish` çizilmez). Bu, `A1`'in şerhi ve `A12`'nin
   kendisi.
2. **Bir dansçının gerçekten dans ettiği** — replay, kaydedilmiş kare
   üretiyor; cihaz kamerasının bu şekilde kare verdiği ölçülmedi.
3. **`gates.sh`'in üçüncü hâli (`exit 2`)** ayrı sabote edilmedi.
4. **`motion_camera` gizlilik manifestinin podspec'i** — motion-core alanı,
   koordinatörde. Dokunulmadı.

---

# 🏭 VARDİYA 2026-08-18 — üretim hattı bootstrap, baseline yeniden mühürlendi, bildirilen P0 ölçümle sorgulandı (C-315)

**Bağlam değişti:** oturum artık `URETIM-HATTI-OTURUM-PROTOKOLU-2026-08-18.md` altında, orkestratörü
**Motion Orchestration**, hattı PREP lane. Önceki "design linki bekleniyor" bekleme modu (`YENI-OTURUM-PROMPT.md`
üst bloğu) bu kickoff'la SÜPERSEDE edildi — production-line kickoff artık kanonik.

**Baseline yeniden ölçüldü (iddiaya değil):** `app` HEAD `9b472de`, ağaç temiz, `origin/main` ile 0/0,
common pin (`motion_core`+`motion_camera`) tam 40-karakter `f13bdc93...` doğrulandı. `bash tool/gates.sh`
**tamamen yeşil**: 269 flutter + 36 engine test, `flutter analyze` 0 uyarı, tüm özel validator/self-test geçti.

**Bildirilen P0 yeniden ölçüldü, çerçevesi doğrulanmadı:** kickoff "`salsa_shines=live` ama runtime'da
erişilemez — dürüstlük ihlali" diyordu. Ölçüm: semptom doğru ama bu **C-101→C-103→C-138'de (07-30) zaten
bulunmuş, M-F-130'a bağlanmış, `style_availability.dart`'a mimari kilitlenmiş, 2026-08-17'de gerçek
simülatör ekranından DA doğrulanmış** (`docs/device-day/PAKET.md`) kasıtlı bir davranış — kapalı ship-gate
sağlıklı content-status'u isimli gerekçeyle ezer, "live" rozeti kullanıcıya hiç sızmaz. Olası okuma: 08-18
sistemik denetim `statusNote`/`shipGatesNote`/DEFTER geçmişini okumadan ham `status` alanını runtime'la
karşılaştırmış olabilir — yani denetimin kendisi C-101 sınıfı bir vekil-okuma. Tam kanıt zinciri: `C-315`.

**Gerçekten açık bulunanlar:** CHO-P0-001'in formal evidence paketi (`docs/evidence/production-line/`)
hiç yok — malzeme var, format yok. **Yeni** (2026-08-17, kapanmamış): `choreia-hatti` simülatöründe giriş
köprüsü (tap/swipe/HOME) tamamen yanıtsız kaldı, RECIPE.md'nin 16 satırından yalnız 1'i ekrandan doğrulandı.

**PREP dörtlüsü tamamlandı** (`docs/research/R27-uretim-hatti-prep-2026-08-18.md`): (a) 34 yüzeyin W1–W5+Hula
envanteri (sahte/aşırı-iddia bulunamadı, 29 comingSoon disk-yokluğuyla tutarlı) · (b) Hula partner adayları
(en güçlü: Hula Preservation Society — dijital-ortaklık presedenti zaten var; temas kurulmadı, kurucu kapısı)
· (c) müzik-hakları gap analizi (R3 mevcut ve sağlam, territory+platform eksenleri sistematik değil, Uppbeat
önerisi + rights-ledger şema taslağı) · (d) `run_device_matrix.sh` için `gates.sh`'in kendi exit-2/"ORTAM YOK"
sözleşmesinin yeniden kullanımı önerisi (roadmap'in ham "eksik hücrede exit 1" tasarımı cihazsız oturumu
kilitleyebilirdi).

**Sıradaki:** Motion Orchestration'dan slot kararı bekleniyor; PREP kadansında (/loop 45-60dk) devam.

---

## Tur: SOLO OTURUM v3, CHO-P0-001 KABUL — 2026-08-19

**Bağlam değişti:** 14-oturumlu üretim hattı orkestrasyonu 2026-08-19'da kurucu kararıyla İPTAL edildi;
bu oturum artık `SOLO-KICKOFF-PROMPTLARI-2026-08-19.md` sözleşmesi altında bağımsız çalışıyor —
orkestratör/koordinatör/mesajlaşma YOK, onaylar bu pencerede kurucuya soruluyor.

**Kickoff'un düzeltilmiş teşhisiyle başlandı:** "salsa_shines=live ama erişilemez" bir dürüstlük ihlali
DEĞİL (R27 + C-315'in dünkü ölçümü zaten bunu bulmuştu) — gerçek açık iş yalnız CHO-P0-001'in formal
evidence paketinin hiç var olmaması ve 2026-08-17'den kalan doğrulanmamış giriş-köprüsü sorunuydu.

**Bu turda kapanan (C-316, evidence: `docs/evidence/production-line/CHO-P0-001/`):**

1. **34 stilin TAMAMI** (R27'nin dizin-örneklemesi değil) `catalog_cross_check.py` ile programatik
   doğrulandı — 0 yapısal uyuşmazlık. `comingSoon` sayısı gerçekte **31**, R27'nin "29"u düzeltildi
   (sonuç aynı kaldı: sahte/aşırı-iddia yok). 3 stilin (`dancehall`/`shuffle`/`samba_no_pe`) klasörü var
   ama `style.json`u yok — kafes kuralıyla hâlâ tutarlı, öksüz değil (adları `prepare_take.py` +
   `metric-vocabulary.json`da zaten geçiyor).
2. **Giriş-köprüsü yeniden test edildi ve temizlendi.** `choreia-hatti`/`choreia-narrow` (Choreia'ya özel
   simülatörler) boyunca tap/HOME sorunsuz çalıştı; yalnız paylaşımlı (Choreia'ya özel olmayan, ekranında
   Burun Farkı ikonu görülen) iPad simülatörü birkaç dakika eş-oturum çekişmesi gösterdi, zorlamadan
   beklenince düzeldi. 2026-08-17'nin kendi "muhtemelen çekişme" hipotezi doğrulandı — köprüde yapısal
   kusur yok. Detay: `input-bridge-retest.md`.
3. **Dört-viewport gerçek ekran kanıtı** üretildi (iPhone 13 mini/17 Pro/17 Pro Max + iPad Pro 13" —
   iPad iPadOS uyumluluk-penceresinde render ediyor, native tam-ekran değil, ayrı not edildi, bu task'ın
   kapsamı değil). Dördü de birebir aynı dürüstlük metnini gösterdi.
4. **"Kilitli kart tamamlanmış ders üretmiyor" testi** zaten `style_detail_test.dart` +
   `reachability_test.dart`ta VARDI (yeni yazılmadı, bulunup kanıt matrisine bağlandı) — her `Start`
   düğmesinin `onPressed != null` olduğu, engellenen derslerin düğme yerine cümle aldığı zaten kanıtlı.
   "Premium entitlement üretmiyor" yarısı boş kümedir — `lib/services/` henüz yok (CHO-P1-005 kapsamı).
5. **Kod/içerik değişikliği YAPILMADI** — envanter 0 uyuşmazlık verdi, mevcut UI zaten roadmap'in istediği
   davranışı taşıyordu. Bu tur doğrulama+biçimlendirmeydi (C-315: "malzeme var, format yok").
6. **Taze `gates.sh` koşumu** (dünkü iddiaya güvenmeden): 269 flutter + 36 engine + 23 self-test, 25/25
   yeşil, exit 0.

**Kuruculara hatırlatma (EXTERNAL_GATE, bu turda kapatılmadı):** Salsa BPM çözümü kurucunun ~10 dk canlı
tap işi (`tools/beat_annotate.py`; paket `scratch/2026-08-19-motion-orch/MANUAL-MOTION-CHOREIA-BPM-20260819.yaml`)
— pencerede hatırlatıldı, yanıt bekleniyor. CHO-P0-001'i bloklamıyor (katalog dürüstlüğü BPM kapısının
durumundan bağımsız), CHO-P0-003/W1 içerik-tamlığı işine ilgili.

**Sıradaki:** CHO-P0-002 (offline/privacy/signing/CI baseline).

---

## Tur: CHO-P0-002 KABUL — 2026-08-19 (aynı oturum, devam)

**Önce bir bulgu, sonra iş:** Android signing dosyaları (`build.gradle.kts`,
`android_signing_test.dart`) uncommitted bulundu, `git add` bir `.git/index.lock`a
çarptı — `ps aux` **farklı bir session-ID'li, canlı çalışan başka bir Claude Code
oturumunun** (motion-core, aile-geneli beş-tüketici contract-matrix taraması
yapıyordu) aynı anda aynı dosyaları commit ettiğini gösterdi (`a3eab87`). Kurucuya
soruldu, "devam et" onayı geldi — ama gerçek yazar motion-core'du, DEFTER'e YANLIŞ
atıf yazılmıştı, C-317 ile düzeltildi (kendi işim DEĞİLDİ diye kayıt düzeltmesi).

**Bu turda kapanan (C-318, evidence: `docs/evidence/production-line/CHO-P0-002/`):**

1. **Signing kaçış-kapısı.** motion-core'un bıraktığı jablab-J-215-birebir deseni
   (anahtar yoksa hard-fail, kaçış yok) `flutter build appbundle --release`i
   hiçbir koşulda ÇALIŞTIRAMAZDI — roadmap bunu istiyor. Gravita/lissom emsali
   (`allowDebugSigning` opt-in bayrağı) Choreia'ya port edildi; test negatif-
   regex'ten pozitif-varlık+sabotaj desenine yükseltildi (kendi sabotaj testim
   BİR hata yakaladı, düzeltildi — kendi-kendini-doğrulama). GERÇEK gradle
   koşumuyla (metinle değil) doğrulandı: bayraksız BEKLENEN banner'la durdu,
   bayrakla BEKLENEN uyarıyla bitti.
2. **Runtime font fetch KAPANDI.** `google_fonts`un üç ailesi (Instrument Serif,
   Manrope, IBM Plex Mono) artık `assets/fonts/`da self-host (lissom L-348
   deseni). Hangi ağırlıkların gerekli olduğu TAHMİN edilmedi — geçici bir ölçüm
   testiyle (kullanılıp silindi) Flutter'ın Material3 varsayılan TextTheme'inin
   HER rolünün `null` (=w400) olduğu ölçüldü, tek açık override grep'lendi.
   Hash'ler kurulu google_fonts paketinin KENDİ kaynağından okundu. Kanıt:
   272/272 test yeşil (eksik ağırlık istisnayla düşerdi) + gerçek simülatör
   kurulumunda üç özel yazı tipinin doğru render edildiği GÖRÜLDÜ.
3. **Secret scan — aile-geneli İLK.** Dört kardeş hat CI'sı tarandı, hiçbirinde
   yoktu. `tools/secret_scan.py` sıfırdan yazıldı, gates.sh'e bağlandı.
4. **`.github/workflows/quality.yml`** — gravita `checks.yml` iskeletinden,
   Choreia'nın kendi `gates.sh`ini tek doğruluk kaynağı kullanarak.
5. **Privacy/permission yüzeyleri DOĞRULANDI, DEĞİŞTİRİLMEDİ** — zaten doğruydu
   (kamera-only, mikrofon kodu yok). **YENİ:** `docs/store/data-safety-matrix.md`,
   ailede ilk kez.
6. **İki gerçek release build:** Android AAB (75,7 MB, imzasız kod-yolu kanıtı) +
   iOS Runner.app (46,0 MB, `--no-codesign`) — ikisi de hash'lendi, kanıt paketinde.

**Eksik, adıyla:** CI workflow'un henüz GERÇEK bir GitHub Actions koşumu yok
(push edilmeden koşamaz) — sıradaki tura açık.

---

## Tur: CHO-P0-003 ARAŞTIRMASI — gerçek kusur bulundu+düzeltildi, gerçek kapsam netleşti (2026-08-19, aynı oturum)

**CHO-P0-003'e "Bounce model doğruluk kapısını geç" diye başlandı; bir Explore ajanı önce mevcut
altyapıyı taradı (fixture/scoring/FSM/DTW ne var, ne yok).** Bulgu roadmap'in kendi çerçevesini
düzeltti: **DTW ve FSM ikisi de bu kod tabanında KASITLI YOK** (`tools/build_reference.py` DTW'yi
adıyla reddediyor; `DanceJudge` iki-moment snapshot karşılaştırıcı) — roadmap checklist'inin
"uygula" dediği şey zaten var olmayan bir mimariye atıfta bulunuyordu.

**Araştırma sırasında GERÇEK, önceden bilinmeyen bir kusur bulundu ve düzeltildi (C-319):**
`LiveSession._moment()` — canlı uygulamanın skorlanan-an çözümleyicisi — hiçbir stil için
içerikten gerçek phase-bin OKUMUYORDU; `scoredMoments[].phaseBin` diye var olmayan bir alanı
arıyor, her seferinde kaçıp keyfi varsayılana (0, phaseBins/2) düşüyordu. Doğru çözüm
(`phase`→`phases[].id`→`enter.phaseBin`) `test/end_to_end_test.dart`'ta ZATEN vardı ama o test
`LiveSession`'ı hiç çağırmıyordu — canlı yol sıfır kapsamdaydı. Ölçülen fark: salsa'da gerçek
bin'ler 1/29 (64 üzerinden), eski kod 0/32 döndürüyordu — henüz kullanıcıya ulaşmadı (BPM kapısı
kapalı) ama kapı açılınca sessizce yanlış ölçerdi. Bounce'ta davranış BİLEREK korundu (bounce'un
fazları canlı-FSM tipi, `phaseBin`i hiç yok — ayrı, daha büyük bir konu, aşağıda). Düzeltme:
`resolveScoredMomentBin()` saf fonksiyona çıkarıldı, `test/live_session_test.dart` (5 test, biri
sabotaj) yazıldı, TDD kırmızı/yeşil ile doğrulandı (stash ile eski koda karşı derleme hatası
görüldü, geri alınca yeşile geçti). `flutter test` 277/277, `flutter analyze` 0, engine 36/36,
salsa liveness scripti hâlâ OK, taze `gates.sh` yeşil.

**CHO-P0-003'ün gerçek kapsamı (C-320, AÇIK — bu tur uygulanmadı, teşhis edildi):**

1. `DanceJudge` yalnız salsa'nın 4 hata koduna sahip — bounce'un kendi 4 hatasının (NO_BOUNCE/
   BOUNCE_INVERTED/TRUNK_COLLAPSE/ASYMMETRIC_BOUNCE) hiçbiri için kod yok, gereken metrikler hiç
   hesaplanmıyor.
2. **Yapısal uyuşmazlık:** salsa'nın fazları sabit-bin/replay-cycle, bounce'unki canlı-FSM/metrik-
   eşik — mevcut TEK skorlayıcı yalnız birincisini biliyor. Bounce'u skorlamak "4 kod ekle" değil,
   ya yeni bir canlı-FSM skorlayıcı ya bounce'un yeniden-tasarımı — mimari karar, tek taraflı
   verilmedi.
3. İçerik-kalitesi ayrı: bounce'un Tier B→A geçişi ≥6 bağımsız kaynak (bugün 4) + gürültü tabanını
   aşan ölçülmüş anlaşmazlık istiyor — 2+ yeni gerçek video hasadı, RM/RR/salsa ölçeğinde ayrı iş.
4. Confusion matrix/precision/recall/F1 üreten hiçbir araç yok; en yakın emsal
   `ss_shine_footwork_liveness.py` (kablolama kanıtı, istatistik değil) ve `fallback_liveness_test.dart`
   (doğru şekil, n=2 yetersiz).

**Sıradaki oturumun gerçek sırası:** (a) mimari karar — kurucu/koordinatör girdisi gerektirir
(roadmap §13: dans tekniği doğruluğu AI tek başına kabul edemez) → (b) skorlayıcı bileşenini TDD ile
yaz → (c) ölçüm-harness'i kur → (d) ≥6-kaynak hasat işini AYRI, büyük bir tur olarak planla.

**Sıradaki:** Mimari karar için kurucuya sorulacak (bounce skorlayıcı yaklaşımı) — yanıt gelene
kadar/paralelde CHO-P1-001 (özgün shell/premium player) veya CHO-P0-004 (fiziksel cihaz, EXTERNAL_GATE
kısmı hariç) değerlendirilebilir.

**Yönlendirme ölçümü (bu tur sonu):** CHO-P0-004'ün kod-yazılabilir kısmı (kalibrasyon akışı) bile
"tek düzeltme seç" feedback arbiter'ıyla iç içe — o da C-320'nin AYNI mimari kararına bağlı (bounce'un
skorlayıcısı yoksa hangi düzeltmenin gösterileceğine karar verecek bir şey de yok). `lib/app/onboarding/`
bugün yalnız `first_run_view.dart` taşıyor, kalibrasyon ekranı hiç yok — inşa edilebilir ama arbiter'sız
yarım kalır. **CHO-P1-001 GERÇEKTEN bloksuz:** `lib/app/today/` ve `lib/app/practice_lab/` hiç yok,
shell bugün yalnız 2 sekme (STYLES/PROGRESS), roadmap'in 5 sekmesi (Bugün/Stiller/Practice Lab/
İlerleme/Profil) yazılmamış — büyük, saf-UI, skorlama mimarisinden bağımsız bir iş. Bu oturum bunu
BAŞLATMADI (bugünkü tur zaten CHO-P0-001+002+C-319/320 taşıyordu) — sıradaki turun temiz başlangıç
noktası budur.

---

## Tur: CHO-P1-001 — 5-sekme shell KABUL, player akışı BİLEREK ertelendi (2026-08-19, aynı oturum)

**Kurucudan mimari yanıt gelmedi** (kickoff'un "yanıt gelmezse sıradaki göreve geç" talimatı, §1.6) —
CHO-P1-001'e geçildi. İkinci bir Explore ajanı mevcut canlı-ders akışını, tasarım belgelerini ve
stil-sayfası eksiklerini taradı (C-321): dokuz-adımlı roadmap akışının SEKİZİ eksik, ikisi TEK BAŞINA
çözülemez (motion-core şema değişikliği + kurucu BPM kapısı), "Practice Lab" repo'da sıfır emsel
taşıyor, "trend" ekranı orijinal `UI-BRIEF.md`'de V1 kapsamı dışı bırakılmıştı (roadmap'in kendisi
bayat olabilir).

**Bu turda kapanan (C-322, evidence `docs/evidence/production-line/CHO-P1-001/`):** yalnız GÜVENLE
uygulanabilir parça — 5-sekme shell. `choreia_shell.dart` 2 sekmeden (Styles/Progress) roadmap'in 5'ine
(Today/Styles/Practice Lab/Progress/Profile) büyüdü; üç yeni sekme (`TodayView`/`PracticeLabView`/
`ProfileView`) `library_view.dart`'ın M-F-186 kuralıyla ("no promise language") dürüst-boş yer
tutucular — ne gizli ne sahte-dolu. `reachability_test.dart`nın tüketici-tam KATI/GEVŞEK bölme
denetimi YAMANMADI, GENİŞLETİLDİ: yeni bir `unreachableByDesign` sınıfı kendi kanıtını taşıyor (kabuk
kaynağında gerçekten `IndexedStack` çocuğu mu, GEVŞEK yürüyüş gerçekten dokunuyor mu — ikisi de
kaynaktan doğrulanıyor). İlk yazımda başlangıç sekmesini Today (index 0) bıraktım — 8 test kırmızı
oldu (`find.byType` IndexedStack'in offstage çocuklarını görmüyor); düzeltme `_index=1` (Styles kalır
varsayılan, Today dürüst-boş bir açılış ekranı olmasın diye BİLEREK) — testlerin kendi kendini
doğrulama disiplininin tam örneği. Gerçek simülatör kanıtı: `choreia-hatti`de 5 sekmenin BEŞİ de
dokunuldu, ekran görüntüleri evidence'ta. `flutter analyze` 0, `flutter test` 280/280.

**Kapsam BİLEREK dar tutuldu:** premium player akışı (preview/mirror/slow/loop/beat-live/weak-count-
retry), stil sayfası kurs/BPM/trend blokları, `CHO-UX-001` (5-katılımcılı kullanılabilirlik testi,
EXTERNAL_GATE) — hiçbiri bu turda uygulanmadı. C-321'in gerekçeleri hâlâ geçerli: çoğu ya tasarım
kararı ya motion-core kapsamı ya kurucu kapısı gerektiriyor.

**Sıradaki (yeni bir oturumda, bu tur BAŞLATMADI):** mimari kararlar netleşince (bounce skorlayıcı
+ mirror/slow/loop tasarımı) premium player akışına TDD ile başla; ya da BPM-bağımsız, tek-başına
buildable parçaları önce al (BPM style-page alanı, kurs-türü şema alanı).

**Aynı tur, küçük ek (C-323):** BPM alanı hemen alındı — `content/styles/*/style.json`daki
`bpmRange`/`bpmStatus` `StyleProse.tempo`ya taşındı, stil sayfasına kendi "TEMPO" bölümü eklendi.
Ham `bpmStatus` dizesi (C-117 kuralı) ekrana hiç çıkmıyor, yalnız okuyucu cümlesi. Gerçek cihazda
salsa'nın disputed vakası doğrulandı, hip-hop'un çözülmüş vakası testle. `flutter test` 282/282.
Kalan: kurs-türü şema alanı (Temeller/Kombolar/Rutinler) — henüz alınmadı, ayrı bir küçük iş olabilir.

---

## Tur: kurs-türü alanı değerlendirildi, ertelendi — C-324 (2026-08-19, aynı oturum)

C-323'ün kendi kapanışında bıraktığı tek soru işaretini ("kurs-türü şema alanı — henüz alınmadı,
ayrı bir küçük iş olabilir") bu turda dikkatle ölçtüm, varsaymadım. `content/styles/salsa_shines/
style.json` + `hip_hop_foundations/style.json`'daki TÜM ders listesi (16 ders) çıkarıldı: hepsi
`level 1` veya `level 2`, yani hepsi tek-adım/tek-kavram "Temel" içerik — sıfır "Kombo", sıfır
"Rutin" örneği repo'da mevcut. Sonuç: alan eklense bile iki kova kalıcı olarak boş kalırdı; bu
BPM'den (C-323, veri zaten vardı, saf kablolama) temelde farklı — burada ne şema alanı var ne de
dolduracak içerik. Alan eklemek ya sahte-derinlik (iki hep-boş kova göstermek) ya da yeni bir
taksonomi uydurmak anlamına gelir — ikisi de içerik/ürün kararı. **C-324** olarak deftere işlendi,
uygulanmadı; C-321'in README karşılaştırma tablosundaki "(buildable)" notu bu bulguyla düzeltildi.

Sonuç: bu turda GÜVENLE alınabilecek başka bağımsız parça kalmadı. İki mimari soru (bounce
skorlayıcı; mirror/slow/loop/Practice Lab tasarımı) hâlâ kurucudan yanıt bekliyor — üçüncü olarak
kurs-türü kapsam sorusu da (iki boş kova dürüstçe mi gösterilsin, yoksa yeni içerik mi üretilsin)
aynı kurucu turunda birlikte sorulmak üzere not edildi. Bugünkü tur kapsamlıydı (CHO-P0-001,
CHO-P0-002, C-319→C-324, 10 commit) — turu kısa bir kapanış notuyla bırakıyorum, uzun loop aralığı
kuruyorum.

---

## Tur: CHO-P1-004 hazırlık taraması, gerçek bir uyum-belgesi hatası bulundu — C-325 (2026-08-19, üçüncü tur)

Kurucudan yanıt yok, başka oturum yeni commit bırakmamış — CHO-P1-004'ün (local-first progress/
privacy/export) gerçekten başlatılmaya hazır olup olmadığını değerlendirmek için bir Explore ajanı
gönderildi. Sonuç iki ayrı bulgu getirdi.

**Birincisi (C-325, bu bölüm):** `docs/store/data-safety-matrix.md` — bu SABAH, CHO-P0-002
sırasında bu oturumda yazılmıştı — "SessionStore yalnız okunuyor, hiç yazma yok" diyordu. YANLIŞ,
yazıldığı anda bile: `live_lesson_page.dart`daki gerçek yazma yolu (C-268/A1) 2026-08-13 13:51'de
açılmıştı, gizlilik manifestinin ölçümünden (C-266/A8, aynı gün 00:33) 13 saat sonra — bu dosya
altı gün sonra eski ölçümü kopyalayıp yeniden doğrulamadan yazılmış. Uyum-belgesi sınıfı olduğu
için (Play/Apple mağaza formlarına doğrudan girdi) düzeltme hemen uygulandı: App activity satırı
düzeltildi, data-deletion iddiası çıkarıldı, Apple tarafı ayrı bir bayatlık uyarısıyla işaretlendi
(Apple'ın kendi manifest dosyası DEĞİŞTİRİLMEDİ — yalnız yeniden-doğrulanmamış olduğu kayda geçti,
Apple'ın on-device-veri muafiyeti Play'den farklı olabileceği için emin olmadan dosyaya dokunulmadı).

**İkincisi, ayrı bir kayıt olarak takip ediyor (C-326):** CHO-P1-004'ün roadmap'teki "yedi Drift
tablosu" planı, bu ajan taramasıyla ortaya çıkan GERÇEK JSONL `SessionStore` mimarisiyle (zaten
canlı, zaten yazıyor) hiç uzlaştırılmamış — üçüncü bir mimari soru.
