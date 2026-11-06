"""Validate actual long-form NASA advanced English-Arabic transcript assets.

Unlike synthetic unit-test fixtures, this checks the committed translated
assets against the 90 official audio URLs and NASA episode source pages.
Do not consider partial uploads or third-party content final.
"""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
SOURCES = ROOT / "assets/podcasts/nasa_advanced_long_form.json"
TRANSLATION_DIR = ROOT / "assets/podcasts"


class NasaAdvancedActualTranslationAssets(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = json.loads(SOURCES.read_text(encoding="utf-8"))
        assert cls.catalog["episode_count"] == 90
        assert cls.catalog["episodes_per_level"] == 30

    def test_source_catalog_has_disjoint_long_recordings(self):
        entries = self.catalog["episodes"]
        self.assertEqual(len(entries), 90)
        self.assertEqual(len({x["source_url"] for x in entries}), 90)
        self.assertEqual(len({x["audio_url"] for x in entries}), 90)
        for level in ("B2", "C1", "C2"):
            selections = [x for x in entries if x["level"] == level]
            self.assertEqual(len(selections), 30)
            for index, item in enumerate(selections, 1):
                with self.subTest(level=level, number=index):
                    self.assertEqual(item["order"], index)
                    self.assertEqual(item["id"], f"en-{level.lower()}-nasa-{index:03d}")
                    self.assertGreaterEqual(item["duration_seconds"], 600)
                    self.assertTrue(item["original_transcript_on_source_page"])

    def test_committed_bilingual_assets_match_every_original(self):
        for level in ("B2", "C1", "C2"):
            originals = [x for x in self.catalog["episodes"]
                         if x["level"] == level]
            path = TRANSLATION_DIR / (
                f"nasa_{level.lower()}_translations.json")
            self.assertTrue(
                path.exists(), f"Missing full 30-episode bilingual {level} asset"
            )
            with self.subTest(level=level):
                document = json.loads(path.read_text(encoding="utf-8"))
                self.assertEqual(document["language"], "en")
                self.assertEqual(document["level"], level)
                self.assertEqual(document["episode_count"], 30)
                self.assertEqual(document["status"],
                                 "machine_draft_review_required")
                episodes = document["episodes"]
                self.assertEqual(len(episodes), 30)
                for expected, record in zip(originals, episodes):
                    with self.subTest(id=expected["id"]):
                        self.assertEqual(record["id"], expected["id"])
                        self.assertEqual(record["audio_url"],
                                         expected["audio_url"])
                        self.assertEqual(record["source_url"],
                                         expected["source_url"])
                        self.assertEqual(record["content_source"],
                                         "NASA_official_podcast_transcript")
                        self.assertEqual(
                            record["translation_status"],
                            "machine_draft_review_required")
                        self.assertEqual(record["sync_status"], "unverified")
                        self.assertFalse(record["approved_for_publication"])
                        self.assertGreaterEqual(len(record["dialogue"]), 12)
                        english_length = 0
                        for phrase in record["dialogue"]:
                            self.assertTrue(
                                isinstance(phrase["text"], str) and
                                phrase["text"].strip())
                            self.assertTrue(
                                isinstance(phrase["translation_ar"], str) and
                                phrase["translation_ar"].strip())
                            self.assertNotIn("start_ms", phrase)
                            self.assertNotIn("end_ms", phrase)
                            english_length += len(phrase["text"])
                        self.assertGreaterEqual(english_length, 2500)


if __name__ == "__main__":
    unittest.main()
