#!/usr/bin/env python3
"""Rebuild Choreia's closed, source-only v2m QA catalog (ops K-4 revision)."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


APP = Path(__file__).resolve().parents[1]
ROOT = APP.parents[2]
CONTRACT = ROOT / "ops/tools/motion_courses/contracts/v2m"
SOURCE = CONTRACT / "source_pins_v1/source-pins.json"
MANIFEST = CONTRACT / "production-manifest.json"
COURSE = APP / "content/salsa_on1_course.json"
OUTPUT = APP / "content/motion_content/choreia_source_pins_v2m.json"
SOURCE_SHA = "cdafd13eafa7eddc3735b288fdd14cf3ea8b312831d1fab1a7351ecd55c1cbb2"
MANIFEST_SHA = "c551d6c91bef39e677f54059b214157aa8d3d253f9c086bfceb21a12c7e52a80"
PROOF_SHA = "8f108c547afedfdeeb8cfdb79f5a4f911d035ec664f80170a4306a87a81ba987"
COURSE_SHA = "284d429656ec8ca56fd10674685cf61069d157a6ee985eb764818ae9db11907d"
OUTPUT_SHA = "fc6e9c0e4a2132877bbf4313e96acb620a7cdf59edf647e642c0c3ab3a1526d1"


def require(ok: bool, message: str) -> None:
    if not ok:
        raise ValueError(message)


def sha(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def canonical(value: object) -> bytes:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()


def read_exact(path: Path, expected: str) -> bytes:
    require(path.is_file() and not path.is_symlink(), f"missing or symlinked input: {path}")
    raw = path.read_bytes()
    require(sha(raw) == expected, f"SHA drift: {path}")
    return raw


def identity(catalog: dict, lesson: dict, scene: dict, variant: dict) -> dict:
    return {
        "manifestSHA256": catalog["manifestSHA256"],
        "app": lesson["app"],
        "courseSourceSHA256": lesson["courseSourceSHA256"],
        "lessonId": lesson["lessonId"],
        "lessonCanonicalSHA256": lesson["lessonCanonicalSHA256"],
        "assetId": lesson["assetId"],
        "sceneId": scene["sceneId"],
        "variantStem": variant["stem"],
        "productionSpecSHA256": scene["productionSpecSHA256"],
        "sourceCueSHA256": scene["sourceCueSHA256"],
        "idempotencyKey": scene["idempotencyKey"],
        "productionState": scene["productionState"],
    }


def projection_bytes() -> bytes:
    catalog = json.loads(read_exact(SOURCE, SOURCE_SHA))
    manifest = json.loads(read_exact(MANIFEST, MANIFEST_SHA))
    read_exact(COURSE, COURSE_SHA)
    require(catalog["kind"] == "MOTION_MEDIA_V2M_SOURCE_PINS_V1"
            and catalog["state"] == "CLOSED_PREPRODUCTION_SOURCE_MEMBERSHIP_ONLY"
            and catalog["manifestSHA256"] == MANIFEST_SHA
            and catalog["sourceProofSHA256"] == PROOF_SHA
            and catalog["pinIdentityManifestSHA256ByApp"]["choreia"] == MANIFEST_SHA
            and catalog["visible"] is False and catalog["releaseEligible"] is False
            and catalog["progressEffect"] == 0 and catalog["approvedProductionTrustRoot"] is False
            and catalog["counts"]["variants"] == 2456
            and catalog["counts"]["generatedMedia"] == catalog["counts"]["qualifiedMedia"] == 0,
            "global v2m closed catalog drift")
    require(manifest["sourceProofReceiptSHA256"] == PROOF_SHA
            and manifest["releaseEligible"] is False
            and manifest["contractRevision"]["revisedApp"] == "choreia"
            and manifest["courseSourcePins"] == catalog["courseSourcePins"], "manifest/proof/course link")
    require(catalog["courseSourcePins"]["choreia"] == {
        "path": "ventures/choreia/app/content/salsa_on1_course.json", "sha256": COURSE_SHA,
    }, "live Choreia course pin")
    lessons = [r for r in catalog["lessons"] if r["app"] == "choreia"]
    require(len(lessons) == len({r["lessonId"] for r in lessons}) == 48, "Choreia lesson set")
    scenes: set[str] = set()
    stems: set[str] = set()
    pins: set[str] = set()
    for lesson in lessons:
        require(lesson["membershipStatus"] == "SOURCE_PINNED_TEST_ONLY"
                and lesson["courseSourceSHA256"] == COURSE_SHA, "Choreia lesson policy")
        for scene in lesson["scenes"]:
            require(scene["sceneId"] not in scenes
                    and scene["productionState"] == "PREPRODUCTION_UNGENERATED", "Choreia scene policy")
            scenes.add(scene["sceneId"])
            for variant in scene["variants"]:
                pin = sha(canonical(identity(catalog, lesson, scene, variant)))
                require(variant["stem"] not in stems and pin not in pins
                        and variant["sourcePinSHA256"] == pin, "Choreia source pin identity")
                stems.add(variant["stem"])
                pins.add(pin)
    require(len(scenes) == 436 and len(stems) == len(pins) == 872
            and not any(h["app"] == "choreia" for h in catalog["holds"]), "Choreia 436/872/no HOLD")
    projection = {
        "schemaVersion": 1,
        "kind": "CHOREIA_V2M_SOURCE_PINS_QA_ONLY",
        "sourceCatalogSHA256": SOURCE_SHA,
        "manifestSHA256": MANIFEST_SHA,
        "sourceProofSHA256": PROOF_SHA,
        "courseSourceSHA256": COURSE_SHA,
        "counts": {"lessons": 48, "scenes": 436, "variants": 872,
                   "generatedMedia": 0, "qualifiedMedia": 0},
        "lessons": lessons,
        "visible": False,
        "releaseEligible": False,
        "progressEffect": 0,
    }
    return (json.dumps(projection, ensure_ascii=False, sort_keys=True, indent=2) + "\n").encode()


def expected_bytes() -> bytes:
    raw = projection_bytes()
    require(sha(raw) == OUTPUT_SHA, "Choreia projection SHA drift")
    return raw


def main() -> None:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true")
    mode.add_argument("--check", action="store_true")
    args = parser.parse_args()
    raw = expected_bytes()
    if args.write:
        require(not OUTPUT.exists(), "versioned output exists; use --check")
        OUTPUT.write_bytes(raw)
    else:
        require(OUTPUT.is_file() and not OUTPUT.is_symlink() and OUTPUT.read_bytes() == raw,
                "Choreia app projection output drift")
    print("PASS_CHOREIA_V2M_CLOSED_QA_48_436_872")


if __name__ == "__main__":
    main()
