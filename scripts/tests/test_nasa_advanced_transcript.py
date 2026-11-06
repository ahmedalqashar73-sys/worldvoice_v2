"""NASA original-English transcript extraction guards, with synthetic HTML."""
from pathlib import Path
import importlib.util
import unittest

path = Path(__file__).resolve().parents[1] / "import_nasa_advanced_transcript.py"
spec = importlib.util.spec_from_file_location("nasa_transcript", path)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class TranscriptGuards(unittest.TestCase):
    def test_no_transcript_heading_is_rejected(self):
        with self.assertRaises(ValueError):
            m.extract_original_transcript(
                "<html><main><p>No source transcript here</p></main></html>")

    def test_source_validation_requires_official_catalog(self):
        for name in ("B2", "C1", "C2"):
            item = m.approved_record(name, 1)
            self.assertEqual(item["level"], name)
            self.assertTrue(item["audio_url"].startswith(
                "https://traffic.megaphone.fm/"))
            with self.assertRaises(ValueError):
                m.approved_record(name, 31)

    def test_source_transcript_preserves_paragraphs(self):
        long_text = "Learning English from NASA scientists is interesting. " * 8
        html = (
            "<html><main><h2>Transcript</h2>" +
            "".join(f"<p>{long_text}Original statement {i}.</p>"
                    for i in range(30)) +
            "</main></html>"
        )
        rows = m.extract_original_transcript(html)
        self.assertGreaterEqual(len(rows), 30)
        self.assertIn("Original statement 0.", rows[0])

    def test_long_genuine_source_paragraph_is_split_not_discarded(self):
        spoken = "An original extended interview with NASA scientists. " * 200
        markup = "<main><h2>Transcript</h2>" + (
            f"<p>{spoken}</p>" * 3) + "</main>"
        rows = m.extract_original_transcript(markup)
        self.assertGreater(len(rows), 15)
        self.assertTrue(all(len(x) <= 620 for x in rows))

    def test_draft_does_not_fabricate_cues(self):
        code = path.read_text(encoding="utf-8")
        self.assertIn('"sync_status": "unverified"', code)
        self.assertIn('"approved_for_publication": False', code)
        self.assertNotIn('"start_ms":', code)


if __name__ == "__main__":
    unittest.main()
