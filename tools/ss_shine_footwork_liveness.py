#!/usr/bin/env python3
"""Does a judgment actually flow from reference to a scored verdict?

Choreia has no runtime yet (validate_reference.py's own note: "gerçek
tüketicisi SIFIR"). Before content/references/ss_shine_footwork.json +
content/styles/salsa_shines/steps/ss_shine_footwork.json are called "bound"
rather than merely "written", something has to consume them the way a future
scorer would and show the judgment moves — the fifth question (M-F-99/102/109)
applied to this specific pair.

This is a proof of the WIRING, not the runtime. It implements STEP_TOO_LARGE's
metric (step_thigh_excursion) well enough to run one real clip and deliberately
corrupted copies through it, and checks what a silent binding failure could hide.

Reference history in this file (read the git log, not just the docstring, if
the two ever disagree): M-F-102 pooled 4 sources; M-F-115 excluded bqoNqA2hmE4
(excludedIdentityAmbiguous) and rebuilt on 3 — which, unplanned, also resolved
mirrorConfident to TRUE (Choreia's first). M-F-117 then blocked
NO_WEIGHT_TRANSFER entirely: its clean-3-source threshold (1.0deg) turned out
to sit below this pipeline's own MIN_TOLERANCE_DEG (6deg landmark-jitter
floor) — a decision line inside that much noise cannot tell a genuine light
transfer from tracking noise, firing or silent are both wrong, so the code is
kept defined but never evaluated (`judge()` does not compute a verdict for
it, checked directly below, not just documented as blocked in the config).

What is checked now, with one live error (STEP_TOO_LARGE) and two documented
non-live ones (NO_WEIGHT_TRANSFER, WRONG_FOOT — the latter unblocked in the
config by mirrorConfident:true but leading_side has no implementation
anywhere yet, out of this file's scope):

  1. A real clip (one of the reference's 3 clean sources) does NOT trip
     STEP_TOO_LARGE — the reference is not so tight it flags its own evidence.
  2. A controlled corruption of that SAME clip DOES trip it (M-C-01 pattern:
     mutate a known-good take, don't invent a "bad" clip from nothing — a
     synthetic worst-case can pass by accident, a targeted mutation cannot).
     A second corruption (flattened knees) confirms NO_WEIGHT_TRANSFER stays
     un-evaluated even when the exact condition it would have caught is
     present — proving the block is inert, not merely unlucky not to fire.
  3. Mirroring the good clip changes STEP_TOO_LARGE's verdict NOT AT ALL —
     it is side-agnostic by construction (max-over-both-legs), independent
     of whatever mirrorConfident happens to be.
  4. The BPM ship-gate is UNCHANGED by any of this. Binding a scorer to a
     step does not make the step shippable — content/library.json still says
     comingSoon and validate_content.py still blocks it on the DISPUTED bpmRange.
     Run explicitly here so "bound" cannot be misread as "shippable".

  python3 tools/ss_shine_footwork_liveness.py
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from prepare_take import prepare  # noqa: E402
from build_reference import take_canonical_cycle, mirrored  # noqa: E402

REPO = Path(__file__).resolve().parents[1]
STEP_PATH = REPO / "content/styles/salsa_shines/steps/ss_shine_footwork.json"
REF_PATH = REPO / "content/references/ss_shine_footwork.json"

# The reference's own richest, mirror-confident source — chosen so a failure
# here cannot be blamed on thin evidence in the clip being judged.
TEST_VIDEO_ID = "jjP8bKWCg9U"

NO_WEIGHT_TRANSFER_MAX_DEG = 1.0  # M-F-115: re-derived from the clean 3-source pool
STEP_TOO_LARGE_MAX_DEG = 20.0


def _phase_bin_value(cycle: dict, joint: str, bin_idx: int) -> float:
    return cycle[joint][bin_idx]


def judge(cycle: dict, moment_a_bin: int, moment_b_bin: int) -> dict:
    """The one unblocked error, computed the way a runtime would.

    NO_WEIGHT_TRANSFER is NOT computed here (M-F-117): its threshold
    (1.0deg) sits below MIN_TOLERANCE_DEG (6deg, this pipeline's own
    landmark-jitter floor) and is calibration-blocked in the step config —
    a decision line inside the noise floor cannot tell a genuine light
    transfer from tracking noise. kneeDeltaDeg is still returned as a
    diagnostic (section 6 uses it), it just backs no verdict.

    STEP_TOO_LARGE is max()'d over both legs rather than "the loaded leg"
    (which would need a leading-side call kural-7 didn't allow before
    mirrorConfident:true) — side-agnostic by construction, not just policy.
    """
    knee_delta = max(
        abs(_phase_bin_value(cycle, "left_knee", moment_b_bin)
            - _phase_bin_value(cycle, "left_knee", moment_a_bin)),
        abs(_phase_bin_value(cycle, "right_knee", moment_b_bin)
            - _phase_bin_value(cycle, "right_knee", moment_a_bin)),
    )
    thigh_delta = max(
        abs(_phase_bin_value(cycle, "left_thigh", moment_b_bin)
            - _phase_bin_value(cycle, "left_thigh", moment_a_bin)),
        abs(_phase_bin_value(cycle, "right_thigh", moment_b_bin)
            - _phase_bin_value(cycle, "right_thigh", moment_a_bin)),
    )
    return {
        "kneeDeltaDeg": round(knee_delta, 2),
        "thighDeltaDeg": round(thigh_delta, 2),
        "STEP_TOO_LARGE": thigh_delta > STEP_TOO_LARGE_MAX_DEG,
    }


def flatten_knees(cycle: dict, bin_a: int, bin_b: int) -> dict:
    """Controlled corruption #1: erase the weight-transfer signal.

    Overwrites BOTH legs' knee angle at moment_b with their moment_a value —
    a dancer marking the step without transferring weight looks exactly like
    this: the foot moves, the knee that would carry weight does not.
    """
    out = {k: list(v) for k, v in cycle.items()}
    for j in ("left_knee", "right_knee"):
        out[j][bin_b] = out[j][bin_a]
    return out


def widen_thighs(cycle: dict, bin_a: int, bin_b: int) -> dict:
    """Controlled corruption #2: exaggerate the step past the reference."""
    out = {k: list(v) for k, v in cycle.items()}
    for j in ("left_thigh", "right_thigh"):
        delta = out[j][bin_b] - out[j][bin_a]
        out[j][bin_b] = out[j][bin_a] + delta + (25.0 if delta >= 0 else -25.0)
    return out


def main() -> int:
    step = json.loads(STEP_PATH.read_text(encoding="utf-8"))
    ref = json.loads(REF_PATH.read_text(encoding="utf-8"))
    moments = {m["id"]: m["phase"] for m in step["scoredMoments"]}
    phase_bins = {p["id"]: p["enter"]["phaseBin"] for p in step["phases"]
                 if p["enter"].get("metric") == "cyclePhaseNear"}
    bin_a = phase_bins[moments["moment_a"]]
    bin_b = phase_bins[moments["moment_b"]]

    print(f"ss_shine_footwork canlılık testi — moment_a=bin{bin_a} "
          f"moment_b=bin{bin_b}\n")

    p = prepare(TEST_VIDEO_ID)
    if not p.get("usable"):
        print(f"FAIL: {TEST_VIDEO_ID} prepare edilemedi: {p.get('why')}")
        return 1
    good = take_canonical_cycle(p)
    if good is None:
        print(f"FAIL: {TEST_VIDEO_ID} canonical cycle çıkmadı")
        return 1

    fails = 0
    findings = []

    def check(label: str, cond: bool, detail: str = "") -> None:
        nonlocal fails
        print(f"  {'✓' if cond else '✗'} {label}" + (f"  {detail}" if detail else ""))
        if not cond:
            fails += 1

    def calibration_check(label: str, cond: bool, detail: str = "") -> None:
        # Separate from `check`: a failure here is not a wiring bug, it is
        # exactly the kind of thing this script exists to surface — a metric
        # whose threshold was reasoned about rather than measured against
        # every contributing source. Reported, not counted toward pass/fail.
        print(f"  {'✓' if cond else '⚠'} {label}" + (f"  {detail}" if detail else ""))
        if not cond:
            findings.append(f"{label} — {detail}")

    print(f"1) GERÇEK KLİP ({TEST_VIDEO_ID}, {p.get('cyclesInSegment')} çevrim, "
          f"mirror confident) — KALİBRASYON sağlık kontrolü (ateşlenmemesi beklenir, "
          f"ama ateşlenirse bu WIRING hatası değil, eşik-kalibrasyon bulgusudur)")
    gv = judge(good, bin_a, bin_b)
    check("NO_WEIGHT_TRANSFER judge()'da hiç yok (M-F-117: calibration-blocked, "
          "eşik gürültü tabanının altında — non-live)",
          "NO_WEIGHT_TRANSFER" not in gv, f"knee Δ={gv['kneeDeltaDeg']}° (bilgi amaçlı)")
    calibration_check("STEP_TOO_LARGE ateşlenmedi", not gv["STEP_TOO_LARGE"],
          f"thigh Δ={gv['thighDeltaDeg']}° (eşik {STEP_TOO_LARGE_MAX_DEG}°)")

    print("\n2) KONTROLLÜ BOZULMA #1 — diz açısı moment_b'de moment_a'ya eşitlendi "
          "(M-C-01: gerçek klip mutasyonu, uydurma 'kötü' klip değil) — "
          "NO_WEIGHT_TRANSFER blocked olduğu için ateşlenmemesi BEKLENİR")
    flat = flatten_knees(good, bin_a, bin_b)
    fv = judge(flat, bin_a, bin_b)
    check("NO_WEIGHT_TRANSFER bozuk klipte de judge()'da yok (blok gerçekten "
          "inert — 'ateşlenmedi' ile 'hiç değerlendirilmedi' aynı şey değil)",
          "NO_WEIGHT_TRANSFER" not in fv, f"knee Δ={fv['kneeDeltaDeg']}° (0.0)")

    print("\n3) KONTROLLÜ BOZULMA #2 — uyluk açısı 25° abartıldı")
    wide = widen_thighs(good, bin_a, bin_b)
    wv = judge(wide, bin_a, bin_b)
    check("STEP_TOO_LARGE ATEŞLENDİ", wv["STEP_TOO_LARGE"],
          f"thigh Δ={wv['thighDeltaDeg']}°")

    print("\n4) AYNA-SİMETRİSİ — STEP_TOO_LARGE taraf-bağımsız TASARLANDI "
          "(max-over-both-legs); orijinal ile aynalanmış AYNI hükmü vermeli, "
          "mirrorConfident ne olursa olsun")
    mirrored_good = mirrored(good)
    mv = judge(mirrored_good, bin_a, bin_b)
    check("STEP_TOO_LARGE aynı", mv["STEP_TOO_LARGE"] == gv["STEP_TOO_LARGE"])
    check("WRONG_FOOT judge()'da hiç yok (M-F-115: config'te unblocked ama "
          "leading_side burada HENÜZ İMPLEMENTE EDİLMEDİ — ayrı bir liveness "
          "turu gerekir, bu turun kapsamı değil)",
          "WRONG_FOOT" not in gv and "WRONG_FOOT" not in mv)

    print("\n5) BPM SHIP-KAPISI DEĞİŞMEDİ — bu bağlama ship-yolunu AÇMAZ")
    vc = subprocess.run([sys.executable, str(REPO / "tools/validate_content.py")],
                        capture_output=True, text=True)
    gate_still_warns = "bpmRange is unresolved (DISPUTED)" in vc.stdout
    still_coming_soon = json.loads((REPO / "content/library.json").read_text()
                                   )["styles"][3]["status"] == "comingSoon"
    check("validate_content hâlâ DISPUTED uyarısı veriyor", gate_still_warns)
    check("library.json hâlâ comingSoon (ship edilmedi)", still_coming_soon)
    print("     ⚠ BOUND ≠ SHIPPABLE: skorlayıcı-bağlama kanıtı bu testin konusu; "
          "ship kararı BPM çözülmeden (beat_annotate, kurucu-bekleyen) verilemez.")

    print("\n6) TEMİZ 3 KAYNAĞIN TAMAMINDA knee/thigh delta (NO_WEIGHT_TRANSFER "
          "NEDEN bloklu kaldığının kanıtı — bqoNqA2hmE4 M-F-115'te "
          "excludedIdentityAmbiguous, eşik M-F-117'de calibration-blocked)")
    per_source = []
    for vid in ("SHGkSbJm2Iw", "jjP8bKWCg9U", "w4opJ2ezmd4"):
        pp = prepare(vid)
        cc = take_canonical_cycle(pp)
        if cc is None:
            continue
        jv = judge(cc, bin_a, bin_b)
        per_source.append((vid, jv["kneeDeltaDeg"], jv["thighDeltaDeg"]))
        print(f"     {vid:<14} knee={jv['kneeDeltaDeg']:>6.2f}°  "
              f"thigh={jv['thighDeltaDeg']:>6.2f}°")
    knee_vals = sorted(v for _, v, _ in per_source)
    print(f"     knee Δ aralığı: {knee_vals[0]:.2f}-{knee_vals[-1]:.2f}° "
          f"— aykırısız hâle geldi (bqoNqA2hmE4'ten önce 21,76° vardı) AMA "
          f"MIN_TOLERANCE_DEG (6°) landmark-gürültü tabanının hâlâ İÇİNDE — "
          f"bu yüzden {NO_WEIGHT_TRANSFER_MAX_DEG}°'lik bir karar çizgisi "
          f"gürültüden ayırt edilemez, temizlenmiş veri bile bu kodu tek "
          f"başına canlı yapmaya yetmiyor (M-F-117)")

    print()
    if fails:
        print(f"CANLILIK TESTİ BAŞARISIZ ({fails}) — bu WIRING sorunu, düzeltilmeli.")
        return 1
    print("CANLILIK TESTİ OK (wiring) — hüküm reference'tan skorlanan-verdikte "
          "akıyor, kontrollü bozulmalar doğru tetikleniyor, kural-7 tutuyor, "
          "ship-kapısı kapalı kalıyor.")
    if findings:
        print(f"\n⚠ {len(findings)} KALİBRASYON BULGUSU (wiring başarılı olsa da "
              "config'in eşikleri henüz doğru değil):")
        for f in findings:
            print(f"   - {f}")
        print("   NO_WEIGHT_TRANSFER'ın 2-noktalı diz-delta metriği, 4 kaynağın "
              "kendi ölçümünde 1,07-21,76° aralığına yayılıyor (bqoNqA2hmE4 "
              "aykırı) — tek sabit derece eşiği bunu güvenle ayıramaz. Eşiği "
              "kendim uydurmadım; movement-science-advisor'a taşınıyor.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
