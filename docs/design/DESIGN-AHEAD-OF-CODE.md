---
tur: kapsam
proje: choreia
guncelleme: 2026-08-06
---

# Choreia — Design Ahead of Code

Written at the end of the first giydirme (dressing) turn, while the design
(`claude.ai/design` project `choreia`, `Choreia.dc.html`) is loaded and the
comparison is cheap. This is **not** a bug list — nothing below is a defect in
the design or in the code. It is the inventory the coordinator asked for:
everywhere the design shows something this app's code has no counterpart for
yet, so the next turn's scope can be decided from evidence instead of memory.

**Read before scoping the next (construction) turn.** Re-importing the design
from the MCP costs nothing; re-deriving this list by re-reading the whole
`.dc.html` by hand does.

For each item: what the design does · why the code doesn't have it ·
what building it would touch.

---

## 1. Navigation shell

**Design:** nine reachable screens (Library → Style → Lesson → Flow → Live →
Music/Summary → Progress), plus a states reference gallery.

**Code:** `lib/main.dart` opens exactly one screen —
`LiveLessonPage(stepId: 'ss_shine_footwork', lessonClass: 'scored')` — with no
router, no back stack, no way to reach `ProgressView` even though that widget
already exists and passes its own test suite. The file says why in its own
comment: *"No navigation shell yet — building one around an unverified chain
would be decorating something that does not work."* The chain (camera →
engine → live screen) is verified now (kısım-1+2, `b9e448e`); the navigation
gap is simply what was deferred, not reconsidered since.

**Touches if built:** every item below depends on this existing first. A
`Navigator`/route table, and a decision on whether `ProgressView` is reachable
from a tab bar, a menu, or only from the end of a lesson.

---

## 2. Library screen

**Design (`isLib`):** a stat panel ("34 styles in the catalogue — 1 scored ·
1 open, ungraded · 32 in preparation"), filter chips (All/Scored/Open/In
prep), two full hero cards for the two real styles, and five "wave" tiers of
compact tiles for the other 32 — name + status + (for Hula) a written on-hold
reason. An empty-filter state.

**Code:** no `LibraryView` widget exists. The data half is split:
- `salsa_shines` and `hip_hop_foundations` are real — `CourseCatalog` +
  `StyleView.derive` (`lib/app/style_availability.dart`) already compute
  exactly the `live` / `demoOpen` / `comingSoon` / `onHold` / `excluded`
  lattice the design's three badges need, from real content.
- The other 32 styles (Bachata, House Jacking, Vogue, Hula, …) exist **only**
  inside the design file's own `WAVES` array — hardcoded mock data written for
  the mockup, not read from `content/`. There is no `content/styles/bachata/`
  etc., and no schema for "a style we intend to teach but have not started."

**Touches if built:** a `LibraryView`; a decision on where the 32-style
roadmap lives — extend the content schema so the wave list is derived (this
app's own rule: "türetimli listeler elle yazılmaz"), or accept it as
UI-declared roadmap data outside the honesty-lattice that governs real
lessons. That decision is a product call, not a styling one.

---

## 3. Style detail page

**Design (`isStyle`):** hero image, badge + teacher count, title + description,
an **Origin & Attribution** box (full paragraph — lineage, decades, who it was
carried by — plus "reviewed with our salsa teacher panel · 6 names credited"),
a step-glossary chip list (9 named steps: Suzie Q, Cross-body lead, …),
a Courses list (Foundations/Combos/Routines with lesson-kind counts), and a
"what this style can tell you" measured/not-measured box.

**Code:** no `StyleDetailView` widget. `StyleView`/`CourseCatalog` can back the
badge, teacher-derived-availability and lesson counts for `salsa_shines`
today. **Unverified in this pass** — not read, not asserted either way —
whether `content/styles/salsa_shines/style.json` carries attribution prose or
a step-glossary list at all; the engine/data files were read for scoring
logic, not for this screen's copy fields. First thing the next turn should
check before designing the widget.

**Touches if built:** a `StyleDetailView`; possibly a content-schema addition
for attribution/glossary if it turns out those fields don't exist yet.

---

## 4. Lesson-class screen (three visual classes)

**Design (`isLesson`):** a three-tab switcher (Graded/Locked/Demo-only), each
a full-weight card. Locked names the exact missing measurement ("Heel-swivel
direction: 2 of 6 teachers measured"). Demo-only gets the **same** card
treatment and CTA as Graded — explicitly not second-class.

**Code:** the data model is complete and already enforces the "locked is not
weak demoOnly" rule (`LessonKind` enum, `demoOnlyClass`, `reason` — all in
`course_catalog.dart`, all tested). No screen renders it; a lesson is reached
today only by hardcoding a `stepId`/`lessonClass` pair into `main.dart`.

**Touches if built:** a `LessonListView`/`LessonCard`, reachable from Style
detail (§3) — chained dependency, not independent of it.

---

## 5. Lesson flow (four steps, third closed)

**Design (`isFlow`):** step 1 "Learn the step" — a slow, counted teacher-figure
demo with spoken/printed counts. Step 2 "Try it without the beat" — shape
only. **Step 3 "Try it with the beat" — closed on purpose**, dashed card,
named reason (no beat grid, salsa's BPM disputed). Step 4 "Read the result" →
leads into the attempt summary (§7).

**Code:** none of the four steps exist as their own screen. What `main.dart`
opens today is closest to step 2+4 merged informally — the live camera path
goes straight to watching/measuring/judging with no preceding slow-counted
demo. **This is the coordinator's specifically named `flow` item.**

**Touches if built:** a `LessonFlowView` (4-step stepper). Steps 2–4 can
likely be built from what exists (`LiveSession`, `LiveView`'s existing
states). **Step 1 is more than a screen** — a slow, counted, mirrored
teacher-figure playback is not backed by anything read in this pass; whether
`DanceReference` (`packages/choreia_engine/lib/src/reference.dart`) carries
enough (posed angles over phase) to *drive* such a playback, versus needing a
real asset (video/animation) per step, is unverified and worth checking before
scoping. Step 3's closed presentation is the cheap part — a single
`PLACEHOLDER(flow)`-marked dashed card, once the shell exists.

---

## 6. Live tour — mirror mode and teacher-figure asset

**Design:** mirror toggle, default ON (K6 — the family rule this brief cites
by name); a mirrored teacher-figure image behind the live count.

**Code:** `LiveView` has no mirror concept at all — no field, no toggle, no
mirrored asset. The "img · mirrored teacher figure" the mockup shows is a
placeholder for reference footage/animation that does not exist as a
`content/` asset for any lesson yet.

**Touches if built:** a mirror-state field threaded from wherever it is
decided to live (session-level? app-level preference?) into `LiveView`; a
real asset pipeline for teacher-figure references — `asset`-category, not
`flow`, and the biggest single asset gap in the whole design (34 styles ×
however many lessons each, if every lesson wants one).

---

## 7. Attempt summary as its own screen

**Design (`isSum`):** a dedicated post-lesson screen — banded scores
("Alignment: strong", "Leg shape: steady"), one correction, a carried-vs-free
joint breakdown, phases with no judgement named as "not measured."

**Code:** `LiveView`'s `LiveJudged` branch shows the same *underlying* data
(`JudgeResult.findings`, each with `code`/`verdict`/`why`) inline, restyled
this turn with verdict-based colour, but never as its own screen and never
reduced to "bands" or "one correction" — it lists every finding, coloured by
verdict, exactly as the pre-existing data shape allows.

**Ruled this turn (structure wins — "style changes, inherits structure"):**
stays inline. **Flagged, not settled:** `UI-BRIEF.md` §3.8 already counts
Attempt Summary as a separate screen, which means the design may be *ahead of
the plan's own code* rather than simply ahead of what got built — a real
product question (is this its own screen with its own route, or does
`LiveJudged` grow into this in place?), the coordinator's to rule on.

---

## 8. Music picker

**Design (`isMusic`):** a dedicated "before you start" screen — two
first-class options (the app's own metronome / the learner's own device
music), a no-source-chosen state, explicitly stating there is no in-app music
catalogue.

**Code:** the *policy* is already decided and defended (K3, DEFTER C-018: $0
default, own-music-or-metronome) — but no screen or flow exists to act on it;
nothing in `lib/` reads or offers a music source today.

**Touches if built:** a `MusicPickerView`; wiring a chosen source (or its
absence) into whatever eventually drives playback/counting during Live.

---

## 9. Calibration step

**Design (§10 states gallery):** "One standing pass first — stand still for
five seconds so we learn your proportions. Until then we describe, we don't
rate." A named, one-time flow before scoring is trusted.

**Code:** no calibration flow exists. K8 (no score before calibration) is
already enforced at the *type* level elsewhere in this codebase (`LiveMeasured`
has no band field at all) — but the design's specific "stand still 5s" UX for
**getting into** a calibrated state is new, not just unrendered.

**Touches if built:** unclear whether this maps to an existing engine concept
(is there a calibration measurement already computed and merely unsurfaced?)
or is a genuinely new capability — check before scoping, don't assume.

---

## 10. Save-failure state

**Design (§10 states gallery), tag `ERROR`:** "That didn't go through. We
couldn't save this practice. It's on our side, not yours. The lesson is still
open."

**Code:** no `SessionStore` write happens anywhere in `lib/` yet — this app
does not currently persist a session at all (consistent with `ProgressView`
being unreachable, §1). A save-failure state has nothing to attach to until
persistence exists.

**Touches if built:** wiring `LiveSession`/`main.dart` to a `SessionStore`
instance (the family's shared, JSONL, append-only store — see
`ProgressSummary.from` for the read side, already written) is the real
prerequisite; the error state itself is small once that exists.

---

## 11. Progress screen — tabs vs. stacked sections (a styling note, not a gap)

**Design:** Recorded/Assessed as two tabs, one mounted at a time.

**Code (this turn's deliberate choice, not a missing piece):** kept as three
always-mounted, strongly separated sections instead. The functional content
is complete — this is a chrome difference, not a design-ahead-of-code item.
Recorded verbatim here only so a future reviewer comparing screenshot to
mockup does not mistake it for an omission: see `lib/app/progress_view.dart`'s
own file doc comment for the full reasoning (co-presence assertions in
`test/progress_test.dart` would not mean what they were written to mean under
real tab mount/unmount).

---

## 12. Design-assumed live state with no engine counterpart

**Design (`LIVE.light`):** "Too dark to see" — a light-level quality issue.

**Code:** `QualityIssue` (`motion_core`) has exactly three values —
`outOfFrame`, `lowTrackingConfidence`, `torsoUnreliable` — none of which is a
light-level signal. **Ruled this turn:** not fabricated; `LiveNoPerson` is
styled with the design's visual pattern but only the three real issues, in
their existing copy. Whether a light-level signal gets added to the engine, or
the design's third variant simply does not apply to this app, is the
coordinator's call — not decided here.

---

## Summary table

| # | Item | Category | Screen/nav needed | Data/asset gap |
|---|---|---|---|---|
| 1 | Navigation shell | flow | — (prerequisite for 2–8) | none |
| 2 | Library | flow + data | yes | 32 styles have no content |
| 3 | Style detail | flow + copy | yes | attribution/glossary fields unverified |
| 4 | Lesson-class screen | flow | yes | none (data model complete) |
| 5 | Lesson flow, step 3 closed | flow | yes | step 1's teacher-demo mechanism unverified |
| 6 | Mirror mode + teacher-figure asset | asset | no (a field on existing screen) | reference imagery for every lesson |
| 7 | Attempt summary as its own screen | flow | maybe (product decision) | none (data exists, presentation doesn't) |
| 8 | Music picker | flow | yes | none (policy already decided) |
| 9 | Calibration step | flow + data | yes | unclear if engine backs it |
| 10 | Save-failure state | flow | no | needs `SessionStore` wired up at all |
| 11 | Progress tabs vs. sections | — | — | styling note only, not a gap |
| 12 | "Low light" live state | data | no | engine has no light-level `QualityIssue` |

---

## Addendum — the brief asked for more than v1 delivered

`docs/design/UI-BRIEF.md` §3.1 (Onboarding) and §3.2 (Home) are not in
`Choreia.dc.html` at all — the design panel's nine screens (§Summary table
above) do not include either. Not a code gap, a **design-panel gap**: worth
naming for whoever plans the next design-panel round, not just the next
construction turn. Two things this doc's author would otherwise have to
rediscover:

- §3.1's mandatory, un-skippable honesty card ("We do **not** score your
  timing yet, your arms, or your groove") has no home in v1 at all — it is
  not merely unbuilt, it has never been drawn.
- §3.3 (Library) cites `content/library.json` as the 34-style source. No such
  file exists — `CourseCatalog` reads one `style.json` per style id, and the
  32 not-yet-built styles live only inside `Choreia.dc.html`'s own mock
  `WAVES` array (§2 above). If `library.json` is meant to be real, it does not
  exist yet either — one more reason §2's "derive vs. declare" question needs
  an answer before Library gets built.
