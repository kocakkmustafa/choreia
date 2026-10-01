#!/usr/bin/env python3
"""Idempotently bind narrow teacher references to five Salsa lessons.

Removing this overlay reproduces the old course SHA. No media is fetched.
"""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path
from urllib.parse import urlparse

HERE = Path(__file__).resolve().parent
COURSE = HERE.parent / "content/salsa_on1_course.json"
CONTRACT = HERE / "salsa_source_attribution.v1.json"
EXPECTED_BINDINGS = {
    "so_15": ["addicted2salsa_arm_layering"],
    "so_25": ["ellmann_front_cross"],
    "so_26": ["ellmann_front_cross"],
    "so_28": ["eld_jazz_box_b"],
    "so_34": ["ellmann_pause_hold"],
}
EXPECTED_RESEARCH_DIGESTS = {
    "v8": "ea9ceaae3c29ce25a2d84444255db35172cdc1910864a39285e7b95f7b4c07d2",
    "v10": "85227a37d47c2bab330c86c1ed847f479dd4ffbdd461e70b4c8952086ea0d52b",
    "v10bRepair": "771fa3175a3b1ded850261010c4c3a10b08fee98b0148762081e415567f5889a",
    "v10bIndependentPeer": "fc47f1d6cff73fece24f322e5e5f009f5f1f05a73779dfdf5e13a94a0bc4798a",
}
EXPECTED_SOURCE_RESEARCH = {
    "addicted2salsa_arm_layering": ["v8"],
    "ellmann_front_cross": ["v8"],
    "eld_jazz_box_b": ["v10bRepair", "v10bIndependentPeer"],
    "ellmann_pause_hold": ["v10", "v10bRepair", "v10bIndependentPeer"],
}


def encoded(value: object) -> bytes:
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def render(current: dict, contract: dict) -> bytes:
    if contract["schemaVersion"] != 1 or contract["bindings"] != EXPECTED_BINDINGS:
        raise ValueError("Unexpected salsa attribution contract or bindings")
    if (contract.get("researchDigests") != EXPECTED_RESEARCH_DIGESTS or
            contract.get("sourceResearch") != EXPECTED_SOURCE_RESEARCH):
        raise ValueError("Salsa attribution research provenance drifted")
    sources = contract["sources"]
    source_ids = [source["id"] for source in sources]
    if (source_ids != list(EXPECTED_SOURCE_RESEARCH) or
            {sid for ids in EXPECTED_BINDINGS.values() for sid in ids} != set(source_ids)):
        raise ValueError("Salsa attribution source roster or binding coverage drifted")
    for source in sources:
        url = urlparse(source["url"])
        if url.scheme != "https" or not url.netloc or source["use"] != "referenceOnly":
            raise ValueError("Attribution needs HTTPS referenceOnly source")
        for scope in ("supports", "doesNotSupport"):
            if any(not source[scope][lang].strip() for lang in ("en", "tr")):
                raise ValueError("Attribution scope must be bilingual and nonempty")

    known = set(source_ids)
    base = json.loads(json.dumps(current, ensure_ascii=False))
    base["sources"] = [s for s in base["sources"] if s["id"] not in known]
    lessons = {lesson["id"]: lesson for lesson in base["lessons"]}
    if not set(EXPECTED_BINDINGS).issubset(lessons):
        raise ValueError("Expected lesson missing")
    for lesson in lessons.values():
        lesson["sourceIds"] = [sid for sid in lesson["sourceIds"] if sid not in known]
    base_sha = hashlib.sha256(encoded(base)).hexdigest()
    if base_sha != contract["parentCourseSha256"]:
        raise ValueError(f"Original salsa lesson body/source baseline drifted: {base_sha}")

    base["sources"].extend(sources)
    for lesson_id, ids in EXPECTED_BINDINGS.items():
        lessons[lesson_id]["sourceIds"].extend(ids)
    for lesson_id in contract["excludedLessonIds"]:
        if known.intersection(lessons[lesson_id]["sourceIds"]):
            raise ValueError(f"Excluded lesson gained attribution: {lesson_id}")
    return encoded(base)


def main() -> None:
    if sys.argv[1:] not in (["--write"], ["--check"]):
        raise SystemExit("Use --write or --check")
    contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
    current_bytes = COURSE.read_bytes()
    expected = render(json.loads(current_bytes), contract)
    if sys.argv[1] == "--check":
        if current_bytes != expected:
            raise SystemExit("Salsa source attribution JSON is out of date")
        print(f"Verified {COURSE} ({hashlib.sha256(expected).hexdigest()})")
    else:
        COURSE.write_bytes(expected)
        print(f"Wrote {COURSE} ({hashlib.sha256(expected).hexdigest()})")


if __name__ == "__main__":
    main()
