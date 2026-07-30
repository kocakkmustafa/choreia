# R12 — Ayna belirsizliğinin ATIFI: RM ve RR (2026-07-30)

**Durum: ÖLÇÜM TAMAM, KARAR KOORDİNATÖRDE.** Bu not bir dışlama önermiyor; dışlama
kararının gerektirdiği kanıtı ölçüyor ve **kanıtın yetersiz kaldığı yeri de** yazıyor.

## Soru

Salsa'da ayna belirsizliği tek kaynağın ithalatı çıktı (`bqoNqA2hmE4` dışlanınca
`mirrorConfident: TRUE`, Choreia'da ilk). Aynı desen RM ve RR'de var mı?

## Yöntem ve neden aritmetik YETMEZ

Yayımlanmış `margin` değerleri **tüm** take'leri içeren uzlaşmaya karşı hesaplanıyor.
Bir kaynak çıkınca uzlaşma kayar ve kalan her take'in marjı değişir. Dolayısıyla
"4 take'ten 3'ü belirsiz, birini atsam 2 belirsiz kalır" çıkarımı **geçersizdir**.
Tek-çıkarma (leave-one-out) gerçekten koşuldu (`prepare_take` çıktıları üzerinden,
yeni çıkarım YOK — hasat sırası o gün Lissom'daydı).

## Sonuç 1 — RM: desen VAR

| Çıkarılan | mirrorConfident | yönelim etkileri |
|---|---|---|
| KV-sxd_pQ9w | false | uncertain ×3 |
| UO9Ehsdt2IE | false | uncertain ×3 |
| **Wd29rBfAzkI** | **TRUE** | **decisive ×3** |
| ZpTgAZBYNrU | false | uncertain ×2 + against_local_optimum |

`Wd29rBfAzkI` dışarıda kalınca `statusBases` **3 → 1**'e düşüyor:
`mirror-ambiguity` çözülüyor, `thin-evidence` çözülüyor (çevrimler 5/5/12, hepsi
`MIN_CYCLES_PER_TAKE=5` üstünde), geriye yalnız `source-count-below-target` kalıyor
— ve o **kötüleşiyor**: 4 → 3 kaynak, `MIN_TAKES=3` tam sınırda, `PREFERRED_TAKES=6`
daha uzakta. Yani bu bir iyileştirme değil, bir **ödünleşim** → hüküm.

## Sonuç 2 — RR: çözüm yolu YAPISAL OLARAK KAPALI

3 kaynak var, `MIN_TAKES=3`. Herhangi birini çıkarmak referansı kurulamaz yapar.
Bu bir seçim değil **havaz darlığı**; tek çıkış yolu HASAT. Salsa'daki reçete
burada uygulanamaz — denemek bile mümkün değil.

## Bağımsız kanıt envanteri (Wd29rBfAzkI)

Sert kural: dışlama daima İSİMLİ + BAĞIMSIZ gerekçeli; **uyuşmazlık gerekçe
değildir.** "Çıkarılınca ayna düzeliyor" tam olarak uyuşmazlık gerekçesidir ve
tek başına KULLANILAMAZ. Bağımsız hatlar:

1. **`cyclesInSegment = 2`**, hattın kendi `MIN_CYCLES_PER_TAKE = 5` eşiğinin
   altında. Bu ölçüm ayna sorusundan önce ve ondan bağımsız yapılmıştı
   (`thinEvidence: true` olarak zaten beyan ediliyordu).
2. **`bestDeg = 39.262°`**, diğer üçünün `18.816 / 20.166 / 20.826` bandına karşı
   ~1,9 katı. En iyi yönelimdeki uzaklık olduğu için ayna KARARINDAN bağımsız.

### Kanıt hijyeni — iki uyarı, kendi aleyhime

- **(2) YENİ bir ölçüm DEĞİL.** `39.262` sayısı 4-kaynaklı artefaktın
  `mirrorResolution[2].bestDeg` alanında **zaten yazılıydı**. Bağımsız bir yoldan
  yeniden türetip aynı sayıyı bulmak doğrulamadır, ama bunu ikinci bir kanıt gibi
  saymak tek kanıtı ikiye katlamış gibi göstermek olur. Asıl bulgu şu:
  **kanıt artefaktta duruyordu ve okunmadı.** ("Yazılmış ama okunmamış alan",
  kaybolan alanın kardeş arıza kipi — `reference_keyset_gate` alanın VARLIĞINI
  ölçüyor, OKUNDUĞUNU ölçemiyor.)
- **Argüman POST-HOC.** Gerekçeyi ayna sonucunu GÖRDÜKTEN sonra aradım. İki hat da
  önceden mevcuttu, ama salsa emsalinde **dört** bağımsız hat + `movement-science-advisor`
  ikinci gözü + koordinatör hükmü vardı. Buradaki kanıt o eşikte DEĞİL.

### Kullanılamayan ölçüt (negatif bulgu)

`periodicity = 0.570` cazip görünüyor ama **ölçüt olarak kullanılamaz**: salsa
referansı — `mirrorConfident: TRUE` dediğim referans — `0.554` ve `0.572`
periyodiklikli kaynaklar taşıyor. Burada eşik gibi davranmak çifte standart olur.

`corePin` hipotezi de elendi: 10 take'in **hepsi** `motion_core-v0.5.0`, bayat-pin
ayrışması yok.

## Koordinatöre giden soru

RM'de `Wd29rBfAzkI` dışlanmalı mı? Ödünleşim: `mirror-ambiguity` + `thin-evidence`
kapanır, `source-count-below-target` kötüleşir (4→3, minimum sınırında). Kanıt iki
hat, biri artefaktta zaten yazılıydı, argüman post-hoc. Alternatif: **hasat** —
5. RM kaynağı gelirse hem dışlama gerekmez hem kaynak sayısı iyileşir.

RR'de karar YOK: yapısal, yalnız hasat.
