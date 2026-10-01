#!/usr/bin/env python3
"""Negative controls for the app-owned, source-only v2l projection gate."""

from __future__ import annotations

import copy
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import check_v2l_source_projection as gate


class ChoreiaSourceProjectionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.slice_raw = gate.SLICE.read_bytes()
        cls.projection_raw = gate.PROJECTION.read_bytes()
        cls.course_raw = gate.COURSE.read_bytes()
        cls.source = json.loads(cls.slice_raw)
        cls.course = json.loads(cls.course_raw)

    def test_live_app_assets_rebuild_exact_sorted_projection(self) -> None:
        gate.check_local_assets()
        projection = json.loads(gate.build_projection(self.source, self.course))
        self.assertEqual(len(projection["rows"]), 872)
        self.assertEqual([row[0] for row in projection["rows"]],
                         sorted(row[0] for row in projection["rows"]))
        self.assertEqual({row[10] for row in projection["rows"]}, {False})

    def test_scene_order_change_breaks_projection_even_with_unchanged_pins(self) -> None:
        source = copy.deepcopy(self.source)
        scenes = source["lessons"][0]["scenes"]
        scenes[0], scenes[1] = scenes[1], scenes[0]
        with self.assertRaisesRegex(gate.SourceProjectionError, "PROJECTION_REBUILD_DRIFT"):
            gate.verify_semantics(source, self.course, self.projection_raw)

    def test_projection_row_change_fails_immutable_pin(self) -> None:
        projection = json.loads(self.projection_raw)
        projection["rows"][0][4] += 1
        with self.assertRaisesRegex(gate.SourceProjectionError, "PROJECTION_SHA_DRIFT"):
            gate.verify_raws(self.slice_raw, gate.canonical(projection), self.course_raw)

    def test_changed_course_bytes_fail_even_if_json_meaning_is_same(self) -> None:
        with self.assertRaisesRegex(gate.SourceProjectionError, "COURSE_SHA_DRIFT"):
            gate.verify_raws(self.slice_raw, self.projection_raw, self.course_raw + b" ")

    def test_course_lesson_change_breaks_canonical_binding(self) -> None:
        course = copy.deepcopy(self.course)
        course["lessons"][0]["title"]["en"] += " changed"
        with self.assertRaisesRegex(gate.SourceProjectionError, "LESSON_CANONICAL_DRIFT"):
            gate.build_projection(self.source, course)

    def test_co_changed_slice_and_projection_cannot_replace_export(self) -> None:
        source = copy.deepcopy(self.source)
        scene = source["lessons"][0]["scenes"][0]
        scene["sourceCueSHA256"] = "f" * 64
        lesson = source["lessons"][0]
        for variant in scene["variants"]:
            identity = {
                "manifestSHA256": gate.MANIFEST_SHA256,
                "app": "choreia",
                "courseSourceSHA256": gate.COURSE_SHA256,
                "lessonId": lesson["lessonId"],
                "lessonCanonicalSHA256": lesson["lessonCanonicalSHA256"],
                "assetId": lesson["assetId"],
                "sceneId": scene["sceneId"],
                "variantStem": variant["stem"],
                "productionSpecSHA256": scene["productionSpecSHA256"],
                "sourceCueSHA256": scene["sourceCueSHA256"],
                "idempotencyKey": scene["idempotencyKey"],
                "productionState": scene["productionState"],
            }
            variant["sourcePinSHA256"] = gate.sha(gate.canonical(identity))
        changed_slice = gate.canonical(source)
        changed_projection = gate.build_projection(source, self.course)
        with self.assertRaisesRegex(gate.SourceProjectionError, "SLICE_SHA_DRIFT"):
            gate.verify_raws(changed_slice, changed_projection, self.course_raw)

    def test_duplicate_pin_and_hold_policy_fail(self) -> None:
        source = copy.deepcopy(self.source)
        variants = source["lessons"][0]["scenes"][0]["variants"]
        variants[1]["sourcePinSHA256"] = variants[0]["sourcePinSHA256"]
        with self.assertRaisesRegex(gate.SourceProjectionError, "VARIANT_ID_OR_DUPLICATE"):
            gate.build_projection(source, self.course)

        source = copy.deepcopy(self.source)
        source["holds"].append({"app": "choreia"})
        with self.assertRaisesRegex(gate.SourceProjectionError, "SOURCE_HOLD"):
            gate.build_projection(source, self.course)

        source = copy.deepcopy(self.source)
        source["lessons"][0]["scenes"][0]["productionState"] = "GENERATED"
        with self.assertRaisesRegex(gate.SourceProjectionError, "SCENE_SOURCE_POLICY"):
            gate.build_projection(source, self.course)

    def test_source_pin_and_schema_drift_fail(self) -> None:
        source = copy.deepcopy(self.source)
        source["lessons"][0]["scenes"][0]["variants"][0]["sourcePinSHA256"] = "f" * 64
        with self.assertRaisesRegex(gate.SourceProjectionError, "VARIANT_SOURCE_PIN_DRIFT"):
            gate.build_projection(source, self.course)

        source = copy.deepcopy(self.source)
        source["lessons"][0]["scenes"][0]["unexpected"] = True
        with self.assertRaisesRegex(gate.SourceProjectionError, "SCENE_SCHEMA"):
            gate.build_projection(source, self.course)

    def test_same_byte_outside_clone_is_rejected_after_precheck_swap(self) -> None:
        # The old Path.is_symlink/stat -> Path.read_bytes sequence follows this
        # swap and accepts the identical SHA from outside the app root.
        # The FD implementation swaps immediately before its leaf open instead.
        with tempfile.TemporaryDirectory() as temporary:
            parent = Path(temporary)
            app = parent / "app"
            target = app / "content/motion_content/choreia.source-slice.v1.json"
            outside = parent / "outside/choreia.source-slice.v1.json"
            target.parent.mkdir(parents=True)
            outside.parent.mkdir()
            target.write_bytes(self.slice_raw)
            outside.write_bytes(self.slice_raw)
            held = target.with_name("held-source.json")
            original_is_symlink = Path.is_symlink
            original_open = os.open
            swapped = False

            def swap() -> None:
                nonlocal swapped
                target.rename(held)
                target.symlink_to(outside)
                swapped = True

            def after_path_precheck(path: Path) -> bool:
                result = original_is_symlink(path)
                if path == target and not swapped:
                    swap()
                return result

            def before_fd_leaf_open(path: str | bytes | os.PathLike[str],
                                    flags: int, mode: int = 0o777,
                                    *, dir_fd: int | None = None) -> int:
                if path == target.name and dir_fd is not None and not swapped:
                    swap()
                if dir_fd is None:
                    return original_open(path, flags, mode)
                return original_open(path, flags, mode, dir_fd=dir_fd)

            with patch.object(gate, "APP", app), \
                 patch.object(Path, "is_symlink", after_path_precheck), \
                 patch("os.open", before_fd_leaf_open):
                with self.assertRaisesRegex(gate.SourceProjectionError,
                                            "LOCAL_ASSET_UNSAFE"):
                    gate.read_local(target, gate.MAX_SLICE_BYTES)
            self.assertTrue(swapped, "the precheck/open race was not exercised")
            self.assertEqual(gate.sha(outside.read_bytes()), gate.SLICE_SHA256)

    def test_intermediate_directory_symlinks_are_rejected(self) -> None:
        for linked_component in ("content", "motion_content"):
            with self.subTest(linked_component=linked_component), \
                 tempfile.TemporaryDirectory() as temporary:
                parent = Path(temporary)
                app = parent / "app"
                outside = parent / "outside"
                target = app / "content/motion_content/choreia.source-slice.v1.json"
                if linked_component == "content":
                    external_leaf = outside / "content/motion_content/choreia.source-slice.v1.json"
                    external_leaf.parent.mkdir(parents=True)
                    app.mkdir()
                    (app / "content").symlink_to(outside / "content", target_is_directory=True)
                else:
                    external_leaf = outside / "motion_content/choreia.source-slice.v1.json"
                    external_leaf.parent.mkdir(parents=True)
                    (app / "content").mkdir(parents=True)
                    (app / "content/motion_content").symlink_to(
                        outside / "motion_content", target_is_directory=True)
                external_leaf.write_bytes(self.slice_raw)
                with patch.object(gate, "APP", app):
                    with self.assertRaisesRegex(gate.SourceProjectionError,
                                                "LOCAL_ASSET_UNSAFE"):
                        gate.read_local(target, gate.MAX_SLICE_BYTES)
                self.assertEqual(gate.sha(external_leaf.read_bytes()), gate.SLICE_SHA256)

    def test_opened_file_growth_and_short_read_fail_with_bounded_read(self) -> None:
        for mutation in ("grow", "shrink"):
            with self.subTest(mutation=mutation), \
                 tempfile.TemporaryDirectory() as temporary:
                app = Path(temporary) / "app"
                target = app / "content/motion_content/choreia.source-slice.v1.json"
                target.parent.mkdir(parents=True)
                target.write_bytes(self.slice_raw)
                original_read = os.read
                mutated = False

                def mutate_before_first_read(fd: int, length: int) -> bytes:
                    nonlocal mutated
                    if not mutated:
                        if mutation == "grow":
                            with target.open("ab") as file:
                                file.write(b"x")
                        else:
                            target.write_bytes(b"")
                        mutated = True
                    return original_read(fd, length)

                with patch.object(gate, "APP", app), \
                     patch("os.read", mutate_before_first_read):
                    with self.assertRaisesRegex(
                        gate.SourceProjectionError, "LOCAL_ASSET_CHANGED_DURING_READ"
                    ):
                        gate.read_local(target, gate.MAX_SLICE_BYTES)
                self.assertTrue(mutated)

    def test_oversized_opened_file_fails_before_read(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            app = Path(temporary) / "app"
            target = app / "content/motion_content/choreia.source-slice.v1.json"
            target.parent.mkdir(parents=True)
            target.write_bytes(b"12345")
            with patch.object(gate, "APP", app), \
                 patch("os.read", side_effect=AssertionError("unexpected read")):
                with self.assertRaisesRegex(gate.SourceProjectionError, "LOCAL_ASSET_SIZE"):
                    gate.read_local(target, 4)


if __name__ == "__main__":
    unittest.main()
