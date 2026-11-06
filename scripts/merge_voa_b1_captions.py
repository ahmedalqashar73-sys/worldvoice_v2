#!/usr/bin/env python3
"""Merge only 30 full-length original B1 VOA audio-derived bilingual drafts.

Never claims human review or exact sentence synchronization. Fails closed for
missing/short/untranslated episodes; neither audio nor A1/A2 is changed.
"""
import argparse
import json
import re
from pathlib import Path

SOURCE = Path("assets/podcasts/voa_english_b1_long_form.json")


def collect(directory: Path) -> dict:
    catalog = json.loads(SOURCE.read_text(encoding="utf-8"))
    original = catalog.get("episodes", [])
    if catalog.get("level") != "B1" or len(original) != 30:
        raise ValueError("Not the approved 30-episode B1 catalog")
    drafts = []
    for index, episode in enumerate(original, start=1):
        file = directory / f"b1-voa-{index:03d}.json"
        if not file.exists():
            raise ValueError(f"Missing original audio transcript draft: {file}")
        transcript = json.loads(file.read_text(encoding="utf-8"))
        if (transcript.get("id") != episode["id"] or
                transcript.get("level") != "B1" or
                transcript.get("audio_url") != episode["audio_url"] or
                transcript.get("source_url") != episode["source_url"] or
                transcript.get("transcript_status") !=
                "machine_draft_review_required" or
                transcript.get("translation_status") !=
                "machine_draft_review_required" or
                transcript.get("sync_status") != "unverified" or
                transcript.get("approved_for_publication") is not False or
                not re.fullmatch("[0-9a-f]{64}",
                                 str(transcript.get("audio_sha256", "")))):
            raise ValueError(f"Untrusted original B1 source or status: {index}")
        duration = transcript.get("measured_duration_ms", 0)
        if not isinstance(duration, int) or not 600000 <= duration <= 3600000:
            raise ValueError(f"Invalid original duration: {index}")
        rows = transcript.get("dialogue", [])
        if not isinstance(rows, list) or len(rows) < 80:
            raise ValueError(f"Too few spoken sentences: {index}")
        previous = -1
        for row in rows:
            start, end = row.get("start_ms"), row.get("end_ms")
            if (not isinstance(start, int) or not isinstance(end, int) or
                    start < previous or not 0 <= start < end <= duration + 3000 or
                    not str(row.get("text") or "").strip() or
                    not str(row.get("translation_ar") or "").strip()):
                raise ValueError(f"Broken English-Arabic recording cue: {index}")
            previous = start
        if rows[-1]["end_ms"] < .55 * duration:
            raise ValueError(f"Transcript does not cover the complete recording: {index}")
        drafts.append(transcript)
    return {
        "schema": 1,
        "language": "en",
        "level": "B1",
        "episode_count": 30,
        "status": "machine_draft_review_required",
        "source": "original VOA Learning English MP3",
        "disclaimer_ar": (
            "هذه نصوص وتراجم آلية مستخرجة من التسجيل الأصلي، وليست معتمدة. "
            "توقيت الجمل مبدئي وتحتاج جميع الحلقات إلى مراجعة تحريرية."
        ),
        "disclaimer_en": (
            "Automatic full-audio transcripts and translations, not "
            "editorially approved. Sentence cue times are approximate."
        ),
        "episodes": drafts,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    result = collect(args.input)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(result, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    print(f"Validated {len(result['episodes'])} original full-length VOA "
          "English+Arabic machine-draft transcripts; never marked final.")


if __name__ == "__main__":
    main()
