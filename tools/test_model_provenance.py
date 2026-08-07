#!/usr/bin/env python3
"""Does a reference carry the model that measured it? (C-196)

The numbers in a reference — tolerances, disagreement, the noise floor every
verdict is compared against — are a property of the pose model that produced
them. `extract_landmarks.py` has always stamped `model_version` and
`model_sha256` into each fixture. `build_reference.py` read `provenance.channel`
out of those same dictionaries and dropped the model on the floor.

So the information was never missing. It was NOT CARRIED, which looks identical
from downstream and is worse: "unknown" invites a guess, "not carried" invites a
fix, and for six weeks nobody could tell which one they were looking at.
"""

from __future__ import annotations

import sys

from build_reference import model_provenance

FAILURES: list[str] = []


def check(name: str, cond: bool, detail: str = "") -> None:
    if cond:
        print(f"  ✓ {name}")
    else:
        FAILURES.append(f"{name}{': ' + detail if detail else ''}")
        print(f"  ✗ {name}  {detail}")


def main() -> int:
    print("model provenance carry")

    # 1. The normal path: every take measured by the same model, stamp carried.
    out = model_provenance([
        {"provenance": {"modelVersion": "pose_landmarker_full/float16/1",
                        "modelSha256": "abc"}},
        {"provenance": {"modelVersion": "pose_landmarker_full/float16/1",
                        "modelSha256": "abc"}},
    ])
    check("aynı model → taşınıyor",
          out["modelVersion"] == "pose_landmarker_full/float16/1"
          and out["modelSha256"] == "abc", repr(out))

    # 2. Absence stays ABSENT. A plausible default here would make the app's
    #    equality gate pass against a fiction — the worst possible outcome for
    #    a field whose whole job is to catch a mismatch.
    out = model_provenance([{"provenance": {"channel": "someone"}}])
    check("damgasız fixture → None, uydurma YOK",
          out["modelVersion"] is None and out["modelSha256"] is None
          and "why" in out, repr(out))

    # 3. Mixed models are an ERROR, never an average. A reference whose three
    #    instructors were measured by two models has no single meaning, and
    #    blending them would bury the exact defect this field exists to expose.
    try:
        model_provenance([
            {"provenance": {"modelVersion": "pose_landmarker_full/float16/1"}},
            {"provenance": {"modelVersion": "pose_landmarker_heavy/float16/1"}},
        ])
        check("karışık model → HATA", False, "kabul edildi")
    except SystemExit as e:
        check("karışık model → HATA", "DIFFERENT models" in str(e), str(e)[:70])

    # 4. Top-level stamp is read too — the fixture schema has carried it in
    #    both shapes across the pipeline's life, and a reader that knows only
    #    one of them silently sees nothing.
    out = model_provenance([
        {"modelVersion": "pose_landmarker_heavy/float16/1",
         "modelSha256": "64437af8"},
    ])
    check("kök seviyedeki damga da okunuyor",
          out["modelVersion"] == "pose_landmarker_heavy/float16/1", repr(out))

    # 5. Vacuum guard: an empty input must not look like a success.
    out = model_provenance([])
    check("boş girdi sessizce 'tamam' demiyor", out["modelVersion"] is None,
          repr(out))

    print("OK" if not FAILURES else f"FAILED ({len(FAILURES)})")
    for f in FAILURES:
        print(f"  {f}")
    return 1 if FAILURES else 0


if __name__ == "__main__":
    sys.exit(main())
