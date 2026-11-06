import importlib.util
import json
import tempfile
from pathlib import Path
import unittest

src = Path(__file__).resolve().parents[1] / "merge_nasa_advanced_transcripts.py"
spec = importlib.util.spec_from_file_location("nasa_merge", src)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
ROOT = Path(__file__).resolve().parents[2]
catalog = json.loads((ROOT / "assets/podcasts/nasa_advanced_long_form.json")
                     .read_text(encoding="utf-8"))


def example(original):
    return {
        "id": original["id"],
        "level": original["level"],
        "audio_url": original["audio_url"],
        "source_url": original["source_url"],
        "content_source": "NASA_official_podcast_transcript",
        "translation_status": "machine_draft_review_required",
        "sync_status": "unverified",
        "approved_for_publication": False,
        "dialogue": [
            {"text": "An original English transcript test fixture, not a real episode. " * 5,
             "translation_ar": "نص ترجمة تجريبي وليس حلقة حقيقية."}
            for _ in range(20)
        ],
    }


class MergeNasaOriginals(unittest.TestCase):
    def test_thirty_per_level_rejects_missing_and_false_approval(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            for level in ("B2", "C1", "C2"):
                originals = [e for e in catalog["episodes"]
                             if e["level"] == level]
                for i, original in enumerate(originals, 1):
                    (folder / f"nasa-{level.lower()}-{i:03d}.json").write_text(
                        json.dumps(example(original)), encoding="utf-8")
                data = m.merge_level(level, folder)
                self.assertEqual(len(data["episodes"]), 30)
                self.assertFalse(data["episodes"][0]["approved_for_publication"])
                one = folder / f"nasa-{level.lower()}-001.json"
                fake = example(originals[0])
                fake["approved_for_publication"] = True
                one.write_text(json.dumps(fake), encoding="utf-8")
                with self.assertRaises(ValueError):
                    m.merge_level(level, folder)
                one.write_text(json.dumps(example(originals[0])),
                               encoding="utf-8")


if __name__ == "__main__":
    unittest.main()
