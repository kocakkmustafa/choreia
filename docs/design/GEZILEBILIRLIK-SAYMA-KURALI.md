---
tur: kural
proje: choreia
guncelleme: 2026-08-12
---

# Choreia — Gezilebilirlik sayma kuralı (dört soru)

Koordinatör sevki: beş hattın **karşılaştırılabilir** sayması için dört soru.
⛔ **Diğer dört hattın kuralına BAKILMADAN yazıldı** (koordinatör sınırı):
önce görmek, seninkini onlara benzetir ve *karşılaştırılabilirliği ölçmek
yerine ÜRETMİŞ* olurduk.

**Kural kodda yaşıyor, burada değil:** `test/reachability_test.dart` her
koşumda yeniden ölçer. Bu belge o testin **ne saydığını** anlatır; sayıyı
tutmaz — sayı testin kendisindedir (elle yazılmış bir sayı, kimsenin
yeniden koşmadığı bir iddiadır).

**Bugünkü ölçüm:** KATI **3** · GEVŞEK **5**.

---

## ① Sekme KATI'da mı GEVŞEK'te mi sayılır — ve kaç?

**Choreia'da 2 sekme var** (`shell.tab.library`, `shell.tab.progress`),
`IndexedStack` ile değişiyorlar — **rota değişmiyor**.

| | sekme sayımı | gerekçe |
|---|---|---|
| **KATI** | **1** (yalnız açılışta üstünde durulan) | KATI ölçütü tek: `Navigator.push`. Sekme itmez, o yüzden ikinci sekme KATI'da **yok**. Ama üstünde durulan sekme sayılır — o *zemin*, hedef değil. |
| **GEVŞEK** | **2** | GEVŞEK'e göre sekme *"gittiğim bir yer"*: kullanıcı ilerlemesine gider ve geri döner; rota hiç değişmese de deneyim bir yer değiştirmedir. |

**Yani sekmeler ölçütü ikiye ayıran şeyin ta kendisi.** İki okuma bunun için
var: *"ayrı ekran"* denince perde-mi-rota-mı belirsizliği kapanmıyordu.

## ② Envanter nasıl türetiliyor?

**Elle liste YOK. İki ayrı türetim, ikisi de içerikten:**

1. **Gezilebilir küme yürüyerek üretilir** — test hiçbir rotayı doğrudan
   çağırmaz; ekranda **boyanmış** bir kontrolü bulur ve **basar**. Bir
   `NavigatorObserver` (`_RouteSpy`) itilen rotaları kaydeder. *Sayılan şey
   kodda var olan rota değil, kullanıcının varabildiği yer.*
2. **Başlatılabilir ders kümesi içerikten TÜRETİLİR ve manifestten süzülür:**
   `library.cards × offers(runnableSteps) × canStart` → bugün
   `['hip_hop_foundations/hh_l1_bounce']`. **`pubspec.yaml`de bildirilmemiş
   bir referans, diskte olsa bile derse dönüşmez** (C-143: *diskte olan ≠
   uygulamada olan*).

⚠️ İki kasıtlı sertlik:
- **Bulmak ≠ erişmek.** Tembel `ListView` görünür alanın **altında** çocuk
  kurar; `find` kullanıcının dokunamadığı bir düğmeyi görür. Bu yüzden her
  basıştan önce `ensureVisible`. (*Bir replikanın varlığı, tetiğinin varlığı
  değildir* — widget ölçeğindeki hâli.)
- **Sahte, cihazın arıza kipini taklit eder.** `DiskBundle` dosya sistemini
  okur ve `pubspec`in sevk etmediği bir dosyayı memnuniyetle döndürür;
  ölçüm bu yüzden `DeviceBundle` ile yapılır — bildirilmemiş referansta
  **cihaz gibi** fırlatır.

## ③ Ölçüm nereden başlıyor?

**Uygulamanın açılışından, TAZE KURULUMDA.** `MaterialApp.home` =
`ChoreiaShell`, ilk-koşu bayrağı `false`.

- **Zemin sayılır, hedef değil:** üstünde durulan ilk rota (kabuk) KATI'da
  **1**'dir; `pushed` yalnız *"bir yere gittim"* demektir.
- **Tanıtım ekranı kullanıcı gibi geçilir** — bayrağı arkadan `true` yaparak
  **değil**, düğmesine **basarak**. Gerekçe kuralın parçası: *bir ekranı
  atlayarak yürüyen bir ölçüm, o ekranın çıkışı olup olmadığını söyleyemez.*

## ④ Onboarding içeride mi?

**GEVŞEK'te EVET, KATI'da HAYIR — ve bu bir tercih değil, ölçütün sonucu.**

`FirstRunView` kabuğun **kendi rotasının içinde** çiziliyor; `Navigator.push`
yok. Dolayısıyla:
- **KATI**: sayılmaz (rota itilmedi).
- **GEVŞEK**: sayılır — yeni bir kullanıcının gördüğü **ilk yer**, ve
  çıkışı olan bir yer.

⚠️ **Ölçütün kabul edilmiş bedeli:** onboarding'i olmayan bir hat ile
onboarding'i olan bir hat **KATI'da aynı** görünür. KATI *ürünün
derinliğini* ölçer, *ilk-koşu deneyimini* değil. Bu yüzden iki sayı da
raporlanır; tek sayıya indirmek, iki farklı soruyu tek rakamın altında
gizlemek olur.

---

## ⚠️ AÇIK — `pushReplacement` kuralın DIŞINDA kaldı (2026-08-13, koordinatörde)

KATI'nın ölçütü yukarıda tek: **`Navigator.push`**. `C-268`'de eklenen sonuç
yüzeyine **`pushReplacement`** ile gidiliyor — biten bir oturuma geri
yürünemesin diye. Sonuç: `didPush` **hiç çağrılmıyor**, `_RouteSpy` görmüyor,
ve kullanıcının gerçekten vardığı bir yer KATI sayıda **görünmüyor**.

Oysa kuralın kendi tanımı şu: *"ayrı ROTA. Bir yere GİDERSİN ve geri
DÖNEBİLİRSİN."* Sonuç yüzeyi bunu karşılıyor (gidilir; oradan stil sayfasına
dönülür). Karşılamayan şey **vekil**: `Navigator.push`, *"ayrı rota"* demenin
kısayoluydu — ve kısayol kırıldı.

> ***BİR ÖLÇÜTÜN KELİMESİ, ÖLÇTÜĞÜ ŞEYİN KELİMESİ OLMAYABİLİR.***

| okuma | Choreia KATI | gerekçe |
|---|---|---|
| **(a) vekile sadık** — yalnız `didPush` | **3** (bugünkü sayı) | değiştirme bir itme değildir |
| **(b) tanıma sadık** — ayrı rota, gidilir ve dönülür | **4** | sonuç yüzeyi ayrı bir rotadır |

⛔ **Hat bunu tek taraflı değiştirmez.** Bu kural beş hattın
**karşılaştırılabilir** sayması için yazıldı; neyin sayıldığını tek başına
değiştirmek karşılaştırılabilirliği ölçmek yerine **bozmak** olur. Ölçüm
`docs/research/R26-kapali-kalemlerin-yeniden-olcumu.md` §④'te; karar
koordinatörde. ⚠️ **`pushReplacement` kullanan her hat aynı boşluğa sahip
olabilir** — bu Choreia'ya özgü değil.

📌 Bu arada `test/first_walk_test.dart`in kendi tanığı `didReplace`'i de
gözlüyor ve budanmayan bir `trail` tutuyor: sonuç yüzeyine **varıldığı
ölçülüyor**; sayılmadığı tek yer A7'nin KATI rakamı.

### 🔢 İKİ PENCERE ARTIK NESİRDE DEĞİL, ÖLÇÜMDE (H-4 ②, 2026-08-13)

Koordinatör hükmü: *karar aile düzeyinde işlenene kadar hat KATI'yı **iki
pencereyle** raporlar.* Yukarıdaki `3` ve `4` **artık bu tablodan okunmuyor** —
`test/first_walk_test.dart` her koşumda ikisini de türetiyor:

```
KATI (pushReplacement HARİÇ) = 1 (kabuk) + spy.pushedEver.length  → 3
KATI (pushReplacement DAHİL) = 1 (kabuk) + spy.trail.length       → 4
```

Niye ölçüm: **bu tablodaki iki sayı, kod değiştiği gün hiçbir şeyi kırmadan
bayatlar.** Bu dosyanın kendi konusu tam olarak o sınıf (*bir ölçütün kelimesi
bayatladı*), ve aynı kusuru kendi çözümünde tekrarlamak tuhaf olurdu.

⭐ **Ve ölçülen asıl şey sayılar değil, ARADAKİ FARK.** Test `dahil − hariç = 1`
ve `replaced.length == 1` çivilerini de taşıyor: `pushReplacement` bir gün
kalkarsa iki pencere **çakışır** ve bu açık sorunun konusu kalmaz — o gün test
kırmızı vererek *"tartışılacak bir şey yok, kuralı kapat"* der. Farkı ölçmeyen
bir kapı, anlaşmazlığın **çözüldüğünü** göremez ve açık bölüm burada sonsuza
kadar durur.

---

## Bu kuralın ölçmediği şey — adıyla

Gezilebilirlik **varılabilirliği** ölçer, **yararlılığı** değil.
Bugün Choreia'da KATI 3 / GEVŞEK 5, ama **34 stilin 33'ü çıkmaz sokak**:
kartına gidilir, sayfası açılır, ders **yoktur**. Sayı bunu **görmez** —
ve görmediğini burada yazmak, sayının yanlış okunmasını engelleyen tek şey.
