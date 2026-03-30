#!/usr/bin/env python3
"""
PoC: async inpaint for 128×64 plains|sea composite via PixelLab POST /inpaint-v3.

Submits a background job, polls GET /background-jobs/{job_id} until completed (no max idling —
uses --max-polls with periodic sleep). Saves full strip and optional 64×64 crops.

Requires PIXELLAB_API_KEY. Spec: SPEC/ui/tileset/plains-sea-wang-inpaint-64.md, SPEC/ui/tileset/base-tiles-64.md (archived).
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

DEFAULT_DESCRIPTION = (
    "pixel art beach shoreline wet sand shallow water sea foam blending grassland plains on the "
    "left into open deep ocean on the right high top-down orthographic colonial strategy map "
    "terrain no buildings no units"
)


def get_api_key() -> str:
    key = os.environ.get("PIXELLAB_API_KEY")
    if not key or not key.strip():
        print("PIXELLAB_API_KEY is not set", file=sys.stderr)
        sys.exit(1)
    return key.strip()


def png_file_to_b64_field(path: Path) -> dict[str, str]:
    raw = path.read_bytes()
    return {
        "type": "base64",
        "base64": base64.standard_b64encode(raw).decode("ascii"),
        "format": "png",
    }


def submit_inpaint_v3(
    api_key: str,
    *,
    description: str,
    composite_path: Path,
    mask_path: Path,
    width: int,
    height: int,
    crop_to_mask: bool,
) -> str:
    url = f"{API_BASE}/inpaint-v3"
    payload: dict[str, Any] = {
        "description": description,
        "inpainting_image": {
            "image": png_file_to_b64_field(composite_path),
            "size": {"width": width, "height": height},
        },
        "mask_image": {
            "image": png_file_to_b64_field(mask_path),
            "size": {"width": width, "height": height},
        },
        "no_background": False,
        "crop_to_mask": crop_to_mask,
    }
    resp = requests.post(
        url,
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        json=payload,
        timeout=120,
    )
    if resp.status_code != 202:
        print(f"inpaint-v3 failed: HTTP {resp.status_code} {resp.text[:2000]}", file=sys.stderr)
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


def decode_result_png(
    job_body: dict,
    *,
    width: int,
    height: int,
) -> bytes:
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
    expected = width * height * 4
    if len(raw) == expected:
        img = Image.frombytes("RGBA", (width, height), raw)
        out = io.BytesIO()
        img.save(out, format="PNG")
        return out.getvalue()
    print(
        f"Unexpected image payload length {len(raw)} (expected PNG or {expected} RGBA)",
        file=sys.stderr,
    )
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


def main() -> None:
    parser = argparse.ArgumentParser(description="Async inpaint-v3 for plains|sea 128×64 composite (PoC)")
    repo = Path(__file__).resolve().parent.parent
    default_poc = repo / "app/assets/images/terrain/base_64/_poc_inpaint"
    parser.add_argument(
        "--composite",
        type=Path,
        default=default_poc / "composite_plains_left_sea_right_128x64.png",
        help="128×64 RGBA composite (plains left, sea right)",
    )
    parser.add_argument(
        "--mask",
        type=Path,
        default=default_poc / "mask_seam_band_128x64.png",
        help="Grayscale mask; white = inpaint",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=default_poc / "inpainted_plains_sea_128x64.png",
        help="Output PNG (full strip)",
    )
    parser.add_argument("--description", type=str, default=DEFAULT_DESCRIPTION)
    parser.add_argument(
        "--poll-interval",
        type=float,
        default=8.0,
        help="Seconds between polls (continuous until done or max-polls)",
    )
    parser.add_argument(
        "--max-polls",
        type=int,
        default=200,
        help="Max poll attempts (~26 min at 8s)",
    )
    parser.add_argument(
        "--crop-to-mask",
        action="store_true",
        help="Pass crop_to_mask=true to API (may change output dimensions)",
    )
    parser.add_argument(
        "--split",
        action="store_true",
        help="Also write plains_half_64.png and sea_half_64.png from output",
    )
    args = parser.parse_args()

    comp = Image.open(args.composite)
    w, h = comp.size
    comp.close()
    mask_img = Image.open(args.mask)
    mw, mh = mask_img.size
    mask_img.close()
    if (w, h) != (mw, mh):
        print(f"Composite {w}×{h} and mask {mw}×{mh} must match", file=sys.stderr)
        sys.exit(1)

    api_key = get_api_key()
    print(f"Submitting inpaint-v3 ({w}×{h}) ...", flush=True)
    job_id = submit_inpaint_v3(
        api_key,
        description=args.description,
        composite_path=args.composite.resolve(),
        mask_path=args.mask.resolve(),
        width=w,
        height=h,
        crop_to_mask=args.crop_to_mask,
    )
    print(f"job_id={job_id!r}, polling every {args.poll_interval}s ...", flush=True)
    completed = poll_until_done(
        api_key,
        job_id,
        interval_s=args.poll_interval,
        max_attempts=args.max_polls,
    )
    png = decode_result_png(completed, width=w, height=h)
    out_path = args.out.resolve()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(png)
    print(f"wrote {out_path} ({len(png)} bytes)", flush=True)

    if args.split:
        img = Image.open(io.BytesIO(png)).convert("RGBA")
        half = w // 2
        if half != 64:
            print("--split expects width 128 (two 64px halves)", file=sys.stderr)
            sys.exit(1)
        left = img.crop((0, 0, half, h))
        right = img.crop((half, 0, w, h))
        left_path = out_path.parent / "inpainted_plains_half_64.png"
        right_path = out_path.parent / "inpainted_sea_half_64.png"
        left.save(left_path)
        right.save(right_path)
        print(f"wrote {left_path} and {right_path}", flush=True)

    print("Done.", flush=True)


if __name__ == "__main__":
    main()
