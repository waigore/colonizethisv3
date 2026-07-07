#!/usr/bin/env python3
"""Generate S9b town icon candidates via PixelLab Pixflux (Refs #3870)."""

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

LEVEL_APPEND: dict[str, dict[int, str]] = {
    "euro": {
        1: (
            ", hamlet with 2-3 simple cottages spread across the full frame, same map scale as "
            "larger towns, no church tower, no spire, low flat roofs only, filled roofs and "
            "walls not outlines"
        ),
        2: (
            ", small village with 4 houses and one low church roof, one bell-cote, modest detail, "
            "no tall spire"
        ),
        3: (
            ", walled market town with 6 buildings and one church tower, medium spire, denser "
            "cluster"
        ),
        4: (
            ", grand European city with 8 buildings and two church spires, tallest spire "
            "dominates, dense medieval city cluster"
        ),
    },
    "colonial": {
        1: (
            ", frontier hamlet with 2-3 log cabins spread across the full frame, same map scale "
            "as larger settlements, no bell tower, no steeple, filled roofs and walls not outlines"
        ),
        2: (
            ", village with 4 wooden houses and a small meeting hall, one low roof peak, "
            "no tall steeple"
        ),
        3: (
            ", colonial town with 6 buildings, palisade segment, one church steeple, denser"
        ),
        4: (
            ", large colonial city with 8 buildings, two steeples, grand plaza, tallest steeple "
            "dominates"
        ),
    },
    "tribal": {
        1: (
            ", camp with 2-3 lodges spread across the full frame, same map scale as larger "
            "settlements, no totem pole, filled roofs and walls not outlines"
        ),
        2: (
            ", village with 4 lodges and one small ceremonial structure, modest roof detail, "
            "no tall totem"
        ),
        3: (
            ", tribal town with 6 lodges, one tall totem pole, enclosed gathering area"
        ),
        4: (
            ", large tribal settlement with 8 lodges, two tall totem poles, grand ceremonial "
            "center, tallest totem dominates"
        ),
    },
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
    parser = argparse.ArgumentParser(description="Generate S9b town icon candidates")
    parser.add_argument(
        "--style",
        choices=["euro", "colonial", "tribal", "all"],
        default="all",
    )
    parser.add_argument(
        "--level",
        type=int,
        choices=[1, 2, 3, 4],
        action="append",
        dest="levels",
        help="Development level(s) to generate; repeat for multiple (default: 1)",
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
        help="Optional extra text appended to each prompt",
    )
    args = parser.parse_args()

    levels = args.levels if args.levels else [1]
    api_key = get_api_key()
    styles = ["euro", "colonial", "tribal"] if args.style == "all" else [args.style]
    args.out.mkdir(parents=True, exist_ok=True)

    for style in styles:
        for level in levels:
            description = (
                BASE_PROMPTS[style] + LEVEL_APPEND[style][level] + args.append
            )
            png = create_pixflux(api_key, description)
            path = args.out / f"ui_icon_com_town_{style}_{level}_candidate_64.png"
            path.write_bytes(png)
            print(f"wrote {path} ({len(png)} bytes)")


if __name__ == "__main__":
    main()
