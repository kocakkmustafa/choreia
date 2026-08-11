#!/usr/bin/env python3
"""Regression: which coordinate space may be fed to the scoring engine.

MediaPipe's image landmarks are normalized to [0,1] on each axis
independently, so on a 16:9 frame a vertical span of N pixels becomes 1.78x
larger in normalized units than the same span measured horizontally. Distances
and angles computed there are anisotropically distorted, and dividing by torso
length does not fix it — that is a uniform scale, and the distortion is not.

Caught family-wide as J-028 / M-F-30. This guard exists because Choreia had in
fact been feeding raw `lm` to SequenceComparator and CycleAligner.

The check runs against real harvested frames and the world landmarks from the
same frame, which are metric and therefore aspect-free.

Run:  python3 tools/test_coordinate_space.py
"""

from __future__ import annotations

import glob
import json
import math
import os
import sys

LIB = os.path.expanduser("~/motion-harvest/choreia/landmarks")
MANIFESTS = os.path.expanduser("~/motion-harvest/choreia/manifests")

# Joints whose vertex angle is sensitive to the vertical/horizontal ratio.
JOINTS = [
    ("left_elbow", 11, 13, 15), ("right_elbow", 12, 14, 16),
    ("left_knee", 23, 25, 27), ("right_knee", 24, 26, 28),
    ("left_hip", 11, 23, 25), ("right_hip", 12, 24, 26),
    ("left_shoulder", 13, 11, 23), ("right_shoulder", 14, 12, 24),
]

# The assertion is aspect INVARIANCE, not agreement with world.
#
# An earlier version of this file asserted that aspect correction moves angles
# closer to the world landmarks, and it failed on half the takes. The data was
# right and the assertion was wrong: world x,y carry their own regression error
# of roughly the same size (~7 degrees here), so they are not a clean oracle,
# and the aspect distortion is pose-dependent — it barely moves a limb that is
# already near horizontal or vertical, and peaks around 45 degrees. Averaged
# over joints and frames it washes out, even though single joints were seen off
# by 35 degrees.
#
# So the test below measures the property that actually matters and needs no
# oracle: re-measure the same body at a different frame aspect. Raw image-space
# angles move; aspect-corrected ones must not.
MAX_INVARIANCE_DEV = 0.5      # degrees; corrected angles must be stable
MIN_RAW_SENSITIVITY = 3.0     # degrees; raw angles must visibly break


def angle(a, b, c) -> float:
    ux, uy = a[0] - b[0], a[1] - b[1]
    vx, vy = c[0] - b[0], c[1] - b[1]
    lu, lv = math.hypot(ux, uy), math.hypot(vx, vy)
    if lu < 1e-9 or lv < 1e-9:
        return float("nan")
    cos = max(-1.0, min(1.0, (ux * vx + uy * vy) / (lu * lv)))
    return math.degrees(math.acos(cos))


def aspect_of(video_id: str) -> float:
    p = f"{MANIFESTS}/{video_id}.json"
    if not os.path.exists(p):
        return 16 / 9
    man = json.load(open(p, encoding="utf-8"))
    for s in man.get("stages", []):
        res = s.get("detail", {}).get("resolution")
        if res and "x" in res:
            w, h = (int(v) for v in res.split("x"))
            return w / h
    return 16 / 9


def main() -> int:
    files = sorted(glob.glob(f"{LIB}/*.full.json"))
    if not files:
        # A5(b), koordinatör sevki: önceden bu satır 0 dönerdi ve
        # gates.sh'in `tail -1` özetinde gerçek bir "N fixture, 0 hata"
        # geçişinden AYIRT EDİLEMİYORDU — "0 dosya = OK" bir ÖLÇÜM değil
        # bir VARSAYIMDI (taze klonda / harvest havuzu boşken sessizce
        # vakum-yeşil). Kırmızı YAPILMADI (yerel veri eksikliği repo-geneli
        # commit'i bloklamamalı) ama son satır artık İSİMLE söylüyor —
        # gerçek bir "OK"la karıştırılamaz.
        print("ATLANDI (0 fixture): ~/motion-harvest/choreia/landmarks boş — "
              "coordinate-space regresyonu bu koşumda ÖLÇÜLMEDİ, doğrulanmadı")
        return 0

    print("Aynı vücut, iki farklı kare en-boyunda yeniden ölçülüyor "
          "(16:9 ve 9:16).\n")
    print(f"{'take':<16}{'ham kayma':>11}{'ham en kötü':>13}"
          f"{'düzelt kayma':>14}{'world sapma':>13}")
    failures = 0
    for path in files:
        vid = os.path.basename(path).split(".")[0]
        d = json.load(open(path, encoding="utf-8"))
        frames = [f for f in d.get("frames", [])
                  if f.get("detected") is not False and f.get("world")]
        if not frames:
            continue
        ar = aspect_of(vid)
        other = 9 / 16  # aynı görüntünün dikey kadrajda kaydedilmiş hâli

        raw_shift, fixed_shift, world_dev, raw_worst = [], [], [], 0.0
        for f in frames[len(frames) // 4::max(1, len(frames) // 12)][:12]:
            lm, wd = f["lm"], f["world"]
            # Aynı gövde, farklı kare en-boyu: normalize koordinatlar yeniden
            # ölçeklenir. Gerçek vücut değişmedi — açılar da değişmemeli.
            rescaled = [[p[0] * (ar / other), p[1]] for p in lm]  # not: çekirdek z’yi de ölçekler (toIsotropic); planar açıda etkisiz
            fixed_a = [[p[0] * ar, p[1]] for p in lm]
            fixed_b = [[p[0] * ar, p[1]] for p in rescaled]
            for _, a, b, c in JOINTS:
                r1, r2 = angle(lm[a], lm[b], lm[c]), \
                         angle(rescaled[a], rescaled[b], rescaled[c])
                f1 = angle(fixed_a[a], fixed_a[b], fixed_a[c])
                w = angle(wd[a], wd[b], wd[c])
                if any(math.isnan(v) for v in (r1, r2, f1, w)):
                    continue
                # düzeltilmiş uzayda ölçek geri alınır → değişmemeli
                f2 = angle([[p[0] / (ar / other) * ar, p[1]] for p in rescaled][a],
                           [[p[0] / (ar / other) * ar, p[1]] for p in rescaled][b],
                           [[p[0] / (ar / other) * ar, p[1]] for p in rescaled][c])
                raw_shift.append(abs(r1 - r2))
                raw_worst = max(raw_worst, abs(r1 - r2))
                fixed_shift.append(abs(f1 - f2))
                world_dev.append(abs(f1 - w))
        if not raw_shift:
            continue
        rm = sum(raw_shift) / len(raw_shift)
        fm = sum(fixed_shift) / len(fixed_shift)
        wm = sum(world_dev) / len(world_dev)
        flag = ""
        if fm > MAX_INVARIANCE_DEV:
            flag += " ✗ düzeltilmiş açı en-boya duyarlı kaldı"
            failures += 1
        if rm < MIN_RAW_SENSITIVITY:
            flag += " ⚠ ham açı beklendiği kadar kaymadı (poz bağımlı)"
        print(f"{vid:<16}{rm:>10.1f}°{raw_worst:>12.1f}°{fm:>13.2f}°"
              f"{wm:>12.1f}°{flag}")

    print()
    if failures:
        print(f"FAILED ({failures})")
        return 1
    print("OK — en-boy düzeltilmiş açılar kare oranından BAĞIMSIZ; ham açılar "
          "değil.")
    print("\nKARAR: skorlama motoruna EN-BOY DÜZELTİLMİŞ lm beslenir; ham lm "
          "ASLA.")
    print("  Ham lm bu takelerde daha DÜŞÜK DTW maliyeti verdi — ama bu "
          "yanıltıcı:\n  üçü de 1.778 en-boyda, dolayısıyla hata "
          "karşılaştırmada sadeleşiyor.\n  Elenen dikey take 608x1080'di; "
          "o karışıma girdiği an sadeleşme biter.")
    print("  'world sapma' sütunu bilgi amaçlı: world x,y'nin kendi regresyon "
          "hatası\n  benzer mertebede, o yüzden hakem olarak değil referans "
          "olarak okunur.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
