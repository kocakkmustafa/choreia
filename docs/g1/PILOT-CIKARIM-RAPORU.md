# G1 — Referans Çıkarım Pilotu: Ölçüm Raporu

**Tarih:** 2026-07-26 · **Adım:** `hh_cabbage_patch` (Tier A) · **Statü:** hat uçtan uca çalıştı, üç bulgu planı etkiliyor

## Ne yapıldı

Gerçek kamu videolarıyla uçtan uca: sonda (metadata) → indirme → landmark çıkarımı → kalite kapıları. Kurucu direktifi M-F-13..16'nın "referans çıkarımına BAŞLA" maddesi.

| Aşama | Sonuç |
|---|---|
| Sonda (indirmesiz) | 11/11 aday video canlı; 3 adımın üçü de ≥3 **bağımsız kanal** kriterini geçiyor |
| İndirme + çıkarım | 3/4 take çıkarıldı (~15.700 kare) |
| Provenance | Her fixture'a yazıldı; `recordingMeta` dürüst "unknown"larla değiştirildi |
| Medya silme (C-024) | Başarılı çıkarımdan sonra otomatik |

## Bulgu 1 — Sentetikte doğrulanmış olmak, doğrulanmış olmak değildir ⛔

Kamera açısı kapısı **7/7 sentetik senaryoyu geçmişti**. Gerçek veride **ayrım yapamadı**: üç takenin üçünü de reddetti, median yaw 30-46°.

Sebep, sezgiselin kendisiydi. Omuz-genişliği/gövde-uzunluğu oranı yaw'ı ölçüyor sanılıyordu; gerçekte üç şeyle karışıyor: **gövde eğilmesi** (payda foreshortening'e uğruyor), **kadraj/zoom değişimi**, ve en kötüsü **dansın kendi dönüşü** — ki o hata değil, sinyal.

Sentetik veri tam da bu üç karıştırıcıyı içermediği için testler geçmişti.

**Çözüm ölçüldü:** MediaPipe **world landmark**'ları (gövde-merkezli metrik 3D). Omuz çizgisi üç boyutta ölçülüyor, foreshortening'den çıkarsanmıyor.

| Take | Görüntü-düzlemi (en iyi 6sn) | **World 3D (en iyi 6sn)** |
|---|---|---|
| Howcast | 21.8° | **10.3°** ✅ |
| V Company | 57.7° | 57.9° ❌ |

Görüntü-düzlemi kanalı ikisini de ellilerde skorlayıp **ayırt edemiyordu**; world kanalı gerçekten fronto-paralel olanı buluyor. World artık birincil kanal.

## Bulgu 2 — Segment bulucu, en pahalı elle adımı otomatikleştiriyor ✅

Tüm videoyu kapıdan geçirmek **yanlış soruydu**. Tutorial'da eğitmen konuşuyor, yandan gösteriyor, dönüyor, kesme var — tam-video hükmü yalnızca "bu bir tutorial" der.

Kapı bir filtreden **segment bulucuya** çevrildi: kayan pencere, world-yaw p90'ı eşikte olan aralıkları döndürüyor.

| Take | Kanal | Kare | Bulunan pencere |
|---|---|---|---|
| Howcast | — | 3252 | **3** — en iyisi **22.3s @ 12.1°** |
| MahaloDance | — | 10463 | 1 — 17.8s @ 10.0° |
| V Company | — | 1968 | 0 — baştan sona eğik |

3.5 dakikalık bir tutorial'ın içindeki 22 saniyelik kullanılabilir bölümü **elle aramadan** buldu. C-027'de "araç kolaylaştırmazsa maliyet buradan patlar" dediğim adım buydu.

## Bulgu 3 — Hasat verimi ~%67, bu bir planlama sayısı 📊

**3 taken 2'si** kullanılabilir segment içeriyor. Bir adım için **≥3 kullanılabilir** take gerektiğine göre, ham hasat hedefi **adım başına ~5 video** olmalı.

Bu, önceki 8 adım × 6 take = 48 tahmininin yerine geçer: **8 adım × 5 ham → ~40 indirme, ~27 kullanılabilir take/stil.**

## Bulgu 4 — Çıkarım hattı hasat için tasarlanmamış (M-C-13)

`extract_landmarks.py`, dosya adından stüdyo metadatası türetiyor (`light=bright|dim`, `clothing=tight|loose`, mesafe santim). Hasat videosunda hiçbiri bilinmiyor ve **uydurmak eşik kalibrasyonunu zehirler** — kalibrasyon tam da bu alanlara göre gruplanıyor.

Geçici çözüm: şema-uyumlu geçici adla çağır, çıktıdaki `recordingMeta`'yı dürüst provenance ile **değiştir**. Çekirdek döngü kopyalanmadı. İkinci tuzak: çıkarıcı **klasörün tamamını** işleyip uyumsuz komşuya takılırsa sıfır-dışı dönüyor → video başına izole klasör gerekti.

## Sırada

1. Kalan iki adımın (Roger Rabbit, Running Man) hasadı — Running Man Tier C, **kapıların bir Tier C adımını nasıl gördüğünü** ölçmek için değerli.
2. Bulunan segmentlerde **beat anotasyonu** (≥16 vuruş) → ilk gerçek `CanonicalReference`.
3. `ReferenceBuilder` konsensüsünü **gerçek** takelerle koştur — aynalama kararı ve eğitmen-varyansından türeyen tolerans ilk kez sentetik olmayan veriyle.
