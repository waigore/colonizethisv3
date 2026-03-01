#!/usr/bin/env python3
"""Apply contrast + wood randomness to button PNG using PIL. Reads PNG, writes new PNG."""
import random
import sys
from pathlib import Path

from PIL import Image


def luminance(r: int, g: int, b: int) -> float:
    return 0.299 * r + 0.587 * g + 0.114 * b


def clamp(v: int) -> int:
    return max(0, min(255, v))


def is_border(r: int, g: int, b: int) -> bool:
    L = luminance(r, g, b)
    return L < 55 and r > b and r >= 15 and g < 35 and b < 35


def is_center_wood(r: int, g: int, b: int) -> bool:
    L = luminance(r, g, b)
    return 60 < L < 180 and r > b and r > 60 and g > 30 and g < 180


def is_gold(r: int, g: int, b: int) -> bool:
    L = luminance(r, g, b)
    return L > 180 and r > 180 and g > 140 and b < 150


def process_pixel(r: int, g: int, b: int, a: int, rng: random.Random) -> tuple[int, int, int, int]:
    if a < 128:
        return (r, g, b, a)
    if is_border(r, g, b):
        r = clamp(int(r * 0.72))
        g = clamp(int(g * 0.72))
        b = clamp(int(b * 0.72))
        return (r, g, b, a)
    if is_center_wood(r, g, b):
        delta = 12
        r = clamp(r + int(r * 0.08) + rng.randint(-delta, delta))
        g = clamp(g + int(g * 0.06) + rng.randint(-delta, delta))
        b = clamp(b + int(b * 0.04) + rng.randint(-delta, delta))
        return (r, g, b, a)
    if is_gold(r, g, b):
        return (r, g, b, a)
    L = luminance(r, g, b)
    if L < 50:
        r = clamp(int(r * 0.88))
        g = clamp(int(g * 0.88))
        b = clamp(int(b * 0.88))
        return (r, g, b, a)
    return (r, g, b, a)


def main() -> None:
    seed = 42
    rng = random.Random(seed)
    if len(sys.argv) < 3:
        print("Usage: button_contrast_wood_pil.py <input.png> <output.png>", file=sys.stderr)
        sys.exit(1)
    inp = Path(sys.argv[1])
    out = Path(sys.argv[2])
    img = Image.open(inp).convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            px[x, y] = process_pixel(r, g, b, a, rng)
    img.save(out, "PNG")
    print("Saved", out)


if __name__ == "__main__":
    main()
