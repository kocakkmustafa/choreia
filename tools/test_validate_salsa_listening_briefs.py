"""Regression tests for the three planned, silent salsa listening storyboards.

Run: python3 -B tools/test_validate_salsa_listening_briefs.py
"""

from __future__ import annotations

import copy
import json
import unittest

from validate_salsa_listening_briefs import APP, validate


class SilentListeningStoryboardTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.course = json.loads((APP / "content/salsa_on1_course.json").read_text())
        cls.schema = json.loads(
            (APP / "docs/schema/salsa-on1-course.schema.json").read_text()
        )

    def setUp(self) -> None:
        self.course_copy = copy.deepcopy(self.course)

    def scenes(self, lesson_id: str, language: str) -> list[str]:
        lesson = next(x for x in self.course_copy["lessons"] if x["id"] == lesson_id)
        return lesson["mediaBrief"]["productionStoryboard"]["scenes"][language]

    def assert_needs_review(self) -> None:
        errors = validate(self.course_copy, self.schema)
        self.assertTrue(errors, "A modified storyboard must not pass silently")
        self.assertTrue(
            any("semantic review" in error for error in errors),
            f"Expected a semantic review gate, got {errors!r}",
        )

    def test_current_live_source_is_accepted(self) -> None:
        self.assertEqual(validate(self.course_copy, self.schema), [])

    def test_automatic_external_track_sync_claim_is_rejected(self) -> None:
        self.scenes("so_36", "en")[1] += (
            " In fact, the screen counter automatically synchronises to the "
            "external track and verifies the correct beat."
        )
        self.assert_needs_review()

    def test_finger_tap_instrument_recognition_claim_is_rejected(self) -> None:
        self.scenes("so_38", "en")[2] += (
            " Finger taps definitively prove correct instrument recognition "
            "in the recording."
        )
        self.assert_needs_review()

    def test_other_scene_edit_also_requires_review(self) -> None:
        self.scenes("so_37", "tr")[0] += " "
        self.assert_needs_review()

    def test_malformed_scene_returns_error(self) -> None:
        self.scenes("so_37", "en")[0] = None
        errors = validate(self.course_copy, self.schema)
        self.assertTrue(errors)
        self.assertTrue(any("scenes" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
