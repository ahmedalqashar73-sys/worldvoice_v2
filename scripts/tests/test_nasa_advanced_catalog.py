import importlib.util
import unittest
from pathlib import Path

src = Path(__file__).resolve().parents[1] / "import_nasa_advanced_catalog.py"
spec = importlib.util.spec_from_file_location("nasa_catalog", src)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class NASAAdvancedLongFormTests(unittest.TestCase):
    def test_duration_guard(self):
        self.assertEqual(m.duration_seconds("01:03:10"), 3790)
        self.assertEqual(m.duration_seconds("19:25"), 1165)
        self.assertEqual(m.duration_seconds("1900"), 1900)
        self.assertEqual(m.duration_seconds("invalid"), 0)

    def test_url_guards(self):
        self.assertTrue(m.eligible_source_url(
            "https://www.nasa.gov/podcasts/houston-we-have-a-podcast/start-here/"))
        self.assertFalse(m.eligible_source_url(
            "https://www.nasa.gov/podcasts/houston-we-have-a-podcast/"))
        self.assertFalse(m.eligible_source_url(
            "https://nasa.gov.evil.net/podcasts/houston-we-have-a-podcast/test/"))
        self.assertTrue(m.eligible_media_url("https://traffic.megaphone.fm/abc"))
        self.assertFalse(m.eligible_media_url("https://evil.example/audio.mp3"))

    def test_fail_closed_without_ninety_sources(self):
        with self.assertRaises(ValueError):
            m.build_catalog([])

    def test_ninety_audio_sources_without_duplicates(self):
        rows = [
            {
                "title": f"NASA Mission Story {n} technical flight mission systems",
                "source_url": (
                    "https://www.nasa.gov/podcasts/"
                    f"houston-we-have-a-podcast/topic-{n}/"),
                "audio_url": f"https://traffic.megaphone.fm/{n}",
                "duration_seconds": 2800,
                "published": "Wed, 06 Nov 2024 20:00:00 GMT",
                "nasa_episode": str(n),
            }
            for n in range(1, 121)
        ]
        result = m.build_catalog(rows)
        self.assertEqual(result["episode_count"], 90)
        self.assertEqual(len(result["episodes"]), 90)
        self.assertEqual(
            {x["level"] for x in result["episodes"]}, {"B2", "C1", "C2"})
        self.assertEqual(
            len({x["audio_url"] for x in result["episodes"]}), 90)


if __name__ == "__main__":
    unittest.main()
