# G1(c) — Stil-Başına Müfredat Maliyeti: Ölçüm Raporu

**Tarih:** 2026-07-26 · **Statü:** ölçüm tamam, iki bulgu V1 hedefini etkiliyor
**Kapı sorusu (roadmap G1.4):** *"1 stilin tam müfredatını üretme eforu ölçülür → 2-stil V1 bütçesi gerçekçi mi?"*

## Yöntem

Tahmin yerine **gerçekten üretildi**: şema yazıldı, iki stilden birer adım **uçtan uca** tanımlandı (faz makinesi + skorlanan anlar + ölçülebilir hata kodları + eklem odağı), iki `style.json` yazıldı, ve içerik bütünlüğünü çekirdek sözleşmesine karşı denetleyen doğrulayıcı kuruldu ve **geçti**.

Üretilenler: `content/SCHEMA.md` · `hip_hop_foundations/{style.json, steps/hh_bounce.json}` · `salsa_shines/{style.json, steps/ss_basic.json}` · `tools/validate_content.py` (4 dosya denetlendi, 0 hata).

## Adım-başına maliyetin bileşenleri

| Bileşen | Gözlenen maliyet | Not |
|---|---|---|
| 1. **Hareket tarifi** (vücut beat-beat ne yapıyor) | **belirsiz — çoğu adımda YOK** | Asıl darboğaz, aşağıda |
| 2. Faz makinesi (4-8 faz) | düşük | Tarif varsa mekanik iş |
| 3. Skorlanan anlar (beat eşlemesi) | düşük | Sayım sisteminden türüyor |
| 4. **Ölçülebilir hata kodları** (4-5) | orta | Her hata landmark koşuluna bağlanmalı |
| 5. Odak/serbest eklem ayrımı | düşük | Ama ürün dürüstlüğü açısından kritik |
| 6. **Referans takeleri** (6 video × çıkarım + elle beat/faz anotasyonu) | **yüksek, tekrarlı** | Asıl hacim maliyeti |

**Ölçümün ana sonucu: 2-5 arası kalemler ucuz. Pahalı olan 1 ve 6.** Adım tanımı yazmak, tanımı *bilmek* kadar zor değil.

---

## Bulgu 1 — Hip-hop hata taksonomisi kullanılamaz durumda ⛔

R1'in bu stil için topladığı 7 "yeni başlayan hatası" **pedagojik öğüt, gözlemlenebilir form hatası değil**:

> *"temelleri atlayıp erken koreografiye geçmek" · "sabırsız olmak" · "müziği kafayla analiz etmek" · "düzenli ev pratiği yapmamak"*

Bunlar doğru olabilir ve **ders metnine** girer, ama hiçbiri kameradan görülemez. `errors[]` girdisi landmark'tan ölçülebilir bir koşula bağlanmak zorundadır (`SCHEMA.md`), dolayısıyla bu stilin hata taksonomisi **sıfırdan kurulmalı**.

Karşılaştırma: R1 salsa'yı hata taksonomisinde 5/5 puanladı (8 hata, güçlü kaynak çeşitliliği) ve o malzeme gerçekten kullanılabilir çıktı — `ss_basic`'in beş hata kodu oradan türetilebildi.

`hh_bounce`'ın dört hata kodu (`NO_BOUNCE`, `BOUNCE_INVERTED`, `TRUNK_COLLAPSE`, `ASYMMETRIC_BOUNCE`) araştırmadan değil, hareketin biyomekaniğinden yazıldı.

## Bulgu 2 — Salsa'nın vokabüleri V1 hedefini karşılamıyor ⚠️

Plan §24 stil başına **≥8 adım + ≥4 kombo** istiyor. Ama R1 salsa shines için **4 çekirdek shine** buldu (biri Suzy Q), üstelik ikisi tek tek isimlendirilmemiş.

Yani salsa'da V1 hedefi ya karşılanmıyor ya da vokabüler zorlanarak şişirilir — ikincisi, "gerçek adımları öğret" vaadine aykırı.

**Öneri (kurucu kararı):** salsa için hedefi **basic + 4 shine + 3 varyasyon** olarak yeniden tanımla, ya da eksiği kombolarla kapat (4 shine'dan üretilen kombo sayısı adım sayısından hızlı büyür). Mimari değişmiyor; değişen yalnız V1 tamamlanma kriterinin sayısı.

## Bulgu 3 — Ölçülebilirlik filtresi gerçek bir kısıt, kozmetik değil

R1'in CV-risk analizi doğrudan üç adımı V1 dışına attı:

| Adım | Neden Tier C |
|---|---|
| Harlem Shake | Omuz izolasyonu — düşük genlikli tek-segment, poz modellerinin belgelenmiş zayıf alanı |
| Running Man | Ayak-zemin temas zamanlamasına dayalı illüzyon; ayak ucu markerless tek kamerada en düşük güvenli noktalardan |
| Happy Feet | Aynı — hızlı ayak sürtme, ayak-ucu bağımlı |

Şema bunu **zorunlu kılıyor**: Tier C adım seviyelere alınamaz, doğrulayıcı reddeder. Ölçemediğimiz bir şeyi öğretip skorlamak, "düşük güvende hüküm yok" kuralının içerik seviyesindeki ihlali olurdu.

Kalan 17 hip-hop adımının tier'ı **"unknown"** olarak işaretlendi — hareket tarifi olmadan tier atamak, kararmış gibi görünen bir tahmin olurdu.

---

## V1 bütçesi — gerçekçi mi?

**Evet, ama şu şartla:** darboğaz adım *yazmak* değil, (a) hareket tarifi araştırması ve (b) referans take anotasyonu.

Hacim hesabı, stil başına 8 adım hedefiyle:

- **8 adım × 6 referans take = 48 video** çıkarım + kalite kapısı + **elle beat/faz anotasyonu**
- İki stil için **96 anotasyon**

Beat anotasyonu videodan gelmiyor (C-019e) — bu sayı, otomatikleştirilmediği sürece V1'in gerçek takvimi. **Anotasyon aracı, referans hattının kendisinden daha kritik.**

## Sıradaki iş (bu oturum devam edebilir)

1. **Hip-hop hareket tarifi araştırma turu** — 17 adım için beat-beat biyomekanik tarif + gözlemlenebilir hata listesi. Tier ataması bunun çıktısı.
2. **Salsa ikinci tur** — isimlendirilmemiş 2 çekirdek shine.
3. **Anotasyon aracı** — 96 elle anotasyonu yönetilebilir kılacak tek şey.
4. `hh_rock`, `hh_groove`, `ss_suzy_q` yazımı (tarif var/kısmen var).

## Kurucuya

- **Salsa V1 adım hedefi** (Bulgu 2) — 8'de ısrar mı, yeniden tanımlama mı?
- Hip-hop hata taksonomisi sıfırdan kurulacak (Bulgu 1) — ek bir araştırma turu demek, plan bunu öngörmüyordu.
