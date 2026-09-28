"""Check the three silent listening demonstrations before exporting media briefs.

This checks source wording and the production boundary, not musical accuracy.
It uses only the Python standard library and does not generate or download media.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


APP = Path(__file__).resolve().parents[1]
TARGETS = {"so_36", "so_37", "so_38"}
BOUNDARY = {
    "masterAudio": "silent",
    "trackSource": "optional_user_supplied_legally_accessed_separate_player",
    "appProvidesOrRecordsMusic": False,
    "autoSyncToTrack": False,
    "soundObjectiveWithoutTrack": "deferred",
}
LESSON_CUES = {
    "so_36": ("müzikal doğruluğunu", "musical accuracy"),
    "so_37": ("dinleme başarısı", "listening success"),
    "so_38": ("çalgı tanıma", "instrument recognition"),
}
# Exact bilingual scenes independently inspected on 2026-09-28. Required
# phrases alone admit added claims that contradict the silent-media boundary.
# A changed scene needs a new semantic review before its pin is updated.
REVIEWED_SCENE_SHA256 = {
    "so_36": "df2205aee524f9034295a4083541eef191f8b8e3149cdb81fcec8225f3b59c84",
    "so_37": "068d54c421fea9ece2d31394f6ed8989560fa785a52a9a84c262cf4892d9c6d5",
    "so_38": "641de2bf82508ad30c79e46de07ceb37d51da51f374261727db98ae9fd7db4da",
}


def scene_sha256(scenes: dict) -> str:
    canonical = json.dumps(
        scenes, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    )
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def validate(course: dict, schema: dict) -> list[str]:
    errors: list[str] = []
    lessons = course.get("lessons", [])
    if len(lessons) != 48 or [x.get("id") for x in lessons] != [
        f"so_{i:02d}" for i in range(1, 49)
    ]:
        errors.append("Expected the unchanged 48-lesson ID sequence")
        return errors

    properties = schema["$defs"]["media"]["properties"]
    storyboard_schema = properties.get("productionStoryboard", {})
    schema_fields = storyboard_schema.get("properties", {})
    for key, value in BOUNDARY.items():
        if schema_fields.get(key, {}).get("const") != value:
            errors.append(f"Schema must freeze {key}={value!r}")

    for lesson in lessons:
        lesson_id = lesson["id"]
        brief = lesson["mediaBrief"]
        storyboard = brief.get("productionStoryboard")
        if lesson_id not in TARGETS:
            if storyboard is not None:
                errors.append(f"{lesson_id}: unrelated storyboard added")
            continue
        if not isinstance(storyboard, dict):
            errors.append(f"{lesson_id}: missing production storyboard")
            continue
        for key, expected in BOUNDARY.items():
            if storyboard.get(key) != expected:
                errors.append(f"{lesson_id}: {key} does not match silent audio boundary")
        if brief.get("status") != "planned" or "no music" not in brief.get("format", ""):
            errors.append(f"{lesson_id}: demo must remain planned and silent")
        if brief.get("sequence") != lesson.get("teaching") or brief.get("teachingAim") != lesson.get("goal"):
            errors.append(f"{lesson_id}: production brief diverges from live teaching")
        scenes = storyboard.get("scenes", {})
        if not isinstance(scenes, dict):
            errors.append(f"{lesson_id}: missing bilingual scenes")
            continue
        tr, en = scenes.get("tr"), scenes.get("en")
        if not (
            isinstance(tr, list) and isinstance(en, list)
            and len(tr) == len(en) == 4
            and all(isinstance(scene, str) and scene for scene in tr + en)
        ):
            errors.append(f"{lesson_id}: expected four nonempty bilingual scenes")
            continue
        if scene_sha256(scenes) != REVIEWED_SCENE_SHA256[lesson_id]:
            errors.append(
                f"{lesson_id}: scenes changed; bilingual semantic review required before pin update"
            )
        tr_text, en_text = " ".join(tr).lower(), " ".join(en).lower()
        if not ("eşzaman" in tr_text or "senkron" in tr_text):
            errors.append(f"{lesson_id}: storyboard missing Turkish sync limit")
        common = (
            ("ayrı oynatıcı", tr_text),
            ("sonraya bırak", tr_text), ("separate player", en_text),
            ("auto-sync", en_text), ("without a track", en_text),
            ("defer", en_text),
        )
        for phrase, text in common:
            if phrase not in text:
                errors.append(f"{lesson_id}: storyboard missing {phrase!r}")
        for phrase, text in zip(LESSON_CUES[lesson_id], (tr_text, en_text)):
            if phrase not in text:
                errors.append(f"{lesson_id}: missing lesson-specific limit {phrase!r}")
    return errors


def main() -> int:
    course = json.loads((APP / "content/salsa_on1_course.json").read_text())
    schema = json.loads((APP / "docs/schema/salsa-on1-course.schema.json").read_text())
    errors = validate(course, schema)
    for error in errors:
        print(error)
    if errors:
        return 1
    print("PASS: 48 lessons preserved; so_36/37/38 silent listening storyboards and schema aligned")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
