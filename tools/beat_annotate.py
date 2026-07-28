#!/usr/bin/env python3
"""Fits a beat grid to hand-tapped timestamps.

Beat annotation cannot be taken from a harvested video: the audio is somebody
else's, so no grid derived from it may ship. Beats therefore come from a human
tapping along, and this module turns that noisy tap train into the constant-
tempo grid the scoring engine needs — plus an honest quality verdict on whether
the annotation is good enough to keep.

Only derived numbers survive this step. The video and its audio are never
retained; what enters the product is a BPM, a downbeat offset, and landmark
sequences.

Run the self-check with:  python3 tools/beat_annotate.py --self-test
"""

from __future__ import annotations

import argparse
import json
import math
import random
import statistics
import sys
from dataclasses import dataclass, asdict


@dataclass
class BeatGridFit:
    bpm: float
    first_beat_s: float
    residual_sd_ms: float
    tap_count: int
    outlier_indices: list[int]
    verdict: str
    note: str

    def to_json(self) -> str:
        return json.dumps(asdict(self), indent=2)


# Human tapping is not precise. These bars come from the same place as the
# scoring tolerances: rhythm-game judgement windows and sensorimotor
# synchronisation variability. They are provisional and are the reason the
# verdict is reported rather than assumed.
GOOD_RESIDUAL_MS = 25.0
USABLE_RESIDUAL_MS = 45.0
MIN_TAPS = 8


def _assign_beats(taps: list[float], bpm: float, first: float) -> list[int]:
    period = 60.0 / bpm
    return [round((t - first) / period) for t in taps]


def _fit_once(taps: list[float], beats: list[int]) -> tuple[float, float]:
    """Least-squares line through (beat index, tap time) → period and offset."""
    n = len(taps)
    mean_b = sum(beats) / n
    mean_t = sum(taps) / n
    num = sum((b - mean_b) * (t - mean_t) for b, t in zip(beats, taps))
    den = sum((b - mean_b) ** 2 for b in beats)
    period = num / den if den > 1e-12 else 0.0
    offset = mean_t - period * mean_b
    return period, offset


def fit_beat_grid(
    taps_s: list[float],
    *,
    max_iterations: int = 12,
    outlier_sigma: float = 2.5,
) -> BeatGridFit:
    """Fits a constant-tempo grid to tap timestamps in seconds.

    Two-stage on purpose. The median inter-tap interval gives a starting tempo
    that a single badly-placed tap cannot wreck; least squares then refines it
    across the whole take, which is what actually pins down the downbeat. Doing
    only the first would drift over a long take; doing only the second needs a
    starting guess it does not have.
    """
    taps = sorted(t for t in taps_s if t is not None)
    if len(taps) < 3:
        return BeatGridFit(0, 0, 0, len(taps), [], "reject",
                           "fewer than 3 taps — nothing to fit")

    intervals = [b - a for a, b in zip(taps, taps[1:]) if b > a]
    if not intervals:
        return BeatGridFit(0, 0, 0, len(taps), [], "reject", "taps do not advance")

    # Median, not mean: one double-tap or missed beat would otherwise halve or
    # double the tempo estimate and poison every downstream tolerance.
    period = statistics.median(intervals)
    if period <= 1e-6:
        return BeatGridFit(0, 0, 0, len(taps), [], "reject", "degenerate interval")
    bpm = 60.0 / period
    first = taps[0]

    beats = _assign_beats(taps, bpm, first)
    for _ in range(max_iterations):
        period, first = _fit_once(taps, beats)
        if period <= 1e-6:
            return BeatGridFit(0, 0, 0, len(taps), [], "reject", "fit collapsed")
        bpm = 60.0 / period
        new_beats = _assign_beats(taps, bpm, first)
        if new_beats == beats:
            break
        beats = new_beats

    residuals = [t - (first + b * (60.0 / bpm)) for t, b in zip(taps, beats)]
    sd = statistics.pstdev(residuals) if len(residuals) > 1 else 0.0
    outliers = [i for i, r in enumerate(residuals)
                if sd > 1e-9 and abs(r) > outlier_sigma * sd]

    sd_ms = sd * 1000.0
    if len(taps) < MIN_TAPS:
        verdict, note = "usable", (
            f"only {len(taps)} taps — grid is fitted but the downbeat estimate "
            f"is weak; {MIN_TAPS}+ recommended")
    elif sd_ms <= GOOD_RESIDUAL_MS:
        verdict, note = "good", "tap spread within the tight band"
    elif sd_ms <= USABLE_RESIDUAL_MS:
        verdict, note = "usable", "tap spread wide but the grid is still meaningful"
    else:
        verdict, note = "reject", (
            "tap spread exceeds the annotation tolerance — re-annotate; a grid "
            "this loose would put its own error into every timing score")

    return BeatGridFit(
        bpm=round(bpm, 3),
        first_beat_s=round(first, 6),
        residual_sd_ms=round(sd_ms, 2),
        tap_count=len(taps),
        outlier_indices=outliers,
        verdict=verdict,
        note=note,
    )


# --------------------------------------------------------------------------
# Self-check: how many taps does an annotator need, and how much jitter can we
# absorb? Measured rather than assumed.
# --------------------------------------------------------------------------

def _simulate(bpm: float, n: int, jitter_ms: float, seed: int,
              drop: int = 0, double: int = 0) -> list[float]:
    rng = random.Random(seed)
    period = 60.0 / bpm
    taps = [0.35 + i * period + rng.gauss(0, jitter_ms / 1000.0) for i in range(n)]
    for _ in range(drop):
        if len(taps) > 4:
            taps.pop(rng.randrange(1, len(taps) - 1))
    for _ in range(double):
        if taps:
            i = rng.randrange(len(taps))
            taps.append(taps[i] + rng.uniform(0.01, 0.05))
    return sorted(taps)


def self_test() -> int:
    print("beat grid fitting — measured accuracy\n")
    print(f"{'scenario':<34}{'BPM err':>10}{'downbeat err':>14}{'sd(ms)':>9}"
          f"{'verdict':>10}")
    failures = 0

    def run(label: str, bpm: float, n: int, jitter: float, seed: int,
            drop: int = 0, double: int = 0, expect: str | None = None,
            max_bpm_err: float = 1.0, max_first_err_ms: float = 60.0) -> None:
        nonlocal failures
        taps = _simulate(bpm, n, jitter, seed, drop, double)
        fit = fit_beat_grid(taps)
        bpm_err = abs(fit.bpm - bpm)
        first_err = abs(fit.first_beat_s - 0.35) * 1000
        print(f"{label:<34}{bpm_err:>10.3f}{first_err:>13.1f}m"
              f"{fit.residual_sd_ms:>9.1f}{fit.verdict:>10}")
        if expect and fit.verdict != expect:
            print(f"    ! expected verdict {expect}, got {fit.verdict}")
            failures += 1
        if fit.verdict != "reject":
            if bpm_err > max_bpm_err:
                print(f"    ! BPM error {bpm_err:.3f} exceeds {max_bpm_err}")
                failures += 1
            if first_err > max_first_err_ms:
                print(f"    ! downbeat error {first_err:.1f}ms exceeds "
                      f"{max_first_err_ms}")
                failures += 1

    run("16 taps, tight (10ms)", 96, 16, 10, 1, expect="good")
    run("16 taps, typical (25ms)", 96, 16, 25, 2)
    run("32 taps, typical (25ms)", 96, 32, 25, 3)
    run("8 taps, typical (25ms)", 96, 8, 25, 4)
    run("4 taps, typical (25ms)", 96, 4, 25, 5, expect="usable",
        max_bpm_err=4.0, max_first_err_ms=120.0)
    run("16 taps, sloppy (70ms)", 96, 16, 70, 6, expect="reject")
    run("32 taps + 2 missed beats", 96, 32, 25, 7, drop=2)
    run("32 taps + 2 double-taps", 96, 32, 25, 8, double=2,
        max_bpm_err=2.0, max_first_err_ms=120.0)
    run("fast tempo 150, 32 taps", 150, 32, 25, 9)
    run("slow tempo 70, 32 taps", 70, 32, 25, 10)

    print()
    if failures:
        print(f"SELF-TEST FAILED ({failures} assertion(s))")
        return 1
    print("SELF-TEST OK")
    print("\nWorkflow conclusion: 16+ taps at ordinary human precision pin the "
          "tempo well within a beat-alignment window; 4 taps do not and the fit "
          "says so rather than pretending.")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--taps", help="comma-separated tap times in seconds")
    args = ap.parse_args()

    if args.self_test:
        return self_test()
    if args.taps:
        taps = [float(x) for x in args.taps.split(",") if x.strip()]
        print(fit_beat_grid(taps).to_json())
        return 0
    ap.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
