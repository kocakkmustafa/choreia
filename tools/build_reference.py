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
import itertools
import json
import math
import statistics
import sys
from pathlib import Path

ORIENTATION_JOINTS = frozenset({
    "left_upper_arm", "right_upper_arm", "left_forearm", "right_forearm",
    "left_thigh", "right_thigh", "left_shin", "right_shin", "trunk_tilt",
})

PHASE_BINS = 64

# Independent instructors required before a reference may be built (M-C-04).
# Two teachers cannot produce a variance estimate that means anything: any
# disagreement is a coin flip between them, with no majority to locate.
MIN_TAKES = 3

# Below this a take's own median is computed from very few repetitions and is
# reported as thin rather than silently weighted like any other source.
MIN_CYCLES_PER_TAKE = 5

# Tolerance floor in degrees. Landmark jitter alone is worth a few degrees, so
# a phase where teachers happen to agree closely must not produce a band so
# tight that correct dancing scores as error.
MIN_TOLERANCE_DEG = 6.0
TOLERANCE_K = 1.5  # band = K * dispersion, floored

# Above this measured teacher dispersion a joint is coached but not scored
# (family rule M-F-41). The number is deliberately a MEASUREMENT threshold and
# not an anatomical judgement: JabLab refuted its own "legs are scored, arms
# are coached" shorthand when it measured a lead hip disagreeing at 27.2 deg
# while a rear shoulder agreed at 13.3.
#
# Choreia adds one refinement that a punch does not need. A dance cycle passes
# through phases, and the same joint can be tight in some and wild in others:
# the Running Man knees sit at the 6 deg floor for most of the cycle and blow
# out to 94 deg at the two kick instants. Scoring that knee "because its median
# is low" would mark correct dancing wrong at exactly the moment the step is
# hardest. So the decision is taken per (joint, PHASE), and each joint reports
# what fraction of the cycle it can honestly be scored over.
SCORED_MAX_DISPERSION_DEG = 14.0


# Orientation angles live on a circle: -179 and +179 are two degrees apart, not
# 358. Treating them linearly produced thigh tolerances of 250-330 degrees,
# which is not a wide band but a meaningless one — the median and the spread
# were both computed across a seam. Flexion angles never approach the seam and
# are left on the ordinary number line.
def ang_diff(a: float, b: float) -> float:
    """Shortest signed difference a-b, in (-180, 180]."""
    return (a - b + 180.0) % 360.0 - 180.0


def circ_mean(vals: list[float]) -> float:
    if not vals:
        return float("nan")
    sx = sum(math.cos(math.radians(v)) for v in vals)
    sy = sum(math.sin(math.radians(v)) for v in vals)
    return math.degrees(math.atan2(sy, sx))


def circ_center(vals: list[float]) -> float:
    """Circular median: the sample minimising total circular deviation.

    The circular MEAN is pulled by outliers the same way a linear one is, and
    three or four teachers is exactly the regime where that matters, so the
    centre is a sample rather than an average — with the mean as the seed for
    tie-breaking on tiny samples.
    """
    if not vals:
        return float("nan")
    if len(vals) <= 2:
        return circ_mean(vals)
    return min(vals, key=lambda c: sum(abs(ang_diff(v, c)) for v in vals))


def center_of(vals: list[float], circular: bool) -> float:
    return circ_center(vals) if circular else statistics.median(vals)


def spread_of(vals: list[float], circular: bool) -> float:
    """Mean absolute deviation about the centre (see `dispersion`)."""
    if len(vals) < 2:
        return 0.0
    c = center_of(vals, circular)
    devs = [abs(ang_diff(v, c)) if circular else abs(v - c) for v in vals]
    return 1.2533 * sum(devs) / len(devs)


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
        circ = name in ORIENTATION_JOINTS
        out[name] = [center_of([c[b] for c in stack], circ) for b in range(bins)]
    return out


# --------------------------------------------------------------------------
# mirror resolution + consensus
# --------------------------------------------------------------------------

# Signed quantities — where a limb POINTS, and how the trunk leans. Mirroring
# these is not just a rename: a thigh pointing 30 degrees to the left becomes a
# thigh pointing 30 degrees to the right, so the value is negated as well.
# Flexion angles are unsigned and must NOT be touched. Getting this wrong would
# not raise anything; it would quietly make every mirrored take disagree with
# its own reflection and inflate the tolerance that is derived from that
# disagreement.


def mirrored(cycle: dict[str, list[float]]) -> dict[str, list[float]]:
    out: dict[str, list[float]] = {}
    for k, v in cycle.items():
        out[mirror_joint(k)] = [-x for x in v] if k in ORIENTATION_JOINTS else v
    return out


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
        circ = j in ORIENTATION_JOINTS
        for x, y in zip(a[j], b[j]):
            total += abs(ang_diff(x, y)) if circ else abs(x - y)
            count += 1
    return total / count if count else float("inf")


# Up to this many takes, orientation is solved exactly instead of greedily.
# 4 variants per take with the first pinned: 4^(n-1) assignments, 16384 at n=8.
MAX_EXHAUSTIVE_TAKES = 8

VARIANTS = [(False, False), (True, False), (False, True), (True, True)]


def _variant(c: dict[str, list[float]], flip: bool, half: bool):
    out = mirrored(c) if flip else c
    return rotate_half(out) if half else out


def orient_exhaustive(cycles: list[dict[str, list[float]]]
                      ) -> tuple[list[dict], list[dict]]:
    """Choose every take's orientation at once, minimising total disagreement.

    The greedy version this replaced decided each take against the consensus of
    the takes already placed, which makes the answer depend on list order. On
    near-ties — and dance steps are full of them, since an alternating step is
    close to its own mirror shifted half a cycle — a coin-flip early on changes
    the running consensus and the error compounds. Measured: re-seeding with a
    different take changed the relative orientation of 3 of 6 pairs on Roger
    Rabbit and 4 of 6 on Running Man. A consensus that depends on which file
    was listed first is not a consensus.

    Orientation is really a global assignment, so it is solved as one: try
    every combination and keep the one with the least total pairwise distance.
    Take 0 is pinned to identity because the whole set can be mirrored or
    rotated together without changing anything — that symmetry has to be broken
    or every solution appears four times over.
    """
    n = len(cycles)
    best_cost, best_assign = None, None
    for combo in itertools.product(range(len(VARIANTS)), repeat=n - 1):
        assign = (0,) + combo
        variants = [_variant(cycles[i], *VARIANTS[a]) for i, a in enumerate(assign)]
        cost = sum(distance(variants[i], variants[j])
                   for i in range(n) for j in range(i + 1, n))
        if best_cost is None or cost < best_cost:
            best_cost, best_assign = cost, assign

    oriented = [_variant(cycles[i], *VARIANTS[a])
                for i, a in enumerate(best_assign)]

    # Absolute convention: keep the majority's handedness and flip the minority
    # (motion_core v0.5.0). Pinning take 0 breaks the global symmetry but leaves
    # the surviving orientation at the mercy of whichever file was listed first,
    # so a set where three teachers face the camera and one mirrors could end up
    # with all three flipped. Nothing downstream breaks, but every artifact
    # would then be described the minority's way round.
    best_assign, oriented = _apply_majority_convention(best_assign, oriented)

    # Provisional bands from the chosen assignment, used only to judge whether
    # a rival orientation could move a cell out of its band.
    merged0 = merge(oriented)
    tolerance_hint = {j: [max(MIN_TOLERANCE_DEG,
                              TOLERANCE_K * spread_of([c[j][b] for c in oriented
                                                       if j in c],
                                                      j in ORIENTATION_JOINTS))
                          for b in range(len(merged0[j]))] for j in merged0}
    log = []
    for i, a in enumerate(best_assign):
        others = [o for j, o in enumerate(oriented) if j != i]
        rest = merge(others) if others else None
        flip, half = VARIANTS[a]
        entry = {"index": i, "flipped": flip, "halfCycle": half,
                 "method": "exhaustive"}
        if rest:
            entry.update(_margin_vs_distinct_rival(cycles[i], oriented[i], rest, others))
        log.append(entry)
    return oriented, log


def _apply_majority_convention(assign, oriented):
    """Flip the whole set if that leaves fewer takes described as mirrored.

    Mirroring every take together is a symmetry of the problem — the relative
    arrangement is untouched — so this only changes how the result is
    described, never what it says.
    """
    flipped = sum(1 for a in assign if VARIANTS[a][0])
    if flipped * 2 <= len(assign):
        return assign, oriented
    swapped = [VARIANTS.index((not f, h)) for f, h in (VARIANTS[a] for a in assign)]
    return swapped, [mirrored(o) for o in oriented]


# A close call only matters if the rival would give a DIFFERENT reference
# (motion_core v0.5.0 semantics). The test for that is not whether the two
# candidate cycles look alike — an earlier version compared them directly and
# never fired — but whether swapping to the rival moves the consensus the takes
# actually produce. Measured on Roger Rabbit: forcing its tightest call to the
# runner-up shifted the consensus by 0.0 degrees, so the "uncertainty" changed
# nothing that is consumed downstream.
#
# The distinction is worth keeping straight. Degenerate means the answer does
# not matter. Uncertain means it matters and is not settled.
# Threshold ordering (audit prompted by Gravita's P0): a counting gate is the
# generous outer bound, a quality line sits inside it. This one was inverted.
#
# The question "does this orientation choice matter" was asked at 0.5 degrees
# while MIN_TOLERANCE_DEG says 6 degrees is the smallest angle worth a verdict.
# A consensus that moves 3 degrees was therefore called "matters" even though
# it cannot change any judgement the reference is capable of making. The test
# has to use the same floor the rest of the pipeline uses.
# Fraction of (joint, phase) cells whose value would leave its own tolerance
# band if this take were flipped. At or below this the orientation cannot
# change a verdict, whatever the raw degrees look like.
CELLS_BEYOND_TOLERANCE = 0.01
MIRROR_MARGIN = 0.03


def _margin_vs_distinct_rival(raw, placed, rest, others, tolerance=None) -> dict:
    best = distance(placed, rest)
    rivals = sorted(
        ((distance(_variant(raw, *v), rest), v) for v in VARIANTS
         if distance(_variant(raw, *v), placed) > 1e-9),
        key=lambda t: t[0])
    if not rivals:
        return {"bestDeg": round(best, 3), "runnerUpDeg": None, "margin": None,
                "confident": True, "orientationEffect": "degenerate",
                "note": "her varyant aynı çevrimi veriyor"}

    rival_cost, rival_v = rivals[0]
    with_placed = merge(others + [placed])
    with_rival = merge(others + [_variant(raw, *rival_v)])
    # "Does the choice matter" is asked cell by cell, against each cell's own
    # band. A single max in degrees is the wrong statistic once orientation
    # angles are in the pool: one joint swinging at one phase captures the whole
    # measure (it read 104-172 degrees on takes whose flexion barely moved). The
    # only shift that can change a judgement is one that leaves the tolerance
    # the reference itself publishes.
    cells = shifted = 0
    for j in with_placed:
        band = tolerance.get(j) if tolerance else None
        for b, (x, y) in enumerate(zip(with_placed[j], with_rival[j])):
            d = abs(ang_diff(x, y)) if j in ORIENTATION_JOINTS else abs(x - y)
            cells += 1
            if d > (band[b] if band else MIN_TOLERANCE_DEG):
                shifted += 1
    moved = shifted / cells if cells else 0.0

    out = {"bestDeg": round(best, 3), "runnerUpDeg": round(rival_cost, 3),
           "margin": round((rival_cost - best) / max(rival_cost, 1e-9), 4),
           "cellsBeyondTolerance": round(moved, 4)}

    if moved <= CELLS_BEYOND_TOLERANCE:
        # The rival is a different cycle but produces the same reference, so
        # the orientation of this take simply does not reach the output.
        out["confident"] = True
        out["orientationEffect"] = "degenerate"
        out["note"] = ("rakip farklı ama uzlaşmayı oynatmıyor — bu take'in yönü "
                       "çıktıya ULAŞMIYOR, belirsizlik değil")
    elif out["margin"] < 0:
        # The global optimum placed this take against its own local preference
        # to lower the total. Real tension, and different from a coin flip.
        out["confident"] = False
        out["orientationEffect"] = "against_local_optimum"
        out["note"] = ("global çözüm bu take'i KENDİ tercihinin tersine "
                       "yerleştirdi (toplam maliyet için) — gerilim var")
    else:
        out["confident"] = out["margin"] >= MIRROR_MARGIN
        out["orientationEffect"] = "decisive" if out["confident"] else "uncertain"
    return out


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
    if len(cycles) <= MAX_EXHAUSTIVE_TAKES:
        return orient_exhaustive(cycles)
    oriented = [cycles[0]]
    log = [{"index": 0, "flipped": False, "halfCycle": False,
            "margin": None, "seed": True, "greedy": True}]
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
        circ = j in ORIENTATION_JOINTS
        out[j] = [center_of([c[b] for c in cols], circ) for b in range(bins)]
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
    return spread_of(vals, joint in ORIENTATION_JOINTS)


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
    # Anchor-source homogeneity. Phase 0 means "left ankle furthest forward"
    # for an ankle-anchored take and "left knee highest" for a knee-anchored
    # one; those are different instants, so merging them merges two phase
    # definitions. Takes re-anchored on the knees are therefore set aside and
    # NAMED — not because they disagreed (excluding inconvenient sources is the
    # failure M-F-47 exists to prevent) but because an independent measurement
    # of the footage says its feet were never tracked: ankle visibility 0.007
    # on the take that triggered this. For a footwork style, footage whose feet
    # cannot be seen is not evidence about footwork.
    # Source suitability, fail-closed (family M-F-43/45, Choreia vocabulary in
    # classify_source.py). A performance clip can repeat a phrase and satisfy
    # every movement, camera and anchor test downstream while encoding styling
    # rather than instruction — no measurement in this pipeline can see the
    # difference, which is why the question is asked of what the instructor
    # SAYS. It caught one: a Roger Rabbit source with nine spoken words in the
    # whole clip. Nobody teaches in nine words.
    from classify_source import classify  # noqa: PLC0415
    all_usable = []
    not_lessons = []
    for p in prepared:
        if not p.get("usable"):
            continue
        c = classify(p["videoId"])
        p["_source"] = c
        (all_usable if c["verdict"] == "lesson" else not_lessons).append(p)
    excluded = [p for p in all_usable
                if (p.get("anchor") or {}).get("anchorSource") == "knee"]
    excluded_source = [
        {"videoId": p["videoId"], "verdict": p["_source"]["verdict"],
         "spokenWords": p["_source"].get("spokenWords"),
         "why": p["_source"].get("why")} for p in not_lessons]
    usable = [p for p in all_usable if p not in excluded]
    cycles, sources = [], []
    for p in usable:
        c = take_canonical_cycle(p, bins)
        if c is not None:
            cycles.append(c)
            sources.append(p)

    # Harmonic agreement. A phase axis only means the same thing across takes
    # if every take was cut on the SAME cycle. An alternating step is nearly
    # periodic at half its cycle, so one take can lock to the 4-count while
    # another locks to the 8 — and merging them silently averages two different
    # things. Salsa surfaced this directly: periods of 0.68 and 1.36 seconds in
    # the same pool. This is C-032's factor-of-two trap reaching the reference
    # itself, not just the BPM report.
    periods = sorted(p.get("periodSeconds") or 0 for p in sources)
    harmonic_conflict = []
    for i in range(len(periods)):
        for j in range(i + 1, len(periods)):
            if periods[i] > 0 and 1.7 <= periods[j] / periods[i] <= 2.3:
                harmonic_conflict.append([periods[i], periods[j]])
    if harmonic_conflict:
        return {
            "step": step, "built": False,
            "why": ("harmonik çelişki — take'ler AYNI çevrimde kesilmemiş "
                    f"(periyot çiftleri ~2x: {harmonic_conflict}); faz ekseni "
                    "take'ler arasında aynı şeyi anlatmıyor"),
            "periodsSeconds": periods,
            "usableTakes": [p["videoId"] for p in sources],
            "remedy": ("measure_tempo ile her take'in dönüşümlü olup olmadığını "
                       "belirle; yarım çevrime kilitlenenleri havuzdan çıkar "
                       "veya tam çevrime taşı"),
        }

    if len(cycles) < MIN_TAKES:
        return {
            "step": step, "built": False,
            "excludedNotLesson": excluded_source,
            "excludedAnchorSource": [
                {"videoId": p["videoId"],
                 "ankleVisibility": (p.get("anchor") or {}).get("ankleVisibility"),
                 "why": "ayak bileği izlenemedi; dizden çapalandı — faz tanımı farklı"}
                for p in excluded],
            "why": f"{len(cycles)} kullanılabilir take — >={MIN_TAKES} gerekli (M-C-04)",
            "usableTakes": [p["videoId"] for p in sources],
        }

    oriented, mirror_log = orient(cycles)
    for entry in mirror_log:
        entry["videoId"] = sources[entry["index"]]["videoId"]
    consensus = merge(oriented)

    joints = sorted(consensus)
    tolerance, tolerance_source = {}, {}
    for j in joints:
        band, src = [], []
        for b in range(bins):
            derived = TOLERANCE_K * dispersion(oriented, j, b)
            band.append(round(max(MIN_TOLERANCE_DEG, derived), 2))
            # Where the floor wins, the band is OUR caution, not the teachers'
            # agreement — they agreed more tightly than landmark noise can be
            # trusted to resolve. A consumer reading 6.0 degrees needs to know
            # which of the two it is looking at (family standard, G-050).
            src.append("floor" if derived <= MIN_TOLERANCE_DEG else "variance")
        tolerance[j] = band
        tolerance_source[j] = src

    disagreement = [d for d in (classify_disagreement(oriented, consensus, j, bins)
                                for j in joints) if d]

    scoring = {}
    for j in joints:
        disp = [dispersion(oriented, j, b) for b in range(bins)]
        mask = [d <= SCORED_MAX_DISPERSION_DEG for d in disp]
        cov = sum(mask) / bins
        scoring[j] = {
            "scoredPhases": mask,
            # Stored unrounded: it is a derived quantity, and rounding it makes
            # the artifact disagree with its own mask by half a bin (0.3125
            # stored as 0.312 failed the conformance check). A number a gate
            # reports must be the number the gate measured.
            "coverage": cov,
            "medianDispersionDeg": round(statistics.median(disp), 2),
            "verdict": ("scored" if cov >= 0.9 else
                        "scored_partial" if cov >= 0.4 else "coached_only"),
        }

    # The invariant that keeps a coach's own variation from being billed to the
    # learner: nowhere may the free band sit below the disagreement actually
    # measured between instructors. Checked here rather than trusted, because
    # any future change to the floor or the multiplier could quietly break it.
    violations = [
        {"joint": j, "phase": round(b / bins, 3),
         "toleranceDeg": tolerance[j][b],
         "dispersionDeg": round(dispersion(oriented, j, b), 2)}
        for j in joints for b in range(bins)
        if tolerance[j][b] + 1e-9 < dispersion(oriented, j, b)
    ]

    # Everything below this line was, until now, patched into the artifact by
    # hand after the fact in three separate sessions (hh_running_man,
    # hh_roger_rabbit, salsa_shines) — the same computation typed fresh each
    # time from numbers already sitting in this function. That is exactly the
    # "beşinci soru" failure mode applied to the tool itself: a value nobody
    # captured as code decays into something a human has to remember to
    # reproduce correctly. It is folded in here so the next rebuild of any
    # step gets it for free.
    mirror_confident = all(m["confident"] for m in mirror_log)
    thin_takes = [p["videoId"] for p in sources
                  if (p.get("cyclesInSegment") or 0) < MIN_CYCLES_PER_TAKE]
    # toleranceSource is "floor" for a phase where the measured floor
    # (MIN_TOLERANCE_DEG) exceeds instructor disagreement — i.e. our own
    # caution, not their agreement. The percentage tells a reader how much of
    # a joint's band is that caution rather than measured variance.
    floor_pct = {j: round(100 * sum(1 for s in tolerance_source[j] if s == "floor")
                           / bins) for j in joints}
    evidence_thickness = {
        "cyclesPerTake": [p.get("cyclesInSegment") for p in sources],
        "thinTakes": thin_takes,
        "toleranceSourceFloorPct": floor_pct,
    }
    source_suitability = {
        "rule": "yalnız DERS-GOSTERIMI kaynaklari referansa girer (fail-closed)",
        "excludedNotLesson": excluded_source,
        "why": ("performans klibi tekrar eden bir cumleyle her hareket/kamera/"
                "capa testini gecer ama ogretim degildir; hukum eğitmenin "
                "SÖZLERİNDEN gelir (classify_source.py)"),
    }
    status, provisional_reason = None, None
    if not mirror_confident:
        uncertain_pct = [round(100 * m["cellsBeyondTolerance"])
                          for m in mirror_log if not m["confident"]]
        status = "provisional"
        provisional_reason = (
            f"Yon BELIRSIZ; bir take cevrilirse hucrelerin "
            f"%{min(uncertain_pct)}-{max(uncertain_pct)}'si bandini asar. "
            f"Take basina cevrim: {evidence_thickness['cyclesPerTake']}.")

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
             "segmentSeconds": (p.get("segment") or {}).get("seconds"),
             "cyclesInSegment": p.get("cyclesInSegment"),
             # A take contributing three cycles is not the same evidence as one
             # contributing nine; the median that represents it is thinner.
             "thinEvidence": (p.get("cyclesInSegment") or 0) < MIN_CYCLES_PER_TAKE}
            for p in sources
        ],
        "excludedNotLesson": excluded_source,
        "excludedAnchorSource": [
            {"videoId": p["videoId"],
             "ankleVisibility": (p.get("anchor") or {}).get("ankleVisibility"),
             "why": "ayak bileği izlenemedi; dizden çapalandı — faz tanımı farklı"}
            for p in excluded],
        "mirrorResolution": mirror_log,
        "mirrorConfident": mirror_confident,
        "reference": consensus,
        "toleranceDeg": tolerance,
        "toleranceSource": tolerance_source,
        "disagreement": disagreement,
        "scoring": scoring,
        "toleranceBelowDispersion": violations,
        "status": status,
        "provisionalReason": provisional_reason,
        "evidenceThickness": evidence_thickness,
        "sourceSuitability": source_suitability,
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

    # build() classifies every take via classify_source.classify(videoId),
    # which reads real manifest/transcript files from the harvest library.
    # The synthetic takes below use fake ids ("a", "b", "c", ...) that have no
    # such files, so left unpatched every one of them is classified as
    # not-a-lesson and every scenario silently degrades to 0 usable takes —
    # this self-test is about consensus/mirror/tolerance behaviour, not the
    # suitability gate (that gate has its own tests in classify_source.py),
    # so the dependency is stubbed for the duration of this run.
    import classify_source  # noqa: PLC0415
    real_classify = classify_source.classify
    classify_source.classify = lambda video_id: {
        "verdict": "lesson", "spokenWords": None, "why": "self-test stub"}
    # No try/finally: this is a terminal --self-test CLI run, nothing else
    # executes after main() returns, so there is nothing for a leaked patch
    # to affect. Restored anyway at the two return points below, for anyone
    # who later imports self_test() as a function rather than running it.

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
    # The orientation-mirror rule, forced. A signed thigh angle must come back
    # negated when the body is mirrored; if mirrored() only renamed the joint,
    # the flipped take would disagree with its own reflection and the tolerance
    # derived from that disagreement would be inflated — silently, since
    # nothing else in the pipeline inspects the sign.
    a_or = _synth_take("a", noise=0.0)
    a_or["joints"]["left_thigh"] = [30.0] * len(a_or["joints"]["left_knee"])
    a_or["joints"]["right_thigh"] = [-30.0] * len(a_or["joints"]["left_knee"])
    cyc_or = take_canonical_cycle(a_or)
    m = mirrored(cyc_or)
    check("aynalama YÖNELİM açısının işaretini çevirir",
          abs(m["right_thigh"][0] - (-30.0)) < 1e-6 and
          abs(m["left_thigh"][0] - 30.0) < 1e-6,
          f"sol={m['left_thigh'][0]:.1f} sağ={m['right_thigh'][0]:.1f}")
    check("aynalama FLEKSİYON açısına dokunmaz",
          abs(m["left_knee"][0] - cyc_or["right_knee"][0]) < 1e-6)

    warped = build([_synth_take("a", noise=0.5),
                    _synth_take("b", noise=0.5, linger=0.18),
                    _synth_take("c", noise=0.5)], "s")
    wk = {d["joint"]: d["kind"] for d in warped.get("disagreement", [])}
    check("çevrim-içi çarpılma ARTIK'a düşer (bilinen sınır)",
          bool(wk) and all(v in ("residual", "mixed") for v in wk.values()),
          str(wk))

    # Order-independence. The greedy orienter passed every test above while
    # quietly making the answer depend on which take was listed first — on real
    # footage it flipped 3 of 6 pairs on one step and 4 of 6 on the other. A
    # consensus that changes with file order is not a consensus, so the property
    # is asserted directly: shuffle the input, the relative orientations must
    # not move.
    takes = [_synth_take("a", noise=1.0), _synth_take("b", noise=1.0, mirror=True),
             _synth_take("c", noise=1.0, phase_shift=0.5)]
    #
    # What must be stable is the RELATIVE arrangement, not the absolute one:
    # the whole set can be mirrored or half-rotated together and remain equally
    # valid, and since the solver pins take 0 to break that symmetry, permuting
    # the input legitimately pins a different take. So the assertion compares
    # the pairwise distance matrix, which is blind to the global symmetry and
    # sees exactly the thing that used to drift.
    cyc = [take_canonical_cycle(t) for t in takes]
    base, _ = orient(cyc)

    def pair_matrix(placed, order):
        m = {}
        for a in range(len(order)):
            for b in range(a + 1, len(order)):
                key = tuple(sorted((order[a], order[b])))
                m[key] = round(distance(placed[a], placed[b]), 6)
        return m

    ref_m = pair_matrix(base, list(range(len(cyc))))
    stable = all(pair_matrix(orient([cyc[i] for i in perm])[0], perm) == ref_m
                 for perm in ([1, 0, 2], [2, 1, 0], [1, 2, 0]))
    check("yönlendirme GİRDİ SIRASINDAN bağımsız (göreli düzen)", stable)

    # M-F-41 invariant, forced rather than trusted: a coach's own spread may
    # never be billed to the learner. Pushed with a teacher who disagrees
    # violently, which is the case a floor-plus-multiplier could get wrong.
    wild = _synth_take("c", noise=0.5)
    wild["joints"]["left_knee"] = [v * 0.3 + 95 for v in wild["joints"]["left_knee"]]
    wild["joints"]["right_elbow"] = [v + 55 for v in wild["joints"]["right_elbow"]]
    inv = build([_synth_take("a", noise=0.5),
                 _synth_take("b", noise=0.5), wild], "s")
    check("DEĞİŞMEZ: tolerans hiçbir fazda ölçülen ayrışmanın altında değil",
          inv["built"] and not inv["toleranceBelowDispersion"],
          f"{len(inv.get('toleranceBelowDispersion', []))} ihlal")

    # And the joint that blew out must stop being scored, not silently keep a
    # band wide enough to pass anything. left_knee is the control: it is
    # perturbed too, but not far enough to clear the threshold once the median
    # of three has absorbed it, so it must STAY scored — the rule has to be a
    # measurement, not a reflex to any disagreement at all.
    v = {j: inv["scoring"][j]["verdict"] for j in inv["scoring"]}
    check("ayrışan eklem SKORLANIR olmaktan çıkar, komşusu çıkmaz",
          v.get("right_elbow") in ("coached_only", "scored_partial") and
          v.get("right_knee") == "scored", str(v))

    classify_source.classify = real_classify

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


def _json_safe(obj):
    """Recursively replaces NaN/Inf with null before serialisation.

    json.dumps's default (allow_nan=True) writes the literal token `NaN` —
    valid Python, not valid JSON, and exactly what turned a NaN produced
    upstream into a cross-language artifact crash rather than a null a
    consumer can check for (0.8.4's lesson, applied here proactively rather
    than after the same failure). Written with allow_nan=False below so a
    NaN that reaches serialisation despite this walk raises loudly instead
    of writing invalid JSON anyway.
    """
    if isinstance(obj, float):
        return None if (math.isnan(obj) or math.isinf(obj)) else obj
    if isinstance(obj, dict):
        return {k: _json_safe(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_json_safe(v) for v in obj]
    return obj


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

    def _restore_nan(p: dict) -> dict:
        # The inverse of _json_safe below: prepare_take.py's own --out
        # sanitises NaN to JSON null on the way out (0.8.4 lesson), so a
        # gated-out joint value round-trips here as None, not NaN — and
        # this file's math still expects the latter (resample/take_
        # canonical_cycle call math.isnan on it). Only "joints" is fixed
        # up: it is the one field this pipeline ever puts a NaN into.
        joints = p.get("joints")
        if isinstance(joints, dict):
            for name, series in joints.items():
                joints[name] = [float("nan") if v is None else v
                                for v in series]
        return p

    prepared: list[dict] = []
    if args.prepared:
        d = json.loads(Path(args.prepared).read_text(encoding="utf-8"))
        prepared.extend(_restore_nan(x) for x in
                        (d if isinstance(d, list) else [d]))
    for p in args.takes:
        prepared.append(
            _restore_nan(json.loads(Path(p).read_text(encoding="utf-8"))))
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
        thin = "  ⚠ ZAYIF KANIT" if s.get("thinEvidence") else ""
        print(f"    {s['videoId']:<13}{s['channel'][:26]:<28}"
              f"periyot {s['periodSeconds']}s  segment {s['segmentSeconds']}s"
              f"  {s.get('cyclesInSegment','?')} çevrim{thin}")
    print("\n  ayna çözümü:")
    for e in r["mirrorResolution"]:
        if False:
            pass
        else:
            bits = ("ayna" if e["flipped"] else "düz") + \
                   ("+yarım" if e["halfCycle"] else "")
            warn = {
                "degenerate": "  ○ DEJENERE — yönü çıktıya ulaşmıyor",
                "against_local_optimum": "  ⚠ global çözüm kendi tercihinin TERSİNE yerleştirdi",
                "uncertain": "  ⚠ BELİRSİZ — rakip farklı ve marj eşiğin altında",
                "decisive": "",
            }.get(e.get("orientationEffect"), "")
            if e.get("cellsBeyondTolerance") is not None:
                warn += (f"  [bandı aşan hücre %"
                         f"{e['cellsBeyondTolerance']*100:.1f}]")
            print(f"    {e['videoId']:<13}{bits:<12}"
                  f"en-iyi={e['bestDeg']}° ikinci={e.get('runnerUpDeg')}° "
                  f"marj={e.get('margin')}{warn}")

    tol = r["toleranceDeg"]
    print("\n  tolerans + skorlama kararı (M-F-41: ölçüm, anatomi değil):")
    print(f"    {'eklem':<16}{'min':>6}{'ortanca':>9}{'max':>7}"
          f"{'kapsam':>9}  karar   [bandın ne kadarı TABAN kaynaklı]")
    for j in sorted(tol):
        col = tol[j]; sc = r["scoring"][j]
        tag = {"scored": "SKORLANIR", "scored_partial": "kısmen skorlanır",
               "coached_only": "yalnız koçlanır"}[sc["verdict"]]
        floor_pct = r["toleranceSource"][j].count("floor") / len(col) * 100
        print(f"    {j:<16}{min(col):>6.1f}{statistics.median(col):>9.1f}"
              f"{max(col):>7.1f}{sc['coverage']*100:>8.0f}%  {tag}"
              f"   [taban %{floor_pct:.0f}]")
    partial = [j for j in tol if r["scoring"][j]["verdict"] == "scored_partial"]
    if partial:
        print("    ↳ kısmen: eklem çevrimin bir kısmında sıkı, kalanında değil —"
              "\n      skorlama o fazlarda KAPATILIR (dansta aynı eklem faz\n"
              "      boyunca skorlanabilir↔skorlanamaz arası gider).")
    if r["toleranceBelowDispersion"]:
        print(f"\n  ✗ DEĞİŞMEZ İHLALİ: {len(r['toleranceBelowDispersion'])} "
              "noktada tolerans ölçülen ayrışmanın ALTINDA — eğitmenlerin kendi\n"
              "    farkı kullanıcı hatası sayılıyor.")
    else:
        print("\n  ✓ değişmez: hiçbir fazda tolerans ölçülen ayrışmanın altında değil.")

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
        Path(args.out).write_text(
            json.dumps(_json_safe(r), ensure_ascii=False, indent=1,
                      allow_nan=False), encoding="utf-8")
        print(f"\nyazıldı: {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
