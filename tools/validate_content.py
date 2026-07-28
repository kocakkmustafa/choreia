#!/usr/bin/env python3
"""Validates Choreia content packs against the engine's contracts.

Content is versioned JSON that the engine interprets at runtime (plan §7), which
means a typo in a joint id is not a compile error — it is a step that silently
scores nothing. This script is the compile step content never had.

The joint vocabulary is read out of a PINNED motion_core tag rather than
duplicated here, so the two cannot drift apart and neither can a neighbouring
session's checkout change this script's verdict. motion_core is READ-ONLY for
this repo (family decision M-F-03): its maintenance belongs to the coordinator
session, and Choreia reports needs as M-C-* records instead of editing it.
Bumping CORE_PIN is a deliberate act: semver + DEFTER entry.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
CONTENT = REPO / "content" / "styles"
CORE_REPO = REPO.parents[1] / "motion-core" / "lib"

# Content is validated against a PINNED core version, never against whatever
# branch happens to be checked out next door. motion-core is a shared repo with
# several sessions working in it; reading its working tree would mean this
# script's verdict silently changed with someone else's checkout.
CORE_PIN = "motion_core-v0.3.0"
CORE_JOINTS_PATH = "packages/motion_core/lib/src/geometry/joint_angles.dart"

SUPPORTED_SCHEMA = 1
MIN_REFERENCE_TAKES = 3  # catalogue §6.0
VALID_TIERS = {"A", "B", "C"}
VALID_SEVERITIES = {"safety", "critical", "major", "minor", "info"}


def core_joint_ids() -> set[str]:
    """Joint ids declared in the pinned motion_core's StandardJoints."""
    import subprocess

    r = subprocess.run(
        ["git", "-C", str(CORE_REPO), "show", f"{CORE_PIN}:{CORE_JOINTS_PATH}"],
        capture_output=True, text=True,
    )
    if r.returncode != 0:
        raise SystemExit(
            f"pinned core {CORE_PIN} not readable from {CORE_REPO}\n"
            f"  {r.stderr.strip()[:200]}\n"
            "  fetch tags, or bump CORE_PIN deliberately (semver + DEFTER)."
        )
    return set(re.findall(r"id:\s*'([a-z_]+)'", r.stdout))


class Report:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []
        self.checked = 0

    def error(self, where: str, msg: str) -> None:
        self.errors.append(f"{where}: {msg}")

    def warn(self, where: str, msg: str) -> None:
        self.warnings.append(f"{where}: {msg}")


def validate_step(path: Path, joints: set[str], rep: Report) -> dict:
    where = path.relative_to(REPO).as_posix()
    step = json.loads(path.read_text(encoding="utf-8"))
    rep.checked += 1

    if step.get("schemaVersion") != SUPPORTED_SCHEMA:
        rep.error(where, f"schemaVersion {step.get('schemaVersion')} unsupported")

    if step.get("id") != path.stem:
        rep.error(where, f"id '{step.get('id')}' does not match filename")

    beats = step.get("beats")
    labels = step.get("countLabels", [])
    if not isinstance(beats, int) or beats < 1:
        rep.error(where, "beats must be a positive integer")
    elif len(labels) != beats:
        rep.error(where, f"countLabels has {len(labels)} entries for {beats} beats")

    tier = step.get("measurability", {}).get("tier")
    if tier not in VALID_TIERS:
        rep.error(where, f"measurability.tier '{tier}' invalid")
    if tier and not step.get("measurability", {}).get("rationale"):
        rep.error(where, "measurability.rationale is required — a tier without a "
                         "reason is an opinion, not a gate")

    scoring = step.get("scoring", {})
    focus = set(scoring.get("focusJoints", []))
    free = set(scoring.get("freeJoints", []))
    if not focus:
        rep.error(where, "scoring.focusJoints is empty — the step scores nothing")
    for j in sorted(focus | free):
        if j not in joints:
            rep.error(where, f"unknown joint id '{j}' (not in StandardJoints)")
    overlap = focus & free
    if overlap:
        rep.error(where, f"joints both scored and free: {sorted(overlap)}")
    if free and not scoring.get("freeJointsRationale"):
        rep.warn(where, "freeJoints declared without a rationale — say why a "
                        "joint is deliberately unscored")

    phase_ids = [p.get("id") for p in step.get("phases", [])]
    if not phase_ids:
        rep.error(where, "no phases declared")
    if len(set(phase_ids)) != len(phase_ids):
        rep.error(where, "duplicate phase ids")
    for p in step.get("phases", []):
        if "enter" not in p:
            rep.error(where, f"phase '{p.get('id')}' has no enter condition")
        if not p.get("requiredLandmarks"):
            rep.warn(where, f"phase '{p.get('id')}' declares no requiredLandmarks "
                            "— gating falls back to the full body")

    moments = step.get("scoredMoments", [])
    if not moments:
        rep.warn(where, "no scoredMoments — this step cannot be timed")
    for m in moments:
        if m.get("phase") not in phase_ids:
            rep.error(where, f"scoredMoment '{m.get('id')}' references unknown "
                             f"phase '{m.get('phase')}'")
        beat = m.get("beat")
        if isinstance(beats, int) and not (isinstance(beat, int) and 0 <= beat < beats):
            rep.error(where, f"scoredMoment '{m.get('id')}' beat {beat} outside "
                             f"[0, {beats})")

    codes = [e.get("code") for e in step.get("errors", [])]
    if len(set(codes)) != len(codes):
        rep.error(where, "duplicate error codes")
    for e in step.get("errors", []):
        if not e.get("detect"):
            rep.error(where, f"error '{e.get('code')}' has no detect condition — "
                             "every error must bind to something measurable")
        if e.get("severity") not in VALID_SEVERITIES:
            rep.error(where, f"error '{e.get('code')}' severity "
                             f"'{e.get('severity')}' invalid")
        for mid in e.get("detect", {}).get("atMoments", []) or []:
            if mid not in [m.get("id") for m in moments] + phase_ids:
                rep.error(where, f"error '{e.get('code')}' references unknown "
                                 f"moment/phase '{mid}'")

    ref = step.get("reference", {})
    if ref.get("requiredTakes", 0) < MIN_REFERENCE_TAKES:
        rep.error(where, f"reference.requiredTakes must be >= {MIN_REFERENCE_TAKES} "
                         "(catalogue §6.0: a single video cannot resolve mirroring "
                         "and cannot yield a tolerance)")

    return step


def validate_style(path: Path, steps: dict[str, dict], rep: Report) -> None:
    where = path.relative_to(REPO).as_posix()
    style = json.loads(path.read_text(encoding="utf-8"))
    rep.checked += 1

    if style.get("schemaVersion") != SUPPORTED_SCHEMA:
        rep.error(where, "unsupported schemaVersion")
    if style.get("id") != path.parent.name:
        rep.error(where, "id does not match directory name")

    rng = style.get("bpmRange")
    if rng is None:
        # A null range is tolerated only when it is an explicit, documented
        # dispute. Working with a known-unknown is fine; shipping one is not,
        # so this stays visible on every run instead of quietly passing.
        if style.get("bpmStatus", "").startswith("DISPUTED"):
            rep.warn(where, "bpmRange is unresolved (DISPUTED) — no lesson in "
                            "this style may ship until a measurement settles it")
        else:
            rep.error(where, "bpmRange missing and no bpmStatus explains why")
    elif not isinstance(rng, list) or len(rng) != 2 or rng[0] >= rng[1]:
        rep.error(where, f"bpmRange {rng} invalid")

    for lvl in style.get("levels", []):
        rule = lvl.get("unlockRule", {})
        if not rule.get("description"):
            rep.error(where, f"level {lvl.get('level')} has no unlockRule — "
                             "completing a lesson must not be what unlocks the next")
        if rule.get("thresholdsCalibrated") is not False and \
                rule.get("thresholdsCalibrated") is not True:
            rep.error(where, f"level {lvl.get('level')} unlockRule must state "
                             "thresholdsCalibrated explicitly (family rule M-F-04)")

    # Tier C must never reach a learner.
    excluded = {e.get("name") for e in
                style.get("stepInventory", {}).get("tierC_excluded", [])}
    for sid, step in steps.items():
        if step.get("style") != style.get("id"):
            continue
        if step.get("measurability", {}).get("tier") == "C":
            rep.error(where, f"step '{sid}' is tier C and must not ship in V1")
        if step.get("name", {}).get("en") in excluded:
            rep.error(where, f"step '{sid}' is authored but also listed as excluded")


VALID_STATUS = {"live", "comingSoon", "onHold", "excluded"}
VALID_FLAGS = {"green", "amber", "red"}
VALID_SCORING = {"pose", "pose+onset", "onset"}


def validate_library(rep: Report, styles_on_disk: set[str]) -> None:
    """Checks the library registry against what actually exists.

    The registry is what the user sees: every style page, including the ones
    that are only "coming soon". Two failure modes matter and both are silent
    without this check — a style marked `live` with no content behind it (an
    empty course, which the IA standard forbids), and a style pack on disk that
    the library never lists (invisible work).
    """
    path = REPO / "content" / "library.json"
    if not path.exists():
        rep.error("content/library.json", "missing — the library IA has no source")
        return
    where = "content/library.json"
    lib = json.loads(path.read_text(encoding="utf-8"))
    rep.checked += 1

    if lib.get("schemaVersion") != SUPPORTED_SCHEMA:
        rep.error(where, "unsupported schemaVersion")

    seen: set[str] = set()
    live: set[str] = set()
    for s in lib.get("styles", []):
        sid = s.get("id", "?")
        if sid in seen:
            rep.error(where, f"duplicate style id '{sid}'")
        seen.add(sid)

        if s.get("status") not in VALID_STATUS:
            rep.error(where, f"'{sid}' status '{s.get('status')}' invalid")
        if s.get("legalFlag") not in VALID_FLAGS:
            rep.error(where, f"'{sid}' legalFlag '{s.get('legalFlag')}' invalid")
        if s.get("legalFlag") == "red":
            rep.error(where, f"'{sid}' is flagged red — named commercial "
                             "choreography / brand / syllabus text may not ship")
        if s.get("scoring") and s["scoring"] not in VALID_SCORING:
            rep.error(where, f"'{sid}' scoring '{s['scoring']}' invalid")

        status = s.get("status")
        if status == "onHold" and not s.get("onHoldReason"):
            rep.error(where, f"'{sid}' is on hold with no reason — the page must "
                             "state why")
        if status == "live":
            live.add(sid)
            if sid not in styles_on_disk:
                rep.error(where, f"'{sid}' is marked live but has no style pack "
                                 "on disk — an empty course must never be listed")
        if status == "comingSoon" and sid in styles_on_disk:
            rep.warn(where, f"'{sid}' has content on disk but is still listed as "
                            "coming soon")

    for sid in sorted(styles_on_disk - seen):
        rep.error(where, f"style pack '{sid}' exists on disk but the library "
                         "does not list it — invisible to the user")

    waves = [s.get("wave") for s in lib.get("styles", []) if s.get("wave")]
    if waves:
        print(f"library: {len(seen)} style pages across waves "
              f"{min(waves)}-{max(waves)}; {len(live)} live")


def main() -> int:
    joints = core_joint_ids()
    rep = Report()

    steps: dict[str, dict] = {}
    for p in sorted(CONTENT.glob("*/steps/*.json")):
        steps[p.stem] = validate_step(p, joints, rep)
    on_disk: set[str] = set()
    for p in sorted(CONTENT.glob("*/style.json")):
        validate_style(p, steps, rep)
        on_disk.add(p.parent.name)
    validate_library(rep, on_disk)

    print(f"motion_core {CORE_PIN}: {len(joints)} joint ids (pinned)")
    print(f"content files checked: {rep.checked}")
    for w in rep.warnings:
        print(f"  WARN  {w}")
    for e in rep.errors:
        print(f"  ERROR {e}")
    print("OK" if not rep.errors else f"FAILED ({len(rep.errors)} errors)")
    return 1 if rep.errors else 0


if __name__ == "__main__":
    sys.exit(main())
