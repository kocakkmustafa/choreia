# Choreia — Claude Design Paneli Promptu (v1, 2026-08-05)

> Koordinatör hazırladı, **kurucu onayı sonrası** panele verilir.
> Kaynak: kurucu tasarım yönü (M-F-282, *"romantik, sıcak"*) + 2 referans görsel
> + ölçülmüş yüzey envanteri (`UI-BRIEF.md`, motorla birebir).
> §9'daki kısıtlar **estetik tercih değil** — testler ve içerik kapıları zorluyor.

---

## 0. Ne tasarlıyorsun

**Choreia** — telefonu karşına koy, bir dans adımını ekrandaki eğitmenlerden öğren, dene;
sistem **yalnız gerçekten ölçebildiğini** söylesin, ölçemediğini de açıkça söyleyip sussun.

**Choreia bir DANS OYUNU DEĞİL.** Skor bir eğlence puanı değil, bir **ölçüm iddiasıdır**.
Değer birimi "yüksek puan" değil **öğrenilmiş adım**. Combo-streak-havai fişek yok,
tezahürat yok.

> **🔴 Bu brief'in en önemli cümlesi:** bir dans uygulamasında kullanıcının beklediği ilk
> şey **ritim/zamanlama puanıdır — ve Choreia'da bu YOK.** Tasarım bu boşluğu gizlemeye
> çalışmayacak; **dürüstlüğü ürünün karakteri yapacak.**

**Karakter:** sakin, ölçen bir eğitmen. Emin olmadığında **"iyi" demez, susar.**
Otorite kaynağı: *"N bağımsız eğitmen şunda anlaştı"* — sayı ve kaynak, slogan değil.

---

## 1. Görsel yön

> **⚠️ Referanslar nasıl okunacak:** iki görsel **renk paleti ve malzeme dili** için
> gönderildi, ekran kompozisyonları için değil. Referans-1 bir VR/oyun mağazası —
> yapısı bizimle ilgisiz. Tasarım **bizim yüzeyimize** göre kurulur (§2-§8).

**Palet — Referans-1'den (koyu görsel):** neredeyse siyah zemin, derin **erik/bordo**
alt tonlu; **gül-pembe** parıltı; zengin görsellerin üstünde sıcak ışık halesi.

**Malzeme — Referans-2'den (Liquid Glass Kit):** **ŞEFFAF** cam — buzlu değil.
Prizmatik/holografik kenar ışığı, arkası görünen paneller, cam hap butonlar, katmanlı
cam kartlar.

**Işık karakteri:** gül/erik parıltısı **SAHNE-STÜDYO IŞIĞI** gibi okunmalı — sıcak,
dağınık, insani. ⛔ **Doygun TikTok-neon DEĞİL.** İsim *khoreia* (Yunan koro-dansı):
**ritim, tekrar, akış.**

### 🔴 KARDEŞ ÇAKIŞMASI — bu bölüm bağlayıcı

Bu ailenin başka bir uygulaması (**JabLab**, solo boks) az önce şöyle tasarlandı:
**koyu zemin + liquid glass + kırmızı.** Choreia da koyu + cam olacağı için bu ikisi
ailenin **en yakın çifti** ve **birbirine benzemesi YASAK** (kurucu kuralı: *"aynı elden
çıkmış renkleri değişik şekilde değil"*).

Ayrım **renkle yapılmayacak** — şu eksenlerde yapılacak:

| Eksen | JabLab | **Choreia (sen)** |
|---|---|---|
| **Cam** | **buzlu, opak**, ağır bulanıklık | **ŞEFFAF, prizmatik kenarlı**, arkası görünür |
| **Tipografi** | ağır, geniş, sans | **zarif, editoryal, kontrastlı** |
| **Hareket** | keskin, hızlı, **kesik** | **akan, sürekli, döngüsel** — dans gibi |
| **Yoğunluk** | sıkı HUD | **ritmik, nefes alan, müzikal boşluk** |
| **Yerleşim** | işlevsel panel ızgarası | **akışkan, asimetrik, tekrar/ritim duygusu** |
| **Görsel** | donmuş tek güç pozu | **hareket izi, akış, çoklu beden** |

**Palet dışında en az 3 eksende ayrışmayan çıktı reddedilir.** Hareket karakteri en güçlü
ayrım aracın — dansın kendisi zaten akış; JabLab'ın kesik ritmini asla kullanma.

---

## 2. Kütüphane — ⚠️ bu tasarımın en zor problemi

**34 stil sayfası, 5 dalga.** Bugün: **1 tanesi `live`** (Salsa Shines) · **1 tanesi
`demoOpen`** (Hip-Hop Foundations) · gerisi henüz yok ya da beklemede.

**Kapsamın TAMAMI gezilebilir olmalı** — ama **sahte/boş kurs asla listelenmez.**

> **Yaratıcı problem:** kütüphane **sahte-dolu görünmeden** nasıl "geniş kapsam" hissi
> verir? 34 sayfa var, 1'i puanlıyor. Bu ekranın çözümü tasarımın asıl sınavı.

### Rozet üç ayrı şey söylemek zorunda

| Rozet | Anlamı |
|---|---|
| **live** | bu stilde **skorlanan** ders var |
| **demoOpen** | dersleri **açabilirsin ama hiçbiri puan vermez** |
| **comingSoon** | açılabilir ders yok |

> ⚠️ **`demoOpen` bu tasarımın yeni ve zor rozeti:** *"açık"* ile *"puanlı"* aynı şey
> değil ve bunu **tek bir rozetle** anlatman gerekiyor. İkinci sınıf gibi görünmemeli.

**Beklemedeki stiller gerekçesiyle görünür, gizlenmez.** Örnek: **Hula** — kumu-hula
ortaklığı olmadan yapılmıyor, kasıtlı beklemede ve sebebi yazılı.

---

## 3. Stil sayfası

- Tanıtım + **köken/atıf kutusu**
- Adım sözlüğü
- Kurs listesi (Temeller · Kombolar · Rutinler)
- Tempo/BPM bilgisi — ⚠️ Salsa için bugün **tartışmalı**, **sayı gösterilemez**
- Kişisel zamanlama trendi — ⚠️ **V1'de YOK** (zamanlama ölçülmüyor)
- **Dürüstlük kutusu:** ne ölçülür / ne ölçülmez, olduğu gibi

> **🌍 KÜLTÜREL ATIF DEKORASYON DEĞİL, İÇERİĞİN PARÇASI.** Vogue → Siyah/Latino LGBTQ+
> ballroom kültürü · Afrobeats → kendi craze'leri · Bhangra → kendi kökeni. Bu kutular
> küçültülmez, dipnota indirilmez. Tasarımda **saygılı ve görünür** yerleri olacak.

---

## 4. Ders — ÜÇ GÖRSEL SINIF, karıştırılamaz

| Sınıf | Kullanıcıya ne der | Görsel gereksinim |
|---|---|---|
| **Skorlu** | *"This is graded: leg shape, which foot leads"* | normal akış + skor yüzeyi |
| **Kilitli** | *"Not enough teachers measured yet"* | kilit **görünür + açılmaz**, sebep **eksik ÖLÇÜMÜN adıyla** |
| **Demo-only** | *"We teach this, we don't grade it — here's why"* | ⚠️ **İKİNCİ SINIF GİBİ GÖRÜNMEMELİ** — bu tam bir ders, yalnız skoru yok |

**Gerçek örnek:** *Running Man* — 4 eğitmen ölçüldü, hareket öğretiliyor, **skorlanmıyor**
(ayak-ucu temas zamanlaması tek kamerada güvenilir değil). Tasarım bunu bir **kusur**
değil bir **dürüstlük** olarak sunacak.

---

## 5. Ders akışı — dört adım, üçüncüsü KAPALI

1. **Adımı öğren** — yavaş, sayımlı (eğitmen figürü + sayım metni)
2. **Beat'siz dene** — sadece şekil
3. **Beat'le dene** — ⚠️ **V1'de KAPALI** (beat ızgarası yok)
4. **Skor + TEK düzeltme** — en önemli tek hata

> **3. adım için hüküm: yerini BOŞ BIRAK, sahte doldurma.** Kullanıcı dörtlü bir yol
> göreceğse üçüncü basamağın neden şu an geçilemediğini de görmeli. Bunu "kırık" değil
> "henüz açılmamış ve sebebi belli" hissettirmek **senin tasarım problemin**.

---

## 6. ⭐ Canlı tur — kullanıcının BAKAMADIĞI ekran

Dans ederken kullanıcı telefona **bakamaz.** Ekran **sesin etrafında** kurulur.

- **Ayna modu varsayılan AÇIK** — referans figür aynalanmış gösterilir, kullanıcı ayna
  gibi taklit eder.
- **Büyük, uzaktan okunur sayım.**
- **Sesli koç birincil.**
- **Hüküm-yok durumları görünür:** kadraj dışı · düşük ışık · düşük takip güveni.
  Bunlar *"kötü dans ettin"* DEMEZ — *"göremiyorum"* der. Ayrı ayrı tasarlanacak.

> **🎵 MÜZİK — birinci sınıf akış, ayar dipnotu değil:** uygulama içi müzik kataloğu
> **YOK** (lisans). Kaynak ya **kendi metronomumuz** ya **kullanıcının kendi yerel
> müziği**. *"Kendi müziğini seç"* akışı **birinci sınıf vatandaş** olarak tasarlanacak.

---

## 7. Deneme özeti

- Şekil değerlendirmesi — ⚠️ **kalibrasyon kapısı geçilmeden MUTLAK SAYI YOK**;
  *"Alignment: strong"* + eğri gibi **bant** dili.
- **TEK** düzeltme cümlesi.
- **Skorlanan ↔ skorlanmayan ayrımı ekranda:** hangi eklemler hüküm taşıdı, hangileri
  (kollar) **bilinçli serbest**.
- **Hüküm verilmeyen fazlar BOŞ görünür — "0 puan" değil, "ölçülmedi".**

---

## 8. İlerleme — İKİ BÖLÜM, asla karıştırılamaz

| Bölüm | İçerik | Hangi dersler |
|---|---|---|
| **Kaydedilenler** (ÖLÇÜM) | süre · çevrim sayısı · tamamlama işareti | **hepsi** (skorlu + demo-only) |
| **Değerlendirilenler** (HÜKÜM) | bant/ilerleme | **yalnız skorlu** |

> **Neden ayrı:** tek listede karıştırmak, demo-only derslerin tamamlamalarını
> **puanlanmış gibi** okutur.
> **Demo-only ders "öğrenildi" işareti ALIR, bant ASLA almaz.** Mantık zinciri:
> *"bu dersi baştan sona çalıştım"* kameradan bağımsız bir **ölçümdür**;
> *"bunu iyi yaptın"* bir **hükümdür** ve demo-only derste tanım gereği yoktur.
> Tamamlamayı da esirgemek dersi ikinci sınıf yapardı.
> Demo-only satırında hüküm alanı **"—"** + sebebi.

---

## 9. ⛔ ASLA

1. **Kalibrasyonsuz mutlak sayı YOK** — bant kullan.
2. **Combo / streak / havai fişek / yüksek skor tablosu YOK.** Bu bir oyun değil.
3. **Tezahürat ve ünlem YOK** — sakin, ölçen eğitmen tonu.
4. **Zamanlama/ritim puanı YOK** ve **varmış gibi gösterilemez** (beat ızgarası yok).
5. **"Official [sanatçı] choreography" YASAK** · **marka adı YASAK** (Zumba vb.).
6. **"Profesyonel seviye" YASAK.** Tıbbi/tedavi dili YASAK.
7. **Sahte/boş kurs listelenmez** — ama kapsam gizlenmez.
8. **Demo-only ders ikinci sınıf gösterilemez.**
9. **Hüküm verilmeyen faz "0" gösterilmez** — boş görünür.
10. **Kültürel atıf kutuları küçültülmez/dekorasyona çevrilmez.**
11. **Uygulama içi müzik kataloğu YOK** — öyle bir yüzey tasarlama.
12. **JabLab'ın buzlu camı ve kesik hareket dili KULLANILMAZ** (§1 çakışma kuralı).

---

## 10. Zorunlu hâller

boş · yükleniyor · hata (teknik jargon yok) · kamera izni reddi (geçici/kalıcı ayrı) ·
kadraj dışı · düşük ışık · düşük takip güveni · kilitli ders · demo-only ders ·
beklemedeki stil (gerekçeli) · müzik seçilmemiş.

---

## 11. Teslim

- Kütüphane (34 stilin **sahte-dolu görünmeden** çözümü — en kritik kalem)
- Üç rozetin görsel çözümü (**`demoOpen` en zoru**)
- Üç ders sınıfı ayrı ayrı
- Ders akışının 4 adımı, **3. adım kapalı hâliyle**
- Canlı tur + tüm hüküm-yok hâlleri
- Deneme özeti · İlerleme'nin **iki bölümü**
- Stil sayfası + köken/atıf kutusu
- Geçiş animasyonları (**akan/döngüsel** karakter) + hareket spec'i
- Palet, tipografi ölçeği, **şeffaf cam** spesifikasyonu (kenar ışığı, saydamlık, kırılma)
- **Arayüz metinleri İNGİLİZCE**

---

*Bağlayıcı kaynak: `docs/design/UI-BRIEF.md` §5-§6 · M-F-123 (statü kafesi) ·
M-F-156 (iki bölüm) · K8 · K10 · K6 (ayna) · K3 (müzik) · M-F-282 (kurucu yönü).*
