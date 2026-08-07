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

    print(f"metrik sürücüsü: {len(metrics)} · yorumlanan {len(interpreted)} · "
          f"yalnız-beyan {len(declared)}")
    for e in errs:
        print(f"  ERROR {e}")
    print("OK" if not errs else f"FAILED ({len(errs)})")
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
