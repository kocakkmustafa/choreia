# R14 — `ballet_barre` plié aday havuzu (2026-08-11)

**Bu not hasat SONUÇLARINDAN ÖNCE yazıldı** (R13'ün disiplini): hangi adayın
hangi riski taşıdığı burada ÖNCEDEN kayıtlı, hasat bitince bu tabloya karşı
okunacak — gerekçeyi sonucu gördükten sonra aramak post-hoc olurdu.

**Bu tur yalnız ARAMA + TRİYAJ.** İndirme/çıkarım/hasat YAPILMADI —
`tools/harvest.py`'nin `CANDIDATES` sözlüğüne henüz hiçbir id eklenmedi.
Sıradaki adım `probe_candidates`/`harvest.py --probe`, sonra `--fetch`.

## Neden bu adım, ve neden şimdi

`ballet_barre` bugün `content/styles/ballet_barre/` dizini bile taşımıyor —
`library.json`'daki `originAttribution`/`description`/`stepGlossary`/
`cameraLimits` yazılı (33/34 sayımının parçası) ama hiçbir `steps/*.json` yok.
Stilin beş adlı hareketinden **plié** seçildi, keyfi değil: `enter.metric`
dispatch'i (C-207) `knee_flexion_mean` ailesini (diz açısı, tek eklem seti,
`hh_bounce`'ta ZATEN doğrulanmış aynı mekanizma) genellikleştirdi ve bu tam
olarak pliénin KENDİSİ — diz bükülüp açılan bir çevrim. Yeni içerik yeni bir
sürücü icat etmeden, ölçülmüş bir ailenin ikinci gerçek kullanıcısı olabilir.

## Metadata triyajı (indirme ÖNCESİ, `yt-dlp --dump-json` ile GERÇEK ölçüldü)

| video | karar | kanal | süre | not |
|---|---|---|---|---|
| `ON8ptc6ymF0` | ADAY | By Carol and Ariel | 342s | saf plié |
| `k70uyYKlIU0` | ADAY | Everyday Ballet | 673s | saf plié |
| `wdhihrgXGYI` | ADAY | Dance Connection (kids) | 275s | saf plié, hedef kitle çocuk — hareket aynı, ton farklı |
| `27skzncX3Ms` | ADAY | Ballet Science | 702s | saf plié + yaygın hata düzeltmeleri |
| `wwXH3fFdtog` | ADAY — VARYANT | Stardust Dance Academy | 343s | başlık demi-plié VE grand-plié'yi birlikte adlandırıyor |
| `I3aP1J-xH7c` | GÖZDEN_GEÇİR — DERLEME | Natalie Danza | 403s | başlık plié VE tendu'yu birlikte adlandırıyor — farklı adım |
| `bhm-Mek3Qws` | ŞÜPHELİ | "Haynes Manuals" | 44s | kanal adı OTOMOTİV TAMİR kitaplarıyla anılıyor, dans kanalı değil gibi görünüyor; süre de bir çevrimi güvenle tekrar ettirmek için kısa. Ret DEĞİL — ölçülmeden kimlik iddiası yapılamaz — ama hasat sırasında EN SON denenecek |
| `JubuC3Lh1i4` | ELENEMEDİ: sebep ÖLÇÜLMEDİ | — | — | `yt-dlp --dump-json` boş/parse edilemez yanıt döndürdü. **Düzeltme (koordinatör):** "kaldırılmış" diye yazmıştım, bu ÖLÇÜLMEDİ — boş dönüşün en az dört olası sebebi var (kaldırılmış · bölge kilidi · hız sınırı · araç hatası) ve hiçbiri ayırt edilmedi. Sebep ölçülmeden ne en kötü (kaldırılmış) ne en iyi okuma varsayılmaz — bir sonraki tur bunu "ölü link" sanıp atmasın |

**7 potansiyel aday / 7 AYRI kanal** (`bhm-Mek3Qws` ve `JubuC3Lh1i4` hariç
tutulsa bile 5 saf aday, 5 ayrı kanal — R13'ün "≥3 bağımsız eğitmen" barını
rahatça geçiyor). Sayım birimi eğitmen; bu turda hiçbir kanal ikinci kez
saymadı.

## Varyant-kimliği taraması (M-F-175 sınıfı) — ÖNCEDEN kaydedilen risk

| video | başlığın iddiası | risk sınıfı | hasat sonrası ne kontrol edilecek |
|---|---|---|---|
| `ON8ptc6ymF0` | "How to do a Plié" | **saf** | — |
| `k70uyYKlIU0` | "BALLET BASICS: How to PLIÉ" | **saf** | — |
| `wdhihrgXGYI` | "Ballet Basics: How to do a Demi-Plie" | **saf (alt-tür adlı)** | seçilen segment demi-plié mi, yoksa grand-plié'ye mi kayıyor |
| `27skzncX3Ms` | "Plie \| Tips For Ballet Technique" | **saf** | — |
| `wwXH3fFdtog` | "Demi-Plié & Grand Plié" | **varyant** | segment HANGİ varyantı gösteriyor — ikisi diz genlik/derinliğinde ayrışabilir, `knee_flexion_amplitude` tek bir referansta İKİ farklı popülasyonu karıştırabilir |
| `I3aP1J-xH7c` | "plié and tendu tutorial" | **derleme** | segment plié mi tendu mu (tendu bir DİZ ÇEVRİMİ değil — ayak sıyırma, ayrı bir aile) |

**Hasat sırası (koordinatör onaylı, KANITA dayalı):**
1. 5 saf plié: `ON8ptc6ymF0` → `k70uyYKlIU0` → `27skzncX3Ms` → `wdhihrgXGYI`
2. varyant riski: `wwXH3fFdtog` (demi+grand birlikte adlandırılmış)
3. derleme riski: `I3aP1J-xH7c` (plié+tendu birlikte adlandırılmış)
4. kimliği şüpheli: `bhm-Mek3Qws` — **ret DEĞİL, ölçülmemiş bir şüphe eleme
   gerekçesi olamaz; şüphe bir SIRALAMA gerekçesidir** (koordinatör). Kanal
   adı otomotiv-tamir kitaplarıyla anılıyor, 44s kısa — kanıt değil, sıra
   sonuna koymanın gerekçesi.
5. `JubuC3Lh1i4` — elenemedi, sebep ÖLÇÜLMEDİ (yukarı bakınız)

Kesinti olursa elde kalan ilk üç yine ≥3 bağımsız eğitmen eder.

## Kimlik doğrulaması nasıl yapılacak (ölçü, izlenim değil)

`ballet_barre` henüz `measurability.tier` beyan etmiyor (adım config'i hiç
yazılmadı) — bu R14'ün kapsamı DEĞİL, hasat sonrası ölçülüp yazılacak.
Kimlik testi C-207'nin genelleştirdiği yoldan gelir: `cycleUnit.driver =
"knee_flexion_mean"` beyan edilirse, `select_by_phase_driver()` segmenti
GERÇEKTEN diz-çöküş olayı içeren pencereden seçer (`hh_bounce` ile AYNI
mekanizma, isim değil davranış paylaşıyor). Diz fleksiyonu baskın değişken
DEĞİLSE (ör. `wwXH3fFdtog`'da segment grand-plié'ye kayarsa genlik `hh_bounce`
referansından belirgin ayrışır) bu ÖLÇÜLECEK, varsayılmayacak.

## `--probe` sonucu (koordinatör onayı, metadata-only — 2026-08-12)

`python3 tools/harvest.py --probe` koşturuldu. 7 adayın 7'si de `candidate`
verdiktiyle döndü (süre 44-702s, hepsi kullanılabilir aralıkta), **7 ayrı
kanal doğrulandı** (elle `yt-dlp` kontrolümle birebir tutarlı — sürpriz yok).
`bhm-Mek3Qws` de dahil: **reddedilmedi**, kanal adı gerçekten "Haynes
Manuals" olarak doğrulandı ama bu RET gerekçesi değil, sıralamada en sona
konmasının gerekçesi (koordinatör: *şüphe bir sıralama gerekçesidir, eleme
gerekçesi değil*). Çıktı `harvest/probe.json`'a yazıldı (gitignored, ürün
deposunun parçası değil).

## Sınır — bu turda YAPILMAYAN

- Hiçbir video indirilmedi, hiçbir landmark çıkarılmadı (`--fetch` koşulmadı).
- Eşik icat edilmedi, `ballet_barre` için hiçbir `steps/*.json` yazılmadı.
- `bhm-Mek3Qws`in kimliği (gerçekten bir dans kanalı mı, tek video mu çok
  video mu) ölçülmedi, yalnız kanal ADI doğrulandı — hasat sırasında EN SON
  denenip, düşerse havuzdan sessizce değil İSİMLE çıkarılmalı.
- `JubuC3Lh1i4` `CANDIDATES`e hiç eklenmedi — aday değil, elenemedi.
