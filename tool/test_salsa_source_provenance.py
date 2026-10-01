#!/usr/bin/env python3
"""Negative controls for the frozen Salsa source research lineage."""

import copy
import json
import unittest

from apply_salsa_source_attribution import CONTRACT, COURSE, render


class SalsaSourceProvenanceTest(unittest.TestCase):
    def setUp(self) -> None:
        self.contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
        self.course_bytes = COURSE.read_bytes()
        self.course = json.loads(self.course_bytes)

    def test_reviewed_lineage_renders_the_exact_live_course(self) -> None:
        self.assertEqual(render(self.course, self.contract), self.course_bytes)

    def test_missing_new_source_lineage_is_rejected(self) -> None:
        broken = copy.deepcopy(self.contract)
        del broken["sourceResearch"]["eld_jazz_box_b"]
        with self.assertRaisesRegex(ValueError, "research provenance drifted"):
            render(self.course, broken)

    def test_misassigned_new_source_lineage_is_rejected(self) -> None:
        broken = copy.deepcopy(self.contract)
        broken["sourceResearch"]["ellmann_pause_hold"] = ["v8"]
        with self.assertRaisesRegex(ValueError, "research provenance drifted"):
            render(self.course, broken)

    def test_missing_source_record_is_rejected(self) -> None:
        broken = copy.deepcopy(self.contract)
        broken["sources"].pop()
        with self.assertRaisesRegex(ValueError, "source roster"):
            render(self.course, broken)

    def test_new_source_binding_cannot_move_to_another_lesson(self) -> None:
        broken = copy.deepcopy(self.contract)
        broken["bindings"]["so_28"] = ["ellmann_pause_hold"]
        with self.assertRaisesRegex(ValueError, "contract or bindings"):
            render(self.course, broken)


if __name__ == "__main__":
    unittest.main()
