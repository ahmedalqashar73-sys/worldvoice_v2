#!/usr/bin/env python3
"""Select 30 original long NASA podcasts per advanced WorldVoice level.

The original B1 VOA catalog and all A1/A2 content stay untouched.
Only the publisher's official NASA RSS is trusted for media URLs. A level
label is WorldVoice's provisional editorial choice, NOT NASA CEFR rating.
NASA transcripts on the original episode pages must exist. Do not invent
English text, Arabic captions, or timestamps.
"""
from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
import argparse
import json
import re
from pathlib import Path
from urllib.parse import urlparse
from xml.etree import ElementTree

import requests
from bs4 import BeautifulSoup

NASA_RSS = "https://www.nasa.gov/feeds/podcasts/houston-we-have-a-podcast"
NASA_ARCHIVE = "https://www.nasa.gov/podcasts/houston-we-have-a-podcast/"
MEGAPHONE_FEED = (
    "https://feeds.megaphone.fm/"
    "nationalaeronauticsandspaceadministration1776343825"
)
NAMESPACES = {
    "itunes": "http://www.itunes.com/dtds/podcast-1.0.dtd",
}
UA = {"User-Agent": "WorldVoiceAcademyEducationalPodcast/1.0"}
OUTPUT = Path("assets/podcasts/nasa_advanced_long_form.json")
LEVELS = ("B2", "C1", "C2")
MINIMUM_SECONDS = 10 * 60
RECENCY_CUTOFF = datetime(2024, 1, 1)

SIMPLE = ("life", "journey", "story", "questions", "astronaut",
          "crew", "team", "home", "training", "living", "career", "day",
          "experience", "work", "women", "communicating", "family")
TECHNICAL = ("engineering", "design", "systems", "architecture",
             "technology", "robotic", "science", "propulsion",
             "radiation", "nuclear", "mission control", "flight director",
             "navigation", "habitat", "research", "laboratory",
             "infrastructure", "avionics", "lander", "sample",
             "lunar", "moon base", "exploration")


def duration_seconds(value: str) -> int:
    raw = str(value or "").strip()
    if raw.isdecimal():
        return int(raw)
    parts = raw.split(":")
    if len(parts) not in (2, 3) or not all(x.isdecimal() for x in parts):
        return 0
    if len(parts) == 2:
        return int(parts[0]) * 60 + int(parts[1])
    return int(parts[0]) * 3600 + int(parts[1]) * 60 + int(parts[2])


def eligible_media_url(uri: str) -> bool:
    parsed = urlparse(uri)
    return (
        parsed.scheme == "https" and
        not parsed.username and not parsed.password and
        (
            parsed.hostname == "www.nasa.gov" or
            parsed.hostname == "nasa.gov" or
            parsed.hostname == "traffic.megaphone.fm" or
            parsed.hostname == "megaphone.fm" or
            parsed.hostname == "chtbl.com" or
            parsed.hostname == "www.podtrac.com" or
            parsed.hostname == "dcs.megaphone.fm"
        )
    )


def eligible_source_url(uri: str) -> bool:
    parsed = urlparse(uri)
    return (
        parsed.scheme == "https" and
        parsed.hostname in ("www.nasa.gov", "nasa.gov") and
        parsed.path.startswith("/podcasts/houston-we-have-a-podcast/") and
        parsed.path.rstrip("/") !=
        "/podcasts/houston-we-have-a-podcast"
    )


def fetch_feed() -> bytes:
    errors = []
    for url in (NASA_RSS, MEGAPHONE_FEED):
        try:
            response = requests.get(url, headers=UA, timeout=80)
            response.raise_for_status()
            if response.content.strip().startswith(b"<?xml") or (
                b"<rss" in response.content[:6000]
            ):
                return response.content
            errors.append(f"{url}: non-XML")
        except requests.RequestException as exc:
            errors.append(f"{url}: {exc}")
    raise RuntimeError("Official NASA podcast RSS failed: " + "; ".join(errors))


def parse_feed(xml_bytes: bytes) -> list[dict]:
    doc = ElementTree.fromstring(xml_bytes)
    items = []
    seen = set()
    for item in doc.findall(".//channel/item"):
        title = (item.findtext("title") or "").strip()
        page = (item.findtext("link") or "").strip()
        episode = (item.findtext("itunes:episode", namespaces=NAMESPACES)
                   or "").strip()
        duration = duration_seconds(item.findtext(
            "itunes:duration", default="", namespaces=NAMESPACES))
        enclosure = item.find("enclosure")
        audio = (enclosure.get("url") or "").strip() if enclosure is not None else ""
        pubdate = (item.findtext("pubDate") or "").strip()
        if (not title or duration < MINIMUM_SECONDS or
                duration > 120 * 60 or not eligible_media_url(audio) or
                not eligible_source_url(page) or page in seen):
            continue
        seen.add(page)
        items.append({
            "title": title,
            "source_url": page,
            "audio_url": audio,
            "duration_seconds": duration,
            "published": pubdate,
            "nasa_episode": episode,
        })
    return items


def technical_score(item: dict) -> int:
    text = item["title"].lower()
    return (sum(2 for word in TECHNICAL if word in text) -
            sum(1 for word in SIMPLE if word in text))


def verify_transcript_page(item: dict) -> dict | None:
    try:
        result = requests.get(item["source_url"], headers=UA, timeout=55)
        result.raise_for_status()
        if not eligible_source_url(result.url):
            return None
        soup = BeautifulSoup(result.text, "html.parser")
        text = soup.get_text(" ", strip=True)
        # Only full official articles with substantial transcript text
        # are candidates; machine-blank descriptions are not published.
        if ("Transcript" not in text or len(text) < 5000 or
                "Houston We Have a Podcast" not in text):
            return None
        return item
    except requests.RequestException:
        return None


def build_catalog(items: list[dict]) -> dict:
    if len(items) < 90:
        raise ValueError(f"Not enough authentic NASA RSS episodes: {len(items)}")
    # There are no official CEFR ratings. Rank by linguistic topic/jargon
    # only as a reversible WorldVoice editorial suggestion.
    ordered = sorted(items, key=lambda x: (
        technical_score(x), x["title"].casefold()))
    choices = {
        "B2": ordered[:30],
        "C1": ordered[len(ordered) // 2 - 15:len(ordered) // 2 + 15],
        "C2": ordered[-30:],
    }
    all_ids = set()
    results = []
    for level in LEVELS:
        subset = sorted(choices[level], key=lambda x: x["title"].lower())
        if len(subset) != 30:
            raise ValueError(f"Exactly 30 {level} recordings are required")
        for position, entry in enumerate(subset, start=1):
            uri = entry["source_url"]
            if uri in all_ids:
                raise ValueError(f"Episode reused across levels: {uri}")
            all_ids.add(uri)
            results.append({
                "id": f"en-{level.lower()}-nasa-{position:03d}",
                "language": "en",
                "level": level,
                "order": position,
                "title": entry["title"],
                "published": entry["published"],
                "audio_url": entry["audio_url"],
                "source_url": uri,
                "duration_seconds": entry["duration_seconds"],
                "duration_source": "NASA_official_RSS_itunes_duration",
                "source_credit": "NASA — Houston We Have a Podcast",
                "original_transcript_on_source_page": True,
                "transcript_status": "official_source_transcript_pending_import",
                "translation_status": "pending_official_transcript",
                "sync_status": "unverified",
                "cefr_status": "provisional_worldvoice_editorial_level",
                "third_party_content_review": "required_before_redistribution",
            })
    return {
        "schema": 1,
        "language": "en",
        "episode_count": 90,
        "episodes_per_level": 30,
        "levels": list(LEVELS),
        "source_url": NASA_ARCHIVE,
        "source_feed": NASA_RSS,
        "rights_notice": (
            "NASA media generally available for educational use with credit; "
            "check third-party music, identifiable voices and non-endorsement "
            "rules. Do not bundle or relicense unreviewed audio."
        ),
        "cefr_notice": (
            "NASA does not label episodes B2/C1/C2. WorldVoice's initial "
            "subject-based assignment requires CEFR pedagogical review."
        ),
        "transcript_notice": (
            "Official NASA pages have English transcripts, but app-imported "
            "matching subtitles, Arabic translation and timings remain pending."
        ),
        "episodes": results,
    }


def run(output: Path):
    candidates = parse_feed(fetch_feed())
    if len(candidates) < 90:
        raise ValueError(f"Official NASA RSS only had {len(candidates)} valid long episodes")
    # Don't trust episode descriptions as full official transcripts:
    # check that the linked NASA source contains long-form transcript text.
    with ThreadPoolExecutor(max_workers=12) as pool:
        verified = list(pool.map(verify_transcript_page, candidates[:190]))
    verified = [item for item in verified if item is not None]
    result = build_catalog(verified)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8")
    print(
        f"Verified {len(verified)} NASA episodes with original long audio "
        f"and English transcript pages; selected exactly 30 each for B2/C1/C2."
    )


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--output", type=Path, default=OUTPUT)
    args = p.parse_args()
    run(args.output)
