#!/usr/bin/env python3
"""Tests for pytool/render_plantation_po_review_strip_3961.py (Refs #3961)."""

from __future__ import annotations

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "pytool/render_plantation_po_review_strip_3961.py"
CANDIDATES = REPO / "pytool/assets/terrain/plantation_field_candidates_3961"
TERRAIN = REPO / "app/assets/images/terrain"


def _load_module():
    spec = importlib.util.spec_from_file_location(
        "render_plantation_po_review_strip_3961",
        SCRIPT,
    )
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


class RenderPlantationPoReviewStrip3961Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.mod = _load_module()

    def test_crop_strip_row_has_eight_tiles(self) -> None:
        paint = self.mod._load_paint_module()
        row = self.mod.crop_strip_row(
            TERRAIN,
            CANDIDATES,
            "sugar_cane",
            letter_by_id=paint.LETTER_BY_ID,
            scale=4,
        )
        # 4 refs + 3 candidates + CURRENT shipped = 8 tiles @ 64px × 4
        self.assertEqual(row.width, 8 * 64 * 4)
        self.assertEqual(row.height, 64 * 4)

    def test_render_strips_writes_overview_and_notes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)
            written = self.mod.render_strips(TERRAIN, CANDIDATES, out, scale=2)
            names = {p.name for p in written}
            self.assertIn("strip_all_crops_x2.png", names)
            self.assertIn("strip_sugar_cane_x2.png", names)
            # Variant ids already include the letter; do not double it.
            self.assertIn("sugar_cane_A_sage_olive_x2.png", names)
            self.assertIn("cotton_B_grey_fibre_x2.png", names)
            self.assertIn("spices_C_ochre_turmeric_x2.png", names)
            self.assertNotIn("sugar_cane_A_A_sage_olive_x2.png", names)
            self.assertTrue((out / "CANDIDATE_NOTES.md").is_file())
            with Image.open(out / "strip_all_crops_x2.png") as overview:
                self.assertGreater(overview.width, 0)
                self.assertGreater(overview.height, 64 * 2)

    def test_composition_row_has_seven_tiles(self) -> None:
        paint = self.mod._load_paint_module()
        picks = {"sugar_cane": "A", "cotton": "B", "spices": "A"}
        row = self.mod.composition_row(
            TERRAIN,
            CANDIDATES,
            picks,
            letter_by_id=paint.LETTER_BY_ID,
            scale=2,
        )
        # 4 refs + 3 picked crops
        self.assertEqual(row.width, 7 * 64 * 2)
        self.assertEqual(row.height, 64 * 2)

    def test_render_composition_strip_writes_two_row_png(self) -> None:
        picks = {"sugar_cane": "A", "cotton": "B", "spices": "A"}
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)
            written = self.mod.render_composition_strip(
                TERRAIN,
                CANDIDATES,
                out,
                picks,
                scale=2,
            )
            names = {p.name for p in written}
            self.assertIn("strip_composition_sugar_caneA_cottonB_spicesA_x2.png", names)
            self.assertIn("COMPOSITION_NOTES.md", names)
            png = out / "strip_composition_sugar_caneA_cottonB_spicesA_x2.png"
            with Image.open(png) as im:
                # two rows + gap
                self.assertEqual(im.width, 7 * 64 * 2)
                self.assertEqual(im.height, 2 * 64 * 2 + 8 * 2 // 4)
            notes = (out / "COMPOSITION_NOTES.md").read_text(encoding="utf-8")
            self.assertIn("sugar_cane=A,cotton=B,spices=A", notes)

    def test_cli_picks_and_recommend_are_mutually_exclusive(self) -> None:
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT),
                "--picks",
                "sugar_cane=A,cotton=B,spices=A",
                "--recommend",
            ],
            cwd=REPO,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("mutually exclusive", (result.stderr + result.stdout).lower())

    def test_cli_recommend_writes_composition(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)
            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    "--recommend",
                    "--scale",
                    "2",
                    "--out-dir",
                    str(out),
                ],
                cwd=REPO,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, msg=result.stderr + result.stdout)
            pngs = list(out.glob("strip_composition_*_x2.png"))
            self.assertEqual(len(pngs), 1)
            self.assertTrue((out / "COMPOSITION_NOTES.md").is_file())


if __name__ == "__main__":
    unittest.main()
