---
tur: olcum
proje: choreia
guncelleme: 2026-08-12
---

# R20 — `sh_running_man` hasat turu: gedik ölçümü + aday havuzu

**Sevk (koordinatör):** A′ = 3 (`dancehall` · `samba_no_pe` · `shuffle`) —
*içerik başlamış, referans yok.* ⛔ **Üçünü birden açma; önce ÖLÇ, en küçük
gedikli olanla başla** — *bir turda bir kalemi KAPATMAK, üçünü ilerletmekten
değerlidir.*

> ⚠️ **Bu bölüm hasat SONUÇLARINDAN ÖNCE yazıldı.**

---

## 1. Gedik ölçümü — hangisi en küçük?

| stil | adım | sürücü | eşik | aday listesi | `style.json` |
|---|---|---|---|---|---|
| **shuffle** | `sh_running_man` | `knee_flexion_mean` ✅ | var | **6** | 🔴 YOK |
| shuffle | `sh_t_step` | `thigh_rotation` 🔴 *(sözlükte `family`/`jointRef` yok)* | 🔴 `null` | — | 🔴 YOK |
| dancehall | `dh_bounce` | `knee_flexion_mean` ✅ | var | **0** | 🔴 YOK |
| samba_no_pe | `sm_samba_no_pe` | `knee_flexion_mean` ✅ | var | **0** | 🔴 YOK |

→ **En küçük gedik: `shuffle` / `sh_running_man`** — tek elinde **hazır aday
listesi** olan adım, ve sürücüsü kanıtlanmış ailede.
⛔ `sh_t_step` bu turda **açılmıyor**: iki ayrı ön koşulu düşük (sözlük kaydı
+ eşik `null`), ve *bir turda bir kalem*.

### 🔴 ÜÇÜNE DE ORTAK, HASATLA KAPANMAYAN BİR GEDİK: `style.json` YOK

Üç stilin **hiçbirinde** `content/styles/<stil>/style.json` yok.
`validate_content.py` her stilden **`shipGates`** (sevk ekseni) bekliyor, ve
`course_catalog.load` dersleri `style.json`dan okuyor.
⇒ ***Bir hasat turu referans gediğini kapatabilir, ama stili AÇILABİLİR
yapamaz.*** İkincisi içerik kararıdır (sevk ekseni + ders bağlama) ve bende
değil. **Bu turun kapsamı adıyla: referans, açılabilirlik DEĞİL.**

### ⚠️ Aday sayacım önce YANLIŞ saydı — ve düzeltildi

İlk sayım `dancehall` için **42 aday** dedi. Sebep: `dance` alt-dizgesi
**kanal adlarına** çarpıyordu (*"Dance Studio"*, *"Dance Tutorials"*).
Düzeltilmiş sayım yalnız **başlık sütununda, tam sözcükle** arıyor →
dancehall **0** · samba **0** · shuffle **6**. C-219'un ölçümü doğrulandı.
*Bir sayaç, aradığı şeyi yanlış yerde ararsa fazla sayar — ve fazla sayım,
eksik sayım kadar sessizdir.*

---

## 2. 🔁 TERSİNE DÖNÜŞ — hip-hop için RİSK olan, shuffle için HEDEF

R8, `hh_running_man` hasadında iki adayı **"adım riski"** ile dışarıda
bırakmıştı:
- `HUOjOJvPJc8` — *"'Shuffle Dance' EDM/Melbourne shuffle bağlamı olabilir,
  old-school hip-hop Running Man ile AYNI hareket olmayabilir"*
- `sv5-muy8720` — *"başlıkta 'Melbourne Shuffle' geçiyor, farklı dans türü
  olabilir"*

**Bu tur o riskin karşı yakasında:** aranan şey **shuffle'ın** running man'i.
⇒ Aynı iki video, **doğru adım için doğru malzeme.**
> ***BİR RİSK NOTU, HANGİ ADIMI ARADIĞINA GÖRE HEDEFE DÖNÜŞEBİLİR — ve bunu
> gören tek şey, notun SEBEBİYLE yazılmış olmasıdır.*** (Sebepsiz bir "RED"
> olsaydı bu iki video bugün geri kazanılamazdı.)

## 3. Triyaj (`probe_candidates.py`, GERÇEK metadata)

| video | çözünürlük | süre | kanal | karar |
|---|---|---|---|---|
| `HUOjOJvPJc8` | 3840x1920 | 621s | Marbiik | ADAY |
| `sv5-muy8720` | 1280x720 | 132s | Howcast | ADAY |
| `b6075roLFmo` | 1920x1080 | **1702s** | Emylee x The Shuffle Vibe | GÖZDEN_GEÇİR — **süre üst sınırı** |
| `CKWGXKj900Y` | 1920x1080 | **1993s** | Nustudios | GÖZDEN_GEÇİR — **süre üst sınırı** |
| `xapTBLAzP5M` | 1920x1080 | 267s | Tori Nishino | ADAY |
| `EP3Q3ttFwtU` | 3840x2160 | 427s | Caroline Kay | ADAY |
| `6m23DNL5idw` | 3840x2160 | 815s | Anna Shuffle | ADAY |
| `7g9PH1Qa4LM` | 640x360 | 161s | We Dance Hard | ADAY |
| `a-1rfX4P6nU` | 640x480 | 93s | aTrueBelgian | ADAY |

**7 aday / 7 ayrı eğitmen** — taban (≥3) rahatça karşılanıyor.
📌 İki GÖZDEN_GEÇİR **kaliteden değil, süre ÜST sınırından** düştü (900s):
ikisi de tam ders. ⛔ **Eşiğe dokunulmadı** — 60s alt sınırında olduğu gibi,
*vekil ile amaç ayrışması* koordinatörün kalemi.

## 4. ÖNCEDEN kaydedilen riskler ve hasat sırası

| sıra | video | risk sınıfı | hasat sonrası kontrol |
|---|---|---|---|
| 1 | `xapTBLAzP5M` (Tori Nishino, 267s) | **saf** — başlık hem *"SHUFFLE"* hem *"Running Man"* diyor | — |
| 2 | `HUOjOJvPJc8` (Marbiik, 621s, 4K) | **saf** (shuffle bağlamı R8'de zaten işaretli) | ⚠️ 3840x1920 alışılmadık en-boy |
| 3 | `EP3Q3ttFwtU` (Caroline Kay, 427s) | ⚠️ **dans adlandırılmamış** — başlık *"Running Man"* diyor ama **shuffle demiyor**; hip-hop RM olabilir | transkriptte hangi dans anılıyor |
| 4 | `6m23DNL5idw` (Anna Shuffle, 815s) | ⚠️ **ALMANCA içerik** | 🔴 kimlik okuması **İngilizce terimlerle** yapılıyor → `shuffl` Almanca'da da geçer ama *"running man"* geçmeyebilir ⇒ **ÖLÇÜLEMEDİ** sınıfına düşebilir, `KANIT_YOK` sanılmamalı |
| 5 | `7g9PH1Qa4LM` (We Dance Hard, 161s) | ⚠️ **varyant** — *"Hardstyle"* Running Man ayrı bir alt-tür olabilir | segment temel mi hardstyle mı |
| 6 | `a-1rfX4P6nU` (aTrueBelgian, 93s) | **saf** ama **93s** — tabanın hemen üstünde | çevrim sayısı yeterli mi |
| 7 | `sv5-muy8720` (Howcast, 132s) | ⚠️ **kanal-düzeyi öncül** — Howcast bu depoda **iki kez** elendi (`hh_running_man` *not-lesson/unknown*; cucaracha *üst-gövde oranı 0,58*) | aynı kapılar yine ötebilir |

**Sıra riske göre, sonuca göre DEĞİL.**
