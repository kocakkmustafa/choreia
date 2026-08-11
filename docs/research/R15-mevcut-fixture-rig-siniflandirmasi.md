---
tur: envanter
proje: choreia
guncelleme: 2026-08-12
---

# R15 — Mevcut 53 fixture'ın rig sınıflandırması (koordinatör hükmü, C-213 devamı)

**Bu not `provenance` alanının VARLIĞINI okur, DEĞERİNİ değil** (koordinatör
dersi): `toolVersions.harvestRig` yalnız CANONİCAL `manifest.py`'de yazılır
(`versions["harvestRig"] = rig_version()`, satır 176); BAYAT (paylaşımlı
ağaç) kopyada bu kod hiç yok. Yani alanın **yokluğu** o fixture'ı bayat
rig'in ürettiğinin kanıtı — SHA'ya bakmaya gerek yok, ANAHTARIN kendisi
sürüm imzası.

## Sınıflandırma (2026-08-12, `ls`+`json.load` ile ölçüldü)

| Sınıf | Sayı | `retrievedAt` | Kanıt |
|---|---|---|---|
| **BAYAT-KUŞAK rig** (`toolVersions.harvestRig` alanı YOK) | **46** | 2026-07-28 / 07-29 | Alan hiç yazılmamış — yazan kod o kopyada yok |
| **KANONİK rig** (alan VAR, `sha`/`observedSha` o an `None`) | **7** | 2026-07-30 (R13 turu — `hh_bounce` adayları) | Alan yazılmış ama `rig_version()` o çalıştırmada "takip edilmiyor" dalına düştü (muhtemelen `git show` ile scratchpad'e çıkarılmış kopyadan koşulmuş, PARK-DURUMU.md'nin tarif ettiği desen) |

**7 kanonik-kuşak dosya:** `1IVtcoqMrBA` `4BRd2E8vBic` `AyzYABnWDEM`
`DEWpw4n8Lkw` `NWB9Y1_lZDQ` `l3r4bPhikGQ` `nOR1qEhpssg` — hepsi R13'ün
(`hh_bounce` aday havuzu) kendi listesiyle birebir örtüşüyor.

**46 bayat-kuşak dosya:** hip-hop temel adımlar (cabbage patch, roger
rabbit, running man) + salsa shines turlarının tamamı — bu notun EK'inde
tam liste.

## `rig_version()` NEDEN `None` DÖNDÜ — ölçüldü, kod BOZUK DEĞİL

Kanonik rig'in KENDİSİ doğru çalışıyor — bugün `~/motion-worktrees/
coordinator-main/tools/harvest_rig/manifest.py`'den `tool_versions()`
doğrudan çağrıldı ve GERÇEK bir SHA döndürdü:

```
sha: 63a0b3edd0e5acffb87edee0d61e65697b073faf · dirty: false ·
branch: main · behindOriginMain: 0 · onMainLineage: true
```

Yani sorun KOD değil, **koşum konumu**: `rig_version()` `git -C <dosyanın
bulunduğu dizin> ls-files --error-unmatch` ile dosyanın O KONUMDA takip
edilip edilmediğini soruyor. Bir `git show` ile scratchpad'e ÇIKARILMIŞ
kopya (içerik var, `.git` yok) bu testi doğası gereği geçemez — `sha: None`
BU YÜZDEN döner, ve bu **tasarım gereği**: takipsiz bir kopyanın SHA'sını
uydurmak, gerçek olmayan bir güven verirdi (manifest.py'nin kendi
gerekçesi, satır 41-49).

**Sonuç: fetch, rig'in KENDİ GERÇEK git konumundan (`~/motion-worktrees/
coordinator-main/tools/harvest_rig/`) çalıştırılmalı — `git show` ile
çıkarılmış bir scratch kopyadan DEĞİL.** Bu bir kod düzeltmesi değil, bir
koşum-disiplini kaydı.

## Bu notun kapsamı — bilerek YAPILMAYAN

- **53 fixture yeniden hasat edilmedi.** Koordinatör sınırı: ayrı ve pahalı
  bir karar (ham video bağımlılığı, M-F-433), gerekirse ayrıca konuşulur.
- **46 fixture'ın kendi JSON dosyaları DEĞİŞTİRİLMEDİ** — bulk script ile 46
  büyük, gitignored (geri alınamaz) dosyayı elle düzenlemek gereksiz risk
  taşırdı. Bunun yerine bu İNDEKS git'e alınıyor — sonraki oturum
  fixture'ın kendisine değil buraya bakabilir.
- Yeni fetch (6 aday, `bb_plie`) henüz BAŞLAMADI — bu not onun ÖN KOŞULUYDU.

## Ek — 46 bayat-kuşak fixture'ın tam listesi

```
-8W2bnjrhE0  0UDxiThjwG8  1F9qFAW_khY  2Zf1U7ViIz8  35sk_G8Vf9o  3pg3AQ7puV0
3yldlm52GRE  5MQEtoEKdEw  7km54RpMuL8  9NZp9_GuKrE  C4fsMsgVN0w  Ce3NCRk1Nl4
DEFnniCN7ok  E6GfqbvDJfU  FtZzjGsPxjg  GXKNLmjxodU  Hki7w5Agwgg  KV-sxd_pQ9w
Ns5TaVGv6uY  Nzy-uJBeWpc  OsQUi2l1ZE8  SHGkSbJm2Iw  UO9Ehsdt2IE  Wd29rBfAzkI
XQif9iHV5sE  XhqT7slTCfY  ZpTgAZBYNrU  _G-hONZsj1w  bdY2Pwqj-9A  bhmOeUJPJB0
blWeCJW2Peo  bqoNqA2hmE4  jjP8bKWCg9U  kUQTYnYDipk  lYpRasK4c9k  mE2fh2XzeNc
mSLyfmQyTiA  o6E9Ljr5o_c  pua9UszdO24  rRlUNGymhmE  selXuuAWI64  t7u8f8L2HK0
uCwim7nbkdE  v_y4l3lAZ0Q  w4opJ2ezmd4  wV8cDpJa2f4
```
