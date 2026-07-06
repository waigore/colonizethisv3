#!/usr/bin/env python3
"""Generate S9b level-1 town icon candidates via PixelLab Pixflux (Refs #3870)."""

from __future__ import annotations

import argparse
import base64
import os
import sys
from pathlib import Path

import requests

API_BASE = "https://api.pixellab.ai/v2"
NEGATIVE = (
    "blurry, anti-aliased, smooth gradient, photorealistic, circular background, "
    "text label, modern buildings, tiny distant buildings, "
    "small cluster in center with large empty margins, black lines only, outline only, "
    "wireframe, sprite sheet"
)

BASE_PROMPTS = {
    "euro": (
        "16th century European settlement pixel art, stone and timber houses, steep roofs, "
        "centered on transparent background, fills the icon frame"
    ),
    "colonial": (
        "17th century American colonial settlement pixel art, wooden buildings, "
        "centered on transparent background, fills the icon frame"
    ),
    "tribal": (
        "indigenous American woodland settlement pixel art, longhouses and totems, "
        "centered on transparent background, fills the icon frame"
    ),
}

LEVEL_ONE_APPEND = {
    "euro": (
        ", hamlet with 2-3 simple cottages spread across the full frame, same map scale as "
        "larger towns, no church tower, no spire, low flat roofs only, filled roofs and "
        "walls not outlines"
    ),
    "colonial": (
        ", frontier hamlet with 2-3 log cabins spread across the full frame, same map scale "
        "as larger settlements, no bell tower, no steeple, filled roofs and walls not outlines"
    ),
    "tribal": (
        ", camp with 2-3 lodges spread across the full frame, same map scale as larger "
        "settlements, no totem pole, filled roofs and walls not outlines"
    ),
}


def get_api_key() -> str:
    key = os.environ.get("PIXELLAB_API_KEY", "").strip()
    if not key:
        print("PIXELLAB_API_KEY is not set", file=sys.stderr)
        sys.exit(1)
    return key


def create_pixflux(api_key: str, description: str) -> bytes:
    resp = requests.post(
        f"{API_BASE}/create-image-pixflux",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        json={
            "description": description,
            "negative_description": NEGATIVE,
            "image_size": {"width": 64, "height": 64},
            "no_background": True,
            "text_guidance_scale": 8,
        },
        timeout=180,
    )
    if resp.status_code != 200:
        print(f"Pixflux failed: {resp.status_code} {resp.text[:500]}", file=sys.stderr)
        sys.exit(1)
    data = resp.json()
    img = data.get("image") or data.get("data", {}).get("image")
    b64 = img.get("base64", img) if isinstance(img, dict) else img
    if "," in b64:
        b64 = b64.split(",", 1)[-1]
    return base64.standard_b64decode(b64)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate S9b level-1 town candidates")
    parser.add_argument(
        "--style",
        choices=["euro", "colonial", "tribal", "all"],
        default="all",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=Path("app/assets/icons/64"),
        help="Output directory for candidate PNGs",
    )
    parser.add_argument(
        "--append",
        type=str,
        default="",
        help="Optional extra text appended to the level-1 prompt",
    )
    args = parser.parse_args()

    api_key = get_api_key()
    styles = ["euro", "colonial", "tribal"] if args.style == "all" else [args.style]
    args.out.mkdir(parents=True, exist_ok=True)

    for style in styles:
        description = BASE_PROMPTS[style] + LEVEL_ONE_APPEND[style] + args.append
        png = create_pixflux(api_key, description)
        path = args.out / f"ui_icon_com_town_{style}_1_candidate_64.png"
        path.write_bytes(png)
        print(f"wrote {path} ({len(png)} bytes)")


if __name__ == "__main__":
    main()
