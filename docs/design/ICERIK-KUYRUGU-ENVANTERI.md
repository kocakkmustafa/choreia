---
tur: envanter
proje: choreia
guncelleme: 2026-08-12
---

# Choreia — İçerik Kuyruğu Envanteri (koordinatör sevki, C-217 devamı)

**Soru:** *"31 `awaiting-content` iddian gerçek mi — kaçı GERÇEKTEN içeriksiz,
kaçı KISMEN var, kaçı BAŞKA bir sebeple kapalı?"* Lissom'un kendi kuyruğunda
3 kalemin 2'sinin zaten sevk edilmiş çıkmasından sonra sorulan aynı soru.
**Körlemesine alınmadı — ölçüldü.**

## Sayım — `library.json`'dan doğrudan

`status` alanı: `live` **1** · `demoOpen` **1** · `comingSoon` **31** ·
`onHold` **1** (hula) = 34. **"31" rakamı doğru** (Lissom'un vakasının
tersine — burada rakam bozuk çıkmadı).

## 31'in içi — üç ayrı sınıf, isimle

| Sınıf | Sayı | Stiller |
|---|---|---|
| **KISMEN VAR — gerçek, git'e alınmış step JSON'u var** | **3** | `dancehall` (`dh_bounce.json`) · `shuffle` (`sh_running_man.json` + `sh_t_step.json`) · `samba_no_pe` (`sm_samba_no_pe.json`). Üçü de C-204'ün "hasat edilebilir" iddiasını taşıyordu — o iddia C-208'de **yanlış** bulundu (`cycleUnit` düz-string, `kinematic_unit()` çökme veriyordu; C-207 çökmeyi durdurdu ama HARVESTABİLİTE hâlâ ÖLÇÜLMEDİ). Yani "kısmen var" = yapı var, doğrulanmış hasat YOK. |
| **KISMEN VAR — bu gece, henüz COMMIT EDİLMEDİ** | **1** | `ballet_barre` (`bb_plie.json`) — C-216/C-217'nin taslağı. **Bu bir istisna, örnek değil:** yalnız arama parametreleri taşıyor, `validate_content.py` 4 şema hatasıyla reddediyor, disk üzerinde ama git'te YOK. Mekanizma kanıtlandı (1 gerçek pencere), havuz ≥3 tabanının altında (C-217) — bu yüzden `ballet_barre` hâlâ `comingSoon`, değişmedi. |
| **BAŞKA SEBEPLE KAPALI — içerik-üretim ÖNCESİ bir karar bekliyor** | **2** | `garba`, `twerk_reggaeton` — `culturalReviewLedger`de `ruling: open` (kimin karar vereceği: koordinatör/kurucu). Sıfır içerik taşımaları diğer 25'le AYNI görünür ama AYRI bir blokörleri var: hula'nın ölçütüyle aynı sınıf mı değil mi kararı verilmeden içerik üretimi başlamamalı. **Bir sonraki oturum bunları "sıradaki kolay aday" sanıp seçmemeli.** |
| **GERÇEKTEN İÇERİKSİZ — başka blokörü yok, yalnız sıra bekliyor** | **25** | Geri kalan hepsi (`latin_fusion_fitness` `line_dance` `tiktok_format` `kpop_point` `bachata_solo` `afrobeats` `belly_dance` `bollywood` `merengue_solo` `cumbia_solo` `ballroom_latin_solo` `tap` `locking` `popping` `waacking` `vogue` `jazz` `solo_jazz_charleston` `bhangra` `contemporary` `flamenco` `irish_dance` `kizomba_zouk_solo` `heels` `breaking`). Hepsinde `originAttribution`/`description`/`stepGlossary`/`cameraLimits` metni YAZILI (33/34 sayımının parçası) — eksik olan yalnız `steps/*.json`. |

**Not:** `contemporary` `culturalReviewLedger`de de geçiyor ama `ruling: cleared`
(çözülmüş) — "başka sebeple kapalı" kümesine GİRMİYOR, 25'in içinde.

## `ballet_barre`/plié'nin yeni durumu — adıyla (C-215/C-216/C-217)

**Mekanizma KANITLANDI, havuz TABAN-ALTI.** İki ayrı, gerçek sonuç:
- `enter.metric` / `knee_flexion_mean` dispatch'i (C-207) plié'de GERÇEKTEN
  çalışıyor — `27skzncX3Ms` gerçek bir pencere üretti (12,0s, periyot 1,583s).
- 7 aday araştırıldı (R14), 6'sı gerçek adaydı, 6/6 koşuldu (C-217) — yalnız
  **1 katkı veren take**. Katalog §6.0'ın **≥3 bağımsız eğitmen TABANININ**
  altında — sözleşmenin 5-eşiği (`provisional`) bile henüz uygulanamıyor,
  referans hiç KURULAMIYOR.

**Bir sonraki tur için çerçeve (koordinatör hükmü, isimle korunuyor):**
> Sıradaki iş **"3'e ulaşmak için 2 aday bul"** DEĞİL, **"plié malzemesini
> düzgün tara ve NE VARSA raporla."** Durma kuralı SAYI ise uydurmadır;
> durma kuralı MALZEME ise ölçümdür. Bu gece havuz bilerek büyütülmedi —
> yeni bir arama turu taze bir oturumun işi.
