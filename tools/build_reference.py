#!/usr/bin/env python3
"""Consensus reference + tolerance from several instructors' takes.

Consumes what prepare_take.py emits and produces the artifact the runtime
scores against: for each joint, a canonical cycle sampled on a fixed phase
axis, plus a per-phase tolerance derived from how much the teachers actually
disagree.

WHY THERE IS NO DTW HERE.

The obvious design is to align takes with dynamic time warping. It would be
wrong twice over. First, motion_core owns the family's DTW and the core is not
to be reimplemented per app. Second, and more importantly, the anchor has
already solved the problem DTW would be solving: once every take is cut into
cycles that start at the same body event, the takes differ only in how long a
cycle takes. Resampling each cycle onto a fixed phase axis removes exactly that
difference. Running DTW on top would let one teacher's tempo bleed into the
consensus instead of being normalised out of it.

The assumption this buys, stated plainly: within-cycle timing is roughly
uniform across teachers. A teacher who lingers on count 1 and rushes count 2 is
phase-distorted relative to one who does not, and the resulting band is honestly
wide rather than wrong — but this tool will report that disagreement as
`residual`, not as a phase offset, because separating a within-cycle warp from a
form difference needs local time alignment and that lives in motion_core.

Mirror handling: teachers film either facing the camera or mirrored for
students to copy. In angle space, mirroring is a swap of the left_*/right_*
series, so each take is scored against the running consensus both ways and the
better orientation wins. The anchor cannot decide this (it is mirror-invariant,
see prepare_take.py) — the joint vector decides it, which is exactly what the
anchor freed it up to do.

  python3 tools/build_reference.py --step hh_roger_rabbit --takes a.json b.json
  python3 tools/build_reference.py --step S --prepared prepared.json --report
  python3 tools/build_reference.py --self-test
"""

from __future__ import annotations

import argparse
import json
import math
import statistics
import sys
from pathlib import Path

PHASE_BINS = 64

# Independent instructors required before a reference may be built (M-C-04).
# Two teachers cannot produce a variance estimate that means anything: any
# disagreement is a coin flip between them, with no majority to locate.
MIN_TAKES = 3

# Tolerance floor in degrees. Landmark jitter alone is worth a few degrees, so
# a phase where teachers happen to agree closely must not produce a band so
# tight that correct dancing scores as error.
MIN_TOLERANCE_DEG = 6.0
TOLERANCE_K = 1.5  # band = K * dispersion, floored


def mirror_joint(name: str) -> str:
    if name.startswith("left_"):
        return "right_" + name[5:]
    if name.startswith("right_"):
        return "left_" + name[6:]
    return name


# --------------------------------------------------------------------------
# phase resampling
# --------------------------------------------------------------------------

def resample(series: list[float], start: int, length: int,
             bins: int = PHASE_BINS) -> list[float] | None:
    """One cycle of `series` onto a fixed phase axis, linearly interpolated."""
    if length < 2 or start < 0 or start + length > len(series):
        return None
    out: list[float] = []
    for b in range(bins):
        pos = start + (b / bins) * length
        i = int(pos)
        frac = pos - i
        a = series[i]
        c = series[min(i + 1, start + length - 1)]
        if math.isnan(a) or math.isnan(c):
            return None
        out.append(a + (c - a) * frac)
    return out


def take_canonical_cycle(prepared: dict, bins: int = PHASE_BINS
                         ) -> dict[str, list[float]] | None:
    """Median cycle of one take, per joint.

    Taking the median ACROSS a take's own cycles before comparing takes is what
    stops one fumbled repetition from being weighed equally against another
    instructor's whole demonstration.
    """
    joints = prepared.get("joints")
    anchor = prepared.get("anchor") or {}
    period = prepared.get("periodFrames") or 0
    if not joints or not anchor.get("ok") or period < 2:
        return None

    start0 = anchor["frameInCycle"]
    n = len(next(iter(joints.values())))
    cycles = [(s, period) for s in range(start0, n - period + 1, period)]
    if not cycles:
        return None

    out: dict[str, list[float]] = {}
    for name, series in joints.items():
        stack = [r for r in (resample(series, s, ln, bins) for s, ln in cycles)
                 if r is not None]
        if not stack:
            return None
        out[name] = [statistics.median([c[b] for c in stack])
                     for b in range(bins)]
    return out


# --------------------------------------------------------------------------
# mirror resolution + consensus
# --------------------------------------------------------------------------

def mirrored(cycle: dict[str, list[float]]) -> dict[str, list[float]]:
    return {mirror_joint(k): v for k, v in cycle.items()}


def rotate_half(cycle: dict[str, list[float]]) -> dict[str, list[float]]:
    """Same cycle read from half a period later."""
    out = {}
    for k, v in cycle.items():
        h = len(v) // 2
        out[k] = v[h:] + v[:h]
    return out


def distance(a: dict[str, list[float]], b: dict[str, list[float]]) -> float:
    """Mean absolute angle difference over shared joints and phases."""
    shared = sorted(set(a) & set(b))
    if not shared:
        return float("inf")
    total, count = 0.0, 0
    for j in shared:
        for x, y in zip(a[j], b[j]):
            total += abs(x - y)
            count += 1
    return total / count if count else float("inf")


def orient(cycles: list[dict[str, list[float]]]) -> tuple[list[dict], list[dict]]:
    """Bring every take into a common handedness.

    The take whose own cycles are most self-consistent would be the natural
    seed, but that information is not carried here, so the first take seeds the
    orientation and the rest follow. Seeding is arbitrary by construction: a
    reference and its mirror are equally valid, and what matters is that the
    takes agree with EACH OTHER before their median is taken.
    """
    if not cycles:
        return [], []
    oriented = [cycles[0]]
    log = [{"index": 0, "flipped": False, "halfCycle": False,
            "margin": None, "seed": True}]
    for i, c in enumerate(cycles[1:], start=1):
        consensus = merge(oriented)
        # Four candidates, not two. The half-cycle rotation is here because
        # prepare_take anchors on whichever ankle axis actually swings, and the
        # two axes disagree by half a cycle under mirroring: lateral separation
        # (L.x-R.x) is mirror-invariant, while vertical separation (L.y-R.y)
        # anti-inverts, since mirroring leaves y alone but the anatomical label
        # swap negates it. A take anchored on "left foot lifted" therefore lands
        # half a cycle from one anchored on "left foot leading" once mirrored.
        # Searching the rotation costs one comparison and removes the need for
        # the two tools to agree on an axis.
        cands = {
            (False, False): c,
            (True, False): mirrored(c),
            (False, True): rotate_half(c),
            (True, True): rotate_half(mirrored(c)),
        }
        scored = sorted(((distance(v, consensus), k) for k, v in cands.items()))
        best_d, (flip, half) = scored[0]
        runner_d = scored[1][0]
        oriented.append(cands[(flip, half)])
        log.append({
            "index": i,
            "flipped": flip,
            "halfCycle": half,
            "bestDeg": round(best_d, 3),
            "runnerUpDeg": round(runner_d, 3),
            # Relative margin: how decisively the winning variant beat the next
            # one. Near zero means the take is close to bilaterally symmetric
            # over the joints measured, and its orientation is genuinely
            # undetermined rather than merely close.
            "margin": round((runner_d - best_d) / max(runner_d, 1e-9), 4),
        })
    return oriented, log


def merge(cycles: list[dict[str, list[float]]]) -> dict[str, list[float]]:
    joints = sorted(set().union(*(set(c) for c in cycles)))
    out: dict[str, list[float]] = {}
    for j in joints:
        cols = [c[j] for c in cycles if j in c]
        bins = len(cols[0])
        out[j] = [statistics.median([c[b] for c in cols]) for b in range(bins)]
    return out


def dispersion(cycles: list[dict[str, list[float]]], joint: str,
               b: int) -> float:
    """Mean absolute deviation about the median, scaled toward a stdev.

    NOT the median absolute deviation, which is the obvious choice and is
    silently catastrophic at this sample size. MAD has a 50% breakdown point,
    so with three teachers a single dissenter is 33% of the data and MAD
    discards them outright: for values [a, a, b] the deviations are [0, 0, d]
    and their median is exactly 0. The disagreement becomes invisible.

    That is not merely a detection miss. Tolerance is derived from this number,
    so a joint where one instructor genuinely works 25 degrees differently would
    have produced a band at the floor — and a learner faithfully copying that
    instructor would have been scored wrong, with nothing in the artifact
    hinting why.

    Averaging the deviations keeps every teacher in the estimate while centring
    on the median, so one wild take widens the band proportionally instead of
    dominating it quadratically the way a standard deviation would.
    """
    vals = [c[joint][b] for c in cycles if joint in c]
    if len(vals) < 2:
        return 0.0
    med = statistics.median(vals)
    mean_abs = sum(abs(v - med) for v in vals) / len(vals)
    return 1.2533 * mean_abs  # E|X-mu| = sigma*sqrt(2/pi) under normality


# Teachers disagreeing about WHEN look nothing like teachers disagreeing about
# HOW, and which one it is changes what a wide tolerance band means: strained
# phase assumption, or genuine style variance worth teaching around.
#
# The test is the definition itself — a timing difference is one that a small
# shift in time removes, and a posture difference is one that survives it. Each
# take is allowed its own small phase offset against the consensus; if
# dispersion collapses once those offsets are applied, the teachers were doing
# the same thing at different moments.
#
# Two earlier detectors are worth remembering as dead ends. Looking for a
# localised dispersion SPIKE never fired: warping time lifts dispersion across
# most of the cycle at once, so the median rises with it and nothing stands out.
# Correlating dispersion with the consensus GRADIENT was closer but still a
# proxy — it holds for a constant offset, and a constant offset is precisely
# what the anchor already removes, so the residual is a within-cycle warp whose
# own shape confounds the correlation. Measuring the thing directly avoids
# needing either proxy to be right.
MAX_SHIFT_FRACTION = 0.125   # +-1/8 cycle; beyond this it is a different step
TIMING_DROP = 0.5            # dispersion at most half of its unshifted value


def _shifted(series: list[float], k: int) -> list[float]:
    n = len(series)
    return [series[(b + k) % n] for b in range(n)]


def _dispersion_of(cols: list[list[float]], b: int) -> float:
    vals = [c[b] for c in cols]
    if len(vals) < 2:
        return 0.0
    med = statistics.median(vals)
    return 1.2533 * sum(abs(v - med) for v in vals) / len(vals)


def classify_disagreement(oriented: list[dict], consensus: dict[str, list[float]],
                          joint: str, bins: int) -> dict | None:
    disp = [dispersion(oriented, joint, b) for b in range(bins)]
    med = statistics.median(disp)
    if med < MIN_TOLERANCE_DEG / 3:
        return None  # teachers agree; nothing to characterise

    ref = consensus[joint]
    span = max(1, int(bins * MAX_SHIFT_FRACTION))
    aligned, shifts = [], []
    for c in oriented:
        if joint not in c:
            continue
        best_k, best_cost = 0, None
        for k in range(-span, span + 1):
            s = _shifted(c[joint], k)
            cost = sum(abs(x - y) for x, y in zip(s, ref)) / bins
            if best_cost is None or cost < best_cost:
                best_k, best_cost = k, cost
        aligned.append(_shifted(c[joint], best_k))
        shifts.append(best_k / bins)

    med_after = statistics.median([_dispersion_of(aligned, b) for b in range(bins)])
    ratio = med_after / med if med > 1e-9 else 1.0

    if ratio <= TIMING_DROP:
        kind, why = "phase_offset", (
            "global faz kayması ayrışmayı siliyor — bu eklem eğitmenler arası "
            "ERKEN/GEÇ gidiyor (çapa ayak bileğinden kurulduğu için kolların "
            "bacaklardan önde gitmesi tipik nedendir)")
    elif ratio >= 0.85:
        kind, why = "residual", (
            "global faz kayması ayrışmayı silmiyor — form farkı VEYA çevrim-içi "
            "ritim farkı; bu araç ikisini AYIRAMAZ (yerel hizalama gerekir)")
    else:
        kind, why = "mixed", "kısmen faz kaymasıyla açıklanıyor"
    return {"joint": joint, "kind": kind,
            "dispersionAfterShift": round(ratio, 3),
            "shiftsApplied": [round(s, 3) for s in shifts],
            "medianDispersionDeg": round(med, 2),
            "maxDispersionDeg": round(max(disp), 2), "why": why}


def build(prepared: list[dict], step: str, *, bins: int = PHASE_BINS) -> dict:
    usable = [p for p in prepared if p.get("usable")]
    cycles, sources = [], []
    for p in usable:
        c = take_canonical_cycle(p, bins)
        if c is not None:
            cycles.append(c)
            sources.append(p)

    if len(cycles) < MIN_TAKES:
        return {
            "step": step, "built": False,
            "why": f"{len(cycles)} kullanılabilir take — >={MIN_TAKES} gerekli (M-C-04)",
            "usableTakes": [p["videoId"] for p in sources],
        }

    oriented, mirror_log = orient(cycles)
    for entry in mirror_log:
        entry["videoId"] = sources[entry["index"]]["videoId"]
    consensus = merge(oriented)

    joints = sorted(consensus)
    tolerance = {
        j: [round(max(MIN_TOLERANCE_DEG, TOLERANCE_K * dispersion(oriented, j, b)), 2)
            for b in range(bins)]
        for j in joints
    }

    disagreement = [d for d in (classify_disagreement(oriented, consensus, j, bins)
                                for j in joints) if d]

    return {
        "step": step,
        "built": True,
        "corePin": sources[0].get("corePin"),
        "phaseBins": bins,
        "takeCount": len(oriented),
        "sources": [
            {"videoId": p["videoId"],
             "channel": (p.get("provenance") or {}).get("channel", ""),
             "periodSeconds": p.get("periodSeconds"),
             "segmentSeconds": (p.get("segment") or {}).get("seconds")}
            for p in sources
        ],
        "mirrorResolution": mirror_log,
        "reference": consensus,
        "toleranceDeg": tolerance,
        "disagreement": disagreement,
    }


# --------------------------------------------------------------------------

def _synth_take(vid: str, *, phase_shift: float = 0.0, mirror: bool = False,
                noise: float = 0.0, cycles: int = 4, period: int = 30,
                linger: float = 0.0) -> dict:
    """A teacher demonstrating the same step, optionally mirrored/off-tempo.

    `linger` warps time within the cycle — the exact assumption violation the
    dispersion report is supposed to catch.
    """
    rng = __import__("random").Random(hash(vid) & 0xFFFF)
    n = period * (cycles + 1)
    joints: dict[str, list[float]] = {}
    spec = {"left_knee": (140.0, 35.0, 0.0), "right_knee": (140.0, 35.0, math.pi),
            "left_elbow": (100.0, 20.0, 0.5), "right_elbow": (150.0, 10.0, 2.0)}
    for name, (base, amp, off) in spec.items():
        target = mirror_joint(name) if mirror else name
        series = []
        for t in range(n):
            u = (t / period + phase_shift) % 1.0
            if linger:
                u = (u + linger * math.sin(2 * math.pi * u)) % 1.0
            series.append(base + amp * math.sin(2 * math.pi * u + off)
                          + rng.gauss(0, noise))
        joints[target] = series
    return {
        "videoId": vid, "usable": True, "corePin": "motion_core-v0.3.0",
        "periodFrames": period, "periodSeconds": period / 30,
        "segment": {"seconds": n / 30},
        "anchor": {"ok": True, "frameInCycle": 0, "phase": 0.0},
        "joints": joints, "provenance": {"channel": vid},
    }


def self_test() -> int:
    print("build_reference — uzlaşma davranışı\n")
    fails = 0

    def check(label, cond, detail=""):
        nonlocal fails
        print(f"  {'✓' if cond else '✗'} {label}{('  ' + detail) if detail else ''}")
        if not cond:
            fails += 1

    two = build([_synth_take("a"), _synth_take("b")], "s")
    check("2 take ile referans ÜRETİLMEZ", not two["built"], two.get("why", ""))

    three = build([_synth_take("a", noise=1.0),
                   _synth_take("b", noise=1.0, phase_shift=0.01),
                   _synth_take("c", noise=1.0)], "s")
    check("3 temiz take ile üretilir", three["built"])
    if three["built"]:
        tol = three["toleranceDeg"]["left_knee"]
        check("uyuşan eğitmenlerde tolerans tabanda",
              max(tol) <= MIN_TOLERANCE_DEG + 1.5, f"max={max(tol):.1f}°")

    flipped = build([_synth_take("a", noise=1.0),
                     _synth_take("b", noise=1.0, mirror=True),
                     _synth_take("c", noise=1.0)], "s")
    check("aynalı take tespit edilir", flipped["built"] and
          any(e["flipped"] for e in flipped["mirrorResolution"]),
          str([(e["videoId"], e["flipped"]) for e in flipped["mirrorResolution"]]))
    if flipped["built"]:
        # Having detected and undone the mirror, the consensus must be as tight
        # as if it had never been there — otherwise the flip was cosmetic.
        tol = flipped["toleranceDeg"]["left_knee"]
        check("ayna düzeltildikten sonra tolerans dar kalır",
              max(tol) <= MIN_TOLERANCE_DEG + 1.5, f"max={max(tol):.1f}°")

    # The realistic phase-offset case, and the reason the anchor makes it
    # possible at all: the anchor is built on the ANKLES, so an instructor whose
    # arms run ahead of their legs is anchored identically and offset only in
    # the upper body. That is a per-joint global shift — exactly what the
    # detector can see.
    early_arms = _synth_take("c", noise=0.5)
    k = len(early_arms["joints"]["left_elbow"])
    shift = early_arms["periodFrames"] // 8
    for j in ("left_elbow", "right_elbow"):
        s = early_arms["joints"][j]
        early_arms["joints"][j] = [s[(i + shift) % k] for i in range(k)]
    lead = build([_synth_take("a", noise=0.5),
                  _synth_take("b", noise=0.5), early_arms], "s")
    lk = {d["joint"]: d["kind"] for d in lead.get("disagreement", [])}
    check("kolları önde giden eğitmen FAZ-KAYMASI olarak sınıflanır",
          lk.get("left_elbow") == "phase_offset", str(lk))

    # A teacher who simply bends less is a different disagreement and must not
    # be reported as a phase offset, or the label stops carrying information.
    shallow = _synth_take("c", noise=0.5)
    shallow["joints"]["left_knee"] = [v * 0.55 + 60 for v in
                                      shallow["joints"]["left_knee"]]
    posture = build([_synth_take("a", noise=0.5),
                     _synth_take("b", noise=0.5), shallow], "s")
    pk = {d["joint"]: d["kind"] for d in posture.get("disagreement", [])}
    check("sığ diz büken eğitmen ARTIK olarak sınıflanır",
          pk.get("left_knee") in ("residual", "mixed"), str(pk))

    # Documented limitation, asserted so it cannot drift into a silent claim:
    # a within-cycle warp is a timing difference that a GLOBAL shift cannot
    # undo, so it lands in `residual` alongside form differences. Separating
    # the two needs local alignment, which is motion_core's DTW, not this tool's.
    warped = build([_synth_take("a", noise=0.5),
                    _synth_take("b", noise=0.5, linger=0.18),
                    _synth_take("c", noise=0.5)], "s")
    wk = {d["joint"]: d["kind"] for d in warped.get("disagreement", [])}
    check("çevrim-içi çarpılma ARTIK'a düşer (bilinen sınır)",
          bool(wk) and all(v in ("residual", "mixed") for v in wk.values()),
          str(wk))

    print()
    if fails:
        print(f"SELF-TEST FAILED ({fails})")
        return 1
    print("SELF-TEST OK")
    print("\nSon üç satır aracın sınırını ÖLÇÜLÜ tutuyor: global faz kaymasıyla\n"
          "silinen ayrışmayı FAZ-KAYMASI diye ayırır; silinmeyeni ARTIK der ve\n"
          "form farkı ile çevrim-içi ritim farkını ayırdığını İDDİA ETMEZ —\n"
          "onun için yerel hizalama (çekirdeğin DTW'si) gerekir. Son kontrol\n"
          "bu sınırın sessizce iddiaya dönüşmesini engelliyor.")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--step")
    ap.add_argument("--takes", nargs="*", default=[],
                    help="prepare_take çıktısı JSON dosyaları")
    ap.add_argument("--prepared", help="prepare_take --all --out çıktısı (liste)")
    ap.add_argument("--out")
    ap.add_argument("--report", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()
    if not args.step:
        ap.print_help()
        return 1

    prepared: list[dict] = []
    if args.prepared:
        d = json.loads(Path(args.prepared).read_text(encoding="utf-8"))
        prepared.extend(d if isinstance(d, list) else [d])
    for p in args.takes:
        prepared.append(json.loads(Path(p).read_text(encoding="utf-8")))
    if not prepared:
        print("take verilmedi")
        return 1

    r = build(prepared, args.step)
    if not r["built"]:
        print(f"✗ {args.step}: {r['why']}")
        print(f"  kullanılabilir: {', '.join(r['usableTakes']) or '—'}")
        return 1

    print(f"✓ {args.step}: {r['takeCount']} eğitmenden referans\n")
    for s in r["sources"]:
        print(f"    {s['videoId']:<13}{s['channel'][:26]:<28}"
              f"periyot {s['periodSeconds']}s  segment {s['segmentSeconds']}s")
    print("\n  ayna çözümü:")
    for e in r["mirrorResolution"]:
        if e.get("seed"):
            print(f"    {e['videoId']:<13}tohum (yön referansı)")
        else:
            bits = ("ayna" if e["flipped"] else "düz") + \
                   ("+yarım" if e["halfCycle"] else "")
            warn = "  ⚠ marj düşük — yön belirsiz" if e["margin"] < 0.03 else ""
            print(f"    {e['videoId']:<13}{bits:<12}"
                  f"en-iyi={e['bestDeg']}° ikinci={e['runnerUpDeg']}° "
                  f"marj={e['margin']}{warn}")

    tol = r["toleranceDeg"]
    print("\n  tolerans (derece, faz boyunca):")
    for j in sorted(tol):
        col = tol[j]
        print(f"    {j:<16}min {min(col):>5.1f}  ortanca "
              f"{statistics.median(col):>5.1f}  max {max(col):>5.1f}")

    if r["disagreement"]:
        print(f"\n  eğitmen ayrışması ({len(r['disagreement'])} eklem):")
        for d in r["disagreement"]:
            tag = {"phase_offset": "FAZ-KAYMASI", "residual": "artık",
                   "mixed": "karışık"}[d["kind"]]
            print(f"    {d['joint']:<16}{tag:<11}faz-kayması-sonrası "
                  f"{d["dispersionAfterShift"]:>6}  ortanca {d['medianDispersionDeg']}°")
            if args.report:
                print(f"      {d['why']}")
        if any(d["kind"] == "phase_offset" for d in r["disagreement"]):
            print("    ⚠ FAZ-KAYMASI = o eklem eğitmenler arasında erken/geç\n"
                  "      gidiyor; geniş bandı 'önemsiz' değil 'zamanlaması\n"
                  "      tartışmalı' diye okuyun.")
    else:
        print("\n  kayda değer eğitmen ayrışması yok.")

    if args.out:
        Path(args.out).write_text(json.dumps(r, ensure_ascii=False, indent=1),
                                  encoding="utf-8")
        print(f"\nyazıldı: {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
