#!/usr/bin/env python3
"""Tests for pytool/finalize_plantation_field_retune_3961.py (Refs #3961)."""

from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "pytool/finalize_plantation_field_retune_3961.py"
CANDIDATES = REPO / "pytool/assets/terrain/plantation_field_candidates_3961"


def _load_module():
    spec = importlib.util.spec_from_file_location(
        "finalize_plantation_field_retune_3961",
        SCRIPT,
    )
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


class FinalizePlantationFieldRetune3961Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.mod = _load_module()
        cls.paint = cls.mod._load_paint_module()

    def test_resolve_locked_means_from_candidate_json(self) -> None:
        means = self.mod.load_candidate_means(CANDIDATES)
        locked = self.mod.resolve_locked_means(
            means,
            {"sugar_cane": "A", "cotton": "B", "spices": "C"},
            letter_by_id=self.paint.LETTER_BY_ID,
        )
        self.assertEqual(locked["tobacco"], self.mod.TOBACCO_MEAN)
        self.assertEqual(locked["sugar_cane"], tuple(means["sugar_cane"]["A_sage_olive"]))
        self.assertEqual(locked["cotton"], tuple(means["cotton"]["B_grey_fibre"]))
        self.assertEqual(locked["spices"], tuple(means["spices"]["C_ochre_turmeric"]))

    def test_resolve_rejects_incomplete_picks(self) -> None:
        means = self.mod.load_candidate_means(CANDIDATES)
        with self.assertRaises(SystemExit):
            self.mod.resolve_locked_means(
                means,
                {"sugar_cane": "A"},
                letter_by_id=self.paint.LETTER_BY_ID,
            )

    def test_patch_spec_and_dart_round_trip(self) -> None:
        means = {
            "sugar_cane": (109, 137, 77),
            "tobacco": (128, 108, 42),
            "cotton": (181, 179, 173),
            "spices": (161, 122, 56),
        }
        with tempfile.TemporaryDirectory() as tmp:
            spec = Path(tmp) / "layered.md"
            spec.write_text(
                "pipeline\n"
                "- **Plantation pipeline (Refs #3961):** One base. "
                "**PO sample gate (in progress):** subtler sugar_cane / cotton / spices "
                "fields must use hand-painted field gradients via "
                "`pytool/paint_plains_plantation_field_gradients.py` (3 candidates/crop "
                "under `pytool/assets/terrain/plantation_field_candidates_3961/`); tobacco "
                "stays; final SPEC mid-tones + shipped PNGs update only after PO locks a "
                "letter per crop (`--promote`).\n"
                "- **PIL field mid-tones (shipped until PO lock):** sugar_cane `(124,179,66)`; "
                "tobacco `(128,108,42)`; cotton `(214,208,178)`; spices `(196,98,42)`.\n",
                encoding="utf-8",
            )
            dart = Path(tmp) / "goldens_test.dart"
            dart.write_text(
                "const _plantationFieldMidTones = <String, (int, int, int)>{\n"
                "  'tile_plains_sugar_cane': (124, 179, 66),\n"
                "  'tile_plains_tobacco': (128, 108, 42),\n"
                "  'tile_plains_cotton': (214, 208, 178),\n"
                "  'tile_plains_spices': (196, 98, 42),\n"
                "};\n",
                encoding="utf-8",
            )
            line = self.mod.patch_spec_midtones(spec, means)
            self.assertIn("109,137,77", line)
            self.assertIn("PO-approved hand-painted fields", spec.read_text(encoding="utf-8"))
            self.mod.patch_golden_test_midtones(dart, means)
            body = dart.read_text(encoding="utf-8")
            self.assertIn("'tile_plains_sugar_cane': (109, 137, 77)", body)
            self.assertIn("'tile_plains_cotton': (181, 179, 173)", body)


if __name__ == "__main__":
    unittest.main()
