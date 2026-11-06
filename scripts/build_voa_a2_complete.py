#!/usr/bin/env python3
"""Import all spoken English turns from the exact credited VOA Level 2 pages.

Preserves manually authored Arabic for unchanged lines; translates any new
lines with a locally downloaded Argos en->ar model. Machine Arabic remains
labelled as a DRAFT, never as a human-reviewed final translation.
Only lessons 8 and 17-30 marked transcript_scope=excerpt are upgraded.
No other curriculum, voice rooms, gifts or branches are touched.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import re
import sys
import unicodedata

from bs4 import BeautifulSoup
import requests

BASE = Path("assets/podcasts")
CATALOG = BASE / "voa_english_a2_originals.json"
ALLOWED = {8, *range(17, 31)}
HEADERS = {"User-Agent": "Mozilla/5.0 (compatible; WorldVoiceVOATranscript/1.0; +https://learningenglish.voanews.com/)"}
SPEAKER = re.compile(r"^([A-Za-z][A-Za-z.'’\-\s]{0,42}):\s*(.*)$")
DIRECTIONS = re.compile(r"\([^()]*\)")
STOP_HEADINGS = ("listening quiz", "free materials", "for teachers", "comments", "related")
ALIASES = {
    "prof bot": "Professor Bot", "prof. bot": "Professor Bot",
    "prof. bot vo": "Professor Bot", "prof bot vo": "Professor Bot",
    "professor bot": "Professor Bot", "peter": "Pete",
    "ms weaver": "Ms. Weaver", "ms. weaver": "Ms. Weaver",
    "announcer": "Announcer", "lightning bolt lady": "Lightning Bolt Lady",
}

def norm(s: str) -> str:
    return re.sub(r"\s+", " ", unicodedata.normalize("NFKC", s).strip()).casefold()

def speaker_name(raw: str) -> str:
    cleaned = re.sub(r"\s+", " ", raw.strip()).strip(".")
    return ALIASES.get(norm(cleaned), cleaned.title() if cleaned.isupper() else cleaned)

def without_stage(s: str) -> str:
    return re.sub(r"\s+", " ", DIRECTIONS.sub(" ", s)).strip()

def extract_dialogue(html: str) -> list[dict[str, str]]:
    """Extract the complete *spoken* Conversation section, not the lesson UI.

    VOA uses normal paragraphs below its Conversation heading. Ignore
    unspoken stage directions, retain spoken Professor Bot instruction,
    and append unlabelled continuation paragraphs to the current voice.
    """
    soup = BeautifulSoup(html, "html.parser")
    start = False
    rows: list[dict[str, str]] = []
    pending = ""
    for tag in soup.find_all(["h2", "h3", "h4", "p", "li"]):
        heading = tag.name in ("h2", "h3", "h4")
        value = tag.get_text(" ", strip=True)
        if heading:
            if norm(value) == "conversation":
                start = True
                continue
            if start and any(norm(value).startswith(h) for h in STOP_HEADINGS):
                break
            continue
        if not start or not value:
            continue
        # Text nodes can contain inline formatting and speaker-labelled <br>s.
        # Keep line separators to avoid joining two people into one turn.
        segments = [x.strip() for x in tag.get_text("\n", strip=True).split("\n") if x.strip()]
        for piece in segments:
            if piece.startswith("(") and piece.endswith(")"):
                continue
            if pending:
                piece = pending + " " + piece
                pending = ""
            matched = SPEAKER.match(piece)
            if matched:
                who, spoken = matched.groups()
                if not spoken:
                    pending = who + ":"
                    continue
                words = without_stage(spoken)
                if words:
                    rows.append({"speaker": speaker_name(who), "text": words})
            elif rows and not piece.startswith("("):
                # Narration or an explanatory sentence may follow its labelled
                # speaker in a distinct paragraph. Never insert a new speaker.
                continuation = without_stage(piece)
                if continuation and not continuation.startswith(("Image:", "Watch ", "Download ")):
                    rows[-1]["text"] += " " + continuation
    # A malformed page may include an embed without a transcript. Fail closed.
    return rows

def install_translator():
    import argostranslate.package
    import argostranslate.translate
    argostranslate.package.update_package_index()
    packages = argostranslate.package.get_available_packages()
    matches = [p for p in packages if p.from_code == "en" and p.to_code == "ar"]
    if not matches:
        raise RuntimeError("No English-to-Arabic Argos translation model available")
    argostranslate.package.install_from_path(matches[0].download())
    return argostranslate.translate

def read_html(url: str) -> str:
    parsed = requests.utils.urlparse(url)
    if parsed.scheme != "https" or parsed.hostname != "learningenglish.voanews.com":
        raise ValueError("Only published official VOA transcript pages are allowed")
    result = requests.get(url, headers=HEADERS, timeout=70)
    result.raise_for_status()
    if len(result.content) < 20000:
        raise ValueError("Unexpectedly small VOA transcript page")
    return result.text

def update_one(item: dict, translator, dry_run: bool) -> dict:
    number = int(item["voa_lesson_number"])
    if number not in ALLOWED or item.get("transcript_scope") == "full":
        return {"lesson": number, "skipped": True}
    path = BASE / "en" / "A2" / item["id"]
    file_path = path.with_suffix(".json")
    episode = json.loads(file_path.read_text(encoding="utf-8"))
    if episode.get("transcript_scope") != "excerpt":
        raise ValueError(f"Unexpected transcript scope: {number}")
    if episode["source_url"] != item["source_url"] or episode["audio_url"] != item["audio_url"]:
        raise ValueError(f"Source and recording mismatch: {number}")
    spoken = extract_dialogue(read_html(item["source_url"]))
    total_words = sum(len(line["text"].split()) for line in spoken)
    if len(spoken) < 15 or total_words < 240 or total_words > 4500:
        raise ValueError(f"Unreliable complete transcript for {number}: {len(spoken)} turns, {total_words} words")
    known_ar = {norm(line["text"]): line["translation_ar"] for line in episode["dialogue"]}
    known_lines = sum(int(norm(line["text"]) in {norm(l["text"]) for l in spoken}) for line in episode["dialogue"])
    if known_lines < 2:
        raise ValueError(f"Transcript appears unrelated to the stored VOA dialogue: {number}")
    new_dialogue = []
    reused = 0
    for line in spoken:
        text = line["text"]
        ar = known_ar.get(norm(text))
        if ar:
            reused += 1
        else:
            ar = translator.translate(text, "en", "ar")
        if not isinstance(ar, str) or not ar.strip() or norm(ar) == norm(text):
            raise ValueError(f"Arabic translation missing for {number}: {text[:60]}")
        new_dialogue.append({
            "speaker": line["speaker"], "text": text,
            "translation_ar": ar.strip(), "start_ms": None, "end_ms": None,
        })
    voices = list(dict.fromkeys(line["speaker"] for line in new_dialogue))
    episode["dialogue"] = new_dialogue
    episode["hosts"] = voices[:2]
    episode["other_speakers"] = voices[2:]
    episode["transcript_scope"] = "full"
    episode["translation_status"] = "machine_draft"
    episode["translation_engine"] = "argos-en-ar"
    episode["source_credit"] = (
        f"VOA Learning English — Let's Learn English Level 2 Lesson {number}. "
        "Complete original VOA spoken English transcript with Arabic translation "
        "drafted by Argos Translate and pending editorial review. "
        "Human original audio; sentence timings still unverified. "
        "WorldVoice is not affiliated with VOA."
    )
    if not dry_run:
        file_path.write_text(json.dumps(episode, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        item["transcript_scope"] = "full"
        item["translation_status"] = "machine_draft"
    return {"lesson": number, "turns": len(new_dialogue), "words": total_words,
            "reused_human_arabic": reused, "machine_arabic": len(new_dialogue)-reused}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    targets = [x for x in catalog["lessons"]
               if x["voa_lesson_number"] in ALLOWED
               and x.get("transcript_scope") == "excerpt"]
    if not targets:
        print("All eligible VOA Level 2 transcripts are already full.")
        return 0
    translator = install_translator()
    results = []
    failures = []
    for item in targets:
        try:
            results.append(update_one(item, translator, args.dry_run))
        except Exception as e:
            failures.append({"lesson": item["voa_lesson_number"], "error": str(e)})
        print(json.dumps(results[-1] if len(results) > 0 and results[-1].get("lesson") == item["voa_lesson_number"]
                         else failures[-1], ensure_ascii=False), flush=True)
    if not args.dry_run:
        catalog["notes"] = (
            "VOA Level 2 has 30 recordings, with English conversations from the official "
            "VOA lesson pages and Arabic translations. New translations marked "
            "machine_draft require editorial review; no unverified line timings are enabled. "
            "Lesson 8 uses the official video audio because standalone MP3 is unavailable. "
            "VOA Level 2 is intermediate, not formally equivalent to CEFR A2."
        )
        CATALOG.write_text(json.dumps(catalog, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    Path("/tmp/voa_a2_full_import_report.json").write_text(
        json.dumps({"results":results,"failures":failures},ensure_ascii=False,indent=2)+"\n",
        encoding="utf-8")
    if failures:
        print(f"{len(failures)} lessons still need editorial/source fixes", file=sys.stderr)
        if results:
            # Publish verified matches incrementally while retaining excerpt
            # labels for anything that failed extraction or translation.
            return 0
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())
