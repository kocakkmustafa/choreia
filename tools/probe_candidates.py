#!/usr/bin/env python3
"""Metadata-only triage of harvest candidates, before anything is downloaded.

Answers the two questions that decide whether a candidate is worth fetching,
and one that decides whether it is worth *counting*:

  1. Is it landscape?      Vertical/Shorts framing crops the legs out of a
                           footwork tutorial, and the frames it does keep enter
                           the pipeline at a different aspect ratio (C-060).
  2. Is it step-length?    A 30-minute video is a class, not a step demo.
  3. Is the channel new?   The >=3-independent-instructor rule (C-025 / M-C-04)
                           counts channels, not videos.

Two things here are deliberate and easy to get wrong:

* **Orientation comes from the real stream resolution, never from the title.**
  A clip can be vertical without saying "#shorts" and can say "#shorts" while
  being landscape. The one take this project lost to framing, k22Bm2pMyD4, was
  608x1080 — the resolution caught it, no keyword would have.

* **Channel identity is `channel_id`, not the channel name.** Display names are
  editable; the UC-id is not. Counting by name lets one renamed channel pass as
  several independent instructors, which is precisely the failure the rule
  exists to prevent.

The already-used set is read off disk rather than hardcoded, so it cannot drift
away from what was actually harvested.

  python3 tools/probe_candidates.py --step hh_roger_rabbit ID [ID ...]
  python3 tools/probe_candidates.py --step hh_running_man --from-file cands.txt
  python3 tools/probe_candidates.py --used            # just show what we have
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

HARVEST = Path(os.path.expanduser("~/motion-harvest/choreia"))
RAW = HARVEST / "raw"
LANDMARKS = HARVEST / "landmarks"

YT = "https://www.youtube.com/watch?v="

# A single-step tutorial shorter than this is a teaser; longer is a class.
MIN_SECONDS = 60
MAX_SECONDS = 900

# Which harvested video belongs to which step. The extractor's filename schema
# does not survive into the raw metadata, so the mapping lives here until the
# rig records it (M-C-13).
STEP_OF: dict[str, str] = {
    "bdY2Pwqj-9A": "hh_roger_rabbit",   # James Deane
    "pua9UszdO24": "hh_roger_rabbit",   # Howcast
    "DEFnniCN7ok": "hh_roger_rabbit",   # Nustudios
    "blWeCJW2Peo": "hh_roger_rabbit",   # Danceopedia
    "5MQEtoEKdEw": "hh_roger_rabbit",   # Kiarilk
    "_G-hONZsj1w": "hh_roger_rabbit",   # The Shed
    "35sk_G8Vf9o": "hh_roger_rabbit",   # Versa-Style Street Dance Company
    "Ce3NCRk1Nl4": "hh_roger_rabbit",   # KAFQA Dance
    "n3keE6peOE4": "hh_roger_rabbit",   # VincaniTV
    "kUQTYnYDipk": "hh_roger_rabbit",   # DanceKizombaTV
    "GXKNLmjxodU": "hh_roger_rabbit",   # STEEZY
    "3pg3AQ7puV0": "hh_roger_rabbit",   # Dani Sanz
    "pmbH7SmdlBw": "hh_roger_rabbit",   # FUNKMODE — çoklu hareket dersi
    "rRlUNGymhmE": "hh_roger_rabbit",   # Marvelous Mosell
    "selXuuAWI64": "hh_roger_rabbit",   # Free Focus Dance
    "lYpRasK4c9k": "hh_running_man",    # Howcast
    "UO9Ehsdt2IE": "hh_running_man",    # JoeyTheJAM
    "k22Bm2pMyD4": "hh_running_man",    # Jayden Rodrigues — dikey, elendi
    "E6GfqbvDJfU": "hh_running_man",    # MihranTV
    "Wd29rBfAzkI": "hh_running_man",    # The Shed
    "KV-sxd_pQ9w": "hh_running_man",    # James Deane
}


def used_channels() -> dict[str, dict[str, dict]]:
    """Channels already harvested, grouped by step.

    A take counts toward the independence rule only if it actually produced
    landmarks: a downloaded-but-rejected video (wrong framing) leaves raw
    metadata behind but contributes no reference material, and treating it as
    a used channel would block a *usable* video from the same instructor.
    """
    # Videos are grouped UNDER a channel rather than keyed BY one. Keying by
    # channel_id silently dropped a second video from the same instructor —
    # The Shed teaches both steps, and one of its takes vanished from the
    # listing without a word. Counting distinct channels is still the rule;
    # losing a row while doing it is not.
    out: dict[str, dict[str, list[dict]]] = {}
    for info in sorted(RAW.glob("*.info.json")):
        vid = info.name[: -len(".info.json")]
        try:
            d = json.loads(info.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        step = STEP_OF.get(vid, "unknown")
        out.setdefault(step, {}).setdefault(
            d.get("channel_id") or vid, []).append({
                "videoId": vid,
                "channel": d.get("channel", ""),
                "extracted": (LANDMARKS / f"{vid}.full.json").exists(),
                "resolution": f"{d.get('width')}x{d.get('height')}",
            })
    return out


def probe(video_id: str) -> dict:
    try:
        r = subprocess.run(
            ["yt-dlp", "--dump-json", "--skip-download", "--no-warnings",
             "--no-playlist", YT + video_id],
            capture_output=True, text=True, timeout=90,
        )
    except (subprocess.TimeoutExpired, FileNotFoundError) as e:
        return {"videoId": video_id, "ok": False, "error": type(e).__name__}
    if r.returncode != 0:
        tail = (r.stderr or "").strip().splitlines()
        return {"videoId": video_id, "ok": False,
                "error": tail[-1][:120] if tail else "unavailable"}
    try:
        d = json.loads(r.stdout)
    except json.JSONDecodeError:
        return {"videoId": video_id, "ok": False, "error": "unparseable"}
    return {
        "videoId": video_id,
        "ok": True,
        "title": (d.get("title") or "")[:70],
        "channel": d.get("channel") or d.get("uploader") or "",
        "channelId": d.get("channel_id") or "",
        "width": d.get("width") or 0,
        "height": d.get("height") or 0,
        "durationSec": d.get("duration") or 0,
        "license": d.get("license") or "standard-youtube",
        "uploadDate": d.get("upload_date") or "",
        "url": YT + video_id,
    }


def verdict(p: dict, seen: set[str]) -> tuple[str, str]:
    """Returns (verdict, reason). `seen` is mutated as channels are claimed."""
    if not p.get("ok"):
        return "ERROR", p.get("error", "?")
    w, h = p["width"], p["height"]
    if w and h and w <= h:
        return "RED", f"dikey {w}x{h} — ayak işi kadrajdan düşer"
    if p["durationSec"] < MIN_SECONDS:
        return "RED", f"çok kısa ({p['durationSec']}s)"
    if p["durationSec"] > MAX_SECONDS:
        return "GOZDEN_GECIR", f"uzun ({p['durationSec']}s) — ders, segment seçimi ister"
    cid = p["channelId"]
    if cid and cid in seen:
        return "RED", f"kanal zaten sayıldı ({p['channel']})"
    if cid:
        seen.add(cid)
    return "ADAY", "yatay + adım uzunluğu + yeni kanal"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("ids", nargs="*")
    ap.add_argument("--step", help="hh_roger_rabbit | hh_running_man")
    ap.add_argument("--from-file", help="one video id per line, # comments ok")
    ap.add_argument("--used", action="store_true",
                    help="show already-harvested channels and exit")
    ap.add_argument("--queue", help="write accepted ids to this file")
    args = ap.parse_args()

    used = used_channels()
    if args.used or not (args.ids or args.from_file):
        print("HASAT EDİLMİŞ KANALLAR (adım bazlı)\n")
        for step in sorted(used):
            rows = used[step]
            vids = [v for vs in rows.values() for v in vs]
            live = {cid for cid, vs in rows.items()
                    if any(v["extracted"] for v in vs)}
            print(f"  {step}  —  {len(live)} kanal çıkarıldı / "
                  f"{len(vids)} video indirildi")
            for cid, vs in sorted(rows.items(), key=lambda kv: kv[1][0]["channel"]):
                for v in vs:
                    mark = "✓" if v["extracted"] else "✗"
                    print(f"    {mark} {v['channel'][:26]:<28}{v['videoId']}  "
                          f"{v['resolution']:>10}  {cid}")
            need = max(0, 3 - len(live))
            print(f"    → hasat tarafı: "
                  f"{'yeterli' if not need else f'{need} kanal daha gerekiyor'}\n")
        # Extraction is not usability. A take still has to survive movement
        # isolation, the folded-obliquity camera gate and mirror resolution
        # before it can back a reference — Roger Rabbit has four extractions
        # and two usable takes (C-066). The >=3 rule counts the survivors, so
        # this view is a floor on the work remaining, never a green light.
        print("NOT: yukarıdaki sayı ÇIKARIM sayısıdır, kullanılabilir take değil.\n"
              "     Take ayrıca hareket-izolasyonu + kamera kapısı + ayna\n"
              "     çözümünden geçmek zorunda; ≥3 kuralı hayatta kalanı sayar.")
        if args.used or not (args.ids or args.from_file):
            return 0

    ids = list(args.ids)
    if args.from_file:
        for line in Path(args.from_file).read_text(encoding="utf-8").splitlines():
            line = line.split("#")[0].strip()
            if line:
                ids.append(line)
    ids = list(dict.fromkeys(ids))  # order-preserving dedup

    step = args.step or "unknown"
    seen = {cid for cid, vs in used.get(step, {}).items()
            if any(v["extracted"] for v in vs)}
    print(f"adım: {step} — hâlihazırda {len(seen)} kullanılabilir kanal\n")
    print(f"{'video':<13}{'karar':<15}{'çözünürlük':>11}{'süre':>7}  "
          f"{'kanal':<24}neden")

    accepted: list[str] = []
    for vid in ids:
        p = probe(vid)
        v, why = verdict(p, seen)
        res = f"{p.get('width', 0)}x{p.get('height', 0)}" if p.get("ok") else "-"
        dur = f"{p.get('durationSec', 0)}s" if p.get("ok") else "-"
        print(f"{vid:<13}{v:<15}{res:>11}{dur:>7}  "
              f"{p.get('channel', '')[:22]:<24}{why}")
        if v == "ADAY":
            accepted.append(vid)

    print(f"\n{len(accepted)}/{len(ids)} aday geçti; "
          f"adım toplamı {len(seen)} kanal olur.")
    if len(seen) < 3:
        print(f"⚠ ≥3 kuralı hâlâ sağlanmıyor — {3 - len(seen)} kanal daha lazım. "
              "Referans ÜRETİLMEZ (M-C-04).")
    if args.queue and accepted:
        Path(args.queue).write_text("\n".join(accepted) + "\n", encoding="utf-8")
        print(f"kuyruk yazıldı: {args.queue}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
