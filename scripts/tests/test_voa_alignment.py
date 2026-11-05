"""Offline guards for VOA audio alignment. No third-party dependencies."""
import importlib.util
import unittest
from pathlib import Path

module_path = Path(__file__).resolve().parents[1] / "voa_lesson20_align_candidate.py"
spec = importlib.util.spec_from_file_location("voa_alignment", module_path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def episode(ident="en-a1-voa-030", url=None):
    return {
        "id": ident, "language": "en", "recording_kind": "human",
        "voice_rights_verified": True, "status": "published_audio",
        "audio_url": url or (
            "https://voa-audio.voanews.eu/vle/2016/09/27/recording_hq.mp3?download=1"
        ),
    }


class VoaApprovedSourceTests(unittest.TestCase):
    def test_approved_lessons(self):
        for number in [*(f"{i:03d}" for i in range(1, 13)), "020", "030", "047"]:
            with self.subTest(number=number):
                data = episode(f"en-a1-voa-{number}")
                self.assertEqual(module.approved_source(data), data["audio_url"])

    def test_external_host_or_episode_rejected(self):
        for data in (
            episode(ident="en-a1-voa-999"),
            episode(ident="en-a1-voa-013"),
            episode(url="https://example.com/vle/fake.mp3"),
            episode(url="https://voa-audio.voanews.eu.evil.com/vle/fake.mp3"),
            episode(url="http://voa-audio.voanews.eu/vle/fake.mp3"),
            episode(url="https://voa-audio.voanews.eu/fake.mp3"),
        ):
            with self.assertRaises(ValueError):
                module.approved_source(data)

    def test_rights_guard(self):
        data = episode()
        data["voice_rights_verified"] = False
        with self.assertRaises(ValueError):
            module.approved_source(data)

    def test_token_normalization(self):
        self.assertEqual(
            module.tokens("Don't. What’s this?"),
            ["don", "t", "what", "s", "this"],
        )


if __name__ == "__main__":
    unittest.main()
