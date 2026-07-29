#!/usr/bin/env python3
"""Turns one harvested take into the anchored, isotropic segment downstream needs.

Every reference-building step wants the same thing first: the stretch of the
video where the step is actually danced, measured in a space where angles mean
something, with cycle phase pinned to a body event. That prefix was being
redone by hand each time; this is it as an instrument.

Pipeline, in order, and each stage exists because skipping it broke something:

  isotropic     image landmarks are anisotropic; feeding them to geometry bends
                every angle by the aspect ratio (C-060 / M-F-30)
  movement      a tutorial is mostly the instructor talking; consensus computed
                over explanation is consensus over nothing (M-C-16)
  camera gate   obliquity folded as min(yaw, 180-yaw) — instructors deliberately
                turn their back to demonstrate, and 0 deg and 180 deg are both
                clean; 30-60 deg is the enemy (C-041)
  anchor        see below

THE ANCHOR IS THE PART THAT IS EASY TO SKIP AND FATAL TO SKIP.

A step repeats, so cycle phase has no natural zero. Left free, an aligner
comparing a take against a mirrored reference will slide phase until the two
match and report a near-perfect score — a symmetric step is, after all, its own
mirror shifted half a cycle. The first mirror measurements here came back at
+-0.0003, which read like "the mirror question is undecidable" and actually
meant "the question was never asked": the phase slide absorbed the answer.

The anchor pins phase to a body event: the peak of the signed left-right ankle
separation, the moment the left foot is furthest forward.

Note what that event does and does not do. It is **invariant** under mirroring:
flipping the image sends x to (c - x) and swaps the anatomical labels, so
(L.x - R.x) comes back unchanged. The anchor therefore cannot itself tell a
mirrored take from a straight one — and that invariance is the point, because
it means the phase origin is the same regardless of whether the instructor
filmed mirrored for students to copy. What anchoring buys is that the mirror
difference can no longer hide in a phase slide; it has to surface in the joint
vector, where the arms and the asymmetric leg work actually differ. That is
what moved the margins from +-0.0003 to 0.027 and 0.072 — not the anchor
detecting the mirror, but the anchor refusing to conceal it.

  python3 tools/prepare_take.py --video bdY2Pwqj-9A
  python3 tools/prepare_take.py --video ID --out prepared/ID.json
  python3 tools/prepare_take.py --self-test
"""

from __future__ import annotations

import argparse
import json
import math
import os
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from camera_angle_gate import find_usable_windows_world  # noqa: E402
from movement_isolator import find_movement_windows  # noqa: E402

HARVEST = Path(os.path.expanduser("~/motion-harvest/choreia"))
LANDMARKS = HARVEST / "landmarks"
RAW = HARVEST / "raw"

REPO = Path(__file__).resolve().parents[1]
CORE_REPO = REPO.parents[1] / "motion-core" / "lib"
CORE_PIN = "motion_core-v0.3.0"
CORE_JOINTS_PATH = "packages/motion_core/lib/src/geometry/joint_angles.dart"

L_SHOULDER, R_SHOULDER = 11, 12
L_HIP, R_HIP = 23, 24
L_ANKLE, R_ANKLE = 27, 28

# Vertex triplets for the angles a dance reference is built from.
#
# The triplets live here because they are landmark-topology facts, but the KEYS
# are checked against the pinned core's StandardJoints. If the core renames or
# drops a joint, this fails loudly instead of silently producing a reference
# keyed on vocabulary the runtime no longer knows.
JOINT_TRIPLETS: dict[str, tuple[int, int, int]] = {
    "left_elbow": (11, 13, 15),
    "right_elbow": (12, 14, 16),
    "left_shoulder": (13, 11, 23),
    "right_shoulder": (14, 12, 24),
    "left_hip": (11, 23, 25),
    "right_hip": (12, 24, 26),
    "left_knee": (23, 25, 27),
    "right_knee": (24, 26, 28),
}


def core_joint_ids() -> set[str]:
    r = subprocess.run(
        ["git", "-C", str(CORE_REPO), "show", f"{CORE_PIN}:{CORE_JOINTS_PATH}"],
        capture_output=True, text=True,
    )
    if r.returncode != 0:
        raise SystemExit(
            f"pinned core {CORE_PIN} not readable from {CORE_REPO}\n"
            f"  {r.stderr.strip()[:200]}"
        )
    return set(re.findall(r"id:\s*'([a-z_]+)'", r.stdout))


def check_vocabulary() -> None:
    known = core_joint_ids()
    unknown = sorted(set(JOINT_TRIPLETS) - known)
    if unknown:
        raise SystemExit(
            f"joint ids not in pinned core {CORE_PIN}: {', '.join(unknown)}\n"
            "  the core vocabulary moved; update JOINT_TRIPLETS deliberately."
        )


# --------------------------------------------------------------------------
# geometry
# --------------------------------------------------------------------------

def aspect_of(video_id: str) -> float:
    info = RAW / f"{video_id}.info.json"
    if info.exists():
        d = json.loads(info.read_text(encoding="utf-8"))
        w, h = d.get("width"), d.get("height")
        if w and h:
            return w / h
    return 16 / 9


def to_isotropic(frames: list[list[list[float]]], aspect: float):
    """x scaled by the aspect ratio, so one unit is one unit in any direction.

    Mirrors motion_core's PoseFrame.toIsotropic. Only x and y are used
    downstream here, so z is carried through untouched.
    """
    return [[[p[0] * aspect] + list(p[1:]) for p in lm] for lm in frames]


def torso_frame(lm) -> tuple[float, float, float] | None:
    hx = (lm[L_HIP][0] + lm[R_HIP][0]) / 2
    hy = (lm[L_HIP][1] + lm[R_HIP][1]) / 2
    sx = (lm[L_SHOULDER][0] + lm[R_SHOULDER][0]) / 2
    sy = (lm[L_SHOULDER][1] + lm[R_SHOULDER][1]) / 2
    torso = math.hypot(sx - hx, sy - hy)
    if torso < 1e-6:
        return None
    return hx, hy, torso


def angle_at(a, b, c) -> float:
    ux, uy = a[0] - b[0], a[1] - b[1]
    vx, vy = c[0] - b[0], c[1] - b[1]
    lu, lv = math.hypot(ux, uy), math.hypot(vx, vy)
    if lu < 1e-9 or lv < 1e-9:
        return float("nan")
    cos = max(-1.0, min(1.0, (ux * vx + uy * vy) / (lu * lv)))
    return math.degrees(math.acos(cos))


def joint_series(frames) -> dict[str, list[float]]:
    out: dict[str, list[float]] = {k: [] for k in JOINT_TRIPLETS}
    for lm in frames:
        for name, (a, b, c) in JOINT_TRIPLETS.items():
            out[name].append(angle_at(lm[a], lm[b], lm[c]))
    return out


# --------------------------------------------------------------------------
# the anchor
# --------------------------------------------------------------------------

def leading_foot_signal(frames, axis: str = "auto") -> tuple[list[float], str]:
    """Signed left-right ankle separation, torso-normalised.

    Two axes are available and they behave differently under mirroring, which
    is why the choice is recorded rather than hidden:

      x  lateral separation. INVARIANT under mirroring — flipping the image
         negates x and swapping the anatomical labels negates it again. Ideal,
         but small for steps that travel backwards rather than sideways: a
         Roger Rabbit take measured 0.079 torso-lengths of lateral swing where
         the threshold wanted 0.08.

      y  vertical separation — which foot is lifted. Large for kick-back steps,
         but it ANTI-inverts: mirroring does not flip y while the label swap
         does, so a mirrored take anchors half a cycle away.

    `auto` takes whichever swings harder and reports it, and build_reference
    absorbs the difference by searching the half-cycle shift as part of mirror
    resolution.
    """
    xs: list[float] = []
    ys: list[float] = []
    for lm in frames:
        tf = torso_frame(lm)
        if tf is None:
            xs.append(float("nan"))
            ys.append(float("nan"))
            continue
        _, _, torso = tf
        xs.append((lm[L_ANKLE][0] - lm[R_ANKLE][0]) / torso)
        ys.append((lm[L_ANKLE][1] - lm[R_ANKLE][1]) / torso)

    def swing(v: list[float]) -> float:
        ok = [q for q in v if not math.isnan(q)]
        return (max(ok) - min(ok)) if ok else 0.0

    if axis == "x":
        return xs, "x"
    if axis == "y":
        return ys, "y"
    return (xs, "x") if swing(xs) >= swing(ys) else (ys, "y")


def _smooth(xs: list[float], k: int) -> list[float]:
    if k < 2:
        return xs
    out = []
    for i in range(len(xs)):
        lo, hi = max(0, i - k // 2), min(len(xs), i + k // 2 + 1)
        win = [v for v in xs[lo:hi] if not math.isnan(v)]
        out.append(sum(win) / len(win) if win else float("nan"))
    return out


def find_anchor(signal: list[float], period_frames: int) -> dict:
    """Cycle phase 0 = left foot furthest forward, located within the first cycle.

    Two different questions are asked at two different scopes, and conflating
    them was a real defect. "Does this take have leading-foot motion at all?"
    is a property of the WHOLE segment. "Where in the cycle is the origin?" is
    necessarily a question about ONE cycle — searching globally would put the
    origin at the take's single biggest stride rather than at a phase.

    Measuring both on the first cycle rejected a take whose ankles swung 0.819
    torso-lengths across the segment but only 0.079 in its opening repetition,
    which was a slow lead-in. The dancer was fine; the gate was reading the
    wrong window.
    """
    if period_frames < 2 or len(signal) < period_frames:
        return {"ok": False, "why": "period longer than segment"}
    sm = _smooth(signal, max(3, period_frames // 8))

    whole = [v for v in sm if not math.isnan(v)]
    if not whole:
        return {"ok": False, "why": "ankles never visible"}
    swing = max(whole) - min(whole)
    # A step whose ankles barely separate anywhere has no leading foot to speak
    # of, and anchoring on noise would be worse than admitting the take cannot
    # be anchored: downstream would then read pure noise as signal.
    if swing < 0.08:
        return {"ok": False, "why": f"ankle swing too small ({swing:.3f} torso)",
                "swing": round(swing, 4)}

    first = sm[:period_frames]
    usable = [(i, v) for i, v in enumerate(first) if not math.isnan(v)]
    if not usable:
        return {"ok": False, "why": "ankles never visible in first cycle"}
    idx, peak = max(usable, key=lambda iv: iv[1])
    return {
        "ok": True,
        "frameInCycle": idx,
        "phase": round(idx / period_frames, 4),
        "leadingFoot": "left" if peak > 0 else "right",
        "peak": round(peak, 4),
        "swing": round(swing, 4),
        "firstCycleSwing": round(max(v for _, v in usable)
                                 - min(v for _, v in usable), 4),
    }


# --------------------------------------------------------------------------

def load_take(video_id: str):
    p = LANDMARKS / f"{video_id}.full.json"
    if not p.exists():
        raise SystemExit(f"no landmarks for {video_id} — harvest it first")
    d = json.loads(p.read_text(encoding="utf-8"))
    fps = float(d.get("recordingMeta", {}).get("fps") or 30)
    lm, world, keep = [], [], []
    for i, f in enumerate(d.get("frames", [])):
        if f.get("detected") is False or not f.get("lm"):
            continue
        lm.append(f["lm"])
        world.append(f.get("world"))
        keep.append(i)
    return d, lm, world, keep, fps


def overlap(a: tuple[int, int], b: tuple[int, int]) -> tuple[int, int] | None:
    lo, hi = max(a[0], b[0]), min(a[1], b[1])
    return (lo, hi) if hi - lo > 0 else None


def prepare(video_id: str) -> dict:
    doc, lm, world, _, fps = load_take(video_id)
    aspect = aspect_of(video_id)
    iso = to_isotropic(lm, aspect)

    # Both searches are widened well past their defaults and then intersected,
    # rather than taking each list's best and hoping the two agree.
    #
    # Taking movement's top window and only then asking the camera gate about
    # it rejected most of the library: on The Shed's take the best movement
    # window ended 40 frames before the nearest clean window began, while the
    # third-best sat inside it. Optimising one criterion and filtering by the
    # other is not the same as optimising over what satisfies both.
    moves = find_movement_windows(iso, fps=fps, max_windows=40)
    if not moves:
        return {"videoId": video_id, "usable": False,
                "why": "no repeating-and-moving window found"}

    cam_ok: list[tuple[int, int]] = []
    if all(w for w in world):
        cam_ok = [(w.start_frame, w.end_frame)
                  for w in find_usable_windows_world(world, fps=fps,
                                                     max_windows=40)]

    if cam_ok:
        feasible = []
        for m in moves:
            for c in cam_ok:
                o = overlap((m.start_frame, m.end_frame), c)
                # A sliver of overlap is not a usable take; require enough of
                # the step to survive that several cycles remain.
                if o and (o[1] - o[0]) >= max(2, int(round(m.period_s * fps))) * 3:
                    feasible.append((o, m))
        if not feasible:
            return {"videoId": video_id, "usable": False,
                    "why": "no movement window overlaps a camera-clean window",
                    "movementWindows": [[m.start_frame, m.end_frame] for m in moves[:6]],
                    "cameraWindows": [list(c) for c in cam_ok[:6]]}
        # Prefer the most self-similar movement, then the longest usable stretch.
        seg, best = max(feasible, key=lambda fm: (fm[1].periodicity,
                                                  fm[0][1] - fm[0][0]))
    else:
        best = moves[0]
        seg = (best.start_frame, best.end_frame)

    frames = iso[seg[0]:seg[1]]
    period_frames = max(2, int(round(best.period_s * fps)))
    signal, axis = leading_foot_signal(frames)
    anchor = find_anchor(signal, period_frames)
    anchor["axis"] = axis

    return {
        "videoId": video_id,
        "usable": bool(anchor.get("ok")),
        "why": None if anchor.get("ok") else anchor.get("why"),
        "corePin": CORE_PIN,
        "space": "isotropic-image",
        "aspect": round(aspect, 4),
        "fps": fps,
        "segment": {"startFrame": seg[0], "endFrame": seg[1],
                    "seconds": round((seg[1] - seg[0]) / fps, 2)},
        "periodSeconds": best.period_s,
        "periodFrames": period_frames,
        "periodicity": best.periodicity,
        "motionEnergy": best.motion_energy,
        "anchor": anchor,
        "anchorAxis": anchor.get("axis"),
        "joints": joint_series(frames) if anchor.get("ok") else None,
        "provenance": doc.get("provenance", {}),
    }


PERIOD = 30


def _stepping(n: int = 180, *, amp: float = 0.09, offset: float = 0.0):
    """A body stepping left-right, with the cycle started `offset` radians in."""
    frames = []
    for t in range(n):
        ph = 2 * math.pi * t / PERIOD + offset
        lm = [[0.5, 0.5, 0.0, 1.0] for _ in range(33)]
        lm[L_HIP] = [0.45, 0.60, 0, 1]
        lm[R_HIP] = [0.55, 0.60, 0, 1]
        lm[L_SHOULDER] = [0.42, 0.38, 0, 1]
        lm[R_SHOULDER] = [0.58, 0.38, 0, 1]
        lm[L_ANKLE] = [0.50 + amp * math.sin(ph), 0.92, 0, 1]
        lm[R_ANKLE] = [0.50 - amp * math.sin(ph), 0.92, 0, 1]
        frames.append(lm)
    return frames


def _mirror(frames):
    """Flip the image AND swap anatomical labels — what a mirrored take is."""
    out = []
    for lm in frames:
        flipped = [[1.0 - p[0]] + list(p[1:]) for p in lm]
        m = list(flipped)
        for a, b in ((L_ANKLE, R_ANKLE), (L_HIP, R_HIP),
                     (L_SHOULDER, R_SHOULDER)):
            m[a], m[b] = flipped[b], flipped[a]
        out.append(m)
    return out


def self_test() -> int:
    """The anchor must be stable under mirroring, and must still track phase."""
    print("prepare_take — çapa davranışı\n")
    fails = 0

    straight = _stepping()
    a = find_anchor(leading_foot_signal(straight, "x")[0], PERIOD)
    b = find_anchor(leading_foot_signal(_mirror(straight), "x")[0], PERIOD)

    print(f"  düz            : ok={a.get('ok')} faz={a.get('phase')} "
          f"öncü={a.get('leadingFoot')} salınım={a.get('swing')}")
    print(f"  aynalı         : ok={b.get('ok')} faz={b.get('phase')} "
          f"öncü={b.get('leadingFoot')} salınım={b.get('swing')}")

    if not (a.get("ok") and b.get("ok")):
        print("  ! çapa bulunamadı"); fails += 1
    else:
        # Invariance, not inversion: a mirrored recording of the same dancing
        # must land on the same phase origin, so takes filmed either way are
        # compared from the same starting point.
        if abs(a["phase"] - b["phase"]) > 1e-9:
            print("  ! çapa aynalamaya DEĞİŞMEZ olmalı"); fails += 1
        if abs(a["swing"] - b["swing"]) > 1e-9:
            print("  ! salınım aynalamayla değişmemeli"); fails += 1

    # Without this, a function that always returned phase 0 would pass every
    # check above. Start the same step a quarter cycle in; the origin must move
    # with it.
    shifted = _stepping(offset=math.pi / 2)
    d = find_anchor(leading_foot_signal(shifted, "x")[0], PERIOD)
    delta = (a.get("phase", 0) - d.get("phase", 0)) % 1.0
    print(f"  çeyrek kaydırma: faz={d.get('phase')} (fark={delta:.3f}, ~0.25 bekleniyor)")
    if not (0.20 <= delta <= 0.30):
        print("  ! çapa faz kaymasını izlemiyor"); fails += 1

    flat = _stepping(amp=0.003)
    c = find_anchor(leading_foot_signal(flat, "x")[0], PERIOD)
    print(f"  ayak ayrılmıyor: ok={c.get('ok')} ({c.get('why', '')})")
    if c.get("ok"):
        print("  ! ayrılmayan ayaklarda çapa REDDEDİLMELİ"); fails += 1

    print()
    if fails:
        print(f"SELF-TEST FAILED ({fails})")
        return 1
    print("SELF-TEST OK")
    print("\n'aynalı' satırı düz satırla AYNI — çapa aynalamayı ayırt etmez,\n"
          "etmemeli de: eğitmen aynalı çekmiş olsa da faz orijini aynı kalsın\n"
          "diye. Çapanın işi ayna farkını faz kaymasında SAKLANAMAZ kılmak;\n"
          "fark eklem vektöründe görünür. 'çeyrek kaydırma' satırı ise çapanın\n"
          "sabit bir sayı döndürmediğinin kanıtı.")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--video")
    ap.add_argument("--out")
    ap.add_argument("--all", action="store_true",
                    help="every harvested take")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    check_vocabulary()
    ids = ([p.name.split(".")[0] for p in sorted(LANDMARKS.glob("*.full.json"))]
           if args.all else ([args.video] if args.video else []))
    if not ids:
        ap.print_help()
        return 1

    print(f"{'video':<13}{'durum':<10}{'segment':>16}{'periyot':>9}"
          f"{'faz':>7}{'öncü':>7}{'eks':>4}  neden")
    results = []
    for vid in ids:
        r = prepare(vid)
        results.append(r)
        seg = r.get("segment") or {}
        anc = r.get("anchor") or {}
        print(f"{vid:<13}{'✓ hazır' if r['usable'] else '✗ elendi':<10}"
              f"{(str(seg.get('seconds', '-')) + 's'):>16}"
              f"{(str(r.get('periodSeconds', '-')) + 's'):>9}"
              f"{str(anc.get('phase', '-')):>7}{str(anc.get('leadingFoot', '-')):>7}"
              f"{str(anc.get('axis', '-')):>4}  {r.get('why') or ''}")

    ok = [r for r in results if r["usable"]]
    print(f"\n{len(ok)}/{len(results)} take hazır.")
    if len(ok) < 3:
        print(f"⚠ ≥3 kuralı sağlanmıyor — referans ÜRETİLMEZ (M-C-04).")

    if args.out:
        Path(args.out).write_text(
            json.dumps(results if len(results) > 1 else results[0],
                       ensure_ascii=False, indent=1), encoding="utf-8")
        print(f"yazıldı: {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
