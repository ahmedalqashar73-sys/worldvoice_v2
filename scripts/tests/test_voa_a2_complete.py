import importlib.util
import unittest
from pathlib import Path

script = Path(__file__).resolve().parents[1] / "build_voa_a2_complete.py"
spec = importlib.util.spec_from_file_location("voa_a2_complete", script)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class VoaA2CompleteSourceTests(unittest.TestCase):
    def test_official_spoken_only_and_paragraph_continuation(self):
        html = """<article><h2>Conversation</h2>
          <p>Anna: Hello, Pete.</p><p>(They wave.)</p>
          <p>Professor Bot: Please listen.</p><p>Here's what you should learn.</p>
          <p>Pete: Good morning!</p><h2>Listening Quiz</h2>
          <p>Anna: Should never be included.</p></article>"""
        spoken = module.extract_dialogue(html)
        self.assertEqual(len(spoken), 3)
        self.assertEqual([x["speaker"] for x in spoken],
                         ["Anna", "Professor Bot", "Pete"])
        self.assertEqual(spoken[1]["text"],
                         "Please listen. Here's what you should learn.")
    def test_30_without_conversation_heading_and_missing_colons(self):
        html = """<article><h2>Download Lesson 30</h2>
          <p>Lesson material, not spoken.</p>
          <p>Ashley: Where are you going?</p>
          <p>Nurse Well, life is short.</p>
          <p>Pete Oh. I have a dream!</p>
          <h2>Listening Quiz</h2><p>Anna: Exclude this.</p></article>"""
        lines = module.extract_dialogue(html)
        self.assertEqual([x["speaker"] for x in lines],
                         ["Ashley", "Nurse", "Pete"])
        self.assertEqual(lines[1]["text"], "Well, life is short.")
        self.assertEqual(lines[2]["text"], "Oh. I have a dream!")

    def test_numbered_speakers_are_not_folded_into_previous_turn(self):
        html = """<article><h2>Conversation</h2>
            <p>Anna: Which barbecue is best?</p>
            <p>Person 1: Texas, of course!</p>
            <p>Person 2: Carolina barbecue.</p>
            <p>Chef 1: No, I cannot tell you.</p>
            <p>Chef 2: (says nothing.)</p>
            <p>Anna: The sauce is a secret.</p>
            <h2>Listening Quiz</h2></article>"""
        lines = module.extract_dialogue(html)
        self.assertEqual([x["speaker"] for x in lines],
                         ["Anna", "Person 1", "Person 2", "Chef 1", "Anna"])
        self.assertEqual(lines[-1]["text"], "The sauce is a secret.")
        self.assertNotIn("Chef 2:", " ".join(x["text"] for x in lines))

    def test_parser_revision_targets_drafts_without_touching_authored(self):
        self.assertIn(8, module.RECHECK_MACHINE_DRAFT)
        self.assertIn(30, module.RECHECK_MACHINE_DRAFT)
        self.assertEqual(module.SOURCE_PARSER_REVISION, 2)

    def test_only_explicit_source_lessons(self):
        self.assertIn(8, module.ALLOWED)
        self.assertIn(30, module.ALLOWED)
        self.assertNotIn(16, module.ALLOWED)

if __name__ == "__main__":
    unittest.main()
