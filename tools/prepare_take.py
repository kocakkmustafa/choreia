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
CORE_PIN = "motion_core-v0.5.0"
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

# Segment ORIENTATIONS — where a limb points, measured against the trunk axis.
#
# These were missing and their absence was not cosmetic. The core states the
# reason plainly: flexion alone cannot tell an arm held out to the side from
# the same arm held in front, because both have the identical elbow angle. In
# dance, limb placement in space *is* the content, so a reference built from
# flexion only cannot describe the step. Choreia's first two references were
# built that way — eight flexion angles out of the seventeen the core defines.
#
# Unlike flexion these are SIGNED (a thigh pointing left is not a thigh
# pointing right), which makes mirroring a different operation: swapping the
# left/right names is no longer enough, the value must be negated too. See
# ORIENTATION_JOINTS use in build_reference.
JOINT_SEGMENTS: dict[str, tuple[int, int]] = {
    "left_upper_arm": (11, 13),
    "right_upper_arm": (12, 14),
    "left_forearm": (13, 15),
    "right_forearm": (14, 16),
    "left_thigh": (23, 25),
    "right_thigh": (24, 26),
    "left_shin": (25, 27),
    "right_shin": (26, 28),
}

# Trunk against image vertical. The core weights this low and says why: it
# moves when the PHONE tilts, so it carries camera error alongside body
# information. Kept because a harvested tutorial has a fixed camera.
TRUNK_TILT = "trunk_tilt"


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


# Below this, a landmark's (x, y) is MediaPipe's guess, not a measurement —
# visible on request: at ankle-vis 0.008 a knee angle still came back 174-179°
# degrees, plausible-looking and numeric, not the NaN the low confidence
# should have produced (J-056; the Dart core hit the same class of defect and
# gates on this same threshold — family symmetry, not a new number).
MIN_JOINT_VISIBILITY = 0.5


def _visible(*points: list[float]) -> bool:
    for p in points:
        if len(p) > 3 and p[3] < MIN_JOINT_VISIBILITY:
            return False
    return True             # no visibility channel at all: cannot judge, pass


def angle_at(a, b, c) -> float:
    if not _visible(a, b, c):
        return float("nan")
    ux, uy = a[0] - b[0], a[1] - b[1]
    vx, vy = c[0] - b[0], c[1] - b[1]
    lu, lv = math.hypot(ux, uy), math.hypot(vx, vy)
    if lu < 1e-9 or lv < 1e-9:
        return float("nan")
    cos = max(-1.0, min(1.0, (ux * vx + uy * vy) / (lu * lv)))
    return math.degrees(math.acos(cos))


def signed_angle_to(ux: float, uy: float, vx: float, vy: float) -> float:
    """Signed angle from vector v to vector u, degrees in (-180, 180]."""
    if math.hypot(ux, uy) < 1e-9 or math.hypot(vx, vy) < 1e-9:
        return float("nan")
    return math.degrees(math.atan2(ux * vy - uy * vx, ux * vx + uy * vy))


def joint_series(frames) -> dict[str, list[float]]:
    out: dict[str, list[float]] = {k: [] for k in JOINT_TRIPLETS}
    out.update({k: [] for k in JOINT_SEGMENTS})
    out[TRUNK_TILT] = []
    for lm in frames:
        for name, (a, b, c) in JOINT_TRIPLETS.items():
            out[name].append(angle_at(lm[a], lm[b], lm[c]))

        # The trunk axis feeds every segment orientation AND trunk_tilt below,
        # so an unreliable hip/shoulder corrupts all of them, not just its own
        # entry — gated once here rather than re-checked at each call site.
        trunk_ok = _visible(lm[L_HIP], lm[R_HIP], lm[L_SHOULDER], lm[R_SHOULDER])
        hx = (lm[L_HIP][0] + lm[R_HIP][0]) / 2
        hy = (lm[L_HIP][1] + lm[R_HIP][1]) / 2
        sx = (lm[L_SHOULDER][0] + lm[R_SHOULDER][0]) / 2
        sy = (lm[L_SHOULDER][1] + lm[R_SHOULDER][1]) / 2
        tx, ty = sx - hx, sy - hy          # trunk axis, hips -> shoulders
        for name, (a, b) in JOINT_SEGMENTS.items():
            if not trunk_ok or not _visible(lm[a], lm[b]):
                out[name].append(float("nan"))
                continue
            out[name].append(signed_angle_to(lm[b][0] - lm[a][0],
                                             lm[b][1] - lm[a][1], tx, ty))
        # Image vertical points up the screen, i.e. decreasing y.
        out[TRUNK_TILT].append(
            signed_angle_to(tx, ty, 0.0, -1.0) if trunk_ok else float("nan"))
    return out


# --------------------------------------------------------------------------
# the anchor
# --------------------------------------------------------------------------

L_KNEE, R_KNEE = 25, 26
MIN_ANKLE_VISIBILITY = 0.5


def ankle_visibility(frames) -> float:
    """Median tracker confidence on the two ankles across the segment."""
    vals = []
    for lm in frames:
        for i in (L_ANKLE, R_ANKLE):
            if len(lm[i]) > 3:
                vals.append(lm[i][3])
    if not vals:
        return 1.0            # fixture carries no visibility; cannot judge
    vals.sort()
    return vals[len(vals) // 2]


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


def find_anchor(signal: list[float], period_frames: int, *,
                visibility: float | None = None,
                knee_swing: float | None = None) -> dict:
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
    # "The feet do not separate" and "the feet cannot be seen" produce the same
    # small number, and until now the same rejection. They are different facts:
    # one is about the dance, the other about the footage, and only the first
    # is a reason to say the take has no leading foot. Corroboration comes from
    # the knees, which stay visible when trousers or occlusion swallow the
    # ankles (single-metric gate, Lissom L-138 class).
    if visibility is not None and visibility < MIN_ANKLE_VISIBILITY:
        if knee_swing is not None and knee_swing >= 0.08:
            # Corroboration establishes that the dancer MOVES; it does not make
            # an anchor derived from untracked ankles trustworthy. Letting the
            # take through on the knees while still phasing it on the ankles
            # would be a rubber stamp — the caller must re-anchor on the knee
            # signal instead. Measured: one salsa take had ankle visibility
            # 0.007 and was contributing both a phase and the anomalous
            # half-period that broke the pool's harmonic agreement.
            return {"ok": False, "reanchorOnKnees": True,
                    "why": f"ankle tracking unusable (vis {visibility:.2f}); "
                           "knees corroborate movement — re-anchor on knees",
                    "ankleVisibility": round(visibility, 3)}
        else:
            return {"ok": False,
                    "why": f"ankle tracking unreliable (vis {visibility:.2f}) "
                           "and knees do not corroborate — UNKNOWN, not 'no swing'",
                    "swing": round(swing, 4), "ankleVisibility": round(visibility, 3)}
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
    fps = d.get("recordingMeta", {}).get("fps")
    if not fps:
        # No silent default. This pool alone carries eight distinct frame rates
        # (23.976 to 60), and every period, window and cycle count downstream is
        # derived from this number — a 60 fps take assumed to be 30 has all of
        # them halved, with nothing to show for it.
        raise SystemExit(f"{video_id}: fixture meta has no fps — refusing to "
                         "assume one (periods and windows depend on it)")
    fps = float(fps)
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


_METRIC_VOCAB_PATH = REPO / "content" / "metric-vocabulary.json"

# Aileler (C-207 tasarımı — docs/design/HASAT-METRIK-TASARIMI.md, koordinatör
# onaylı). Metrik ADLARI değil metrik SINIFLARI: dördü de bu tasarımın kendisi
# tanımlıyor, C-202'nin "türetimli liste elle yazıldı" hatasını tekrarlamıyor
# çünkü content'ten türetilmiyor, content'in ÜZERİNE bir taksonomi kuruyor.
_FAMILY_FLEXION = "flexion"          # core AngleKind.flexion — işaretsiz derece
_FAMILY_ORIENTATION = "orientation"  # core AngleKind.orientation/trunkTilt — işaretli derece
_FAMILY_RHYTHM = "rhythm"            # DAİMA kapsam dışı — ürün sınırı, eksik kayıt değil
_FAMILY_COMPOSITE = "composite"      # HENÜZ kapsam dışı — bileşim semantiği ölçülmedi


def _metric_vocabulary_entry(driver: str) -> dict:
    """`driver` content/metric-vocabulary.json'da KAYITLI mı, family+jointRef
    taşıyor mu? İsimli ret — sessiz varsayılan yok (C-207, koordinatör (a)).

    Şekli değil adı bilinmeyen sürücü için son sözleşme burada: adım id'si
    değil DRIVER ADI + hangi durumla karşılaştığı mesajda taşınır, ki bir
    sonraki oturum "bulunamaz" ile "bakılmadı"yı ayırt edebilsin.
    """
    vocab = json.loads(_METRIC_VOCAB_PATH.read_text(encoding="utf-8"))
    entry = (vocab.get("metrics") or {}).get(driver)
    if entry is None:
        raise SystemExit(
            f"sürücü '{driver}' content/metric-vocabulary.json'da hiç yok — "
            "adlandırılmamış bir metrik faz-sürücülü seçime giremez")
    family = entry.get("family")
    if family == _FAMILY_RHYTHM:
        raise SystemExit(
            f"sürücü '{driver}' aile 'rhythm' — DAİMA kapsam dışı (ritim/"
            "zamanlama puanı bu üründe yok; 'henüz yok' değil 'asla "
            "olmayacak' — docs/design/HASAT-METRIK-TASARIMI.md §1)")
    if family == _FAMILY_COMPOSITE:
        raise SystemExit(
            f"sürücü '{driver}' aile 'composite' — ilk kesimde kapsam dışı "
            "(bileşim semantiği ölçülmedi, icat edilmiyor — koordinatör (b))")
    if family not in (_FAMILY_FLEXION, _FAMILY_ORIENTATION) or not entry.get("jointRef"):
        raise SystemExit(
            f"sürücü '{driver}' metric-vocabulary.json'da var ama family/"
            f"jointRef eksik veya bilinmeyen (family={family!r}) — isimsiz "
            "varsayılan yok, kayıt tamamlanmadan hasat edilemez")
    return entry


def kinematic_unit(step: str | None) -> dict | None:
    """Adım config'i KİNEMATİK bir çevrim birimi beyan ediyor mu? (M-F-231)

    Dispatch kuralı bu fonksiyondadır ve tek yerdedir. `None` dönerse çağıran
    ESKİ yolu koşar — ve o yol satır satır değiştirilmemiştir, yani
    non-kinematik adımların bit-değişmezliği İDDİA değil İNŞA gereğidir.

    `cyclePhaseNear` sınıfı adımlar (ss_shine_footwork vb.) `cycleUnit`
    beyan etmez: onların fazı bir eklem açısından değil, çapanın kendisinden
    türer — dolayısıyla "hangi pencerede bu olay var" sorusu onlar için
    tanımsızdır ve sorulmaz.
    """
    if not step:
        return None
    import json as _json  # noqa: PLC0415
    for p in REPO.glob(f"content/styles/*/steps/{step}.json"):
        cfg = _json.loads(p.read_text(encoding="utf-8"))
        raw = cfg.get("cycleUnit")
        if raw is None:
            return None
        if not isinstance(raw, dict):
            # ŞEKİL KAPISI (C-207, koordinatör (c)). Düz-dizge cycleUnit
            # "bu adım kinematik dispatch İSTEMİYOR, yalnız insan-okur
            # açıklama taşıyor" demektir — MEŞRU (bugün 4 adım böyle: dh_bounce,
            # sm_samba_no_pe, sh_running_man, sh_t_step) ama SESSİZ değil.
            # Önceki davranış `raw.get('driver')`'ı kontrolsüz çağırıp
            # AttributeError ile çöküyordu — ölçüldü, iki adımda (bkz. DEFTER
            # C-204 düzeltmesi). Bu turda bu 4 adım NESNEYE ÇEVRİLMİYOR
            # (koordinatör (c)): önce çökme isimli-rete, SONRA ölçerek nesneye.
            print(f"[kinematic_unit] '{step}': cycleUnit dizge ({raw!r}) — "
                 "faz-sürücülü seçim ATLANIYOR, eski (ankara-çapa) yol kullanılıyor")
            return None
        driver, dips = raw.get("driver"), raw.get("dipsPerCycle")
        if not driver or not dips:
            return None
        entry = _metric_vocabulary_entry(driver)  # isimli ret burada olur
        unit = dict(raw)
        unit["_phases"] = cfg.get("phases") or []
        unit["_errors"] = cfg.get("errors") or []
        unit["_family"] = entry["family"]
        unit["_jointRef"] = entry["jointRef"]
        return unit
    return None


def _standing_still_floor(unit: dict) -> float:
    """Adımın KENDİ "yerinde duruyor" eşiği, sürücünün kendi biriminde.

    İcat edilmedi: config'in `NO_BOUNCE` hatası zaten
    `knee_flexion_amplitude < 12°` diyor ve notu birebir "öğrenci müziğe
    kıpırdamadan duruyor". Aday penceresini elemek için gereken şey tam
    olarak bu — rig'in tüm-vücut enerji tabanı ise torso-göreli birimlerde
    ve bu eklem hakkında hiçbir şey söylemiyor.

    Eşik yoksa 0.0 döner (kapı kapanır, uydurulmaz).
    """
    for err in unit.get("_errors") or []:
        det = err.get("detect") or {}
        if (det.get("metric") == f"{unit['driver'].replace('_mean', '')}_amplitude"
                and det.get("op") == "<"):
            return float(det["valueDeg"])
    return 0.0


def _phase_thresholds_from(phases: list) -> tuple[float | None, float | None]:
    """(top giriş açısı, hız eşiği °/s) — adımın KENDİ faz tanımından.

    `probe_knee_windows.phase_thresholds` ile aynı sözleşme; oradan import
    etmek döngüsel olurdu (o modül bu modülü import ediyor), o yüzden okuma
    burada tekrarlanıyor. Tekrarlanan şey EŞİK DEĞİL, eşiğin nereden
    okunacağıdır — eşiklerin tek kaynağı hâlâ config.
    """
    top = rate = None
    for ph in phases:
        enter = ph.get("enter") or {}
        if ph.get("id") == "top" and enter.get("op") == ">":
            top = float(enter["valueDeg"])
        if enter.get("minRateDegPerSec") is not None:
            r = float(enter["minRateDegPerSec"])
            rate = r if rate is None else min(rate, r)
    return top, rate


def _knee_mean_series(frames) -> list[float]:
    """Ortalama diz açısı serisi. Tek diz görünmüyorsa NaN — yarım kanıttan
    tam sayı üretmek görünürlük kapısının engellemek için var olduğu şey.

    Yalnız ÇAPANIN diz-korobarasyonu için kalır (find_anchor'ın knee_swing'i,
    her zaman diz — sürücüden BAĞIMSIZ, tasarım gereği). Sürücüye göre seri
    seçimi `_driver_series`'e taşındı (C-207) — bu fonksiyon artık
    `select_by_phase_driver`/`prepare`'in genel dispatch yolunda KULLANILMIYOR."""
    j = joint_series(frames)
    left, right = j.get("left_knee") or [], j.get("right_knee") or []
    out: list[float] = []
    for i in range(min(len(left), len(right))):
        a, b = left[i], right[i]
        out.append(float("nan") if (a != a or b != b) else (a + b) / 2.0)
    return out


def _driver_series(frames, unit: dict) -> list[float]:
    """`unit['_family']`/`unit['_jointRef']`'e göre AÇI SERİSİ — sürücü-göre
    seçimin TEK dispatch noktası (C-207). `kinematic_unit()` bunları ÖNCEDEN
    doğrulamıştır (isimli ret orada olur); burada yeniden doğrulama YOK,
    yalnız okunur — önceki hatanın (select_by_phase_driver + prepare'in
    KOŞULSUZCA diz serisi okuması, sürücü adı ne olursa olsun) yerini alır.
    """
    j = joint_series(frames)
    ref = unit["_jointRef"]
    if unit["_family"] == _FAMILY_FLEXION:
        left, right = j.get(ref[0]) or [], j.get(ref[1]) or []
        out: list[float] = []
        for i in range(min(len(left), len(right))):
            a, b = left[i], right[i]
            out.append(float("nan") if (a != a or b != b) else (a + b) / 2.0)
        return out
    # orientation: TEK adlı seri (bugün yalnız trunk_tilt) — joint_series()
    # çıktısında adıyla doğrudan var.
    return j.get(ref[0]) or []


def select_by_phase_driver(iso, feasible, fps: float, unit: dict) -> tuple:
    """Adayları, ADIMIN BEYAN ETTİĞİ OLAYI içermelerine göre sırala.

    ARAMA UZAYINA DOKUNULMAZ: adaylar yine hareket ∩ kamera-temiz
    kesişiminden gelir. Değişen tek şey, o uzayda hangi pencerenin
    seçildiğidir.

    Neden gerekliydi (ÖLÇÜLDÜ, C-124): eski sıralama `max(periodicity,
    uzunluk)` ile "en kendine-benzer" pencereyi alıyordu ve konuşan bir
    eğitmenin hafif salınımı, dans eden bedenden DAHA düzenlidir.
    `4BRd2E8vBic`'te bu, 193 çöküşlü bir videoda SIFIR çöküşlü bir pencere
    seçtirdi — yani bulucu, aranan olayı içermeyen bir yeri "en iyi" ilan
    etti. Düzenlilik, doğru olayın orada olduğunun kanıtı değildir.

    Periyot da buradan TÜRETİLİR: `çöküş aralığı × beyanEdilenÇöküş/çevrim`.
    Bu, harmonik birim sorusunu inşa gereği çözer — ve meşrudur, çünkü
    birimi CONFIG beyan eder (M-F-231/3), ben "take'ler uyuşsun diye"
    seçmem. Take'ler arası çöküş-periyodu yayılımı TEMPO varyansıdır,
    birim çatışması değil.
    """
    from probe_knee_dips import detect_dips  # noqa: PLC0415  (döngüsel import
    # riski yüzünden TEMBEL: probe_knee_dips -> probe_knee_windows -> bu modül.
    # Çağrı anında bu modül tamamen yüklüdür, o yüzden güvenli.)

    top, rate = _phase_thresholds_from(unit.get("_phases") or [])
    dips_per_cycle = float(unit["dipsPerCycle"])
    scored = []
    for seg, mv in feasible:
        # C-207: sürücünün KENDİ ailesine göre seri — önceden burası
        # KOŞULSUZCA diz serisi okuyordu (unit['driver'] ne olursa olsun).
        # hh_rock'un sürücüsü trunk_tilt; bu yol hiç ölçülmeden hep diz
        # okuyor olabilirdi ve isim etiket kalıp davranışı belirlemezdi.
        rep = detect_dips(_driver_series(iso[seg[0]:seg[1]], unit), fps,
                          top_deg=top, rate_deg_s=rate)
        gap = rep["medianInterDipSeconds"]
        if not rep["dipCount"] or not gap:
            continue                      # aranan olay YOK -> aday değil
        scored.append({
            "seg": seg, "mv": mv, "dips": rep["dipCount"], "gap": gap,
            "periodSeconds": round(gap * dips_per_cycle, 3),
            "topQualified": rep["topQualifiedCount"],
        })
    if not scored:
        return None, None, None
    # Sıralama: önce KANIT MİKTARI (nitelikli çöküş sayısı), sonra uzunluk.
    # Periyodikliğe göre DEĞİL — eski sıralamanın yanıldığı yer tam orasıydı.
    best = max(scored, key=lambda s: (s["dips"], s["seg"][1] - s["seg"][0]))
    return best["seg"], best["mv"], best


def prepare(video_id: str, step: str | None = None) -> dict:
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
    # ADAY ÜRETİMİ de faz-sürücülü olabilir (M-F-235). Sıralamayı düzeltmek
    # yetmedi: `4BRd2E8vBic`'te 896 saniyelik, 193 nitelikli çöküş taşıyan bir
    # derste tüm-vücut pencereleme 5 aday üretti ve dördü o çöküşlerin
    # HİÇBİRİNİ içermiyordu. Tüm-vücut enerjisi "adım oluyor mu"nun VEKİLİDİR
    # ve bounce gibi bedeni yerinde tutan bir adımda vekil adımla anlaşmıyor.
    #
    # C-207: seri artık sürücünün KENDİ ailesinden — önceden bu yorum
    # "rig'e hangi eklem olduğu söylenmez" diyordu ama kod her zaman diz
    # okuyordu; niyet ile davranış AYRIŞMIŞTI ve isim etiket kalıyordu.
    # `kinematic_unit()` artık driver'ı isimli-ret'le doğruluyor, burası
    # yalnız sonucu (`unit['_family']`/`_jointRef`) okuyor.
    unit = kinematic_unit(step)
    if unit:
        cfg_amp = _standing_still_floor(unit)
        moves = find_movement_windows(
            iso, fps=fps, max_windows=40,
            driver_series=_driver_series(iso, unit),
            # Vekil kapı KAPALI: yerine adımın KENDİ "yerinde duruyor"
            # eşiği geçiyor (config'in NO_BOUNCE tanımı), yani daha zayıf
            # değil DAHA DOĞRUDAN bir kapı.
            min_energy_per_s=0.0,
            min_amplitude=cfg_amp)
    else:
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
        feasible = [(seg, best)]

    # FAZ-SÜRÜCÜLÜ SEÇİM (M-F-231). Yalnız adım config'i kinematik bir çevrim
    # birimi BEYAN ediyorsa devreye girer; etmiyorsa yukarıdaki seçim aynen
    # kalır (bit-değişmezlik inşa gereği).
    unit = kinematic_unit(step)
    driver_pick = None
    if unit:
        d_seg, d_best, driver_pick = select_by_phase_driver(iso, feasible,
                                                            fps, unit)
        if driver_pick is None:
            # HİÇBİR aday pencere adımın beyan ettiği olayı içermiyor. Bu
            # "hareket yok" DEĞİL: hareket ve kamera kapıları geçilmiş ama
            # aranan olay hiçbir adayda bulunamamış. İkisini aynı gerekçeye
            # yıkmak, ölçülen arızayı gizler.
            return {"videoId": video_id, "usable": False,
                    "why": (f"aday pencerelerin hiçbirinde nitelikli "
                            f"{unit['driver']} olayı yok (faz-sürücülü seçim)"),
                    "candidateWindows": len(feasible)}
        seg, best = d_seg, d_best

    frames = iso[seg[0]:seg[1]]
    # Periyot: faz-sürücülü seçimde çöküş aralığından TÜRETİLİR
    # (aralık × beyanEdilenÇöküş/çevrim), yoksa hareket penceresinden gelir.
    period_s = driver_pick["periodSeconds"] if driver_pick else best.period_s
    period_frames = max(2, int(round(period_s * fps)))
    signal, axis = leading_foot_signal(frames)
    knee_sig = [((lm[L_KNEE][1] - lm[R_KNEE][1]) / tf[2])
                for lm in frames if (tf := torso_frame(lm))]
    knee_swing = (max(knee_sig) - min(knee_sig)) if knee_sig else None
    vis = ankle_visibility(frames)
    anchor = find_anchor(signal, period_frames, visibility=vis, knee_swing=knee_swing)
    if anchor.get("reanchorOnKnees"):
        knee_series = [((lm[L_KNEE][1] - lm[R_KNEE][1]) / tf[2])
                       for lm in frames if (tf := torso_frame(lm))]
        anchor = find_anchor(knee_series, period_frames)
        anchor["anchorSource"] = "knee"
        axis = "knee_y"
    else:
        anchor["anchorSource"] = "ankle"
    anchor["axis"] = axis
    anchor["ankleVisibility"] = round(vis, 3)
    anchor["kneeSwing"] = round(knee_swing, 4) if knee_swing is not None else None

    out = {
        "videoId": video_id,
        "usable": bool(anchor.get("ok")),
        "why": None if anchor.get("ok") else anchor.get("why"),
        "corePin": CORE_PIN,
        "space": "isotropic-image",
        "aspect": round(aspect, 4),
        "fps": fps,
        "segment": {"startFrame": seg[0], "endFrame": seg[1],
                    "seconds": round((seg[1] - seg[0]) / fps, 2)},
        "periodSeconds": period_s,
        "periodFrames": period_frames,
        # `cycleUnit` AŞAĞIDA, yalnızca faz-sürücülü seçim koştuysa eklenir.
        # Burada `None` olarak yazılamaz: YOK OLAN alan ile NULL olan alan
        # aynı şey değildir — non-kinematik adımların çıktısına null bir
        # anahtar koymak bit-değişmezliği bozar (ölçüldü: regresyon diff'i
        # tam bu tek satırda kırıldı) ve keyset tabanına gerçekte var
        # olmayan bir sözleşme yazar.
        # How many whole cycles the usable segment actually contains. The
        # reference builder takes a per-take median ACROSS these, so a take
        # with three of them is a much weaker vote than one with nine — and
        # nothing downstream could see the difference until it was recorded.
        "cyclesInSegment": max(0, (seg[1] - seg[0] - anchor.get("frameInCycle", 0))
                               // period_frames),
        "periodicity": best.periodicity,
        "motionEnergy": best.motion_energy,
        "anchor": anchor,
        "anchorAxis": anchor.get("axis"),
        "joints": joint_series(frames) if anchor.get("ok") else None,
        "provenance": doc.get("provenance", {}),
    }
    if driver_pick:
        # BEYAN EDİLEN BİRİM görünür olmalı: aşağı akıştaki harmonik kapı
        # oranları buna göre yorumlar (oran≈2,0'ın anlamı beyana bağlıdır —
        # RM dönüşümlü olduğu için orada 2 çöküş/çevrim KANONİKTİR, bounce'ta
        # değildir). Alanın YOKLUĞU "segment eski yolla seçildi" demektir.
        out["cycleUnit"] = {
            "driver": unit["driver"],
            "dipsPerCycle": unit["dipsPerCycle"],
            "dipsInSegment": driver_pick["dips"],
            "medianInterDipSeconds": driver_pick["gap"],
            "topQualifiedDips": driver_pick["topQualified"],
            "selectedBy": "phase-driver",
        }
    return out


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
    ap.add_argument("--video")
    ap.add_argument("--step", help="adım id — config KİNEMATİK çevrim birimi "
                                   "beyan ediyorsa segment seçimi faz-sürücülü "
                                   "olur (M-F-231); yoksa davranış DEĞİŞMEZ")
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
        r = prepare(vid, args.step)
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
        payload = results if len(results) > 1 else results[0]
        Path(args.out).write_text(
            json.dumps(_json_safe(payload), ensure_ascii=False, indent=1,
                      allow_nan=False), encoding="utf-8")
        print(f"yazıldı: {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
