#!/usr/bin/env python3
"""
Layer 1: Generate base terrain Wang tiles via PixelLab API v2.
Upscales to 64×64 and writes 1_terrain/tiles/ + manifest.json.
Requires PIXELLAB_API_KEY. See SPEC/ui/wang-tileset-and-assets.md.
"""
import argparse
import base64
import io
import json
import os
import sys
import time
from pathlib import Path

import requests
from PIL import Image

API_BASE = "https://api.pixellab.ai/v2"
DEFAULT_SEED = 42
TARGET_SIZE = 64


def get_api_key() -> str:
    key = os.environ.get("PIXELLAB_API_KEY")
    if not key or not key.strip():
        print("PIXELLAB_API_KEY is not set", file=sys.stderr)
        sys.exit(1)
    return key.strip()


def load_palette_base64(palette_path: Path) -> str:
    data = palette_path.read_bytes()
    return base64.standard_b64encode(data).decode("ascii")


def create_tileset(
    api_key: str,
    *,
    lower_description: str,
    upper_description: str,
    transition_description: str = "",
    tile_size: tuple[int, int] = (32, 32),
    view: str = "high top-down",
    transition_size: float = 0.25,
    color_image_b64: str,
    seed: int = DEFAULT_SEED,
) -> tuple[str, str]:
    """POST /tilesets; returns (job_id, tileset_id) from 202 response. Use job_id for polling."""
    url = f"{API_BASE}/tilesets"
    payload = {
        "lower_description": lower_description,
        "upper_description": upper_description,
        "transition_description": transition_description,
        "tile_size": {"width": tile_size[0], "height": tile_size[1]},
        "view": view,
        "transition_size": transition_size,
        "color_image": {"type": "base64", "base64": f"data:image/png;base64,{color_image_b64}"},
        "seed": seed,
    }
    resp = requests.post(
        url,
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        json=payload,
        timeout=60,
    )
    if resp.status_code != 202:
        print(f"Create tileset failed: {resp.status_code} {resp.text}", file=sys.stderr)
        sys.exit(1)
    data = resp.json()
    job_id = data.get("background_job_id") or data.get("job_id") or ""
    tileset_id = data.get("tileset_id") or data.get("data", {}).get("tileset_id") or job_id
    if not job_id:
        job_id = tileset_id
    if not job_id:
        print("No job_id or tileset_id in response", data, file=sys.stderr)
        sys.exit(1)
    return (job_id, tileset_id)


def poll_until_done(api_key: str, job_id: str, tileset_id: str) -> dict:
    """Poll GET /background-jobs/{job_id} for status; when completed, fetch tiles from GET /tilesets/{tileset_id}. Returns result dict with tiles/images."""
    # API: GET /tilesets/{id} returns 423 while processing; GET /background-jobs/{id} returns 200 with status "processing" | "completed" | "failed" | "error"
    max_attempts = 120  # ~10 min at 5s
    hang_after_attempts = 24   # ~2 min of "processing" with no change → suggest job may be hung
    last_status = None
    for attempt in range(max_attempts):
        r = requests.get(
            f"{API_BASE}/background-jobs/{job_id}",
            headers={"Authorization": f"Bearer {api_key}"},
            timeout=30,
        )
        if r.status_code != 200:
            print(f"Poll {attempt + 1}/{max_attempts}: background-jobs -> HTTP {r.status_code}", flush=True)
            time.sleep(5)
            continue
        job = r.json()
        status = job.get("status") or job.get("data", {}).get("status") or "unknown"
        print(f"Poll {attempt + 1}/{max_attempts}: status={status!r}", flush=True)
        last_status = status

        if status in ("failed", "error"):
            print("Tileset job failed:", job, file=sys.stderr)
            sys.exit(1)
        if status == "completed":
            # Tile images come from GET /tilesets/{tileset_id}; job body may or may not include them
            result = job.get("data") or job
            if result.get("tiles") or result.get("images") or (result.get("data") or {}).get("tiles"):
                return result
            r2 = requests.get(
                f"{API_BASE}/tilesets/{tileset_id}",
                headers={"Authorization": f"Bearer {api_key}"},
                timeout=30,
            )
            if r2.status_code == 200:
                return r2.json()
            if r2.status_code == 423:
                print("Job completed but tilesets still locked; retrying in 5s...", flush=True)
                time.sleep(5)
                continue
            print(f"Tileset fetch failed: {r2.status_code} {r2.text[:200]}", file=sys.stderr)
            sys.exit(1)

        if status == "processing" and attempt + 1 >= hang_after_attempts and (attempt + 1) % 12 == 0:
            print("Job still processing; if it does not finish soon it may be hung. You can retry later.", flush=True)
        time.sleep(5)
    print("Timeout waiting for tileset (job may be hung). Try again later or check PixelLab dashboard.", file=sys.stderr)
    sys.exit(1)


def extract_tile_images(result: dict) -> list[tuple[str, bytes]]:
    """Return list of (tile_id, png_bytes)."""
    out = []
    data = result.get("data") or result
    tiles = data.get("tiles") or data.get("images") or []
    if isinstance(tiles, dict):
        for tid, img in tiles.items():
            if isinstance(img, dict) and "base64" in img:
                b64 = img["base64"].split(",", 1)[-1] if "," in img["base64"] else img["base64"]
                out.append((tid, base64.standard_b64decode(b64)))
            elif isinstance(img, str):
                out.append((tid, base64.standard_b64decode(img)))
        return out
    for i, img in enumerate(tiles):
        if isinstance(img, dict) and "base64" in img:
            b64 = img["base64"].split(",", 1)[-1] if "," in img["base64"] else img["base64"]
            out.append((f"tile_{i}", base64.standard_b64decode(b64)))
        elif isinstance(img, str):
            out.append((f"tile_{i}", base64.standard_b64decode(img)))
    return out


def upscale_to_64(png_bytes: bytes) -> Image.Image:
    img = Image.open(io.BytesIO(png_bytes)).convert("RGBA")
    return img.resize((TARGET_SIZE, TARGET_SIZE), Image.NEAREST)


def main() -> None:
    global API_BASE
    parser = argparse.ArgumentParser(description="Layer 1: Generate terrain Wang tiles (PixelLab API)")
    parser.add_argument("--out", type=Path, default=Path("out/1_terrain"), help="Output dir (1_terrain)")
    parser.add_argument("--palette", type=Path, default=Path("pytool/config/wang_palette.png"), help="Palette PNG path")
    parser.add_argument("--seed", type=int, default=DEFAULT_SEED, help="Random seed")
    parser.add_argument("--api-base", type=str, default=API_BASE, help="PixelLab API base URL")
    args = parser.parse_args()
    API_BASE = args.api_base.rstrip("/")

    api_key = get_api_key()
    palette_path = args.palette
    if not palette_path.is_file():
        print(f"Palette not found: {palette_path}", file=sys.stderr)
        sys.exit(1)
    color_b64 = load_palette_base64(palette_path)

    job_id, tileset_id = create_tileset(
        api_key,
        lower_description="deep ocean water, top-down view, pixel art strategy game terrain",
        upper_description="grass and earth land, top-down view, pixel art strategy game terrain",
        transition_description="sandy coast, beach, top-down",
        tile_size=(32, 32),
        view="high top-down",
        transition_size=0.25,
        color_image_b64=color_b64,
        seed=args.seed,
    )
    print("Job id:", job_id, "Tileset id:", tileset_id)
    result = poll_until_done(api_key, job_id, tileset_id)
    tiles_data = extract_tile_images(result)
    if not tiles_data:
        print("No tile images in result", result.keys(), file=sys.stderr)
        sys.exit(1)

    out_dir = args.out
    tiles_dir = out_dir / "tiles"
    tiles_dir.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for tile_id, png_bytes in tiles_data:
        img = upscale_to_64(png_bytes)
        safe_id = tile_id.replace("/", "_").replace(" ", "_")
        path = tiles_dir / f"{safe_id}.png"
        img.save(path)
        manifest[tile_id] = f"tiles/{safe_id}.png"
    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print(f"Wrote {len(manifest)} tiles and manifest to {out_dir}")


if __name__ == "__main__":
    main()
