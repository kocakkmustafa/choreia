#!/usr/bin/env python3
"""Kimlik OKUMA kanalı — kabul edilmiş her kaynağın transkripti, ATANDIĞI
adımı çürütüyor mu? (C-231/C-233, koordinatör hükmü 2026-08-12)

NİYE VAR
--------
Kabul edilmiş 14 kaynağın 12'sinde kimlik sorusu araştırma notlarında HİÇ
YAZILMAMIŞTI (C-225), ve leave-one-out probu borcun dörtte üçüne ulaşamıyordu
(üç ön koşulu var: >=4 kaynak · beyan edilmiş hipotez · ölçüm taşıyan bölge).
Bu kanalın ön koşulu yalnız TRANSKRİPT — ve kabul edilmiş kaynakların
hepsinde var.

KAPI YALNIZ KIRMIZIDA ÖTER (koordinatör hükmü, ve gerekçesi kayda değer)
------------------------------------------------------------------------
Bir kapı, hattın KONTROL ETTİĞİ bir şeyi ölçmelidir. Transkript sessizliği
KAYNAK VİDEONUN özelliğidir, bu deponun işi değil — kimsenin düzeltemeyeceği
bir kırmızı, kapatılan bir kapıdır, ve kapatılmış kapı hiç olmayandan
kötüdür (kırmızıyı yok saymayı öğretir).

  KIRMIZI  transkript ATANMIŞ dersi ÇÜRÜTÜYOR (karıştırılabilir terim baskın)
           -> eyleme dönüşür: kaynağı çıkar ya da etiketi düzelt
  UYARI    pencerede/derste kanıt YOK -> BLOKLAMAZ, kütüğe yazılır
  ORTAM    transkript havuzu yok (taze klon) -> exit 2, ne yeşil ne kırmızı

⛔ "EN AZ N ✅" EŞİĞİ YOK, ve bu ÖZELLİKLE yasaklandı. Sebebi ölçüldü:
eğitmen adımı ÖNCE ANLATIR, SONRA SESSİZCE GÖSTERİR; hasat hattı ise tam o
GÖSTERİM penceresini seçer (hareket + kamera-temiz). Yani en iyi ÖLÇÜM
penceresi ile en iyi KANIT penceresi aynı yer değildir — kanal en çok
gerektiği yerde en sessizdir (`KV-sxd_pQ9w`in penceresinde 2 sözcük var).
Bir "≥N ✅" eşiği bu ters-ilişki yüzünden seçimi İYİ GÖSTEREN eğitmenden ÇOK
KONUŞAN eğitmene kaydırırdı: bir eşik, ölçtüğü şeyi seçme baskısına
dönüşüyorsa ölçtüğü şeyi bozar.

SINIR — üç kez yazıldı, burada da yazılıyor
-------------------------------------------
Transkript SÖYLENENİ ölçer, YAPILANI değil. Segment düzeyinde bile bu bir
DERS KONUSU kanıtıdır, hareket kanıtı değil. Leave-one-out'un YERİNE GEÇMEZ;
onun ulaşamadığı yerde konuşur. Ve sessizlik ne aklanmadır ne mahkûmiyet —
ikisi de sessizlikten hüküm çıkarmak olurdu.

KULLANIM
    python3 tools/identity_read.py              # kapı (yalnız kirmizida 1)
    python3 tools/identity_read.py --register   # kütüğü yeniden üret
    python3 tools/identity_read.py --self-test
"""
from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
TRANSCRIPTS = Path(os.path.expanduser("~/motion-harvest/choreia/transcripts"))
REGISTER = REPO / "docs/design/IDENTITY-REGISTER.md"

# KÖK eşleme, tam sözcük DEĞİL: tam-sözcük sayımı "when you're SHUFFLING"i
# kaçırıyordu (ölçüldü, C-231). Ve ASR İngilizce olmayan adım adlarını FONETİK
# yazıyor ("cucaracha" -> "kukaraches"/"Kukuracep", ölçüldü) — bu yüzden
# İngilizce olmayan bir ad eklendiğinde okunuş varyantları da eklenmelidir,
# yoksa kanal yanlış SIFIR verir ve bunu tam olarak kimlik riskinin en yüksek
# olduğu stillerde (Latin, Afro-diasporik) yapar.
#
# `cites`: karşıtlığın nereden geldiği. Bu terimler UYDURULMADI — içeriğin
# kendi notlarından türetildi, ve `--self-test` o notların hâlâ o ayrımı
# yaptığını doğrular. Kaynak metin değişirse harita da gözden geçirilmeli.
TERMS: dict[str, dict] = {
    "hh_bounce": {
        "own": ["bounc", "hip hop", "hip-hop"],
        "confusable": ["rock", "dancehall"],
        "cites": {
            "content/styles/dancehall/steps/dh_bounce.json": "hip-hop",
            "content/styles/hip_hop_foundations/steps/hh_rock.json": "rock",
        },
    },
    "hh_roger_rabbit": {
        "own": ["roger"],
        "confusable": ["running man", "shuffl"],
        "cites": {},
    },
    "hh_running_man": {
        "own": ["running man"],
        "confusable": ["shuffl", "melbourne"],
        "cites": {"content/styles/shuffle/steps/sh_running_man.json": "hip-hop"},
    },
    "ss_shine_footwork": {
        "own": ["shine", "salsa"],
        "confusable": ["bachata", "cha cha", "merengue"],
        "cites": {},
    },
}


# HÜKME BAĞLANMIŞ ÇÜRÜTMELER — taban çizgisi, EŞİK DEĞİL.
#
# Niye var: koordinatör hükmü ikiye bölünüyordu — kapı çürütmede ötmeli, AMA
# `4BRd2E8vBic` AÇIK KALEM olarak kalmalı (kapatılmamalı). İkisi birlikte
# "kimsenin temizleyemeyeceği kalıcı kırmızı" demekti, ve o tam olarak
# koordinatörün yasakladığı şey: kapatılmış kapı, kırmızıyı yok saymayı
# öğretir.
#
# Çözüm bu depoda ZATEN var: `artifact_keyset_gate.py`nin taban-çizgisi
# deseni. Bilinen ve HÜKME BAĞLANMIŞ bir çürütme taşınır; YENİ bir çürütme
# ya da SAYILARI DEĞİŞMİŞ bir çürütme kırmızı yanar.
#
# ⚠️ Sayılar kaydın parçası: transkript ya da terim seti değişirse eşleşme
# bozulur ve kalem YENİDEN hüküm ister. Bir muafiyet, muaf tuttuğu ÖLÇÜMÜ de
# kaydetmiyorsa sessizce her şeyi muaf tutar.
ADJUDICATED: dict[str, dict] = {
    "4BRd2E8vBic": {
        "step": "hh_bounce",
        "own": 32,
        "confusable": 50,
        "why": "AÇIK KALEM (koordinatör hükmü 2026-08-12). Ders düzeyinde "
               "çürütme sinyali var ama SEGMENT penceresi SESSİZ (bounce 0 · "
               "rock 0, R17 §5) — iki ayrı aletin ikisi de hüküm veremedi. "
               "Kapatılmadı, leave-one-out'a havale edildi. Sessizlik ne "
               "aklanmadır ne mahkûmiyet.",
    },
}


WORDLIST = Path("/usr/share/dict/words")


def _soundex(w: str) -> str:
    """Kaba fonetik anahtar. NİYE: ASR İngilizce olmayan adım adlarını
    DUYDUĞU GİBİ yazıyor ('cucaracha' → 'kukaraches'/'Kukuracep', ölçüldü),
    ve tam-dizge sayacı bunlara SIFIR der."""
    w = re.sub(r"[^a-z]", "", w.lower())
    if not w:
        return ""
    codes = {**dict.fromkeys("bfpv", "1"), **dict.fromkeys("cgjkqsxz", "2"),
             **dict.fromkeys("dt", "3"), "l": "4",
             **dict.fromkeys("mn", "5"), "r": "6"}
    # ⚠️ STANDART SOUNDEX'TEN SAPMA, ve sebebi ölçüldü: klasik soundex İLK
    # HARFİ olduğu gibi korur. Ama ASR'nin yaptığı ikame tam orada —
    # "cucaracha" → "kukaraches" (c→k). Öz-test bu iki GERÇEK dizgeyle
    # koşuldu ve klasik anahtar ikisini de KAÇIRDI (C262 ↔ K262). İlk harf de
    # kodlanıyor: c ve k aynı sınıfa düşsün.
    out, prev = codes.get(w[0], w[0].upper()), codes.get(w[0], "")
    for ch in w[1:]:
        c = codes.get(ch, "")
        if c and c != prev:
            out += c
        if ch not in "hw":
            prev = c
    return (out + "000")[:4]


def near_hits(text: str, term: str) -> list[str]:
    """Metinde `term`in fonetik yakınları: fonetik anahtar EŞİTLİĞİ + uzunluk
    penceresi. İkisi de eşiksiz.

    ⛔ BURADA BİR BENZERLİK-ORANI EŞİĞİ VARDI, KALDIRILDI — ve sebebi
    ayarlama değil ÖLÇÜM. `cucaracha` (anahtar 2262) için ölçülen değerler:

        kukaraches  2262 ✓  oran 0,632   ← GERÇEK pozitif (transkriptten)
        kukuracep   2262 ✓  oran 0,444   ← GERÇEK pozitif (transkriptten)
        approach    A162 ✗  oran 0,588
        chacha      2200 ✗  oran 0,667
        coach       2200 ✗  oran 0,571

    Negatiflerin HEPSİ zaten ANAHTARLA eleniyor; oran ise TERS sıralıyor —
    `chacha` (0,667) gerçek pozitif `kukuracep`ten (0,444) yüksek. Yani eşik
    yalnız gereksiz değil, ZARARLI: gerçek vakayı eler, yanlışını geçirirdi.
    Bir ölçütü, ayırt ettiğini SANDIĞIN yönde ölçmeden eklemek, kapıya
    gürültü eklemektir."""
    key = _soundex(term)
    # ⚠️ ANAHTAR DOLU DEĞİLSE TARAMA YAPILMAZ, ve bu bir eşik değil terimin
    # KENDİ ÖZELLİĞİ: anahtar 4 semboldür; terim onu doldurmuyorsa (sonu
    # dolgu '0' ile bitiyorsa) anahtar iki-üç ünsüzden ibaret kalır ve
    # her şeye çarpar. Oranı kaldırdığımda ölçülen gürültü tam buydu:
    # `shuffl`(2140)~"couple" · `salsa`(2420)~"class" · `bachata`(1230)~"visit".
    # `cucaracha`(2262) · `merengue`(5652) · `dancehall`(3524) doludur.
    if key.endswith("0"):
        return []
    hits = []
    for tok in set(re.findall(r"[A-Za-z]+", text)):
        t = tok.lower()
        if t == term or term in t:
            continue
        if abs(len(t) - len(term)) > 3:
            continue
        if _soundex(t) == key:
            hits.append(tok)
    return sorted(hits)


def asr_fragile(term: str) -> tuple[bool, str]:
    """ÖLÇÜLÜR, tahmin edilmez (koordinatör ek hükmü): terim İngilizce sözlük
    sözcüğü değilse sayaç onda kırılgandır — ASR onu fonetik yazar.

    ⚠️ Fail-closed: sözlük yoksa 'kırılgan' varsayılır. Bilinmeyen bir terimi
    sağlam saymak, çıplak sıfırı güvenilir göstermek olurdu."""
    if " " in term:
        parts = [asr_fragile(p) for p in term.split()]
        return (any(p[0] for p in parts), "çok sözcüklü: " +
                ", ".join(f"{p}={'kırılgan' if f else 'sağlam'}"
                          for p, (f, _) in zip(term.split(), parts)))
    if not WORDLIST.exists():
        return (True, "sözlük yok — fail-closed, kırılgan sayıldı")
    words = {w.strip().lower() for w in WORDLIST.read_text(errors="ignore").splitlines()}
    if term in words:
        return (False, "İngilizce sözlük sözcüğü")
    return (True, "sözlükte yok — ASR fonetik yazabilir")


def shipped_references() -> list[Path]:
    """Kapsam `pubspec`ten TÜRETİLİR, dizin listesinden değil — dizin derleme
    defteri de taşıyor ve elle bir dışlama listesi bir sonraki defter
    dosyasında sessizce yanlış olur (C-230'da ölçüldü). Bu kanal CİHAZA
    GİRENİ ölçmeli."""
    out = []
    for line in (REPO / "pubspec.yaml").read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if s.startswith("- content/references/"):
            out.append(REPO / s[2:])
    return out


def verdict(counts_own: int, counts_conf: int, words: int) -> str:
    if words == 0:
        return "SESSIZ"
    if counts_conf > counts_own:
        return "KIRMIZI"
    if counts_own > counts_conf:
        return "TEYIT"
    return "KANIT_YOK"


def read_lesson(video: str, terms: dict) -> tuple[str, int, int, int, list[str]]:
    """Dördüncü dönüş değeri: KÖR terimler — `asr-fragile` olup metinde
    çıplak sıfır veren, ama fonetik yakını BULUNAN terimler. Koordinatör ek
    hükmü: böyle bir terimde çıplak sıfır RAPOR EDİLEMEZ."""
    p = TRANSCRIPTS / f"{video}.transcript.json"
    if not p.exists():
        return ("TRANSKRIPT_YOK", 0, 0, 0, [])
    text = " ".join(x["text"] for x in json.loads(p.read_text(encoding="utf-8"))).lower()
    o = sum(text.count(w) for w in terms["own"])
    c = sum(text.count(w) for w in terms["confusable"])

    blind = []
    for term in terms["own"] + terms["confusable"]:
        if text.count(term):
            continue
        fragile, _ = asr_fragile(term)
        if not fragile:
            continue
        hits = near_hits(text, term)
        if hits:
            blind.append(f"{term}~{'/'.join(hits[:3])}")
    return (verdict(o, c, len(text.split())), o, c, len(text.split()), blind)


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()

    if not TRANSCRIPTS.is_dir() or not any(TRANSCRIPTS.glob("*.json")):
        print(f"⚪ ORTAM YOK: {TRANSCRIPTS} yok/boş — kimlik okuması YAPILMADI, "
              "doğrulanmadı. (Hasat havuzu bu makinede değil.)")
        return 2

    rows, red = [], []
    for ref in shipped_references():
        step = ref.name.replace(".json", "")
        terms = TERMS.get(step)
        doc = json.loads(ref.read_text(encoding="utf-8"))
        for src in doc.get("sources", []):
            v = src["videoId"]
            if terms is None:
                rows.append((step, v, "TERIM_YOK", 0, 0, 0, []))
                continue
            vd, o, c, w, blind = read_lesson(v, terms)
            rows.append((step, v, vd, o, c, w, blind))
            if vd == "KIRMIZI":
                red.append((step, v, o, c))

    if "--register" in sys.argv:
        write_register(rows)
        print(f"kütük yazıldı: {REGISTER.relative_to(REPO)}")

    for r in rows:
        if r[6]:
            print(f"  ⚠️ SAYAÇ KÖR — {r[1]} ({r[0]}): {', '.join(r[6])} — bu "
                  f"terimde çıplak sıfır GÜVENİLİR DEĞİL (ASR fonetik yazmış "
                  f"olabilir)")

    counts: dict[str, int] = {}
    for r in rows:
        counts[r[2]] = counts.get(r[2], 0) + 1
    print("kimlik okuması (ders düzeyi): " +
          " · ".join(f"{k}={v}" for k, v in sorted(counts.items())))

    fresh = []
    for step, v, o, c in red:
        k = ADJUDICATED.get(v)
        if k and k["step"] == step and k["own"] == o and k["confusable"] == c:
            print(f"  📌 {v} ({step}): çürütme sinyali TAŞINIYOR — açık kalem, "
                  f"sayılar değişmedi (kendi={o} karışt={c})")
        else:
            fresh.append((step, v, o, c, bool(k)))

    if fresh:
        for step, v, o, c, was_known in fresh:
            if was_known:
                print(f"  🔴 {v} ({step}): hükme bağlanmış kalemin SAYILARI "
                      f"DEĞİŞTİ (şimdi kendi={o} karışt={c}) — kayıt bayat, "
                      f"kalem yeniden hüküm istiyor")
            else:
                print(f"  🔴 {v} ({step}): karıştırılabilir terim BASKIN "
                      f"(kendi={o} karışt={c}) — transkript ATANMIŞ dersi "
                      f"çürütüyor")
        print("Kaynağı çıkar ya da etiketi düzelt. (UYARI'lar bloklamaz, "
              f"{REGISTER.name} kütüğünde sayılır.)")
        return 1

    print("OK — hiçbir kabul edilmiş kaynağın transkripti atandığı dersi "
          "çürütmüyor. (Sessizlik/kanıt-yok BLOKLAMAZ ve kütükte sayılıdır.)")
    return 0


def write_register(rows: list[tuple]) -> None:
    n_red = sum(1 for r in rows if r[2] == "KIRMIZI")
    n_ok = sum(1 for r in rows if r[2] == "TEYIT")
    body = [
        "<!-- GENERATED by tools/identity_read.py --register. Do not hand-edit. -->",
        "",
        "# Choreia — Kimlik Kütüğü (kabul edilmiş kaynaklar)",
        "",
        f"{len(rows)} kabul edilmiş kaynak · **{n_ok} teyit** · **{n_red} çürütme** · "
        f"kalanı kanıt-yok.",
        "",
        "**Bu kütük bir KAPI DEĞİL.** Kapı yalnız *çürütme*de öter; kanıt-yok",
        "bloklamaz çünkü transkript sessizliği **kaynak videonun** özelliğidir,",
        "bu deponun işi değil — kimsenin düzeltemeyeceği bir kırmızı, kapatılan",
        "bir kapıdır.",
        "",
        "**Sessizlik yapısal:** eğitmen adımı önce *anlatır*, sonra *sessizce",
        "gösterir*; hasat hattı tam o **gösterim** penceresini seçer. En iyi",
        "ölçüm penceresi ile en iyi kanıt penceresi aynı yer değildir.",
        "",
        "⛔ Transkript **söyleneni** ölçer, **yapılanı** değil. Leave-one-out'un",
        "yerine geçmez; ulaşamadığı yerde konuşur. Sessizlik ne aklanmadır ne",
        "mahkûmiyet.",
        "",
        "| referans | kaynak | ders düzeyi | kendi | karışt. | sözcük |",
        "|---|---|---|---|---|---|",
    ]
    label = {"TEYIT": "✅ kendi adımı baskın", "KIRMIZI": "🔴 **ÇÜRÜTÜYOR**",
             "KANIT_YOK": "⚠️ kanıt yok", "SESSIZ": "🔇 sessiz",
             "TRANSKRIPT_YOK": "⚪ transkript yok", "TERIM_YOK": "⚪ terim seti yok"}
    for step, v, vd, o, c, w, blind in rows:
        note = " ⚠️ **SAYAÇ KÖR:** " + ", ".join(blind) if blind else ""
        body.append(f"| {step} | `{v}` | {label[vd]}{note} | {o} | {c} | {w} |")
    body += [
        "",
        "## Segment düzeyi — AYRI bir granül, tek sayıya indirilmez",
        "",
        "Ders düzeyi *\"bu ders bu adımı öğretiyor\"* der; segment düzeyi",
        "*\"referansın kurulduğu pencere o adımı gösteriyor\"* der. İkincisi",
        "hazırlanmış segment gerektirir (`prepare_take`), yani bu kütükten",
        "türetilemez — 2026-08-12 ölçümü R17 §5'te: **5 teyit · 9 kanıt yok ·",
        "0 çürütme.**",
        "",
        "**Açık kalem:** `4BRd2E8vBic` — ders düzeyinde çürütme sinyali",
        "(bounce 32 ↔ rock 50) ama **segment penceresi sessiz**. İki ayrı",
        "aletin ikisi de hüküm veremedi; leave-one-out'a havale.",
    ]
    REGISTER.write_text("\n".join(body) + "\n", encoding="utf-8")


def self_test() -> int:
    fails = []

    # 1) Karşıtlık terimleri UYDURULMADI: alıntılanan içerik dosyası hâlâ o
    #    ayrımı yapıyor mu? Yapmıyorsa harita bayatlamıştır.
    for step, t in TERMS.items():
        for path, needle in (t.get("cites") or {}).items():
            f = REPO / path
            if not f.exists():
                fails.append(f"{step}: alıntılanan {path} YOK")
            elif needle not in f.read_text(encoding="utf-8").lower():
                fails.append(f"{step}: {path} artık '{needle}' ayrımını yapmıyor")

    # 2) Hüküm mantığı — dört sınıf da üretilebiliyor mu?
    cases = [((3, 0, 50), "TEYIT"), ((0, 5, 50), "KIRMIZI"),
             ((0, 0, 50), "KANIT_YOK"), ((0, 0, 0), "SESSIZ")]
    for (o, c, w), want in cases:
        got = verdict(o, c, w)
        if got != want:
            fails.append(f"verdict({o},{c},{w}) = {got}, beklenen {want}")

    # 3) KÖK eşleme gerçekten çekimli biçimi yakalıyor mu? (C-231'in ölçülmüş
    #    vakası: "when you're shuffling" tam-sözcük sayımıyla KAÇIYORDU.)
    text = "same thing when you're shuffling you either put it here".lower()
    if text.count("shuffl") != 1:
        fails.append("kök eşleme 'shuffling'i yakalamıyor")
    if text.count("shuffle") != 0:
        fails.append("öz-testin kendi öncülü yanlış: 'shuffle' bu metinde geçmemeli")

    # 4) ASR TRANSLİTERASYONU — kanalın ölçülmüş kör noktası, ve GERÇEK
    #    transkript dizgeleriyle sınanıyor (uydurma örnekle değil).
    for real in ("it's called the kukaraches", "kukuracep compact chasse in chacha"):
        if "cucaracha" in real:
            fails.append("öz-test öncülü yanlış: bu dizgede 'cucaracha' geçmemeli")
        if not near_hits(real, "cucaracha"):
            fails.append(f"fonetik tarama gerçek vakayı KAÇIRDI: {real!r}")
    # NEGATİF İKİZ: kendi ilk regex'imin ürettiği yanlış pozitif. Bu olmadan
    # "yakalıyor" iddiası, her şeyi yakalayan bir eşleyicide de doğru olurdu.
    if near_hits("that is a great approach to dancing", "cucaracha"):
        fails.append("fonetik tarama 'approach'ı 'cucaracha' sanıyor (yanlış pozitif)")
    # KABA-ANAHTAR gürültüsü: oran eşiğini kaldırdığımda GERÇEK kütükte
    # ölçülen dört yanlış pozitif. Doyum kuralı olmadan hepsi geri gelir.
    for text, term in [("a couple of times", "shuffl"), ("in this class", "salsa"),
                       ("the best one", "bachata"), ("a quick visit", "bachata")]:
        if near_hits(text, term):
            fails.append(f"kaba anahtar gürültüsü geri geldi: {term}~{text!r}")
    # 4b) asr-fragile ÖLÇÜLÜYOR mu — İngilizce sözcük sağlam, yabancı ad kırılgan
    if WORDLIST.exists():
        if asr_fragile("rock")[0]:
            fails.append("'rock' kırılgan sayıldı — İngilizce sözlük sözcüğü")
        if not asr_fragile("cucaracha")[0]:
            fails.append("'cucaracha' sağlam sayıldı — sözlükte olmamalı")

    # 5) Kapsam pubspec'ten mi geliyor? (dizin listesi derleme defteri taşır)
    refs = shipped_references()
    if not refs:
        fails.append("pubspec'ten hiç referans okunmadı — kapsam boş")
    if any(r.name.startswith(".") for r in refs):
        fails.append("kapsama gizli defter dosyası girdi")

    for f in fails:
        print(f"  FAIL: {f}")
    print(f"SELF-TEST {'OK' if not fails else 'FAILED'} ({len(cases)+4} kontrol)")
    return 1 if fails else 0


if __name__ == "__main__":
    raise SystemExit(main())
