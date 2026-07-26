#!/usr/bin/env python3
"""Reference harvest pilot: probe → download → extract → gate.

Deliberately staged. Probing is metadata-only and costs nothing, so it runs
first and answers the questions that decide whether a download is worth doing at
all: does the video still exist, is it short enough to be a single-step
tutorial, and is it from a channel we have not already counted. Only what
survives the probe gets fetched.

Retention rule (C-024): the media is working material, not product. Landmarks,
angles, beat grids and provenance are kept; the video and its audio are deleted
once extraction succeeds.

Usage:
  python3 tools/harvest.py --probe                 # metadata only, no download
  python3 tools/harvest.py --fetch <step>          # download probed candidates
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
WORK = REPO / "harvest"
PROBE_OUT = WORK / "probe.json"

YT = "https://www.youtube.com/watch?v="

# Candidates from the harvest research (R5a). Blog-post sources are excluded:
# a written tutorial has no frames to extract.
CANDIDATES: dict[str, list[str]] = {
    "hh_cabbage_patch": ["0iweU5HmAUQ", "V6w_9vWXXjE", "N4STZCPuhf0", "EUuqLa1oqo8"],
    "hh_roger_rabbit": ["bdY2Pwqj-9A", "pua9UszdO24", "DEFnniCN7ok", "blWeCJW2Peo"],
    "hh_running_man": ["lYpRasK4c9k", "k22Bm2pMyD4", "UO9Ehsdt2IE"],
}

# A single-step tutorial that runs half an hour is a class, not a step demo.
MAX_USEFUL_SECONDS = 900
MIN_USEFUL_SECONDS = 20


def probe_one(video_id: str) -> dict:
    """Metadata only — no media leaves the network."""
    try:
        r = subprocess.run(
            ["yt-dlp", "--dump-json", "--no-warnings", "--skip-download",
             YT + video_id],
            capture_output=True, text=True, timeout=90,
        )
    except subprocess.TimeoutExpired:
        return {"videoId": video_id, "status": "timeout"}

    if r.returncode != 0:
        first = (r.stderr or "").strip().splitlines()
        return {
            "videoId": video_id,
            "status": "unavailable",
            "error": first[-1][:200] if first else "unknown",
        }

    try:
        d = json.loads(r.stdout)
    except json.JSONDecodeError:
        return {"videoId": video_id, "status": "unparseable"}

    dur = d.get("duration") or 0
    if dur < MIN_USEFUL_SECONDS:
        verdict, why = "reject", f"too short ({dur}s)"
    elif dur > MAX_USEFUL_SECONDS:
        verdict, why = "review", f"long ({dur}s) — a class, needs segment picking"
    else:
        verdict, why = "candidate", "usable length"

    return {
        "videoId": video_id,
        "status": "ok",
        "verdict": verdict,
        "why": why,
        "title": d.get("title", "")[:120],
        "channel": d.get("channel") or d.get("uploader", ""),
        "channelId": d.get("channel_id", ""),
        "durationSec": dur,
        "uploadDate": d.get("upload_date", ""),
        "license": d.get("license") or "unknown",
        "url": YT + video_id,
    }


def probe_all() -> dict:
    WORK.mkdir(exist_ok=True)
    out: dict[str, list[dict]] = {}
    for step, ids in CANDIDATES.items():
        print(f"\n=== {step} ===")
        rows = []
        for vid in ids:
            info = probe_one(vid)
            rows.append(info)
            if info.get("status") != "ok":
                print(f"  {vid}  ✗ {info.get('status')}: "
                      f"{info.get('error', '')[:80]}")
                continue
            print(f"  {vid}  {info['verdict']:<10} {info['durationSec']:>5}s  "
                  f"{info['license']:<12} {info['channel'][:28]:<30} "
                  f"{info['title'][:44]}")
        out[step] = rows

        # The independence rule (C-025) counts distinct channels, not videos.
        chans = {r.get("channelId") for r in rows
                 if r.get("status") == "ok" and r.get("verdict") != "reject"}
        chans.discard("")
        chans.discard(None)
        mark = "✅" if len(chans) >= 3 else ("⚠️" if len(chans) == 2 else "❌")
        print(f"  → {mark} {len(chans)} distinct channel(s) usable "
              f"(≥3 required — same studio does not count twice)")

    PROBE_OUT.write_text(json.dumps(out, indent=2, ensure_ascii=False),
                         encoding="utf-8")
    print(f"\nwritten: {PROBE_OUT.relative_to(REPO)}")
    return out


def fetch_and_extract(step: str, *, keep_media: bool = False) -> int:
    """Downloads probed candidates, extracts landmarks, then deletes the media.

    The deletion is the point, not housekeeping: what the product is allowed to
    carry forward is the derived skeleton, never the recording it came from
    (C-024).
    """
    if not PROBE_OUT.exists():
        print("run --probe first")
        return 1
    probe = json.loads(PROBE_OUT.read_text(encoding="utf-8"))
    rows = [r for r in probe.get(step, [])
            if r.get("status") == "ok" and r.get("verdict") != "reject"]
    if not rows:
        print(f"no usable candidates for {step}")
        return 1

    media = WORK / "media" / step
    fixtures = WORK / "fixtures" / step
    media.mkdir(parents=True, exist_ok=True)
    fixtures.mkdir(parents=True, exist_ok=True)

    extractor = (REPO.parents[1] / "motion-core" / "lib" / "tools" /
                 "fixture_pipeline" / "extract_landmarks.py")
    venv_py = (REPO.parents[1] / "motion-core" / "lib" / "tools" /
               "fixture_pipeline" / ".venv" / "bin" / "python")
    if not extractor.exists() or not venv_py.exists():
        print(f"extraction pipeline not found: {extractor}")
        return 1

    ok = 0
    for r in rows:
        vid = r["videoId"]
        mp4 = media / f"{vid}.mp4"
        print(f"\n--- {vid}  {r['channel'][:30]} ({r['durationSec']}s)")

        if not mp4.exists():
            dl = subprocess.run(
                ["yt-dlp", "-f", "bv*[height<=720][ext=mp4]+ba[ext=m4a]/b[height<=720]",
                 "--merge-output-format", "mp4", "-o", str(mp4),
                 "--no-warnings", "--no-playlist", r["url"]],
                capture_output=True, text=True, timeout=900)
            if dl.returncode != 0 or not mp4.exists():
                tail = (dl.stderr or "").strip().splitlines()
                print(f"    download failed: {tail[-1][:140] if tail else '?'}")
                continue
        size_mb = mp4.stat().st_size / 1e6
        print(f"    downloaded {size_mb:.1f} MB")

        # The shared extractor derives its recording metadata from the
        # filename, using a contract built for controlled studio shoots
        # (subject / lighting / clothing / distance-in-cm). None of that is
        # knowable for a harvested public video. The name below only exists to
        # satisfy that parser; its values are meaningless and are REPLACED with
        # honest provenance immediately after extraction. Leaving invented
        # values in place would be worse than useless — threshold calibration
        # groups takes by exactly these fields. See M-C-13.
        staged = media / (f"{step}__yt{vid.lower().replace('-', '')}"
                          f"__bilateral__frontal__bright__tight__0__t01.mp4")
        if staged.exists():
            staged.unlink()
        mp4.rename(staged)

        ex = subprocess.run(
            [str(venv_py), str(extractor), "--input", str(media),
             "--output", str(fixtures), "--variant", "heavy",
             "--app", "choreia", "--overwrite"],
            capture_output=True, text=True, timeout=3600)
        produced = fixtures / f"{staged.stem}.heavy.json"
        if ex.returncode != 0 or not produced.exists():
            tail = (ex.stderr or ex.stdout or "").strip().splitlines()
            print(f"    extraction failed: {tail[-1][:160] if tail else '?'}")
            staged.rename(mp4)
            continue

        doc = json.loads(produced.read_text(encoding="utf-8"))
        doc["recordingMeta"] = {
            "source": "harvested_public_video",
            "device": "unknown",
            "fps": doc.get("recordingMeta", {}).get("fps", 0),
            "lighting": "unknown",
            "bodyProfile": "unknown",
            "cameraSetup": "unknown_pending_angle_gate",
            "notes": "filename-derived studio metadata does not apply to "
                     "harvested video; see provenance",
        }
        doc["provenance"] = {
            "schemaVersion": 1,
            "platform": "youtube",
            "videoId": vid,
            "url": r["url"],
            "channel": {"name": r.get("channel", ""),
                        "id": r.get("channelId", ""),
                        "independent": None},
            "title": r.get("title", ""),
            "license": r.get("license", "unknown"),
            "uploadDate": r.get("uploadDate", ""),
            "durationSec": r.get("durationSec", 0),
            "mediaRetained": False,
        }
        final = fixtures / f"{vid}.json"
        final.write_text(json.dumps(doc, ensure_ascii=False), encoding="utf-8")
        produced.unlink(missing_ok=True)

        print(f"    extracted {len(doc.get('frames', []))} frames -> {final.name}")
        ok += 1
        mp4 = staged

        if not keep_media:
            mp4.unlink(missing_ok=True)
            print("    media deleted (C-024: only derived data is retained)")

    print(f"\n{ok}/{len(rows)} takes extracted for {step}")
    return 0 if ok else 1


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--probe", action="store_true",
                    help="metadata only, downloads nothing")
    ap.add_argument("--fetch", metavar="STEP",
                    help="download + extract probed candidates for a step")
    ap.add_argument("--keep-media", action="store_true",
                    help="debug only; violates the retention rule if committed")
    args = ap.parse_args()
    if args.probe:
        probe_all()
        return 0
    if args.fetch:
        return fetch_and_extract(args.fetch, keep_media=args.keep_media)
    ap.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
