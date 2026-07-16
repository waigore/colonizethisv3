#!/usr/bin/env python3
"""Tests for pytool/render_plantation_po_review_strip_3961.py (Refs #3961)."""

from __future__ import annotations

import importlib.util
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


if __name__ == "__main__":
    unittest.main()
