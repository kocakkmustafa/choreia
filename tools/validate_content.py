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
CORE_PIN = "motion_core-v0.5.0"
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
    beats_blocked = beats is None and bool(step.get("beatsStatus"))
    if beats_blocked:
        rep.warn(where, f"beats is null (blocked: {step['beatsStatus'][:80]}...) "
                        "— phase-only step, cannot be beat-timed until filled in")
    elif not isinstance(beats, int) or beats < 1:
        rep.error(where, "beats must be a positive integer, or null with a "
                         "named beatsStatus explaining the block")
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


def validate_style(path: Path, steps: dict[str, dict], rep: Report) -> dict:
    where = path.relative_to(REPO).as_posix()
    style = json.loads(path.read_text(encoding="utf-8"))
    rep.checked += 1

    if style.get("schemaVersion") != SUPPORTED_SCHEMA:
        rep.error(where, "unsupported schemaVersion")
    if style.get("id") != path.parent.name:
        rep.error(where, "id does not match directory name")

    # M-F-130: the RELEASE axis, orthogonal to library.json `status`.
    #
    # Deliberately NOT cross-checked against status in either direction — that
    # is the point of the hüküm. A style may honestly be `live` with every ship
    # gate blocked (salsa_shines today: it has a scored lesson AND cannot be
    # published). Adding a "live implies shippable" check here would recreate
    # exactly the proxy defect C-101 recorded.
    #
    # What IS checked: the field exists, each entry is self-explaining, and a
    # blocked gate names its own unblocking condition rather than leaving the
    # reader to guess when it lifts.
    gates = style.get("shipGates")
    if gates is None:
        rep.error(where, "no shipGates field — the release axis must be stated "
                         "explicitly (empty list is fine WITH a shipGatesNote; "
                         "absent means the question was never asked, M-F-130)")
    elif not isinstance(gates, list):
        rep.error(where, "shipGates must be a list")
    else:
        if not gates and not style.get("shipGatesNote"):
            rep.error(where, "shipGates is empty without a shipGatesNote — an "
                             "empty list must say why nothing blocks release")
        for g in gates:
            gid = g.get("gate", "<unnamed>") if isinstance(g, dict) else repr(g)
            if not isinstance(g, dict) or not g.get("gate"):
                rep.error(where, f"shipGates entry {gid} has no `gate` name")
                continue
            if g.get("blocked") not in (True, False):
                rep.error(where, f"ship gate '{gid}' must state `blocked` "
                                 "explicitly (true/false)")
            if not g.get("why"):
                rep.error(where, f"ship gate '{gid}' has no `why`")
            if g.get("blocked") and not g.get("unblockedBy"):
                rep.error(where, f"ship gate '{gid}' is blocked without an "
                                 "`unblockedBy` — a block with no named lifting "
                                 "condition is indistinguishable from a dead end")

    rng = style.get("bpmRange")
    if rng is None:
        # A null range is tolerated only when it is an explicit, documented
        # dispute. Working with a known-unknown is fine; shipping one is not,
        # so this stays visible on every run instead of quietly passing.
        if style.get("bpmStatus", "").startswith("DISPUTED"):
            rep.warn(where, "bpmRange is unresolved (DISPUTED) — no lesson in "
                            "this style may ship until a measurement settles it")
            # A known release blocker must appear on the release axis too, or
            # the two records drift and a release decision reading only
            # shipGates (which M-F-130 says is the ONLY thing it may read)
            # would miss it.
            named = any(isinstance(g, dict) and g.get("blocked")
                        and "bpm" in str(g.get("gate", "")).lower()
                        for g in (style.get("shipGates") or []))
            if not named:
                rep.error(where, "bpmStatus is DISPUTED but no blocked bpm* ship "
                                 "gate declares it — a release decision reads "
                                 "shipGates ONLY (M-F-130), so an undeclared "
                                 "blocker is invisible to it")
        else:
            rep.error(where, "bpmRange missing and no bpmStatus explains why")
    elif not isinstance(rng, list) or len(rng) != 2 or rng[0] >= rng[1]:
        rep.error(where, f"bpmRange {rng} invalid")

    # K10: what the style grades and what it deliberately does not, with a
    # reason per line. `measured` may be EMPTY (a style that grades nothing
    # yet is an honest state) but the field must exist and, when empty, say
    # why — an absent honesty block is what lets ungraded content drift into
    # looking graded.
    honesty = style.get("honesty")
    if not isinstance(honesty, dict):
        rep.error(where, "no honesty block — K10 requires every style to state "
                         "what it measures and what it deliberately does not")
    else:
        if not isinstance(honesty.get("measured"), list):
            rep.error(where, "honesty.measured must be a list (may be empty)")
        elif not honesty["measured"] and not honesty.get("measuredNote"):
            rep.error(where, "honesty.measured is empty without a measuredNote "
                             "— an empty list must say why it is empty")
        if not honesty.get("notMeasured"):
            rep.error(where, "honesty.notMeasured is empty — no style measures "
                             "everything; an empty list means the question "
                             "was not asked")

    for lvl in style.get("levels", []):
        lvl_id = lvl.get("level")
        lessons = lvl.get("lessons", [])
        scored_lessons = [ls for ls in lessons
                          if isinstance(ls, dict) and ls.get("scored")]

        rule = lvl.get("unlockRule")
        if rule is None:
            # Legitimate only when there is no graded lesson to gate on. A
            # level that DOES score something still may not let lesson
            # completion be the unlock (the original rule this check exists
            # for), so the exemption is narrow and must be explained.
            if scored_lessons:
                rep.error(where, f"level {lvl_id} has scored lessons but no "
                                 "unlockRule — completing a lesson must not be "
                                 "what unlocks the next")
            elif not lvl.get("unlockRuleNote"):
                rep.error(where, f"level {lvl_id} has unlockRule:null without "
                                 "an unlockRuleNote explaining why")
        elif not isinstance(rule, dict) or not rule.get("description"):
            rep.error(where, f"level {lvl_id} unlockRule has no description")
        elif rule.get("thresholdsCalibrated") not in (True, False):
            rep.error(where, f"level {lvl_id} unlockRule must state "
                             "thresholdsCalibrated explicitly (family rule M-F-04)")

        for ls in lessons:
            if not isinstance(ls, dict):
                rep.error(where, f"level {lvl_id} lesson {ls!r} is a bare id — "
                                 "lessons must declare scored/locked/demoOnly "
                                 "state, so an ungraded lesson cannot be "
                                 "mistaken for a graded one")
                continue
            lid = ls.get("id", "<no id>")
            if "scored" not in ls:
                rep.error(where, f"lesson '{lid}' does not declare `scored`")
            # A lesson may be graded, locked, or demo-only. Anything else is
            # an ungraded lesson with no stated reason — the silent case.
            if not ls.get("scored"):
                locked = ls.get("status") == "locked"
                demo = bool(ls.get("demoOnly"))
                if locked and not ls.get("lockedReason"):
                    rep.error(where, f"lesson '{lid}' is locked without a "
                                     "lockedReason in user language")
                if demo and not ls.get("demoOnlyReason"):
                    rep.error(where, f"lesson '{lid}' is demoOnly without a "
                                     "demoOnlyReason in user language (K10)")
                if demo:
                    # M-F-152: the axis that matters is not "temporary vs
                    # permanent" but whether a promotion path EXISTS and is
                    # named. A structural-circular block that never says how it
                    # lifts is indistinguishable from a permanent one, and the
                    # lesson would quietly stay unscored forever.
                    klass = ls.get("demoOnlyClass")
                    if klass not in ("permanent", "structural-circular"):
                        rep.error(where, f"lesson '{lid}' demoOnlyClass "
                                         f"'{klass}' invalid — must be "
                                         "'permanent' (no promotion possible) "
                                         "or 'structural-circular' (promotion "
                                         "path exists and must be named)")
                    elif klass == "structural-circular":
                        path = ls.get("promotionPath") or {}
                        for field in ("blockedBy", "unblockedBy"):
                            if not path.get(field):
                                rep.error(where, f"lesson '{lid}' is "
                                                 "structural-circular but "
                                                 f"promotionPath.{field} is "
                                                 "missing — an unnamed way out "
                                                 "is not a way out")
                if not locked and not demo:
                    rep.error(where, f"lesson '{lid}' is not scored but is "
                                     "neither locked nor demoOnly — say which, "
                                     "and why (K10)")
            step_id = ls.get("step")
            if step_id and step_id not in steps:
                # Tolerated when the lesson is locked precisely because the
                # step is not authored yet; an unexplained dangling reference
                # is not.
                if ls.get("status") != "locked":
                    rep.error(where, f"lesson '{lid}' references unknown step "
                                     f"'{step_id}'")

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

    return style


VALID_STATUS = {"live", "demoOpen", "comingSoon", "onHold", "excluded"}
VALID_FLAGS = {"green", "amber", "red"}
VALID_SCORING = {"pose", "pose+onset", "onset"}


def validate_library(rep: Report, styles_on_disk: dict[str, dict]) -> None:
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

        # M-F-123 status lattice, checked BOTH WAYS. Overclaiming ("live" with
        # nothing scored) and underclaiming ("comingSoon" while the user can
        # actually open a lesson) are the same defect pointing opposite ways:
        # the registry saying something the content does not.
        #
        # Openable means demoOnly. A `locked` lesson cannot be opened (the lock
        # is visible and does not lift), so a style carrying only locked lessons
        # is NOT demoOpen.
        style = styles_on_disk.get(sid)
        scored = demo = 0
        if style is not None:
            for lvl in style.get("levels", []):
                for ls in lvl.get("lessons", []):
                    if not isinstance(ls, dict):
                        continue
                    if ls.get("scored"):
                        scored += 1
                    elif ls.get("demoOnly"):
                        demo += 1

        if status == "live":
            live.add(sid)
            if style is None:
                rep.error(where, f"'{sid}' is marked live but has no style pack "
                                 "on disk — an empty course must never be listed")
            else:
                if not scored:
                    rep.error(where, f"'{sid}' is marked live but no lesson in "
                                     "its style pack is scored — statusValues "
                                     "defines live as '>=1 SKORLANAN ders'; "
                                     f"found {demo} demo-only and 0 scored "
                                     "(should this be demoOpen?)")
                if not style.get("honesty", {}).get("measured"):
                    rep.error(where, f"'{sid}' is marked live but its "
                                     "honesty.measured is empty — the style "
                                     "itself declares it grades nothing")
        elif status == "demoOpen":
            if style is None:
                rep.error(where, f"'{sid}' is marked demoOpen but has no style "
                                 "pack on disk — there is no lesson to open")
            else:
                if scored:
                    rep.error(where, f"'{sid}' is marked demoOpen but has "
                                     f"{scored} scored lesson(s) — that is "
                                     "`live`; demoOpen means 0 scored")
                if not demo:
                    rep.error(where, f"'{sid}' is marked demoOpen but no lesson "
                                     "is demoOnly — a style whose lessons are "
                                     "all locked has nothing the user can open, "
                                     "which is comingSoon")
        elif status == "comingSoon":
            # The underclaim direction. Content on disk alone is only a warning
            # (a style pack can legitimately exist while every lesson is still
            # locked), but an OPENABLE lesson means the user can reach it, and
            # the registry must say so.
            if scored:
                rep.error(where, f"'{sid}' is listed comingSoon but has {scored} "
                                 "SCORED lesson(s) — that is `live`. "
                                 "Underclaiming is the same defect as "
                                 "overclaiming (M-F-123)")
            elif demo:
                rep.error(where, f"'{sid}' is listed comingSoon but has {demo} "
                                 "demo-only lesson(s) the user can actually "
                                 "open — that is `demoOpen`. Underclaiming is "
                                 "the same defect as overclaiming (M-F-123)")
            elif style is not None:
                rep.warn(where, f"'{sid}' has content on disk but is still "
                                "listed as coming soon (all lessons locked)")

    for sid in sorted(set(styles_on_disk) - seen):
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
    on_disk: dict[str, dict] = {}
    for p in sorted(CONTENT.glob("*/style.json")):
        on_disk[p.parent.name] = validate_style(p, steps, rep)
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
