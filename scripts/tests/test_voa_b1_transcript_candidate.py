"""Offline source and editorial safety tests for B1 original audio."""
import importlib.util
import json
from pathlib import Path
import unittest

path = Path(__file__).resolve().parents[1] / "voa_b1_transcript_candidate.py"
spec = importlib.util.spec_from_file_location("b1", path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class OriginalB1Tests(unittest.TestCase):
    def setUp(self):
        catalog = Path(__file__).resolve().parents[2] / (
            "assets/podcasts/voa_english_b1_long_form.json")
        self.items = json.loads(catalog.read_text())["episodes"]

    def test_all_30_approved_sources(self):
        self.assertEqual(len(self.items), 30)
        for item in self.items:
            self.assertEqual(module.approved_source(item), item["audio_url"])

    def test_fake_audio_and_wrong_date_rejected(self):
        x = dict(self.items[0])
        for audio in (
            "https://example.org/20250302-003003-vle122-program.mp3",
            "http://voa-audio.voanews.eu/vle/2025/03/02/20250302-003003-vle122-program.mp3",
            "https://voa-audio.voanews.eu.evil.com/vle/2025/03/02/20250302-003003-vle122-program.mp3",
        ):
            with self.assertRaises(ValueError):
                module.approved_source({**x, "audio_url": audio})
        with self.assertRaises(ValueError):
            module.approved_source({**x, "published_date": "2025-03-03"})

    def test_machine_output_is_never_published(self):
        script = path.read_text()
        self.assertIn('"approved_for_publication": False', script)
        self.assertIn('"sync_status": "unverified"', script)
        self.assertNotIn("git push", script)


if __name__ == "__main__":
    unittest.main()
