# Referans artefaktı — tüketim sözleşmesi

`build_reference.py` çıktısı. Bir adım için birden çok bağımsız eğitmenden
türetilmiş **uzlaşma çevrimi** ve **faz-başına tolerans** taşır.

Bu dosya artefaktı *nasıl okuyacağını* söyler. Yanlış okunursa üretilen her şey
boşa gider — özellikle `scoredPhases`, çünkü onu görmezden gelen bir tüketici
doğru dans edeni yanlış sayar.

> **Kanonik kaynak:** aile-geneli sözleşme
> `motion-core/docs/50-REFERANS-TUKETIM-SOZLESMESI.md` (M-F-46). Aşağıdaki
> kurallar oraya girdi; burada kalmalarının nedeni her birinin Choreia'da
> ölçülmüş bir gerekçesi olması. Çakışma olursa kanonik doküman kazanır.

## Alanlar

| alan | ne |
|---|---|
| `reference[eklem][faz]` | uzlaşma açısı (derece), `phaseBins` kutuya örneklenmiş çevrim |
| `toleranceDeg[eklem][faz]` | o fazda serbest bant (derece) |
| `scoring[eklem].scoredPhases[faz]` | **bool** — o fazda skorlanabilir mi |
| `scoring[eklem].coverage` | çevrimin ne kadarında skorlanabilir (0-1) |
| `scoring[eklem].verdict` | `scored` ≥%90 · `scored_partial` ≥%40 · `coached_only` |
| `mirrorResolution[]` | her take'in yönü + `margin` (düşükse yön belirsiz) |
| `disagreement[]` | eklem başına: `phase_offset` · `residual` · `mixed` |
| `status` | `provisional` ise gerekçesi `provisionalReason`'da |

## Okuma kuralları

**1. `scoredPhases` false olan fazda HÜKÜM VERİLMEZ.** Geniş bant koyup skorlamak
yeterli değil — o fazda eğitmenler birbirine uymuyor, dolayısıyla "doğru" diye
bir şey yok. Kullanıcıya o an için puan değil, olsa olsa koçluk gösterilir.

Running Man'de bu soyut değil: dizler çevrimin %75-84'ünde skorlanabilir, kalan
kısım iki tekme anı. Eklem-başına karar verilseydi (diz medyanı 6.0°) o anlar da
skorlanır ve öğrenci adımın **en zor yerinde** haksız yere yanlış sayılırdı.

**2. Hiçbir eklem tüm çevrimde skorlanmıyor olabilir — bu bir eksiklik değil.**
`coverage` alanını "veri kalitesi" gibi okuma. Dans çevrimi fazlıdır; aynı eklem
duruşta sıkı, geçişte serbesttir.

**3. `coached_only` eklem kullanıcıya GÖSTERİLİR ama PUANLANMAZ.** Running Man'de
kollar böyle (kapsam %8-31): dört eğitmen kollarını farklı taşıyor, çünkü adım
ayaklarda. "Kolun şöyle olabilir" denir, "kolun yanlış" denmez.

**4. Serbest bant ölçülen eğitmen-ayrışmasının ALTINA indirilemez** (aile
değişmezi M-F-41). Antrenörlerin kendi farkını kullanıcı hatası saymak yasak.
Artefakt `toleranceBelowDispersion` alanıyla bunu kendi içinde raporlar; boş
olmayan bir liste artefaktın bozuk olduğu anlamına gelir, sıkılaştırma fırsatı
değil.

**5. `status: provisional` ise ürün yüzeyinde kesin dil kullanılmaz.**
`provisionalReason` neyin zayıf olduğunu söyler (genelde örneklem: take başına
kaç çevrim). Provisional bir referans deneyime girebilir, ama "ustalaştın"
türü bir hüküm veremez.

**6. `mirrorResolution[].margin` düşükse (<0.03) o take'in yönü belirsizdir.**
Referans yine kurulabilir — Running Man'de belirsiz take'i çıkarmak uzlaşmayı
en az oynatan değişiklikti (0.9°) — ama yeni take eklenirken o kaydın kesin
olmadığı bilinmeli.

## Ürün yüzeyi (kanonik §4 — JabLab'dan gelen iki kural)

**7. Skor YALNIZ skorlanan eklemlerden akar; `coached_only` başlıklar seans
özetinde AYRI ve nedeniyle gösterilir.** Running Man'de kolları puana katmak
skoru gürültüyle sulandırır (kapsam %8-31); ayrı göstermemek ise kullanıcıya
"kolun ölçülmedi" bilgisini borçlu kalır. "Kollar: dört eğitmen farklı taşıyor,
bu adımda stil serbest" denir.

**8. Sesli koç ölçülmeyen şeyi İDDİA EDEMEZ.** Dansta bunun somut tuzağı
`scoredPhases=false` olan fazlar: motorun o anda bir hükmü yoktur, dolayısıyla
replik "tekmede geç kaldın" diyemez. Aynı şekilde ölçülmeyen büyüklükler
(enerji, "akış", "müzikalite") replikte geçemez — Choreia açı ve faz ölçüyor,
ifade değil.

## Faz ekseni

`phase = 0` çapadır: öncü ayağın en ayrık olduğu an (`prepare_take.py`).
Çapa aynalamaya değişmez değildir — hangi eksenden kurulduğu take'in
`anchorAxis`'inde. Uzlaşma kurulurken yön ve yarım-çevrim kayması birlikte
aranır, bu yüzden artefaktın faz ekseni tek ve tutarlıdır.

Beat ızgarasına bağlanırken: `phase` müzikal ölçüye değil ADIM ÇEVRİMİNE
görelidir. İkisinin eşlenmesi adım config'inin `beats` alanının işidir, bu
artefaktın değil.

## Tempo bağımsızlığı (doğrulandı)

Artefakt **hiçbir yerde saniye taşımaz** — `reference` ve `toleranceDeg`
`phaseBins` kutu üzerinde, yani çevrime göreli. Zaman taşıyan tek alanlar
`sources[].periodSeconds` ve `segmentSeconds`, ve onlar künyedir: hangi
eğitmenin hangi tempoda gösterdiğini kaydeder, hesaba girmez.

Bunun pratik sonucu: 150 BPM'de gösteren eğitmenle 200 BPM'de gösteren **aynı
faz eksenine** katkı verir. Ölçüldü — take'ler arası gösterim temposu 90-274
BPM aralığında değişiyordu ve uzlaşma bundan etkilenmedi.

**Tüketici için tuzak:** `phase`'i saniyeye çevirmeye çalışma. Kullanıcının
çevrim süresi kendi temposundan gelir; referansın işi o çevrimin İÇİNDE
nerede ne olması gerektiğini söylemek. Zamanlama hükmü beat ızgarasına
bağlanır, eğitmenin gösterim temposuna değil — bir eğitmen yavaşlatarak
öğretmişse bu bir stil özelliği değil, o çekimin özelliğidir.
