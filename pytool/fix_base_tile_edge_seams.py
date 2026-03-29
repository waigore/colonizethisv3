#!/usr/bin/env python3
"""
Extrapolate 1px edge rows/columns from the adjacent interior line (PIL).

Useful when a generated tile has a bad outer row or column (e.g. black) on one or more sides.
Spec: SPEC/ui/tileset/base-tiles-64.md.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image


def extrapolate_tile_edges(
    img: Image.Image,
    *,
    north: bool,
    south: bool,
    east: bool,
    west: bool,
) -> Image.Image:
    """RGBA copy; each selected outer line copies from its immediate inward neighbor."""
    out = img.convert("RGBA").copy()
    w, h = out.size
    if w < 2 or h < 2:
        return out
    px = out.load()
    if north:
        for x in range(w):
            px[x, 0] = px[x, 1]
    if south:
        for x in range(w):
            px[x, h - 1] = px[x, h - 2]
    if west:
        for y in range(h):
            px[0, y] = px[1, y]
    if east:
        for y in range(h):
            px[w - 1, y] = px[w - 2, y]
    return out


def parse_edges(s: str) -> tuple[bool, bool, bool, bool]:
    parts = {p.strip().lower() for p in s.split(",") if p.strip()}
    valid = {"north", "south", "east", "west"}
    bad = parts - valid
    if bad:
        print(f"Unknown edge(s): {bad}; use comma-separated from {sorted(valid)}", file=sys.stderr)
        sys.exit(1)
    return (
        "north" in parts,
        "south" in parts,
        "east" in parts,
        "west" in parts,
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Copy interior neighbor pixels onto selected outer edges (fix 1px seams).",
    )
    parser.add_argument(
        "image",
        type=Path,
        help="Input PNG (or any format Pillow opens)",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="Write here (required unless --in-place)",
    )
    parser.add_argument(
        "--in-place",
        action="store_true",
        help="Overwrite input file",
    )
    parser.add_argument(
        "--edges",
        type=str,
        default="south,east",
        help="Comma-separated: north,south,east,west (default: south,east)",
    )
    args = parser.parse_args()
    if not args.in_place and args.output is None:
        print("Specify --output PATH or --in-place", file=sys.stderr)
        sys.exit(1)
    if args.in_place and args.output is not None:
        print("Use only one of --in-place or --output", file=sys.stderr)
        sys.exit(1)

    path = args.image.resolve()
    if not path.is_file():
        print(f"Not a file: {path}", file=sys.stderr)
        sys.exit(1)

    n, s, e, w = parse_edges(args.edges)
    if not (n or s or e or w):
        print("At least one edge required in --edges", file=sys.stderr)
        sys.exit(1)

    src = Image.open(path)
    fixed = extrapolate_tile_edges(src, north=n, south=s, east=e, west=w)
    out_path = path if args.in_place else args.output.resolve()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fixed.save(out_path, format="PNG")
    print(f"Wrote {out_path} (edges={args.edges})", flush=True)


if __name__ == "__main__":
    main()
