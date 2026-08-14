# ⏸️ BEKLEME MODU — DESIGN LİNKİ BEKLENİYOR (devir: 2026-08-05, koordinatör yazdı)

> **Bu blok en güncel talimattır ve altındaki her şeyden ÖNCELİKLİDİR.**
> Aşağıdaki eski bölüm (önceki oturumun devir promptu) teknik durum/sınırlar için
> GEÇERLİ — ama "kendi tasarımını sen yap" varsayımı **SÜPERSEDE** edildi (M-F-279).

## 🎨 Yeni model (kurucu kararı 2026-08-05)
Tasarımlar **TEK design-orkestrasyonu oturumunda** üretilir (Remotion + Claude design
paneli), sonra sana **tasarım linki + giydirme brief'i** olarak gelir. Her uygulama
KENDİ dilinde, birbirinden TAMAMEN FARKLI tasarlanacak.

**BU OTURUMDA YAPMAYACAKLARIN:**
- ❌ Tasarım kararı üretme (renk/tipografi/düzen/akış dili) — yön koordinatörden gelir.
- ❌ Kendi başına design turu başlatma, UI yeniden yazma, "cila" turu koşma.
- ❌ Kurucuya doğrudan tasarım sorusu sorma (M-F-77; koordinatörden geçer).

**BU OTURUMDA YAPACAKLARIN:**
1. Aşağıdaki okuma listesini bitir (bağlam kopukluğu olmasın).
2. Ağacı doğrula: `git -C ventures/choreia/app status` + `git -C ventures/choreia/app log -1` (**beyana değil ağaca güven**).
3. Kısa bir "hazırım" özeti yaz: okuduklarını + doğrulanan tepe commit'i + varsa
   ağaçta beklenmedik bir şey. **Sonra BEKLE.**
4. Giydirme brief'i gelince: tasarımı KENDİ yüzeyine uygula, dürüstlük sınırlarını
   ESNETMEDEN (aşağıda), kapılarını koştur, commit+push (kalıcı yetkin var).

## 📖 Okuma listesi (sırayla — bağlam bunlarda)
1. **Vault:** `knowledge/Yula Lab/20 Şirketler/Motion/🔄 Oturum Devri 2026-08-05 — Choreia Bounce Dosyası Kapandı + Kamera TAM.md` — senin son turunun kaydı.
2. **Vault:** `📊 Durum Panosu — Motion.md` → **08-05 "GÜNCEL DURUM BU BLOK"** (altı tarihsel).
3. **Vault:** `🔄 Oturum Devri 2026-08-05 — Orkestratör Kamera Dalgası Kapanışı → Design Orkestrasyonu Devri.md` — §4 yeni model + §5 kalan işler.
4. `ventures/choreia/workspace/DEFTER.md` + `PROGRESS.md` — **son bölüm** (kendi hükümlerin).
5. `ventures/motion-core/workspace/DEFTER.md` — **M-F-260 → M-F-279** (aile kuralları, bağlayıcı).
6. Bu dosyanın altındaki eski bölüm — teknik durum, ölçülmüş tuzaklar, bağlayıcı sınırlar.

## 📍 Senin durumun (2026-08-05, git-doğrulandı)
**Kamera entegrasyonu TAM (kısım-1+2)** — main `b9e448e`, push 0/0, ağaç temiz; iOS sim + Android APK derlemeleri ve sim ekran kanıtı var. **İsimli eksik:** izin İKİNCİ hâli (kalıcı ret) simülatörde teyit edilmedi (widget-testte kanıtlı) — 'design-öncesi ucuz' kalem.

**İlk işin:** okuma listesi + ağaç doğrulaması + 'hazırım' özeti. İstersen bekleme sırasında SADECE o ucuz kalemi (kalıcı-ret sim teyidi) kapatabilirsin — tasarıma dokunmadan. Sonra BEKLE.

## 🚧 Tasarımda da ESNEMEYEN sınırlar (giydirme sırasında geçerli)
- **K8:** kalibre edilmemiş sayısal skor YOK ("bant, nokta değil").
- **M-F-186:** vaat dili (`comingSoon`/"yakında") YASAK · engelli özellik İSİMLİ
  gerekçeyle görünür · `measurementOnly` beyanı **yüzeyin TEPESİNDE** (konum içeriğin parçası).
- **Dürüst hâller birinci sınıf ekrandır** (izin · kamera-yok · kimse-yok · kadraj-dışı) —
  tasarım bunları "artık" gibi ele alamaz; hâl-başına ayrı render yolu korunur.
- **Türetimli listeler elle yazılmaz** · ham `detail`/hata kodu yüzeye sızmaz.
- **Ekran kanıtı KAPIDIR:** "testler metnin VARLIĞINI sınar, DOĞRULUĞUNU sınamaz"
  (95 yeşil test yanlış-anatomi metnini görmedi — Lissom P0 dersi).
- Yeni ölçü/kapı/eşik tasarımı veya dürüstlük-metriği hükmü → **koordinatöre**.

## ⚙️ Kalıcı kurallar
- commit + push + merge **KALICI YETKİLİ**; `ventures/motion-core/lib` paylaşımlı ağacında
  **dal değiştirmek YASAK** (M-F-22).
- **iCloud-altı repoda `git add -A` yerine DOSYA-İSİMLİ add** (0-bayt `index.lock` riski, M-F-273);
  başkasının untracked dosyasına dokunma (M-016; `* 2.plist`-sınıfı iCloud artıkları dahil).
- **Bağlam sıkışırsa İSİMLİ DURDUR** — sessiz kalite düşüşü yerine isimli duruş (aile standardı).
- **Cihaz-kanıtı vaat edilmez:** iOS sim'de kamera YOK; gerçek-kamera canlılığı cihaz gününe
  ertelendi (kurucu, tek oturum). Hiçbir yüzey "cihazda kanıtlı" demez.

---
---

# Choreia — yeni oturum devir promptu (2026-08-05, DESIGN turu girişli)

Bunu aynen yapıştır. Kamera entegrasyonu **kısım 1 ve 2 KAPANDI**; bu oturumun
ilk işi **design turu**.

---

Sen Choreia oturumusun — Yula Motion ailesinin dans app'i. Kamera entegrasyonu
bitti: canlı yol, ekran, iki platform derlemesi ve simülatör ekran kanıtı
mühürlü. **Ekran YAPI'dır; görünüm senin turun.**

## OKU (sırayla)

1. `ventures/choreia/VENTURE.md`
2. `ventures/choreia/workspace/PROGRESS.md` — son iki blok (kısım 1 + kısım 2)
3. `ventures/choreia/workspace/DEFTER.md` — **C-133** ve **C-134**
4. `ventures/choreia/app/docs/design/UI-BRIEF.md` — design turunun girdisi
5. `ventures/choreia/app/lib/app/live/live_view.dart` — devralacağın yapı

## GÜNCEL DURUM

- **`app` HEAD = `b9e448e`**, ağaç TEMİZ, senkron, açık dal YOK.
- **80 Flutter + 16 engine testi · analyze temiz · Python kapıları 0.**
- **Derlemeler GEÇTİ:** iOS simülatör 22,1s · Android debug APK 25,4s.
- Ekran kanıtı: `app/docs/evidence/live-permission-denied-ios-sim.png`.
- Canlı ekran yedi hâli render ediyor; `gatedChecks` + `notMeasuredNote` HER
  hâlde görünüyor.

## İLK İŞ — DESIGN TURU

`UI-BRIEF.md` girdisi hazır. Kural: **"design stil değiştirir, YAPIYI
DEVRALIR, icat etmez."** Yani:

- Yedi hâlin hepsi ekranda kalır — hiçbiri "temiz görünsün" diye gizlenmez.
- **`gatedChecks` ve `notMeasuredNote` katlanmaz, sekmeye saklanmaz.**
  Yapılamayan kontrol, kullanıcının aksi hâlde "geçti" sanacağı şeydir.
- **"Hiç başlamadı ≠ sıfır"** korunur: çıplak `0` render edilmez.
- Kalıcı retde "tekrar dene" butonu **geri gelmez**.

Bunlar test altında (`test/live_view_test.dart`) — design turu onları
kırıyorsa yapı değil tasarım değişir.

## AÇIK, İSİMLİ EKSİK (design turundan önce ucuz)

**İzin ikinci-hâli simülatörde teyit EDİLMEDİ.** "Try again"e basınca ekran
kalıcı-ret hâline geçmedi; **dokunuş ıskalaması mı `_permanentlyDenied`
mantığı mı ayırt edilmedi**. Widget testinde desen kanıtlı, simülatörde
değil. `lib/main.dart` `_start()` içindeki ikinci-ret tespitine bak.

## ⚠️ ÖLÇÜLMÜŞ TUZAKLAR (aynısına düşme)

- **Pin eşitliği aynı COMMIT değil aynı DİZE meselesi** — `motion_core` ve
  `motion_camera` **tam 40-karakter SHA** ile aynı ref'ten pinli
  (`f13bdc9…`). Kısa SHA ya da tag adı yazarsan pub reddeder
  (*"motion_camera from git is forbidden"*). `test/pin_equality_test.dart`
  çiviliyor.
- **iOS:** deployment target **14** · Podfile **`:linkage => :static`** ·
  `pod install` **`LANG=en_US.UTF-8`** ile. Üçü de gerekli (Gravita ölçtü).
- **iCloud: ÖNCE `flutter clean`, SONRA symlink** (`build → ~/choreia_buildout`).
- `testWidgets` + gerçek dosya G/Ç → kilitlenir, hata VERMEZ; `runAsync` ile sar.
- **zsh tırnaksız parametreyi word-split ETMEZ** — kapı sağlamken kırmızı görünür.
- **Yok olan alan ≠ null olan alan.**
- **Metin testi SAYIYI arasın** — interpolasyon kaçağı "not var mı" testinden geçer.

## Bekleyen, isimli tetikler (senin açman gereken iş DEĞİL)

- `ss_basic` / `FtZzjGsPxjg` kurucu-göz → havuza **kimliksiz ALINMAZ**.
- Hasat slotu: bounce 3/6 + `mirror-ambiguity` · rock 0/6 — **düşük öncelik**.
- **Cihaz günü** — cihaz-doğrulaması İSİMLİ release-gate; hiçbir beyan
  "cihazda kanıtlı" DEMEZ.

## Sert kurallar (aynen)

Dışlama İSİMLİ + BAĞIMSIZ gerekçeli · dairesel istatistik yasak · karar ölçüsü
gürültü tabanının altında soru soramaz · fps fallback yok · yeni
ölçü/kapı/eşik TASARIMI ve dürüstlük-metriği hükmü **koordinatöre** ·
alt-ajanlara `model:'sonnet'` + git-yazma yasağı · commit+push+merge Motion
ailesinde kalıcı izinli.
