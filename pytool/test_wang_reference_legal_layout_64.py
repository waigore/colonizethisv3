"""Tests for wang_reference_legal_layout_64 (stdlib unittest).

Run from repo root: python3 pytool/test_wang_reference_legal_layout_64.py
"""
from __future__ import annotations

import random
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from wang_reference_legal_layout_64 import (
    build_compatibility_tables,
    solve_legal_layout,
    validate_layout,
)


class TestLegalLayout(unittest.TestCase):
    def test_validate_rejects_row_major_atlas(self) -> None:
        can_r, can_d = build_compatibility_tables()
        atlas = [[r * 4 + c for c in range(4)] for r in range(4)]
        self.assertFalse(validate_layout(atlas, can_right=can_r, can_down=can_d))

    def test_solver_seed_zero_satisfies_constraints(self) -> None:
        can_r, can_d = build_compatibility_tables()
        rng = random.Random(0)
        grid = solve_legal_layout(
            can_right=can_r,
            can_down=can_d,
            rng=rng,
            forward_checking=True,
        )
        self.assertIsNotNone(grid)
        assert grid is not None
        self.assertTrue(validate_layout(grid, can_right=can_r, can_down=can_d))
        flat = [grid[r][c] for r in range(4) for c in range(4)]
        self.assertEqual(len(flat), 16)
        self.assertEqual(len(set(flat)), 16)
        self.assertEqual(set(flat), set(range(16)))

    def test_golden_seed_zero_layout(self) -> None:
        can_r, can_d = build_compatibility_tables()
        rng = random.Random(0)
        grid = solve_legal_layout(
            can_right=can_r,
            can_down=can_d,
            rng=rng,
            forward_checking=True,
        )
        self.assertIsNotNone(grid)
        expected = [
            [10, 5, 14, 12],
            [8, 4, 9, 2],
            [0, 1, 7, 11],
            [3, 6, 13, 15],
        ]
        self.assertEqual(grid, expected)


if __name__ == "__main__":
    unittest.main()
