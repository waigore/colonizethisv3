#!/usr/bin/env python3
"""Generate 64x64 colonial-era fort map icons (levels 1–3). Refs #4280."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

OUT_DIR = Path(__file__).resolve().parents[1] / "app" / "assets" / "icons" / "64"
OUTLINE = (20, 16, 12, 255)
WOOD = (139, 90, 43, 255)
WOOD_DARK = (101, 67, 33, 255)
STONE = (140, 140, 150, 255)
STONE_DARK = (90, 90, 100, 255)
STONE_LIGHT = (180, 180, 190, 255)
FLAG = (180, 40, 40, 255)


def _outline_rect(draw: ImageDraw.ImageDraw, xy, fill, width: int = 1) -> None:
    draw.rectangle(xy, fill=fill, outline=OUTLINE, width=width)


def draw_fort_1(img: Image.Image) -> None:
    draw = ImageDraw.Draw(img)
    # Simple wooden palisade blockhouse.
    _outline_rect(draw, (14, 28, 50, 54), WOOD)
    for x in range(16, 49, 4):
        draw.line((x, 28, x, 54), fill=WOOD_DARK, width=1)
    _outline_rect(draw, (24, 16, 40, 30), WOOD_DARK)
    draw.polygon([(28, 16), (36, 10), (44, 16)], fill=WOOD)
    draw.line((28, 16, 44, 16), fill=OUTLINE, width=1)
    draw.rectangle((30, 38, 34, 54), fill=STONE_DARK, outline=OUTLINE)


def draw_fort_2(img: Image.Image) -> None:
    draw = ImageDraw.Draw(img)
    # Stone walls with corner tower and gate.
    _outline_rect(draw, (10, 34, 54, 56), STONE)
    for x in range(12, 53, 6):
        draw.line((x, 34, x, 56), fill=STONE_DARK, width=1)
    _outline_rect(draw, (42, 18, 56, 40), STONE_LIGHT)
    _outline_rect(draw, (44, 20, 54, 26), STONE_DARK)
    draw.rectangle((46, 28, 52, 36), fill=STONE_DARK, outline=OUTLINE)
    draw.polygon([(42, 18), (49, 12), (56, 18)], fill=STONE_LIGHT, outline=OUTLINE)
    draw.rectangle((22, 40, 32, 56), fill=(30, 30, 35, 255), outline=OUTLINE)
    draw.line((10, 42, 54, 42), fill=STONE_DARK, width=2)


def draw_fort_3(img: Image.Image) -> None:
    draw = ImageDraw.Draw(img)
    # Star-fort bastions — heaviest silhouette.
    base = [
        (32, 8),
        (48, 18),
        (58, 32),
        (48, 48),
        (32, 56),
        (16, 48),
        (6, 32),
        (16, 18),
    ]
    draw.polygon(base, fill=STONE, outline=OUTLINE)
    inner = [
        (32, 18),
        (42, 24),
        (48, 32),
        (42, 40),
        (32, 44),
        (22, 40),
        (16, 32),
        (22, 24),
    ]
    draw.polygon(inner, fill=STONE_LIGHT, outline=OUTLINE)
    for bx, by in ((10, 30), (54, 30), (32, 52)):
        draw.ellipse((bx - 4, by - 4, bx + 4, by + 4), fill=STONE_DARK, outline=OUTLINE)
    draw.rectangle((28, 30, 36, 40), fill=(25, 25, 30, 255), outline=OUTLINE)
    draw.line((32, 18, 32, 12), fill=OUTLINE, width=1)
    draw.polygon([(30, 12), (32, 6), (34, 12)], fill=FLAG, outline=OUTLINE)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    drawers = {1: draw_fort_1, 2: draw_fort_2, 3: draw_fort_3}
    for level, drawer in drawers.items():
        img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        drawer(img)
        path = OUT_DIR / f"ui_icon_com_fort_{level}_64.png"
        img.save(path)
        print(f"wrote {path}")


if __name__ == "__main__":
    main()
