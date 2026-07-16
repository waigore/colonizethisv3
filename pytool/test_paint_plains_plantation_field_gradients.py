#!/usr/bin/env python3
"""Tests for pytool/paint_plains_plantation_field_gradients.py (Refs #3961)."""

from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "pytool/paint_plains_plantation_field_gradients.py"
BASE = REPO / "pytool/assets/terrain/tile_plains_plantation_base.png"


def _load_module():
    spec = importlib.util.spec_from_file_location(
        "paint_plains_plantation_field_gradients",
        SCRIPT,
    )
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


class PaintPlainsPlantationFieldGradientsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.mod = _load_module()

    def test_exactly_three_candidates_per_retune_crop(self) -> None:
        self.assertEqual(set(self.mod.CANDIDATES), {"sugar_cane", "cotton", "spices"})
        for crop, variants in self.mod.CANDIDATES.items():
            with self.subTest(crop=crop):
                self.assertEqual(len(variants), 3)
                letters = {key[0] for key in variants}
                self.assertEqual(letters, {"A", "B", "C"})

    def test_paint_preserves_alpha_and_changes_field_pixels(self) -> None:
        self.assertTrue(BASE.is_file(), f"missing base {BASE}")
        src = Image.open(BASE).convert("RGBA")
        stops = self.mod.CANDIDATES["sugar_cane"]["A_sage_olive"]
        out = self.mod.paint_field_gradient(src, stops)
        src_px = self.mod._rgba_pixels(src)
        out_px = self.mod._rgba_pixels(out)
        self.assertEqual(
            [p[3] for p in out_px],
            [p[3] for p in src_px],
        )
        changed = 0
        for a, b in zip(src_px, out_px, strict=True):
            if self.mod.is_field_highlight(*a) and a[:3] != b[:3]:
                changed += 1
        self.assertGreater(changed, 50)

    def test_paint_does_not_touch_non_field_pixels(self) -> None:
        src = Image.open(BASE).convert("RGBA")
        stops = self.mod.CANDIDATES["cotton"]["B_grey_fibre"]
        out = self.mod.paint_field_gradient(src, stops)
        for a, b in zip(
            self.mod._rgba_pixels(src),
            self.mod._rgba_pixels(out),
            strict=True,
        ):
            if not self.mod.is_field_highlight(*a):
                self.assertEqual(a, b)

    def test_write_candidates_emits_nine_pngs_not_tobacco(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            out_dir = Path(tmp)
            means = self.mod.write_candidates(BASE, out_dir)
            pngs = sorted(out_dir.glob("tile_plains_*.png"))
            self.assertEqual(len(pngs), 9)
            names = {p.name for p in pngs}
            self.assertFalse(any("tobacco" in n for n in names))
            self.assertIn("sugar_cane", means)
            self.assertIn("cotton", means)
            self.assertIn("spices", means)
            self.assertTrue((out_dir / "CANDIDATE_MEANS.json").is_file())

    def test_promote_rejects_tobacco_and_bad_letter(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            cand = Path(tmp) / "cand"
            app = Path(tmp) / "app"
            app.mkdir()
            self.mod.write_candidates(BASE, cand)
            with self.assertRaises(SystemExit):
                self.mod.promote(cand, app, {"tobacco": "A"})
            with self.assertRaises(SystemExit):
                self.mod.promote(cand, app, {"sugar_cane": "Z"})

    def test_promote_copies_locked_pick_only(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            cand = Path(tmp) / "cand"
            app = Path(tmp) / "app"
            app.mkdir()
            self.mod.write_candidates(BASE, cand)
            self.mod.promote(cand, app, {"sugar_cane": "A", "cotton": "B", "spices": "C"})
            for stem in ("sugar_cane", "cotton", "spices"):
                self.assertTrue((app / f"tile_plains_{stem}.png").is_file())
            self.assertFalse((app / "tile_plains_tobacco.png").exists())


if __name__ == "__main__":
    unittest.main()
