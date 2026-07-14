#!/usr/bin/env python3
"""Recolour shared plantation plains base into four resource variants (Refs #3961).

Reads the approved PixelLab plantation base PNG and writes
`tile_plains_{sugar_cane,tobacco,cotton,spices}.png` by recolouring only the
yellow-green field/crop highlight pixels. Buildings, soil, path, and alpha
silhouette are unchanged.

See SPEC/ui/layered-terrain-rendering.md § Plains plantation variants and
SPEC/ui/pytool-image-tools.md.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

# Mid-tone field highlight colours (RGB). Luminance within the crop set is preserved.
FIELD_TARGETS: dict[str, tuple[int, int, int]] = {
    "sugar_cane": (124, 179, 66),
    "tobacco": (128, 108, 42),
    "cotton": (214, 208, 178),
    "spices": (196, 98, 42),
}


def is_field_highlight(r: int, g: int, b: int, a: int) -> bool:
    if a < 16:
        return False
    # Yellow-green field/crop fill from the PixelLab plantation base.
    return g > r + 8 and g > b + 8 and g >= 55 and r >= 40


def luminance(r: int, g: int, b: int) -> float:
    return 0.299 * r + 0.587 * g + 0.114 * b


def recolour_field(
    src: Image.Image,
    target_rgb: tuple[int, int, int],
) -> Image.Image:
    im = src.convert("RGBA")
    px = im.load()
    assert px is not None
    width, height = im.size
    lums = [
        luminance(*px[x, y][:3])
        for y in range(height)
        for x in range(width)
        if is_field_highlight(*px[x, y])
    ]
    if not lums:
        raise SystemExit("no field-highlight pixels found in base image")
    lo, hi = min(lums), max(lums)
    span = max(hi - lo, 1.0)
    tr, tg, tb = target_rgb
    out = im.copy()
    opx = out.load()
    assert opx is not None
    for y in range(height):
        for x in range(width):
            r, g, b, a = px[x, y]
            if not is_field_highlight(r, g, b, a):
                continue
            t = (luminance(r, g, b) - lo) / span
            factor = 0.58 + 0.85 * t
            opx[x, y] = (
                max(0, min(255, int(tr * factor))),
                max(0, min(255, int(tg * factor))),
                max(0, min(255, int(tb * factor))),
                a,
            )
    return out


def main() -> None:
    repo = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--base",
        type=Path,
        default=repo / "pytool/assets/terrain/tile_plains_plantation_base.png",
        help="Approved PixelLab plantation base PNG (64×64, RGBA)",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=repo / "app/assets/images/terrain",
        help="Directory for tile_plains_*.png outputs",
    )
    args = parser.parse_args()
    if not args.base.is_file():
        raise SystemExit(f"base PNG not found: {args.base}")
    src = Image.open(args.base)
    if src.size != (64, 64):
        raise SystemExit(f"expected 64×64 base, got {src.size}")
    args.out_dir.mkdir(parents=True, exist_ok=True)
    base_alpha = [p[3] for p in src.convert("RGBA").get_flattened_data()]
    for stem, rgb in FIELD_TARGETS.items():
        out_path = args.out_dir / f"tile_plains_{stem}.png"
        out = recolour_field(src, rgb)
        out_alpha = [p[3] for p in out.convert("RGBA").get_flattened_data()]
        if out_alpha != base_alpha:
            raise SystemExit(f"alpha silhouette changed for {stem}")
        out.save(out_path, optimize=True)
        print(f"wrote {out_path}")


if __name__ == "__main__":
    main()
