#!/usr/bin/env python3
"""Camera-angle quality gate for harvested reference takes (C-019b).

The whole normalization stack assumes the dancer faces the camera. Joint angles
are measured in the image plane because single-camera depth is the weakest
channel a pose model emits — which is exactly why an obliquely-filmed take is
dangerous rather than merely imperfect: the angles still compute, they are just
quietly wrong, and nothing downstream can tell.

Tutorial footage is filmed however the instructor felt like filming it, so this
gate has to run before any harvested take reaches the reference builder.

Self-check:  python3 tools/camera_angle_gate.py --self-test
"""

from __future__ import annotations

import argparse
import json
import math
import statistics
import sys
from dataclasses import dataclass, asdict

# BlazePose GHUM indices used here.
L_SHOULDER, R_SHOULDER = 11, 12
L_HIP, R_HIP = 23, 24

OK_YAW_DEG = 15.0
OBLIQUE_YAW_DEG = 35.0


@dataclass
class AngleVerdict:
    verdict: str
    median_yaw_deg: float
    p90_yaw_deg: float
    z_cross_check_deg: float
    frames: int
    reason: str

    def to_json(self) -> str:
        return json.dumps(asdict(self), indent=2)


def _mid(a, b):
    return [(a[i] + b[i]) / 2 for i in range(3)]


def _dist2d(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def _percentile(values: list[float], q: float) -> float:
    if not values:
        return 0.0
    s = sorted(values)
    k = (len(s) - 1) * q
    lo = math.floor(k)
    hi = math.ceil(k)
    if lo == hi:
        return s[int(k)]
    return s[lo] + (s[hi] - s[lo]) * (k - lo)


def shoulder_ratio_series(frames: list[list[list[float]]]) -> list[float]:
    """shoulderWidth / torsoLength per frame, in the image plane."""
    out = []
    for lm in frames:
        sw = _dist2d(lm[L_SHOULDER], lm[R_SHOULDER])
        torso = _dist2d(_mid(lm[L_SHOULDER], lm[R_SHOULDER]),
                        _mid(lm[L_HIP], lm[R_HIP]))
        out.append(sw / torso if torso > 1e-9 else 0.0)
    return out


def z_yaw_series(frames: list[list[list[float]]]) -> list[float]:
    """Yaw estimated from left/right shoulder depth difference, in degrees.

    Independent of the self-calibration below, and therefore the only thing that
    can catch a take filmed at an angle from beginning to end.
    """
    out = []
    for lm in frames:
        sw = _dist2d(lm[L_SHOULDER], lm[R_SHOULDER])
        dz = abs(lm[L_SHOULDER][2] - lm[R_SHOULDER][2])
        span = math.hypot(sw, dz)
        if span < 1e-9:
            out.append(0.0)
            continue
        out.append(math.degrees(math.asin(min(1.0, dz / span))))
    return out


def evaluate(frames: list[list[list[float]]]) -> AngleVerdict:
    """Judges whether a take was filmed close enough to fronto-parallel."""
    if len(frames) < 5:
        return AngleVerdict("reject", 0, 0, 0, len(frames),
                            "too few frames to judge")

    ratios = shoulder_ratio_series(frames)
    usable = [r for r in ratios if r > 1e-6]
    if not usable:
        return AngleVerdict("reject", 0, 0, 0, len(frames),
                            "torso reference unusable")

    # The dancer's own fronto-parallel reference: the widest their shoulders
    # ever appear within this take. Self-calibrating, so it needs no population
    # constant and works for any build. p90 rather than max so one noisy frame
    # cannot set the baseline.
    reference = _percentile(usable, 0.90)
    if reference <= 1e-6:
        return AngleVerdict("reject", 0, 0, 0, len(frames), "no usable reference")

    yaws = [math.degrees(math.acos(max(0.0, min(1.0, r / reference))))
            for r in ratios]
    median_yaw = statistics.median(yaws)
    p90_yaw = _percentile(yaws, 0.90)

    z_yaws = z_yaw_series(frames)
    z_median = statistics.median(z_yaws) if z_yaws else 0.0

    # The self-calibrated estimate is relative: a take filmed at a constant
    # angle throughout would read near zero, because the turned pose became its
    # own baseline. The depth channel is noisy but absolute, so it is used only
    # as a blind-spot alarm, never as the primary measure.
    if z_median > OBLIQUE_YAW_DEG and median_yaw < OK_YAW_DEG:
        return AngleVerdict(
            "reject", round(median_yaw, 1), round(p90_yaw, 1),
            round(z_median, 1), len(frames),
            "in-take yaw looks small but depth says the dancer is turned for "
            "the whole take — the self-calibrated baseline is itself oblique")

    if p90_yaw <= OK_YAW_DEG:
        verdict, reason = "ok", "close to fronto-parallel throughout"
    elif p90_yaw <= OBLIQUE_YAW_DEG:
        verdict, reason = "oblique", (
            "turns away from the camera during the take — usable for step order "
            "and timing, not for joint-angle reference")
    else:
        verdict, reason = "reject", (
            "turns too far from the camera; image-plane angles would be "
            "silently wrong rather than merely noisy")

    return AngleVerdict(verdict, round(median_yaw, 1), round(p90_yaw, 1),
                        round(z_median, 1), len(frames), reason)


# --------------------------------------------------------------------------
# Self-check with synthetic skeletons rotated about the vertical axis.
# --------------------------------------------------------------------------

def _frontal_skeleton(shoulder_w=0.16, hip_w=0.11, torso=0.22):
    lm = [[0.5, 0.5, 0.0, 1.0] for _ in range(33)]
    cx, sy, hy = 0.5, 0.40, 0.62
    lm[L_SHOULDER] = [cx + shoulder_w / 2, sy, 0.0, 1.0]
    lm[R_SHOULDER] = [cx - shoulder_w / 2, sy, 0.0, 1.0]
    lm[L_HIP] = [cx + hip_w / 2, hy, 0.0, 1.0]
    lm[R_HIP] = [cx - hip_w / 2, hy, 0.0, 1.0]
    return lm


def _yaw_skeleton(lm, deg: float):
    """Rotates about the vertical axis through the body centre."""
    t = math.radians(deg)
    cx = 0.5
    out = []
    for p in lm:
        dx = p[0] - cx
        out.append([cx + dx * math.cos(t), p[1], dx * math.sin(t), p[3]])
    return out


def _take(deg_series: list[float]):
    base = _frontal_skeleton()
    return [_yaw_skeleton(base, d) for d in deg_series]


def self_test() -> int:
    print("camera angle gate — measured behaviour\n")
    print(f"{'scenario':<44}{'median':>8}{'p90':>7}{'z':>7}{'verdict':>10}")
    failures = 0

    def run(label, degs, expect):
        nonlocal failures
        v = evaluate(_take(degs))
        print(f"{label:<44}{v.median_yaw_deg:>8.1f}{v.p90_yaw_deg:>7.1f}"
              f"{v.z_cross_check_deg:>7.1f}{v.verdict:>10}")
        if v.verdict != expect:
            print(f"    ! expected {expect}")
            failures += 1

    run("facing camera throughout", [0] * 40, "ok")
    run("small sway +/-8 deg", [8 * math.sin(i / 3) for i in range(40)], "ok")
    run("turns to 25 deg mid-take", [0] * 15 + [25] * 10 + [0] * 15, "oblique")
    run("turns to 50 deg mid-take", [0] * 15 + [50] * 10 + [0] * 15, "reject")
    run("filmed at 45 deg the WHOLE take", [45] * 40, "reject")
    run("filmed at 60 deg the WHOLE take", [60] * 40, "reject")
    run("too few frames", [0] * 3, "reject")

    print()
    if failures:
        print(f"SELF-TEST FAILED ({failures} assertion(s))")
        return 1
    print("SELF-TEST OK")
    print("\nThe constant-angle cases are the ones that matter: self-calibration "
          "alone reads them as fine, and only the depth cross-check catches them.")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--fixture", help="fixture JSON produced by extract_landmarks")
    args = ap.parse_args()

    if args.self_test:
        return self_test()
    if args.fixture:
        data = json.load(open(args.fixture, encoding="utf-8"))
        frames = [[[p.get("x", 0), p.get("y", 0), p.get("z", 0), p.get("vis", 1)]
                   for p in f["landmarks"]] for f in data["frames"]]
        print(evaluate(frames).to_json())
        return 0
    ap.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
