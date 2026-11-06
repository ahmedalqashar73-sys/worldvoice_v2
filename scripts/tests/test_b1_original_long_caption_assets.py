"""Guard authentic, complete long-form VOA B1 bilingual draft assets.

These tests examine the actual original audio-derived text in the repository,
not a synthetic fixture. Machine drafts must remain labelled as unreviewed.
"""
import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
ORIGINALS = ROOT / "assets/podcasts/voa_english_b1_long_form.json"
TRANSCRIPTS = ROOT / "assets/podcasts/voa_english_b1_transcripts.json"


class B1LongAudioCaptionAssets(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.originals = json.loads(ORIGINALS.read_text(encoding="utf-8"))
        cls.doc = json.loads(TRANSCRIPTS.read_text(encoding="utf-8"))

    def test_thirty_unique_originals_and_complete_bilingual_drafts(self):
        self.assertEqual(self.doc["level"], "B1")
        self.assertEqual(self.doc["episode_count"], 30)
        self.assertEqual(len(self.doc["episodes"]), 30)
        self.assertEqual(
            self.doc["status"], "machine_draft_review_required")
        self.assertEqual(
            len(self.originals["episodes"]), 30)
        seen_urls = set()
        for num, (expected, actual) in enumerate(
            zip(self.originals["episodes"], self.doc["episodes"]), 1
        ):
            with self.subTest(number=num):
                self.assertEqual(actual["id"], expected["id"])
                self.assertEqual(actual["audio_url"], expected["audio_url"])
                self.assertEqual(actual["source_url"], expected["source_url"])
                self.assertTrue(actual["approved_for_publication"] is False)
                self.assertEqual(actual["sync_status"], "unverified")
                self.assertEqual(
                    actual["transcript_status"],
                    "machine_draft_review_required")
                self.assertEqual(
                    actual["translation_status"],
                    "machine_draft_review_required")
                self.assertTrue(600_000 <= actual["measured_duration_ms"]
                                <= 3_600_000)
                self.assertGreaterEqual(len(actual["dialogue"]), 80)
                self.assertNotIn(actual["audio_url"], seen_urls)
                seen_urls.add(actual["audio_url"])
                previous = -1
                for line in actual["dialogue"]:
                    start = line["start_ms"]
                    end = line["end_ms"]
                    self.assertIsInstance(start, int)
                    self.assertIsInstance(end, int)
                    self.assertGreaterEqual(start, previous)
                    self.assertGreater(end, start)
                    self.assertLessEqual(
                        end, actual["measured_duration_ms"] + 3_000)
                    self.assertTrue(str(line["text"]).strip())
                    self.assertTrue(str(line["translation_ar"]).strip())
                    previous = start
                self.assertGreaterEqual(
                    actual["dialogue"][-1]["end_ms"],
                    actual["measured_duration_ms"] * .55)

    def test_drafts_are_not_labeled_human_verified_or_exactly_synchronized(self):
        doc = self.doc
        self.assertIn("machine_draft_review_required", doc["status"])
        self.assertNotEqual(doc.get("approved_for_publication"), True)
        self.assertTrue(all(
            x["sync_status"] == "unverified" and
            x["approved_for_publication"] is False
            for x in doc["episodes"]
        ))


if __name__ == "__main__":
    unittest.main()
