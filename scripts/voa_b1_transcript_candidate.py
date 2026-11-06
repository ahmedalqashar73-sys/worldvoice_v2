#!/usr/bin/env python3
"""Propose original VOA B1 English/Arabic captions for review, never auto-publish."""
import argparse
import hashlib
import json
import re
import subprocess
import tempfile
import urllib.request
from pathlib import Path
from urllib.parse import urlparse

CATALOG = Path("assets/podcasts/voa_english_b1_long_form.json")


def approved_source(item):
    number = item.get("order")
    if not isinstance(number, int) or not 1 <= number <= 30:
        raise ValueError("Unapproved episode")
    day = f"{number + 1:02d}"
    if (item.get("id") != f"en-b1-voa-{number:03d}" or
            item.get("level") != "B1" or item.get("language") != "en" or
            item.get("recording_kind") != "human" or
            item.get("published_date") != f"2025-03-{day}" or
            item.get("transcript_status") !=
            "pending_full_audio_transcription_review"):
        raise ValueError("Unapproved episode metadata")
    audio = urlparse(item.get("audio_url", ""))
    page = urlparse(item.get("source_url", ""))
    if (audio.scheme != "https" or
            audio.hostname != "voa-audio.voanews.eu" or
            audio.username or audio.password or
            audio.path != (f"/vle/2025/03/{day}/"
                           f"202503{day}-003003-vle122-program.mp3") or
            audio.query != "download=1" or
            page.scheme != "https" or
            page.hostname != "learningenglish.voanews.com" or
            not re.fullmatch(r"/a/\d+\.html", page.path)):
        raise ValueError("Unapproved VOA source URL")
    return item["audio_url"]


def process_episode(number, target, translate_arabic=False):
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    items = catalog["episodes"]
    if catalog.get("level") != "B1" or len(items) != 30 or not 1 <= number <= 30:
        raise ValueError("Invalid B1 lesson catalog")
    item = items[number - 1]
    url = approved_source(item)

    with tempfile.TemporaryDirectory(prefix="worldvoice_voa_b1_") as root:
        audio = Path(root) / "voa.mp3"
        request = urllib.request.Request(url, headers={
            "User-Agent": "WorldVoicePodcastEditorial/1.0",
            "Referer": "https://learningenglish.voanews.com/",
        })
        hash_value = hashlib.sha256()
        length = 0
        with urllib.request.urlopen(request, timeout=90) as response, audio.open("wb") as file:
            if response.status != 200:
                raise RuntimeError(f"VOA returned HTTP {response.status}")
            while True:
                chunk = response.read(65536)
                if not chunk:
                    break
                length += len(chunk)
                if length > 90 * 1024 * 1024:
                    raise ValueError("Recording too large")
                hash_value.update(chunk)
                file.write(chunk)
        if length < 1_000_000:
            raise ValueError("Too small for the full original recording")

        result = subprocess.run([
            "ffprobe", "-v", "error", "-show_entries", "format=duration",
            "-of", "default=noprint_wrappers=1:nokey=1", str(audio),
        ], check=True, capture_output=True, text=True)
        duration = round(float(result.stdout.strip()) * 1000)
        if not 600_000 <= duration <= 3_600_000:
            raise ValueError("Original recording is not 10+ minutes")

        import whisper_timestamped as whisper
        model = whisper.load_model("tiny.en", device="cpu")
        transcription = whisper.transcribe(
            model, whisper.load_audio(str(audio)), language="en", vad=False)
        rows = []
        for segment in transcription.get("segments", []):
            text = segment.get("text", "").strip()
            start = round(float(segment["start"]) * 1000)
            end = round(float(segment["end"]) * 1000)
            if text and 0 <= start < end <= duration + 3000:
                rows.append({
                    "text": text, "translation_ar": None,
                    "start_ms": start, "end_ms": end,
                })
        if len(rows) < 20:
            raise ValueError("Not enough original speech segments")

    # Translations are optional machine drafts, never approved captions.
    if translate_arabic:
        import argostranslate.package
        import argostranslate.translate
        argostranslate.package.update_package_index()
        packages = argostranslate.package.get_available_packages()
        model = next((m for m in packages
                      if m.from_code == "en" and m.to_code == "ar"), None)
        if model is None:
            raise RuntimeError("Offline English-Arabic model unavailable")
        argostranslate.package.install_from_path(model.download())
        for row in rows:
            text_ar = argostranslate.translate.translate(
                row["text"], "en", "ar"
            ).strip()
            row["translation_ar"] = text_ar or None

    proposal = {
        "id": item["id"], "level": "B1",
        "source_url": item["source_url"],
        "audio_url": url,
        "audio_sha256": hash_value.hexdigest(),
        "measured_duration_ms": duration,
        "transcript_status": "machine_draft_review_required",
        "translation_status": (
            "machine_draft_review_required" if translate_arabic
            else "pending_editorial_translation"
        ),
        "sync_status": "unverified",
        "approved_for_publication": False,
        "warning": "Review with original sound and check third-party media rights before publication.",
        "dialogue": rows,
    }
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(proposal, ensure_ascii=False, indent=2) + "\n",
                      encoding="utf-8")
    print(f"Review-only {item['id']}: {len(rows)} segments, {duration} ms")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--episode-number", type=int, default=1)
    parser.add_argument("--draft-arabic", action="store_true")
    parser.add_argument("--output", type=Path,
                        default=Path("/tmp/voa_b1_transcript_REVIEW_ONLY.json"))
    args = parser.parse_args()
    process_episode(args.episode_number, args.output,
                    translate_arabic=args.draft_arabic)
