#!/usr/bin/env python3
"""Does a judgment actually flow from reference to a scored verdict?

Choreia has no runtime yet (validate_reference.py's own note: "gerçek
tüketicisi SIFIR"). Before content/references/ss_shine_footwork.json +
content/styles/salsa_shines/steps/ss_shine_footwork.json are called "bound"
rather than merely "written", something has to consume them the way a future
scorer would and show the judgment moves — the fifth question (M-F-99/102/109)
applied to this specific pair.

This is a proof of the WIRING, not the runtime. It implements the two
unblocked errors' metrics (loaded_leg_knee_change, step_thigh_excursion) just
well enough to run one real clip and one deliberately corrupted copy through
them, and checks four things a silent binding failure could hide:

  1. A real clip (one of the reference's own 4 sources) does NOT trip either
     error — the reference is not so tight it flags its own evidence.
  2. A controlled corruption of that SAME clip DOES trip the corresponding
     error (M-C-01 pattern: mutate a known-good take, don't invent a "bad"
     clip from nothing — a synthetic worst-case can pass by accident, a
     targeted mutation of real data cannot).
  3. Mirroring the good clip changes NEITHER verdict — kural-7 (JabLab stance
     precedent): mirrorConfident:false on this reference means no error may
     depend on which side is which, and this is checked by construction
     (max-over-both-legs) rather than asserted in prose.
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

NO_WEIGHT_TRANSFER_MAX_DEG = 4.0
STEP_TOO_LARGE_MAX_DEG = 20.0


def _phase_bin_value(cycle: dict, joint: str, bin_idx: int) -> float:
    return cycle[joint][bin_idx]


def judge(cycle: dict, moment_a_bin: int, moment_b_bin: int) -> dict:
    """The two unblocked errors, computed the way a runtime would.

    Deliberately max()'d over both legs rather than "the loaded leg" (which
    would need a leading-side call this reference cannot make) — this is
    kural-7 enforced in the metric itself, not just documented.
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
        "NO_WEIGHT_TRANSFER": knee_delta < NO_WEIGHT_TRANSFER_MAX_DEG,
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
    calibration_check("NO_WEIGHT_TRANSFER ateşlenmedi", not gv["NO_WEIGHT_TRANSFER"],
          f"knee Δ={gv['kneeDeltaDeg']}° (eşik {NO_WEIGHT_TRANSFER_MAX_DEG}°)")
    calibration_check("STEP_TOO_LARGE ateşlenmedi", not gv["STEP_TOO_LARGE"],
          f"thigh Δ={gv['thighDeltaDeg']}° (eşik {STEP_TOO_LARGE_MAX_DEG}°)")

    print("\n2) KONTROLLÜ BOZULMA #1 — diz açısı moment_b'de moment_a'ya eşitlendi "
          "(M-C-01: gerçek klip mutasyonu, uydurma 'kötü' klip değil)")
    flat = flatten_knees(good, bin_a, bin_b)
    fv = judge(flat, bin_a, bin_b)
    check("NO_WEIGHT_TRANSFER ATEŞLENDİ", fv["NO_WEIGHT_TRANSFER"],
          f"knee Δ={fv['kneeDeltaDeg']}° (0.0 olmalı)")

    print("\n3) KONTROLLÜ BOZULMA #2 — uyluk açısı 25° abartıldı")
    wide = widen_thighs(good, bin_a, bin_b)
    wv = judge(wide, bin_a, bin_b)
    check("STEP_TOO_LARGE ATEŞLENDİ", wv["STEP_TOO_LARGE"],
          f"thigh Δ={wv['thighDeltaDeg']}°")

    print("\n4) AYNA-SİMETRİSİ (kural-7: mirrorConfident:false → taraf-bağımsız "
          "hüküm) — orijinal ile aynalanmış AYNI iki hükmü vermeli")
    mirrored_good = mirrored(good)
    mv = judge(mirrored_good, bin_a, bin_b)
    check("NO_WEIGHT_TRANSFER aynı", mv["NO_WEIGHT_TRANSFER"] == gv["NO_WEIGHT_TRANSFER"])
    check("STEP_TOO_LARGE aynı", mv["STEP_TOO_LARGE"] == gv["STEP_TOO_LARGE"])
    check("WRONG_FOOT hiç değerlendirilmedi (kod blocked, judge() onu hiç hesaplamıyor)",
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

    print("\n6) 4 KAYNAĞIN TAMAMINDA knee/thigh delta (eşik NEREDEN geldiğinin kanıtı)")
    per_source = []
    for vid in ("SHGkSbJm2Iw", "bqoNqA2hmE4", "jjP8bKWCg9U", "w4opJ2ezmd4"):
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
          f"(4°'lik eşik bu aralığın İÇİNDE — tek bir sabit derece eşiği "
          f"4 kaynağı da dürüstçe ayıramıyor)")

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
