#!/usr/bin/env python3
"""Merge only source-linked NASA B2/C1/C2 English and Arabic drafts."""
import argparse
import json
from pathlib import Path

LEVELS = ("B2", "C1", "C2")
CATALOG = Path("assets/podcasts/nasa_advanced_long_form.json")


def merge_level(level: str, folder: Path) -> dict:
    if level not in LEVELS:
        raise ValueError("Only B2 C1 C2")
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    originals = [e for e in catalog["episodes"] if e["level"] == level]
    if len(originals) != 30:
        raise ValueError("Missing source validated originals")
    result = []
    for i, original in enumerate(originals, 1):
        filename = folder / f"nasa-{level.lower()}-{i:03d}.json"
        if not filename.exists():
            raise ValueError(f"Missing official transcript draft {filename}")
        item = json.loads(filename.read_text(encoding="utf-8"))
        if (
            item.get("id") != original["id"] or
            item.get("level") != level or
            item.get("audio_url") != original["audio_url"] or
            item.get("source_url") != original["source_url"] or
            item.get("content_source") !=
                "NASA_official_podcast_transcript" or
            item.get("translation_status") !=
                "machine_draft_review_required" or
            item.get("sync_status") != "unverified" or
            item.get("approved_for_publication") is not False
        ):
            raise ValueError(f"NASA source/audio/transcript mismatch {level} {i}")
        dialogue = item.get("dialogue") or []
        if not isinstance(dialogue, list) or len(dialogue) < 12:
            raise ValueError(f"Source transcript too short {level} {i}")
        if sum(len(str(v.get("text", ""))) for v in dialogue) < 2500:
            raise ValueError(f"Insufficient source language text {level} {i}")
        for row in dialogue:
            if (not isinstance(row, dict) or
                    not str(row.get("text", "")).strip() or
                    not str(row.get("translation_ar", "")).strip() or
                    "start_ms" in row or "end_ms" in row):
                raise ValueError(f"Invalid Arabic draft or fabricated cue {level} {i}")
        result.append(item)
    return {
        "schema": 1,
        "language": "en",
        "level": level,
        "episode_count": 30,
        "status": "machine_draft_review_required",
        "source": "NASA — Houston We Have a Podcast",
        "notice_ar": (
            "النصوص الإنجليزية مأخوذة من صفحات NASA الأصلية والترجمة العربية "
            "مسودة آلية تحتاج مراجعة. لا توجد مزامنة زمنية معتمدة."
        ),
        "episodes": result,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--level", choices=LEVELS, required=True)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    data = merge_level(args.level, args.input)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(data, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    print(f"{args.level}: validated 30 source-linked complete NASA original "
          "English transcripts with Arabic machine-draft text")
