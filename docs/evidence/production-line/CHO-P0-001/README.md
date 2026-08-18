# CHO-P0-001 — Katalog ve yüzey dürüstlüğünü kilitle

**State:** ACCEPTED (this package). **Date:** 2026-08-19. **Owner:** Choreia solo
session. **Reviewer:** none assigned — R0/R1 risk (content/UI honesty verification,
no payment/security/migration/privacy surface touched), roadmap §16 does not require
independent R2 review at this risk tier.

**Input SHA:** app HEAD `a9a8349` (unchanged by this task — verification and
packaging only, no code or content edit was needed), common pin
`f13bdc93b2eae2f741bfcdb4c9270a88e5d75e5d`. Both confirmed live-fresh this session,
not carried over from yesterday's claim.

## Why this package looks the way it does

The 2026-08-18 kickoff (`R27-uretim-hatti-prep-2026-08-18.md`) already re-measured
the original P0 finding and concluded the "salsa_shines=live but unreachable"
symptom was real but the "dishonesty" framing was wrong — it's a known, intentional,
already-tested two-axis design (content truth vs. release gate, M-F-130). That
correction is accepted as the starting point of this session (see the 2026-08-19
kickoff's "BİLİNEN DURUM"). What R27 flagged as still open was **format, not
substance**: no `docs/evidence/production-line/` package existed, 29/31 comingSoon
entries had only been spot-checked by directory listing, and a 2026-08-17 simulator
input-bridge failure had blocked real-screen verification.

This session's work was to close exactly those three gaps — verify exhaustively, get
real screens, package it — not to re-relitigate a diagnosis that was already correct.

## What's in this package

| File | What it proves |
|---|---|
| `claim-matrix.md` | Every catalogue claim (tally sentence, per-style badge/counts, the two hero cards) matched against `library.json`, disk content, `CourseCatalog` parsing, and a real screen |
| `catalog_cross_check.py` + `catalog_cross_check_output.txt` | Exhaustive (34/34, not sampled) structural audit: declared status vs. `style.json` presence on disk. 0 mismatches. Corrects R27's "29 comingSoon" to the actual 31, and names the 3 folders that hold orphaned `steps/*.json` without a `style.json` |
| `gates-sh-output-2026-08-19.txt` | Fresh (today, not carried over) `bash tool/gates.sh` run: 269 Flutter tests + 36 engine tests + 23 self-tests/validators, all green, exit 0 |
| `screenshots/styles-*.png` | The Styles tab, real simulator screen capture, 4 device sizes (see below) |
| `input-bridge-retest.md` | The 2026-08-17 "simulator input completely unresponsive" finding, retested this session — resolved, was environmental |

## The 4-viewport screenshot set

All four show byte-identical catalogue copy — same tally sentence, same two hero
cards, same filter counts — proving the honesty language doesn't regress or get
truncated at different screen sizes:

| File | Device | Point space | Notes |
|---|---|---|---|
| `styles-iphone13mini-360x780.png` | iPhone 13 mini (`choreia-narrow`) | 360×780 | Narrowest supported phone — text-wrap stress case |
| `styles-iphone17pro-402x874.png` | iPhone 17 Pro (`choreia-hatti`) | 402×874 | The family's standard device-day simulator |
| `styles-iphone17promax-440x956.png` | iPhone 17 Pro Max | 440×956 | Largest phone |
| `styles-ipadpro13-1032x1376.png` | iPad Pro 13-inch (M5) | 1032×1376 | Tablet — see note below |

**iPad note (observed, not a CHO-P0-001 defect, not fixed here):** the app renders in
iPadOS's iPhone-compatibility window (a fixed-size inset frame on the iPad's own
Home Screen background), not a native full-screen iPad layout. Nothing in the
roadmap's W1 scope asks for iPad-adaptive layout yet, and `CHO-DEVICE-001`'s C3 cell
is about camera framing/landscape multi-angle, not this. Noted for whoever picks up
iPad-native layout later; out of scope here.

These are simulator screens verifying **UI honesty**, not `CHO-DEVICE-001`'s real
8-device physical matrix (camera liveness, thermal, FPS) — that gate stays
`EXTERNAL_GATE`, unaffected by this package.

## Corrected finding (supersedes the original P0 framing)

See `claim-matrix.md` §3 for the full evidence chain. Short version: `salsa_shines`
really is `live` (a scored, tested lesson exists) and really is unreachable (BPM ship
gate closed) — both true, on two axes that are deliberately never collapsed into one.
The screen never shows Salsa as "open" or hides that it has a graded lesson; it shows
**BUILT · NOT OPEN** with a named reason, on all 4 screenshots. The actual gap this
audit surfaces is narrower than "dishonest catalogue": **zero lessons in the shipped
app are simultaneously open and graded** (`hh_l1_bounce` is open/ungraded,
`ss_l1_footwork` is graded/closed). That's a content-completeness gap, not a
truth-in-labelling one — closed by `CHO-P0-003`/`CHO-P1-002` (real scored W1 content)
and by resolving Salsa's BPM (founder task, see below), not by editing
`library.json`.

## No content or code change was needed

The exhaustive audit found 0 structural mismatches and the existing UI
(`library_view.dart`, `library_catalog.dart`) already implements exactly what the
roadmap's checklist items 1-2 ask for (only-working-content-featured grouping,
`M-F-186` "no promise language" rule, badge system distinguishing scored /
open-ungraded / built-gated / on-hold / in-preparation). This package is
verification and formal evidence, not a fix — consistent with C-315's own finding
("malzeme var, format yok").

## Outstanding, not blocking this task's acceptance

- **Salsa BPM resolution** — founder ~10 min live-tap task
  (`tools/beat_annotate.py`; package staged at
  `scratch/2026-08-19-motion-orch/MANUAL-MOTION-CHOREIA-BPM-20260819.yaml`).
  `EXTERNAL_GATE` — reminded in-session, see PROGRESS.md/DEFTER entry for this date.
  Not required for CHO-P0-001 (catalog honesty holds regardless of whether Salsa's
  gate is open or closed); relevant to `CHO-P0-003`/W1 content-completeness work.
- **`CHO-DEVICE-001` 8-device physical matrix** — `EXTERNAL_GATE`, devices are with
  the founder, unaffected by this simulator-only package.
- **iPad-native layout** — observed, not scoped to any current task, noted above.
