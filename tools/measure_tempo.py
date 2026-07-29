#!/usr/bin/env python3
"""Step-cycle tempo from a prepared take, with the factor-of-two trap disarmed.

C-032 recorded a salsa BPM that disagreed with itself: one source said 89-100,
another 160-220. The suspected cause was that the two had measured different
things about the same dancing, roughly a factor of two apart. This tool exists
to settle that by measurement — and to avoid reproducing the very same error
while doing so.

THE TRAP.

An alternating step is nearly periodic at HALF its own cycle: salsa's counts
1-2-3 mirror 5-6-7 with the feet swapped, so a detector that only asks "when
does the body look like it did before?" can lock onto the half cycle and
report double the tempo. Roger Rabbit showed the same degeneracy from the other
side — forcing a take to its runner-up mirror orientation moved the consensus
by 0.0 degrees, because mirror-plus-half-rotation is very nearly the identity
for that step.

THE DISCRIMINATOR.

Half a cycle later the LEFT and RIGHT roles have swapped. So:

  * a left/right ANTISYMMETRIC signal — signed ankle separation, which changes
    sign when the roles swap — repeats only after a FULL cycle;
  * a left/right SYMMETRIC signal — overall motion energy, blind to which foot
    is doing what — repeats after HALF a cycle.

Measure both. If the symmetric period is about half the antisymmetric one, the
full step cycle is the antisymmetric one and the factor of two is explained
rather than guessed at. If they agree, the step does not alternate and either
answer is the cycle.

  python3 tools/measure_tempo.py --video ID --beats 8
  python3 tools/measure_tempo.py --step hh_running_man --prepared all.json
"""

from __future__ import annotations

import argparse
import json
import math
import statistics
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from movement_isolator import _periodicity, normalized_series  # noqa: E402
from prepare_take import (aspect_of, leading_foot_signal, load_take,  # noqa: E402
                          prepare, to_isotropic)

MIN_PERIOD_S = 0.3
MAX_PERIOD_S = 6.0
# Two measurements count as "one is the double of the other" within this
# fractional slack. Landmark noise and a dancer's own tempo drift make an exact
# 2.000 unrealistic.
DOUBLE_TOL = 0.18


def _acf(series: list[list[float]], fps: float) -> list[tuple[float, float]]:
    """(period_seconds, correlation) over the plausible lag range.

    The autocorrelation is computed here rather than by calling the core
    isolator's `_periodicity` once per lag. That function now *searches* a lag
    range for a prominent interior peak (the M-C-25 fix), so asking it about a
    single lag hands it a one-element range in which no interior peak can
    exist and it correctly returns zero — a whole curve of zeros. The peak
    logic lives one level up, here; what is needed at this level is the raw
    curve.
    """
    n = len(series)
    lo, hi = max(1, int(MIN_PERIOD_S * fps)), min(int(MAX_PERIOD_S * fps), n // 3)
    if hi <= lo or n < 4:
        return []
    dim = len(series[0])
    means = [sum(f[d] for f in series) / n for d in range(dim)]
    c = [[f[d] - means[d] for d in range(dim)] for f in series]

    out: list[tuple[float, float]] = []
    for lag in range(lo, hi + 1):
        num = e1 = e2 = 0.0
        for t in range(n - lag):
            for d in range(dim):
                a, b = c[t][d], c[t + lag][d]
                num += a * b
                e1 += a * a
                e2 += b * b
        denom = math.sqrt(e1 * e2)
        out.append((lag / fps, num / denom if denom > 1e-12 else 0.0))
    return out


def _best_peak(curve: list[tuple[float, float]]) -> tuple[float, float] | None:
    """Most prominent interior local maximum, same rule as the core isolator."""
    if len(curve) < 5:
        return None
    r = [c for _, c in curve]
    best = None
    for k in range(1, len(r) - 1):
        if not (r[k] > r[k - 1] and r[k] >= r[k + 1]):
            continue
        j = k
        while j > 0 and r[j - 1] < r[j]:
            j -= 1
        left = r[j]
        j = k
        while j < len(r) - 1 and r[j + 1] < r[j]:
            j += 1
        prom = r[k] - max(left, r[j])
        if prom < 0.08:
            continue
        if best is None or r[k] > best[1]:
            best = (curve[k][0], r[k])
    return best


# Mirrored landmark pairs that carry a step. Summing each pair is what makes
# the channel blind to which side is doing what.
PAIRS = [(11, 12), (13, 14), (15, 16), (23, 24), (25, 26), (27, 28)]
L_SH, R_SH, L_HP, R_HP = 11, 12, 23, 24


def symmetric_series(frames) -> list[list[float]]:
    """Body description that is INVARIANT under swapping left and right.

    The first attempt used the plain torso-normalised landmark series and it
    could not do the job: that vector lists each side separately, so it still
    knows which foot is which and therefore repeats on the FULL cycle, exactly
    like the antisymmetric channel. Every take came back with a ratio near 1.0
    and the discriminator silently measured nothing.

    Summing each mirrored pair fixes it. Under a left/right swap the summands
    trade places and the sum is unchanged, so this channel genuinely repeats
    once per half cycle when the step alternates.
    """
    out: list[list[float]] = []
    for lm in frames:
        hx = (lm[L_HP][0] + lm[R_HP][0]) / 2
        hy = (lm[L_HP][1] + lm[R_HP][1]) / 2
        sx = (lm[L_SH][0] + lm[R_SH][0]) / 2
        sy = (lm[L_SH][1] + lm[R_SH][1]) / 2
        torso = math.hypot(sx - hx, sy - hy)
        if torso < 1e-6:
            continue
        row: list[float] = []
        for a, b in PAIRS:
            row.append(((lm[a][0] - hx) + (lm[b][0] - hx)) / torso)
            row.append(((lm[a][1] - hy) + (lm[b][1] - hy)) / torso)
        out.append(row)
    return out


def _peak_near(curve: list[tuple[float, float]], target: float,
               tol: float = DOUBLE_TOL) -> tuple[float, float] | None:
    """Is there a local maximum within `tol` (fractional) of `target` seconds?"""
    if not curve or target <= 0:
        return None
    r = [c for _, c in curve]
    hits = []
    for k in range(1, len(r) - 1):
        if not (r[k] > r[k - 1] and r[k] >= r[k + 1]):
            continue
        per = curve[k][0]
        if abs(per - target) / target <= tol:
            hits.append((per, r[k]))
    return max(hits, key=lambda h: h[1]) if hits else None


def measure(video_id: str, beats: int) -> dict:
    p = prepare(video_id)
    if not p.get("usable"):
        return {"videoId": video_id, "ok": False, "why": p.get("why")}
    seg = p["segment"]
    _, lm, _, _, fps = load_take(video_id)
    iso = to_isotropic(lm, aspect_of(video_id))[seg["startFrame"]:seg["endFrame"]]

    # Antisymmetric channel: signed ankle separation on whichever axis the
    # anchor used, as a single-column series.
    sig, axis = leading_foot_signal(iso)
    anti = [[v] for v in sig if not math.isnan(v)]

    sym = symmetric_series(iso)

    a_peak = _best_peak(_acf(anti, fps))
    sym_curve = _acf(sym, fps)
    s_peak = _best_peak(sym_curve)
    # Targeted question, not a free search. A symmetric signal repeats at BOTH
    # the half cycle and the full one, and the full-cycle match is the stronger
    # of the two (exact rather than approximate) — so simply taking the tallest
    # peak finds T and reports "not alternating" for a step that plainly does
    # alternate. What actually distinguishes the two cases is whether the
    # symmetric channel has a peak at HALF the antisymmetric period at all.
    half_peak = _peak_near(sym_curve, a_peak[0] / 2) if a_peak else None

    out = {
        "videoId": video_id, "ok": True, "fps": fps, "anchorAxis": axis,
        "antisymmetricPeriodS": round(a_peak[0], 3) if a_peak else None,
        "antisymmetricAcf": round(a_peak[1], 3) if a_peak else None,
        "symmetricPeriodS": round(s_peak[0], 3) if s_peak else None,
        "symmetricAcf": round(s_peak[1], 3) if s_peak else None,
        "isolatorPeriodS": p.get("periodSeconds"),
    }

    out["symmetricHalfPeriodS"] = round(half_peak[0], 3) if half_peak else None
    out["symmetricHalfAcf"] = round(half_peak[1], 3) if half_peak else None

    if a_peak and half_peak:
        out["verdict"] = "alternating"
        out["cycleSeconds"] = a_peak[0]
        out["ratio"] = round(a_peak[0] / half_peak[0], 3)
        out["why"] = ("simetrik kanalda antisimetriğin YARISINDA tepe var "
                      "→ adım DÖNÜŞÜMLÜ; tam çevrim antisimetrik olan")
    elif a_peak and s_peak:
        out["verdict"] = "non_alternating"
        out["cycleSeconds"] = a_peak[0]
        out["ratio"] = round(a_peak[0] / s_peak[0], 3) if s_peak[0] else None
        out["why"] = ("simetrik kanalda yarım-çevrim tepesi YOK → adım "
                      "dönüşümlü değil, tek çevrim")
    elif a_peak:
        out["verdict"] = "antisymmetric_only"
        out["cycleSeconds"] = a_peak[0]
        out["why"] = "simetrik kanalda belirgin tepe yok; tek kanala dayanıyor"
    else:
        out["verdict"] = "no_peak"
        out["cycleSeconds"] = None
        out["why"] = "hiçbir kanalda belirgin tepe yok"

    if out.get("cycleSeconds"):
        out["beatsPerCycle"] = beats
        out["bpm"] = round(beats * 60.0 / out["cycleSeconds"], 1)
        # The number the trap would have produced, printed so a reader can see
        # which of two disputed figures corresponds to which mistake.
        out["bpmIfHalfCycleMistaken"] = round(beats * 60.0 /
                                              (out["cycleSeconds"] / 2), 1)
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--video")
    ap.add_argument("--videos", nargs="*", default=[])
    ap.add_argument("--beats", type=int, default=8,
                    help="çevrim başına müzikal vuruş (salsa 8, hip-hop adımı 4/8)")
    ap.add_argument("--out")
    args = ap.parse_args()

    ids = ([args.video] if args.video else []) + list(args.videos)
    if not ids:
        ap.print_help()
        return 1

    rows = [measure(v, args.beats) for v in ids]
    print(f"{'video':<13}{'anti':>8}{'sim':>8}{'oran':>7}{'karar':<20}"
          f"{'çevrim':>8}{'BPM':>7}{'(yarım hata)':>13}")
    for r in rows:
        if not r.get("ok"):
            print(f"{r['videoId']:<13}  — {r.get('why','')}")
            continue
        print(f"{r['videoId']:<13}"
              f"{str(r['antisymmetricPeriodS'] or '-'):>8}"
              f"{str(r['symmetricPeriodS'] or '-'):>8}"
              f"{str(r.get('ratio','-')):>7}"
              f"  {r['verdict']:<18}"
              f"{str(r.get('cycleSeconds') or '-'):>8}"
              f"{str(r.get('bpm','-')):>7}"
              f"{str(r.get('bpmIfHalfCycleMistaken','-')):>13}")

    good = [r for r in rows if r.get("bpm")]
    if good:
        bpms = [r["bpm"] for r in good]
        print(f"\n{len(good)} take · BPM ortanca {statistics.median(bpms):.1f} "
              f"(aralık {min(bpms):.0f}-{max(bpms):.0f})")
        print("  'yarım hata' sütunu: çevrimi yarım sanan bir ölçümün vereceği\n"
              "  sayı. İki çelişkili kaynak arasında ~2× fark varsa, biri\n"
              "  büyük olasılıkla o sütundadır (C-032).")
    if args.out:
        Path(args.out).write_text(json.dumps(rows, ensure_ascii=False, indent=1),
                                  encoding="utf-8")
        print(f"yazıldı: {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
