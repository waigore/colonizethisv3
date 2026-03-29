#!/usr/bin/env python3
"""
PoC: one 64×64 Wang-style tile from 16×16 corner anchors + async inpaint-v3.

Separate from generate_sea_plains_wang_inpaint_64.py (contracts / cross / strips).

Corners NW→NE→SW→SE: P = plains crop, S = sea crop from respective base PNGs.
Default pattern PPPS = three plains corners + sea at SE (wang_index 14 per SPEC).

Composite (option A): transparent 64×64, paste four 16×16 anchors only.
Mask: black = keep anchors, white = inpaint (PixelLab convention).

Requires PIXELLAB_API_KEY. Verbatim description: SPEC/ui/tileset/plains-sea-wang-inpaint-64.md § Wang tiles.
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import logging
import os
import sys
import time
from pathlib import Path
from typing import Any

LOG = logging.getLogger("pytool.wang_corner_anchor")


def configure_logging(*, verbose: bool) -> None:
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(levelname)s [%(name)s] %(message)s",
        stream=sys.stderr,
        force=True,
    )

import requests
from PIL import Image, ImageDraw

API_BASE = "https://api.pixellab.ai/v2"

TILE = 64
SUB = 16

VERBATIM_WANG_INPAINT_DESCRIPTION = (
    "pixel art high-detail top-down orthographic strategy map terrain seamlessly extend "
    "grassland plains and open sea from kept corners and edges into the masked region blend "
    "gradually across the boundary over several pixels matching local hue value and grain avoid "
    "abrupt color steps bright rims or sharp cutoffs natural shoreline where land meets sea match "
    "palette texture and pixel-scale detail of kept areas no visible seam "
    "the masked interior is the same tile as the kept frame only continue what arms sixteen-pixel "
    "center bands and anchor corners already show same land versus sea story palette grain and scale "
    "at the mask edge do not invent a different biome lighting or focal theme in the center that "
    "contradicts those pixels"
)

CORNER_NAMES = ("nw", "ne", "sw", "se")
# (left, upper) paste position for each corner's 16×16 anchor
PASTE_POS = {"nw": (0, 0), "ne": (48, 0), "sw": (0, 48), "se": (48, 48)}
# PIL crop box (l, u, r, l) for 16×16 at each corner of a 64×64 base
CROP_BOX = {
    "nw": (0, 0, SUB, SUB),
    "ne": (TILE - SUB, 0, TILE, SUB),
    "sw": (0, TILE - SUB, SUB, TILE),
    "se": (TILE - SUB, TILE - SUB, TILE, TILE),
}


def get_api_key() -> str:
    key = os.environ.get("PIXELLAB_API_KEY")
    if not key or not key.strip():
        LOG.error("PIXELLAB_API_KEY is not set")
        sys.exit(1)
    LOG.debug("API key present (length=%d)", len(key.strip()))
    return key.strip()


def parse_corners(s: str) -> tuple[bool, bool, bool, bool]:
    """Return (nw, ne, sw, se) True=plains, False=sea."""
    t = s.strip().upper()
    if len(t) != 4:
        LOG.error("--corners must be exactly 4 letters (NW NE SW SE order), e.g. PPPS")
        sys.exit(1)
    out: list[bool] = []
    for c in t:
        if c == "P":
            out.append(True)
        elif c == "S":
            out.append(False)
        else:
            LOG.error("Invalid corner char %r; use only P or S", c)
            sys.exit(1)
    return (out[0], out[1], out[2], out[3])


def wang_index(nw: bool, ne: bool, sw: bool, se: bool) -> int:
    """SPEC: true=upper(plains); index = NW*8 + NE*4 + SW*2 + SE."""
    return (8 if nw else 0) | (4 if ne else 0) | (2 if sw else 0) | (1 if se else 0)


def assert_base_size(img: Image.Image, path: Path) -> None:
    if img.size != (TILE, TILE):
        LOG.error(
            "Expected %d×%d base: %s is %d×%d",
            TILE,
            TILE,
            path,
            img.size[0],
            img.size[1],
        )
        sys.exit(1)


def build_composite_and_mask(
    plains: Image.Image,
    sea: Image.Image,
    corners: tuple[bool, bool, bool, bool],
) -> tuple[Image.Image, Image.Image]:
    """RGBA composite + L mask (white=inpaint, black=keep)."""
    LOG.info("build composite: %d×%d transparent base + %d×%d corner anchors", TILE, TILE, SUB, SUB)
    composite = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    mask = Image.new("L", (TILE, TILE), 255)
    draw = ImageDraw.Draw(mask)
    for i, name in enumerate(CORNER_NAMES):
        use_plains = corners[i]
        src = plains if use_plains else sea
        terrain = "plains" if use_plains else "sea"
        crop = src.crop(CROP_BOX[name])
        x, y = PASTE_POS[name]
        LOG.info(
            "  anchor %s: %s crop_box=%s paste=(%d,%d)",
            name,
            terrain,
            CROP_BOX[name],
            x,
            y,
        )
        composite.paste(crop, (x, y))
        # Pillow rectangle includes right and bottom edges: [x,y,x+SUB,y+SUB] is (SUB+1)² px.
        # Use inclusive end at x+SUB-1, y+SUB-1 to match a SUB×SUB paste exactly.
        draw.rectangle([x, y, x + SUB - 1, y + SUB - 1], fill=0)
    hist = mask.histogram()
    kept = hist[0] if hist else 0
    inpaint_px = TILE * TILE - kept
    LOG.info(
        "build mask: L mode white=inpaint black=keep; keep_pixels=%d inpaint_pixels=%d",
        kept,
        inpaint_px,
    )
    return composite, mask


def png_file_to_b64_field(path: Path) -> dict[str, str]:
    raw = path.read_bytes()
    b64 = base64.standard_b64encode(raw).decode("ascii")
    LOG.debug("base64 %s: raw_bytes=%d b64_chars=%d", path.name, len(raw), len(b64))
    return {
        "type": "base64",
        "base64": b64,
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
    LOG.info(
        "inpaint-v3 submit: url=%s size=%d×%d crop_to_mask=%s description_len=%d",
        url,
        width,
        height,
        crop_to_mask,
        len(description),
    )
    LOG.debug("inpaint-v3 composite_path=%s mask_path=%s", composite_path, mask_path)
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
    LOG.debug("POST %s (timeout=120s)", url)
    resp = requests.post(
        url,
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        json=payload,
        timeout=120,
    )
    if resp.status_code != 202:
        LOG.error("inpaint-v3 failed: HTTP %s %s", resp.status_code, resp.text[:2000])
        sys.exit(1)
    data = resp.json()
    LOG.info("inpaint-v3 accepted: HTTP 202")
    root = data.get("data") if isinstance(data.get("data"), dict) else data
    job_id = (
        root.get("background_job_id")
        or root.get("job_id")
        or data.get("background_job_id")
        or data.get("job_id")
    )
    if not job_id:
        LOG.error("No job id in response: %s", json.dumps(data, indent=2)[:1200])
        sys.exit(1)
    LOG.info("background job id=%r", str(job_id))
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


def decode_result_png(job_body: dict, *, width: int, height: int) -> bytes:
    b64 = _find_base64_image(job_body)
    if not b64:
        LOG.error("Could not find image base64 in job payload: %s", json.dumps(job_body, indent=2)[:4000])
        sys.exit(1)
    if "," in b64:
        b64 = b64.split(",", 1)[-1]
    raw = base64.standard_b64decode(b64)
    if raw.startswith(b"\x89PNG\r\n\x1a\n"):
        LOG.info("decode result: PNG wire format, %d bytes", len(raw))
        return raw
    expected = width * height * 4
    if len(raw) == expected:
        LOG.info("decode result: raw RGBA %d bytes -> encode PNG", len(raw))
        img = Image.frombytes("RGBA", (width, height), raw)
        out = io.BytesIO()
        img.save(out, format="PNG")
        png = out.getvalue()
        LOG.debug("encoded PNG size=%d", len(png))
        return png
    LOG.error(
        "Unexpected image payload length %d (expected PNG or %d RGBA)",
        len(raw),
        expected,
    )
    sys.exit(1)


def poll_until_done(
    api_key: str,
    job_id: str,
    *,
    interval_s: float,
    max_attempts: int,
) -> dict:
    LOG.info("poll: job_id=%r interval=%ss max_attempts=%d", job_id, interval_s, max_attempts)
    for attempt in range(max_attempts):
        r = requests.get(
            f"{API_BASE}/background-jobs/{job_id}",
            headers={"Authorization": f"Bearer {api_key}"},
            timeout=60,
        )
        if r.status_code != 200:
            LOG.warning(
                "poll %d/%d: GET background-jobs -> HTTP %s",
                attempt + 1,
                max_attempts,
                r.status_code,
            )
            time.sleep(interval_s)
            continue
        job = r.json()
        status = job.get("status") or (job.get("data") or {}).get("status") or "unknown"
        LOG.info(
            "poll %d/%d: job_id=%r status=%r",
            attempt + 1,
            max_attempts,
            job_id,
            status,
        )
        if status in ("failed", "error"):
            LOG.error("Job failed: %s", json.dumps(job, indent=2)[:4000])
            sys.exit(1)
        if status == "completed":
            LOG.info("job completed after %d poll(s)", attempt + 1)
            return job
        time.sleep(interval_s)
    LOG.error("Timeout waiting for job %s", job_id)
    sys.exit(1)


def main() -> None:
    repo = Path(__file__).resolve().parent.parent
    default_base = repo / "app/assets/images/terrain/base_64"
    default_out_dir = default_base / "_poc_wang_corner_anchor"

    p = argparse.ArgumentParser(
        description="PoC: 64×64 tile from 16×16 corner anchors + inpaint-v3 (async)"
    )
    p.add_argument(
        "--plains",
        type=Path,
        default=default_base / "plains_base_64_v5.png",
        help="64×64 plains base (default: plains_base_64_v5.png)",
    )
    p.add_argument(
        "--sea",
        type=Path,
        default=default_base / "sea_base_64.png",
        help="64×64 sea base",
    )
    p.add_argument(
        "--corners",
        type=str,
        default="PPPS",
        help="Four chars NW NE SW SE: P=plains S=sea (default PPPS)",
    )
    p.add_argument(
        "--out-dir",
        type=Path,
        default=default_out_dir,
        help="Directory for composite, mask, output, meta JSON",
    )
    p.add_argument(
        "--description",
        type=str,
        default=VERBATIM_WANG_INPAINT_DESCRIPTION,
        help="inpaint-v3 prompt (default: SPEC verbatim Wang description)",
    )
    p.add_argument(
        "--no-crop-to-mask",
        action="store_true",
        help="Pass crop_to_mask=false (default: true)",
    )
    p.add_argument(
        "--dry-run",
        action="store_true",
        help="Only write composite + mask + meta; do not call API",
    )
    p.add_argument(
        "--poll-interval",
        type=float,
        default=8.0,
        help="Seconds between job polls",
    )
    p.add_argument(
        "--max-polls",
        type=int,
        default=200,
        help="Max poll attempts",
    )
    p.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="DEBUG logs (payload sizes, API details)",
    )
    args = p.parse_args()
    configure_logging(verbose=args.verbose)

    corners = parse_corners(args.corners)
    idx = wang_index(*corners)
    out_dir: Path = args.out_dir.resolve()
    LOG.info(
        "start corners=%s wang_index=%d out_dir=%s dry_run=%s",
        args.corners.strip().upper(),
        idx,
        out_dir,
        args.dry_run,
    )

    out_dir.mkdir(parents=True, exist_ok=True)
    LOG.debug("ensured out_dir exists")

    plains_path = args.plains.resolve()
    sea_path = args.sea.resolve()
    if not plains_path.is_file():
        LOG.error("Missing plains base: %s", plains_path)
        sys.exit(1)
    if not sea_path.is_file():
        LOG.error("Missing sea base: %s", sea_path)
        sys.exit(1)

    LOG.info("load plains base: %s", plains_path)
    plains_img = Image.open(plains_path).convert("RGBA")
    LOG.info("load sea base: %s", sea_path)
    sea_img = Image.open(sea_path).convert("RGBA")
    assert_base_size(plains_img, plains_path)
    assert_base_size(sea_img, sea_path)

    composite, mask = build_composite_and_mask(plains_img, sea_img, corners)
    plains_img.close()
    sea_img.close()

    stem = f"corner_anchor_wang_{args.corners.strip().upper()}_{idx}"
    comp_path = out_dir / f"{stem}_composite.png"
    mask_path = out_dir / f"{stem}_mask.png"
    composite.save(comp_path)
    mask.save(mask_path)
    LOG.info("wrote composite: %s", comp_path)
    LOG.info("wrote mask: %s", mask_path)

    meta = {
        "corners_arg": args.corners.strip().upper(),
        "wang_index": idx,
        "plains_base": str(plains_path),
        "sea_base": str(sea_path),
        "composite": str(comp_path),
        "mask": str(mask_path),
        "subtile_px": SUB,
        "crop_to_mask": not args.no_crop_to_mask,
        "description": args.description,
    }
    meta_path = out_dir / f"{stem}_meta.json"
    meta_path.write_text(json.dumps(meta, indent=2), encoding="utf-8")
    LOG.info("wrote meta: %s", meta_path)

    if args.dry_run:
        LOG.info("dry run: skipping API")
        return

    api_key = get_api_key()
    crop_to_mask = not args.no_crop_to_mask
    job_id = submit_inpaint_v3(
        api_key,
        description=args.description,
        composite_path=comp_path,
        mask_path=mask_path,
        width=TILE,
        height=TILE,
        crop_to_mask=crop_to_mask,
    )
    completed = poll_until_done(
        api_key,
        job_id,
        interval_s=args.poll_interval,
        max_attempts=args.max_polls,
    )
    png = decode_result_png(completed, width=TILE, height=TILE)
    out_png = out_dir / f"{stem}_inpaint.png"
    out_png.write_bytes(png)
    meta["job_id"] = job_id
    meta["output_png"] = str(out_png)
    meta_path.write_text(json.dumps(meta, indent=2), encoding="utf-8")
    LOG.info("wrote output: %s (%d bytes)", out_png, len(png))
    LOG.info("updated meta with job_id and output: %s", meta_path)
    LOG.info("done")


if __name__ == "__main__":
    main()
