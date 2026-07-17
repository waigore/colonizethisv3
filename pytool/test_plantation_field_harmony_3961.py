#!/usr/bin/env python3
"""Tests for plantation field harmony scoring / PO pick parsing (#3961)."""

from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MODULE = REPO / "pytool/plantation_field_harmony_3961.py"
CANDIDATES = REPO / "pytool/assets/terrain/plantation_field_candidates_3961"


def _load_module():
    spec = importlib.util.spec_from_file_location(
        "plantation_field_harmony_3961",
        MODULE,
    )
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


class PlantationFieldHarmony3961Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.mod = _load_module()

    def test_recommend_picks_match_committed_means(self) -> None:
        picks = self.mod.recommend_picks()
        self.assertEqual(picks["sugar_cane"], "A")
        self.assertEqual(picks["cotton"], "B")
        self.assertEqual(picks["spices"], "A")

    def test_lower_score_is_better_for_sugar_cane_a_vs_b(self) -> None:
        means = self.mod.load_candidate_means(CANDIDATES)
        ow = self.mod.load_ow_reference_means()
        ranked = self.mod.rank_candidates_for_crop(
            "sugar_cane",
            means["sugar_cane"],
            ow_means=ow,
        )
        self.assertEqual(ranked[0][0], "A")
        self.assertLess(ranked[0][3], ranked[1][3])

    def test_parse_po_lock_block(self) -> None:
        text = """
PO LOCK #3961
sugar_cane: A
cotton: B
spices: A
"""
        picks = self.mod.parse_po_picks_from_text(text)
        self.assertIsNotNone(picks)
        assert picks is not None
        self.assertEqual(picks, {"sugar_cane": "A", "cotton": "B", "spices": "A"})

    def test_parse_inline_picks(self) -> None:
        picks = self.mod.parse_po_picks_from_text(
            "Confirmed — sugar_cane=A,cotton=B,spices=C for ship.",
        )
        self.assertEqual(
            picks,
            {"sugar_cane": "A", "cotton": "B", "spices": "C"},
        )

    def test_parse_incomplete_returns_none(self) -> None:
        self.assertIsNone(self.mod.parse_po_picks_from_text("sugar_cane: A only"))

    def test_recommended_combo_validates_pairwise_distinct(self) -> None:
        finalize_spec = importlib.util.spec_from_file_location(
            "finalize_plantation_field_retune_3961",
            REPO / "pytool/finalize_plantation_field_retune_3961.py",
        )
        assert finalize_spec is not None and finalize_spec.loader is not None
        finalize = importlib.util.module_from_spec(finalize_spec)
        finalize_spec.loader.exec_module(finalize)
        picks = self.mod.recommend_picks()
        candidate_means = finalize.load_candidate_means(CANDIDATES)
        locked = finalize.resolve_locked_means(
            candidate_means,
            picks,
            letter_by_id=finalize._load_paint_module().LETTER_BY_ID,
        )
        errors = finalize.validate_plantation_picks(locked)
        self.assertEqual(errors, [])


if __name__ == "__main__":
    unittest.main()
