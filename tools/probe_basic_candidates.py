#!/usr/bin/env python3
"""Is the salsa BASIC already in the footage we harvested for the shines?

M-F-128 asks a cheap question before an expensive one: `ss_basic` has no
reference (collectedTakes 0, lesson locked), but five salsa clips are already
extracted — including a compilation whose own title claims five different
footwork steps. If three independent sources happen to contain the basic, the
reference can be built with no new harvest at all.

WHAT MAKES A SEGMENT "THE BASIC" — taken from the step's own config, not
invented here. `steps/ss_basic.json` states two things a camera can see:

  * `hold_4` (minDurationMs 120) and its note: "Counts 4 and 8 are held, not
    stepped — the pause is part of the step." So the basic contains a PLATEAU:
    a stretch where the body is markedly still, twice per cycle.
  * `fwd_step` / `back_step` enter on `left_thigh_forward` / `right_thigh_back`,
    and STEP_TOO_LARGE only trips at 38 degrees of thigh excursion. So the
    basic TRAVELS: a large sagittal thigh swing.

Shine footwork is the opposite on both counts, and that was measured, not
assumed: its rate-of-change signal has no third low-velocity region (which is
why STEP_MISSED_ON_4 was dropped from ss_shine_footwork.json), and its whole
thigh excursion is 1.4-4.0 degrees. So the two steps are separable on evidence
this pipeline already produces.

NEGATIVE CONTROL IS PART OF THE RUN. The three sources that built
ss_shine_footwork are probed too, at their known shine segments. If the plateau
detector "finds" the basic there, the detector is wrong — printed as a FAIL
rather than quietly reported as five basic candidates.

  python3 tools/probe_basic_candidates.py
  python3 tools/probe_basic_candidates.py --video bqoNqA2hmE4
"""

from __future__ import annotations

import argparse
import json
import math
import statistics
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from camera_angle_gate import find_usable_windows_world  # noqa: E402
from movement_isolator import find_movement_windows  # noqa: E402
from prepare_take import (aspect_of, ankle_visibility, find_anchor,  # noqa: E402
                          joint_series, leading_foot_signal, load_take,
                          to_isotropic)
from build_reference import (PHASE_BINS, take_canonical_cycle,  # noqa: E402
                             ang_diff, distance, mirrored, VARIANTS,
                             rotate_half)

REPO = Path(__file__).resolve().parents[1]
SHINE_REF = REPO / "content/references/ss_shine_footwork.json"
STEP_PATH = REPO / "content/styles/salsa_shines/steps/ss_basic.json"


def declared_window_s() -> float:
    """The step's own analysisWindow declaration (M-F-144), or the family default.

    Read rather than hardcoded: an 8-count step is invisible in the isolator's
    6s default by construction (C-104 limit (a)), and the fix belongs in the
    step config where the measurement that justifies it also lives.
    """
    step = json.loads(STEP_PATH.read_text(encoding="utf-8"))
    win = (step.get("analysisWindow") or {}).get("windowSeconds")
    return float(win) if win else 6.0

# The five extracted salsa clips: the three that built ss_shine_footwork, the
# one excluded as identity-ambiguous (M-F-115 — a 5-step compilation, the most
# likely place for a basic to hide), and the one excluded on anchor grounds.
SOURCES = {
    "SHGkSbJm2Iw": "Dame Más Dance — Suzie Q (shine source)",
    "jjP8bKWCg9U": "The Get Down — Salsa Basic Footwork (shine source)",
    "w4opJ2ezmd4": "Alfonso y Mónica — Pasos Libres (shine source)",
    "bqoNqA2hmE4": "Dalia Dance — '5 FOOTWORK/Shine Steps' COMPILATION",
    "v_y4l3lAZ0Q": "Dance With Rasa (excluded: ankle visibility 0.007)",
    # Targeted round (M-F-132/139), single-step basic lessons:
    "wV8cDpJa2f4": "Salsaventura — Basic Step for the Absolute Beginner",
    "9NZp9_GuKrE": "Ballroom Feed — Forward & Back",
    "FtZzjGsPxjg": "Dame Mas Dance — Front & Back Basic Variations",
    "Ns5TaVGv6uY": "Dance Dojo — 10 Minute Basic Steps Practice",
}
SHINE_SOURCES = {"SHGkSbJm2Iw", "jjP8bKWCg9U", "w4opJ2ezmd4"}

LEG_JOINTS = ("left_hip", "right_hip", "left_knee", "right_knee",
              "left_thigh", "right_thigh", "left_shin", "right_shin")

# A hold of 120 ms (ss_basic hold_4.minDurationMs) on a ~1.1 s cycle sampled at
# 64 bins is about 7 bins. Declared in BINS because the cycle is phase-resampled
# by then; the millisecond figure is what it is derived FROM.
MIN_PLATEAU_BINS = 7
# The basic's thigh excursion has to clear the shine's measured ceiling by a
# real margin to be a different step rather than the same step read noisily.
# Shine measured 1.4-4.0 deg; ss_basic's own STEP_TOO_LARGE sits at 38 deg.
MIN_BASIC_THIGH_EXCURSION_DEG = 12.0


def _smooth(xs: list[float], k: int = 2) -> list[float]:
    n = len(xs)
    return [sum(xs[(i + j) % n] for j in range(-k, k + 1)) / (2 * k + 1)
            for i in range(n)]


def rate_of_change(cycle: dict[str, list[float]]) -> list[float]:
    """Coordinated multi-joint speed, per phase bin.

    Same construction used to find ss_shine_footwork's settle points: z-score
    each leg joint's curve so no single joint's range dominates, then sum the
    absolute bin-to-bin change across joints.
    """
    bins = len(cycle[LEG_JOINTS[0]])
    z: dict[str, list[float]] = {}
    for j in LEG_JOINTS:
        sm = _smooth(cycle[j])
        mean = sum(sm) / bins
        sd = (sum((v - mean) ** 2 for v in sm) / bins) ** 0.5 or 1.0
        z[j] = [(v - mean) / sd for v in sm]
    rate = []
    for i in range(bins):
        rate.append(sum(abs(z[j][i] - z[j][(i - 1) % bins]) for j in LEG_JOINTS))
    return _smooth(rate)


def plateaus(cycle: dict[str, list[float]]) -> list[tuple[int, int]]:
    """Runs of bins where coordinated motion is markedly below its own median.

    "Markedly" is half the median rather than the median itself: a cycle always
    spends about half its bins below its own median, so the median alone would
    report a plateau in any movement whatsoever — including the shine, which is
    measured NOT to have one. This threshold has to separate 'slower than
    average' from 'held'.
    """
    rate = rate_of_change(cycle)
    med = statistics.median(rate)
    low = [r < med * 0.5 for r in rate]
    n = len(low)
    runs: list[tuple[int, int]] = []
    i = 0
    while i < n:
        if not low[i]:
            i += 1
            continue
        start = i
        while i < n and low[i]:
            i += 1
        runs.append((start, i - start))
    # A plateau can straddle bin 0; join the wrap-around pair.
    if len(runs) > 1 and runs[0][0] == 0 and runs[-1][0] + runs[-1][1] == n:
        first, last = runs[0], runs.pop()
        runs[0] = (last[0], last[1] + first[1])
    return [r for r in runs if r[1] >= MIN_PLATEAU_BINS]


def thigh_excursion(cycle: dict[str, list[float]]) -> float:
    """Peak-to-peak sagittal thigh swing, the larger of the two legs."""
    out = 0.0
    for j in ("left_thigh", "right_thigh"):
        series = cycle[j]
        base = series[0]
        rel = [ang_diff(v, base) for v in series]
        out = max(out, max(rel) - min(rel))
    return out


def shine_distance(cycle: dict[str, list[float]], ref: dict) -> float:
    """Best-orientation leg-only distance to the built shine reference."""
    a = {k: v for k, v in cycle.items() if k in LEG_JOINTS}
    b = {k: v for k, v in ref.items() if k in LEG_JOINTS}

    def variant(c, flip, half):
        out = mirrored(c) if flip else c
        return rotate_half(out) if half else out

    return min(distance(variant(a, f, h), b) for f, h in VARIANTS)


def _overlap(a: tuple[int, int], b: tuple[int, int]):
    lo, hi = max(a[0], b[0]), min(a[1], b[1])
    return (lo, hi) if hi > lo else None


def probe(video_id: str, shine_ref: dict, window_s: float | None = None) -> list[dict]:
    """Every camera-clean movement window in one clip, measured."""
    doc, lm, world, _, fps = load_take(video_id)
    iso = to_isotropic(lm, aspect_of(video_id))
    moves = find_movement_windows(iso, fps=fps, max_windows=40,
                                  window_s=window_s or declared_window_s())
    cam = []
    if all(w for w in world):
        cam = [(w.start_frame, w.end_frame)
               for w in find_usable_windows_world(world, fps=fps, max_windows=40)]

    rows: list[dict] = []
    for m in moves:
        seg = (m.start_frame, m.end_frame)
        if cam:
            best = None
            for c in cam:
                o = _overlap(seg, c)
                if o and (best is None or (o[1] - o[0]) > (best[1] - best[0])):
                    best = o
            if best is None:
                continue
            seg = best
        period_frames = max(2, int(round(m.period_s * fps)))
        if seg[1] - seg[0] < period_frames * 3:
            continue
        frames = iso[seg[0]:seg[1]]
        signal, _axis = leading_foot_signal(frames)
        anchor = find_anchor(signal, period_frames,
                             visibility=ankle_visibility(frames), knee_swing=None)
        if not anchor.get("ok"):
            continue
        cycle = take_canonical_cycle({"joints": joint_series(frames),
                                      "anchor": anchor,
                                      "periodFrames": period_frames})
        if cycle is None:
            continue
        pls = plateaus(cycle)
        exc = thigh_excursion(cycle)
        rows.append({
            "videoId": video_id,
            "segment": list(seg),
            "seconds": round((seg[1] - seg[0]) / fps, 2),
            "periodSeconds": round(m.period_s, 2),
            "plateaus": [{"startBin": s, "bins": n} for s, n in pls],
            "plateauCount": len(pls),
            "thighExcursionDeg": round(exc, 2),
            "shineDistanceDeg": round(shine_distance(cycle, shine_ref), 2),
            "basicCandidate": len(pls) >= 2 and exc >= MIN_BASIC_THIGH_EXCURSION_DEG,
        })
    return rows


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--video", help="tek kaynak (varsayılan: hepsi)")
    ap.add_argument("--window-s", type=float,
                    help="varsayılan: adımın analysisWindow beyanı (M-F-144)")
    ap.add_argument("--out")
    args = ap.parse_args()

    shine = json.loads(SHINE_REF.read_text(encoding="utf-8"))["reference"]
    ids = [args.video] if args.video else list(SOURCES)

    ws = args.window_s or declared_window_s()
    print(f"ss_basic aday taraması — ölçütler adımın KENDİ config'inden (pencere {ws}s):")
    print(f"  plato: >={MIN_PLATEAU_BINS} bin (hold_4 minDurationMs=120ms), >=2 tane "
          f"(count 4 ve 8)")
    print(f"  ileri-geri: uyluk salınımı >={MIN_BASIC_THIGH_EXCURSION_DEG}deg "
          f"(shine ölçülen tavanı 4.0deg)\n")

    all_rows: list[dict] = []
    for vid in ids:
        print(f"{vid} — {SOURCES.get(vid, '?')}")
        try:
            rows = probe(vid, shine, args.window_s)
        except SystemExit as e:          # load_take fail-closed (eksik fixture/fps)
            print(f"    atlandı: {e}\n")
            continue
        if not rows:
            print("    kamera-temiz + çapalanabilir pencere YOK\n")
            continue
        for r in rows:
            mark = "  <== BASIC ADAYI" if r["basicCandidate"] else ""
            print(f"    {str(r['segment']):<18} {r['seconds']:>6.2f}s  "
                  f"per={r['periodSeconds']:.2f}s  plato={r['plateauCount']}  "
                  f"uyluk={r['thighExcursionDeg']:>6.2f}°  "
                  f"shine-mesafe={r['shineDistanceDeg']:>6.2f}°{mark}")
        all_rows.extend(rows)
        print()

    # NEGATIVE CONTROL — the detector must not call the known shine segments
    # "basic". A detector that fires everywhere measures nothing.
    print("NEGATİF KONTROL — bilinen shine segmentlerinde plato bulunmamalı:")
    fails = 0
    for vid in sorted(SHINE_SOURCES & set(ids)):
        mine = [r for r in all_rows if r["videoId"] == vid]
        bad = [r for r in mine if r["basicCandidate"]]
        if bad:
            print(f"  ✗ {vid}: {len(bad)} pencere BASIC diye işaretlendi — "
                  "dedektör shine'ı basic'ten ayıramıyor")
            fails += 1
        else:
            print(f"  ✓ {vid}: hiçbir pencere basic diye işaretlenmedi "
                  f"({len(mine)} pencere tarandı)")

    cands = [r for r in all_rows if r["basicCandidate"]]
    srcs = sorted({r["videoId"] for r in cands})
    print(f"\nSONUÇ: {len(cands)} aday pencere, {len(srcs)} bağımsız kaynak")
    if srcs:
        print(f"  kaynaklar: {', '.join(srcs)}")
    if len(srcs) >= 3:
        print("  → M-C-04 sağlanır: referans DENENEBİLİR")
    else:
        print(f"  → M-C-04 SAĞLANMAZ (>=3 gerekli, {len(srcs)} var) — "
              "isimli ret: ss_basic bu havuzda yok, hedefli hasat gerekiyor")

    if args.out:
        Path(args.out).write_text(
            json.dumps(all_rows, ensure_ascii=False, indent=1, allow_nan=False),
            encoding="utf-8")
        print(f"\nyazıldı: {args.out}")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
