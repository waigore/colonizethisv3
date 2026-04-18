#!/usr/bin/env python3
"""Generate the Wang tileset forced-palette image (8×2 PNG). See SPEC/ui/wang-tileset-and-assets.md."""
from pathlib import Path

from PIL import Image

# 16 colors from SPEC/ui/wang-tileset-and-assets.md § Forced palette
WANG_PALETTE_HEX = [
    "#1e3a5f",  # 0 water_dark
    "#2d5a87",  # 1 water_mid
    "#c4a574",  # 2 sand
    "#7cb342",  # 3 grass_light
    "#558b2f",  # 4 grass_dark
    "#2e7d32",  # 5 forest
    "#1b5e20",  # 6 forest_dark
    "#6d4c41",  # 7 hill
    "#4e342e",  # 8 hill_dark
    "#78909c",  # 9 mountain
    "#546e7a",  # 10 mountain_dark
    "#5d4037",  # 11 swamp
    "#3e2723",  # 12 swamp_dark
    "#d7ccc8",  # 13 desert
    "#5d4037",  # 14 road
    "#ffb74d",  # 15 accent
]


def hex_to_rgb(hex_str: str) -> tuple[int, int, int]:
    h = hex_str.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def main() -> None:
    config_dir = Path(__file__).resolve().parent / "config"
    config_dir.mkdir(parents=True, exist_ok=True)
    out_path = config_dir / "wang_palette.png"

    pixels = [hex_to_rgb(c) for c in WANG_PALETTE_HEX]
    # 8×2 image (16 pixels)
    img = Image.new("RGB", (8, 2))
    for i, rgb in enumerate(pixels):
        img.putpixel((i % 8, i // 8), rgb)
    img.save(out_path)
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
