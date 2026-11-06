#!/usr/bin/env python3
"""Import actual NASA source-page podcast transcripts, then draft Arabic.

Each original NASA page was validated against the official NASA RSS.
Do not fabricate English dialogue, timestamps or copyrighted third-party
material. Human editorial review is still required.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import time

import requests
from bs4 import BeautifulSoup

CATALOG = Path("assets/podcasts/nasa_advanced_long_form.json")
LEVELS = ("B2", "C1", "C2")
HEADERS = {
    "User-Agent": "WorldVoiceAcademyNASAOriginalPodcastEditorial/1.0",
}
TRAILERS = (
    "was created and is supervised",
    "for more podcasts visit",
    "download this episode",
    "was produced by",
    "this episode was recorded",
)
EXCLUDE = (
    "share this", "facebook", "pinterest", "twitter",
    "copy link", "listen to the podcast",
    "subscribe to", "spotify", "apple podcasts",
    "rss feed", "soundcloud", "related content",
    "embed this", "what is nasa",
)


def approved_record(level: str, index: int) -> dict:
    if level not in LEVELS or not 1 <= index <= 30:
        raise ValueError("Expected a B2/C1/C2 episode from 1 through 30")
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    if catalog.get("schema") != 1 or catalog.get("episode_count") != 90:
        raise ValueError("Original NASA catalog has not been validated")
    candidates = [e for e in catalog["episodes"]
                  if e.get("level") == level]
    if len(candidates) != 30:
        raise ValueError("Exactly thirty original recordings required")
    item = candidates[index - 1]
    if (item.get("id") != f"en-{level.lower()}-nasa-{index:03d}" or
            item.get("duration_seconds", 0) < 600 or
            not item.get("original_transcript_on_source_page") or
            not item.get("source_url", "").startswith(
                "https://www.nasa.gov/podcasts/houston-we-have-a-podcast/") or
            not item.get("audio_url", "").startswith(
                "https://traffic.megaphone.fm/") or
            item.get("transcript_status") !=
            "official_source_transcript_pending_import"):
        raise ValueError("Unapproved NASA original source or transcript")
    return item


def fetch_source(url: str) -> str:
    if not url.startswith(
        "https://www.nasa.gov/podcasts/houston-we-have-a-podcast/"
    ):
        raise ValueError("Only official NASA transcript pages allowed")
    # NASA may rate-limit simultaneous podcast transcript imports.
    # Retry only transient network/server failures without swapping sources.
    last_error = None
    for attempt in range(6):
        try:
            response = requests.get(url, headers=HEADERS, timeout=75)
            if response.status_code in (429, 500, 502, 503, 504):
                last_error = RuntimeError(
                    f"NASA temporarily returned HTTP {response.status_code}"
                )
            else:
                response.raise_for_status()
                if not response.url.startswith(
                    "https://www.nasa.gov/podcasts/houston-we-have-a-podcast/"
                ) or len(response.content) < 15000:
                    raise ValueError("Unexpected source page or redirect")
                return response.text
        except requests.RequestException as exc:
            last_error = exc
        if attempt < 5:
            time.sleep(min(9 * (2 ** attempt), 65))
    raise RuntimeError(
        f"Original NASA transcript unavailable after retry: {last_error}"
    )


def clean_row(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


def split_long_paragraph(value: str, maximum: int = 620) -> list[str]:
    sentences = re.split(r"(?<=[.!?])\s+(?=[A-Z0-9])", value)
    results = []
    chunk = ""
    for sentence in sentences:
        if len(sentence) > maximum:
            if chunk:
                results.append(chunk)
                chunk = ""
            for offset in range(0, len(sentence), maximum):
                results.append(sentence[offset:offset + maximum])
        elif len(chunk) + len(sentence) + 1 <= maximum:
            chunk = (chunk + " " + sentence).strip()
        else:
            if chunk:
                results.append(chunk)
            chunk = sentence
    if chunk:
        results.append(chunk)
    return results


def extract_original_transcript(html: str) -> list[str]:
    soup = BeautifulSoup(html, "html.parser")
    main = soup.find("main") or soup.find("article") or soup
    marker = None
    for child in main.find_all(["h1", "h2", "h3", "h4", "p", "strong", "b", "div"]):
        if child.get_text(" ", strip=True).strip().lower() == "transcript":
            marker = child
            break
    if marker is None:
        raise ValueError("Official NASA page did not contain a transcript heading")

    rows = []
    consumed = 0
    for paragraph in marker.find_all_next("p"):
        if main is not soup and main not in paragraph.parents:
            break
        value = clean_row(paragraph.get_text(" ", strip=True))
        if not value:
            continue
        consumed += 1
        lower = value.casefold()
        if consumed > 600:
            break
        if any(x in lower for x in EXCLUDE) and len(value) < 125:
            continue
        if (len(rows) > 15 and
                ("this is an official nasa podcast" in lower or
                 "was created and is supervised" in lower)):
            # Retain the paragraph if it is still original spoken transcript.
            rows.extend(split_long_paragraph(value))
            break
        if lower.startswith(("end transcript", "reader comments",
                             "related articles", "more on this topic",
                             "was this page helpful")):
            break
        # Some official NASA episodes place several minutes of genuine
        # speech inside a single <p> element. Split the source paragraph
        # into readable passages; never confuse length with invalid text.
        if len(value) > 150000:
            raise ValueError("Implausibly large NASA transcript container")
        rows.extend(split_long_paragraph(value))

    if len(rows) < 12 or sum(len(x) for x in rows) < 2500:
        raise ValueError("NASA original transcript appears incomplete")
    return rows


def translate_english(english: list[str]) -> list[dict]:
    import argostranslate.package
    import argostranslate.translate

    argostranslate.package.update_package_index()
    models = argostranslate.package.get_available_packages()
    selected = next((m for m in models
                     if m.from_code == "en" and m.to_code == "ar"), None)
    if selected is None:
        raise RuntimeError("No offline English-Arabic translation model")
    argostranslate.package.install_from_path(selected.download())

    result = []
    for index, line in enumerate(english):
        arabic = argostranslate.translate.translate(line, "en", "ar").strip()
        if not arabic:
            raise ValueError(f"Empty Arabic machine draft at segment {index}")
        result.append({"text": line, "translation_ar": arabic})
    return result


def import_one(level: str, index: int, output: Path) -> None:
    item = approved_record(level, index)
    original = extract_original_transcript(
        fetch_source(item["source_url"]))
    translations = translate_english(original)
    record = {
        "id": item["id"],
        "level": level,
        "audio_url": item["audio_url"],
        "source_url": item["source_url"],
        "source_credit": "NASA — Houston We Have a Podcast",
        "content_source": "NASA_official_podcast_transcript",
        "translation_status": "machine_draft_review_required",
        "sync_status": "unverified",
        "approved_for_publication": False,
        "rights_review": "NASA_original_media_third_party_review_pending",
        "warning": (
            "English from original NASA transcript; Arabic is offline "
            "machine-draft translation. Sentence-level audio timing is "
            "not available and no NASA endorsement is implied."
        ),
        "dialogue": translations,
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(record, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    print(f"{item['id']}: {len(original)} official English passages "
          "with Arabic draft translations; no invented timestamps")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--level", choices=LEVELS, required=True)
    parser.add_argument("--episode", type=int, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    import_one(args.level, args.episode, args.output)
