#!/usr/bin/env python3
"""
Pack `tile_00.png`…`tile_15.png` into a 4×4×64 Wang atlas + JSON shaped like PixelLab tilesets
(`tileset_sea_plains.json`). Atlas layout: **row-major wang_index** — tile K at (K % 4, K // 4)×64px.

Subcommand **preview**: render sea/plains coastline from `generate_map --write-tile-map-json` using the same
corner rules as `region_map_component.dart` (_getCoastlineCornerValues for sea; land = upper base).

Spec: SPEC/ui/tileset/plains-sea-wang-inpaint-64.md, SPEC/program/map-data.md (TileMapResult JSON).
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

from PIL import Image

TILE = 64
ATLAS = TILE * 4


def repo_root_from_script() -> Path:
    return Path(__file__).resolve().parent.parent


def wang_index_from_corners(nw: bool, ne: bool, sw: bool, se: bool) -> int:
    return (8 if nw else 0) | (4 if ne else 0) | (2 if sw else 0) | (1 if se else 0)


def wang_name_to_index(name: str) -> int:
    m = re.search(r"wang_(\d+)", name, re.IGNORECASE)
    if not m:
        raise ValueError(f"cannot parse wang index from name={name!r}")
    k = int(m.group(1))
    if not 0 <= k <= 15:
        raise ValueError(f"wang index out of 0..15: {k} from {name!r}")
    return k


def bbox_row_major_wang(k: int) -> dict[str, int]:
    col, row = k % 4, k // 4
    return {"x": col * TILE, "y": row * TILE, "width": TILE, "height": TILE}


def cmd_pack(args: argparse.Namespace) -> None:
    ref_path: Path = args.ref_json
    tiles_dir: Path = args.tiles_dir
    out_png: Path = args.out_png
    out_json: Path = args.out_json

    data = json.loads(ref_path.read_text(encoding="utf-8"))
    tiles = data.get("tileset_data", {}).get("tiles")
    if not isinstance(tiles, list):
        print("ref JSON missing tileset_data.tiles list", file=sys.stderr)
        sys.exit(1)

    atlas = Image.new("RGBA", (ATLAS, ATLAS), (0, 0, 0, 0))
    for k in range(16):
        p = tiles_dir / f"tile_{k:02d}.png"
        if not p.is_file():
            print(f"missing tile: {p}", file=sys.stderr)
            sys.exit(1)
        im = Image.open(p).convert("RGBA")
        if im.size != (TILE, TILE):
            print(f"expected {TILE}×{TILE}, got {im.size} for {p}", file=sys.stderr)
            sys.exit(1)
        x, y = (k % 4) * TILE, (k // 4) * TILE
        atlas.paste(im, (x, y))

    out_png.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(out_png)

    out_data = json.loads(json.dumps(data))
    out_data.setdefault("tileset_data", {})
    out_data["tileset_data"]["tile_size"] = {"width": TILE, "height": TILE}
    out_data.setdefault("tile_size", {"width": TILE, "height": TILE})
    if "tileset_image" in out_data and isinstance(out_data["tileset_image"], dict):
        out_data["tileset_image"]["dimensions"] = {"width": ATLAS, "height": ATLAS}

    new_tiles = []
    for t in tiles:
        if not isinstance(t, dict):
            continue
        name = str(t.get("name", ""))
        k = wang_name_to_index(name)
        t2 = dict(t)
        t2["bounding_box"] = bbox_row_major_wang(k)
        new_tiles.append(t2)
    out_data["tileset_data"]["tiles"] = new_tiles
    out_data["tileset_data"]["total_tiles"] = 16

    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(out_data, indent=2), encoding="utf-8")
    print(f"wrote {out_png}\nwrote {out_json}")


def is_sea_cell(cell_id: str) -> bool:
    return len(cell_id) > 0 and cell_id[0] == "s"


def is_land_at(grid: list[list[str]], x: int, y: int, w: int, h: int) -> bool:
    if x < 0 or y < 0 or x >= w or y >= h:
        return False
    return not is_sea_cell(grid[y][x])


def coastline_corners_for_sea(
    grid: list[list[str]],
    x: int,
    y: int,
    w: int,
    h: int,
) -> tuple[bool, bool, bool, bool, bool]:
    """Returns (nw, ne, sw, se, same_interior_sea) matching Dart _getCoastlineCornerValues."""
    nw_l = is_land_at(grid, x - 1, y - 1, w, h)
    n_l = is_land_at(grid, x, y - 1, w, h)
    ne_l = is_land_at(grid, x + 1, y - 1, w, h)
    w_l = is_land_at(grid, x - 1, y, w, h)
    e_l = is_land_at(grid, x + 1, y, w, h)
    sw_l = is_land_at(grid, x - 1, y + 1, w, h)
    s_l = is_land_at(grid, x, y + 1, w, h)
    se_l = is_land_at(grid, x + 1, y + 1, w, h)

    has_nw = nw_l or n_l or w_l
    has_ne = ne_l or n_l or e_l
    has_sw = sw_l or s_l or w_l
    has_se = se_l or s_l or e_l
    all_same = has_nw == has_ne == has_sw == has_se
    same = all_same and not has_nw
    return has_nw, has_ne, has_sw, has_se, same


def crop_wang(atlas: Image.Image, wang_idx: int) -> Image.Image:
    x, y = (wang_idx % 4) * TILE, (wang_idx // 4) * TILE
    return atlas.crop((x, y, x + TILE, y + TILE))


def _average_center_rgba(
    atlas: Image.Image, wang_idx: int, half: int = 4
) -> tuple[int, int, int, int]:
    """Opaque RGBA sampled from wang tile interior (for underpaint behind semi-transparent edges)."""
    x0, y0 = (wang_idx % 4) * TILE, (wang_idx // 4) * TILE
    cx, cy = x0 + TILE // 2, y0 + TILE // 2
    px = atlas.load()
    r_acc = g_acc = b_acc = n = 0
    for dy in range(-half, half):
        for dx in range(-half, half):
            r, g, b, _a = px[cx + dx, cy + dy]
            r_acc += r
            g_acc += g
            b_acc += b
            n += 1
    return (r_acc // n, g_acc // n, b_acc // n, 255)


def cmd_preview(args: argparse.Namespace) -> None:
    tm_path: Path = args.tile_map_json
    atlas_path: Path = args.tileset_png
    out_path: Path = args.out_png
    cell = args.cell_size

    tm = json.loads(tm_path.read_text(encoding="utf-8"))
    w = int(tm["width"])
    h = int(tm["height"])
    grid_raw = tm["grid"]
    grid = [[str(row[c]) for c in range(len(row))] for row in grid_raw]

    atlas = Image.open(atlas_path).convert("RGBA")
    if atlas.size != (ATLAS, ATLAS):
        print(f"expected atlas {ATLAS}×{ATLAS}, got {atlas.size}", file=sys.stderr)
        sys.exit(1)

    scale = cell // TILE
    if cell != TILE * scale:
        print(f"--cell-size must be a multiple of {TILE}, got {cell}", file=sys.stderr)
        sys.exit(1)

    out_w, out_h = w * cell, h * cell
    # Match in-game layering: opaque underpaint per cell so transparent / soft tile edges
    # do not reveal a global background (black was showing as grid seams between cells).
    sea_fill = _average_center_rgba(atlas, 0)
    land_fill = _average_center_rgba(atlas, 15)
    out_img = Image.new("RGBA", (out_w, out_h), sea_fill)
    sea_cell_bg = Image.new("RGBA", (cell, cell), sea_fill)
    land_cell_bg = Image.new("RGBA", (cell, cell), land_fill)

    for y in range(h):
        for x in range(w):
            cid = grid[y][x]
            sea = is_sea_cell(cid)
            if sea:
                nw_c, ne_c, sw_c, se_c, same = coastline_corners_for_sea(grid, x, y, w, h)
                if same:
                    idx = 0
                else:
                    idx = wang_index_from_corners(nw_c, ne_c, sw_c, se_c)
            else:
                idx = 15
            patch = crop_wang(atlas, idx)
            if scale != 1:
                patch = patch.resize((cell, cell), Image.Resampling.NEAREST)
            x0, y0 = x * cell, y * cell
            out_img.paste(sea_cell_bg if sea else land_cell_bg, (x0, y0))
            out_img.paste(patch, (x0, y0), patch)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_img.save(out_path)
    print(f"wrote {out_path} ({out_w}×{out_h})")


def main() -> None:
    root = repo_root_from_script()
    default_ref = root / "app/assets/images/terrain/tilesets/tileset_sea_plains.json"
    default_tiles = root / "app/assets/images/terrain/base_64/wang_incremental/tiles"
    default_out_png = root / "app/assets/images/terrain/tilesets/tileset_sea_plains_incremental_64.png"
    default_out_json = root / "app/assets/images/terrain/tilesets/tileset_sea_plains_incremental_64.json"

    parser = argparse.ArgumentParser(description="Pack / preview 64×64 sea↔plains Wang tileset")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_pack = sub.add_parser("pack", help="Build atlas PNG + JSON from reference + tile_*.png")
    p_pack.add_argument("--ref-json", type=Path, default=default_ref)
    p_pack.add_argument("--tiles-dir", type=Path, default=default_tiles)
    p_pack.add_argument("--out-png", type=Path, default=default_out_png)
    p_pack.add_argument("--out-json", type=Path, default=default_out_json)
    p_pack.set_defaults(func=cmd_pack)

    p_prev = sub.add_parser("preview", help="Render map PNG from TileMapResult JSON + atlas")
    p_prev.add_argument("--tile-map-json", type=Path, required=True)
    p_prev.add_argument(
        "--tileset-png",
        type=Path,
        default=default_out_png,
        help="256×256 atlas from pack (row-major wang)",
    )
    p_prev.add_argument("--out-png", type=Path, required=True)
    p_prev.add_argument(
        "--cell-size",
        type=int,
        default=64,
        help=f"Output pixels per map cell (multiple of {TILE}; default 64)",
    )
    p_prev.set_defaults(func=cmd_preview)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
