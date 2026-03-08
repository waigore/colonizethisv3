#!/usr/bin/env python3
"""
Layer 3: Generate improvement overlay sprites (roads + optional extraction) via PixelLab API.
Roads: 16 connectivity patterns; center-band constraint for tile alignment.
Writes 3_improvements/tiles/ + manifest.json. Requires PIXELLAB_API_KEY.
See SPEC/ui/wang-tileset-and-assets.md.
"""
import argparse
import base64
import json
import os
import sys
from pathlib import Path

import requests

API_BASE = "https://api.pixellab.ai/v2"

ROAD_PATTERNS = [
    "none",
    "N", "S", "E", "W",
    "NS", "EW", "NE", "ES", "SW", "WN",
    "NSE", "SEW", "EWN", "WNS",
    "NSEW",
]


def get_api_key() -> str:
    key = os.environ.get("PIXELLAB_API_KEY")
    if not key or not key.strip():
        print("PIXELLAB_API_KEY is not set", file=sys.stderr)
        sys.exit(1)
    return key.strip()


def load_palette_base64(palette_path: Path) -> str:
    data = palette_path.read_bytes()
    return base64.standard_b64encode(data).decode("ascii")


def create_image_pixflux(
    api_key: str,
    *,
    description: str,
    width: int,
    height: int,
    color_image_b64: str | None = None,
    no_background: bool = True,
) -> bytes:
    """POST create-image-pixflux; returns PNG bytes."""
    url = f"{API_BASE}/create-image-pixflux"
    payload = {
        "description": description,
        "image_size": {"width": width, "height": height},
        "no_background": no_background,
    }
    if color_image_b64:
        payload["color_image"] = {"type": "base64", "base64": f"data:image/png;base64,{color_image_b64}"}
    resp = requests.post(
        url,
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        json=payload,
        timeout=120,
    )
    if resp.status_code != 200:
        print(f"Create image failed: {resp.status_code} {resp.text}", file=sys.stderr)
        sys.exit(1)
    data = resp.json()
    img_data = data.get("image") or data.get("data", {}).get("image")
    if not img_data:
        print("No image in response", data.keys(), file=sys.stderr)
        sys.exit(1)
    b64 = img_data.get("base64", img_data) if isinstance(img_data, dict) else img_data
    if isinstance(b64, str) and "," in b64:
        b64 = b64.split(",", 1)[-1]
    return base64.standard_b64decode(b64)


def main() -> None:
    parser = argparse.ArgumentParser(description="Layer 3: Generate improvement overlays (roads + extraction)")
    parser.add_argument("--out", type=Path, default=Path("out/3_improvements"), help="Output dir")
    parser.add_argument("--palette", type=Path, default=Path("pytool/config/wang_palette.png"), help="Palette PNG")
    parser.add_argument("--api-base", type=str, default=API_BASE, help="PixelLab API base URL")
    args = parser.parse_args()

    api_key = get_api_key()
    palette_b64 = None
    if args.palette.is_file():
        palette_b64 = load_palette_base64(args.palette)

    out_dir = args.out
    tiles_dir = out_dir / "tiles"
    tiles_dir.mkdir(parents=True, exist_ok=True)
    manifest = {}

    for pattern in ROAD_PATTERNS:
        if pattern == "none":
            desc = "pixel art top-down empty tile, no road, 64x64, strategy game map, transparent center"
        else:
            dirs = ", ".join(pattern)
            desc = f"pixel art top-down road segment, gravel path, only in center of tile, 64x64, strategy game map, directions: {dirs}"
        tile_id = f"road_{pattern}"
        png_bytes = create_image_pixflux(
            api_key,
            description=desc,
            width=64,
            height=64,
            color_image_b64=palette_b64,
            no_background=True,
        )
        path = tiles_dir / f"{tile_id}.png"
        path.write_bytes(png_bytes)
        manifest[tile_id] = {"path": f"tiles/{tile_id}.png", "w": 64, "h": 64}
        print(f"  {tile_id}")

    # Optional: extraction icon
    extraction_desc = "pixel art mine extraction icon, top-down, strategy game"
    png_bytes = create_image_pixflux(
        api_key,
        description=extraction_desc,
        width=48,
        height=48,
        color_image_b64=palette_b64,
        no_background=True,
    )
    path = tiles_dir / "extraction_1.png"
    path.write_bytes(png_bytes)
    manifest["extraction_1"] = {"path": "tiles/extraction_1.png", "w": 48, "h": 48}
    print("  extraction_1")

    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print(f"Wrote {len(manifest)} improvement sprites and manifest to {out_dir}")


if __name__ == "__main__":
    main()
