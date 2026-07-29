#!/usr/bin/env python3
"""Does the salsa basic's held count show up at ANKLE level?

C-105 found that the plateau detector reads the summed speed of eight LEG-ANGLE
joints, while `steps/ss_basic.json` declares its hold at FOOT-CONTACT level
("Counts 4 and 8 are held, not stepped"). Those are different measurements: on
count 4 the foot stops while the hips and the weight keep moving, so an
angle-speed detector sees no pause. The detector was consistent — it measured
the wrong LEVEL.

M-F-144 asks one measurement that settles both open questions at once:

  (a) If ANKLE horizontal travel separates stepped counts from held ones, the
      plateau detector moves to ankle-travel (threshold from the measured
      separation, not invented) and ss_basic keeps measurability tier A —
      what makes Running Man tier C is TOE-tip unreliability, and the ankle is
      a markedly more reliable landmark than the toe.
  (b) If only the TOE separates them, ss_basic drops to tier C and becomes a
      demoOnly lesson (K10) — by measurement, not by taste.

REPORT ONLY, BY INSTRUCTION. No threshold is proposed here and nothing is
gated on the output: the distribution comes first, a threshold (if any) second.

WHY THE SHINES ARE IN THE RUN. They are the control. Shine footwork is
continuous by construction — it is the step whose whole cycle keeps moving —
so if the ankle channel reports the same shape for shines and for basic
candidates, the channel does not separate anything and (a) is answered NO
regardless of what the numbers look like on their own.

  python3 tools/probe_ankle_travel.py
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
from prepare_take import (ankle_visibility, aspect_of, find_anchor,  # noqa: E402
                          leading_foot_signal, load_take, to_isotropic,
                          L_ANKLE, R_ANKLE, L_HIP, R_HIP, L_SHOULDER, R_SHOULDER)

PHASE_BINS = 64

# MediaPipe foot landmarks, proximal to distal. The hüküm's two branches turn
# on WHICH of these separates a held count from a stepped one: the ankle is a
# reliable landmark, the toe is the least reliable point in markerless
# single-camera pose (the very reason Running Man is tier C).
FOOT_LEVELS = {
    "ankle": (L_ANKLE, R_ANKLE),      # 27/28
    "heel": (29, 30),
    "toe": (31, 32),                  # foot_index — least reliable
}

# Candidates carrying real travel (C-104: thigh excursion cleared 12 deg) plus
# the shine controls. The two 90s-rejected clips never reached extraction.
GROUPS = {
    "BASIC ADAYI (seyahat ölçütünü geçen)": [
        ("FtZzjGsPxjg", "Dame Más Dance — Front & Back Basic Variations"),
        ("9NZp9_GuKrE", "Ballroom Feed — Forward & Back"),
    ],
    "KONTROL (shine — yapı gereği sürekli)": [
        ("jjP8bKWCg9U", "The Get Down — shine"),
        ("w4opJ2ezmd4", "Alfonso y Mónica — shine"),
        ("SHGkSbJm2Iw", "Dame Más Dance — Suzie Q shine"),
    ],
}


def _torso_relative_feet(frames, level: str = "ankle") -> list[tuple[float, float]] | None:
    """Each ankle's horizontal position relative to the hips, torso-scaled.

    Normalised the same way the rest of the pipeline normalises, so a dancer
    drifting toward the camera does not read as ankle travel.
    """
    li, ri = FOOT_LEVELS[level]
    out = []
    for lm in frames:
        hx = (lm[L_HIP][0] + lm[R_HIP][0]) / 2
        hy = (lm[L_HIP][1] + lm[R_HIP][1]) / 2
        sx = (lm[L_SHOULDER][0] + lm[R_SHOULDER][0]) / 2
        sy = (lm[L_SHOULDER][1] + lm[R_SHOULDER][1]) / 2
        torso = math.hypot(sx - hx, sy - hy)
        if torso < 1e-6:
            return None
        out.append(((lm[li][0] - hx) / torso,
                    (lm[ri][0] - hx) / torso))
    return out


def _resample(series: list[float], start: int, length: int, bins: int):
    if length < 2:
        return None
    out = []
    for b in range(bins):
        pos = start + (b / bins) * length
        i = int(math.floor(pos))
        frac = pos - i
        if i + 1 >= len(series):
            if i >= len(series):
                return None
            out.append(series[i])
            continue
        out.append(series[i] * (1 - frac) + series[i + 1] * frac)
    return out


def foot_speed_profile(frames, period_frames: int, anchor_frame: int,
                       fps: float, level: str = "ankle") -> dict | None:
    """Per-phase-bin ankle horizontal SPEED, median across the take's cycles.

    Speed rather than position: the question is whether the foot is moving or
    held, and that is a derivative. Reported in torso-lengths per second so
    frame rate cannot change the numbers (the family's unit rule).
    """
    pos = _torso_relative_feet(frames, level)
    if pos is None:
        return None
    n = len(pos)
    if n < period_frames * 2:
        return None

    # Speed per frame, per leg, then the faster leg — a held count means BOTH
    # feet are settled, so taking the max is the conservative reading.
    speed = []
    for i in range(1, n):
        dl = abs(pos[i][0] - pos[i - 1][0]) * fps
        dr = abs(pos[i][1] - pos[i - 1][1]) * fps
        speed.append(max(dl, dr))

    cycles = [(s, period_frames) for s in
              range(anchor_frame, len(speed) - period_frames + 1, period_frames)]
    if not cycles:
        return None
    stack = [r for r in (_resample(speed, s, ln, PHASE_BINS) for s, ln in cycles)
             if r is not None]
    if not stack:
        return None
    prof = [statistics.median([c[b] for c in stack]) for b in range(PHASE_BINS)]

    med = statistics.median(prof)
    lo = min(prof)
    hi = max(prof)
    # Fraction of the cycle spent markedly slower than its own median — the
    # ankle-level analogue of the plateau measure, reported NOT gated.
    slow_frac = sum(1 for v in prof if v < med * 0.5) / PHASE_BINS
    return {
        "cycles": len(stack),
        "minSpeed": round(lo, 3),
        "medianSpeed": round(med, 3),
        "maxSpeed": round(hi, 3),
        # How deep the quietest moment is relative to typical motion. A held
        # count should drive this toward 0; continuous motion keeps it high.
        "minOverMedian": round(lo / med, 3) if med > 1e-9 else None,
        "dynamicRange": round(hi / lo, 2) if lo > 1e-9 else None,
        "slowFraction": round(slow_frac, 3),
    }


def _overlap(a, b):
    lo, hi = max(a[0], b[0]), min(a[1], b[1])
    return (lo, hi) if hi > lo else None


def probe(video_id: str, window_s: float = 6.0, level: str = "ankle") -> list[dict]:
    doc, lm, world, _, fps = load_take(video_id)
    iso = to_isotropic(lm, aspect_of(video_id))
    moves = find_movement_windows(iso, fps=fps, window_s=window_s, max_windows=40)
    cam = []
    if all(w for w in world):
        cam = [(w.start_frame, w.end_frame)
               for w in find_usable_windows_world(world, fps=fps, max_windows=40)]

    rows = []
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
        pf = max(2, int(round(m.period_s * fps)))
        if seg[1] - seg[0] < pf * 3:
            continue
        frames = iso[seg[0]:seg[1]]
        signal, _ = leading_foot_signal(frames)
        anchor = find_anchor(signal, pf, visibility=ankle_visibility(frames),
                             knee_swing=None)
        if not anchor.get("ok"):
            continue
        prof = foot_speed_profile(frames, pf, anchor["frameInCycle"], fps, level)
        if prof is None:
            continue
        prof.update({"videoId": video_id, "segment": list(seg),
                     "periodSeconds": round(m.period_s, 2)})
        rows.append(prof)
    return rows


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--window-s", type=float, default=6.0)
    ap.add_argument("--level", choices=sorted(FOOT_LEVELS), default="ankle",
                    help="ayak landmark seviyesi: ankle (güvenilir) → toe (en güvenilmez)")
    ap.add_argument("--out")
    args = ap.parse_args()

    print(f"AYAK yatay-seyahat dağılımı — seviye={args.level.upper()} — SALT RAPOR (M-F-144)")
    print("  birim: gövde-boyu/saniye · min/medyan oranı düşükse 'durma' var demektir")
    print(f"  window_s={args.window_s}\n")

    allrows = []
    for group, vids in GROUPS.items():
        print(f"{group}")
        for vid, label in vids:
            try:
                rows = probe(vid, window_s=args.window_s, level=args.level)
            except SystemExit as e:
                print(f"  {vid:<14} atlandı: {e}")
                continue
            if not rows:
                print(f"  {vid:<14} ölçülebilir pencere YOK — {label}")
                continue
            for r in rows:
                r["group"] = group
                allrows.append(r)
                print(f"  {vid:<14} {str(r['segment']):<16} çevrim={r['cycles']:<3} "
                      f"min={r['minSpeed']:<6} med={r['medianSpeed']:<6} "
                      f"min/med={str(r['minOverMedian']):<6} "
                      f"dinamik={str(r['dynamicRange']):<7} yavaş%={r['slowFraction']}")
        print()

    # The comparison the hüküm turns on: do the two groups separate?
    def stat(group_key, field):
        vals = [r[field] for r in allrows
                if r["group"].startswith(group_key) and r[field] is not None]
        return vals

    b = stat("BASIC", "minOverMedian")
    c = stat("KONTROL", "minOverMedian")
    print("KARŞILAŞTIRMA — min/medyan (0'a yakın = belirgin durma anı var):")
    if b and c:
        print(f"  basic adayları : {sorted(round(v,3) for v in b)}  "
              f"medyan {statistics.median(b):.3f}")
        print(f"  shine kontrol  : {sorted(round(v,3) for v in c)}  "
              f"medyan {statistics.median(c):.3f}")
        print()
        print("  Bu iki grup AYRIŞMIYORSA ankle kanalı da holdu göremiyor demektir")
        print("  ve M-F-144(a) cevabı HAYIR olur — sayılar kendi başına ne kadar")
        print("  düşük görünürse görünsün. Eşik ÖNERİLMİYOR (talimat: salt rapor).")
    else:
        print("  yeterli veri yok — karşılaştırma yapılamıyor")

    if args.out:
        Path(args.out).write_text(
            json.dumps(allrows, ensure_ascii=False, indent=1, allow_nan=False),
            encoding="utf-8")
        print(f"\nyazıldı: {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
