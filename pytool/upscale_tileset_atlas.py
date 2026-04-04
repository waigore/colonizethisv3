#!/usr/bin/env python3
"""Upscale a PixelLab-style Wang atlas PNG + JSON by integer scale (nearest-neighbor)."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def _scale_bb(bb: dict, scale: int) -> None:
    for k in ("x", "y", "width", "height"):
        bb[k] = int(bb[k]) * scale


def upscale_tileset_json(data: dict, scale: int) -> None:
    if scale < 1:
        raise ValueError("scale must be >= 1")

    td = data.get("tileset_data")
    if not isinstance(td, dict):
        raise ValueError("missing tileset_data")
    tiles = td.get("tiles")
    if not isinstance(tiles, list):
        raise ValueError("missing tileset_data.tiles")

    for t in tiles:
        if isinstance(t, dict) and isinstance(t.get("bounding_box"), dict):
            _scale_bb(t["bounding_box"], scale)

    for key in ("tile_size",):
        if key in data and isinstance(data[key], dict):
            data[key]["width"] = int(data[key]["width"]) * scale
            data[key]["height"] = int(data[key]["height"]) * scale
        if key in td and isinstance(td[key], dict):
            td[key]["width"] = int(td[key]["width"]) * scale
            td[key]["height"] = int(td[key]["height"]) * scale

    ti = data.get("tileset_image")
    if isinstance(ti, dict) and isinstance(ti.get("dimensions"), dict):
        d = ti["dimensions"]
        d["width"] = int(d["width"]) * scale
        d["height"] = int(d["height"]) * scale


def main() -> None:
    p = argparse.ArgumentParser(description="Upscale Wang tileset atlas (nearest neighbor) + JSON")
    p.add_argument("--in-png", type=Path, required=True)
    p.add_argument("--in-json", type=Path, required=True)
    p.add_argument("--scale", type=int, default=2)
    p.add_argument("--out-png", type=Path, required=True)
    p.add_argument("--out-json", type=Path, required=True)
    args = p.parse_args()

    if args.scale < 1:
        print("scale must be >= 1", file=sys.stderr)
        sys.exit(1)

    try:
        from PIL import Image
    except ImportError:
        print("PIL (Pillow) required", file=sys.stderr)
        sys.exit(1)

    data = json.loads(args.in_json.read_text(encoding="utf-8"))
    upscale_tileset_json(data, args.scale)

    im = Image.open(args.in_png).convert("RGBA")
    w, h = im.size
    im2 = im.resize((w * args.scale, h * args.scale), Image.Resampling.NEAREST)

    args.out_png.parent.mkdir(parents=True, exist_ok=True)
    args.out_json.parent.mkdir(parents=True, exist_ok=True)
    im2.save(args.out_png)
    args.out_json.write_text(json.dumps(data, indent=2), encoding="utf-8")
    print(f"wrote {args.out_png} ({im2.size[0]}×{im2.size[1]})\nwrote {args.out_json}")


if __name__ == "__main__":
    main()
