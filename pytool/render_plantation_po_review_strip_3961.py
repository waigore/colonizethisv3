#!/usr/bin/env python3
"""Render PO review strips for plantation field-gradient candidates (Refs #3961).

Builds 4× nearest-neighbor strips at map tile scale: OW reference tiles
(grain / meat / horses / tobacco), three hand-painted candidates (A/B/C), and
the current shipped overlay per retune crop. Does not modify app terrain.

See SPEC/ui/pytool-image-tools.md § render_plantation_po_review_strip_3961.py.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[1]
PAINT_SCRIPT = REPO / "pytool/paint_plains_plantation_field_gradients.py"
DEFAULT_CANDIDATES = (
    REPO / "pytool/assets/terrain/plantation_field_candidates_3961"
)
REFERENCE_STEMS = ("grain", "meat", "horses", "tobacco")
RETUNE_CROPS = ("sugar_cane", "cotton", "spices")
LETTERS = ("A", "B", "C")
TILE_PX = 64
SCALE = 4
ROW_GAP_PX = 8


def _load_paint_module():
    spec = importlib.util.spec_from_file_location(
        "paint_plains_plantation_field_gradients",
        PAINT_SCRIPT,
    )
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


def upscale_nearest(im: Image.Image, scale: int) -> Image.Image:
    w, h = im.size
    return im.resize((w * scale, h * scale), Image.Resampling.NEAREST)


def load_rgba(path: Path) -> Image.Image:
    if not path.is_file():
        raise SystemExit(f"missing tile PNG: {path}")
    with Image.open(path) as opened:
        im = opened.convert("RGBA")
    if im.size != (TILE_PX, TILE_PX):
        raise SystemExit(f"expected 64×64, got {im.size} for {path}")
    return im


def concat_horizontal(tiles: list[Image.Image], *, gap: int = 0) -> Image.Image:
    if not tiles:
        raise SystemExit("concat_horizontal requires at least one tile")
    height = tiles[0].height
    width = sum(t.width for t in tiles) + gap * max(0, len(tiles) - 1)
    out = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    x = 0
    for i, tile in enumerate(tiles):
        if tile.height != height:
            raise SystemExit("tile height mismatch in strip row")
        out.paste(tile, (x, 0))
        x += tile.width + (gap if i < len(tiles) - 1 else 0)
    return out


def concat_vertical(rows: list[Image.Image], *, gap: int = 0) -> Image.Image:
    if not rows:
        raise SystemExit("concat_vertical requires at least one row")
    width = max(r.width for r in rows)
    height = sum(r.height for r in rows) + gap * max(0, len(rows) - 1)
    out = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    y = 0
    for i, row in enumerate(rows):
        out.paste(row, (0, y))
        y += row.height + (gap if i < len(rows) - 1 else 0)
    return out


def crop_strip_row(
    terrain_dir: Path,
    candidate_dir: Path,
    crop: str,
    *,
    letter_by_id: dict[str, dict[str, str]],
    scale: int,
) -> Image.Image:
    tiles: list[Image.Image] = []
    for stem in REFERENCE_STEMS:
        tiles.append(upscale_nearest(load_rgba(terrain_dir / f"tile_plains_{stem}.png"), scale))
    for letter in LETTERS:
        variant = letter_by_id[crop][letter]
        path = candidate_dir / f"tile_plains_{crop}_{variant}.png"
        tiles.append(upscale_nearest(load_rgba(path), scale))
    tiles.append(
        upscale_nearest(load_rgba(terrain_dir / f"tile_plains_{crop}.png"), scale),
    )
    return concat_horizontal(tiles)


def write_candidate_notes(
    out_dir: Path,
    candidate_dir: Path,
    terrain_dir: Path,
    *,
    paint_mod,
) -> None:
    means_path = candidate_dir / "CANDIDATE_MEANS.json"
    data = json.loads(means_path.read_text(encoding="utf-8"))
    field_means = data["field_mask_means"]
    lines = [
        "# Plantation field-gradient candidates (Refs #3961)",
        "",
        "Row order per strip: grain | meat | horses | tobacco | A | B | C | CURRENT.",
        "",
    ]
    for crop in RETUNE_CROPS:
        lines.append(f"## {crop}")
        lines.append("")
        lines.append("| ID | Variant | Field-mask mean RGB |")
        lines.append("|----|---------|---------------------|")
        for letter in LETTERS:
            variant = paint_mod.LETTER_BY_ID[crop][letter]
            rgb = field_means[crop][variant]
            lines.append(f"| **{letter}** | `{variant}` | `({rgb[0]}, {rgb[1]}, {rgb[2]})` |")
        current = paint_mod.field_mask_mean_rgb(
            load_rgba(terrain_dir / f"tile_plains_{crop}.png"),
            mask_from=load_rgba(REPO / "pytool/assets/terrain/tile_plains_plantation_base.png"),
        )
        lines.append(f"| CURRENT | shipped | `({current[0]}, {current[1]}, {current[2]})` |")
        lines.append("")
    (out_dir / "CANDIDATE_NOTES.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def render_strips(
    terrain_dir: Path,
    candidate_dir: Path,
    out_dir: Path,
    *,
    scale: int = SCALE,
) -> list[Path]:
    paint = _load_paint_module()
    out_dir.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    rows: list[Image.Image] = []
    for crop in RETUNE_CROPS:
        row = crop_strip_row(
            terrain_dir,
            candidate_dir,
            crop,
            letter_by_id=paint.LETTER_BY_ID,
            scale=scale,
        )
        rows.append(row)
        path = out_dir / f"strip_{crop}_x{scale}.png"
        row.save(path, optimize=True)
        written.append(path)
        print(f"wrote {path}")
        for letter in LETTERS:
            # Variant ids already include the letter (e.g. A_sage_olive).
            variant = paint.LETTER_BY_ID[crop][letter]
            single = upscale_nearest(
                load_rgba(candidate_dir / f"tile_plains_{crop}_{variant}.png"),
                scale,
            )
            single_path = out_dir / f"{crop}_{variant}_x{scale}.png"
            single.save(single_path, optimize=True)
            written.append(single_path)
    overview = concat_vertical(rows, gap=ROW_GAP_PX * scale // SCALE)
    overview_path = out_dir / f"strip_all_crops_x{scale}.png"
    overview.save(overview_path, optimize=True)
    written.append(overview_path)
    print(f"wrote {overview_path}")
    write_candidate_notes(out_dir, candidate_dir, terrain_dir, paint_mod=paint)
    print(f"wrote {out_dir / 'CANDIDATE_NOTES.md'}")
    return written


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--candidate-dir",
        type=Path,
        default=DEFAULT_CANDIDATES,
    )
    parser.add_argument(
        "--terrain-dir",
        type=Path,
        default=REPO / "app/assets/images/terrain",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=REPO / "tmp/plantation_po_review_strips_3961",
    )
    parser.add_argument(
        "--scale",
        type=int,
        default=SCALE,
        help="Nearest-neighbor upscale factor (default 4)",
    )
    args = parser.parse_args()
    if args.scale < 1:
        raise SystemExit("--scale must be >= 1")
    render_strips(
        args.terrain_dir,
        args.candidate_dir,
        args.out_dir,
        scale=args.scale,
    )


if __name__ == "__main__":
    main()
