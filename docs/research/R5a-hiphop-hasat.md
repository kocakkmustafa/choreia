# R5a — Hip-Hop Foundations: Hasat Fizibilitesi

**Tarih:** 2026-07-26 · **Kaynak:** araştırma ajanı ham teslimi (sentez oturumda yapıldı)
**Soru:** Aynı adımı öğreten **≥3 bağımsız eğitmen** videosu bulunabiliyor mu? — tüm referans yaklaşımının dayandığı varsayım.

> ⚠️ **Bu dosyanın kanıt sınırı:** araştırma aracı **video izleyemez**. Kanal listeleri ve URL'ler doğrulanmıştır; *yavaş-tempo öğretim* ve *kamera kurulumu* bulguları başlık/format çıkarımıdır, görsel teyit DEĞİLDİR. İkisi de zaten **pilotta ölçümle** kapanacak (`camera_angle_gate.py`) — daha fazla araştırmayla değil.

## HÜKÜM: ✅ ≥3 bağımsız eğitmen bulunabiliyor (rahatlıkla)

Örneklenen 3 adımın üçünde de 4-5+ bağımsız kaynak çıktı.

| Adım | Bağımsız kaynak | Kanallar |
|---|---|---|
| **Roger Rabbit** | **5** | STEEZY · James Deane · Howcast (Chi-Chi Smith) · "Rosa" · +1 |
| **Running Man** | **≥4** | STEEZY · Howcast · Dance Moves In Minutes · +1 |
| **Cabbage Patch** | **≥5** | STEEZY · V Company · Minute Moves · Howcast · +1 |

⚠️ Tek dikkat: "Rosa" markalı seri hem Roger Rabbit hem Running Man'de göründü (aynı kişi olabilir) → `channel.independent` alanında tek kaynak sayılmalı. Düşülse bile eşik rahat karşılanıyor.

⚠️ Kalan 17 adım **tek tek doğrulanmadı** — örneklem güçlü olumlu sinyal veriyor ama adım-başına doğrulama hasat sırasında yapılacak.

## Pilot için aday URL'ler

**Roger Rabbit:** `steezy.co/posts/how-to-do-the-roger-rabbit` · `watch?v=bdY2Pwqj-9A` (James Deane) · `watch?v=pua9UszdO24` (Howcast) · `watch?v=DEFnniCN7ok` · `watch?v=blWeCJW2Peo`
**Running Man:** `steezy.co/posts/how-to-do-the-running-man` · `watch?v=lYpRasK4c9k` (Howcast) · `watch?v=k22Bm2pMyD4` · `watch?v=UO9Ehsdt2IE`
**Cabbage Patch:** `steezy.co/posts/how-to-do-the-cabbage-patch` · `watch?v=0iweU5HmAUQ` (V Company) · `watch?v=V6w_9vWXXjE` (Minute Moves) · `watch?v=N4STZCPuhf0` (Howcast) · `watch?v=EUuqLa1oqo8`

> **Not:** Running Man Tier C (ayak-ucu temas zamanlaması) olarak elenmişti — pilot için yine de değerli, çünkü **kalite kapılarının bir Tier C adımı nasıl gördüğünü** ölçmek istiyoruz.

## Adım envanteri — üçüncü bağımsız kaynakla doğrulandı

20 adımlık iampro listesi, FraGue Moser-Kindler'ın bağımsız "Hip-Hop Move List" kaynağıyla (`frague.at/hip-hop-move-list/`) çapraz kontrol edildi: **20/20 birebir örtüşüyor.** Yeni adım yok; envanter artık üç bağımsız kaynağa dayanıyor.

Ek değer: kaynak her adım için tarihsel öncüyü de veriyor — Roger Rabbit→Buddha Stretch · Cabbage Patch→Suga Pop · Smurf→Buddha Stretch & Mr. Wiggles · Monastery→Yuljah · Steve Martin/Janet Jackson→Marcio Ratinho. (Atıf ve ders metni için değerli; telif açısından değiştirmiyor — adımlar korunmuyor.)

## Kanal envanteri

| Kanal | İçerik tipi | Not |
|---|---|---|
| STEEZY Studio | Karışık: "Hip Hop Classes" + Bianca Vallar "Grooves" (günlük 10dk temel gruv) | Üç adımın üçünde de var |
| Howcast (Chi-Chi Smith) | **Tek-adım "How to Do the X" serisi** | Cabbage Patch + Running Man + Roger Rabbit + Reebok + Bart Simpson kapsıyor — hasat için en verimli tek kaynak |
| James Deane | Bağımsız koreograf, 15+ yıl, tek-adım tutorial | |
| V Company / Minute Moves | Numaralı "Dance Tutorial No.N" serisi, old-school odaklı | İki ayrı marka |
| DanceWithCeech | Tek-adım (Bart Simpson) | |
| MihranTV | Kısa tutorial + "absolute beginners" playlist | |
| Matt Steffanina | Ağırlıklı uzun şarkı-koreografisi | **Yeni bulgu:** tutorial'lar AYRI kanalda ("Dance Tutorials LIVE") |
| 1MILLION Dance Studio | Uzun K-pop/şarkı koreografisi | Klasik tek-adım içerik görülmedi |
| Yak Films | Performans/freestyle — **tutorial DEĞİL** | Hasat için uygun değil |

## Bağımsızlık durumu — ürün için iyi haber

İçerik **1-2 ajansta yoğunlaşmamış**, ve ayrışma tam da işimize yarayan yerden geçiyor:

- **"Groove" çerçevesi** büyük stüdyolarda (STEEZY, 1MILLION) — çoğu K-pop-etkili şarkı koreografisi. STEEZY'nin kendi tespiti: *birçok stüdyo hareketler temel gruvlara dayanmasa da "Hip Hop" terimini kullanıyor.*
- **"İsimli klasik adım" çerçevesi** bağımsız kanallarda baskın (Howcast, James Deane, V Company, Minute Moves, DanceWithCeech).

V1 müfredatı isimli klasik adımlara dayandığı için, hasat doğal olarak **bağımsız kanallara** düşüyor — `channel.independent` kuralı (C-025) zorlanmadan karşılanıyor.

## DOĞRULANAMAYANLAR

1. Hiçbir kanalın **güncel (2026) abone sayısı** — YouTube kanal sayfaları JS-render nedeniyle WebFetch'le okunamadı (araç kısıtı, veri yokluğu değil). Sayılar arama-motoru toplayıcılarından; Social Blade/vidIQ doğrudan fetch'te 403/402 verdi.
2. Matt Steffanina'nın iki kanalı arası abone bölünmesi (kaynaklar çelişkili: 13.4-15.2M vs 3-3.95M).
3. **Hiçbir kanalın CC-lisans kullanımı** — kanıt yok; muhtemelen standart lisans ama video-video kontrol edilmedi.
4. **Yavaş-tempo öğretim** — dolaylı kanıt tutarlı (MihranTV'nin "Slow Motion Walk" tutorial'ı, STEEZY'nin kademeli Grooves serisi, "STEP 1, ROGER RABBIT" tarzı numaralı format) ama **görsel teyit yok**.
5. **Kamera kurulumu** — tür-geneli kaynaklara göre standart sabit tripod/tam vücut/önden; büyük prodüksiyonlar muhtemelen çoklu-kamera. **Mantıksal çıkarım, ölçüm değil.**
6. Kalan 17 adımın ≥3-eğitmen testi.

**4 ve 5, pilotun `camera_angle_gate.py` ve segment-seçim adımıyla ölçümle kapanacak** — bunlar için ek araştırma turu gerekmiyor.
