#!/usr/bin/env python3
"""Attach an authorized, reviewed five-minute human podcast recording.

This program never estimates word timestamps. A manually reviewed or
forced-aligned cue sheet must match the true recording before publication.

Example:
  python3 scripts/attach_podcast_recording.py \
    --episode assets/podcasts/en/A1/en-a1-pod-001.json \
    --audio-file /path/to/authorized-original.mp3 \
    --audio-url https://your-approved-cdn.example/audio/en-a1-pod-001.mp3 \
    --cues /path/to/reviewed-line-cues.json \
    --voice-rights-confirmed --audio-qa-confirmed
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
from urllib.parse import urlparse


def duration_ms(audio_path: Path) -> int:
    if not audio_path.is_file():
        raise ValueError(f"Audio file does not exist: {audio_path}")
    if audio_path.suffix.lower() != ".mp3":
        raise ValueError("Provide a reviewed MP3 recording")
    proc = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", str(audio_path)],
        capture_output=True, text=True, check=True,
    )
    return round(float(proc.stdout.strip()) * 1000)


def checked_episode(episode: dict, cues: list, length: int, url: str) -> dict:
    address = urlparse(url)
    if address.scheme != "https" or not address.netloc:
        raise ValueError("Audio URL must use a genuine HTTPS host")
    if not 285000 <= length <= 315000:
        raise ValueError(f"Recording duration {length}ms is not 4:45–5:15")
    turns = episode["dialogue"]
    if not turns or len(turns) != len(cues):
        raise ValueError("Every transcript turn needs exactly one measured cue")
    if episode.get("hosts") != ["Anna", "Daniel"]:
        raise ValueError("The podcast must retain fixed hosts Anna and Daniel")
    previous_end = 0
    for i, (turn, cue) in enumerate(zip(turns, cues)):
        if turn.get("speaker") not in {"Anna", "Daniel"}:
            raise ValueError(f"Unexpected speaker at turn {i + 1}")
        start, end = cue.get("start_ms"), cue.get("end_ms")
        if not (type(start) is int and type(end) is int):
            raise ValueError(f"Missing numeric start/end for turn {i + 1}")
        if not (previous_end <= start < end <= length):
            raise ValueError(f"Invalid or overlapping cue at turn {i + 1}")
        previous_end = end
        turn["start_ms"], turn["end_ms"] = start, end
    if cues[0]["start_ms"] > 5000 or length - previous_end > 10000:
        raise ValueError("Cue sheet does not cover the recorded conversation")
    episode["status"] = "published"
    episode["recording_kind"] = "human"
    episode["voice_rights_verified"] = True
    episode["duration_ms"] = length
    episode["audio_url"] = url
    return episode


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--episode", type=Path, required=True)
    parser.add_argument("--audio-file", type=Path, required=True)
    parser.add_argument("--index", type=Path, default=Path("assets/podcasts/index.json"))
    parser.add_argument("--audio-url", required=True)
    parser.add_argument("--cues", type=Path, required=True)
    parser.add_argument("--voice-rights-confirmed", action="store_true")
    parser.add_argument("--audio-qa-confirmed", action="store_true",
                        help="Confirm the spoken text and speaker identities were reviewed")
    args = parser.parse_args()

    if not args.voice_rights_confirmed or not args.audio_qa_confirmed:
        parser.error(
            "Publication requires written voice rights and completed audio QA "
            "(--voice-rights-confirmed --audio-qa-confirmed).")
    episode = json.loads(args.episode.read_text(encoding="utf-8"))
    cues = json.loads(args.cues.read_text(encoding="utf-8"))
    if not isinstance(cues, list):
        parser.error("The cue sheet must be a JSON array")
    ms = duration_ms(args.audio_file)
    updated = checked_episode(episode, cues, ms, args.audio_url)
    index = json.loads(args.index.read_text(encoding="utf-8"))
    matches = [item for item in index["episodes"] if item["id"] == updated["id"]]
    if len(matches) != 1:
        raise ValueError("The podcast must have exactly one catalog entry")
    matches[0]["status"] = "published"
    args.episode.write_text(
        json.dumps(updated, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    args.index.write_text(
        json.dumps(index, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Published {updated['id']}: {len(cues)} aligned lines, {ms}ms")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as exc:
        print(f"Podcast recording rejected: {exc}", file=sys.stderr)
        sys.exit(1)
