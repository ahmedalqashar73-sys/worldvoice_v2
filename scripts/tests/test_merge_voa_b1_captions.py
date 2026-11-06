"""Validate fail-closed B1 captions merging with synthetic test-only fixtures."""
import importlib.util
import json
import tempfile
from pathlib import Path
import unittest

SRC = Path(__file__).resolve().parents[1] / "merge_voa_b1_captions.py"
spec = importlib.util.spec_from_file_location("merge_b1_captions", SRC)
script = importlib.util.module_from_spec(spec)
spec.loader.exec_module(script)
CATALOG = json.loads((Path(__file__).resolve().parents[2] /
    "assets/podcasts/voa_english_b1_long_form.json").read_text())


def fixture(episode):
    return {
        "id": episode["id"], "level": "B1",
        "audio_url": episode["audio_url"],
        "source_url": episode["source_url"],
        "measured_duration_ms": 1800000,
        "audio_sha256": "1" * 64,
        "transcript_status": "machine_draft_review_required",
        "translation_status": "machine_draft_review_required",
        "sync_status": "unverified",
        "approved_for_publication": False,
        "dialogue": [
            {"start_ms": i * 10000, "end_ms": i * 10000 + 9500,
             "text": "Verified as a test fixture only.",
             "translation_ar": "جملة تجريبية فقط."}
            for i in range(180)
        ],
    }


class MergeB1Tests(unittest.TestCase):
    def test_full_thirty_file_validation(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for i, item in enumerate(CATALOG["episodes"], 1):
                (root / f"b1-voa-{i:03d}.json").write_text(
                    json.dumps(fixture(item)), encoding="utf-8")
            result = script.collect(root)
            self.assertEqual(len(result["episodes"]), 30)
            self.assertEqual(result["status"], "machine_draft_review_required")
            self.assertTrue(all(x["approved_for_publication"] is False
                                for x in result["episodes"]))
            broken = root / "b1-voa-030.json"
            broken.unlink()
            with self.assertRaises(ValueError):
                script.collect(root)

    def test_machine_transcripts_cannot_masquerade_as_approved(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for i, item in enumerate(CATALOG["episodes"], 1):
                record = fixture(item)
                if i == 2:
                    record["dialogue"][0]["translation_ar"] = ""
                (root / f"b1-voa-{i:03d}.json").write_text(
                    json.dumps(record), encoding="utf-8")
            with self.assertRaises(ValueError):
                script.collect(root)


if __name__ == "__main__":
    unittest.main()
