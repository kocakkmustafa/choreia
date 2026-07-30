#!/usr/bin/env python3
"""Consumer-side conformance check for a reference artifact.

WHY THIS EXISTS.

The family's fifth question — "is anyone asking this gate?" — was put to
Choreia's reference flags and the answer was zero. Nothing reads
`scoredPhases`, `evidenceThickness`, `mirrorConfident`, `toleranceSource`,
`excludedAnchorSource` or the rest, because Choreia has no scorer yet: no Dart
project, no runtime, nothing downstream of `content/references/`. A grep found
three apparent readers and all three were false positives — step configs that
happen to use the same field names for their own purposes.

Deleting the flags would be the wrong fix; they carry the evidence a scorer
will need, and `content/references/README.md` already defines how each is to be
used. But a flag nobody reads and nobody checks decays into decoration, and the
decay is invisible.

So this tool plays the consumer. It does not pretend to score anything — it
asserts that an artifact is internally consistent and *actionable*: that every
published flag agrees with the numbers it is derived from, and that a scorer
following the README could not be led into a contradiction. A flag that cannot
be checked here has no defined use, and that is the signal to bind it or drop
it.

  python3 tools/validate_reference.py
  python3 tools/validate_reference.py content/references/ss_shine_footwork.json
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from build_reference import (MIN_CYCLES_PER_TAKE, MIN_TAKES,  # noqa: E402
                             MIN_TOLERANCE_DEG, SCORED_MAX_DISPERSION_DEG)

REPO = Path(__file__).resolve().parents[1]
REFS = REPO / "content" / "references"


class Report:
    def __init__(self, name: str) -> None:
        self.name = name
        self.errors: list[str] = []
        self.warnings: list[str] = []
        self.checks = 0

    def check(self, ok: bool, msg: str) -> None:
        self.checks += 1
        if not ok:
            self.errors.append(msg)

    def warn(self, cond: bool, msg: str) -> None:
        if cond:
            self.warnings.append(msg)


def validate(path: Path) -> Report:
    r = Report(path.name)
    d = json.loads(path.read_text(encoding="utf-8"))

    if not d.get("built", True):
        r.check(bool(d.get("why")), "built=false ama gerekçe (why) yok")
        return r

    bins = d.get("phaseBins")
    r.check(isinstance(bins, int) and bins > 0, "phaseBins yok veya geçersiz")
    ref, tol = d.get("reference", {}), d.get("toleranceDeg", {})
    src = d.get("toleranceSource", {})
    scoring = d.get("scoring", {})

    r.check(set(ref) == set(tol) == set(src) == set(scoring),
            "reference / toleranceDeg / toleranceSource / scoring EKLEM KÜMELERİ ayrışıyor")

    for j in sorted(ref):
        r.check(len(ref[j]) == bins, f"{j}: reference uzunluğu phaseBins değil")
        r.check(len(tol.get(j, [])) == bins, f"{j}: tolerans uzunluğu phaseBins değil")
        r.check(len(src.get(j, [])) == bins, f"{j}: toleranceSource uzunluğu phaseBins değil")

        # A band at the floor must be labelled floor, and one above it variance.
        for b, (t, s) in enumerate(zip(tol.get(j, []), src.get(j, []))):
            expect = "floor" if t <= MIN_TOLERANCE_DEG + 1e-9 else "variance"
            r.check(s == expect,
                    f"{j}[{b}]: tolerans {t}° ama toleranceSource '{s}' (beklenen '{expect}')")

        sc = scoring.get(j, {})
        mask = sc.get("scoredPhases", [])
        r.check(len(mask) == bins, f"{j}: scoredPhases uzunluğu phaseBins değil")
        cov = sum(1 for m in mask if m) / bins if bins else 0
        # The stored value is rounded to three places, so the comparison has to
        # allow for that. A first version used 1e-6 and reported every joint as
        # broken while printing the two numbers at the same rounding — "0.797
        # does not match 0.797". The tolerance was wrong and so was the message.
        stored = sc.get("coverage", -1)
        r.check(abs(cov - stored) <= 5e-4,
                f"{j}: coverage {stored!r} ≠ maskeden hesaplanan {cov!r}")
        verdict = sc.get("verdict")
        expect_v = ("scored" if cov >= 0.9 else
                    "scored_partial" if cov >= 0.4 else "coached_only")
        r.check(verdict == expect_v,
                f"{j}: verdict '{verdict}' kapsamla ({cov:.2f}) uyuşmuyor, '{expect_v}' olmalı")
        # A scored phase must have had dispersion under the rule's threshold,
        # which shows up as a band no wider than K x threshold.
        for b, m in enumerate(mask):
            if m:
                r.check(tol[j][b] <= 1.5 * SCORED_MAX_DISPERSION_DEG + 1e-6,
                        f"{j}[{b}]: skorlanır işaretli ama bant {tol[j][b]}° eşiğin üstünde")

    # The family invariant, republished as a consumer check.
    r.check(not d.get("toleranceBelowDispersion"),
            "toleranceBelowDispersion BOŞ DEĞİL — eğitmen farkı kullanıcı hatası sayılıyor")

    srcs = d.get("sources", [])
    r.check(len(srcs) >= MIN_TAKES, f"{len(srcs)} kaynak — >= {MIN_TAKES} gerekli")
    r.check(len({s.get("channel") for s in srcs}) == len(srcs),
            "aynı eğitmen birden fazla kaynak olarak sayılmış")
    for s in srcs:
        thin = (s.get("cyclesInSegment") or 0) < MIN_CYCLES_PER_TAKE
        r.check(bool(s.get("thinEvidence")) == thin,
                f"{s.get('videoId')}: thinEvidence bayrağı çevrim sayısıyla uyuşmuyor")

    mirror = d.get("mirrorResolution", [])
    r.check(len(mirror) == len(srcs), "mirrorResolution kaynak sayısıyla uyuşmuyor")
    r.check(d.get("mirrorConfident") ==
            all(e.get("confident", True) for e in mirror),
            "mirrorConfident tek tek take kararlarıyla uyuşmuyor")

    for e in d.get("excludedAnchorSource", []):
        r.check(bool(e.get("why")) and e.get("videoId"),
                "dışlanan kaynak adsız veya gerekçesiz — isimli dışlama kuralı")

    if d.get("status") == "provisional":
        r.check(bool(d.get("provisionalReason")),
                "status=provisional ama provisionalReason yok")

    r.warn(not d.get("mirrorConfident"),
           "yön belirsiz — tüketici taraf-bağımlı hüküm VERMEMELİ (README kural 6)")
    r.warn(any(s.get("thinEvidence") for s in srcs),
           "en az bir kaynak <5 çevrim taşıyor — kanıt ince")
    r.warn(all(sc.get("verdict") != "scored" for sc in scoring.values()),
           "hiçbir eklem çevrimin tamamında skorlanmıyor")
    return r


DECISIONS_NAME = "decisions.json"

# Bir dışlamanın hattın NERESİNDE olduğu. Sabit liste, çünkü serbest metin
# olsaydı aynı sınıf üç farklı yazımla üç sınıf gibi görünürdü.
EXCLUSION_STAGES = {
    "triage",            # indirme öncesi metadata elemesi
    "prepare",           # kullanılabilir pencere/segment çıkmadı
    "identity",          # bu kaynağın BU adımı gösterdiği kurulamadı
    "suitability",       # ders-gösterimi olduğu kurulamadı (kaynak uygunluğu)
    "tool-disagreement", # iki ölçüm aleti aynı büyüklükte anlaşamadı
}


def check_decisions(rep: list[str]) -> int:
    """Minimal contract for the decisions file: shape + non-empty reasons.

    It cannot be validated like a reference (no cycles, no tolerances), but it
    must not go unchecked either — every entry is a judgement that overrides
    what the build would otherwise say, so an entry without a stated reason is
    an unexplained exclusion.
    """
    path = REFS / DECISIONS_NAME
    if not path.exists():
        return 0                      # optional file; absence is not an error
    doc = json.loads(path.read_text(encoding="utf-8"))
    errors = 0

    if doc.get("schemaVersion") != 1:
        rep.append("decisions.json: schemaVersion 1 bekleniyor")
        errors += 1

    for step, dec in (doc.get("steps") or {}).items():
        for e in dec.get("excludedIdentityAmbiguous") or []:
            if not e.get("videoId"):
                rep.append(f"decisions.json [{step}]: dışlama kaydında videoId yok")
                errors += 1
            if not e.get("why"):
                rep.append(f"decisions.json [{step}]: '{e.get('videoId')}' "
                           "dışlaması GEREKÇESİZ — uyuşmazlık gerekçe değildir "
                           "(M-F-47), bağımsız bir ölçüm yazılmalı")
                errors += 1
        for e in dec.get("excludedNotLesson") or []:
            if not e.get("videoId"):
                rep.append(f"decisions.json [{step}]: taşınan ders-dışı "
                           "kaydında videoId yok")
                errors += 1
            if not e.get("why"):
                rep.append(f"decisions.json [{step}]: '{e.get('videoId')}' "
                           "ders-dışı dışlaması GEREKÇESİZ")
                errors += 1
            # A carried record is an OLDER measurement. Without a date and a
            # reason for carrying it, a reader cannot tell it apart from one
            # taken against today's pool — and a stale exclusion that looks
            # fresh is worse than no record, because it silently vetoes a source
            # the pipeline might accept today.
            if not (e.get("measuredAt") and e.get("carriedWhy")):
                rep.append(f"decisions.json [{step}]: '{e.get('videoId')}' "
                           "taşınan ölçüm ama measuredAt/carriedWhy eksik — "
                           "bayat dışlama TAZE görünürse sessiz veto olur")
                errors += 1
        for e in dec.get("excludedWithReason") or []:
            vid = e.get("videoId")
            if not vid:
                rep.append(f"decisions.json [{step}]: excludedWithReason "
                           "kaydında videoId yok")
                errors += 1
            if e.get("stage") not in EXCLUSION_STAGES:
                rep.append(f"decisions.json [{step}]: '{vid}' stage "
                           f"{e.get('stage')!r} tanımlı değil — "
                           f"biri olmalı: {', '.join(sorted(EXCLUSION_STAGES))}")
                errors += 1
            # reasonCode MAKİNE-okur, why İNSAN-okur. İkisi de zorunlu: yalnız
            # kod, gerekçesi olmayan bir dışlamadır; yalnız metin, gruplanamaz.
            if not e.get("reasonCode"):
                rep.append(f"decisions.json [{step}]: '{vid}' reasonCode yok")
                errors += 1
            if not e.get("why"):
                rep.append(f"decisions.json [{step}]: '{vid}' GEREKÇESİZ "
                           "dışlama — uyuşmazlık gerekçe değildir (M-F-47)")
                errors += 1
            if not (e.get("measuredAt") and e.get("carriedWhy")):
                rep.append(f"decisions.json [{step}]: '{vid}' taşınan kayıt ama "
                           "measuredAt/carriedWhy eksik — bayat dışlama TAZE "
                           "görünürse sessiz veto olur")
                errors += 1

        for vid, label in (dec.get("namedVariants") or {}).items():
            if not label:
                rep.append(f"decisions.json [{step}]: '{vid}' namedVariant boş")
                errors += 1
    return errors


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("paths", nargs="*")
    args = ap.parse_args()
    # WHAT COUNTS AS A REFERENCE ARTIFACT — a rule, not a list of names.
    #
    # `decisions.json` is not one: it holds the source-level judgements the
    # build carries INTO artifacts (C-113), and it gets its own check below
    # rather than being skipped silently — a file excluded from validation with
    # no reason is how an unchecked file becomes an unnoticed one.
    #
    # The first version of this exclusion named that one file. That fixed the
    # instance, not the class: the next sibling to land in this directory
    # (`.keyset-baseline.json`) fell into the same hole and produced three
    # nonsense errors. Ledger/baseline files are dot-prefixed by convention
    # (the rig's own keyset gate does the same), so the rule is: dot-prefixed
    # files are bookkeeping, not artifacts.
    paths = [Path(p) for p in args.paths] or sorted(
        p for p in REFS.glob("*.json")
        if p.name != DECISIONS_NAME and not p.name.startswith("."))
    if not paths:
        print("referans artefaktı bulunamadı")
        return 1

    decision_problems: list[str] = []
    decision_errors = check_decisions(decision_problems)

    failed = 0
    for p in paths:
        r = validate(p)
        mark = "✓" if not r.errors else "✗"
        print(f"{mark} {r.name:<28}{r.checks:>4} kontrol"
              f"{('  ' + str(len(r.errors)) + ' HATA') if r.errors else ''}")
        for e in r.errors:
            print(f"    ✗ {e}")
        for w in r.warnings:
            print(f"    ⚠ {w}")
        failed += bool(r.errors)

    if decision_problems:
        print(f"\n✗ {DECISIONS_NAME}  {len(decision_problems)} HATA")
        for e in decision_problems:
            print(f"    ✗ {e}")
    else:
        print(f"\n✓ {DECISIONS_NAME}  kaynak-düzeyi kararlar sözleşmeye uyuyor "
              "(her dışlama gerekçeli, her varyasyon etiketli)")

    print(f"\n{len(paths) - failed}/{len(paths)} artefakt sözleşmeye uyuyor.")
    print("\nNOT: bu araç SKORLAMAZ. Choreia'nın skorlayıcısı henüz yok, yani\n"
          "ürettiğim bayrakların gerçek tüketicisi SIFIR. Bu araç tüketicinin\n"
          "rolünü oynayarak bayrakların süse dönüşmesini engelliyor: burada\n"
          "kontrol edilemeyen bir bayrağın tanımlı kullanımı yok demektir.")
    return 1 if (failed or decision_errors) else 0


if __name__ == "__main__":
    sys.exit(main())
