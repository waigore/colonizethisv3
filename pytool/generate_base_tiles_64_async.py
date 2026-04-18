#!/usr/bin/env python3
"""
Generate 64×64 seamless base terrain tiles via PixelLab POST /generate-image-v2 (async).

Polls GET /background-jobs/{job_id} until completed. Prints status on each poll.

Requires PIXELLAB_API_KEY. Spec: SPEC/ui/tileset/base-tiles-64.md (MCP prompts and REST parity).
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import os
import sys
import time
from pathlib import Path
from typing import Any

import requests
from PIL import Image

API_BASE = "https://api.pixellab.ai/v2"

# Pro async endpoint; 64×64 within limits. Prompts stress seamless wrapping.
TILE_SPECS: dict[str, str] = {
    "plains": (
        "single 64 by 64 pixel art grassland plains ground tile, high top-down orthographic map view, "
        "seamless tileable texture: left edge must match right edge and top edge must match bottom edge "
        "when repeated in a grid, subtle grass and soil variation, no trees rocks buildings units, "
        "colonial era strategy game terrain base only"
    ),
    "sea": (
        "single 64 by 64 pixel art deep sea water surface tile, high top-down orthographic, "
        "seamless tileable: all four edges wrap continuously when tiled, gentle wave pattern, "
        "no land no boats, open ocean fill only, strategy game water base"
    ),
    "desert": (
        "single 64 by 64 pixel art arid desert sand ground tile, high top-down orthographic, "
        "seamless tileable texture with matching edges for grid tiling, fine dune ripples and grit, "
        "no plants structures, strategy game desert terrain base only"
    ),
}


def get_api_key() -> str:
    key = os.environ.get("PIXELLAB_API_KEY")
    if not key or not key.strip():
        print("PIXELLAB_API_KEY is not set", file=sys.stderr)
        sys.exit(1)
    return key.strip()


def submit_job(api_key: str, description: str) -> str:
    url = f"{API_BASE}/generate-image-v2"
    payload = {
        "description": description,
        "image_size": {"width": 64, "height": 64},
        "no_background": False,
    }
    resp = requests.post(
        url,
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        json=payload,
        timeout=120,
    )
    if resp.status_code != 202:
        print(f"generate-image-v2 failed: HTTP {resp.status_code} {resp.text[:800]}", file=sys.stderr)
        sys.exit(1)
    data = resp.json()
    root = data.get("data") if isinstance(data.get("data"), dict) else data
    job_id = (
        root.get("background_job_id")
        or root.get("job_id")
        or data.get("background_job_id")
        or data.get("job_id")
    )
    if not job_id:
        print("No job id in response:", json.dumps(data, indent=2)[:1200], file=sys.stderr)
        sys.exit(1)
    return str(job_id)


def _find_base64_image(obj: Any, depth: int = 0) -> str | None:
    if depth > 12:
        return None
    if isinstance(obj, dict):
        b64 = obj.get("base64")
        if isinstance(b64, str) and len(b64) > 100:
            if "image" in obj or obj.get("format") in ("png", "image/png", None):
                return b64
        for v in obj.values():
            found = _find_base64_image(v, depth + 1)
            if found:
                return found
    elif isinstance(obj, list):
        for item in obj:
            found = _find_base64_image(item, depth + 1)
            if found:
                return found
    return None


def decode_image_bytes_from_completed_job(job_body: dict) -> bytes:
    """Decode image from job; PixelLab may return raw RGBA (width*height*4) or PNG bytes."""
    b64 = _find_base64_image(job_body)
    if not b64:
        print("Could not find image base64 in job payload:", file=sys.stderr)
        print(json.dumps(job_body, indent=2)[:4000], file=sys.stderr)
        sys.exit(1)
    if "," in b64:
        b64 = b64.split(",", 1)[-1]
    raw = base64.standard_b64decode(b64)
    if raw.startswith(b"\x89PNG\r\n\x1a\n"):
        return raw
    if len(raw) == 64 * 64 * 4:
        img = Image.frombytes("RGBA", (64, 64), raw)
        out = io.BytesIO()
        img.save(out, format="PNG")
        return out.getvalue()
    print(f"Unexpected image payload length {len(raw)} (expected PNG or {64*64*4} RGBA)", file=sys.stderr)
    sys.exit(1)


def poll_until_done(
    api_key: str,
    job_id: str,
    *,
    interval_s: float,
    max_attempts: int,
) -> dict:
    for attempt in range(max_attempts):
        r = requests.get(
            f"{API_BASE}/background-jobs/{job_id}",
            headers={"Authorization": f"Bearer {api_key}"},
            timeout=60,
        )
        if r.status_code != 200:
            print(
                f"poll {attempt + 1}/{max_attempts}: GET background-jobs -> HTTP {r.status_code}",
                flush=True,
            )
            time.sleep(interval_s)
            continue
        job = r.json()
        status = job.get("status") or (job.get("data") or {}).get("status") or "unknown"
        print(
            f"poll {attempt + 1}/{max_attempts}: job_id={job_id!r} status={status!r}",
            flush=True,
        )
        if status in ("failed", "error"):
            print("Job failed:", json.dumps(job, indent=2)[:4000], file=sys.stderr)
            sys.exit(1)
        if status == "completed":
            return job
        time.sleep(interval_s)
    print("Timeout waiting for job", job_id, file=sys.stderr)
    sys.exit(1)


def run_one(
    api_key: str,
    name: str,
    description: str,
    out_path: Path,
    interval_s: float,
    max_polls: int,
) -> None:
    print(f"\n=== {name}: submitting generate-image-v2 ===", flush=True)
    job_id = submit_job(api_key, description)
    print(f"submitted job_id={job_id!r}, polling every {interval_s}s ...", flush=True)
    completed = poll_until_done(api_key, job_id, interval_s=interval_s, max_attempts=max_polls)
    png = decode_image_bytes_from_completed_job(completed)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(png)
    print(f"wrote {out_path} ({len(png)} bytes)", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser(description="Async 64×64 base terrain tiles (PixelLab generate-image-v2)")
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=Path("assets/images/terrain/base_64"),
        help="Output directory for PNGs",
    )
    parser.add_argument(
        "--only",
        type=str,
        default="",
        help="Comma-separated subset of: plains,sea,desert",
    )
    parser.add_argument("--poll-interval", type=float, default=12.0, help="Seconds between status polls")
    parser.add_argument("--max-polls", type=int, default=120, help="Max polls per job (~24 min at 12s)")
    args = parser.parse_args()

    api_key = get_api_key()
    only = {s.strip() for s in args.only.split(",") if s.strip()} if args.only else set()

    for name, description in TILE_SPECS.items():
        if only and name not in only:
            continue
        out = args.out_dir / f"{name}_base_64.png"
        run_one(api_key, name, description, out, args.poll_interval, args.max_polls)

    print("\nDone.", flush=True)


if __name__ == "__main__":
    main()
