#!/usr/bin/env python3
"""Faz/hata sürücülerinin sayımı DOĞRU mu? (C-202)

`content/metric-vocabulary.json` bir KAYIT, bir beyan değil. Bu betik onu
içerikten ve araç kaynaklarından yeniden hesaplar; fark varsa kırmızı verir.

Neden: içerik, fazları ayıran ve hataları tetikleyen büyüklüklerin ADLARINI
taşıyor, ve ölçüldü ki bu adların 24'ünden 22'sini hiçbir araç okumuyor. Bu
kendiliğinden kusur DEĞİL — bir büyüklüğü adlandırmak, onu ölçen kodu yazmanın
önkoşulu. Kusur olan, okunan bir ad ile okuyucusunu bekleyen bir adın AYIRT
EDİLEMEMESİ; ikincisi sessizce "bunu ölçüyoruz"a dönüşüyor.
"""
from __future__ import annotations

import glob
import json
import os
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
RECORD = REPO / "content" / "metric-vocabulary.json"


def measure() -> dict[str, list[str]]:
    metrics: dict[str, list[str]] = {}
    for f in sorted(glob.glob(str(REPO / "content/styles/*/steps/*.json"))):
        d = json.loads(Path(f).read_text(encoding="utf-8"))
        for p in d.get("phases", []):
            m = (p.get("enter") or {}).get("metric")
            if m:
                metrics.setdefault(m, []).append(f"{d['id']}.phase:{p.get('id')}")
        for e in d.get("errors", []):
            m = (e.get("detect") or {}).get("metric")
            if m:
                metrics.setdefault(m, []).append(f"{d['id']}.error:{e.get('code')}")
    return metrics


# C-207 (koordinatör onaylı tasarım): tool/prepare_take.py'nin
# `_metric_vocabulary_entry` isimli-ret sözleşmesiyle AYNI dört aile. Burada
# TEKRAR yazılmasının sebebi bu betiğin prepare_take'i import ETMEMESİ
# (bağımsız, içerik-yalnız bir doğrulayıcı kalması istendi) — drift riski,
# ikisi de aynı dört ismi taşıdığı için küçük ve isimle görünür.
_KNOWN_FAMILIES = {"flexion", "orientation", "rhythm", "composite"}
_FAMILIES_NEEDING_JOINT_REF = {"flexion", "orientation"}


def cycle_unit_drivers() -> dict[str, list[str]]:
    """Hangi sürücü adı, hangi adım(lar)ın `cycleUnit.driver`'ında geçiyor?

    Yalnız NESNE şekilli `cycleUnit` sayılır — düz-dizge olanlar (C-207,
    koordinatör (c)) kinematik dispatch'e hiç girmiyor, bu yüzden family/
    jointRef'e ihtiyaçları yok ve burada aranmazlar.
    """
    drivers: dict[str, list[str]] = {}
    for f in sorted(glob.glob(str(REPO / "content/styles/*/steps/*.json"))):
        d = json.loads(Path(f).read_text(encoding="utf-8"))
        cu = d.get("cycleUnit")
        if isinstance(cu, dict) and cu.get("driver"):
            drivers.setdefault(cu["driver"], []).append(d["id"])
    return drivers


def readers_of(names: set[str]) -> dict[str, list[str]]:
    srcs = {}
    for pat in ("tools/*.py", "lib/**/*.dart",
                "packages/choreia_engine/lib/**/*.dart"):
        for f in glob.glob(str(REPO / pat), recursive=True):
            # This file and the vocabulary gate itself do not count as readers:
            # a checker that mentions a name is not a tool that INTERPRETS it,
            # and counting it would let the record certify itself.
            if os.path.basename(f) in {"validate_content.py",
                                       "validate_metric_vocabulary.py"}:
                continue
            srcs[f] = Path(f).read_text(errors="ignore")
    return {m: sorted(os.path.basename(f) for f, t in srcs.items()
                      if f'"{m}"' in t or f"'{m}'" in t)
            for m in names}


def main() -> int:
    if not RECORD.exists():
        print(f"FAILED: {RECORD.name} yok — sayım kaydı silinmiş")
        return 1
    rec = json.loads(RECORD.read_text(encoding="utf-8"))

    metrics = measure()
    if not metrics:
        print("FAILED: hiçbir metrik okunmadı — bu betik hiçbir şey ölçmüyor")
        return 1
    reads = readers_of(set(metrics))

    interpreted = sorted(m for m in metrics if reads[m])
    declared = sorted(m for m in metrics if not reads[m])

    errs: list[str] = []
    if sorted(rec.get("interpreted", [])) != interpreted:
        errs.append(f"interpreted kaydı {rec.get('interpreted')} · ölçüm {interpreted}")
    if sorted(rec.get("declaredOnly", [])) != declared:
        missing = sorted(set(declared) - set(rec.get("declaredOnly", [])))
        extra = sorted(set(rec.get("declaredOnly", [])) - set(declared))
        errs.append(f"declaredOnly kaydı kaydı ile ölçüm ayrıştı — "
                    f"kayıtta olmayan: {missing} · ölçümde olmayan: {extra}")
    for m, e in (rec.get("metrics") or {}).items():
        want = "interpreted" if reads.get(m) else "declared-only"
        if m in metrics and e.get("state") != want:
            errs.append(f"{m}: kayıt '{e.get('state')}', ölçüm '{want}'")

    # C-221: YETİM SATIR — kayıtta olup içerikte HİÇ geçmeyen bir ad, yukarıdaki
    # `if m in metrics` koruması yüzünden bu ölçümden sessizce geçiyordu.
    # `interpreted`/`declaredOnly` listeleri iki yönlü karşılaştırılıyor ama
    # `metrics` SÖZLÜĞÜ yalnız tek yönlü okunuyordu.
    #
    # Niye kusur: bu dosyanın kendi sözleşmesi "içerikten yeniden hesaplanır,
    # fark varsa kırmızı" — hesaplanan kümede olmayan bir satır tam olarak bir
    # farktır, ve C-202'nin adlandırdığı zararın üçüncü biçimi: okunan ad ile
    # okuyucusunu bekleyen ad ayrıldı, ama İÇERİĞİN HİÇ ANMADIĞI ad ayrılmadı.
    # Sonraki tur onu "demek ki bunu ölçüyoruz" diye okur.
    #
    # GERÇEK SABOTAJLA ölçüldü (iç öz-test değil): kayda `hayalet_surucu`
    # eklendi, `tool/gates.sh` YEŞİL kaldı ve commit GEÇTİ — delik varsayım
    # değil, ölçüm.
    orphans = sorted(set(rec.get("metrics") or {}) - set(metrics))
    if orphans:
        errs.append(f"kayıtta olup içerikte HİÇ geçmeyen ad: {orphans} — kayıt "
                    f"içerikten türer, kendi başına ad taşıyamaz")

    # C-207: cycleUnit.driver olarak KULLANILAN her sürücü family+jointRef
    # taşımalı — taşımıyorsa tools/prepare_take.py `kinematic_unit()` zaten
    # isimli SystemExit ile duracak, ama bu ölçüm commit ANINDA yakalar,
    # yalnız o adım hasat edilmeye ÇALIŞILDIĞINDA değil (sessiz varsayılan
    # yok — kayıt eksikse commit'ten ÖNCE kırmızı, sonra değil).
    drivers = cycle_unit_drivers()
    driver_errs: list[str] = []
    for driver, steps in sorted(drivers.items()):
        entry = (rec.get("metrics") or {}).get(driver)
        where = f"{driver} (cycleUnit.driver: {', '.join(steps)})"
        if entry is None:
            driver_errs.append(f"{where}: metric-vocabulary.json'da hiç yok")
            continue
        family = entry.get("family")
        if family not in _KNOWN_FAMILIES:
            driver_errs.append(f"{where}: family={family!r} bilinmeyen "
                               f"(bilinenler: {sorted(_KNOWN_FAMILIES)})")
        elif family in _FAMILIES_NEEDING_JOINT_REF and not entry.get("jointRef"):
            driver_errs.append(f"{where}: family={family!r} ama jointRef yok")
    if driver_errs:
        errs.append(f"cycleUnit.driver kayıtları eksik/bozuk: {driver_errs}")

    print(f"metrik sürücüsü: {len(metrics)} · yorumlanan {len(interpreted)} · "
          f"yalnız-beyan {len(declared)} · cycleUnit.driver {len(drivers)}")
    for e in errs:
        print(f"  ERROR {e}")
    print("OK" if not errs else f"FAILED ({len(errs)})")
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
