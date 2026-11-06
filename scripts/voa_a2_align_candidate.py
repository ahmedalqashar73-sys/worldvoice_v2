#!/usr/bin/env python3
"""Produce *review-only* line timing proposals from original VOA recordings.

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

from urllib.parse import urlparse

# All thirty documented VOA Level 2 lessons. Short conversations use full VOA MP4 audio.
# Results are review candidates; source identity alone never approves timing.
APPROVED_EPISODES = frozenset(
    f"en-a2-voa-{number:03d}" for number in range(1, 31)
)


def approved_source(record: dict) -> str:
    """Restrict ASR to the thirty credited original VOA A2 recordings."""
    if (record.get("id") not in APPROVED_EPISODES or
            record.get("language") != "en" or
            record.get("level") != "A2" or
            record.get("recording_kind") != "human" or
            record.get("voice_rights_verified") is not True or
            record.get("status") != "published_audio"):
        raise ValueError("Unapproved VOA English A2 episode")
    source = record.get("audio_url")
    if not isinstance(source, str):
        raise ValueError("Missing VOA audio URL")
    url = urlparse(source)
    official_mp3 = (
        record["id"] not in {
            "en-a2-voa-007", "en-a2-voa-008", "en-a2-voa-010",
            "en-a2-voa-013", "en-a2-voa-017"} and
        url.hostname == "voa-audio.voanews.eu" and
        url.path.startswith("/vle/") and
        url.path.lower().endswith(".mp3")
    )
    official_full_video = (
        record["id"] in {
            "en-a2-voa-007", "en-a2-voa-008", "en-a2-voa-010",
            "en-a2-voa-013", "en-a2-voa-017"} and
        url.hostname == "voa-video-ns.akamaized.net" and
        url.path.startswith("/pangeavideo/") and
        url.path.lower().endswith("_240p.mp4")
    )
    if (url.scheme != "https" or
            url.username is not None or url.password is not None or
            not (official_mp3 or official_full_video)):
        raise ValueError("Unapproved VOA recording URL")
    return source


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
        default=Path("assets/podcasts/en/A2/en-a2-voa-001.json"),
    )
    parser.add_argument(
        "--output", type=Path,
        default=None,
    )
    parser.add_argument("--audio", type=Path, default=None)
    parser.add_argument("--model", default="base.en")
    args = parser.parse_args()

    record = json.loads(args.episode.read_text(encoding="utf-8"))
    source = approved_source(record)
    if len(record["dialogue"]) < 5:
        raise ValueError("Unexpectedly short VOA transcript")
    expected_duration = int(record["duration_ms"])
    extension = ".mp4" if source.split("?")[0].endswith(".mp4") else ".mp3"
    audio_file = args.audio or Path(f"/tmp/{record['id']}_original{extension}")
    output_file = args.output or Path(f"/tmp/{record['id']}_cues_proposed.json")

    if not audio_file.exists():
        request = urllib.request.Request(source, headers={
            "User-Agent": "Mozilla/5.0 WorldVoiceAcademy/1.0",
            "Referer": "https://learningenglish.voanews.com/",
        })
        with urllib.request.urlopen(request, timeout=80) as resp:
            if resp.status != 200:
                raise RuntimeError(f"VOA MP3 returned {resp.status}")
            audio_file.write_bytes(resp.read())
    # A 29-second 64-kbps original conversation can legitimately be
    # ~230 KB; a single 800 KB cutoff incorrectly rejects lesson 1.
    expected_min_bytes = max(30000, int(expected_duration / 1000 * 5500))
    if audio_file.stat().st_size < expected_min_bytes:
        raise ValueError("Downloaded VOA recording was suspiciously small")
    duration = read_duration(audio_file)
    if abs(duration - expected_duration) > 12000:
        raise ValueError(f"Unexpected VOA recording duration: {duration}ms")

    import whisper_timestamped as whisper

    audio = whisper.load_audio(str(audio_file))
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
    # Short A1 conversations contain fewer than 120 words. Reject an
    # empty/broken ASR transcription but keep review-only short candidates.
    script_token_count = sum(
        len(tokens(line["text"])) for line in record["dialogue"]
    )
    if len(recognised) < max(8, min(120, script_token_count // 3)):
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
        "audio_source": source,
        "sha256": hashlib.sha256(audio_file.read_bytes()).hexdigest(),
        "actual_duration_ms": duration,
        "expected_tokens": len(expected),
        "matched_tokens": matched_count,
        "token_match_ratio": round(matched_count / len(expected), 3),
        "needs_manual_review": sum(int(x["manual_review_required"]) for x in cues),
        "approved_for_publication": False,
        "cues": cues,
    }
    output_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.write_text(
        json.dumps(summary, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print("VOA original recording actual duration:", duration, "ms")
    print("Aligned tokens:", matched_count, "of", len(expected))
    print("Cue rows requiring review:", summary["needs_manual_review"])
    print("Only a manual review may activate karaoke-style highlighting.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
