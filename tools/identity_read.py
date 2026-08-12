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


def read_lesson(video: str, terms: dict) -> tuple[str, int, int, int]:
    p = TRANSCRIPTS / f"{video}.transcript.json"
    if not p.exists():
        return ("TRANSKRIPT_YOK", 0, 0, 0)
    text = " ".join(x["text"] for x in json.loads(p.read_text(encoding="utf-8"))).lower()
    o = sum(text.count(w) for w in terms["own"])
    c = sum(text.count(w) for w in terms["confusable"])
    return (verdict(o, c, len(text.split())), o, c, len(text.split()))


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
                rows.append((step, v, "TERIM_YOK", 0, 0, 0))
                continue
            vd, o, c, w = read_lesson(v, terms)
            rows.append((step, v, vd, o, c, w))
            if vd == "KIRMIZI":
                red.append((step, v, o, c))

    if "--register" in sys.argv:
        write_register(rows)
        print(f"kütük yazıldı: {REGISTER.relative_to(REPO)}")

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
    for step, v, vd, o, c, w in rows:
        body.append(f"| {step} | `{v}` | {label[vd]} | {o} | {c} | {w} |")
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

    # 4) ASR transliterasyon vakası — kanalın bilinen kör noktası ADIYLA
    #    sınanıyor: gerçek transkriptlerden alınan iki gerçek dizge.
    for real in ("it's called the kukaraches", "kukuracep compact chasse in chacha"):
        if "cucaracha" in real:
            fails.append("öz-test öncülü yanlış: bu dizgede 'cucaracha' geçmemeli")

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
