#!/usr/bin/env python3
"""Build a 48×48 nine-patch PNG from a wide button PNG (e.g. ui_main_menu_button.png).

Flame's NineTileBoxWidget expects a square image with a 3×3 grid; tile_size is the
width/height of each cell (e.g. 16 → 48×48 image). This script slices the source
into left/middle/right columns and top/middle/bottom rows and assembles them.

Usage:
  python pytool/button_nine_patch_slice.py <input.png> <output.png> [tile_size]

Example:
  python pytool/button_nine_patch_slice.py app/assets/images/ui_main_menu_button.png app/assets/images/ui_button_nine_patch.png 16

See SPEC/ui/buttons-nine-patch.md.
"""
import sys
from pathlib import Path

from PIL import Image

DEFAULT_TILE_SIZE = 16


def main() -> None:
    if len(sys.argv) < 3:
        print(
            "Usage: button_nine_patch_slice.py <input.png> <output.png> [tile_size]",
            file=sys.stderr,
        )
        sys.exit(1)
    inp = Path(sys.argv[1])
    out = Path(sys.argv[2])
    tile_size = int(sys.argv[3]) if len(sys.argv) > 3 else DEFAULT_TILE_SIZE

    img = Image.open(inp).convert("RGBA")
    w, h = img.size

    if w < tile_size * 3 or h < tile_size:
        print(
            f"logic: image {w}×{h} too small for tile_size {tile_size} (need width >= {tile_size * 3}, height >= {tile_size})",
            file=sys.stderr,
        )
        sys.exit(1)

    # Source columns: left [0 : tile_size], middle [center - tile_size/2 : center + tile_size/2], right [w - tile_size : w]
    mid_start = (w - tile_size) // 2
    left = (0, tile_size)
    mid = (mid_start, mid_start + tile_size)
    right = (w - tile_size, w)

    # Source rows: top [0 : tile_size], middle [tile_size : 2*tile_size], bottom [h - tile_size : h]
    # If source height is exactly tile_size, use same row for all three.
    if h >= tile_size * 3:
        row_top = (0, tile_size)
        row_mid = (tile_size, tile_size * 2)
        row_bot = (h - tile_size, h)
    else:
        # e.g. 48px tall: use 0:16, 16:32, 32:48
        row_top = (0, tile_size)
        row_mid = (tile_size, min(tile_size * 2, h))
        row_bot = (max(0, h - tile_size), h)

    out_img = Image.new("RGBA", (tile_size * 3, tile_size * 3))

    for row_idx, (sy_lo, sy_hi) in enumerate([row_top, row_mid, row_bot]):
        for col_idx, (sx_lo, sx_hi) in enumerate([left, mid, right]):
            cell = img.crop((sx_lo, sy_lo, sx_hi, sy_hi))
            # Cell might be smaller than tile_size if source was narrow/short; paste into full tile
            if cell.size == (tile_size, tile_size):
                out_img.paste(cell, (col_idx * tile_size, row_idx * tile_size))
            else:
                # Stretch to tile_size × tile_size
                cell = cell.resize((tile_size, tile_size), Image.Resampling.NEAREST)
                out_img.paste(cell, (col_idx * tile_size, row_idx * tile_size))

    out.parent.mkdir(parents=True, exist_ok=True)
    out_img.save(out, "PNG")
    print(f"Saved {out} ({tile_size * 3}×{tile_size * 3}, tile_size={tile_size})")


if __name__ == "__main__":
    main()
