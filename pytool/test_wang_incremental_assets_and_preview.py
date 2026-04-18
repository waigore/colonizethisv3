#!/usr/bin/env python3
"""Committed Wang incremental assets + map preview smoke test. No network."""
from __future__ import annotations

import tempfile
import unittest
from argparse import Namespace
from pathlib import Path

from PIL import Image

from pack_sea_plains_wang_tileset_64 import cmd_preview, repo_root_from_script


TILE = 64


class TestWangIncrementalAssets(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.root = repo_root_from_script()
        cls.tiles_dir = cls.root / "app/assets/images/terrain/base_64/wang_incremental/tiles"
        cls.atlas_png = cls.root / "app/assets/images/terrain/tilesets/tileset_sea_plains_incremental_64.png"
        cls.tile_map = cls.root / (
            "app/assets/images/terrain/tilesets/_tile_map_incremental_preview_seed100.json"
        )

    def test_incremental_tiles_64_png(self) -> None:
        for i in range(16):
            p = self.tiles_dir / f"tile_{i:02d}.png"
            self.assertTrue(p.is_file(), f"missing {p}")
            with Image.open(p) as im:
                self.assertEqual(im.size, (TILE, TILE), p.name)
                self.assertEqual(im.format, "PNG")

    def test_incremental_atlas_png(self) -> None:
        self.assertTrue(self.atlas_png.is_file())
        with Image.open(self.atlas_png) as im:
            self.assertEqual(im.size, (256, 256))
            self.assertEqual(im.format, "PNG")

    def test_tile_map_and_preview_smoke(self) -> None:
        self.assertTrue(self.tile_map.is_file())
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as f:
            out = Path(f.name)
        try:
            cmd_preview(
                Namespace(
                    tile_map_json=self.tile_map,
                    tileset_png=self.atlas_png,
                    out_png=out,
                    cell_size=64,
                )
            )
            self.assertTrue(out.is_file())
            self.assertGreater(out.stat().st_size, 500)
            with Image.open(out) as im:
                self.assertEqual(im.format, "PNG")
        finally:
            out.unlink(missing_ok=True)


if __name__ == "__main__":
    unittest.main()
