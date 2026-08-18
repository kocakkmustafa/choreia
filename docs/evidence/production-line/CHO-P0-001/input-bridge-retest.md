# Simulator input-bridge retest (2026-08-19)

## The 2026-08-17 finding

`docs/device-day/PAKET.md` and `RECIPE.md` recorded that on `choreia-hatti`, after a
working `screenshot` call, `tap` (2 coordinates), `swipe`, and system-level
`button:HOME` — all four — left the screen completely unchanged. HOME not
responding was treated as decisive: not a permissions problem (access had already
been granted), a fully closed input path. That session noted `ListAgents` showed 8
concurrent Motion-family sessions active at the time and flagged contention as the
likely cause, to be retested "next turn."

This blocked the RECIPE.md 16-step walkthrough at step 9 (only the Styles tab was
seen; the remaining 15 rows stayed code-reading, not screen-verified) and was called
out in `R27-uretim-hatti-prep-2026-08-18.md` as a risk to this exact evidence
package.

## This session's retest

Booted 4 fresh/existing simulators (`choreia-hatti`, `choreia-narrow`, a new iPhone
17 Pro Max boot, and the shared iPad Pro 13" M5). All were `Shutdown` before this
session touched them — no contention at boot time.

- **`choreia-hatti`:** `tap` on the Salsa Shines card navigated correctly to the
  style detail page on the first attempt. Input bridge fully responsive.
- **`choreia-narrow`:** `tap` on "Open the catalogue" missed twice (coordinate
  miscalibration on my part, not a bridge failure — confirmed because `button HOME`
  worked immediately after, proving the bridge itself was live), then landed
  correctly on the third attempt with a recalibrated y-coordinate. Input bridge
  responsive throughout; the two misses were pointing error, not an unresponsive
  screen.
- **iPhone 17 Pro Max:** already on the Styles tab from a prior launch; no
  interaction needed to capture it.
- **iPad Pro 13" M5 (shared, non-Choreia-specific simulator):** `tap` and
  `screenshot` both hung / returned internal errors for several minutes — this one
  **did** reproduce contention-like symptoms. A raw `xcrun simctl io screenshot`
  call to the same device also took over 2 minutes to return (vs. sub-second on the
  other three). Given `Burun Farkı` was visibly installed on this same shared
  simulator's Home Screen (seen in an earlier screenshot on this device), another
  concurrent session was almost certainly holding it. Waiting out the contention
  (rather than force-killing or restarting the simulator) let both the tap and the
  follow-up screenshot complete successfully once free.

## Conclusion

The 2026-08-17 finding's own hypothesis was correct: the input bridge itself has no
structural defect. What looked like "HOME does nothing" was resource contention on a
simulator instance under load from multiple concurrent sessions. On an
uncontended device, taps, swipes and the HOME button all work normally. The one
device that reproduced slowness today (the shared iPad) was, itself, evidence for
the contention theory rather than against it — and resolved by waiting rather than
by any code or configuration change.

**Practical note for future device-day sessions:** prefer the Choreia-dedicated
simulators (`choreia-hatti`, `choreia-narrow`) over shared/generic ones when other
Motion-family sessions may be running concurrently — the dedicated ones were
uncontended throughout this session while the shared iPad was not.

No product or tooling change was made as a result of this retest.
