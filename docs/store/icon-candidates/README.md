# Choreia mağaza simgesi adayı — 2026-09-24

Kurucu, aynı dansçının art arda iki pozunu gösteren **Hareket izi** görselinin son özenli yeniden çizimini seçti. Seçilen kaynak `motion-trace-dancer-selected-reference-1254.png` dosyasıdır (SHA-256: `90c12f2a184584f5b2f797759f719eda9cf5814f9f9478df675af84a4f82f4da`).

| Dosya | Kullanım |
|---|---|
| `motion-trace-dancer-selected-reference-1254.png` | Seçilen, opak RGB kaynak görsel (1254 × 1254) |
| `motion-trace-dancer-rounded-preview-1254.png` | Dört dış köşesi yaklaşık %9 yumuşatılmış, saydam köşeli önizleme |
| `motion-trace-dancer-App-Store-1024.png` | Kare ve opak 1024 × 1024 mağaza adayı |
| `motion-trace-dancer-Google-Play-512.png` | Kare ve opak 512 × 512 mağaza adayı |

Yuvarlatılmış önizleme, seçilen kaynak görsele yalnız alfa maskesi uygulanarak üretildi. Alfa kapatılarak yapılan piksel karşılaştırmasında kaynakla fark **0** çıktı. Kare/opak mağaza adayları aynı kaynaktan küçültüldü. Seçilen simge native iOS AppIcon kümesindeki 15 ve Android mipmap kümesindeki 5 dosyaya aktarılmıştır. 2026-10-15 yerel kontrolünde iOS 1024 simgesi ile App Store adayının RGB pikselleri birebir eşleşti. Yeni binary kurulumu ve mağaza konsolu yükleme/geri okuması ayrıca doğrulanmalıdır.

## 2026-10-15 — Google Play dosya biçimi

Güncel `motion-trace-dancer-Google-Play-512.png` dosyası, [Google Play ikon şartına](https://developer.android.com/distribute/google-play/resources/icon-design-specifications) uygun 512 × 512, 32-bit RGBA PNG olarak dışa aktarıldı; sRGB etiketi taşır. Önceki RGB pikselleri birebir korundu (fark 0); alfa kanalı her pikselde 255, görünüm opaktır. Kaynak çizim, App Store adayı ve native ikonlar değişmedi. Bu yerel dosya doğrulamasıdır; mağazaya yükleme kabulü değildir.
