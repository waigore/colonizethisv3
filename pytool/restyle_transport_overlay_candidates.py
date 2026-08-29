#!/usr/bin/env python3
"""
Terrain-palette procedural restyle for transport overlay candidates (Refs #1819).

When PixelLab seeds drift from the live terrain tileset (or PIXELLAB_API_KEY is
unavailable), this script builds new straight seeds from the sea/plains palette
and rebuilds masks 0..15 via the locked N/E/S/W contract compositor in
generate_transport_overlay_tiles_64.py (no per-mask independent images).

Does not claim PixelLab provenance. Shipped UI atlases are never written.
"""

from __future__ import annotations

import argparse
import importlib.util
import sys
from collections import Counter
from pathlib import Path

from PIL import Image

REPO_ROOT = Path(__file__).resolve().parents[1]
GENERATOR = REPO_ROOT / "pytool/generate_transport_overlay_tiles_64.py"
DEFAULT_TERRAIN = REPO_ROOT / "app/assets/images/terrain/tilesets/tileset_sea_plains_v2_64.png"
DEFAULT_CONTRACTS = REPO_ROOT / "pytool/out/transport_edge_contracts_64"
DEFAULT_ATLAS_OUT = REPO_ROOT / "pytool/out/transport_overlay_atlases_64"
SHIPPED_TILESET_DIR = REPO_ROOT / "app/assets/images/terrain/tilesets"
SEPIA_TILESET_DIR = REPO_ROOT / "app/assets/themes/sepia/images/terrain/tilesets"
WIDGETBOOK_CANDIDATE_DIR = REPO_ROOT / "widgetbook_host/assets/transport_overlay_candidates"

PROMOTE_TARGETS = (
    SHIPPED_TILESET_DIR,
    SEPIA_TILESET_DIR,
    WIDGETBOOK_CANDIDATE_DIR,
)


def load_generator():
    spec = importlib.util.spec_from_file_location("generate_transport_overlay_tiles_64", GENERATOR)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load {GENERATOR}")
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


def det_hash(x: int, y: int, salt: int = 0) -> int:
    return ((x * 374761393 + y * 668265263 + salt * 982451653) ^ (x << 13)) & 0xFFFFFFFF


def pick(seq: list[tuple[int, int, int, int]], x: int, y: int, salt: int = 0) -> tuple[int, int, int, int]:
    return seq[det_hash(x, y, salt) % len(seq)]


def extract_terrain_earth_palette(terrain_path: Path, *, top_n: int = 24) -> list[tuple[int, int, int, int]]:
    """Return muted land tones from the live terrain atlas (greens/browns, not sea blues)."""
    image = Image.open(terrain_path).convert("RGBA")
    counts: Counter[tuple[int, int, int, int]] = Counter()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = image.getpixel((x, y))
            if a == 0:
                continue
            if g < 30 or b > 110:
                continue
            counts[(r, g, b, 255)] += 1
    if not counts:
        raise RuntimeError(f"No land palette samples in {terrain_path}")
    return [color for color, _ in counts.most_common(top_n)]


def road_palette(terrain_earth: list[tuple[int, int, int, int]]) -> list[tuple[int, int, int, int]]:
    """Muted browns anchored to shipped road + terrain olive edge tones."""
    shipped = [
        (153, 101, 56, 255),
        (122, 82, 48, 255),
        (108, 78, 40, 255),
        (92, 60, 34, 255),
        (78, 55, 30, 255),
    ]
    olive = [c for c in terrain_earth if c[1] > c[0] and c[0] < 120][:6]
    return shipped + olive


def build_road_straight(mod: object, palette: list[tuple[int, int, int, int]]) -> Image.Image:
    tile = mod.TILE
    start = mod.CORRIDOR_START
    end = mod.CORRIDOR_END
    image = Image.new("RGBA", (tile, tile), (0, 0, 0, 0))
    px = image.load()
    for y in range(tile):
        for x in range(start, end):
            edge = min(x - start, end - 1 - x)
            if edge == 0:
                color = (70, 50, 28, 255)
            elif edge == 1:
                color = (88, 62, 36, 255)
            else:
                color = pick(palette, x, y, salt=1)
                if det_hash(x, y, 7) % 11 == 0:
                    color = pick(palette, x, y, salt=3)
            px[x, y] = color
    return mod.normalize_straight(image)


def build_rail_straight(mod: object, terrain_earth: list[tuple[int, int, int, int]]) -> Image.Image:
    tile = mod.TILE
    start = mod.CORRIDOR_START
    end = mod.CORRIDOR_END
    bed = (118, 122, 120, 255)
    steel = (68, 72, 76, 255)
    tie_dark = (88, 60, 38, 255)
    tie_mid = (108, 78, 50, 255)
    gravel = pick(
        [c for c in terrain_earth if 60 < c[0] < 130 and 70 < c[1] < 140] or [bed],
        0,
        0,
        salt=9,
    )
    image = Image.new("RGBA", (tile, tile), (0, 0, 0, 0))
    px = image.load()
    tie_period = 8
    tie_height = 3
    for y in range(tile):
        in_tie = (y % tie_period) < tie_height
        for x in range(start, end):
            if in_tie:
                px[x, y] = tie_dark if (x + y) % 3 else tie_mid
            else:
                px[x, y] = gravel if det_hash(x, y, 5) % 17 == 0 else bed
        px[start + 2, y] = steel
        px[end - 3, y] = steel
    return mod.normalize_straight(image)


def write_family_seed(mod: object, family: str, straight: Image.Image, contracts_out: Path) -> Path:
    family_dir = contracts_out / family
    family_dir.mkdir(parents=True, exist_ok=True)
    straight_path = family_dir / "straight_seed_normalized.png"
    straight.save(straight_path)
    contracts = mod.build_contracts(straight)
    for key, contract in contracts.items():
        contract.save(family_dir / f"edge_contract_{key}.png")
    mod.inpaint_mask_for_mask(mod.MASK_N | mod.MASK_E | mod.MASK_S | mod.MASK_W).save(
        family_dir / "center_mask.png",
    )
    return family_dir


def write_terrain_qa_composites(
    mod: object,
    family_dir: Path,
    terrain_path: Path,
    out_dir: Path,
) -> None:
    """QA joins on a representative plains tile (not flat green fill)."""
    terrain = Image.open(terrain_path).convert("RGBA")
    best_mask = 0
    best_score = -1
    for mask in range(16):
        col = mask % 4
        row = mask // 4
        tile = terrain.crop((col * 64, row * 64, (col + 1) * 64, (row + 1) * 64))
        score = sum(
            1
            for y in range(64)
            for x in range(64)
            if tile.getpixel((x, y))[1] > 70 and tile.getpixel((x, y))[0] < 120
        )
        if score > best_score:
            best_score = score
            best_mask = mask
    col = best_mask % 4
    row = best_mask // 4
    plains_tile = terrain.crop((col * 64, row * 64, (col + 1) * 64, (row + 1) * 64))

    family = family_dir.name
    tiles: dict[int, Image.Image] = {}
    for mask in range(16):
        tile_path = family_dir / f"tile_mask_{mask:02d}.png"
        tiles[mask] = Image.open(tile_path).convert("RGBA")

    out_dir.mkdir(parents=True, exist_ok=True)
    for name, cells in mod.QA_LAYOUTS.items():
        cols = max(cell[0] for cell in cells) + 1
        rows = max(cell[1] for cell in cells) + 1
        canvas = Image.new("RGBA", (cols * 64, rows * 64), (0, 0, 0, 255))
        for c, r, mask in cells:
            base = plains_tile.copy()
            base.alpha_composite(tiles[mask])
            canvas.paste(base, (c * 64, r * 64))
        dest = out_dir / f"qa_{family}_{name}_on_plains.png"
        canvas.save(dest)
        print(f"[{family}] wrote terrain QA composite {dest}")


def promote_atlases(out_dir: Path, *, families: tuple[str, ...]) -> None:
    """Copy candidate atlases into shipped default, sepia theme, and Widgetbook paths."""
    for family in families:
        source = out_dir / f"tileset_transport_{family}_64.png"
        if not source.is_file():
            raise FileNotFoundError(f"Missing candidate atlas to promote: {source}")
        for target_dir in PROMOTE_TARGETS:
            target_dir.mkdir(parents=True, exist_ok=True)
            dest = target_dir / source.name
            dest.write_bytes(source.read_bytes())
            print(f"[{family}] promoted {source.name} -> {dest}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--terrain", type=Path, default=DEFAULT_TERRAIN)
    parser.add_argument("--contracts-out", type=Path, default=DEFAULT_CONTRACTS)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_ATLAS_OUT)
    parser.add_argument("--family", choices=["road", "rail", "both"], default="both")
    parser.add_argument(
        "--terrain-qa",
        action="store_true",
        help="Also write QA composites overlaid on a plains terrain tile",
    )
    parser.add_argument(
        "--promote",
        action="store_true",
        help=(
            "After rebuild, copy candidate atlases into shipped default + sepia theme "
            "tileset folders and Widgetbook candidate assets (byte-identical copies)."
        ),
    )
    parser.add_argument(
        "--promote-only",
        action="store_true",
        help="Copy existing candidate atlases from --out-dir into shipped/theme paths (no rebuild).",
    )
    args = parser.parse_args()

    if args.promote_only:
        families = ("road", "rail") if args.family == "both" else (args.family,)
        promote_atlases(args.out_dir.resolve(), families=families)
        return

    mod = load_generator()
    mod.refuse_shipped_out_dir(args.out_dir.resolve(), allow_shipped=False)

    terrain_path = args.terrain.resolve()
    if not terrain_path.is_file():
        raise SystemExit(f"Terrain atlas not found: {terrain_path}")

    earth = extract_terrain_earth_palette(terrain_path)
    road_colors = road_palette(earth)

    built_families: list[tuple[str, Image.Image]] = []
    if args.family in ("road", "both"):
        built_families.append(("road", build_road_straight(mod, road_colors)))
    if args.family in ("rail", "both"):
        built_families.append(("rail", build_rail_straight(mod, earth)))

    family_keys: list[str] = []
    for family, straight in built_families:
        family_keys.append(family)
        family_dir = write_family_seed(mod, family, straight, args.contracts_out.resolve())
        mod.refresh_family_tiles_from_seed(family_dir)
        atlas_path = args.out_dir.resolve() / f"tileset_transport_{family}_64.png"
        mod.build_atlas_from_tiles(family_dir, atlas_path)
        seam_errors = mod.check_family_seams(family_dir)
        if seam_errors:
            raise RuntimeError("Seam check failed:\n" + "\n".join(seam_errors))
        mod.write_qa_composites(family_dir, args.out_dir.resolve())
        if args.terrain_qa:
            write_terrain_qa_composites(mod, family_dir, terrain_path, args.out_dir.resolve())
        print(f"[{family}] restyle complete -> {atlas_path}")

    if args.promote:
        promote_atlases(args.out_dir.resolve(), families=tuple(family_keys))


if __name__ == "__main__":
    main()
