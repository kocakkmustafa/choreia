# Cihaz günü PAKETİ — Choreia (2026-08-17)

**Bu, `RECIPE.md`nin YERİNE geçmiyor** — reçete adım adım yürüyüşü anlatır (tek doğru kaynak,
tekrarlanmıyor burada). Bu dosya reçeteye ekli, TARİHLİ bir **hazır mı** anlık görüntüsü.

## 🟡 Durum: KISMEN HAZIR — ön-uçuş temiz, yürüyüş GÖRSEL olarak doğrulanmadı

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

## 🔴 Eksik kalan — yürüyüş adımı GÖRSEL olarak doğrulanamadı

`RECIPE.md`nin §3 tablosu bu turda yazıldı ama **kod-okumasından** — `choreia-hatti`
simülatörüne erişim istendi ve reddedildi/bekliyordu:

```
mcp__Claude_Code_iOS_Simulator__control{action:"attach"} →
"The user has not granted Claude access to choreia-hatti (iOS 26.5) (a recent
request was declined or is awaiting a response)."
```

Muhtemel sebep: bu gece paralel koşan sekiz eş-oturumdan biri aynı simülatör/panel kaynağını
tutuyor olabilir (`ListAgents` bu turda 8 aktif Motion-ailesi oturumu gösterdi). Tekrar
denemedim — araç talimatı aynı çağrıyı döngüde tekrarlamamayı söylüyor ("or try again later"
ipucu var ama kök sebep kurucunun tek-tık izniyle çözülüyor, bu oturumda zorlanamaz).

**Sonuç: RECIPE.md'nin §3 tablosu Gravita'nınkinden FARKLI bir kanıt sınıfı taşıyor** —
Gravita'nınki gerçek ekran görüntüsünden, Choreia'nınki her satırın kaynak dosya+satırına
bağlı birebir kod metninden. İkisi de "iddia değil" ama ikincisi "ekranda GÖRÜLDÜ" değil,
"kodda YAZILI" — RECIPE.md'nin kendi başlığında bu fark adıyla ayrıldı, karıştırılmadı.

## Sıradaki

- Bir sonraki turda `choreia-hatti` simülatörüne erişim iste (kurucunun panel içinden
  "Let Claude use it" onayı gerekebilir) → `RECIPE.md`'nin §3 tablosunu gerçek ekran
  görüntüleriyle DOĞRULA veya DÜZELT.
- Kamera köprüsünün canlılığı (aile-geneli açık soru) bu paketin de yakalayamadığı bir
  eksen — yalnız gerçek bir telefonda ölçülebilir.

## Kaynaklar

- Yürüyüş tablosu + ön-uçuş komutu: `RECIPE.md`
- Ön-uçuş betiği: `tools/device_day_preflight.py` (bu turda yazıldı)
- İmza/kurulum dersi: `feedback-ios-cihaz-kurulum-imza.md` (`H-9`)
- Aile-geneli tuzaklar: `motion-core/workspace/CIHAZ-GUNU-AILE-RECETESI.md`
- Gölgeleme düzeltmesinin kaynağı: `gravita/app/docs/device-day/PAKET.md` (`G-253`)
