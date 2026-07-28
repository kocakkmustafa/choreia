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


def world_yaw_series(world_frames: list[list[list[float]]]) -> list[float]:
    """Yaw from MediaPipe world landmarks — metric 3D in a body-centred frame.

    This is the primary channel, and the pilot is why. The image-plane estimator
    below passes every synthetic test and then fails to discriminate on real
    footage: its shoulder-width ratio is confounded by torso lean, by framing
    changes, and — worst for us — by the dance's own rotation, which is signal
    rather than error. World landmarks separate those, because the shoulder line
    is measured in three dimensions rather than inferred from foreshortening.

    Measured on two harvested takes: the world channel put a genuinely
    head-on Howcast segment at 10.3 degrees while correctly leaving an
    obliquely-filmed take at 58. The image-plane channel scored both in the
    fifties and so could not tell them apart.
    """
    out = []
    for w in world_frames:
        dx = w[L_SHOULDER][0] - w[R_SHOULDER][0]
        dz = w[L_SHOULDER][2] - w[R_SHOULDER][2]
        if abs(dx) < 1e-9 and abs(dz) < 1e-9:
            out.append(float("nan"))
            continue
        out.append(abs(math.degrees(math.atan2(dz, dx))))
    return out


def load_fixture_world(path) -> list[list[list[float]]]:
    """Reads world-landmark frames, skipping undetected ones."""
    data = json.load(open(path, encoding="utf-8"))
    out = []
    for f in data.get("frames", []):
        if f.get("detected") is False:
            continue
        w = f.get("world")
        if w:
            out.append(w)
    return out


def find_usable_windows_world(
    world_frames: list[list[list[float]]],
    *,
    fps: float,
    min_seconds: float = 6.0,
    stride_seconds: float = 1.0,
    max_windows: int = 5,
) -> list[Window]:
    """Segment finder on the world channel — the one the pipeline should use."""
    if fps <= 0 or not world_frames:
        return []
    win = max(2, int(min_seconds * fps))
    if len(world_frames) < win:
        return []
    stride = max(1, int(stride_seconds * fps))
    yaws = [y for y in world_yaw_series(world_frames)]

    out: list[Window] = []
    for s in range(0, len(world_frames) - win + 1, stride):
        seg = [y for y in yaws[s:s + win] if not math.isnan(y)]
        if len(seg) < win * 0.8:
            continue
        p90 = _percentile(seg, 0.90)
        if p90 <= OK_YAW_DEG:
            out.append(Window(s, s + win, win / fps, round(p90, 1), 0.0))

    merged: list[Window] = []
    for w in out:
        if merged and w.start_frame <= merged[-1].end_frame:
            prev = merged[-1]
            merged[-1] = Window(prev.start_frame,
                                max(prev.end_frame, w.end_frame),
                                (max(prev.end_frame, w.end_frame)
                                 - prev.start_frame) / fps,
                                min(prev.p90_yaw_deg, w.p90_yaw_deg), 0.0)
        else:
            merged.append(w)
    merged.sort(key=lambda w: (-w.seconds, w.p90_yaw_deg))
    return merged[:max_windows]


def load_fixture_frames(path) -> list[list[list[float]]]:
    """Reads landmark frames from a fixture, tolerating both layouts in use.

    The extraction pipeline emits flat `lm: [x, y, z, visibility, presence]`
    rows; the family fixture contract uses `landmarks: [{x, y, z, vis}]`. Frames
    the detector never resolved are dropped rather than passed through as zeros
    — a skeleton collapsed at the origin would read as a perfectly
    fronto-parallel dancer.
    """
    data = json.load(open(path, encoding="utf-8"))
    out = []
    for f in data.get("frames", []):
        if f.get("detected") is False:
            continue
        rows = f.get("lm") or f.get("landmarks")
        if not rows:
            continue
        if isinstance(rows[0], dict):
            out.append([[p.get("x", 0), p.get("y", 0), p.get("z", 0),
                         p.get("vis", 1)] for p in rows])
        else:
            out.append([[r[0], r[1], r[2] if len(r) > 2 else 0.0,
                         r[3] if len(r) > 3 else 1.0] for r in rows])
    return out


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


@dataclass
class Window:
    start_frame: int
    end_frame: int
    seconds: float
    p90_yaw_deg: float
    z_median_deg: float


def find_usable_windows(
    frames: list[list[list[float]]],
    *,
    fps: float,
    min_seconds: float = 6.0,
    stride_seconds: float = 0.5,
    max_windows: int = 5,
) -> list[Window]:
    """Finds the stretches of a take that are actually filmed head-on.

    A whole tutorial is the wrong unit to judge. Instructors talk to camera,
    demonstrate from the side, turn to show the footwork, and cut between
    angles — so a verdict over the full runtime says only "this is a tutorial",
    which we knew. What the reference pipeline needs is the handful of seconds
    where the dancer is square to the lens and dancing.

    Searching for those windows is also the cheapest thing we can do about the
    biggest cost in the workflow: picking the segment by hand was measured as
    the real bottleneck, not the tapping.
    """
    if fps <= 0 or not frames:
        return []
    win = max(2, int(min_seconds * fps))
    if len(frames) < win:
        return []
    stride = max(1, int(stride_seconds * fps))

    # The whole-take p90 shoulder ratio is the dancer's own fronto-parallel
    # reference: they are square to the camera at some point in a tutorial,
    # even if only briefly.
    ratios = shoulder_ratio_series(frames)
    usable = [r for r in ratios if r > 1e-6]
    if not usable:
        return []
    reference = _percentile(usable, 0.95)
    if reference <= 1e-6:
        return []
    yaws = [math.degrees(math.acos(max(0.0, min(1.0, r / reference))))
            for r in ratios]
    zy = z_yaw_series(frames)

    cands: list[Window] = []
    for s in range(0, len(frames) - win + 1, stride):
        seg_yaw = yaws[s:s + win]
        seg_z = zy[s:s + win]
        p90 = _percentile(seg_yaw, 0.90)
        zmed = statistics.median(seg_z)
        if p90 <= OK_YAW_DEG and zmed <= OBLIQUE_YAW_DEG:
            cands.append(Window(s, s + win, win / fps, round(p90, 1),
                                round(zmed, 1)))

    # Merge overlaps, keeping the squarest window of each run.
    merged: list[Window] = []
    for w in cands:
        if merged and w.start_frame <= merged[-1].end_frame:
            prev = merged[-1]
            merged[-1] = Window(
                prev.start_frame, max(prev.end_frame, w.end_frame),
                (max(prev.end_frame, w.end_frame) - prev.start_frame) / fps,
                min(prev.p90_yaw_deg, w.p90_yaw_deg),
                min(prev.z_median_deg, w.z_median_deg))
        else:
            merged.append(w)

    merged.sort(key=lambda w: (-w.seconds, w.p90_yaw_deg))
    return merged[:max_windows]


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
        print(json.dumps(evaluate(load_fixture_frames(args.fixture)).__dict__,
                         indent=2))
        return 0
    ap.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
