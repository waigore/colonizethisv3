#!/usr/bin/env python3
"""
Layer 2: Generate resource overlay sprites via PixelLab API.
Writes 2_resources/tiles/ + manifest.json. Requires PIXELLAB_API_KEY.
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

RESOURCE_PROMPTS = {
    "grain": "pixel art grain wheat icon, top-down view, strategy game resource",
    "meat": "pixel art meat livestock icon, top-down view, strategy game resource",
    "wool": "pixel art wool sheep icon, top-down view, strategy game resource",
    "horses": "pixel art horses icon, top-down view, strategy game resource",
    "timber": "pixel art wood timber icon, top-down view, strategy game resource",
    "iron": "pixel art iron ore icon, top-down view, strategy game resource",
    "copper": "pixel art copper ore icon, top-down view, strategy game resource",
    "tin": "pixel art tin ore icon, top-down view, strategy game resource",
    "coal": "pixel art coal mineral icon, top-down view, strategy game resource",
    "sugarCane": "pixel art sugar cane icon, top-down view, strategy game resource",
    "tobacco": "pixel art tobacco plant icon, top-down view, strategy game resource",
    "cotton": "pixel art cotton plant icon, top-down view, strategy game resource",
    "furs": "pixel art furs pelts icon, top-down view, strategy game resource",
    "spices": "pixel art spices icon, top-down view, strategy game resource",
    "silver": "pixel art silver ore icon, top-down view, strategy game resource",
    "gold": "pixel art gold ore icon, top-down view, strategy game resource",
    "gems": "pixel art gems precious stones icon, top-down view, strategy game resource",
    "diamonds": "pixel art diamonds icon, top-down view, strategy game resource",
}


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
    """POST create-image-pixflux (v2) or generate-image-pixflux (v1); returns PNG bytes."""
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
    if "," in b64:
        b64 = b64.split(",", 1)[-1]
    return base64.standard_b64decode(b64)


def main() -> None:
    parser = argparse.ArgumentParser(description="Layer 2: Generate resource overlay sprites")
    parser.add_argument("--out", type=Path, default=Path("out/2_resources"), help="Output dir")
    parser.add_argument("--palette", type=Path, default=Path("pytool/config/wang_palette.png"), help="Palette PNG")
    parser.add_argument("--size", type=int, default=48, choices=[32, 48], help="Sprite size (32 or 48)")
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
    size = args.size
    for resource_id, description in RESOURCE_PROMPTS.items():
        png_bytes = create_image_pixflux(
            api_key,
            description=description,
            width=size,
            height=size,
            color_image_b64=palette_b64,
            no_background=True,
        )
        path = tiles_dir / f"{resource_id}.png"
        path.write_bytes(png_bytes)
        manifest[resource_id] = {"path": f"tiles/{resource_id}.png", "w": size, "h": size}
        print(f"  {resource_id}")
    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print(f"Wrote {len(manifest)} resource sprites and manifest to {out_dir}")


if __name__ == "__main__":
    main()
