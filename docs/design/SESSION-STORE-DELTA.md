# SessionStore — Choreia delta sözleşmesi (M-F-156 paket 1 hazırlığı)

**Tarih:** 2026-07-30 · **Statü:** tasarım sözleşmesi, KOD DEĞİL · **Kaynak desen:** `ventures/jablab/app/lib/app/session_store.dart` (205 satır, okundu) + `test/session_store_test.dart`
**Neden şimdi ve app olmadan:** koordinatör portla birlikte **delta-kaydı** istedi ("arayüzü JabLab'ınkiyle hizalı tut, farklarını kaydet — sen İKİNCİ tüketicisin; Lissom üçüncü olduğunda üçler kuralı çekirdek-terfisini tetikler, o gün senin delta-kaydın terfinin girdisi"). Delta analizi app gerektirmiyor; port ise gerektiriyor (aşağıda).

## 0. ⚠️ KAPSAM GERÇEĞİ — port henüz YAPILAMAZ

**Choreia'da hiç Dart/Flutter projesi yok.** Ölçüldü: `app/` = `content/ docs/ tools/ harvest/` + iki markdown; `pubspec.yaml` yok, tek `.dart` dosyası yok. C-087'de kayıtlı durum aynen sürüyor.

SessionStore bir **ürün** bileşeni (`path_provider` ile uygulama-özel dizin + Flutter yaşam döngüsü). Bu yüzden bu belge sözleşmeyi yazar, kodu yazmaz. App bootstrap'ı ayrı bir kalem olarak koordinatörde (Lissom'un paketinde aynı iş açıkça ayrı kalem).

## 1. JabLab arayüzü — olduğu gibi (hizalanacak yüzey)

```dart
final class SessionRecord {
  final String lessonId;
  final DateTime completedAt;
  final int workedSeconds;      // fiilen çalışılan, dinlenme HARİÇ
  final int roundsCompleted;    // yarıda bırakılan da kaydedilir
  final int plannedRounds;
  bool get isComplete => roundsCompleted >= plannedRounds;
}

abstract interface class SessionStore {
  Future<void> append(SessionRecord record);
  Future<List<SessionRecord>> recent({int? limit});   // en yeni ÖNCE
  Future<int> workedSecondsFor(String lessonId);
}
```

Taşınacak dört yapısal karar (Choreia'da **aynen** geçerli, delta yok):

| Karar | Gerekçe (JabLab'ın kendi kaydı) | Choreia'da |
|---|---|---|
| **Append-only JSONL, 3. taraf DB YOK** | Seans kaydı olay akışı; sorgu yükü yok. DB şema göçü + platform bağımlılığı getirir, sorgu ihtiyacı ÖLÇÜLDÜĞÜNDE gelir. (Hive gotcha'sı: yanlış cipher'da fırlatmaz, içeriği sessizce siler) | Aynen |
| **SATIR-düzeyi şema sürümü** (`v`) | Dosya düzeyinde tek sürüm, eski satırların hangi kurala göre yazıldığını okunamaz kılar | Aynen |
| **Atomik tmp+rename** | Mobilde OS uygulamayı her an öldürebilir; doğrudan append yarım satır bırakır, `rename` POSIX'te atomik | Aynen |
| **Bilerek-az alan; hüküm/skor alanı YOK** | Kamera köprüsü yokken sıfır kaydetmek, yarın "ilerleme" grafiğinde sıfır çizmek olurdu | Aynen — **Choreia'da daha da bağlayıcı**: skorlanan tek dersim var, beşi demoOnly |

Arıza davranışları (test edilecek, JabLab'ın testinden birebir): bozuk satır **tüm geçmişi silmez** (atlanır) · yarım son satır götürmez · bilinmeyen `v` atlanır (ileri uyumluluk: kullanıcı uygulamayı geri kurabilir) · depo kurulamazsa app çalışır · `_readAll` **değiştirilebilir** liste döner (JabLab'da `const []` dönmek ilk-açılış yolunu çökertmişti — testin yakaladığı gerçek kusur).

## 2. DELTA 1 — `roundsCompleted`/`plannedRounds` Choreia'da KARŞILIKSIZ

Bokstaki "tur" (round) bir zaman kutusudur: 3 dakika çalış, dinlen, tekrar. **Dansta böyle bir birim yok.** Bir dans dersi tekrarlanan bir ÇEVRİM üzerine kurulur, ve çevrim bu repoda zaten ölçüm birimi:

- `content/references/*.json` → `sources[].cyclesInSegment`, `evidenceThickness.cyclesPerTake`
- C-054'te aile kaydına giren üçüncü sayım birimi: **TEKRAR(take) ≠ EĞİTMEN(source) ≠ ÇEVRİM(cycle)**

**Öneri:** `cyclesCompleted` / `plannedCycles`.

```dart
final int cyclesCompleted;   // fiilen tamamlanan adım çevrimi
final int plannedCycles;     // dersin hedeflediği
bool get isComplete => cyclesCompleted >= plannedCycles;
```

Aynı semantik (yarıda bırakılan kaydedilir, tamamlanma oranı okunabilir kalır), farklı birim. **Çekirdek-terfisi günü için not:** ortak arayüz bu alanı `unitsCompleted`/`plannedUnits` gibi birim-agnostik adlandırmalı ve birimin adını app tarafında bırakmalı — üç app üç farklı şey sayacak (JabLab tur, Choreia çevrim, Lissom muhtemelen tekrar/rep). Bugün bunu tek taraflı yapmıyorum; ikinci tüketici olarak deltayı kaydediyorum, isimlendirme kararı üçüncü tüketici geldiğinde koordinatörde.

## 3. DELTA 2 — `lessonClass` gerekiyor (demoOnly gerçeği)

JabLab'ın kaydında ders sınıfı yok, çünkü orada tüm dersler aynı sınıfta. Choreia'da **bugün 1 skorlanan + 5 demoOnly ders** var (M-F-152 sonrası) ve ilerleme yüzeyi bu ayrımı göstermek ZORUNDA — aksi halde "5 ders tamamladın" cümlesi, beşinin puanlanmadığını saklar.

**Öneri:** `lessonClass` kaydedilir (`scored` | `demoOnly`), `style.json`'daki ders beyanından okunur.

Neden kayda giriyor (yüzeyde türetilmesin): ders sınıfı **zamanla değişebilir** — `ss_l1_basic` bugün `demoOnly/structural-circular`, kurucu videoyu izleyip temiz basic çıkarsa `scored`'a terfi edecek (M-F-152 `promotionPath`). Kaydı yazıldığı günün sınıfıyla saklamak, geçmişi retroaktif olarak yeniden yorumlamayı engeller: terfi öncesi seanslar terfi sonrası "skorlanmış" görünmez. Bu, `modelSha256`/`corePin` disiplininin (M-L-01) seans katmanındaki karşılığı.

## 4. DELTA 3 — "TAMAMLAMA ÖLÇÜMDÜR, HÜKÜM DEĞİL" (paket 2'nin Choreia-özgü sorusu)

Koordinatörün sorusu: *demoOnly dersler ilerlemede "öğrenildi-işareti" alabilir mi?*

**Cevap: ALIR — ve ayrım yüzeye yazılır.** Gerekçe zincirli:

1. K8/M-F-04 **SKORU** kapatır, olguyu kapatmaz. JabLab'ın `RecordedSummary`'si tam bu ayrım üzerine kurulu: *"hüküm YOK: burada 'iyi/kötü' diyen tek alan bile bulunmaz… bu yüzden K8 kilidi bunları kapatmaz"*.
2. "Bu dersi açtım, baştan sona çalıştım" bir **ölçümdür** — kameradan bağımsız, dürüstçe kaydedilebilir.
3. "Bunu iyi yaptın" bir **hükümdür** — ölçüm gerektirir, demoOnly derste tanım gereği yok.
4. K10'un ruhu: ölçülemeyen hareket ELENMEZ. Tamamlamayı da esirgemek, dersi ikinci sınıf yapardı — tam K10'un engellemek istediği şey.

**Yüzey sözleşmesi (UI-BRIEF'e işlenecek):**

| Ders sınıfı | Kaydedilen (ölçüm) | Gösterilen bant/skor (hüküm) |
|---|---|---|
| `scored` | süre · çevrim · tamamlama | bant (kalibrasyon kapısından sonra) |
| `demoOnly` | süre · çevrim · tamamlama | **"—"** + sebebi (`demoOnlyReason`) |

İlerleme ekranı iki bölüm olmak zorunda: **"Kaydedilenler"** (ölçüm; her iki sınıf) ve **"Değerlendirilenler"** (hüküm; yalnız `scored`). Tek listede karıştırmak, demoOnly tamamlamalarını puanlanmış gibi okutur.

Ve JabLab'ın J-066 disiplini aynen: **"hangi kapılar bugün geçilemez ve süre retroaktif kredi OLMAZ" ekranda yazılı** — sessizlik yalandır. Choreia'nın bugünkü karşılığı: *zamanlama hiçbir derste ölçülmüyor (BPM disputed)*, *ss_shine dışında skorlanan ders yok*, *`NO_WEIGHT_TRANSFER` gürültü tabanı yüzünden bloklu*.

## 5. Port ön-koşulları (app bootstrap kaleminde karşılanacak)

- `pubspec.yaml` + `analysis_options.yaml` + `lib/` + `test/`
- `packages/choreia_engine` — motion_core **pinli** (bugün pin `motion_core-v0.5.0`, `validate_content.py` CORE_PIN ile aynı olmalı; ⚠️ `--drift-check` şu an pinin 25 commit geride olduğunu söylüyor, bootstrap günü bilinçli bir pin kararı gerekir)
- `path_provider` (yalnız uygulama-özel dizin için; depolama biçimi uygulamada)
- Bundle ID `com.yulalab.choreia` (rezerve 2026-07-25)
- CLAUDE.md sert kuralı: *ortak altyapı motion-core'dan PİNLİ sürümle; çekirdek KOPYALANMAZ*

## 6. Bu belgenin kendi sınırı

Buradaki hiçbir alan **çalıştırılarak** doğrulanmadı — kod yok. Üç delta önerisi (çevrim birimi, `lessonClass`, tamamlama/hüküm ayrımı) tasarım gerekçelerine dayanıyor, ölçüme değil; port günü testler bunları ya doğrular ya düzeltir. Delta-kaydının değeri şu an "üçler kuralı için ikinci veri noktası" olmasında, kanıtlanmış bir arayüz olmasında değil.
