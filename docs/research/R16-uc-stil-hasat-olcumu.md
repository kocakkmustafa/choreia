---
tur: olcum
proje: choreia
guncelleme: 2026-08-12
---

# R16 — `dancehall` · `shuffle` · `samba_no_pe`: hasat edilebilirlik ÖLÇÜMÜ

**Sevk (koordinatör):** *"Kapat demiyorum: ÖLÇ. Malzeme var mı, hasat yürüyor
mu, hangisi tabanı (≥3) geçiyor — tara ve NE VARSA raporla."*
**Sınır (aynı sevk):** C-208'in *"hasat edilebilir"* iddiası **devralınmadı**,
sıfırdan ölçüldü. Üçü de taban-altı çıkarsa **o da bir sonuçtur**.

---

## Cevap, tek cümlede

**Üçü de taban-altı — ama plié'den FARKLI bir sebeple: blokör MEKANİZMA değil
MALZEME.** Hasat hattı bu adımlar için çalışıyor; hasat edilecek hiçbir take
yok. Bu, "hasat edilemiyor" değil **"hasat edilecek şey yok"** demektir, ve
ikisi aynı iş kalemine çıkmaz.

---

## 1. MALZEME ekseni — ölçülen: SIFIR

`~/motion-harvest/choreia/landmarks` havuzunda **59 fixture** var. Üçünün
hiçbirine ait **tek take yok**. Havuzun tamamının dağılımı (her fixture'ın
kendi `provenance.channel` + `recordingMeta.technique`/`movement` alanından
okundu, elle atfedilmedi):

| adım | havuzdaki fixture |
|---|---|
| `salsa_shines` | 21 |
| `hh_roger_rabbit` | 13 |
| `hh_running_man` | 8 |
| `hh_bounce` (STEP_OF'ta atıfsız, `provenance.movement` yazıyor) | 7 |
| ballet plié (dün gece, C-215/217 — `movement` alanı boş) | 6 |
| `salsa_basic` (atıfsız) | 4 |
| **`dh_bounce` · `sh_running_man` · `sh_t_step` · `sm_samba_no_pe`** | **0** |
| **toplam** | **59** |

⚠️ Bu sayılar `probe_candidates.py --used`'ın çıktısından (15/9/24) DÜŞÜK:
o araç `STEP_OF` haritasındaki **tüm** id'leri sayar, havuzda dosyası olup
olmadığına bakmaksızın. Yukarıdaki tablo **havuzdaki gerçek dosyalardan**
sayıldı. *Haritada olmak indirilmiş olmak değildir* — C-212'nin
("aracın varlığı boru hattına bağlı olduğu anlamına gelmez") veri tarafı.

**POZİTİF KONTROL — "sıfır" vakum değil:** aynı okuma kanalı 6 ayrı adım için
DOLU değer üretti (`probe_candidates.py --used` üç adımı isimle listeliyor;
`provenance.movement` 7 `hh_bounce` + 3 `running_man` + 4 `salsa_basic`
fixture'ında yazılı). Kanal bulabildiğini kanıtladı; bu üç stil için
bulmadı.

**İçeriğin KENDİSİ de aynı şeyi söylüyor** — iddia benim değil, dosyaların:
her üç step JSON'unda `reference.collectedTakes = 0`,
`reference.status = "not-started"`, `requiredTakes = 3`.

### Aday listesi var mı — bu da ölçüldü

| stil | aday listesi | not |
|---|---|---|
| `dancehall` | **YOK** | R1 stil kataloğunda stil-düzeyi araştırma var (Bogle/Willie Bounce/Whine, BPM 80-108, Dutty Wine güvenlik riski) ama **tek bir videoId adayı bile yok** |
| `samba_no_pe` | **YOK** | aynı |
| `shuffle` | **KISMEN VAR — 3 aday, hiçbiri hasat edilmemiş** | R11 §2'de: `b6075roLFmo` ("SHUFFLE TUTORIAL // The Foundations: **Running Man & T-step**" — İKİ shuffle adımını da adlandırıyor) · `94GApB4ul1I` ve `LdovZRXWzQ0` (ikisi de `/shorts/`, **dikey** — bilinen ret sınıfı) |

**POZİTİF KONTROL:** aynı tarama 5 R-notunda **78 aday satırı** buldu
(R10:19 · R11:30 · R12:3 · R8:18 · R9:8) — yani "dancehall/samba için sıfır
aday" ölçülmüş bir yokluk, aracın körlüğü değil.

---

## 2. MEKANİZMA ekseni — ölçülen: hat ÇALIŞIYOR, faz-sürücülü seçim devrede DEĞİL

Dördü de gerçek bir fixture'a karşı koşuldu. **Bu bir hasat değil, YOL
ölçümüdür** — kullanılan take (`AyzYABnWDEM`) bir `hh_bounce` take'idir, bu
stillere ait değildir; ölçülen tek şey *"dispatch devreye giriyor mu"*.

| adım | `phases[].enter.metric` | `cycleUnit` | dispatch | genel yol sonucu |
|---|---|---|---|---|
| `dh_bounce` | `knee_flexion_mean` (167°) | **düz dizge** | ATLANIYOR (isimli log) | ✓ hazır, 27,0s / 1,37s |
| `sm_samba_no_pe` | `knee_flexion_mean` (166°) | **düz dizge** | ATLANIYOR | ✓ hazır, aynı |
| `sh_running_man` | `knee_flexion_mean` (165°) | **düz dizge** | ATLANIYOR | ✓ hazır, aynı |
| `sh_t_step` | `thigh_rotation` (`valueDeg: null`) | **düz dizge** | ATLANIYOR | ✓ hazır, aynı |

**Okunuşu — plié'yle KARŞITLIK burada:** plié'de genel (tüm-vücut enerji) yol
**SIFIR** pencere buluyordu (C-215), o yüzden `knee_flexion_mean` dispatch'i
plié için ZORUNLUYDU. Burada genel yol **çalışıyor ve segment üretiyor** —
yani bu üç adım için faz-sürücülü seçim bir ön koşul DEĞİL, bir iyileştirme.
`cycleUnit`'i nesneye çevirmek (C-207'nin kalan alt-parçası) bu stillerin
hasadını AÇMAZ; onu açan tek şey take'tir.

**`sh_t_step` ayrıca ikinci bir kapıyla da kapalı** (bugün maskeli, çünkü
dispatch zaten atlanıyor): `thigh_rotation` `content/metric-vocabulary.json`'da
`family`/`jointRef` TAŞIMIYOR → C-207'nin isimli reddine düşer. Ve
`valueDeg: null` (`"unset until harvest"`) — yani eşiği hasat belirleyecek,
hasat ise take bekliyor.

---

## 3. Hüküm: her üçü de TABAN-ALTI, ve mesafe bir FETCH kadar

| stil | tabana (≥3) uzaklık | blokör |
|---|---|---|
| `dancehall` | 3 take | malzeme **+ aday listesi bile yok** (arama turu gerekir) |
| `samba_no_pe` | 3 take | aynı |
| `shuffle` (`sh_running_man`) | 3 take | malzeme; **1 yatay aday hazır** (`b6075roLFmo`), 2'si dikey-ret |
| `shuffle` (`sh_t_step`) | 3 take | malzeme + `thigh_rotation` sözlük kaydı + eşik (hasattan türetilecek) |

**1 → 4 başlatılabilir ders yolu AÇIK ama bugün DEĞİL:** hiçbir yapı icat
edilmesi gerekmiyor (step JSON'lar git'te, sürücü ölçülmüş aileden, genel yol
çalışıyor) — gereken tek şey **gerçek take**. En ucuz giriş `shuffle`:
elde adı iki adımı birden vaat eden bir yatay aday var.

⛔ **Havuz BÜYÜTÜLMEDİ, aday aranmadı** — sevk "ÖLÇ" dedi, "getir" demedi.

---

## 4. Tarama sırasında ÇIKAN, sevkin parçası olmayan bulgu

Detay ve kanıt: **DEFTER C-220**. Özet: `hh_running_man`'in **yayınlanan**
referansının 4 kaynağından biri (`ZpTgAZBYNrU`, DNCR Dance Tutorials) başlığında
*"Beginner **Shuffle Dance** Tutorial"* yazıyor ve referansın **24 çevriminin
12'sini** tek başına taşıyor. Choreia'nın kendi içeriği
(`sh_running_man.json`'un notu) shuffle'ın running man'inin hip-hop'unkinden
**AYRI bir adım, ayrı bir referans** olduğunu söylüyor. R8 aynı riski iki
başka aday için **adıyla** işaretleyip onları dışarıda bırakmış; bu aday
R11'de yalnız "başlangıç seviye, yatay görünüyor" notuyla geçmiş — **kimlik
sorusu ona hiç sorulmamış.**

**Ölçülmeyen ve benim hükmüm OLMAYAN:** videodaki dansçının hangi adımı
yaptığı. Kinematik karşılaştırma da bugün koşulamıyor, ve sebebi ölçüldü:
`hh_running_man`'in `content/styles/` altında **step config'i yok** (referans
var, adım yok) — `probe_knee_dips --step hh_running_man` bu yüzden
`adım config'i bulunamadı` diyor.
