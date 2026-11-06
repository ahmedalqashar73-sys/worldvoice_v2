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
        "id": ident, "language": "en", "level": "A1",
        "recording_kind": "human", "voice_rights_verified": True,
        "status": "published_audio", "duration_ms": 300000,
        "recording_format": "original_full_lesson_video_mp4",
        "audio_url": url or (
            "https://voa-video-ns.akamaized.net/pangeavideo/"
            "2021/02/c/cc/cc4d97ac-b23a-4c71-a915-205f1bac86fc_240p.mp4"
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
            episode(url="https://example.com/pangeavideo/fake_mobile.mp4"),
            episode(url="https://voa-video-ns.akamaized.net.evil.com/pangeavideo/fake_mobile.mp4"),
            episode(url="http://voa-video-ns.akamaized.net/pangeavideo/fake_mobile.mp4"),
            episode(url="https://voa-video-ns.akamaized.net/fake_mobile.mp4"),
            episode(url="https://voa-audio.voanews.eu/vle/short.mp3"),
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
