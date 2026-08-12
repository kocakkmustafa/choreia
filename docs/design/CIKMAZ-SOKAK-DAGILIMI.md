---
tur: olcum
proje: choreia
guncelleme: 2026-08-12
---

# Choreia — 33 çıkmaz sokağın SEBEBİ (A/B/C dağılımı)

**Sevk (koordinatör):** *"34 stilin 33'ü çıkmaz sokak"* bir **sayı**; kurucuya
giden soru **sebebe** bağlı. **A** içerik yok (aylar) · **B** içerik var ama
bağlı değil (saatler) · **C** kart zaten olmamalıydı (yüzey).
⛔ Tek kovaya koyma · payda+işlem bas · **hiçbirini düzeltme**.

**Payda:** 34 stil − **1** başlatılabilir ders taşıyan stil
(`hip_hop_foundations` → `hh_l1_bounce`) = **33**.

---

## Dağılım — ve sevkin üç sınıfına SIĞMADI

| sınıf | sayı | ne demek |
|---|---|---|
| **A — içerik hiç yazılmamış** | **29** | ne adım JSON'u ne referans var |
| **A′ — içerik BAŞLAMIŞ, referans yok** | **3** | adım JSON'u git'te, ama `collectedTakes: 0` — engel **hasat** |
| **B — içerik var, bağlı değil** | **0** | kablolama boşluğu **bulunamadı** |
| **C — kart olmamalıydı** | **0** | liste **kurucu onaylı bir standardın** sonucu (aşağı bak) |
| **D — içerik TAM + BAĞLI, ama bilerek KAPALI** | **1** | `salsa_shines` — ölçüm-dürüstlüğü kapısı, **adı konmuş ~10 dakikalık kurucu işi** |

**29 + 3 + 0 + 0 + 1 = 33** ✓

### Ölçüm nasıl yapıldı

`content/styles/*/steps/*.json` × `content/references/*.json` × `pubspec.yaml`
kesişimi; blok sebebi uygulamanın **kendi** dört-yönlü taksonomisinden
(`LessonBlock`: `styleShut` · `measurementMissing` · `noLessonBuilt` ·
`referenceMissing`). **34 stilin yalnız 5'i herhangi bir içerik taşıyor:**
`dancehall` · `hip_hop_foundations` · `salsa_shines` · `samba_no_pe` ·
`shuffle`.

---

## A′ (3) — `dancehall` · `samba_no_pe` · `shuffle`

Adım JSON'ları **git'te** ama üçünde de `reference.collectedTakes = 0`,
`status: not-started`. Bugün ölçüldü (C-219): **blokör mekanizma değil
MALZEME** — hasat hattı bu adımlar için çalışıyor, hasat edilecek take yok.
→ **A ile aynı işe çıkar** (içerik üretimi), ama başlangıç noktası daha
ileride: yapı yazılmış, take bekliyor.

## D (1) — `salsa_shines`: sevkin sınıflarında YOK, ve en önemlisi bu

Tek stil `contentOnDisk: true`, durumu **`live`**, **iki dersi** tanımlı
(`ss_l1_footwork`→`ss_shine_footwork`, `ss_l1_basic`→`ss_basic`),
referansı **diskte VE `pubspec`te**. Yani **kablolama tam.**

Açılmamasının sebebi **bilerek konmuş bir sevk kapısı**:

```
shipGates: [{ gate: "bpmResolved", blocked: true,
  why: "bpmRange unresolved (bpmStatus DISPUTED — two research passes ~2x
        apart, 89-100 vs 160-220). A beat grid off by 2x scores half a
        learner's correct steps as misses, so no lesson in this style may
        ship until one measurement settles it.",
  unblockedBy: "tools/beat_annotate.py live tap on one known track
                (founder, ~10 min)" }]
```

**Bu bir eksiklik değil, bir DÜRÜSTLÜK kararı:** 2× kayık bir vuruş ızgarası,
öğrencinin **doğru** adımlarının yarısını **ıska** sayar. Kod bunu adıyla
söylüyor: *"kapalı bir sevk kapısı, sağlıklı bir içerik durumunu **geçersiz
kılar**"* — açılabilir göstermek *"yakında yasağının ayna görüntüsü"* olurdu.

→ **İş boyu: aylar değil, saatler değil — ~10 DAKİKA**, ve **kurucunun**.
Elde bir bilinen parçaya canlı tap; sonra `beats`/`countLabels` doluyor,
`STEP_LATE` açılıyor, ders-akışının 3. adımı (*"vuruşla dene"*) açılıyor.

## C (0) — kart listesi bir NİYET BEYANI, ve bu KURUCU ONAYLI

`library.json`'ın kendi alanları cevabı veriyor:
- `generatedFrom: "docs/CHOREIA-BLUEPRINT.md (M-F-18, **kurucu onaylı**)"`
- `note: "Standart §2: kapsamın TAMAMI kullanıcıya baştan görünür; açılmamış
  stiller 'yakında' durumundadır, ama **SAHTE/boş kurs asla listelenmez**.
  Dalga = motor rollout sırası, ürün vaadinin tavanı DEĞİL."`
- Her stilde `wave: 1..5` — yani liste bir **sıralanmış yol haritası**.

→ **34 kartı göstermek kaza değil, beyan edilmiş bir standart.** *Bir listenin
nereden geldiği ne vaat ettiğini belirler* (koordinatör): bu liste bir içerik
envanteri **değil**, kurucu onaylı bir kapsam beyanı.

⚠️ **Ama bir gerilimi adıyla yazıyorum:** standart *"kapsamın tamamı görünür,
ama sahte/boş kurs listelenmez"* diyor. Bu, **yüzeyin "yakında"yı dürüstçe
göstermesi koşuluna** bağlı. Gezilebilirlik kuralında *"çıkmaz sokak"*
dememin sebebi bu koşulun **kullanıcı tarafındaki** karşılığı: karta gidilir,
sayfa açılır, ders yoktur. İkisi **çelişmiyor** — biri **niyeti**, öteki
**deneyimi** tarif ediyor. Hangisinin raporlanacağı bir **yüzey kararı**,
ve bende değil.

## 29'un içinde AYRI blokörü olanlar (adıyla)

- `hula` — `ruling: held` (kurucu direktifi)
- `garba` · `twerk_reggaeton` — `culturalReviewLedger` `ruling: open`,
  **kurucuda**; içerik üretimi kararı beklemeden başlamamalı

Yani 29'un **3'ü** salt sıra beklemiyor, **kurucu kararı** bekliyor.
