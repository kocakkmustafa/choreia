# CHO-P1-001 — Özgün shell ve premium ders player'ını tamamla

**State:** PARTIAL — one well-scoped slice ACCEPTED (the 5-tab shell), the
task's much larger remainder (the premium lesson-player flow, style-page
enrichment, CHO-UX-001) is NOT attempted here and is documented as open,
with reasons. **Date:** 2026-08-19. **Owner:** Choreia solo session.
**Reviewer:** none assigned — R0/R1 (UI/navigation scaffold, no payment/
security/migration surface). **Input SHA:** baseline `f3e56fc`, common pin
unchanged (`f13bdc93b2eae2f741bfcdb4c9270a88e5d75e5d`).

## Why this package looks the way it does

CHO-P1-001 as written is one checklist covering at least three genuinely
separate bodies of work: a 5-tab shell, a full premium lesson-player flow
(preview/count/mirror/slow/loop/beat-live/weak-count-retry/review), and a
5-participant human usability study (`CHO-UX-001`). Two Explore-agent
surveys this session (see DEFTER C-321) measured that the player-flow work
is not a checklist of small gaps — most of it needs a real interaction-
design decision (mirror mode, slow motion and loop have no spec anywhere in
this repo to build against), one item needs a **cross-repo** schema change
this session cannot make alone (weak-count retry needs per-cycle data
`SessionRecord`, pinned in `motion_core`, does not carry), one item is
blocked on the same founder BPM-tap this session already flagged
(beat-live), and one item (style-page "trend" display) turns out to
contradict the *original* design brief, which explicitly ruled it out of V1
scope. None of that is something to rush.

What *was* safely buildable: the shell itself. This package is that slice.

## What shipped

- `lib/app/shell/choreia_shell.dart` — grown from 2 tabs (Styles, Progress)
  to the roadmap's 5 (Today, Styles, Practice Lab, Progress, Profile, §5),
  in that order. Initial selection stays on Styles (index 1) rather than
  Today (index 0) — landing on an honestly-empty tab as the app's front door
  would undercut the one tab with real value, the same undersell direction
  `library_view.dart`'s own M-F-186 discipline already guards against.
- Three new screens — `lib/app/today/today_view.dart`,
  `lib/app/practice_lab/practice_lab_view.dart`,
  `lib/app/shell/profile_view.dart` — sharing one honest-placeholder body
  (`lib/app/shell/not_built_tab_body.dart`) that states plainly what each
  tab will eventually hold and that none of it exists yet. This is the same
  discipline `library_view.dart` already applies to the 31 not-yet-built
  styles (M-F-186: no promise language, name what's true now), extended to
  shell tabs for the first time.
- `test/not_built_tabs_test.dart` (new, 3 tests) — asserts each placeholder
  states its plan and that none of it uses promise language ("coming soon",
  "yakında", "soon", "launching").
- `test/reachability_test.dart` — extended, not just patched around. The
  exhaustive candidate/reached/unreached partition check (this file's own
  core mechanism) picked up the 3 new screens automatically from source; a
  second, separately-verified exclusion class was added for "shell tab,
  excluded from STRICT counting by design" (checked against the shell's own
  source and against this file's own LOOSE-walk source, not just asserted).
  The LOOSE walk now taps all 5 tabs; its destination count moved from 5 to
  8 with the arithmetic re-derived, not just bumped.
- `test/live_session_test.dart` **is unrelated to this task** — see C-319/
  C-320, landed earlier the same session.

## What did NOT ship, and why (see DEFTER C-321 for the full evidence)

| Roadmap item | Status | Blocker |
|---|---|---|
| preview / count (taught, slow, counted demo) | Not built | No renderer anywhere for `DanceReference`'s per-phase angle data; needs a real interaction-design pass, not a gap-fill |
| mirror | Not built | Zero mirror-toggle UI or spec anywhere in `docs/design/` |
| slow / loop | Not built | Same — no spec, no code |
| beat-live | Not built | Same founder BPM-tap gate already flagged this session (Salsa) |
| weak-count retry | Not built | **Cross-repo.** `SessionRecord` (pinned `motion_core`) carries no per-cycle/per-finding data to retry against — a shared-package schema change, not something this session's own scope covers (family rule: common package changes need the common writer + 5-app contract matrix) |
| style-page BPM block | **Shipped, C-323 (see addendum below)** | Was buildable+small as predicted — data already existed, just unwired |
| style-page course block (Foundations/Combos/Routines) | Not built | **Re-measured, C-324 — this row's original "(buildable)" was too optimistic.** Not just a missing field: today's real catalogue (16 lessons across both real styles) is 100% single-step "Foundations"-tier content — zero Combos, zero Routines exist anywhere. Adding the field now would either display two permanently-empty buckets or require inventing a lesson taxonomy with nothing to validate it against — a content/product decision, not a wiring task |
| style-page trend block | Not built | Explicitly ruled OUT of V1 scope by the original `UI-BRIEF.md` (§3.4, §3.9b: timing is not measured, a trend chart would draw zeros) — the roadmap's ask may itself be stale, not a gap |
| `CHO-UX-001` (5-participant usability protocol) | Not run | **EXTERNAL_GATE** — needs real human participants, cannot be run by this session |

## Verification

```
flutter analyze                    → 0 issues
flutter test                       → 280/280 (277 baseline + 3 new)
```

Screenshots (`screenshots/`), all real simulator captures (`choreia-hatti`,
fresh install, this session) — not code-reading:

- `styles-with-5-tabs.png` — the nav bar in its new 5-tab form, Styles
  selected, showing the same catalogue content CHO-P0-001's evidence
  already verified is unchanged.
- `today-not-built.png`, `practice-lab-not-built.png`,
  `profile-not-built.png` — each honest placeholder, real device text
  rendering (not code excerpt).

Not produced: a `gates.sh` run pinned to this exact commit before the
commit lands (done as part of the commit's own pre-commit hook, matching
every other task this session).

## Addendum (same day) — the style-page BPM block, C-323

One item from the "not shipped" table above turned out to be small and
architecture-independent after all: `content/styles/*/style.json` already
carries `bpmRange`/`bpmStatus`, just never read into `StyleProse`. Added:

- `StyleProse.tempo` — a reader-ready sentence, derived once at parse time.
  A resolved `bpmRange` becomes "Danced at roughly N–M BPM."; a `bpmStatus`
  dispute becomes "This style's tempo is not confirmed yet." — the raw
  authoring string (which names the dispute for whoever resolves it next,
  not for a dancer) never reaches the surface, matching this app's existing
  C-117 rule.
- `StyleDetailView._tempoSection()` — its own section, its own guard clause,
  kept apart from `_honestySection` (a claim about the style, not about what
  the camera measures on a dancer).
- Tests: `test/style_detail_test.dart` new group, one case per branch, plus
  an explicit check that neither `"DISPUTED"` nor `"measurement"` (substrings
  of the real raw `bpmStatus`) ever appear on screen.
- Real-device verification: `screenshots/tempo-section-salsa-disputed.png`
  — the harder of the two cases (leak risk), captured live on
  `choreia-hatti`. The resolved-range case is covered by the passing test;
  a second screenshot was judged redundant.

`flutter analyze`: 0. `flutter test`: 282/282 (280 + 2 new).

## Addendum (same day) — the style-page course block, C-324 (re-measured, not shipped)

The other item this README's original table called "(buildable)" — course-kind
(Foundations/Combos/Routines) — was re-measured before touching code, per the
same-session instruction to evaluate it carefully rather than assume it is as
small as BPM turned out to be. It is not.

Read every lesson in both real styles (`content/styles/salsa_shines/style.json`,
`content/styles/hip_hop_foundations/style.json` — 16 lessons total): all of
them sit at `level` 1 or 2, and every one is single-step/single-concept
"Foundations"-tier material. There is no Combo, no Routine, anywhere in the
actual catalogue today. Unlike BPM — where `bpmRange`/`bpmStatus` already
existed in the data and only the reader-facing wiring was missing — course-kind
has neither a schema field *nor* any real content that would populate two of
its three buckets. Adding the field now would mean either shipping two
buckets that are permanently empty (a structural version of the overclaiming
this app's own M-F-186 discipline exists to prevent) or inventing a lesson
taxonomy with nothing in the real catalogue to check it against — a content/
product decision, not a data-wiring task.

Not built. Recorded as DEFTER C-324, not C-323's kind of small win. The
comparison table above is corrected accordingly.
