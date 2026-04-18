#!/usr/bin/env python3
"""Process button PNG pixels: higher border/center contrast, more random wood grain.
Reads pixel JSON from stdin or path, writes modified pixels JSON to stdout or out path.
"""
import json
import random
import sys
from pathlib import Path


def hex_to_rgb(hex_str: str) -> tuple[int, int, int, int]:
    h = hex_str.lstrip("#")
    if len(h) == 8:
        r, g, b, a = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), int(h[6:8], 16)
    else:
        r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
        a = 255
    return (r, g, b, a)


def rgb_to_hex(r: int, g: int, b: int, a: int = 255) -> str:
    return f"#{r:02X}{g:02X}{b:02X}{a:02X}"


def luminance(r: int, g: int, b: int) -> float:
    return 0.299 * r + 0.587 * g + 0.114 * b


def clamp(v: int) -> int:
    return max(0, min(255, v))


def is_border(r: int, g: int, b: int) -> bool:
    """Dark reddish-brown border."""
    L = luminance(r, g, b)
    return L < 55 and r > b and r >= 15 and g < 35 and b < 35


def is_center_wood(r: int, g: int, b: int) -> bool:
    """Medium warm brown center."""
    L = luminance(r, g, b)
    return 60 < L < 180 and r > b and r > 60 and g > 30 and g < 180


def is_gold(r: int, g: int, b: int) -> bool:
    """Golden corner accents."""
    L = luminance(r, g, b)
    return L > 180 and r > 180 and g > 140 and b < 150


def process_pixel(px: dict, rng: random.Random) -> dict:
    x, y = px["x"], px["y"]
    color = px["color"]
    r, g, b, a = hex_to_rgb(color)
    if a < 128:
        return {"x": x, "y": y, "color": color}
    L = luminance(r, g, b)
    if is_border(r, g, b):
        # Darken border for more contrast (scale down)
        r, g, b = clamp(int(r * 0.72)), clamp(int(g * 0.72)), clamp(int(b * 0.72))
        return {"x": x, "y": y, "color": rgb_to_hex(r, g, b, a)}
    if is_center_wood(r, g, b):
        # Lighten center slightly and add woody randomness (±6 to R,G,B)
        delta = 12
        r = clamp(r + int(r * 0.08) + rng.randint(-delta, delta))
        g = clamp(g + int(g * 0.06) + rng.randint(-delta, delta))
        b = clamp(b + int(b * 0.04) + rng.randint(-delta, delta))
        return {"x": x, "y": y, "color": rgb_to_hex(r, g, b, a)}
    if is_gold(r, g, b):
        return {"x": x, "y": y, "color": color}
    # Other pixels (e.g. dark outline): slight darken to keep border pop
    if L < 50:
        r, g, b = clamp(int(r * 0.88)), clamp(int(g * 0.88)), clamp(int(b * 0.88))
        return {"x": x, "y": y, "color": rgb_to_hex(r, g, b, a)}
    return {"x": x, "y": y, "color": color}


def main() -> None:
    seed = 42
    rng = random.Random(seed)
    if len(sys.argv) > 1:
        with open(sys.argv[1], "r") as f:
            data = json.load(f)
    else:
        data = json.load(sys.stdin)
    pixels = data.get("pixels", data)
    if isinstance(data, list):
        pixels = data
    out = [process_pixel(px, rng) for px in pixels]
    if len(sys.argv) > 2:
        with open(sys.argv[2], "w") as f:
            json.dump({"pixels": out}, f)
    else:
        json.dump({"pixels": out}, sys.stdout)


if __name__ == "__main__":
    main()
