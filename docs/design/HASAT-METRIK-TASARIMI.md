---
tur: tasarim
proje: choreia
guncelleme: 2026-08-11
---

# Choreia — Hasat Hattı `enter.metric` Tasarımı (onay bekliyor)

**Kapsam bu belgenin sınırıdır — 22 sürücünün formülü değil, dispatch'in
ŞEKLİ.** Koordinatör sevkinin dört maddesi: ① metrik ailesi ② eklem referansı
③ birim ④ yorumlanamayan ad. İçerik (gerçek eşik sayıları, kalibrasyon)
onay SONRASI, kod yazılırken gelir.

## 0. Neden şimdi, ve neyin üstüne kuruluyor

`content/metric-vocabulary.json`: 24 sürücü adından **22'si `declaredOnly`**
— hiçbir araç okumuyor. `tools/prepare_take.py`'nin `kinematic_unit()` /
`select_by_phase_driver()` yolu bugün TEK aileyi tanıyor: diz fleksiyonu
(`_knee_mean_series`, hardcoded). Adım config'i `cycleUnit.driver` alanında
BAŞKA bir ad beyan etse bile kod sessizce dizi diz serisiyle işliyor —
isim etiket, davranışı belirlemiyor.

**Bu tasarımı yazarken canlı bir kanıt bulundu (ölçüldü, bugün):**

```
kinematic_unit('dh_bounce')       -> AttributeError: 'str' object has no attribute 'get'
kinematic_unit('sm_samba_no_pe')  -> AttributeError: 'str' object has no attribute 'get'
kinematic_unit('hh_bounce')       -> OK (dict)
```

`content/styles/*/steps/*.json` içinde `cycleUnit` alanı **6/8 adımda var,
ama İKİ FARKLI ŞEKİLDE**: `hh_bounce`/`hh_rock` yapılandırılmış nesne
(`{driver, dipsPerCycle,...}`), `dh_bounce`/`sm_samba_no_pe`/`sh_running_man`/
`sh_t_step` düz açıklayıcı STRING (`"vuruş başına bir sekme"` gibi).
`kinematic_unit()` ikinciyi hiç kontrol etmeden `.get()` çağırıyor —
DEFTER C-204'ün "dancehall + samba_no_pe hasat edilebilir" kaydı, bu
fonksiyon üzerinden değil başka bir yoldan (muhtemelen `--step` bayrağı
verilmeden, eski ankara-çapa yoluyla) doğru olmuş olmalı. Yani bu, ④'ün
soyut bir gerekçesi değil, **şu an gerçek, tetiklenebilir bir çökme.**

## ① Metrik aileleri

Üç aile, artı bir DIŞLANMIŞ sınıf. Ayrım rastgele değil — motion-core'un
kendi `AngleKind` üçlüsünü (`flexion` / `orientation` / `trunkTilt`) ve
`prepare_take.py`'nin zaten sahip olduğu iki hesaplama yolunu (eklem-açısı
serisi vs. çapa-tipi konum serisi) izliyor:

| Aile | Tanım | Bugünkü emsal | Kapsadığı sürücüler (22'den) |
|---|---|---|---|
| **A — Fleksiyon** | Bir eklemdeki büzülme açısı, işaretsiz 0–180° | `_knee_mean_series` (zaten var, tek aile bu) | `knee_flexion_mean/amplitude/lr_difference` |
| **B — Yönelim** | Bir segmentin gövde eksenine göre işaretli açısı | `TRUNK_TILT` hesaplaması (zaten var, `trunk_tilt` bunun üstünden "interpreted") | `shin_angle_mean/amplitude`, `thigh_rotation`, `thigh_rotation_amplitude`, `trunk_tilt_amplitude`, `left_thigh_forward`, `right_thigh_back`, `step_thigh_excursion` |
| **C — Konum/türetilmiş-durum** | Ham `(x,y)` işaret noktasından, gövde-normalize, açı DEĞİL | `leading_foot_signal` + `find_anchor` (çapa için zaten var, ama adlandırılmış/yeniden-kullanılabilir bir metrik olarak DEĞİL) | `hip_lateral_shift`, `weight_side`, `weight_balance`, `leading_side`, `feet_settled`, `movement_during_hold`, `loaded_leg_knee_change` (bileşik — bkz. §4) |
| **DIŞLANMIŞ — Ritim** | Vuru ızgarasına bağlı | Yok, ve **olmayacak** | `bottom_beat_phase`, `timing_verdict` |

**Ritim ailesi neden dışlanıyor, "henüz yok" değil "olmayacak":** CLAUDE.md
sert kuralı + coordinator'ın bu sevkteki sınırı ikisi de aynı şeyi söylüyor —
*ritim/zamanlama puanı yok*. `judge.dart`'ta `STEP_LATE` zaten kalıcı
`noVerdict` (beat grid yok, BPM disputed). Hasat hattı bu iki adı
**"unknownDriver" değil, "outOfScope: rhythm scoring"** diye reddetmeli —
farklı bir ret sınıfı, çünkü sebep "henüz yazılmadı" değil "yazılmayacak".

**`side_agreement` bu tabloda YOK, kasıtlı:** `judge.dart`'taki
`SideAgreement` sınıfı bunu ÇALIŞMA-ZAMANINDA zaten yorumluyor —
öğrenci-vs-referans karşılaştırması, hasat hattının hiç sahip olmadığı bir
kavram (hasat yalnız ham eğitmen take'lerini işler, "öğrenci" yok). Sözlük
kapısının bunu `declaredOnly` görmesi ayrı, küçük bir kusur (dize eşleşmesi
`SideAgreement` sınıf adını yakalamıyor) — bu tasarımın kapsamı DEĞİL,
notu düşülüyor.

## ② Eklem referansı

A ve B aileleri motion-core'un **pinli, kapalı** 17 eklemlik sözlüğünden
gelir (`packages/motion_core/lib/src/geometry/joint_angles.dart`,
`motion_core-v0.5.0`) — `prepare_take.py` zaten bunu `check_vocabulary()`
ile doğruluyor, yeni bir sözlük İCAT EDİLMİYOR:

- A: `left/right_{elbow,shoulder,hip,knee}` (8 fleksiyon)
- B: `left/right_{upper_arm,forearm,thigh,shin}` + `trunk_tilt` (9 yönelim)

Sürücü adından eklem adına dönüş **son-ek sözleşmesiyle**: `knee_flexion_*`
→ `left_knee`+`right_knee` ortalaması (bugünkü `_knee_mean_series`'in
GENELLEŞTİRİLMİŞ hâli); `thigh_rotation*` → `left_thigh`+`right_thigh`;
`shin_angle_*` → `left_shin`+`right_shin`. Bu, içerik değil kural — hangi
TEKİL eşiklerin hangi takeler'den geleceği (içerik) onay sonrası.

C ailesi motion-core'un açı sözlüğünde YOK — ham `(x,y)` gerekiyor. Bugün
yalnız çapa için `L_ANKLE/R_ANKLE` (`prepare_take.py:73-75`) tanımlı. Yeni,
KÜÇÜK bir tablo gerekiyor (yeni bir mimari değil, `JOINT_TRIPLETS`'in
konum-eşleniği):

```
POSITION_LANDMARKS = {
  "hip_lateral":   (L_HIP, R_HIP),      # hip_lateral_shift, weight_side, weight_balance
  "ankle_lateral": (L_ANKLE, R_ANKLE),  # zaten var — leading_side bunun üstünden
}
```

`loaded_leg_knee_change` **bileşik**: önce C (`weight_side` — hangi bacak
yüklü) sorulur, SONRA o bacağın A (diz fleksiyon değişimi) serisi okunur.
Bugünkü düz dispatch (`driver` → tek seri) bunu ifade edemez; tasarımın
④'e bağlı kararı bu yüzden "kayıt tipini genişlet" değil "kayıt DIZISI
kabul et" olmalı (bkz. §4, açık soru 2).

## ③ Birim

| Aile | Birim | Kaynak sözleşme |
|---|---|---|
| A | işaretsiz derece (0–180°) | `angle_at()`, zaten var |
| B | işaretli derece (-180,180], **ayna altında NEGATİF olur** | `signed_angle_to()` + `judge.dart`'taki `orientationJoints` — **iki katmanın da AYNI işaret sözleşmesini kullanması ZORUNLU**, yoksa harvest'te ölçülen bir eşik runtime'da farklı bir şey söyler |
| C (sürekli) | gövde-boyu oranı (birimsiz), `leading_foot_signal`'daki `torso`'ya bölme ile AYNI normalize | zaten var, `find_anchor`'ın `swing`/`peak` alanları |
| C (kategorik) | `"left"` / `"right"` dizgesi, VEYA boolean (`feet_settled`) | yeni ama `find_anchor`'ın `leadingFoot` alanıyla AYNI sözleşme |

## ④ Yorumlanamayan ad — isimli ret

Bugünkü davranış (yok): `kinematic_unit()` `unit["driver"]` dizgesini hiç
doğrulamadan kullanır → ya sessizce YANLIŞ diz serisini okur (adı bilinmeyen
ama nesne-şekilli bir `cycleUnit` için) ya da çöker (adı bilinmeyen ve
STRING-şekilli bir `cycleUnit` için, kanıt §0). İkisi de "isimli ret" DEĞİL.

**Önerilen sözleşme** (şekil, kod değil):

1. **Şekil kapısı önce.** `cycleUnit` bir nesne DEĞİLSE (`dh_bounce` gibi
   düz string), `kinematic_unit()` `None` dönüp eski (ankara-çapa) yola
   düşmeli — string bir cycleUnit "bu adım kinematik dispatch İSTEMİYOR,
   yalnız insan-okur açıklama taşıyor" demektir, ve bu MEŞRU bir durum,
   hata değil (bugün 4 adım böyle). Ama bu geçiş **isimli loglanmalı**
   ("adım X: cycleUnit string, faz-sürücülü seçim atlanıyor") — sessiz
   DEĞİL, çünkü aksi hâlde bir yazarın nesne yazmayı UNUTMASI ile
   BİLEREK string yazması ayırt edilemez (aynı "bulunamaz ↔ bakılmadı"
   ayrımı, bu sefer şema düzeyinde).
2. **Ad kapısı sonra.** `cycleUnit` bir nesnEYSE, `unit["driver"]` bir
   KAYITLI aile-üye adı (A/B'nin son-ek sözleşmesiyle çözülen bir eklem
   VEYA C'nin tablosunda bir giriş) değilse: `SystemExit` — adımın id'si +
   bilinmeyen sürücü adı + "bu ad content/metric-vocabulary.json'da var mı,
   varsa hangi ailede olması gerekiyor" sorusuyla. Dosyadaki idiomla aynı
   ton (`load_take()`'in fps kontrolü, `check_vocabulary()`) — bu depoda
   zaten "sessiz varsayılan yok" bir kural, yeni bir üslup İCAT edilmiyor.
3. **Ritim adları AYRI kod yoluyla reddedilir** (§1) — `unknownDriver`
   değil `outOfScopeRhythm`, çünkü ikisinin düzeltme yolu farklı (biri
   "kayıt eksik", öbürü "bu ürün kararı gereği asla yazılmayacak").

## Onay için açık sorular (koordinatöre)

1. **Son-ek sözleşmesi** (`_mean`/`_amplitude`/`_lr_difference` → eklem adı)
   yeterli mi, yoksa her sürücü adı content'te açık bir
   `"jointRef": "left_knee+right_knee"` alanı mı taşımalı? Sözleşme daha az
   yazım yükü ama gelecekte "iki farklı eklemden aynı son-ekli ad" çakışması
   riski taşır — bugün 22 adın hiçbiri çakışmıyor, ölçüldü.
2. **`loaded_leg_knee_change` gibi bileşik sürücüler** ilk sürümde
   kapsanacak mı, yoksa `④`'ün isimli-ret yolu bunları da (geçici olarak)
   "composite: henüz desteklenmiyor" diye mi işaretlesin? İkincisi daha
   küçük bir ilk kesim ama `ss_basic.error:NO_WEIGHT_TRANSFER`'ı kapsam
   dışı bırakır.
3. **`dh_bounce`/`sm_samba_no_pe`/`sh_running_man`/`sh_t_step`'in mevcut
   STRING `cycleUnit`'i** — bu tasarımın parçası olarak nesneye mi
   çevrilsin (içerik değişikliği, onay sonrası ayrı iş) yoksa string kalıp
   yalnız §④ madde 1'in "atla ve logla" yolundan mı geçsin? İkincisi bu
   dört adımı faz-sürücülü seçimin DIŞINDA bırakır — C-204'ün "hasat
   edilebilir" kaydı hangi yoldan doğru çıktıysa o yolda kalırlar.

Kod yazılmıyor. Onay/düzeltme bekleniyor.
