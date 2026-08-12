#!/usr/bin/env python3
"""DEFTER TAZELİĞİ — iki yönlü. (C-267, A6)

ÖLÇÜT (`YAYIN-HAZIRLIK-OLCUTU.md` A6): *"DEFTER taze — gedik 0, İKİ YÖNDE."*
Ölçüt ve karar kuralları **sonuçtan önce** yazıldı: `docs/research/R25-*.md`.

NİYE VAR — ve niye `closure_authority` DEĞİL
--------------------------------------------
A6'nın ön-girdisi koordinatör tarafından `✅` yazılmıştı. Hat ölçtü, **yanlıştı**:
`closure_authority.py` **kapanış otoritesini** ölçer (*"bir yer 'C-NNN kapandı'
diyorsa, C-NNN'in kendi durum sütunu da öyle demeli"*) — defter **bir hafta bayat
olsa da** o kapı yeşil kalır. ⇒ ***AYNI KELİME, İKİ KATMANDA İKİ BİRİM.***

İKİ YÖN
-------
  ① **iş → kayıt**  commit indi, kaydı yazılmadı  → **gerekçe kaybolur**
  ② **kayıt → iş**  kayıt yazıldı, işi inmedi     → **defter fazla-satar**

⚠️ Ve ikisi **aynı ceza almaz**, çünkü aynı kusur değiller (R25 §1'de ölçüldü):
  ①  18 kimlik (`C-183…C-204`) commit'lerde **anılıyor**, defterde **satırı yok**
     — `C-183`/`C-190` ham metinde **0 kez** geçiyor ⇒ **BİLGİ kaybı**.
  ②  92 kayıt hiçbir commit'te anılmıyor — ama kayıt **var**, iş **inmiş**;
     commit araştırma numarası anmış (`C-265` ↔ `c54c957` *"(R24)"*) ⇒ **BAĞ kaybı**.

> ***BİR KAYDIN HİÇ YAZILMAMASI İLE ANILMAMASI AYNI KUSUR DEĞİLDİR.***

⇒ **① tüm geçmişte, muafiyetsiz** · **② `BASELINE`'dan sonra**, ve öncesi
**her koşumda sayıyla basılır** (susturulmuyor, sayılıyor).

UÇUŞTAKİ KAYIT — sınır önceden yazıldı
--------------------------------------
Bu kapı `gates.sh`ten **commit'ten ÖNCE** koşar; turun kaydı yazılmış ama commit'i
inmemişse ② tanım gereği öter. Kural: **ağaç temizse gedik TAM 0** (temiz ağaçta
uçuşta iş yoktur ⇒ o kayıt **inmemiş** demektir); **kirliyse** en fazla **1**
anılmamış kayıt, **ve o EN BÜYÜK kimlik olmalı**.
⚠️ Mühür anı hep temiz ağaçtır ⇒ **her mühürde gedik 0 zorunlu.**

BU KAPININ ÖLÇMEDİĞİ
--------------------
- **mtime'a bakmaz** — defter git-dışı, `touch` tazeliği taklit eder. İçerik ölçer.
- Bir kaydın **DOĞRULUĞUNU** ölçmez, yalnız **varlığını** ve **bağını**.
- `R` numaraları atıf **sayılmaz** (taban çizgisinden sonra commit `C-NNN` anmalı).
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

# ⛔ Ayrıştırıcıyı YENİDEN YAZMA — C-260'ın bedeli tam buydu: `closure_authority`
# durumu `strip("|")` SONRASI sondan ikinci hücreden okur; elle yeniden yazılan
# bir ayrıştırıcı aynı satırı farklı hücreye böldü ve sabotaj "inmedi" sanıldı.
# ***Bir aracın koruduğu şey, ancak ARAÇTAN GEÇİLDİĞİNDE korunur.***
from closure_authority import DEFTER, authority

REPO = Path(__file__).resolve().parents[1]

# YÖN ② TABAN ÇİZGİSİ — ADIYLA, ve gerekçesi ölçülmüş (R25 §2).
# Bundan SONRAKİ her kayıt bir commit tarafından anılmalı. Öncesi geriye dönük
# cezalandırılmaz: orada **kayıp yok, bağ yok** — olmayan bir konvansiyonu
# geçmişe uygulamak kusur değil GÜRÜLTÜ üretir.
# ⛔ Bu bir muafiyet değil bir SINIR: altındaki kalemler sayılır ve basılır.
BASELINE = 266

RECORD = re.compile(r"\bC-(\d{3})\b")


def cited_ids() -> set[int]:
    """Commit mesajlarında (konu + gövde) anılan her `C-NNN`."""
    out = subprocess.run(
        ["git", "log", "--format=%s%n%b"],
        cwd=REPO, capture_output=True, text=True, check=True).stdout
    return {int(m) for m in RECORD.findall(out)}


def tree_dirty() -> bool:
    out = subprocess.run(
        ["git", "status", "--porcelain"],
        cwd=REPO, capture_output=True, text=True, check=True).stdout
    return bool(out.strip())


def verdict(ledger: set[int], cited: set[int], dirty: bool,
            baseline: int = BASELINE) -> tuple[list[str], list[str]]:
    """SAF — dosya/git okumaz. Sabotaj gerçek deftere dokunmadan koşsun diye.

    Döner: (hatalar, notlar). Hata varsa kapı kırmızı.
    """
    errors: list[str] = []
    notes: list[str] = []

    # VAKUM — ölçecek şey yoksa kapı yeşil ÖTMEZ. (privacy_manifest_check'in
    # deseni: boş bir popülasyonda "ihlal yok" bir ölçüm değil bir sessizliktir.)
    if not ledger:
        errors.append("VAKUM: defterde tek kayıt yok — ölçülecek şey yok")
        return errors, notes
    if not cited:
        errors.append("VAKUM: hiçbir commit kayıt anmıyor — ölçülecek bağ yok")
        return errors, notes

    # ── YÖN ① iş → kayıt : muafiyetsiz, tüm geçmiş ────────────────────────
    ghost = sorted(cited - ledger)
    for r in ghost:
        errors.append(
            f"① C-{r:03d}: bir commit bu kaydı anıyor — ama DEFTER'de satırı YOK "
            "(iş indi, gerekçesi yazılmadı)")

    # ── YÖN ② kayıt → iş : taban çizgisinden sonra ────────────────────────
    uncited = sorted(r for r in ledger if r > baseline and r not in cited)
    old_uncited = sorted(r for r in ledger if r <= baseline and r not in cited)

    if uncited:
        top = max(ledger)
        if not dirty:
            for r in uncited:
                errors.append(
                    f"② C-{r:03d}: DEFTER'de yazılı — ama hiçbir commit anmıyor, "
                    "ve AĞAÇ TEMİZ (uçuşta iş yok ⇒ bu kayıt İNMEDİ)")
        elif len(uncited) > 1:
            for r in uncited:
                errors.append(
                    f"② C-{r:03d}: kirli ağaçta en fazla 1 uçuşan kayıt olabilir "
                    f"— {len(uncited)} var ({', '.join(f'C-{x:03d}' for x in uncited)})")
        elif uncited[0] != top:
            errors.append(
                f"② C-{uncited[0]:03d}: anılmamış — ve EN BÜYÜK kimlik değil "
                f"(en büyük: C-{top:03d}) ⇒ gedik ortada, uçuşta değil")
        else:
            notes.append(
                f"⏳ C-{uncited[0]:03d} UÇUŞTA (ağaç kirli, en büyük kimlik) — "
                "commit inince bu satır kaybolur; temiz ağaçta KIRMIZI olur")

    if old_uncited:
        notes.append(
            f"📌 taban çizgisi (C-{baseline:03d}) altında anılmamış {len(old_uncited)} "
            "kayıt — BAĞ eksik, KAYIT değil; susturulmadı, sayıldı")
    return errors, notes


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()

    if not DEFTER.exists():
        print(f"⚪ ORTAM YOK: {DEFTER} yok — defter tazeliği OKUNAMADI, "
              "doğrulanmadı. (Defter git-dışı workspace'te; taze klonda bulunmaz.)")
        return 2

    ledger = {int(r[2:]) for r in authority()}
    cited = cited_ids()
    dirty = tree_dirty()

    errors, notes = verdict(ledger, cited, dirty)
    print(f"defter: {len(ledger)} kayıt (en büyük C-{max(ledger):03d}) · "
          f"commit'lerin andığı: {len(cited)} · ağaç: "
          f"{'KİRLİ' if dirty else 'temiz'}")
    for n in notes:
        print(f"  {n}")
    for e in errors:
        print(f"  🔴 {e}")

    if errors:
        print("Gedik iki yönde de 0 OLMALI (A6). ① kayıt YAZILIR (içerik "
              "uydurulmaz — mezar taşı da bir kayıttır) · ② commit kaydı ANAR.")
        return 1
    print("OK — gedik iki yönde de 0: anılan her kaydın satırı var, "
          "taban çizgisi sonrası her kaydın commit'i var.")
    return 0


def self_test() -> int:
    """Sekiz senaryo. İki yön AYRI AYRI, ve iki POZİTİF kontrol.

    Pozitif kontrol olmadan bir kapı denetim değil YASAK olur: her şeye kırmızı
    yanan bir kapı da "sabotajı yakaladı" der.
    """
    fails = []

    def check(name, ledger, cited, dirty, want_red, want_in=None):
        errs, notes = verdict(set(ledger), set(cited), dirty, baseline=266)
        got_red = bool(errs)
        if got_red != want_red:
            fails.append(f"{name}: beklenen {'KIRMIZI' if want_red else 'yeşil'}, "
                         f"gelen {'KIRMIZI' if got_red else 'yeşil'} ({errs or notes})")
            return
        if want_in and not any(want_in in e for e in errs + notes):
            fails.append(f"{name}: kırmızı ama {want_in!r} adıyla geçmiyor: {errs}")

    # ① POZİTİF: sağlam hâl yeşil — kapı kırmızıya SIKIŞMIŞ değil
    check("sağlam", {265, 266, 267}, {265, 266, 267}, False, want_red=False)

    # ② YÖN ①: commit anıyor, defterde yok  (muafiyetsiz, taban çizgisi altı bile)
    check("yön① hayalet kayıt", {266, 267}, {190, 266, 267}, False,
          want_red=True, want_in="C-190")

    # ③ YÖN ②: defterde var, commit anmıyor, ağaç TEMİZ
    check("yön② temiz ağaç", {266, 267}, {266}, False,
          want_red=True, want_in="C-267")

    # ④ POZİTİF İKİZ: aynı kayıt + KİRLİ ağaç + EN BÜYÜK kimlik → yeşil
    #    (bu olmasaydı kapı kendi turunun commit'ini de bloklardı ⇒ yasak)
    check("yön② uçuşta", {266, 267}, {266}, True, want_red=False)

    # ⑤ kirli ağaç ama İKİ anılmamış kayıt → tolerans 1
    check("iki uçuşan", {266, 267, 268}, {266}, True,
          want_red=True, want_in="C-267")

    # ⑥ kirli ağaç, anılmamış kayıt EN BÜYÜK değil → gedik ortada
    check("ortadaki gedik", {266, 267, 268}, {266, 268}, True,
          want_red=True, want_in="C-267")

    # ⑦ VAKUM: ölçecek şey yoksa yeşil ötme
    check("vakum: defter boş", set(), {266}, False, want_red=True, want_in="VAKUM")
    check("vakum: atıf yok", {266}, set(), False, want_red=True, want_in="VAKUM")

    # ⑧ POZİTİF: taban çizgisi ALTINDA anılmamış kayıt → yeşil, ama SAYILIR
    check("taban altı anılmamış", {100, 266}, {266}, False,
          want_red=False, want_in="taban çizgisi")

    for f in fails:
        print(f"  FAIL: {f}")
    print(f"SELF-TEST {'OK' if not fails else 'FAILED'} (9 kontrol, "
          "2'si pozitif kontrol)")
    return 1 if fails else 0


if __name__ == "__main__":
    raise SystemExit(main())
