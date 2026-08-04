#!/usr/bin/env python3
"""Finds the stretch of a tutorial where the step is actually being danced.

APPLICABILITY (M-F-31 — measure before adopting): the signal here is
periodicity, so this tool is for REPETITIVE content — dance steps, reps,
strike combinations. It is the wrong question for single-direction ROM
sweeps, one-off holds (plank, balance) and 3-rep assessment clips: Lissom
measured that on such material the high "periodicity" scores are low-lag
autocorrelation artifacts (adjacent frames always correlate), with the
reported period pinned to the search floor. For phase-defined tests the
movement window is the phase state machine's own output, not a pre-filter.

The harvest gates answer "is this footage usable" — framing, sharpness, camera
angle. None of them answer "is this part the movement", and that gap broke the
first real reference build (M-C-16): three takes that all passed the camera gate
still produced DTW costs of 0.06-0.18 and near-zero joint dispersion, because
most of each window was the instructor standing and talking. Consensus and
variance-derived tolerance cannot work on material that is mostly explanation.

The signal used here is periodicity. A dance step is, by definition, a movement
that repeats — an instructor demonstrating one repeats it several times, and
almost nothing else in a tutorial does.

The trap this has to avoid is that **standing still is perfectly periodic**: a
static pose correlates with itself at every lag. Periodicity alone would score
the talking sections highest of all. So a window qualifies only when it is both
repeating AND moving.

Self-check:  python3 tools/movement_isolator.py --self-test

VENDORED FILE — see drift_check() below.

This is a copy of motion-core's tools/harvest_rig/movement_isolator.py, not
a package import (build_reference.py's docstring explains why apps don't
import the family's Dart core directly; this Python rig tooling is copied
per-app the same way). A copy with no way to notice its source moving on is
exactly how the fps-fallback and per-frame-energy bugs (M-F-59, this file's
own git history) drifted silently for a full session before the coordinator
caught them. `--drift-check` is the standing answer: it distinguishes an
edit *I* made here from motion moving upstream that I have not looked at.

Drift-check:  python3 tools/movement_isolator.py --drift-check
"""

from __future__ import annotations

import argparse
import json
import math
import os
import statistics
import sys
from dataclasses import dataclass
from pathlib import Path

# --- vendoring pin -----------------------------------------------------
# Update PIN_SHA only after re-reading the upstream diff since the last pin
# and either porting the change or adding it to DECLARED_DIFFERENCES with a
# named, independent reason (family rule: exclusion is always named).
PIN_REPO_PATH = "tools/harvest_rig/movement_isolator.py"
PIN_SHA = "5054426"  # feat/isolator-kinematic-driver — MERGE BEKLİYOR (M-F-235)

DECLARED_DIFFERENCES = {
    "normalized_series": (
        "M-O-43's [ids] scoping param not ported — Choreia's harvest is "
        "always full-body dance footage (never a waist-up lesson), so the "
        "out-of-frame-landmark-noise problem that param solves has no "
        "current caller. Port it if a style ever needs partial-body "
        "scoping."),
    "_motion_energy": (
        "Docstring wording only (credit-trail differs: this file's own "
        "fix vs. rig's after-the-fact credit to it) — semantics identical, "
        "both per-second."),
    "load_frames": (
        "Comment/message wording only — both fail-closed on missing fps, "
        "no silent default either side."),
    "main": (
        "Adds the --drift-check CLI flag (local-only, see below) — "
        "upstream's own main() has no reason to check itself against "
        "itself."),
}

# Functions that exist ONLY in this copy, by design — the drift-check
# machinery itself. Distinct from DECLARED_DIFFERENCES (same name, changed
# body): these have no upstream counterpart at all, because checking a copy
# against its source is a copy-specific concern the source doesn't have.
LOCAL_ONLY_ADDITIONS = {"_find_motion_core_lib", "drift_check"}

L_SHOULDER, R_SHOULDER = 11, 12
L_HIP, R_HIP = 23, 24

# Joints that carry a dance step. Face and hand-detail landmarks are excluded:
# they are noisy and they move while the instructor talks, which is exactly the
# section we are trying to reject.
BODY = [11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28]


@dataclass
class MovementWindow:
    start_frame: int
    end_frame: int
    seconds: float
    periodicity: float
    motion_energy: float
    period_s: float

    def __str__(self) -> str:
        return (f"{self.start_frame}-{self.end_frame} ({self.seconds:.1f}s) "
                f"per={self.periodicity:.2f} enerji={self.motion_energy:.4f} "
                f"periyot={self.period_s:.2f}s")


def normalized_series(frames: list[list[list[float]]],
                      ids: list[int] | None = None) -> list[list[float]]:
    """Torso-relative body landmarks, flattened per frame.

    [ids] scopes WHICH landmarks enter the series (default: full BODY).
    M-O-43: measuring energy/drift over landmarks that are structurally out
    of frame (legs in a waist-up lesson) folds MediaPipe's guessed-position
    noise into the measurement — the scope must match what the downstream
    consumer actually requires.

    Same normalization idea as the engine: origin at the hip midpoint, scaled by
    torso length, so that a dancer stepping toward the camera does not read as
    movement.
    """
    out = []
    for lm in frames:
        hx = (lm[L_HIP][0] + lm[R_HIP][0]) / 2
        hy = (lm[L_HIP][1] + lm[R_HIP][1]) / 2
        sx = (lm[L_SHOULDER][0] + lm[R_SHOULDER][0]) / 2
        sy = (lm[L_SHOULDER][1] + lm[R_SHOULDER][1]) / 2
        torso = math.hypot(sx - hx, sy - hy)
        if torso < 1e-6:
            out.append(None)
            continue
        row = []
        for i in (ids if ids is not None else BODY):
            row.append((lm[i][0] - hx) / torso)
            row.append((lm[i][1] - hy) / torso)
        out.append(row)
    return out


def _motion_energy(seg: list[list[float]], fps: float) -> float:
    """Mean change PER SECOND — how much the body is actually moving.

    Per-second, not per-frame (doc 60 §1 / M-O-23, wf_dfb1dcd3 confirmed
    this as a frame-unit leak): per-frame deltas shrink as the frame rate
    grows, so the same real movement read half the "energy" at 60 fps and
    a fixed per-frame floor silently rejected it. The floor below is
    declared in per-second units; 0.30/s is the old 0.010/frame at the
    30 fps the number was tuned on — identical behavior there, correct
    behavior everywhere else.
    """
    if len(seg) < 2 or fps <= 0:
        return 0.0
    total = 0.0
    for a, b in zip(seg, seg[1:]):
        total += sum(abs(x - y) for x, y in zip(a, b)) / len(a)
    return (total / (len(seg) - 1)) * fps


def _periodicity(
    seg: list[list[float]], lo: int, hi: int, *, min_prominence: float = 0.08
) -> tuple[float, int]:
    """Periodicity as a *prominent local peak* of the autocorrelation.

    Centring is what stops a held pose from scoring 1.0: subtracting the window
    mean leaves a static segment with almost no signal to correlate, so its
    score collapses instead of saturating.

    M-C-25 (P0, measured on real harvest footage): taking the ACF's *global
    maximum* over the lag range is structurally wrong for real recordings.
    Continuous motion makes adjacent frames similar, so the ACF **decays
    monotonically** and its maximum sits at the smallest allowed lag on
    every non-repetitive segment — the reported "period" was the search
    floor, not a measurement (4/5 selected segments had no real peak at
    all). A true repetition instead produces a *local peak rising above the
    decaying envelope* (measured positive case: acf 0.588 at 1.20 s with its
    2.40 s harmonic alongside). So: only interior local maxima with at least
    [min_prominence] of rise over their neighbouring valleys count; a window
    whose ACF has no such peak is *moving but not repeating* and is rejected.
    Synthetic sinusoids cannot catch this defect — their ACF has a genuine
    peak AND a non-decaying envelope — which is how it survived self-tests.
    """
    n = len(seg)
    if n < hi + 2:
        return 0.0, 0
    dim = len(seg[0])
    means = [sum(f[d] for f in seg) / n for d in range(dim)]
    c = [[f[d] - means[d] for d in range(dim)] for f in seg]

    energy = sum(sum(v * v for v in f) for f in c)
    if energy < 1e-9:
        return 0.0, 0

    lags = list(range(lo, hi + 1))
    r: list[float] = []
    for lag in lags:
        num = 0.0
        for t in range(n - lag):
            num += sum(c[t][d] * c[t + lag][d] for d in range(dim))
        # Normalise by the energy of the overlapping span.
        e1 = sum(sum(v * v for v in c[t]) for t in range(n - lag))
        e2 = sum(sum(v * v for v in c[t + lag]) for t in range(n - lag))
        denom = math.sqrt(e1 * e2)
        r.append(num / denom if denom >= 1e-12 else 0.0)

    best, best_lag = 0.0, 0
    for k in range(1, len(r) - 1):
        if not (r[k] > r[k - 1] and r[k] >= r[k + 1]):
            continue  # not an interior local maximum
        # Walk down to the valley on each side; prominence is the rise above
        # the *higher* of the two valleys — a micro-bump on a decaying slope
        # has a shallow uphill side and fails this.
        j = k
        while j > 0 and r[j - 1] < r[j]:
            j -= 1
        left_valley = r[j]
        j = k
        while j < len(r) - 1 and r[j + 1] < r[j]:
            j += 1
        right_valley = r[j]
        prominence = r[k] - max(left_valley, right_valley)
        if prominence < min_prominence:
            continue
        if r[k] > best:
            best, best_lag = r[k], lags[k]
    return best, best_lag


def _amplitude(seg: list[list[float]]) -> float:
    """Robust per-dimension excursion (p95-p5), max across dimensions.

    p95-p5 rather than max-min: on real takes max-min measures the worst
    tracking glitch in the window, not the movement (a consumer measured
    a "3031 deg/s" knee once and it was one bad frame).
    """
    if len(seg) < 3:
        return 0.0
    dim = len(seg[0])
    best = 0.0
    for d in range(dim):
        col = sorted(f[d] for f in seg)
        lo_i = int(0.05 * (len(col) - 1))
        hi_i = int(0.95 * (len(col) - 1))
        best = max(best, col[hi_i] - col[lo_i])
    return best


def find_movement_windows(
    frames: list[list[list[float]]],
    *,
    fps: float,
    window_s: float = 6.0,
    stride_s: float = 1.0,
    min_period_s: float = 0.4,
    max_period_s: float = 4.0,
    min_periodicity: float = 0.5,
    min_energy_per_s: float = 0.30,
    max_windows: int = 5,
    driver_series: list[float] | None = None,
    min_amplitude: float = 0.0,
) -> list[MovementWindow]:
    """Windows that are both repeating and moving.

    KINEMATIC-DRIVER MODE (optional, off by default).

    By default the window search runs over `normalized_series` — whole-body,
    torso-relative motion. That is the right signal when the step's identity
    IS gross body movement, and it is what every existing caller gets.

    It is the WRONG signal when a step's defining event is a small excursion
    of one joint while the body stays put. A consumer measured this: on a
    896 s lesson containing 193 qualified events of the step being taught,
    whole-body windowing produced 5 candidate windows totalling ~34 s (3.8%
    of the video) and four of them contained none of those events. The
    energy pre-gate was rejecting the very thing being looked for, because
    whole-body energy is a PROXY for "is the step happening" and the proxy
    disagrees with the step.

    So the signal to window over becomes caller-supplied:

      driver_series   per-frame scalar the caller considers definitional
                      (NaN or None marks an unusable frame, exactly as a
                      missing torso does in the default path)
      min_amplitude   excursion floor IN THE DRIVER'S OWN UNITS

    The rig stays domain-blind: it never learns which joint, which step, or
    what the units mean. It windows over the signal it is handed. Callers
    source the driver and its floors from their own step configuration, so
    the vocabulary lives where the domain knowledge lives.

    Note the scalar is simply a one-dimensional vector series, so
    `_motion_energy` and `_periodicity` are reused UNCHANGED — no second
    implementation of either measure exists to drift from the first.

    Both new parameters default to no-ops, so the existing path is not
    merely "expected" to be unchanged, it is the same code with the same
    inputs.
    """
    if driver_series is None:
        series = normalized_series(frames)
    else:
        series = [None if (v is None or v != v) else [float(v)]
                  for v in driver_series]
    usable = [i for i, r in enumerate(series) if r is not None]
    if len(usable) < 10 or fps <= 0:
        return []

    win = max(4, int(window_s * fps))
    stride = max(1, int(stride_s * fps))
    lo = max(1, int(min_period_s * fps))

    # A lag may not exceed a third of the window. At larger lags the two
    # compared spans barely overlap, so the normalized correlation is computed
    # from very little data and inflates — the first run on real takes reported
    # "periods" of 4-8 s for a step that repeats about once a second, which was
    # this artefact rather than a finding. Requiring three repetitions inside
    # the window also matches what a demonstration actually looks like.
    hi = min(int(max_period_s * fps), win // 3)
    if hi <= lo:
        return []

    cands: list[MovementWindow] = []
    for s in range(0, len(series) - win + 1, stride):
        seg = [r for r in series[s:s + win] if r is not None]
        if len(seg) < win * 0.8:
            continue
        energy = _motion_energy(seg, fps)
        if energy < min_energy_per_s:
            continue                      # standing still — reject before the
                                          # autocorrelation can flatter it
        # Excursion floor in the driver's own units. A no-op at the default
        # 0.0, so this cannot change any existing caller. It exists because a
        # caller windowing over a joint angle has a floor that means something
        # concrete ("below this the person is standing still") while the
        # whole-body energy floor above is in torso-relative units that say
        # nothing about that joint.
        if min_amplitude > 0.0 and _amplitude(seg) < min_amplitude:
            continue
        per, lag = _periodicity(seg, lo, min(hi, len(seg) - 2))
        if per < min_periodicity:
            continue
        cands.append(MovementWindow(s, s + win, win / fps, round(per, 3),
                                    round(energy, 4), round(lag / fps, 2)))

    merged: list[MovementWindow] = []
    for w in cands:
        if merged and w.start_frame <= merged[-1].end_frame:
            p = merged[-1]
            merged[-1] = MovementWindow(
                p.start_frame, max(p.end_frame, w.end_frame),
                (max(p.end_frame, w.end_frame) - p.start_frame) / fps,
                max(p.periodicity, w.periodicity),
                max(p.motion_energy, w.motion_energy),
                p.period_s if p.periodicity >= w.periodicity else w.period_s)
        else:
            merged.append(w)

    merged.sort(key=lambda w: (-w.periodicity, -w.seconds))
    return merged[:max_windows]


def load_frames(path: str) -> tuple[list[list[list[float]]], float]:
    d = json.load(open(path, encoding="utf-8"))
    # Fail-closed, never a silent 30 (M-F-59 class; Choreia found the same
    # leak in its copy and fixed it first — ff4f665): a wrong fps corrupts
    # every per-second number downstream while looking plausible.
    fps = d.get("recordingMeta", {}).get("fps")
    if not fps:
        raise SystemExit(f"fps yok: {path} — recordingMeta.fps zorunlu "
                         "(sessiz 30 varsayımı yasak, doc 60 §1)")
    out = []
    for f in d.get("frames", []):
        if f.get("detected") is False:
            continue
        lm = f.get("lm")
        if lm:
            out.append(lm)
    return out, float(fps)


# --------------------------------------------------------------------------

def _synth(n: int, *, period: int, amp: float, seed: int = 1):
    """Fake landmark frames: a limb swinging with a given period."""
    rng = __import__("random").Random(seed)
    frames = []
    for t in range(n):
        ph = 2 * math.pi * t / period if period else 0
        lm = [[0.5, 0.5, 0.0, 1.0] for _ in range(33)]
        lm[L_HIP] = [0.45, 0.60, 0, 1]
        lm[R_HIP] = [0.55, 0.60, 0, 1]
        lm[L_SHOULDER] = [0.42, 0.38, 0, 1]
        lm[R_SHOULDER] = [0.58, 0.38, 0, 1]
        for i in BODY:
            if i in (L_HIP, R_HIP, L_SHOULDER, R_SHOULDER):
                continue
            j = rng.gauss(0, 0.002)
            lm[i] = [0.5 + amp * math.sin(ph) + j, 0.5 + amp * math.cos(ph) + j,
                     0, 1]
        frames.append(lm)
    return frames


def self_test() -> int:
    print("movement isolator — measured behaviour\n")
    print(f"{'scenario':<40}{'windows':>8}{'per':>7}{'energy':>9}")
    fails = 0

    def run(label, frames, expect_found):
        nonlocal fails
        ws = find_movement_windows(frames, fps=30, window_s=4.0)
        top = ws[0] if ws else None
        print(f"{label:<40}{len(ws):>8}"
              f"{(top.periodicity if top else 0):>7.2f}"
              f"{(top.motion_energy if top else 0):>9.4f}")
        if bool(ws) != expect_found:
            print(f"    ! expected {'a window' if expect_found else 'none'}")
            fails += 1

    run("repeating step (1.0s period)", _synth(300, period=30, amp=0.10), True)
    run("repeating step (0.6s period)", _synth(300, period=18, amp=0.08), True)
    # The trap: a held pose is perfectly self-similar at every lag.
    run("standing still (the trap)", _synth(300, period=0, amp=0.0), False)
    run("tiny idle sway", _synth(300, period=30, amp=0.004), False)
    run("moving but not repeating", _synth(300, period=400, amp=0.10), False)

    # M-C-25 class in its purest form: continuous, energetic, NEVER repeating.
    # Its ACF decays monotonically — under the old global-max rule this scored
    # "periodic" at the search floor on every real tutorial's talking segments.
    rng = __import__("random").Random(7)
    walk = []
    wx, wy = 0.5, 0.5
    for _t in range(300):
        wx += rng.gauss(0, 0.004)
        wy += rng.gauss(0, 0.004)
        lm = [[0.5, 0.5, 0.0, 1.0] for _ in range(33)]
        lm[L_HIP] = [0.45, 0.60, 0, 1]
        lm[R_HIP] = [0.55, 0.60, 0, 1]
        lm[L_SHOULDER] = [0.42, 0.38, 0, 1]
        lm[R_SHOULDER] = [0.58, 0.38, 0, 1]
        for i in BODY:
            if i in (L_HIP, R_HIP, L_SHOULDER, R_SHOULDER):
                continue
            lm[i] = [wx, wy, 0, 1]
        walk.append(lm)
    run("random walk (M-C-25 class)", walk, False)

    # ---- KINEMATIC-DRIVER MODE ------------------------------------------
    # The driver is a caller-supplied scalar, so these cases feed it directly
    # and hand in body frames that carry NO movement at all. That separation
    # is the point: if the driver path were quietly still reading the body,
    # the oscillating case below would find nothing.
    print()
    print(f"{'driver-mode scenario':<40}{'windows':>8}{'per':>7}{'energy':>9}")
    n = 30 * 40
    inert = [[[0.0, 0.0, 0.0]] * 33 for _ in range(n)]

    def run_driver(label, driver, expect_found, min_amplitude=10.0):
        nonlocal fails
        ws = find_movement_windows(inert, fps=30, window_s=4.0,
                                   driver_series=driver, min_energy_per_s=0.0,
                                   min_amplitude=min_amplitude)
        top = ws[0] if ws else None
        print(f"{label:<40}{len(ws):>8}"
              f"{(top.periodicity if top else 0):>7.2f}"
              f"{(top.motion_energy if top else 0):>9.4f}")
        if bool(ws) != expect_found:
            print(f"    ! expected {'a window' if expect_found else 'none'}")
            fails += 1

    osc = [172.0 - 20.0 * (0.5 - 0.5 * math.cos(2 * math.pi * i / 30.0))
           for i in range(n)]
    run_driver("driver: 1 s oscillation, 20 deg", osc, True)
    run_driver("driver: held still", [172.0] * n, False)
    run_driver("driver: untracked (NaN)", [float("nan")] * n, False)
    # Amplitude floor is the caller's, in the caller's units: the SAME signal
    # must be rejected once the floor is raised above its excursion. Without
    # this the floor could be ignored entirely and every row above still pass.
    run_driver("driver: 20 deg swing under a 40 deg floor", osc, False,
               min_amplitude=40.0)
    # Body frames are inert throughout, so a window here can only have come
    # from the driver — this is what proves the driver is actually being read.

    print()
    if fails:
        print(f"SELF-TEST FAILED ({fails})")
        return 1
    print("SELF-TEST OK")
    print("\nThe 'standing still' row is the one that matters: periodicity "
          "alone would rank it top, and requiring motion is what rejects it.")
    return 0


def _find_motion_core_lib():
    candidate = Path(__file__).resolve().parents[3] / "motion-core" / "lib"
    return candidate if (candidate / ".git").exists() else None


def drift_check() -> int:
    """Has this vendored copy silently diverged from its upstream source?

    Two separate questions, because conflating them is how the last drift
    hid: (1) does every function this file did NOT declare as different
    still match upstream at the pinned commit, structurally (ast-compared,
    so comment/whitespace churn cannot mask a real change, and cannot
    manufacture a false failure either)? (2) has upstream moved past the
    pin at all? This file can answer (1) on its own; it cannot answer
    whether motion in (2) needs porting — only a human/agent reading the
    new commits can — so it reports the gap and stops.
    """
    import ast
    import subprocess

    lib = _find_motion_core_lib()
    if lib is None:
        print("SKIP: motion-core/lib not checked out as a sibling repo — "
              "nothing to compare this vendored copy against.")
        return 0

    try:
        pinned_src = subprocess.run(
            ["git", "-C", str(lib), "show", f"{PIN_SHA}:{PIN_REPO_PATH}"],
            capture_output=True, text=True, check=True).stdout
    except subprocess.CalledProcessError as e:
        print(f"FAIL: could not read {PIN_REPO_PATH} at {PIN_SHA} from "
              f"{lib}: {e.stderr.strip()}")
        return 1

    def top_level_funcs(src: str) -> dict:
        tree = ast.parse(src)
        return {n.name: n for n in tree.body
                if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))}

    pinned_funcs = top_level_funcs(pinned_src)
    local_funcs = top_level_funcs(Path(__file__).read_text(encoding="utf-8"))

    ok = True
    for name, node in local_funcs.items():
        if name in DECLARED_DIFFERENCES:
            print(f"  ~ {name}: declared different — "
                  f"{DECLARED_DIFFERENCES[name]}")
            continue
        if name in LOCAL_ONLY_ADDITIONS:
            if name in pinned_funcs:
                print(f"  ✗ {name}: declared local-only, but upstream now "
                      "has it too — check for a name collision/real merge")
                ok = False
            continue
        if name not in pinned_funcs:
            print(f"  + {name}: local-only (not in pinned upstream) — "
                  "undeclared, name it above or this is unreviewed drift")
            ok = False
            continue
        if ast.dump(node) != ast.dump(pinned_funcs[name]):
            print(f"  ✗ {name}: UNDECLARED DRIFT from pinned upstream")
            ok = False
    for name in sorted(set(pinned_funcs) - set(local_funcs)):
        print(f"  ✗ {name}: in pinned upstream, missing here entirely — "
              "new upstream function never ported or declared")
        ok = False

    print(("✓" if ok else "✗") +
          f" vendored copy matches pin {PIN_SHA} + declared differences")

    try:
        behind = subprocess.run(
            ["git", "-C", str(lib), "rev-list", "--count",
             f"{PIN_SHA}..origin/main"],
            capture_output=True, text=True, check=True).stdout.strip()
        head = subprocess.run(
            ["git", "-C", str(lib), "rev-parse", "--short", "origin/main"],
            capture_output=True, text=True, check=True).stdout.strip()
    except subprocess.CalledProcessError:
        behind, head = None, None
    # IS THE PIN EVEN ON MAIN? `rev-list --count PIN..origin/main` is 0 both
    # when the pin IS main and when the pin is a branch commit AHEAD of main —
    # and the second case was being printed as "current with origin/main",
    # which is the opposite of true. That is precisely the case this check was
    # added for (C-114 pinned to an unmerged branch and recorded that the
    # drift check would say so loudly; measured today, it did not). Ancestry
    # has to be asked directly.
    try:
        merged = subprocess.run(
            ["git", "-C", str(lib), "merge-base", "--is-ancestor",
             PIN_SHA, "origin/main"],
            capture_output=True, text=True).returncode == 0
    except Exception:                                    # noqa: BLE001
        merged = True                                    # bilinmiyorsa sessiz
                                                         # geçme, aşağıda söyle
    if not merged:
        print(f"⚠ pin {PIN_SHA} is NOT an ancestor of origin/main ({head}) — "
              "this file is vendored from an UNMERGED branch. That is allowed "
              "while the branch is in review, but it must be re-pinned to the "
              "merge commit once it lands, or this copy silently outlives the "
              "branch it came from.")
    elif behind and behind != "0":
        print(f"⚠ pin {PIN_SHA} is {behind} commit(s) behind origin/main "
              f"({head}) — re-diff PIN_REPO_PATH before trusting this file "
              "matches current rig behavior")
    elif behind == "0":
        print(f"✓ pin is current with origin/main ({head})")

    return 0 if ok else 1


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--drift-check", action="store_true")
    ap.add_argument("--fixture")
    args = ap.parse_args()
    if args.self_test:
        return self_test()
    if args.drift_check:
        return drift_check()
    if args.fixture:
        frames, fps = load_frames(os.path.expanduser(args.fixture))
        for w in find_movement_windows(frames, fps=fps):
            print(w)
        return 0
    ap.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
