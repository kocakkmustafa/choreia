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
    """Joint ids declared in the pinned motion_core's StandardJoints.

    İKİ AYRI ARIZA SINIFI, İKİ AYRI ÇIKIŞ (koordinatör hükmü, C-210):
    kardeş repo HİÇ checkout edilmemişse bu bir ORTAM eksikliği — taze bir
    klonda/başka bir makinede beklenir, ürün kusuru değil (exit 2, ne
    yeşil ne kırmızı — bkz. tool/gates.sh). Kardeş repo ORADA ama pin
    okunamıyorsa (yanlış dal, çekilmemiş tag) bu GERÇEK bir problem — o
    hâlâ kırmızı (exit 1 / SystemExit varsayılanı). Önceden ikisi AYNI
    opak hatayı üretiyordu ve taze klondaki geliştirici "içerik bozuk"
    sanabilirdi (O-084 sınıfı risk).
    """
    import subprocess

    if not (CORE_REPO / ".git").exists():
        print(f"ORTAM YOK: motion-core kardeş repo olarak checkout "
             f"edilmemiş ({CORE_REPO}) — bu kapı burada koşamadı, içerik "
             "ÖLÇÜLMEDİ")
        raise SystemExit(2)

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

    # A step may be DESCRIBED before it is CALIBRATED (C-200).
    #
    # Splitting the two is what unblocked 31 styles: harvesting a reference
    # needs a step definition to tell it what to harvest, so demanding
    # calibrated numbers up front made the whole content queue look shut when
    # its first link was writing, not measuring.
    #
    # The line: "what IS this movement" is descriptive — phases, the quantity
    # that separates them, which joints do the work, what can go wrong. "How
    # GOOD is it" is judgement, and judgement needs calibration. Every
    # judgement field may be null ONLY while a named `calibration` block says
    # so, and the block's reason may not promise anything (M-F-186).
    pending = step.get("calibration") or {}
    calibrating = pending.get("status") == "PENDING"
    if calibrating:
        if not pending.get("why"):
            rep.error(where, "calibration.status is PENDING with no `why` — "
                             "an unexplained hold is indistinguishable from "
                             "an oversight")
        blurb = f"{pending.get('why', '')} {pending.get('unblockedBy', '')}"
        for promise in ("will be", "coming soon", "soon", "once we", "yakında"):
            if promise in blurb.lower():
                rep.error(where, f"calibration reason promises ('{promise}') — "
                                 "say what is MISSING and what would supply "
                                 "it, never when")
        if not pending.get("unblockedBy"):
            rep.error(where, "calibration has no `unblockedBy` — a block "
                             "nobody can lift is a block nobody will")

    meas = step.get("measurability", {})
    tier = meas.get("tier")
    if tier is None and calibrating:
        # Condition 3: the two may never both be filled. "Measured, and still
        # waiting" is not a state — it is two authors disagreeing in one file.
        if not meas.get("tierStatus"):
            rep.error(where, "measurability.tier is null with no tierStatus — "
                             "an absent tier reads as a LOW tier unless the "
                             "absence says otherwise")
    elif tier not in VALID_TIERS:
        rep.error(where, f"measurability.tier '{tier}' invalid")
    elif meas.get("tierStatus"):
        # THREE states, not two — found on this gate's first run, in a file
        # written weeks before it (C-201).
        #
        # The gate was built assuming `tier` and `tierStatus` were mutually
        # exclusive: either a step is measured or it is waiting. `ss_basic`
        # is neither. It carries tier A as an INHERITED value and a status
        # saying the measurement commissioned to confirm it came back
        # undecided for a named structural reason — "Tier A is the INHERITED
        # value, not a re-confirmed one. Do not cite it as measured."
        #
        # The original rule would have demanded one of them be deleted, and
        # the cheap deletion is the warning — turning an honest "unverified"
        # into a silent claim of measurement. A gate that makes the dishonest
        # repair the easy one is worse than no gate.
        #
        # So the third state is legal and must SAY it is: an unverified tier
        # declares itself, and only an undeclared pairing is a leftover.
        if "UNVERIFIED" not in str(meas.get("tierStatus")).upper():
            rep.error(where, "measurability has a tier AND a tierStatus that "
                             "does not declare the tier UNVERIFIED. Either "
                             "the status is a stale leftover, or the tier is "
                             "inherited and the status must say so — a "
                             "reader cannot tell those apart")
    if tier and not meas.get("rationale"):
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
        sev = e.get("severity")
        if sev is None and calibrating:
            if not e.get("severityStatus"):
                rep.error(where, f"error '{e.get('code')}' has no severity and "
                                 "no severityStatus — silence about how bad "
                                 "something is reads as 'not bad'")
        elif sev not in VALID_SEVERITIES:
            rep.error(where, f"error '{e.get('code')}' severity "
                             f"'{sev}' invalid")
        elif e.get("severityStatus"):
            rep.error(where, f"error '{e.get('code')}' carries BOTH a severity "
                             "and a severityStatus")
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
            # AİLE KURALI (koordinatör hükmü 2026-08-12, C-247): engelleyen her
            # kapı İKİ yönü de taşır — AÇAN yol (`unblockedBy`) ve ÖLÇÜLÜP
            # KAPATILMIŞ yollar (`closedPaths`).
            #
            # Niye: bu depoda tek engelleyen kapı `unblockedBy` taşıyordu ama
            # kapalı yolu taşımıyordu, ve kapalı yol (C-032) BAŞKA bir dosyada
            # duruyordu. Sonuç ölçüldü: aynı çıkmaz sokağa ikinci kez girildi
            # (C-244), maliyeti bir turdu. *Bir kapı, açılış yolunu taşıyıp
            # kapalı yolu taşımıyorsa, onu okuyan herkesi kapalı yola bir kez
            # daha davet eder.*
            #
            # ⚠️ ÜÇÜNCÜ HÂL ZORUNLU: kapalı yol bilinmiyorsa alan BOŞ
            # bırakılmaz, `"none-known"` yazılır — boş bir alan "yok" ile
            # "bakılmadı"yı ayırt ettirmez.
            cp = g.get("closedPaths")
            if g.get("blocked") and not cp:
                rep.error(where, f"ship gate '{gid}' is blocked without "
                                 "`closedPaths` — a gate that carries only the "
                                 "way IN invites every reader back down the "
                                 "measured-and-closed path. If none is known, "
                                 'write "none-known" rather than leaving it out')
            if cp is not None and cp != "none-known" and (
                    not isinstance(cp, list) or not all(isinstance(x, str) and x
                                                        for x in cp)):
                rep.error(where, f"ship gate '{gid}' `closedPaths` must be a "
                                 'non-empty list of strings, or the literal '
                                 '"none-known"')

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

            # ── cycleTarget: the ABSENCE is the default, and a present value
            # has to survive two ways of being useless (C-273, H-4 ③).
            #
            # NOT validated by "is it there" — that would be a gate on a field
            # nothing ships yet, and this repo's rule is that a gate verifies an
            # A-table item, not itself. What it verifies is the DENOMINATOR
            # promise on the result surface: a ratio is a claim about a plan,
            # and both failure modes below put a false sentence on a screen
            # that already exists.
            if "cycleTarget" in ls:
                target = ls["cycleTarget"]
                # `isinstance(True, int)` is True in Python — a JSON `true`
                # would sail through a bare int check and reach the wire as 1,
                # i.e. a one-cycle target nobody wrote. Bool is excluded by
                # name, not by hoping the author never types it.
                if isinstance(target, bool) or not isinstance(target, int):
                    rep.error(where, f"lesson '{lid}' cycleTarget must be an "
                                     f"integer, got {target!r}")
                elif target < 1:
                    rep.error(where, f"lesson '{lid}' cycleTarget is {target} — "
                                     "must be >= 1. The family's plannedUnits "
                                     "field is a non-nullable int and 0 is how "
                                     "ABSENCE is encoded on the wire, so a "
                                     "target of 0 is not a target the surface "
                                     "can tell apart from no target at all: "
                                     "content would believe it set a plan and "
                                     "the screen would show none")
                if not str(ls.get("cycleTargetBasis") or "").strip():
                    rep.error(where, f"lesson '{lid}' declares cycleTarget "
                                     "without cycleTargetBasis — a target "
                                     "renders as '6 of 8 cycles', which blames "
                                     "the learner for falling short of a "
                                     "number. Say where the number came from, "
                                     "measured (same bar as `honesty`): "
                                     "'the richest reference take carries 12 "
                                     "cycles' is a basis, '8 is a good number' "
                                     "is not")
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
                    elif klass == "permanent":
                        # İKİZ KAPI (M-F-245/3). structural-circular tarafı
                        # "yol VAR mı" diye sorar; permanent tarafı iki şeyi
                        # birden sorar ve İKİNCİSİ ters yönlüdür:
                        #
                        #   (1) kalıcılığın KENDİ gerekçesi yazılmış mı —
                        #       `demoOnlyReason` "ne alırsın/almazsın" der,
                        #       `whyPermanent` "ve bu DEĞİŞMEYECEK, çünkü bu
                        #       kameranın görebileceği bir nicelik değil" der.
                        #       İkincisi olmadan kalıcı sınıflandırma, genel
                        #       bir demo gerekçesinin arkasına saklanabilir.
                        #
                        #   (2) terfi yolu yazılMAMIŞ mı — permanent bir derse
                        #       yol yazmak ÇELİŞKİDİR, eksiklik değil: ya sınıf
                        #       yanlıştır ya yol sahtedir. Sessiz geçmek,
                        #       kullanıcıya var olmayan bir gelecek vaat eder.
                        #       (M-F-207 zeyli: en-az-yetkinin AŞIRI hâli de
                        #       arızadır — bu kapı fazla-kısıtlamayı da yakalar.)
                        if not ls.get("whyPermanent"):
                            rep.error(where, f"lesson '{lid}' is permanent "
                                             "without whyPermanent — 'never "
                                             "scored' is a claim and needs its "
                                             "own stated reason, in user "
                                             "language")
                        if ls.get("promotionPath"):
                            rep.error(where, f"lesson '{lid}' is permanent but "
                                             "declares a promotionPath — "
                                             "CONTRADICTION: either the class "
                                             "is wrong or the path is fiction. "
                                             "A permanent block with a way out "
                                             "is not permanent")
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

    # EVERY relatedDrill MUST RESOLVE TO A LESSON.
    #
    # The error taxonomy tells a learner "here is the drill for this mistake".
    # If that drill has no lesson behind it, the app has promised help it
    # cannot deliver — the dead-button class, in content rather than in UI, and
    # invisible because nothing was checking it. Measured when this gate was
    # added: ALL SEVEN drill targets across both styles were dangling.
    #
    # The drill must live in the SAME style: a hip-hop error pointing at a
    # salsa drill would resolve here and still be wrong for the learner.
    lesson_ids = {ls.get("id")
                  for lv in style.get("levels", [])
                  for ls in (lv.get("lessons") or [])}
    for sid, step in steps.items():
        if step.get("style") != style.get("id"):
            continue
        for err in step.get("errors") or []:
            drill = err.get("relatedDrill")
            if drill and drill not in lesson_ids:
                rep.error(where, f"step '{sid}' error '{err.get('code')}' "
                                 f"points at drill '{drill}' but no lesson "
                                 "with that id exists in this style — a named "
                                 "remedy with nothing behind it is a promise "
                                 "the app cannot keep")

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


# Recall-oriented flagger for the cultural-review ledger. These words RAISE a
# style for a human ruling; they never assign one. Over-flagging costs a line in
# the ledger, under-flagging ships an unreviewed claim about a living community,
# so the list is deliberately loose.
#
# Why this is not the keyword classifier that was rejected: on 2026-08-07 a
# keyword proxy was tried for splitting `comingSoon` into awaiting-content vs
# awaiting-capability, and it put 12 of 31 styles in NEITHER bucket (C-181). A
# proxy that ASSIGNS a class must be accurate; a proxy that CALLS FOR REVIEW
# only has to over-include. Same technique, different job — and only the second
# job is one keywords can hold.
CULTURAL_REVIEW_WORDS = (
    "worship", "devotional", "sacred", "spiritual", "ceremon", "ritual",
    "prayer", "goddess", "deity", "temple", "shrine", "initiat", "lineage",
    "halau", "hālau", "kumu",
)

VALID_RULINGS = {"held", "cleared", "open"}


def validate_cultural_review(rep: Report, lib: dict, where: str) -> None:
    """Every style whose own attribution claims a living devotional or
    transmission-restricted practice must appear in the ledger.

    What this gate does NOT do: decide whether such a style should be `onHold`.
    That is a cultural and honesty ruling, and it belongs to a person. What it
    does is make the difference between *ruled* and *never looked at* readable —
    which is the thing that was missing when this was written. `hula` was held
    by an explicit founder directive; `garba`'s own attribution says "It is
    worship as much as it is dance" and nobody had ever considered it.

    The gate is green while every flagged style carries SOME ruling, including
    `open`. That is the point: an open question that is written down is a
    different state from one nobody has noticed, and only the second is a
    defect this repository can fix on its own.
    """
    ledger = (lib.get("culturalReviewLedger") or {}).get("ledger")
    if not isinstance(ledger, dict):
        rep.error(where, "culturalReviewLedger.ledger missing — styles making "
                         "living-practice claims would have no review record")
        return

    for sid, entry in ledger.items():
        ruling = (entry or {}).get("ruling")
        if ruling not in VALID_RULINGS:
            rep.error(where, f"cultural review of '{sid}' has ruling "
                             f"'{ruling}' — expected one of "
                             f"{sorted(VALID_RULINGS)}")

    for s in lib.get("styles", []):
        sid = s.get("id", "?")
        text = (s.get("originAttribution") or "").lower()
        hits = sorted({w for w in CULTURAL_REVIEW_WORDS if w in text})
        if not hits:
            continue
        if sid not in ledger:
            rep.error(where, f"'{sid}' attribution asserts a living practice "
                             f"({', '.join(hits)}) but carries NO cultural "
                             "review record. The criterion that put 'hula' "
                             "onHold may or may not apply — the defect is that "
                             "nobody ruled and nothing says so. Add it to "
                             "culturalReviewLedger.ledger with ruling 'open' "
                             "if the question is unanswered.")

    for sid in ledger:
        if sid not in {s.get("id") for s in lib.get("styles", [])}:
            rep.error(where, f"cultural review names '{sid}', which is not a "
                             "style in this library")


# Phrases that assert the READER'S OWN HISTORY — what they have already done,
# seen or been told. Deliberately MULTI-WORD and few.
#
# The wide scan that produced this list matched 7 places on single words
# (`first`, `again`, `next`, `already`); six were innocent — "step out and back
# AGAIN" is a direction, "the NEXT one" is the next beat, "at FIRST" is about
# learning a craft rather than about the reader. A recall-oriented scan is the
# right instrument for FINDING candidates and the wrong one for a gate, because
# a gate ASSIGNS a verdict and assigning needs precision (C-181). So the scan
# stayed loose, and this list is what survived reading all seven.
NTH_TIME_CLAIMS = (
    "you have seen", "as you saw", "last time", "welcome back",
    "you already", "by now you", "remember when", "again this time",
    "you have learned", "you will remember",
)


def validate_nth_time_claims(rep: Report, lib: dict, where: str) -> None:
    """Content may not assume how many times a dancer has been here.

    A style page has no visit counter, a glossary has no reading history, and
    the app records nothing at all. Any sentence that assumes a second visit is
    asserting a context no code path carries — true at N=1 by accident, false
    every time after.
    """
    for s in lib.get("styles", []):
        texts = [
            (f, s.get(f) or "")
            for f in ("description", "originAttribution", "onHoldReason")
        ]
        texts += [(f"gloss:{g.get('name')}", g.get("gloss") or "")
                  for g in (s.get("stepGlossary") or [])]
        texts += [("cameraLimits", t) for t in (s.get("cameraLimits") or [])]
        for field, text in texts:
            low = text.lower()
            for claim in NTH_TIME_CLAIMS:
                if claim in low:
                    rep.error(where, f"'{s.get('id')}' {field} assumes the "
                                     f"reader's own history (\"{claim}\") — "
                                     "nothing counts visits, so this is true "
                                     "at N=1 by accident and false after")


def validate_attribution_sources(rep: Report, lib: dict, where: str) -> None:
    """Attribution sourcing is COUNTED, never declared.

    The provenance block used to carry one blanket word — `UNSOURCED` — plus a
    note that sourcing would take a research round. The note was true and the
    word was read as something stronger: that sources could not be had. Nobody
    had tried. One attribution (`vogue`) was then actually attempted and three
    usable sources, including the Smithsonian's own history, turned up in
    minutes and AGREED with the text already written.

    So the tally lives here, derived from the styles themselves. A blanket
    status can drift from reality in silence; a count cannot, because this
    check recomputes it.
    """
    prov = lib.get("originAttributionProvenance") or {}
    styles = [s for s in lib.get("styles", []) if s.get("originAttribution")]
    sourced = [s["id"] for s in styles if s.get("attributionSources")]

    declared = prov.get("sourcedStyles")
    if declared is None:
        rep.error(where, "originAttributionProvenance.sourcedStyles missing — "
                         "the sourcing claim is a declaration again")
    elif sorted(declared) != sorted(sourced):
        rep.error(where, f"sourcedStyles says {sorted(declared)} but content "
                         f"has {sorted(sourced)} — the tally drifted from the "
                         "styles it counts")

    status = str(prov.get("status", ""))
    if sourced and f"{len(sourced)}/" not in status:
        rep.error(where, f"provenance status '{status[:40]}...' does not carry "
                         f"the measured count ({len(sourced)}/{len(styles)})")

    # A source entry that cannot be followed is a citation-shaped decoration.
    for s in styles:
        for i, src in enumerate(s.get("attributionSources") or []):
            for field in ("title", "publisher", "url", "kind"):
                if not src.get(field):
                    rep.error(where, f"'{s['id']}' source[{i}] has no {field} — "
                                     "an unfollowable citation is worse than "
                                     "none, it LOOKS checked")
            if not str(src.get("url", "")).startswith("http"):
                rep.error(where, f"'{s['id']}' source[{i}] url is not a link")

    # The surface must never turn a source record into a badge. This is OUR
    # bookkeeping; a dancer who sees "verified" reads a guarantee nobody made.
    if "surfaceRule" not in prov:
        rep.error(where, "provenance lost its surfaceRule — the rule that the "
                         "screen never claims verification")


def validate_limits_not_doubled(rep: Report, lib: dict,
                                on_disk: dict[str, dict], where: str) -> None:
    """A style page must state its camera limits ONCE.

    Two registers exist for the same truth. A style with a pack on disk shows
    the MEASURED honesty box — "instructors disagree by 11-58deg on arm joints,
    so there is no single correct arm to grade you against". A style with no
    pack shows the GENERAL `cameraLimits` list — "effort is heart rate and
    breath, and a camera reads neither".

    `style_detail_view` renders both when both exist, so a built style that
    also carried `cameraLimits` would tell a dancer the same limitation twice
    in two voices, and the weaker one would undercut the measured one.

    This is why `hip_hop_foundations` and `salsa_shines` have no `cameraLimits`
    and must not get any: their absence is the CORRECT state, and without this
    check the next person counting empty fields reads it as a content gap and
    "fixes" it. A gate that protects a deliberate emptiness is worth as much
    as one that protects a filled field.
    """
    for s in lib.get("styles", []):
        sid = s.get("id", "?")
        if not s.get("cameraLimits"):
            continue
        style = on_disk.get(sid)
        if style is None:
            continue
        honesty = style.get("honesty") or {}
        if honesty.get("measured") or honesty.get("notMeasured"):
            rep.error(where, f"'{sid}' carries cameraLimits AND a measured "
                             "honesty box; the style page renders both, so a "
                             "dancer reads the same limit twice — once "
                             "measured, once general. Keep the measured one")


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

    validate_cultural_review(rep, lib, where)
    validate_limits_not_doubled(rep, lib, styles_on_disk, where)
    validate_attribution_sources(rep, lib, where)
    validate_nth_time_claims(rep, lib, where)

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
