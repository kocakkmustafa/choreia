# CHOREIA — Tam Kapsam Blueprint (oturumun kapsam otoritesi)

**Tarih:** 2026-07-28 · **Statü:** KURUCU-ONAYLI (revizyonlu: samba/tango-sınıfı global danslar + funk styles EKLENDİ). Ortak omurga: motion-core `docs/30-URUN-BLUEPRINT-STANDARDI.md` (ÖNCE onu oku). G-1 tam planı (M-009) bu blueprint kapsamıyla yazılır.
**Nihai ürün:** "Learn to Dance" — **~30 stil**, her stil kendi sayfasında kurslarıyla; beat-senkron skorlama + sesli eğitmen; tap/flamenko gibi perküsif stillerde SES-onset skorlaması (benzersiz fark).

---

## 1. TAM KAPSAM — 5 dalga + 1 beklemede

**W1 (launch):** Hip-Hop foundations · Latin-fusion fitness dans ("Zumba" adı KULLANILMAZ — marka) · Line Dance (step-sheet formatı kural-motoruna birebir; yayımlı step-sheet kopyalanmaz, orijinal diziler) · Salsa shines · TikTok-format (orijinal kombolar).
**W2 (hızlı takip):** K-Pop point-choreo (ayna-modu) · Bachata solo · Afrobeats **+ Amapiano döner trend-paketi** (sabit müfredat değil — viral döngü) · Dancehall (Dutty Wine boyun-riski hariç) · Shuffle (≥60fps önerisi) · Belly Dance (prop'lar avatar-demo) · Bollywood (mudra = el-landmark varsa skorlu, yoksa demo) · **Merengue solo + Cumbia solo** (bachata/shines deseninin birebir tekrarı — en ucuz ekleme).
**W3 (sylabus-destekli büyük genişleme):** **Ballroom/Latin Solo Technique — TEK AİLE SAYFASI altında 7 dans: Cha-Cha, Rumba, Jive, Waltz, Quickstep, Paso Doble, Tango solo** (ISTD/WDSF Bronze→Gold seviye yapısı esin — müfredat metni telifli, figür ADLARI ve yapı esinlenilir, ORİJİNAL anlatım; önceki "Tango solo" maddesi bu ailenin içine taşındı) · **Tap Dance** (ISTD 6-seviye + 315-adım sözlüğü esinli; **PERKÜSİF ONSET SKORLAMASI** — ayak sesleri Ostinato'nun onset motoruyla puanlanır: shuffle/flap/stamp ayrımı + zamanlama; tap ayakkabısı + sert zemin onboarding'i ZORUNLU) · **Funk Styles paketi: Locking + Popping + Waacking + Vogue** (birlikte tek genişleme; Popping hit'leri RhythmEngine'e mükemmel uyum; Vogue köken-atfı: Black/Latino LGBTQ+ ballroom kültürü) · Jazz · **Samba no Pé** (karnaval solo samba; Gafieira ayrı SKU DEĞİL — ileri-stil katmanı) · **Solo Jazz/Charleston/Shim Sham** (Shim Sham = sabit 32-count rutin, DTW-dostu) · **Bhangra** (dhol ritmi RhythmEngine'e uygun; müfredat orijinal geliştirilir).
**W4:** Balet/Barre (ev-desteği modu) · Contemporary (ayakta alt-küme; yer-frazları demo-only) · **Flamenco** (zapateado = onset skorlama + palmas bonus; flamenko ayakkabısı önerisi) · **Irish Dance** (hard-shoe = onset; soft-shoe = poz+sıçrama kadraj kalibrasyonu; tek lineage seçilir) · Kizomba/Zouk solo (cambré skor-baskısız) · **Garba** (yalnız solo footwork/tef-el çırpma tekniği; **Dandiya-Raas ❌ — çift-sopa vuruşmalı, solo öğrenilemez**; sezonluk lansman-takvimi notu: Navratri) · Twerk **+ Reggaeton/Perreo aynı "duyusal-ifade" kovasında** (store-policy turu bu kovaya birlikte bakar; 3/4 kamera açısı modu).
**W5:** Heels (ayakkabı-güvenlik onboarding'i zorunlu) · Breaking (toprock/uprock skorlu; power move demo-only + güvenlik uyarısı).
**⏸ BEKLEMEDE:** Hula — hālau/kumu-hula ortaklığı OLMADAN yapılmaz (yaşayan kültürel-manevi pratik; jenerik kaynakla içerik üretimi yasak — kurucu ortaklık isterse açılır).
**Elendi (kanıt ince — "Neden yok?" gerekmez, sessiz):** Kuduro · Dabke · Yunan halk/sirtaki · Country two-step.

## 2. Bilgi mimarisi (standart §2'nin Choreia örneği)
Kütüphane → **Stil sayfası** (her stil: tanıtım + köken/atıf kutusu + adım sözlüğü + kurs listesi [Temeller · Kombolar · Rutinler] + tempo/BPM bilgisi + kişisel zamanlama-trend grafiği + hukuk/dürüstlük kutusu) → Kurs → Ders (adımı öğren [yavaş, sayımlı] → beat'siz dene → beat'le dene → skor+tek düzeltme). Ballroom ailesi tek sayfa altında 7 alt-dans sekmesi. Ortak araçlar: metronom/beat kütüphanesi, ayna-modu, tempo yavaşlatıcı (kendi beat'imizde — telif yok).

## 3. Motor iş listesi
1. Mevcut Dart çekirdek üstüne: adım-FSM + DTW hizalayıcı + beat-grid (yazıldı, 94/94) → native taşıma + G4 kalibrasyonu (C-012: kalibrasyonsuz skor gösterilmez).
2. **Perküsif-onset dans skorlaması** (tap/flamenko/Irish-hardshoe): Ostinato'nun onset motoru + beat-grid — ADIM SESİ zamanlaması puanlanır (yeni modül DEĞİL, iki mevcut modülün bağlanması; mikrofon+kamera eşzamanlı — Ostinato tek-saat sözleşmesi).
3. Ayna-modu merkezî çözümü (K6/LmMirror — kurallarda dallanma yasak).
4. Trend-paketi altyapısı (Amapiano/TikTok: içerik döner, motor sabit).
5. Sezonluk içerik zamanlayıcı (Garba/Navratri gibi).

## 4. İçerik hattı
Stil-başına ≥3 bağımsız eğitmen konsensüsü (M-C-01..04) + hukuk-katmanı bayrağı (🟢 sosyal/halk adımı · 🟡 stil-temsili orijinal kombo · 🔴 adlı ticari koreografi/marka/syllabus-metni YASAK). Beat anotasyonu ELLE (videodan gelmez — telif). Royalty-free beat kütüphanesi stil-tipik BPM aralıklarıyla (cha-cha ~30 bar/dk, jive ~44, merengue 120-140, cumbia 90-100...). Voice-pack: sayım-tabanlı EN replikler. Öğretim görseli: iskelet-avatar (ayna-modlu).

## 5. Görev backlog'u
**W0:** G-1 TAM PLAN bu blueprint kapsamıyla yaz (M-009 kapanır) + IA çatısı (~30 stil sayfası "yakında" durumlu) + platform katmanı.
**W1→W5:** dalga içerikleri (hasat→referans→config→ders→sweep→DEFTER→vault). W3 öncesi: tap-onset bağlantı spike'ı + ISTD-esin hukuk süzgeci turu. Duyusal-kova store-policy turu W4 öncesi.
**Kapanış:** kapsam-tamamlama turu + köken-atıf denetimi (her stil sayfasında).

## 6. Choreia-özel platform deltaları
Metronom/beat kütüphanesi + BPM yavaşlatıcı · ayna-modu · Lissom "dansçı ısınması" deep-link · HealthKit "Dance/Cardio Dance" yazımı · pratik-video kaydı (izinli, cihazda).

## 7. Dürüstlük/güvenlik (Choreia-özel)
"Resmî [sanatçı] koreografisi" pazarlaması YOK · groove/musicality skorlanmaz (V1: adım+zamanlama — açıkça söylenir, C-014) · tap/Irish/flamenko donanım bağımlılığı (ayakkabı+zemin) onboarding'de net · Dutty Wine/boyun-riski hareketler yok · heels/cambré güvenlik çerçevesi · köken-atıf kutuları (Vogue, Afrobeats craze'leri, Bhangra...).

## 8. Manuel-sona listesi (kurucu)
Dans eğitmeni doğrulama turları (stil-aile başına) · royalty-free beat lisans satın alımı (W1 öncesi tek harcama onayı) · Hula ortaklık kararı (istersen) · duyusal-kova store-policy onayı · cihaz-benchmark (G8) · fiyat onayı · submission.
