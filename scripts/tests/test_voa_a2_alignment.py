"""Offline A2 guard rails: do not use unrelated MP3s or synthetic recordings."""
import importlib.util
import unittest
from pathlib import Path

path = Path(__file__).resolve().parents[1] / "voa_a2_align_candidate.py"
spec = importlib.util.spec_from_file_location("voa_a2", path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

def record(n=1, url=None):
    return {
        "id": f"en-a2-voa-{n:03d}",
        "language": "en", "level": "A2",
        "recording_kind": "human",
        "voice_rights_verified": True,
        "status": "published_audio",
        "audio_url": url or "https://voa-audio.voanews.eu/vle/2017/10/17/original_hq.mp3?download=1",
    }

class A2AlignmentTests(unittest.TestCase):
    def test_all_30_original_a2_recordings_can_be_processed(self):
        self.assertEqual(len(module.APPROVED_EPISODES), 30)
        for n in range(1, 31):
            x = record(n)
            if n == 8:
                x["audio_url"] = (
                    "https://voa-video-ns.akamaized.net/pangeavideo/"
                    "2021/02/6/6a/6a264ff8-5d3a-4460-8d09-b56daf6ebe65_240p.mp4"
                )
            self.assertEqual(module.approved_source(x), x["audio_url"])
        for n in (0, 31, 99):
            with self.assertRaises(ValueError):
                module.approved_source(record(n))
        with self.assertRaises(ValueError):
            module.approved_source(record(8))
        with self.assertRaises(ValueError):
            module.approved_source(record(17,
                "https://voa-video-ns.akamaized.net/pangeavideo/2021/clip_240p.mp4"))

    def test_protect_against_wrong_source_or_level(self):
        for u in (
            "https://example.org/vle/audio.mp3",
            "http://voa-audio.voanews.eu/vle/2017/clip.mp3",
            "https://voa-audio.voanews.eu.evil.com/vle/clip.mp3",
            "https://voa-audio.voanews.eu/clip.mp3",
        ):
            with self.assertRaises(ValueError):
                module.approved_source(record(url=u))
        for field, value in (
            ("level", "A1"), ("language", "es"), ("recording_kind", "synthetic"),
            ("voice_rights_verified", False), ("status", "script_ready"),
        ):
            x = record()
            x[field] = value
            with self.assertRaises(ValueError):
                module.approved_source(x)

    def test_output_is_review_only_and_not_published(self):
        src = path.read_text(encoding="utf-8")
        self.assertIn('"approved_for_publication": False', src)
        self.assertEqual(module.tokens("Doesn't - I've!"),
                         ["doesn", "t", "i", "ve"])

if __name__ == "__main__":
    unittest.main()
