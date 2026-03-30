"""Tests for wang_incremental_64 feather_inpaint_mask_l_from_keep.

Run from repo root: python3 pytool/test_wang_incremental_mask_feather.py
"""

import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

from wang_incremental_64 import feather_inpaint_mask_l_from_keep


class TestFeatherInpaintMask(unittest.TestCase):
    def test_one_dimensional_ramp(self) -> None:
        # Keep x=0,1; inpaint x=2,3,4 — distances 1,2,3 with feather_px=2
        m = Image.new("L", (5, 1), 0)
        px = m.load()
        assert px is not None
        for x in range(2, 5):
            px[x, 0] = 255
        out = feather_inpaint_mask_l_from_keep(m, 2)
        opx = out.load()
        assert opx is not None
        self.assertEqual(opx[0, 0], 0)
        self.assertEqual(opx[1, 0], 0)
        self.assertEqual(opx[2, 0], 128)  # round(255 * 1 / 2)
        self.assertEqual(opx[3, 0], 255)
        self.assertEqual(opx[4, 0], 255)

    def test_feather_zero_returns_copy(self) -> None:
        m = Image.new("L", (2, 2), 255)
        px = m.load()
        assert px is not None
        px[0, 0] = 0
        out = feather_inpaint_mask_l_from_keep(m, 0)
        self.assertEqual(
            [out.getpixel((x, y)) for y in range(2) for x in range(2)],
            [m.getpixel((x, y)) for y in range(2) for x in range(2)],
        )


if __name__ == "__main__":
    unittest.main()
