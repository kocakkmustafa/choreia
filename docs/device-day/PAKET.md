# Cihaz günü PAKETİ — Choreia (2026-08-17)

**Bu, `RECIPE.md`nin YERİNE geçmiyor** — reçete adım adım yürüyüşü anlatır (tek doğru kaynak,
tekrarlanmıyor burada). Bu dosya reçeteye ekli, TARİHLİ bir **hazır mı** anlık görüntüsü.

## 🟡 Durum: KISMEN HAZIR — ön-uçuş temiz, yürüyüşün BİR ekranı GERÇEKTEN görüldü, ötesi giriş-köprüsü arızasından engellendi

## 🟢 GÜNCELLEME (aynı gün) — STYLES sekmesi gerçekten görüldü, `C-308`'in iki bulgusunu ekrandan doğruladı

İlk yazımdan sonra `choreia-hatti` simülatörüne erişim ikinci denemede verildi ve uygulama
zaten kurulu+açık çıktı. Ekranda GERÇEKTEN görülen metin, `docs/store/listing.json`
(`C-308`) yazılırken kod okumasından çıkarılan iki kritik bulguyu birebir doğruladı:

- **"34 styles are in the catalogue. One of them is open to practise right now, and none
  of the open ones is graded."**
- **Hip-Hop Foundations — "OPEN·NOT SCORED — 7 LESSONS WRITTEN·NONE GRADED·1 OPEN"**
- **Salsa Shines — "BUILT·NOT OPEN — 9 LESSONS WRITTEN·1 GRADED·NONE OPEN — Not open — the
  beat for this style is unconfirmed, and we will not grade your timing against a count we
  are not sure of."**

Bu, `C-308`'in `$onlyOneStartableLessonWhy` ve `$salsaExcludedWhy` notlarını KOD-ÇIKARIMINDAN
EKRAN-KANITINA yükseltiyor — listing.json'ın metnini değiştirmiyor (zaten doğruydu), ama
kanıt sınıfını güçlendiriyor.

### 🔴 Yeni bulgu — giriş (tap/swipe/HOME) köprüsü bu oturumda tamamen yanıtsız

Ekran görüntüsü çalıştı ama `tap` (2 farklı koordinat), `swipe` ve sistem-seviyeli
`button:HOME` — DÖRDÜ DE ekranı hiç değiştirmedi. HOME düğmesinin yanıtsız kalması giriş
köprüsünün TAMAMEN kapalı olduğunun kesin kanıtı (izin sorunu değil — erişim verilmişti).
Bu yüzden Bounce dersine girip canlı kamera ekranını görmek bu turda mümkün olmadı — aile-
geneli "kamera köprüsü canlılığı hiç ölçülmedi" sorusunun bir kardeşi: bu turda "giriş
köprüsü canlılığı" da ölçülemedi.

## Bugünün taze ölçümü

`tools/device_day_preflight.py` bu turda YAZILDI (Gravita'nın v2 gölgeleme-düzeltmesi
gerekçesiyle alınarak — bkz dosyanın kendi docstring'i) ve DOĞRUDAN çalıştırıldı:

```
═══ CİHAZ GÜNÜ ÖN-UÇUŞ ═══
✅ [imza] 4 geçerli codesign kimliği bulundu.
✅ [profil] bulundu (cihaz-kapsamlı): iOS Team Provisioning Profile:
   com.yulalab.choreia (bitiş 2027-08-13 22:30:14)
✅ [cihaz] 00008120-001804D83E13C01E PROFİLDE KAYITLI — kurulum tazeleme
   GEREKTİRMEMELİ.

✅ ÖN-UÇUŞ TEMİZ — kuruluma geçilebilir.
```

Choreia'da Gravita'yı ısıran gölgeleme durumu (bir Store-dağıtım profilinin geliştirme
profilinden "daha yeni" görünüp yanlış seçilmesi) **henüz oluşmamış** — bugüne kadar yalnız
tek bir geliştirme profili üretilmiş, ikinci (Store) profil yok. Betik yine de v2 mantığıyla
yazıldı (aynı hazırlık, gerçekleşmeden önce) — Choreia bir yayın-provası turu koşturduğunda
bu kusura karşı zaten bağışık.

## 🔴 Eksik kalan — 15/16 satır hâlâ kod-okuması, giriş köprüsü arızalı

İlk denemede `choreia-hatti` simülatörüne erişim reddedildi/bekliyordu (muhtemelen paralel
koşan eş-oturumlardan biri aynı kaynağı tutuyordu — `ListAgents` o an 8 aktif Motion-ailesi
oturumu gösterdi). İkinci denemede erişim VERİLDİ ve `screenshot` çalıştı — ama ardından
denenen `tap`/`swipe`/`button:HOME` (yukarıdaki 🟢 bölüm) HİÇBİRİ ekranı değiştirmedi.
Yani engel değişti: önce erişim reddi, şimdi çalışan bir ekran-yakalama + yanıtsız bir
giriş köprüsü. Sonuç aynı — STYLES sekmesi (madde 9) dışında tabloya GÖRSEL kanıt eklenemedi.

**RECIPE.md'nin §3 tablosu artık İKİ kanıt sınıfını bir arada taşıyor, satır satır
işaretli:** madde 9 🟢 gerçek ekrandan (Gravita'nın yöntemiyle aynı), geri kalan 15 satır
🔴 kod-okumasından (dosya+satır kaynaklı, birebir metin ama görülmedi). Bu karışıklık
yaratmasın diye RECIPE.md'nin başında ve ilgili satırda adıyla ayrıldı.

## Sıradaki

- Bir sonraki turda giriş köprüsünü tekrar dene (erişim artık sorun DEĞİL — sorun tap/swipe/
  HOME'un yanıtsız kalması; başka bir oturum penceresi/kilit tutuyor olabilir, ya da ortamın
  kendi bir sınırı) → geçerse `RECIPE.md`'nin kalan 15 satırını gerçek ekran görüntüleriyle
  DOĞRULA veya DÜZELT.
- Kamera köprüsünün canlılığı (aile-geneli açık soru) VE şimdi giriş köprüsünün canlılığı —
  ikisi de bu paketin yakalayamadığı bir eksen, yalnız gerçek bir telefonda/çalışan bir giriş
  köprüsünde ölçülebilir.

## Kaynaklar

- Yürüyüş tablosu + ön-uçuş komutu: `RECIPE.md`
- Ön-uçuş betiği: `tools/device_day_preflight.py` (bu turda yazıldı)
- İmza/kurulum dersi: `feedback-ios-cihaz-kurulum-imza.md` (`H-9`)
- Aile-geneli tuzaklar: `motion-core/workspace/CIHAZ-GUNU-AILE-RECETESI.md`
- Gölgeleme düzeltmesinin kaynağı: `gravita/app/docs/device-day/PAKET.md` (`G-253`)
