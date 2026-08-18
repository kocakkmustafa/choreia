#!/usr/bin/env python3
"""CHO-P0-001 exhaustive catalogue cross-check.

Reads content/library.json and, for every one of the 34 declared styles,
checks the disk directly against the M-F-123 lattice rule already written
into library.json's own statusLattice.rule block:

    live       -> style.json has >=1 lessons[].scored==true AND honesty.measured non-empty
    demoOpen   -> style.json has >=1 lessons[].demoOnly==true AND scored count == 0
    comingSoon -> no openable (demoOnly) lesson -- including style.json absence

This script checks the STRUCTURAL half only (style.json presence/absence vs
declared status), because that half is fully mechanical. The
scored/demoOnly/honesty.measured half is exercised by the Dart test suite
(library_catalog_test.dart, style_detail_test.dart) against the parsed
CourseCatalog -- this script and that suite check different layers of the
same claim.

Run from ventures/choreia/app/:
    python3 docs/evidence/production-line/CHO-P0-001/catalog_cross_check.py
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))))
LIBRARY_JSON = os.path.join(ROOT, "content", "library.json")
STYLES_DIR = os.path.join(ROOT, "content", "styles")


def main() -> int:
    with open(LIBRARY_JSON, "r", encoding="utf-8") as f:
        doc = json.load(f)
    styles = doc["styles"]

    print(f"Total styles declared in library.json: {len(styles)}")
    print()
    header = f"{'id':28s} {'wave':5s} {'status':11s} {'dirExists':10s} {'styleJson':10s} stepFiles"
    print(header)
    print("-" * len(header))

    mismatches = []
    on_disk_no_style_json = []

    for s in styles:
        sid = s["id"]
        status = s["status"]
        wave = str(s.get("wave", "-"))
        dirpath = os.path.join(STYLES_DIR, sid)
        dir_exists = os.path.isdir(dirpath)
        style_json = os.path.isfile(os.path.join(dirpath, "style.json")) if dir_exists else False
        step_files = []
        if dir_exists:
            stepsdir = os.path.join(dirpath, "steps")
            if os.path.isdir(stepsdir):
                step_files = sorted(os.listdir(stepsdir))
        print(f"{sid:28s} {wave:5s} {status:11s} {str(dir_exists):10s} {str(style_json):10s} {step_files}")

        # The lattice's own written rule: comingSoon <=> no style.json.
        if status == "comingSoon" and style_json:
            mismatches.append((sid, "comingSoon but HAS style.json (should be demoOpen/live)"))
        if status in ("demoOpen", "live") and not style_json:
            mismatches.append((sid, f"{status} but NO style.json (should be comingSoon)"))
        if status == "comingSoon" and dir_exists and not style_json and step_files:
            on_disk_no_style_json.append((sid, step_files))

    print()
    print(f"STRUCTURAL MISMATCHES (status vs style.json presence): {mismatches if mismatches else 'NONE -- 0/%d'  % len(styles)}")
    print()
    print("comingSoon styles that DO have a directory with orphaned steps/*.json but no")
    print("style.json (still lattice-consistent -- style.json absence is what the rule")
    print("checks, not directory absence; these are known/tracked raw step fixtures, see")
    print("tools/prepare_take.py and content/metric-vocabulary.json references):")
    for sid, files in on_disk_no_style_json:
        print(f"  - {sid}: {files}")
    print()
    comingsoon_count = sum(1 for s in styles if s["status"] == "comingSoon")
    print(f"comingSoon total: {comingsoon_count} (R27 2026-08-18 said '29' -- exhaustive count "
          f"today is {comingsoon_count}; R27's figure undercounted by not exhaustively listing "
          f"every entry, though its conclusion -- 'no fake/oversold status' -- holds)")

    return 1 if mismatches else 0


if __name__ == "__main__":
    sys.exit(main())
