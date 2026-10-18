# Güncel mağaza görselleri — 18 Ekim 2026

Onaylı `v15-human-dancer` master korunur; figür yeniden çizilmedi, kırpılmadı
ve köşe maskesi eklenmedi. Kaynak onay: [native envanter](../../design/icon/approved-2026-10-16/manifest.json).
[Dosya manifesti](manifest.json) boyut/hash/alt metin ve açık kapıları tutar.

- `choreia-v15-app-store-1024.png`: onaylı native iOS marketing simgesinin
  byte eş kopyası; RGB, alfasız, 1024×1024.
- `choreia-v15-play-512.png`: aynı masterı tam kare kullanan 512×512 Play
  simgesi; 32-bit RGBA PNG, alfa kanalı tamamen opak (255), 230.404 byte.
- `choreia-v15-feature-en-US.png` ve `choreia-v15-feature-tr-TR.png`:
  1024×500, 24-bit RGB PNG feature graphic taslakları. Yazılı beş yol, görsel
  sayım ve kişinin çalışma kaydını anlatır; kamera/AI/doğru dans puanı,
  teslim edilmemiş video/müzik veya yayındaki ürün iddiası içermez.

Her yeni PNG'nin `.svg` kaynağı yanındadır. SVG'ler onaylı masterı byte eş
olarak içerir. Önceden kurulu `rsvg-convert` ile vektör düzen çizildi;
ImageMagick yalnız Play için opak 32-bit RGBA simge ve 24-bit RGB feature
PNG çıktısı aldı. PNG dönüşümü çizilen RGB
piksellerini değiştirmez. Son dosyalarda zaman/metin metadata'sı yoktur.
Başlık Georgia/serif, gövde Arial/sans-serif fallback kullanır; yeni font
kurulmadı, birebir uygulama fontu kullanıldığı iddia edilmez. Görsel kontrolde
figür, Türkçe karakterler, metin sığması ve çakışma/kırpma olmaması PASS.

Bunlar **yerel mağaza taslaklarıdır**; yeni pazarlama düzeni final kullanıcı
incelemesine ve ayrı yükleme kapısına tabidir. Güncel native uygulama ekranı
ve fiziksel cihaz kabulü bu grafiklerle kapanmaz. Simülatör bu oturumun etkin
native CUA yüzeyinde yoktur; mevcut eski simülatör çıktısı güncel kaynak diye
sunulmadı. Yeni yetki, cihaz/simülatör oluşturma, build veya kurulum yapılmadı.

`../icon-candidates/` ve `../feature-graphics/` altındaki eski adaylar tarihsel
kayıttır. Güncel EN/TR native ekranlar ayrıca yakalanmalı; kişisel hesap/e-posta,
sentetik dans klibi veya gerçek model değerlendirmesi izlenimi içermemeli.
[Google görsel şartları](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en).
