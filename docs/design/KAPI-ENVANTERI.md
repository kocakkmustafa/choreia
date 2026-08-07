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
| `pin_equality_test` | İki paketin tek ref'ten geldiği | — | ⚠️ **Bu envanterin açık kalemi:** regex tarıyor ama boş-değil koruması yok; ref deseni değişirse iddia vakum-doğru olabilir | kod |

---

## ⛔ Envanterin kendi sınırı

Bu envanter **benim bildiğim** kapıları listeler. *"Hangi kapıyı hiç kurmadım"*
sorusunu cevaplamaz — onu ancak bir yüzey turu veya başka bir hattın aktarımı
cevaplar. Bu gecenin beş aktarımının beşi de bende gerçek kusur buldu, ve
hiçbirini kendim aramamıştım.
