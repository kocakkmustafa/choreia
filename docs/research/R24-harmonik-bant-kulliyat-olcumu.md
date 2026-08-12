---
tur: olcum
proje: choreia
guncelleme: 2026-08-12
---

# R24 — Harmonik bant: kabul edilmiş külliyat ne kadar tempo ayrışması taşıyor?

**Sevk (koordinatör):** bant *"kapının İŞİ mi, yoksa bir VEKİL hatası mı"*?
Yöntem, bu turda iki kez işleyen yöntem: ***sevk edilen referansların
take'leri arasında tempo yayılımı ne kadar?***
⛔ Bandı **değiştirme** — bu bir **ölçüm**, ayar değil.

---

## Ölçüm — yalnız `pubspec.yaml`ın sevk ettiği dört referans

| referans | n | periyotlar (s) | **en geniş ayrışma** | bantta (1,7–2,3) çift |
|---|---|---|---|---|
| `hh_bounce` | 4 | 0,583 · 0,625 · 0,625 · 0,68 | **1,166×** | **YOK** |
| `hh_running_man` | 4 | 1,20 · 1,21 · 1,38 · 1,67 | **1,392×** | **YOK** |
| `ss_shine_footwork` | 3 | 1,07 · 1,13 · 1,36 | **1,271×** | **YOK** |
| `hh_roger_rabbit` | 3 | 1,17 · 1,75 · 1,75 | **1,496×** | **YOK** |

> ## ⇒ SEVK EDİLEN KÜLLİYATTA EN GENİŞ AYRIŞMA: **1,496×** · BANT TABANI: **1,700** · BOŞLUK: **0,204**
> **Hiçbir sevk edilen referans, bugün reddedilen ayrışmayı taşımıyor.**
> ⇒ **Bant İŞİNİ YAPIYOR.** Kalem **kapanır, sebebiyle.**

Ve dört referansın **dördü de** bandın altında — tek bir sınır vakası bile
yok. *(En yakını `hh_roger_rabbit`, ve o bile tabana 0,2 uzakta.)*

---

## 🔴 DÜZELTME — sevkte iki AYRI büyüklük karışmış

Sevk *"`7g9PH1Qa4LM` **haklı olarak** düşüyor"* diyor. **Ölçüm bunu
desteklemiyor:** düşen take **`7g9PH1Qa4LM` değil, `HUOjOJvPJc8`.**

| çift | oran | bant |
|---|---|---|
| `HUOjOJvPJc8` ↔ `EP3Q3ttFwtU` | **1,906×** | 🔴 **BANTTA — çelişkiyi çıkaran çift bu** |
| `HUOjOJvPJc8` ↔ `7g9PH1Qa4LM` | 2,780× | ✅ dışında |
| `EP3Q3ttFwtU` ↔ `7g9PH1Qa4LM` | **1,458×** | ✅ dışında |

**Karışan iki büyüklük:**

| büyüklük | ne ölçer | `7g9PH1Qa4LM` değeri |
|---|---|---|
| **take'ler ARASI periyot yayılımı** | harmonik kapının baktığı şey | **1,458×** (EP3Q3ttFwtU'a karşı) — **kabul aralığında** |
| **kanal ↔ çöküş-türevi ayrışması** | tek take içinde **birim doğrulaması** | **%170** — ayrı soru |

*"%170"* bir **tempo ayrışması değil**, o take'in bağımsız kanalının kendi
çöküş-türevi periyoduyla uyuşmaması. Harmonik kapı bu sayıyı **hiç
görmüyor**.

## ⭐ VE BUNDAN ÇIKAN ASIL SONUÇ: hayatta kalan iki take TEMPO BAKIMINDAN UYUMLU

`EP3Q3ttFwtU` (1,75) ↔ `7g9PH1Qa4LM` (1,20) = **1,458×**, ve bu **sevk
edilen külliyatın en geniş ayrışmasının (1,496×) ALTINDA.**

> ### ⇒ Kalan tek engel **TEMPO DEĞİL, SAYI**: 2 < 3.
> Üçüncü bir take **hasat işidir**, ve inecek take'in tempo bakımından
> uyması için `1,20–1,75` bandına yakın durması yeterli — bu, ölçülmüş bir
> hedef, tahmin değil.

## ⚠️ Ve sevkin kendi uyarısı burada da geçerli, TERS yönde

*"Bir eşiğin fazla filtrelediğini kanıtlamak, onu geçen her adayı aklamaz."*
Simetriği: **bant işini yapıyor olması, `7g9PH1Qa4LM`in %170'lik kanal
ayrışmasını çözmez** — o ayrı bir kalem ve **açık kalıyor**. Bu ölçüm ona
dokunmuyor.

## 📌 Ve yöntem bugün İKİ ZIT cevap verdi — bu, yöntemin kendisinin kanıtı

| vekil | külliyat ne dedi | sonuç |
|---|---|---|
| süre üst sınırı (`MAX_SECONDS = 900`) | sevk edilen kaynak **1443,7s** | 🔴 **vekil ayrışmış — kalem AÇIK** |
| harmonik bant (1,7–2,3) | en geniş ayrışma **1,496×** | ✅ **vekil sağlam — kalem KAPALI** |

> ***AYNI YÖNTEM İKİ ZIT CEVAP ÜRETEBİLİYORSA, "SAĞLAM" HÜKMÜ BİR LASTİK
> DAMGA DEĞİLDİR.*** Bant için *"işini yapıyor"* demek, bu yüzden
> bir onay değil bir **ölçüm sonucu**.

⛔ Bant **değiştirilmedi**. ⛔ `non_alternating` okuması **yorumlanmadı**.
