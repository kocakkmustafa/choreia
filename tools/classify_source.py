#!/usr/bin/env python3
"""Is this footage a LESSON or a PERFORMANCE? Choreia's source-suitability gate.

The family's rig has a fail-closed suitability gate (M-F-43/45) and the idea is
right: material that cannot be shown to be instructional must not silently
become a reference. But its markers are Lissom's — ACTIVE and PASSIVE
range-of-motion vocabulary — and a dance tutorial never says "active range" or
"passive stretch". Run against Choreia's pool it returns `unknown` for
everything and, being fail-closed, rejects everything: including the takes that
already produced three usable references. Measured on a transcript that opens
"So today I'm gonna be teaching you guys basically the fundamentals..." — an
unmistakable lesson, classified unknown.

So the concept is adopted and the vocabulary is replaced. The question for
dance is not active-vs-passive but **lesson-demonstration vs performance**,
because a performance clip can repeat a phrase and pass every movement test
downstream while encoding styling rather than instruction.

Evidence is ranked, not pooled: the transcript is what the instructor actually
said and outranks a title anyone can write. A clip with no speech at all is the
strongest performance signal there is — nobody teaches silently.

  python3 tools/classify_source.py --all
  python3 tools/classify_source.py --video ZpTgAZBYNrU
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

HARVEST = Path(os.path.expanduser("~/motion-harvest/choreia"))
RAW = HARVEST / "raw"
TRANSCRIPTS = HARVEST / "transcripts"

# Second person plus an act of teaching. These are what an instructor says and
# a performer does not.
LESSON_MARKERS = (
    r"\bi'?m (?:gonna|going to) (?:teach|show)\b", r"\blet'?s break (?:it|this) down\b",
    r"\bstep by step\b", r"\bfollow (?:along|me)\b", r"\byou'?re gonna\b",
    r"\btry (?:it|this)\b", r"\bpractice\b", r"\brepeat\b", r"\bone more time\b",
    r"\bslow(?:ly| motion| it down)\b", r"\bthe first step\b", r"\btutorial\b",
    r"\bfundamental", r"\bbeginners?\b", r"\bmake sure (?:you|your)\b",
    r"\bwhat you want to do\b", r"\bcommon mistake\b",
    r"\b5,? ?6,? ?7,? ?8\b", r"\band one,? and two\b",
)

# Performance framing. Weaker individually — a lesson can mention choreography
# — so these only decide when no lesson marker fires.
PERFORMANCE_MARKERS = (
    r"\bchoreograph(?:y|ed) by\b", r"\bperformance\b", r"\bofficial (?:video|music)\b",
    r"\bfeaturing\b", r"\bdance cover\b", r"\bshowcase\b", r"\bcompetition\b",
)

# Below this many spoken words the clip is treated as having no instruction in
# it, whatever the title claims.
MIN_SPOKEN_WORDS = 40


def transcript_text(video_id: str) -> tuple[str, int]:
    for p in (TRANSCRIPTS / f"{video_id}.transcript.json",
              HARVEST / f"{video_id}.transcript.json"):
        if p.exists():
            d = json.loads(p.read_text(encoding="utf-8"))
            segs = d if isinstance(d, list) else d.get("segments", [])
            text = " ".join(s.get("text", "") for s in segs)
            return text, len(text.split())
    return "", -1          # -1 distinguishes "no transcript" from "silent clip"


def meta_text(video_id: str) -> str:
    p = RAW / f"{video_id}.info.json"
    if not p.exists():
        return ""
    d = json.loads(p.read_text(encoding="utf-8"))
    return f"{d.get('title', '')} {d.get('description', '')}"


def hits(text: str, patterns) -> list[str]:
    low = text.lower()
    return sorted({m.pattern for m in (re.compile(p) for p in patterns)
                   if m.search(low)})


def classify(video_id: str) -> dict:
    tr, words = transcript_text(video_id)
    meta = meta_text(video_id)

    out = {"videoId": video_id, "spokenWords": words}

    if words == -1:
        # No transcript is not evidence of anything; say so rather than guessing
        # from a title. Fail-closed, like the family gate.
        out.update(verdict="unknown", evidence="none",
                   why="transkript yok — başlıktan hüküm verilmez (fail-closed)")
        return out

    if words < MIN_SPOKEN_WORDS:
        out.update(verdict="performance", evidence="silence",
                   why=f"yalnız {words} sözcük konuşulmuş — kimse sessizce "
                       "öğretmez; en güçlü performans işareti")
        return out

    lesson = hits(tr, LESSON_MARKERS)
    perf = hits(tr, PERFORMANCE_MARKERS)
    out["lessonHits"] = lesson
    out["performanceHits"] = perf

    if lesson:
        out.update(verdict="lesson", evidence="transcript",
                   why=f"{len(lesson)} öğretim işareti (eğitmenin kendi sözleri)")
        return out
    if perf:
        out.update(verdict="performance", evidence="transcript",
                   why=f"öğretim işareti yok, {len(perf)} performans işareti var")
        return out

    # Speech but no teaching language: a vlog, a talk, a demo without cues.
    meta_lesson = hits(meta, LESSON_MARKERS)
    out.update(verdict="unknown", evidence="transcript",
               why="konuşma var ama öğretim dili yok"
                   + (f"; başlık/açıklamada {len(meta_lesson)} işaret — ZAYIF kanıt, "
                      "hüküm için yetmez" if meta_lesson else ""))
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--video")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--out")
    args = ap.parse_args()

    ids = ([args.video] if args.video else
           sorted(p.name[: -len(".info.json")] for p in RAW.glob("*.info.json"))
           if args.all else [])
    if not ids:
        ap.print_help()
        return 1

    rows = [classify(v) for v in ids]
    print(f"{'video':<13}{'karar':<13}{'kanıt':<12}{'sözcük':>7}  neden")
    for r in rows:
        print(f"{r['videoId']:<13}{r['verdict']:<13}{r['evidence']:<12}"
              f"{r['spokenWords']:>7}  {r['why'][:70]}")

    tally = {}
    for r in rows:
        tally[r["verdict"]] = tally.get(r["verdict"], 0) + 1
    print(f"\n{tally}")
    print("\nTranskripti olan klipler için hüküm eğitmenin KENDİ SÖZLERİNDEN\n"
          "gelir; başlık yalnız zayıf destek sayılır ve tek başına yeterli\n"
          "değildir. Transkript yoksa hüküm YOK (fail-closed).")
    if args.out:
        Path(args.out).write_text(json.dumps(rows, ensure_ascii=False, indent=1),
                                  encoding="utf-8")
        print(f"yazıldı: {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
