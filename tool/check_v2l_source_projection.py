#!/usr/bin/env python3
"""Check Choreia's frozen, source-only v2l assets without workspace ops.

The projection is QA/source identity data, not a media or release trust root.
Both JSON assets are versioned and deliberately have no write mode.
"""

from __future__ import annotations

import argparse
from contextlib import ExitStack
import hashlib
import json
import os
import re
import stat
from pathlib import Path


APP = Path(__file__).resolve().parents[1]
SLICE = APP / "content/motion_content/choreia.source-slice.v1.json"
PROJECTION = APP / "content/motion_content/choreia.source-projection.v1.json"
COURSE = APP / "content/salsa_on1_course.json"

# App-local text-revision byte-evidence pins; SDK/source acceptance pending.
# Historical opaque refs stay unresolved; no media/model/physical approval follows.
SLICE_SHA256 = "a0b73771ef94639988c83ced2621338ccc12b75204e876216bf71f4a2e0c698d"
PROJECTION_SHA256 = "7f41392feb363e27902d6061e4ba99c58ef10823e6f4e35e0b0f17f5639046b3"
COURSE_SHA256 = "284d429656ec8ca56fd10674685cf61069d157a6ee985eb764818ae9db11907d"
CATALOG_SHA256 = "6a1a1ebf201b05e72562b447373a907639896e2327d1d2c1eef9f8c6c44fc54f"
MANIFEST_SHA256 = "ef6eaa2ba38d0b3abdc7300e6bbf7af419ec9484c1fbd7dca8de174ddadb0adc"
PROOF_SHA256 = "1e461b23043b30fbae0c2cfc326d93b0252370d7fc4204b82ae7c55b64682824"
COUNTS = (48, 436, 872, 0)  # lessons, scenes, variants, HOLDs
MAX_SLICE_BYTES = 2 * 1024 * 1024
MAX_PROJECTION_BYTES = 2 * 1024 * 1024  # Core decoder's size ceiling
MAX_COURSE_BYTES = 2 * 1024 * 1024


class SourceProjectionError(ValueError):
    pass


def require(condition: bool, code: str) -> None:
    if not condition:
        raise SourceProjectionError(code)


def sha(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def canonical(value: object) -> bytes:
    return json.dumps(value, ensure_ascii=False, sort_keys=True,
                      separators=(",", ":"), allow_nan=False).encode("utf-8")


def parse(raw: bytes, code: str) -> object:
    try:
        return json.loads(raw)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise SourceProjectionError(code) from exc


def exact_fields(value: object, fields: set[str], code: str) -> None:
    require(type(value) is dict and set(value) == fields, code)


def hex64(value: object) -> bool:
    return isinstance(value, str) and re.fullmatch(r"[0-9a-f]{64}", value) is not None


def build_projection(source: object, course: object) -> bytes:
    """Rebuild sorted rows from the slice's scene order and the live course."""
    exact_fields(source, {
        "schemaVersion", "kind", "appId", "sourceCatalogSHA256",
        "sourceManifestSHA256", "sourceProofSHA256", "courseSourceSHA256",
        "lessons", "holds",
    }, "SLICE_SCHEMA")
    require(type(source["schemaVersion"]) is int and source["schemaVersion"] == 1
            and source["kind"] == "MOTION_V2L_APP_SOURCE_SLICE_V1"
            and source["appId"] == "choreia"
            and source["sourceCatalogSHA256"] == CATALOG_SHA256
            and source["sourceManifestSHA256"] == MANIFEST_SHA256
            and source["sourceProofSHA256"] == PROOF_SHA256
            and source["courseSourceSHA256"] == COURSE_SHA256,
            "SLICE_IDENTITY")
    require(type(source["holds"]) is list and source["holds"] == [], "SOURCE_HOLD")
    require(type(course) is dict and type(course.get("lessons")) is list
            and len(course["lessons"]) == COUNTS[0], "COURSE_LESSONS")
    require(type(source["lessons"]) is list and len(source["lessons"]) == COUNTS[0],
            "SLICE_LESSONS")

    course_ids = []
    for lesson in course["lessons"]:
        require(type(lesson) is dict and type(lesson.get("id")) is str,
                "COURSE_LESSON_SCHEMA")
        course_ids.append(lesson["id"])
    require(len(set(course_ids)) == COUNTS[0], "COURSE_LESSON_DUPLICATE")

    lesson_ids: set[str] = set()
    scene_ids: set[str] = set()
    variant_pins: set[str] = set()
    variant_stems: set[str] = set()
    rows: list[list[object]] = []
    for index, lesson in enumerate(source["lessons"]):
        exact_fields(lesson, {
            "app", "assetId", "courseSourceSHA256", "lessonCanonicalSHA256",
            "lessonId", "membershipStatus", "scenes",
        }, "LESSON_SCHEMA")
        lesson_id = lesson["lessonId"]
        require(type(lesson_id) is str and lesson_id == course_ids[index]
                and lesson_id not in lesson_ids, "LESSON_ORDER_OR_DUPLICATE")
        lesson_ids.add(lesson_id)
        require(lesson["app"] == "choreia"
                and type(lesson["assetId"]) is str
                and lesson["courseSourceSHA256"] == COURSE_SHA256
                and lesson["membershipStatus"] == "SOURCE_PINNED_TEST_ONLY",
                "LESSON_SOURCE_POLICY")
        require(lesson["lessonCanonicalSHA256"] == sha(canonical(course["lessons"][index])),
                "LESSON_CANONICAL_DRIFT")
        require(type(lesson["scenes"]) is list and bool(lesson["scenes"]),
                "LESSON_SCENES")
        for scene_order, scene in enumerate(lesson["scenes"]):
            exact_fields(scene, {
                "sceneId", "productionSpecSHA256", "sourceCueSHA256",
                "idempotencyKey", "productionState", "variants",
            }, "SCENE_SCHEMA")
            scene_id = scene["sceneId"]
            require(type(scene_id) is str and scene_id.startswith(f"choreia:{lesson_id}:")
                    and scene_id not in scene_ids, "SCENE_ID_OR_DUPLICATE")
            scene_ids.add(scene_id)
            require(hex64(scene["productionSpecSHA256"])
                    and hex64(scene["sourceCueSHA256"])
                    and scene["idempotencyKey"] ==
                    f'motion-media-v1:{scene["productionSpecSHA256"]}'
                    and scene["productionState"] == "PREPRODUCTION_UNGENERATED",
                    "SCENE_SOURCE_POLICY")
            require(type(scene["variants"]) is list and bool(scene["variants"]),
                    "SCENE_VARIANTS")
            for variant in scene["variants"]:
                exact_fields(variant, {"sourcePinSHA256", "stem"}, "VARIANT_SCHEMA")
                pin, stem = variant["sourcePinSHA256"], variant["stem"]
                require(hex64(pin) and type(stem) is str and bool(stem)
                        and pin not in variant_pins and stem not in variant_stems,
                        "VARIANT_ID_OR_DUPLICATE")
                variant_pins.add(pin)
                variant_stems.add(stem)
                identity = {
                    "manifestSHA256": MANIFEST_SHA256,
                    "app": "choreia",
                    "courseSourceSHA256": COURSE_SHA256,
                    "lessonId": lesson_id,
                    "lessonCanonicalSHA256": lesson["lessonCanonicalSHA256"],
                    "assetId": lesson["assetId"],
                    "sceneId": scene_id,
                    "variantStem": stem,
                    "productionSpecSHA256": scene["productionSpecSHA256"],
                    "sourceCueSHA256": scene["sourceCueSHA256"],
                    "idempotencyKey": scene["idempotencyKey"],
                    "productionState": scene["productionState"],
                }
                require(pin == sha(canonical(identity)), "VARIANT_SOURCE_PIN_DRIFT")
                rows.append([
                    pin, lesson_id, lesson["assetId"], scene_id, scene_order,
                    stem, lesson["lessonCanonicalSHA256"],
                    scene["productionSpecSHA256"], scene["sourceCueSHA256"],
                    scene["idempotencyKey"], False,
                ])

    require((len(lesson_ids), len(scene_ids), len(rows), len(source["holds"])) == COUNTS,
            "SOURCE_COUNTS")
    rows.sort(key=lambda row: row[0])
    projection = {
        "schemaVersion": 1,
        "kind": "MOTION_V2L_APP_SOURCE_PROJECTION_V1",
        "appId": "choreia",
        "sourceCatalogSHA256": CATALOG_SHA256,
        "sourceManifestSHA256": MANIFEST_SHA256,
        "courseSourceSHA256": COURSE_SHA256,
        "rows": rows,
    }
    raw = canonical(projection)
    require(len(raw) <= MAX_PROJECTION_BYTES, "PROJECTION_TOO_LARGE")
    return raw


def verify_raws(slice_raw: bytes, projection_raw: bytes, course_raw: bytes) -> None:
    require(sha(slice_raw) == SLICE_SHA256, "SLICE_SHA_DRIFT")
    require(sha(projection_raw) == PROJECTION_SHA256, "PROJECTION_SHA_DRIFT")
    require(sha(course_raw) == COURSE_SHA256, "COURSE_SHA_DRIFT")
    source = parse(slice_raw, "SLICE_JSON")
    projection = parse(projection_raw, "PROJECTION_JSON")
    course = parse(course_raw, "COURSE_JSON")
    require(canonical(source) == slice_raw, "SLICE_NOT_CANONICAL")
    require(canonical(projection) == projection_raw, "PROJECTION_NOT_CANONICAL")
    verify_semantics(source, course, projection_raw)


def verify_semantics(source: object, course: object, projection_raw: bytes) -> None:
    require(build_projection(source, course) == projection_raw, "PROJECTION_REBUILD_DRIFT")


def read_local(path: Path, limit: int) -> bytes:
    # relative_to is lexical: resolving the path here would already follow an
    # intermediate symlink. Every component after the trusted app root is
    # opened from the preceding directory FD without following symlinks.
    try:
        parts = path.relative_to(APP).parts
    except ValueError as exc:
        raise SourceProjectionError("LOCAL_ASSET_OUTSIDE_APP") from exc
    require(bool(parts) and all(part not in ("", ".", "..") for part in parts),
            "LOCAL_ASSET_PATH")
    directory_flags = os.O_RDONLY | os.O_CLOEXEC | os.O_DIRECTORY | os.O_NOFOLLOW
    leaf_flags = os.O_RDONLY | os.O_CLOEXEC | os.O_NOFOLLOW
    try:
        with ExitStack() as stack:
            directory_fd = os.open(APP, directory_flags)
            stack.callback(os.close, directory_fd)
            require(stat.S_ISDIR(os.fstat(directory_fd).st_mode), "LOCAL_ASSET_UNSAFE")
            for component in parts[:-1]:
                directory_fd = os.open(component, directory_flags, dir_fd=directory_fd)
                stack.callback(os.close, directory_fd)
                require(stat.S_ISDIR(os.fstat(directory_fd).st_mode), "LOCAL_ASSET_UNSAFE")

            leaf_fd = os.open(parts[-1], leaf_flags, dir_fd=directory_fd)
            stack.callback(os.close, leaf_fd)
            opened = os.fstat(leaf_fd)
            require(stat.S_ISREG(opened.st_mode), "LOCAL_ASSET_UNSAFE")
            require(0 < opened.st_size <= limit, "LOCAL_ASSET_SIZE")

            # Read at most the opened size plus one byte. A short read, growth,
            # or changed final size fails; content SHA pins catch same-size edits.
            chunks: list[bytes] = []
            remaining = opened.st_size + 1
            while remaining:
                chunk = os.read(leaf_fd, min(remaining, 64 * 1024))
                if not chunk:
                    break
                chunks.append(chunk)
                remaining -= len(chunk)
            raw = b"".join(chunks)
            require(len(raw) == opened.st_size and
                    os.fstat(leaf_fd).st_size == opened.st_size,
                    "LOCAL_ASSET_CHANGED_DURING_READ")
            return raw
    except OSError as exc:
        raise SourceProjectionError("LOCAL_ASSET_UNSAFE") from exc


def check_local_assets() -> None:
    verify_raws(read_local(SLICE, MAX_SLICE_BYTES),
                read_local(PROJECTION, MAX_PROJECTION_BYTES),
                read_local(COURSE, MAX_COURSE_BYTES))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", required=True)
    parser.parse_args()
    check_local_assets()
    print("PASS_CHOREIA_V2L_SOURCE_ONLY_48_436_872_0_HOLD")


if __name__ == "__main__":
    main()
