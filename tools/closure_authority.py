#!/usr/bin/env python3
"""KAPANIŞ OTORİTESİ — bir yer "C-NNN kapandı" diyorsa, C-NNN'in KENDİ durum
sütunu da öyle demeli. (C-249, koordinatör hükmü 2026-08-12)

NİYE VAR — ölçülmüş bir turun bedeli
------------------------------------
2026-08-12'de aynı çıkmaz sokağa **ikinci kez** girildi (C-244) ve maliyeti
bir turdu. Sebep TEK bir eksik değildi, **üç eksiğin HİZALANMASIYDI**:

  ① engelleyen kapıda kapalı-yola atıf YOKTU        (C-245 → C-247'de kapandı)
  ② C-032'nin KENDİ durum sütunu "kapalı" DEMİYOR   (bu betiğin konusu)
  ③ kapanış ÜÇÜNCÜ bir yerde, bir ANLATInın içinde  (paydası tanımsız)

Üçünden HERHANGİ BİRİ yerinde olsaydı tur harcanmayacaktı.

OTORİTE = A (koordinatör hükmü)
-------------------------------
  A  kaydın KENDİ `Durum` sütunu   → **OTORİTE**
  B  dış not (içerik dosyaları)    → İŞARETÇİ, otorite DEĞİL
  C  anlatı (ardıl kayıt metni)    → hiçbir zaman otorite değil (payda tanımsız)

Kanonik değer tek evde, ötekinde işaretçi — ve bu betik ikisinin AYRIŞMASINI
yakalar.

⚠️ İKİNCİ, DAHA SİNSİ HÂL: bir kaydın kapanışı BAŞKA bir satıra yazılınca
(örn. C-140'ın kapanışı C-222'ye), öncekinin durumu **sessizce bayatlar** —
kimse yalan söylemez, kayıt yalan söylemeye başlar.

⛔ Bu betik hiçbir durumu DÜZELTMEZ. Kırmızı yakar; düzeltme ayrı bir iştir.
"""
from __future__ import annotations

import glob
import json
import os
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
DEFTER = REPO.parent / "workspace" / "DEFTER.md"

# ⛔ `.lower()` YOK — `'İ'.lower()` birleşik nokta üretir ve Türkçe büyük
# kipte yanlış sıfır verir (C-236'da ölçüldü). `re.IGNORECASE` ölçülüp `İ`yi
# KATLADIĞI doğrulandı; her yerde o kullanılıyor.
#
# Kapanış sözcükleri TAHMİNLE değil ÖLÇÜLEREK yazıldı: DEFTER'in kendi durum
# sütununda `kapalı` 170 kez geçiyor (`açık` 37+19). Assertion tarafında
# ayrıca `kapandı`/`kapatıldı` çekimleri kullanılıyor.
CLOSED_WORD = re.compile(r"kapalı|kapandı|kapatıldı", re.IGNORECASE)
RECORD = re.compile(r"\bC-(\d{3})\b")

# KONUM ÇAPASI — *sözünü etmek ≠ kapatmak*. Kapanış sözcüğü, kimliğin
# ARDINDAN en fazla 40 karakter içinde ve ARADA CÜMLE BİTMEDEN gelmeli.
# Gevşek bir "aynı paragrafta geçiyor" kuralı, `C-207 … (başka cümle) …
# kapandı` gibi vakaları YANLIŞ yakalardı.
# ⚠️ ARADA BAŞKA KİMLİK OLMAMALI — ölçülmüş bir yanlış pozitif yüzünden.
# İlk hâl `"C-250 satırı C-007 kapandı diyor"` cümlesinde kapanışı **C-250**'ye
# bağladı; oysa sözcük **araya giren ikinci kimliğe** aitti. Türkçede yüklem
# sona geldiği için iki kimlik arasına kapanış sözcüğü kolayca düşüyor.
# Kural ilkeli, ayarlanmış değil: *araya başka bir kimlik girdiyse bağlanma
# BELİRSİZDİR, ve belirsiz bir iddia iddia sayılmaz.*
ASSERTION = re.compile(
    r"\bC-(\d{3})\b(?P<gap>(?:(?!C-\d{3})[^.·|\n]){0,40}?)"
    r"(?:kapalı|kapandı|kapatıldı)",
    re.IGNORECASE)


# TAŞINAN AYRIŞMALAR — taban çizgisi, MUAFİYET DEĞİL.
#
# Niye var: bu kapı doğduğu anda ÜÇ GERÇEK kusur buldu (koordinatörün istediği
# gibi — *bir kapı doğduğu anda gerçek bir kusuru göstermelidir, yoksa neyi
# koruduğu bilinmez*). Ama `tool/gates.sh` commit kapısıdır: kalıcı kırmızı
# hiçbir commit'i geçirmez, ve **kapatılmış kapı hiç olmayandan kötüdür.**
#
# ⚠️ Muafiyet ÖLÇÜMÜNÜ TAŞIR (C-233'ün deseni): kaydın o anki durum METNİ de
# yazılı. Metin değişirse eşleşme bozulur ve kalem YENİDEN kırmızı yanar —
# *bir muafiyet, muaf tuttuğu ölçümü kaydetmiyorsa sessizce her şeyi muaf
# tutar.* Ve taşınanlar her koşumda ADIYLA basılır: susturulmuyor, sayılıyor.
#
# ⛔ Bunlar DÜZELTİLMEDİ — düzeltme ayrı bir sıra (koordinatör hükmü).
# 2026-08-12: ÜÇÜ DE DÜZELTİLDİ (koordinatör sevki, C-253) → taban çizgisi
# BOŞ. Ve boş kalması bir başarı değil bir DURUM: yeni bir ayrışma çıkarsa
# kapı doğrudan kırmızı yanar, taşıyacak bir şey yok.
#
# ⚠️ Buraya bir kalem eklemek "muaf tut" demek DEĞİL, "bu ayrışma BİLİNİYOR
# ve durumu ŞU metinde donduruldu" demektir — metin değişirse eşleşme bozulur
# ve kalem yeniden kırmızı yanar.
CARRIED: dict[str, str] = {}


def authority() -> dict[str, tuple[bool, str]]:
    """A: her kaydın KENDİ durum sütunu.

    ⚠️ Durum **sondan ikinci** hücreden okunur, baştan sayarak DEĞİL: kod
    aralıklarındaki `|` karakteri 231 satırın 10'unda sütun kaydırıyor
    (ölçüldü, C-246 — baştan sayan ilk deneme 2 kaydı yanlış sınıflandırdı).
    """
    out: dict[str, tuple[bool, str]] = {}
    for line in DEFTER.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 6:
            continue
        m = re.match(r"\**\s*(C-\d{3})", cells[0])
        if not m:
            continue
        durum = cells[-2]
        out[m.group(1)] = (bool(CLOSED_WORD.search(durum)), durum)
    return out


def assertions() -> list[tuple[str, str, str]]:
    """B + C: "C-NNN kapandı" diyen her yer. (kayıt, nerede, alıntı)"""
    found: list[tuple[str, str, str]] = []

    def scan(text: str, where: str, skip_own: str | None = None) -> None:
        for m in ASSERTION.finditer(text):
            rid = f"C-{m.group(1)}"
            if rid == skip_own:      # kendi satırının kendi durumu iddia değil
                continue
            found.append((rid, where, text[max(0, m.start() - 10):m.end() + 10]))

    for f in sorted(glob.glob(str(REPO / "content/**/*.json"), recursive=True)):
        if os.path.basename(f).startswith("."):
            continue
        scan(Path(f).read_text(encoding="utf-8"),
             os.path.relpath(f, REPO))

    for line in DEFTER.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 6:
            continue
        m = re.match(r"\**\s*(C-\d{3})", cells[0])
        own = m.group(1) if m else None
        # Kaydın KENDİ durum sütunu (sondan ikinci) iddia sayılmaz — otoritenin
        # kendisi o. Geri kalan hücreler (bulgu, kanıt) iddia taşıyabilir.
        body = " | ".join(cells[:-2] + cells[-1:])
        scan(body, f"DEFTER:{own or '?'}", skip_own=own)
    return found


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()

    if not DEFTER.exists():
        print(f"⚪ ORTAM YOK: {DEFTER} yok — kapanış otoritesi OKUNAMADI, "
              "doğrulanmadı. (Defter git-dışı workspace'te; taze klonda "
              "bulunmaz.)")
        return 2

    auth = authority()
    claims = assertions()
    print(f"otorite A: {len(auth)} kayıt · kapanış iddiası: {len(claims)}")

    bad: list[tuple[str, str, str]] = []
    unknown: list[tuple[str, str]] = []
    for rid, where, quote in claims:
        if rid not in auth:
            unknown.append((rid, where))
            continue
        closed, durum = auth[rid]
        if not closed:
            bad.append((rid, where, durum))

    for rid, where in unknown:
        print(f"  ⚠️ {rid}: {where} kapandı diyor ama DEFTER'de böyle bir kayıt YOK")
    seen = set()
    fresh = []
    for rid, where, durum in bad:
        if (rid, where) in seen:
            continue
        seen.add((rid, where))
        if CARRIED.get(rid) == durum:
            print(f"  📌 {rid}: ayrışma TAŞINIYOR ('{where}' kapandı diyor, "
                  f"kendi durumu {durum!r}) — açık kalem, düzeltilmedi")
            continue
        fresh.append((rid, where, durum))
        print(f"  🔴 {rid}: '{where}' KAPANDI diyor — ama {rid}'in KENDİ durum "
              f"sütunu: {durum!r}")
    bad = fresh

    if bad or unknown:
        print("Otorite kaydın KENDİ durum sütunudur (A). Kapanış başka yere "
              "yazıldıysa, kaydın kendi satırı AYNI commit'te güncellenir.")
        return 1
    carried = sum(1 for r in CARRIED if r in auth and CARRIED[r] == auth[r][1])
    if carried:
        print(f"OK — YENİ ayrışma yok. ⚠️ {carried} ayrışma TAŞINIYOR "
              "(yukarıda adıyla); bunlar düzeltilmedi, susturulmadı.")
    else:
        print("OK — kapanış iddiası olan her kayıt, kendi durum sütununda da "
              "kapalı, ve taşınan ayrışma yok.")
    return 0


def self_test() -> int:
    fails = []
    # ① KONUM ÇAPASI: sözünü etmek ≠ kapatmak
    if not ASSERTION.search("C-032 kapandı — ölçüldü"):
        fails.append("bitişik kapanış iddiası yakalanmıyor")
    if ASSERTION.search("C-207 çökmeyi durdurdu. Ayrı bir iş kapandı"):
        fails.append("cümle sınırı aşılıyor — 'sözünü etmek' kapatmak sayılıyor")
    if ASSERTION.search("C-091'in dersi uygulandı"):
        fails.append("kapanış sözcüğü olmayan atıf iddia sayıldı")
    # ARAYA GİREN KİMLİK — gerçek yanlış pozitif, kendi DEFTER kaydımda çıktı
    m = ASSERTION.search("C-250 satırı C-007 kapandı diyor")
    if m and m.group(1) == "250":
        fails.append("kapanış araya giren kimliği atlayıp ilkine bağlanıyor")
    if not (m and m.group(1) == "007"):
        fails.append("araya kimlik girince DOĞRU kimliğe bağlanmıyor")
    # ② Türkçe kip: BÜYÜK yazım da yakalanmalı (⛔ .lower() yok)
    if not ASSERTION.search("C-140 KAPANDI"):
        fails.append("büyük kip kapanış iddiası kaçıyor")
    # ③ Durum okuma sondan mı — `|` kaymasına dayanıklı mı
    if DEFTER.exists():
        a = authority()
        if len(a) < 50:
            fails.append(f"otorite tablosu şüpheli küçük ({len(a)}) — "
                         "ayrıştırıcı satırları kaçırıyor olabilir")
    for f in fails:
        print(f"  FAIL: {f}")
    print(f"SELF-TEST {'OK' if not fails else 'FAILED'} (5 kontrol)")
    return 1 if fails else 0


if __name__ == "__main__":
    raise SystemExit(main())
