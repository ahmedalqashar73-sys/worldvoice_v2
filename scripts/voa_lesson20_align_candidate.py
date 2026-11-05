#!/usr/bin/env python3
"""Produce a *review-only* timing proposal from the REAL VOA Lesson 20 MP3.

This does not change any podcast episode metadata or falsely publish cues.
Requires: ffmpeg/ffprobe, whisper-timestamped, Internet access.
Run in the dedicated GitHub workflow on original main.

Line timing comes from audio ASR with word alignment (not a word-count
estimate), and must be checked against the original recording before publish.
"""
from __future__ import annotations

import argparse
import difflib
import hashlib
import json
from pathlib import Path
import re
import subprocess
import urllib.request

SOURCE = (
    "https://voa-audio.voanews.eu/vle/2016/06/29/"
    "8225db0f-179b-453f-92bb-50f548175c42_hq.mp3"
)


def tokens(text: str) -> list[str]:
    return re.findall(r"[a-z0-9]+", text.lower().replace("’", "'"))


def read_duration(audio: Path) -> int:
    proc = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", str(audio)],
        capture_output=True, text=True, check=True,
    )
    return round(float(proc.stdout.strip()) * 1000)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--episode", type=Path,
        default=Path("assets/podcasts/en/A1/en-a1-voa-020.json"),
    )
    parser.add_argument(
        "--output", type=Path,
        default=Path("/tmp/voa_lesson20_cues_proposed.json"),
    )
    parser.add_argument("--audio", type=Path,
                        default=Path("/tmp/voa_lesson20_original.mp3"))
    parser.add_argument("--model", default="base.en")
    args = parser.parse_args()

    record = json.loads(args.episode.read_text(encoding="utf-8"))
    if record.get("id") != "en-a1-voa-020" or len(record["dialogue"]) < 30:
        raise ValueError("Unexpected VOA episode; cannot align this source")
    if record.get("audio_url") != SOURCE:
        raise ValueError("Only the explicitly approved VOA audio may be used")

    if not args.audio.exists():
        request = urllib.request.Request(SOURCE, headers={
            "User-Agent": "Mozilla/5.0 WorldVoiceAcademy/1.0",
            "Referer": "https://learningenglish.voanews.com/",
        })
        with urllib.request.urlopen(request, timeout=80) as resp:
            if resp.status != 200:
                raise RuntimeError(f"VOA MP3 returned {resp.status}")
            args.audio.write_bytes(resp.read())
    if args.audio.stat().st_size < 800000:
        raise ValueError("Downloaded MP3 was suspiciously small")
    duration = read_duration(args.audio)
    if duration < 205000 or duration > 240000:
        raise ValueError(f"Unexpected VOA Lesson 20 duration: {duration}ms")

    import whisper_timestamped as whisper

    audio = whisper.load_audio(str(args.audio))
    model = whisper.load_model(args.model, device="cpu")
    output = whisper.transcribe(model, audio, language="en", vad=False)
    recognised = []
    for seg in output["segments"]:
        for word in seg.get("words", []):
            for part in tokens(word["text"]):
                recognised.append((
                    part,
                    round(float(word["start"]) * 1000),
                    round(float(word["end"]) * 1000),
                ))
    if len(recognised) < 250:
        raise ValueError("Insufficient word transcription for usable alignment")

    expected = []
    owners = []
    for row, line in enumerate(record["dialogue"]):
        for token in tokens(line["text"]):
            expected.append(token)
            owners.append(row)

    matched = [[] for _ in record["dialogue"]]
    alignment = difflib.SequenceMatcher(
        a=expected,
        b=[word[0] for word in recognised],
        autojunk=False,
    )
    matched_count = 0
    for block in alignment.get_matching_blocks():
        for offset in range(block.size):
            src = block.a + offset
            tgt = block.b + offset
            matched[owners[src]].append(recognised[tgt])
            matched_count += 1

    cues = []
    last_end = 0
    for i, line in enumerate(record["dialogue"]):
        aligned = matched[i]
        total = max(1, len(tokens(line["text"])))
        coverage = round(len(aligned) / total, 3)
        start = aligned[0][1] if aligned else None
        end = aligned[-1][2] if aligned else None
        monotonic = start is not None and last_end <= start < end <= duration
        cues.append({
            "line": i + 1,
            "speaker": line["speaker"],
            "source_text": line["text"],
            "start_ms": start,
            "end_ms": end,
            "word_coverage": coverage,
            "manual_review_required": coverage < 0.85 or not monotonic,
        })
        if monotonic:
            last_end = end

    summary = {
        "episode_id": record["id"],
        "audio_source": SOURCE,
        "sha256": hashlib.sha256(args.audio.read_bytes()).hexdigest(),
        "actual_duration_ms": duration,
        "expected_tokens": len(expected),
        "matched_tokens": matched_count,
        "token_match_ratio": round(matched_count / len(expected), 3),
        "needs_manual_review": sum(int(x["manual_review_required"]) for x in cues),
        "approved_for_publication": False,
        "cues": cues,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(summary, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print("VOA original MP3 actual duration:", duration, "ms")
    print("Aligned tokens:", matched_count, "of", len(expected))
    print("Cue rows requiring review:", summary["needs_manual_review"])
    print("Only a manual review may activate karaoke-style highlighting.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
