---
tur: envanter
proje: choreia
guncelleme: 2026-08-07
---

# Choreia — Yayın Envanteri

**Soru, kullanıcı tarafından sorulur:** *bir kullanıcı bugün bu uygulamayı açsa,
hangi yüzey onu yanlış bilgilendirir?*

Bu, *"ne eksik?"* sorusunun yerine geçmez — onun göremediğini görür. JabLab'ın
notu (J-119): **"eksik" merceği FAZLALIĞI göremez.** Bu gecenin bulgusu tam da
fazlalıktı: var olmayan bir mekanizmanın arıza hâlini anlatan bir cümle.

**Kanıt sütunu zorunludur.** *"Nasıl biliyorum"* yazılamayan satır bir kanaattir,
bulgu değil. Bu envanterin tek gerçek bulgusu o sütunda düştü.

---

## 🔴 BULGU — konuşkan yokluk (düzeltildi, `C-163`)

| Yüzey | Kullanıcı ne anlıyor | Gerçek | Kanıt | Durum |
|---|---|---|---|---|
| Progress ekranı, geçmiş notu | *"We could not open your practice history … until we can read it."* → **"pratiğim kaydedildi ve erişilemiyor"** | Hiçbir şey yazılmıyor. Depo YOK. | `lib/` genelinde `SessionStore` yalnız **OKUNUYOR** (`store.recent()`); hiçbir çağrı yeri depo kurmuyor, hiçbir yere `append` yok — `publication_inventory_test.dart` bunu regex ile çiviliyor | ✅ `HistoryIntegrity.notRecorded` eklendi: *"Choreia does not save your practice in this build … and nothing of yours has been lost."* |

**Sınıf:** bu ailenin alışık olduğu *"beyan var, üretici yok"*un **TERSİ** —
üretici yok ama **yüzey onu anlatıyor.** Yokluk sessiz değil, **konuşkan**; ve
konuşkan yokluk sessizinden kötü, çünkü **uydurma bir teselli** ekliyor
(*"until we can read it"* = "geri gelecek").

**Yan bulgu, aynı düzeltmede:** `showsTotals` `fidelity != unavailable` diye
yazılmıştı — yeni durum eklenince onu **sessizce "rakamları göster"** saydı. Yani
hiç tutulmamış bir kayıt için toplam gösterecekti. Tüketici `switch`'e çevrildi;
derleyici artık yeni bir durumu sınıflandırmadan geçirmiyor.

---

## 🟡 İZLENEN — bugün sessiz, konuşulursa bulgu olur

| Kalem | Neden bugün sorun değil | Ne zaman sorun olur | Kanıt |
|---|---|---|---|
| `unlockRule` (salsa L1) | İçerik bildiriyor, **hiçbir kod uygulamıyor**, ve **hiçbir yüzey bahsetmiyor** | Bir ekran "ilerleme"den söz ettiği an — JabLab'ın bulduğu şeklin aynısı | Koddaki 4 referansın hepsi **doküman yorumu** (`correctionPriority`'nin türetim dayanağı olarak anıyor); `json['unlockRule']` hiçbir yerde parse edilmiyor. Kapı: kullanıcı-görünür dizgide `unlock` yasak |
| Ders akışı 4 adım | Hiç inşa edilmedi ve **hiçbir yüzey adım sayısından söz etmiyor** | Bir sayfa "4 adım" derse | `DESIGN-AHEAD-OF-CODE.md` §5; `lib/`'de akış widget'ı yok |
| Ayna modu (K6) | `LiveView`'da kavram yok, **vaat de yok** | Bir metin "aynalı" derse | §6; `mirror` kelimesi yüzey dizgilerinde geçmiyor |

---

## ✅ DENETLENDİ — mekanizma var, cümle doğru

| Yüzey | İddia | Kanıt |
|---|---|---|
| Stil rozetleri (4) | Açılabilirlik | `StyleView.derive` içerikten türetiyor; `library_catalog_test` gerçek içeriğe karşı |
| *"BUILT · NOT OPEN"* + gerekçe | Yayın kapısı kapalı | `shipGates` içerikte gerçek, `CourseCatalog` parse ediyor, cümle `AvailabilityStrings`'ten |
| Ders engel cümleleri (4 sınıf) | Neden başlatılamıyor | `LessonOffer` türetiyor; `runnableSteps` **gerçek bundle'dan probe** ediliyor |
| 31 stilin `cameraLimits` | Kameranın göremediği | Her satır **zaten ölçülmüş** bir sınırı yeniden kullanıyor (tier C teması · 6° gürültü tabanı · mirrorConfident · §22). Kapı: "will be / once we / unlock" yasak; "beat grid" yalnız **yokluk** olarak anılabilir |
| Atıf kutusu | Dansın kökeni | 34/34 içerikte; kapı: yazar-notu olamaz |
| Sözlük | Adım adları | Kapı: *"Names, not lessons"* notu zorunlu, aynı sayfada `noLessons` görünüyor |

---

## ⛔ Envanterin kendi sınırı

Bu envanter **kod ve içerik** okur. Okumadığı iki şey:

1. **Cihazda gerçekten ne oluyor** — dokunuş yolu bu oturumda yok (`idb` kurulu
   değil, MCP cihaz izni etkileşimli), yani navigasyon iddiaları ekranla
   kapatılamıyor (`C-146`).
2. **Bir cümlenin ANLAŞILIR olup olmadığı.** Kapılar bir mekanizmanın var
   olduğunu ölçer, cümlenin doğru okunduğunu değil. *"Okunabilirlik
   `find.textContaining` ile ölçülebilen bir şey değil"* (Lissom).
