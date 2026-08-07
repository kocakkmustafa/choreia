---
tur: envanter
proje: choreia
guncelleme: 2026-08-07
---

# Choreia — Kapı Envanteri

**Soru dışarıdan sorulur: *bu kapı neyi ÖLÇMÜYOR?***

Şablon notu (JabLab J-126): **kapı kurmak bir iş değil, İKİ iş — kapıyı kurmak
ve KAPSAMINI YAZMAK.** İkincisi atlanınca kapı yeşil kalır ve o alanda kimse
bakmaz: ***yeşil bir kapı, bakılmayan bir alan üretir.***

**Kanıt sütunu zorunlu:** kapsamı nasıl biliyorum · negatif ikizi var mı ·
sabotajla sınandı mı.

**Kör nokta sınıfı (J-125):** `algı` = yalnız göz kapatabilir · `kod` =
kapanabilir · `yöntem` = ölçüm yöntemi değişirse kapanabilir.

---

## 🔴 Bu envanteri yazarken bulunanlar

| # | Bulgu | Sınıf | Durum |
|---|---|---|---|
| 1 | **BEŞİNCİ muafiyet yapısı vardı ve onu BEN yazdım** — `explainedOmissions` (sözlüksüz 16 stil), C-160'ta, yani C-153'ün *tam bu sınıfı* temizlemesinden **bir saat sonra**. Diğer dördüne verdiğim kendi-kendini-denetleme kapısı buna verilmemişti: içerikten silinen bir stil listede ölü id bırakır ve `containsAll` sonsuza dek yeşil kalır | kod | ✅ denetim eklendi, **sabotajla kanıtlandı** (ölü id → isimle düştü) |
| 2 | **Motor kapılarım faz bin'lerini SABİT yazmıştı** (`momentA: 1, momentB: 29`), `judge_test`'ten kopyalanmış. Bugün doğru — **şans eseri**. Hiçbir şey doğrulamıyordu; içerik faz bin'ini yeniden ayarlarsa C-147/C-149 ölçümlerim **yanlış anda** ölçmeye devam eder ve yeşil kalır. İki kardeş test (`end_to_end`, `fallback_liveness`) zaten içerikten türetiyordu — **doğru desen repoda vardı, izlemedim** | kod | ✅ içerikten türetiliyor, eksik faz `StateError` |

---

## Kapılar ve kapsamları

| Kapı | ÖLÇÜYOR | ÖLÇMÜYOR | Kanıt / ikiz / sabotaj | Sınıf |
|---|---|---|---|---|
| `contrast_test` | Token alfalarının + rozet tonlarının WCAG oranı, en kötü zemine karşı; taban **ve** tavan; hiyerarşi yayılımı | **Yerinde ezilen renkleri** (`copyWith(color:)` gibi bir yol) — bugün böyle bir yol yok ama kapı da onu aramıyor. **Ayırt edilebilirliği** ölçmüyor (WCAG luminans ölçer) | Alfa listesi `lib/` kaynağından taranıyor + boş-değil koruma. Ölçüm aleti önce doğrulanıyor (21:1 · sıfır-alfa · bindirme rengi oynatmalı). **3 sabotaj** | algı (ayırt edilebilirlik) + kod (yerinde ezme) |
| `content_assets_test` | Bir dersin erişebildiği referans **sevk ediliyor mu** | Referansın **içeriğinin doğru** olduğunu; bundle dışındaki varlıkları | `pubspec` parse ediliyor; dizin girdisi **özyinelemeli değil** ayrıca test edilmiş (ilk sürüm `startsWith` ile hiçbir şey ölçmeden geçti). Muafiyet listesi 3 yönde denetleniyor (dosya var mı · hâlâ beyansız mı · **derse erişilebilir mi**) | kod |
| `content_schema_test` | **Ölü okuma** (parser çekiyor, içerik yazmıyor) + **ölü yazma** (içerik yazıyor, kimse okumuyor) | `style.json` şemasını (yalnız `library.json`); alanın **değerinin** doğruluğunu | İki taraf da kaynaktan taranıyor; muafiyet listesi kendini denetliyor. **Bu kapı kurulduktan dakikalar sonra kendi ölü-yazmamı yakaladı** | kod |
| `content_claims_test` | Metnin rozetle tutarlılığı: teslim-fiili · uygulama sesi · özneli hüküm sözcüğü · sözlük iddiası | Metnin **doğru** olduğunu (kültürel/olgusal doğruluk); **anlaşılırlığını** | Kurallar koşulsuz (açılabilirliğe bağlı olsaydı bir stil açıldığı gün gevşerdi). Çapraz kontrol: hiçbir stil `scored` değilken yazıldı, olursa düşer. **Sabotaj: 3 ihlal → 3 kapı** | algı (anlaşılırlık) |
| `worst_case_page_test` | Sentetik en-uzun sayfa 375×812'de, **1,0× ve 2,0×**, kaydırma boyunca; katalog aynı baskıda | **Cihazda** gerçekten ne olduğunu; 2,0× üstünü; yatay dar cihazları | Alanlar içerikten türetiliyor; **kompozit kapsamı** `style_detail_view`'daki `card.entry.<alan>` okumaları taranarak çivili — o kapı hemen `onHoldReason` eksiğini buldu. **Sabotaj: katı `Row` → 62px** | kod |
| `chrome_layout_test` | İçeriğin AppBar'a göre NEREDE başladığı (üstte ölü boşluk / altına gizlenme) | Diğer ekranların iç boşluklarını; görsel ritmi | **47pt çentik inset'i ŞART** — `top: 0` ile çift sayım görünmez, o testi atlayan sürüm bozuk kodda da geçerdi | kod |
| `publication_inventory_test` | Yüzeyin **var olmayan mekanizmayı anlatması** (konuşkan yokluk) | Yalnız bildiğim mekanizmaları; bir cümlenin **yanlış anlaşılmasını** | Hiçbir şeyin yazmadığı regex'le çivili + *"depo oluştuysa yeniden bak"* uyarısı. Yorumlar ayıklanıyor (ilk sürüm yorumdaki apostrofla **yanlış pozitif** üretti) | algı (anlaşılma) |
| `single_correction_test` | Türetilmiş sıra; sıralanmamış kodun üste çıkmaması; mute kodun asla düzeltmeye terfi etmemesi | Sıranın **doğru** olduğunu — yalnız `unlockRule`'dan türediğini | Kodlar **gerçek judge koşusundan** türetiliyor; dayanak `unlockRule`'a çivili (`STEP_TOO_LARGE` girerse düşer). Faz bin'leri artık içerikten | yöntem |
| `library_catalog_test` | Türetimin gerçek içerikle birebirliği; rozet kafesi; kural-tabanlı sayımlar | İçeriğin **doğru** olduğunu | Sayımlar kurala çevrildi (C-160); tripwire'lar isimli. **Sabotaj: doğru büyüme yeşil, gerekçesiz eksik kırmızı** | kod |
| `style_detail_test` / `library_view_test` | Render, taşma, dürüstlük anahtarları | Görsel kaliteyi; **dokunuş yolunu** (simülatörde tıklama yok) | `deviceRunnable` manifestten türetiliyor; harness'ın cihazdan **daha müsamahakâr** olduğu isimli | kod (dokunuş) |
| `pin_equality_test` | İki paketin tek ref'ten geldiği; sürümlerin ne olduğu | Pin'in **doğru** commit olduğunu (yalnız AYNI olduğunu) | `entry()` içinde `isNotNull` kapıları + **pozitif ikiz** (lock'ta iki paket de gerçekten var). Sürüm sabitleri **kasıtlı tripwire** — pin bump'lanınca düşsün diye, gerekçesi kodda | kod |

---

## ⛔ SERT KURAL SÜPÜRMESİ (C-174)

*"Kural var"* ile *"kural ZORLANIYOR"* ayrı şeyler. Brief'in ⛔ listesi tek tek
süpürüldü. **Bağlanamayan kalemler tek kutuya konmadı** — hangisinin bir gün
bağlanabileceği kaybolmasın diye sınıfı yazılı (J-143 taksonomisi).

| # | Sert kural | Kapı | Nerede |
|---|---|---|---|
| ① | Ritim/zamanlama puanı YOK | ✅ | `STEP_LATE` yapısal `noVerdict`; *"blocked codes never fire"* (judge) + C-170 beat-grid bağı |
| ② | Sahte/boş kurs ASLA listelenmez | ✅ | *"a style with no authored document declares no lessons"* + *"cannot be openable with nothing to open"* |
| ③ | Ölçüm olmadan skorlanan adım YOK (K10) | ✅ | *"nothing claims grading while nothing IS graded"* + *"an ungraded lesson always states why"* + `runnableSteps` probe |
| ④ | `demoOnly` **ikinci sınıf görünmez** | ✅ | Aynı padding (yapı) **+ kontrast bandı** `0,85×–1,05×` scored (görsel). Taban C-156, **tavan C-159** |
| ⑤ | Köken/atıf **küçültülmez** | ✅ **BU SÜPÜRMEDE KURULDU** | Karşılaştırmalı: sayfadaki hiçbir düzyazı atıftan büyük olamaz. **Ölçüldü: atıf 13,5 iken tanıtım 14,5'ti** — kredi, hemen üstündeki paragraftan küçüktü |
| ⑥ | Ders akışı 3. adım **boş bırakılır** | ⛔ **SINIF ③ — yanlışlayacak referans yok** | Ders akışı ekranı **hiç yok** (design-ahead §5). Kuralın bağlanacağı yüzey yok; akış inşa edildiği gün kapı ZORUNLU |
| ⑦ | `onHold` gerekçesiyle görünür | ✅ | Hula kataloğa dahil + gerekçesi zorunlu (3 ayrı test) |

**Sınıf dağılımı: 6 kapıda · 1'i sınıf ③.** Sınıf ① (meşru hâli var) ve ② (kural
kendi ölçütünü geçemiyor) bu listede yok — yani ⑥ bağlanabilir hâle geldiğinde
**tek açık kalem** olarak duruyor, unutulacak bir kuyruğun içinde değil.

## 🧱 KATMAN kapsamı (C-169)

**Kapı yazarken ilk soru *"hangi kelimeler"* değil, *"hangi KATMANLAR"*.**
İçerik iki katmanlı (`library.json` + `style.json`/`steps/*`), ve
`content_claims_test` **yalnız birincisini** okuyordu — ikincide 53 parça
kullanıcı metni hiç denetlenmemişti.

⚠️ **Ve kurallar katmandan katmana TAŞINMIYOR.** İkinci katmanı kütüphane
kurallarıyla taradım: **16 eşleşme, hepsi MEŞRU.** *"we check HOW you do the
step"* bir dürüstlük bloğunda doğrudur — o bloğun konusu zaten **bizim ne
yaptığımız**; *"(not graded)"* bir ders başlığında doğrudur. `we` yasağı stil
**tanıtımları** için yazılmıştı, çünkü onlar **dansı** anlatır.

Kuralları sorgulamadan taşımak kapının **bulgu ÜRETMESİ** demektir — caveat
enflasyonunun kardeşi, ve o 16 sahte bulgu, gerçekten geçerli olan tek kuralı
(vaat dili, her katmanda) gömerdi.

| Katman | Denetlenen | Kural |
|---|---|---|
| `library.json` tanıtım | dansı anlatır | `we` YASAK · teslim-fiili YASAK · hüküm sözcüğü özneli |
| `library.json` cameraLimits | sınırı anlatır | mekanizma vaadi YASAK · yetenek iddiası YASAK · **kalıplaşma YASAK** (C-168) |
| `style.json` honesty/reason | **bizim ne yaptığımızı** anlatır | birinci şahıs DOĞRU · vaat dili YASAK · `whyPermanent` ↔ `demoOnlyClass` çelişemez |

## ⚠️ Envanterin KENDİ yanlış pozitifi (düzeltildi)

İlk sürüm `pin_equality_test`'i *"korumasız regex"* diye işaretledi. **Yanlıştı:**
o dosya `isNotEmpty` yerine **`isNotNull`** kullanıyor ve ayrıca bir pozitif
ikizi var — benim otomatik taramam yalnız üç kalıba bakıyordu.

İki kez aynı şey oldu bu gece: burada, ve yayın envanterinde yorumdaki
`content's own unlock rule` apostrofunu string sanan tarama. **Ders: envanter
çıkarmak için yazılan tarama da bir kapıdır ve onun da kapsamı yazılmalıdır** —
yoksa envanter, olmayan bulguyu rapor eder ve gerçek olanı kaçırır.

Düzeltme yolu ikisinde de aynı oldu: **taramayı okuyup doğrula**, taramaya
güvenme.

## ⛔ Envanterin kendi sınırı

Bu envanter **benim bildiğim** kapıları listeler. *"Hangi kapıyı hiç kurmadım"*
sorusunu cevaplamaz — onu ancak bir yüzey turu veya başka bir hattın aktarımı
cevaplar. Bu gecenin beş aktarımının beşi de bende gerçek kusur buldu, ve
hiçbirini kendim aramamıştım.
