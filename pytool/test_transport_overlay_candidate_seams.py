#!/usr/bin/env python3
"""Candidate transport overlay isolation and seam checks (Refs #1819)."""

from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from PIL import Image

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "pytool/generate_transport_overlay_tiles_64.py"
CANDIDATE_DIR = REPO / "pytool/out/transport_overlay_atlases_64"
SHIPPED_ROAD = REPO / "app/assets/images/terrain/tilesets/tileset_transport_road_64.png"
SHIPPED_RAIL = REPO / "app/assets/images/terrain/tilesets/tileset_transport_rail_64.png"
SHIPPED_JSON = REPO / "app/assets/data/map_terrain_tilesets.json"


def _load_module():
    spec = importlib.util.spec_from_file_location("generate_transport_overlay_tiles_64", SCRIPT)
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


def _paint_corridor_ns(module: object, image: Image.Image, color: tuple[int, int, int, int]) -> None:
    px = image.load()
    for y in range(module.TILE):
        for x in range(module.CORRIDOR_START, module.CORRIDOR_END):
            px[x, y] = color


class TransportOverlayCandidateSeamsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.mod = _load_module()

    def test_default_out_dir_is_candidate_folder(self) -> None:
        self.assertEqual(self.mod.DEFAULT_ATLAS_OUT_DIR, CANDIDATE_DIR.resolve())
        self.assertNotEqual(self.mod.DEFAULT_ATLAS_OUT_DIR, self.mod.SHIPPED_TILESET_DIR)

    def test_refuse_shipped_out_dir_without_override(self) -> None:
        with self.assertRaises(SystemExit) as raised:
            self.mod.refuse_shipped_out_dir(
                self.mod.SHIPPED_TILESET_DIR,
                allow_shipped=False,
            )
        self.assertEqual(raised.exception.code, 2)

    def test_allow_shipped_out_dir_override(self) -> None:
        self.mod.refuse_shipped_out_dir(
            self.mod.SHIPPED_TILESET_DIR,
            allow_shipped=True,
        )

    def _write_family(self, family_dir: Path, *, break_south: bool = False) -> None:
        seed = Image.new("RGBA", (self.mod.TILE, self.mod.TILE), (0, 0, 0, 0))
        _paint_corridor_ns(self.mod, seed, (160, 110, 70, 255))
        straight = self.mod.normalize_straight(seed)
        contracts = self.mod.build_contracts(straight)
        family_dir.mkdir(parents=True, exist_ok=True)
        straight.save(family_dir / "straight_seed_normalized.png")
        for key, image in contracts.items():
            image.save(family_dir / f"edge_contract_{key}.png")
        self.mod.center_mask_for_inpaint().save(family_dir / "center_mask.png")
        for mask in range(16):
            if mask == 0:
                tile = Image.new("RGBA", (self.mod.TILE, self.mod.TILE), (0, 0, 0, 0))
            else:
                composed = self.mod.compose_mask_contract(mask, contracts)
                tile = self.mod.reinforce_contract_edges(composed, composed)
                if break_south and mask & self.mod.MASK_S:
                    px = tile.load()
                    px[self.mod.CORRIDOR_START, self.mod.TILE - 1] = (255, 0, 0, 255)
            tile.save(family_dir / f"tile_mask_{mask:02d}.png")

    def test_short_corridor_is_extended_to_tile_edges(self) -> None:
        seed = Image.new("RGBA", (self.mod.TILE, self.mod.TILE), (0, 0, 0, 0))
        px = seed.load()
        for y in range(20, 44):
            for x in range(self.mod.CORRIDOR_START, self.mod.CORRIDOR_END):
                px[x, y] = (80, 80, 90, 255)
        straight = self.mod.normalize_straight(seed)
        edge_px = straight.load()
        self.assertGreater(edge_px[self.mod.CORRIDOR_START, 0][3], 0)
        self.assertGreater(edge_px[self.mod.CORRIDOR_START, self.mod.TILE - 1][3], 0)
        with tempfile.TemporaryDirectory() as tmp:
            family_dir = Path(tmp) / "road"
            self._write_family(family_dir)
            errors = self.mod.check_family_seams(family_dir)
            self.assertEqual(errors, [])

    def test_reinforce_restores_transparent_contract_edge_gaps(self) -> None:
        seed = Image.new("RGBA", (self.mod.TILE, self.mod.TILE), (0, 0, 0, 0))
        px = seed.load()
        px[self.mod.CORRIDOR_START, 0] = (10, 20, 30, 255)
        px[self.mod.CORRIDOR_END - 1, 0] = (10, 20, 30, 255)
        for y in range(self.mod.TILE):
            px[self.mod.CORRIDOR_START, y] = (10, 20, 30, 255)
            px[self.mod.CORRIDOR_END - 1, y] = (10, 20, 30, 255)
        straight = self.mod.normalize_straight(seed)
        contracts = self.mod.build_contracts(straight)
        composed = self.mod.compose_mask_contract(self.mod.MASK_N, contracts)
        dirty = composed.copy()
        dirty.putpixel((self.mod.CORRIDOR_START + 2, 0), (255, 0, 0, 255))
        cleaned = self.mod.reinforce_contract_edges(dirty, composed)
        self.assertEqual(
            cleaned.getpixel((self.mod.CORRIDOR_START + 2, 0)),
            composed.getpixel((self.mod.CORRIDOR_START + 2, 0)),
        )

    def test_synthetic_family_seams_fail_on_broken_edge(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            family_dir = Path(tmp) / "road"
            self._write_family(family_dir, break_south=True)
            errors = self.mod.check_family_seams(family_dir)
            self.assertTrue(any("S edge" in err or "complementary" in err for err in errors))

    def test_rebuild_atlas_refuses_shipped_path(self) -> None:
        argv = [
            str(SCRIPT),
            "--rebuild-atlas",
            "--family",
            "road",
            "--out-dir",
            str(self.mod.SHIPPED_TILESET_DIR),
        ]
        with patch.object(sys, "argv", argv), self.assertRaises(SystemExit) as raised:
            self.mod.main()
        self.assertEqual(raised.exception.code, 2)

    def test_shipped_transport_assets_still_present(self) -> None:
        self.assertTrue(SHIPPED_ROAD.is_file())
        self.assertTrue(SHIPPED_RAIL.is_file())
        self.assertTrue(SHIPPED_JSON.is_file())

    def test_clip_plus_removes_square_hub(self) -> None:
        blob = Image.new("RGBA", (self.mod.TILE, self.mod.TILE), (0, 0, 0, 0))
        px = blob.load()
        for y in range(16, 48):
            for x in range(16, 48):
                px[x, y] = (160, 110, 70, 255)
        leak_before = self.mod.plus_leak_count(blob, 15)
        self.assertGreater(leak_before, 0)
        clipped = self.mod.clip_to_mask_plus(blob, 15)
        self.assertEqual(self.mod.plus_leak_count(clipped, 15), 0)
        self.assertGreater(clipped.getpixel((self.mod.CORRIDOR_START, 20))[3], 0)
        self.assertEqual(clipped.getpixel((16, 16))[3], 0)

    def test_unclipped_square_hub_fails_family_plus_check(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            family_dir = Path(tmp) / "road"
            self._write_family(family_dir)
            dirty = Image.open(family_dir / "tile_mask_15.png").convert("RGBA")
            px = dirty.load()
            px[16, 16] = (255, 0, 0, 255)
            dirty.save(family_dir / "tile_mask_15.png")
            errors = self.mod.check_family_seams(family_dir)
            self.assertTrue(any("outside the 14px plus" in err for err in errors))

    def test_rail_period_repeats_sparse_edge_ties(self) -> None:
        seed = Image.new("RGBA", (self.mod.TILE, self.mod.TILE), (0, 0, 0, 0))
        px = seed.load()
        rail = (80, 80, 90, 255)
        tie = (140, 100, 80, 255)
        for y in range(self.mod.TILE):
            px[self.mod.CORRIDOR_START, y] = rail
            px[self.mod.CORRIDOR_END - 1, y] = rail
        for origin in range(20, 48, 7):
            for y in range(origin, min(origin + 3, self.mod.TILE)):
                for x in range(self.mod.CORRIDOR_START, self.mod.CORRIDOR_END):
                    px[x, y] = tie
        straight = self.mod.normalize_straight(seed)
        edge_opaque = sum(
            1
            for x in range(self.mod.CORRIDOR_START, self.mod.CORRIDOR_END)
            if straight.getpixel((x, 0))[3] > 0
        )
        self.assertGreaterEqual(edge_opaque, self.mod.CORRIDOR_PX - 1)

    def test_committed_candidates_pass_seam_check_when_present(self) -> None:
        for family in ("road", "rail"):
            atlas = CANDIDATE_DIR / f"tileset_transport_{family}_64.png"
            if not atlas.is_file():
                self.skipTest(f"candidate {family} atlas not committed yet")
            errors = self.mod.check_atlas_seams(atlas)
            self.assertEqual(errors, [], msg="\n".join(errors))
            with Image.open(atlas) as image:
                rgba = image.convert("RGBA")
                self.assertEqual(rgba.size, (256, 256))
                opaque = 0
                pixels = rgba.load()
                width, height = rgba.size
                for y in range(height):
                    for x in range(width):
                        if pixels[x, y][3] > 0:
                            opaque += 1
                self.assertGreaterEqual(opaque, 2500)


if __name__ == "__main__":
    unittest.main()
