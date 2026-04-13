#!/usr/bin/env python3
"""
Generate 64x64 road/rail transport overlay atlases (masks 0..15).

Pipeline:
1) Pixflux creates a straight reference tile per family.
2) Derive 16x64 edge contracts from the straight tile.
3) Compose a mask tile and fill center continuity with inpaint-v3.
4) Persist each mask tile + state; atlas can be rebuilt/resumed anytime.
"""

from __future__ import annotations

import argparse
import base64
import io
import json
import os
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import requests
from PIL import Image, ImageOps

API_BASE = "https://api.pixellab.ai/v2"
TILE = 64
ATLAS_COLS = 4
ATLAS_ROWS = 4
CORRIDOR_PX = 14
CORRIDOR_START = (TILE - CORRIDOR_PX) // 2
CORRIDOR_END = CORRIDOR_START + CORRIDOR_PX
HALF = TILE // 2

MASK_N = 1
MASK_E = 2
MASK_S = 4
MASK_W = 8


@dataclass(frozen=True)
class FamilyPlan:
    key: str
    seed_prompt: str
    center_fill_prompt: str


FAMILY_PLANS = (
    FamilyPlan(
        key="road",
        seed_prompt=(
            "pixel art top-down dirt road straight segment, centered 14px wide corridor, "
            "64x64 tile, transparent background, crisp strategy game terrain style"
        ),
        center_fill_prompt=(
            "fill the center of this top-down road tile so the existing edge road segments connect "
            "seamlessly through the center. preserve edge contracts and transparent background."
        ),
    ),
    FamilyPlan(
        key="rail",
        seed_prompt=(
            "pixel art top-down railroad straight segment, centered 14px wide corridor, "
            "64x64 tile, transparent background, wooden ties and steel rails"
        ),
        center_fill_prompt=(
            "fill the center of this top-down railroad tile so the existing edge rail segments connect "
            "seamlessly through the center. preserve edge contracts and transparent background."
        ),
    ),
)


def require_api_key() -> str:
    key = os.environ.get("PIXELLAB_API_KEY", "").strip()
    if not key:
        print("PIXELLAB_API_KEY is required", file=sys.stderr)
        sys.exit(1)
    return key


def png_b64_field(png_bytes: bytes) -> dict[str, str]:
    return {
        "type": "base64",
        "base64": base64.standard_b64encode(png_bytes).decode("ascii"),
        "format": "png",
    }


def image_to_png_bytes(image: Image.Image) -> bytes:
    buf = io.BytesIO()
    image.save(buf, format="PNG")
    return buf.getvalue()


def decode_image_payload(payload: dict[str, Any], *, width: int, height: int) -> bytes:
    def find_b64(obj: Any) -> str | None:
        if isinstance(obj, dict):
            b64 = obj.get("base64")
            if isinstance(b64, str) and len(b64) > 100:
                return b64.split(",", 1)[-1]
            for value in obj.values():
                found = find_b64(value)
                if found:
                    return found
        elif isinstance(obj, list):
            for value in obj:
                found = find_b64(value)
                if found:
                    return found
        return None

    b64 = find_b64(payload)
    if not b64:
        raise RuntimeError("No base64 image payload found")
    raw = base64.standard_b64decode(b64)
    if raw.startswith(b"\x89PNG\r\n\x1a\n"):
        return raw
    if len(raw) == width * height * 4:
        img = Image.frombytes("RGBA", (width, height), raw)
        return image_to_png_bytes(img)
    raise RuntimeError(f"Unexpected payload length: {len(raw)}")


def poll_background_job(api_key: str, job_id: str, *, interval_s: float, max_polls: int) -> dict[str, Any]:
    for _ in range(max_polls):
        resp = requests.get(
            f"{API_BASE}/background-jobs/{job_id}",
            headers={"Authorization": f"Bearer {api_key}"},
            timeout=60,
        )
        if resp.status_code != 200:
            time.sleep(interval_s)
            continue
        body = resp.json()
        status = body.get("status") or (body.get("data") or {}).get("status")
        if status == "completed":
            return body
        if status in ("failed", "error"):
            raise RuntimeError(f"Background job failed: {json.dumps(body)[:2000]}")
        time.sleep(interval_s)
    raise RuntimeError(f"Timed out waiting for background job {job_id}")


def create_pixflux_seed(api_key: str, prompt: str) -> Image.Image:
    payload = {
        "description": prompt,
        "image_size": {"width": TILE, "height": TILE},
        "no_background": True,
    }
    resp = requests.post(
        f"{API_BASE}/create-image-pixflux",
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        json=payload,
        timeout=120,
    )
    if resp.status_code != 200:
        raise RuntimeError(f"Pixflux request failed: {resp.status_code} {resp.text[:500]}")
    png = decode_image_payload(resp.json(), width=TILE, height=TILE)
    return Image.open(io.BytesIO(png)).convert("RGBA")


def normalize_straight(seed: Image.Image) -> Image.Image:
    normalized = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    column = seed.crop((CORRIDOR_START, 0, CORRIDOR_END, TILE))
    normalized.paste(column, (CORRIDOR_START, 0), column)
    return normalized


def build_contracts(straight: Image.Image) -> dict[str, Image.Image]:
    contracts: dict[str, Image.Image] = {}
    north = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    strip_n = straight.crop((CORRIDOR_START, 0, CORRIDOR_END, HALF))
    north.paste(strip_n, (CORRIDOR_START, 0), strip_n)
    contracts["N"] = north

    south = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    strip_s = straight.crop((CORRIDOR_START, HALF, CORRIDOR_END, TILE))
    south.paste(strip_s, (CORRIDOR_START, HALF), strip_s)
    contracts["S"] = south

    horiz = straight.rotate(90, expand=False)
    west = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    strip_w = horiz.crop((0, CORRIDOR_START, HALF, CORRIDOR_END))
    west.paste(strip_w, (0, CORRIDOR_START), strip_w)
    contracts["W"] = west

    east = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    strip_e = horiz.crop((HALF, CORRIDOR_START, TILE, CORRIDOR_END))
    east.paste(strip_e, (HALF, CORRIDOR_START), strip_e)
    contracts["E"] = east
    return contracts


def compose_mask_contract(mask: int, contracts: dict[str, Image.Image]) -> Image.Image:
    tile = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    if mask & MASK_N:
        tile.alpha_composite(contracts["N"])
    if mask & MASK_E:
        tile.alpha_composite(contracts["E"])
    if mask & MASK_S:
        tile.alpha_composite(contracts["S"])
    if mask & MASK_W:
        tile.alpha_composite(contracts["W"])
    return tile


def center_mask_for_inpaint() -> Image.Image:
    mask = Image.new("L", (TILE, TILE), 0)
    for y in range(16, 48):
        for x in range(16, 48):
            mask.putpixel((x, y), 255)
    return mask


def run_inpaint_v3(api_key: str, base_tile: Image.Image, mask_image: Image.Image, prompt: str) -> Image.Image:
    base_png = image_to_png_bytes(base_tile)
    mask_png = image_to_png_bytes(ImageOps.grayscale(mask_image))
    payload = {
        "description": prompt,
        "inpainting_image": {
            "image": png_b64_field(base_png),
            "size": {"width": TILE, "height": TILE},
        },
        "mask_image": {
            "image": png_b64_field(mask_png),
            "size": {"width": TILE, "height": TILE},
        },
        "no_background": True,
        "crop_to_mask": False,
    }
    resp = requests.post(
        f"{API_BASE}/inpaint-v3",
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        json=payload,
        timeout=120,
    )
    if resp.status_code != 202:
        raise RuntimeError(f"inpaint-v3 failed: {resp.status_code} {resp.text[:800]}")
    body = resp.json()
    root = body.get("data") if isinstance(body.get("data"), dict) else body
    job_id = root.get("background_job_id") or root.get("job_id")
    if not job_id:
        raise RuntimeError(f"inpaint-v3 missing job_id: {json.dumps(body)[:800]}")
    done = poll_background_job(api_key, str(job_id), interval_s=8.0, max_polls=90)
    png = decode_image_payload(done, width=TILE, height=TILE)
    return Image.open(io.BytesIO(png)).convert("RGBA")


def reinforce_contract_edges(tile: Image.Image, contract_base: Image.Image) -> Image.Image:
    out = tile.copy()
    out.alpha_composite(contract_base)
    return out


def load_state(state_path: Path) -> dict[str, Any]:
    if not state_path.is_file():
        return {"families": {}}
    raw = json.loads(state_path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        return {"families": {}}
    if "families" not in raw or not isinstance(raw["families"], dict):
        raw["families"] = {}
    return raw


def save_state(state_path: Path, state: dict[str, Any]) -> None:
    state_path.parent.mkdir(parents=True, exist_ok=True)
    state_path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")


def get_family_state(state: dict[str, Any], family: str) -> dict[str, Any]:
    families = state.setdefault("families", {})
    family_state = families.setdefault(family, {})
    family_state.setdefault("completed_masks", [])
    return family_state


def seed_and_write_contracts(
    api_key: str,
    family: FamilyPlan,
    family_contract_dir: Path,
    *,
    force_reseed: bool,
) -> None:
    straight_path = family_contract_dir / "straight_seed_normalized.png"
    if straight_path.is_file() and not force_reseed:
        print(f"[{family.key}] reuse existing straight seed: {straight_path}")
        return
    print(f"[{family.key}] create pixflux straight seed")
    seed = create_pixflux_seed(api_key, family.seed_prompt)
    straight = normalize_straight(seed)
    contracts = build_contracts(straight)
    family_contract_dir.mkdir(parents=True, exist_ok=True)
    straight.save(straight_path)
    for dir_key, image in contracts.items():
        image.save(family_contract_dir / f"edge_contract_{dir_key}.png")
    center_mask_for_inpaint().save(family_contract_dir / "center_mask.png")


def load_contract_assets(family_contract_dir: Path) -> tuple[dict[str, Image.Image], Image.Image]:
    straight_path = family_contract_dir / "straight_seed_normalized.png"
    if not straight_path.is_file():
        raise RuntimeError(
            f"Missing {straight_path}. Run with --init-seed for this family first.",
        )
    straight = Image.open(straight_path).convert("RGBA")
    contracts = build_contracts(straight)
    center_mask_path = family_contract_dir / "center_mask.png"
    if center_mask_path.is_file():
        center_mask = Image.open(center_mask_path).convert("L")
    else:
        center_mask = center_mask_for_inpaint()
        center_mask.save(center_mask_path)
    return contracts, center_mask


def build_atlas_from_tiles(family_contract_dir: Path, atlas_path: Path) -> None:
    atlas = Image.new("RGBA", (ATLAS_COLS * TILE, ATLAS_ROWS * TILE), (0, 0, 0, 0))
    missing = []
    for mask in range(16):
        tile_path = family_contract_dir / f"tile_mask_{mask:02d}.png"
        if not tile_path.is_file():
            missing.append(mask)
            continue
        tile = Image.open(tile_path).convert("RGBA")
        row = mask // ATLAS_COLS
        col = mask % ATLAS_COLS
        atlas.paste(tile, (col * TILE, row * TILE), tile)
    if missing:
        raise RuntimeError(
            f"Cannot build atlas for {family_contract_dir.name}; missing masks {missing}",
        )
    atlas_path.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(atlas_path)
    print(f"[{family_contract_dir.name}] wrote atlas {atlas_path}")


def parse_mask_args(mask_values: list[int] | None) -> list[int]:
    if not mask_values:
        return list(range(16))
    masks = sorted(set(mask_values))
    for mask in masks:
        if mask < 0 or mask > 15:
            raise ValueError(f"--mask must be in [0,15], got {mask}")
    return masks


def process_family_masks(
    api_key: str,
    family: FamilyPlan,
    atlas_path: Path,
    contracts_out: Path,
    state_path: Path,
    masks: list[int],
    *,
    resume: bool,
    init_seed: bool,
    force_reseed: bool,
    rebuild_atlas: bool,
) -> None:
    family_contract_dir = contracts_out / family.key
    family_contract_dir.mkdir(parents=True, exist_ok=True)
    if init_seed or force_reseed:
        seed_and_write_contracts(
            api_key,
            family,
            family_contract_dir,
            force_reseed=force_reseed,
        )

    contracts, center_mask = load_contract_assets(family_contract_dir)
    state = load_state(state_path)
    family_state = get_family_state(state, family.key)
    completed = set(int(x) for x in family_state.get("completed_masks", []))

    for mask in masks:
        tile_out = family_contract_dir / f"tile_mask_{mask:02d}.png"
        if resume and mask in completed and tile_out.is_file():
            print(f"[{family.key}] skip completed mask={mask}")
            continue

        composed = compose_mask_contract(mask, contracts)
        if mask == 0:
            final_tile = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
        else:
            print(f"[{family.key}] inpaint-v3 mask={mask}")
            inpainted = run_inpaint_v3(
                api_key,
                composed,
                center_mask,
                family.center_fill_prompt,
            )
            final_tile = reinforce_contract_edges(inpainted, composed)

        final_tile.save(tile_out)
        completed.add(mask)
        family_state["completed_masks"] = sorted(completed)
        family_state["updated_at_epoch_s"] = int(time.time())
        save_state(state_path, state)
        print(f"[{family.key}] wrote {tile_out.name}")

    if rebuild_atlas:
        build_atlas_from_tiles(family_contract_dir, atlas_path)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate road/rail 64px transport overlay atlases via Pixflux + inpaint-v3",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=Path("app/assets/images/terrain/tilesets"),
        help="Output directory for atlas PNG files",
    )
    parser.add_argument(
        "--contracts-out",
        type=Path,
        default=Path("pytool/out/transport_edge_contracts_64"),
        help="Debug output path for per-mask/contract PNGs",
    )
    parser.add_argument(
        "--state-path",
        type=Path,
        default=Path("pytool/out/transport_edge_contracts_64/state.json"),
        help="State file used to resume completed mask tiles",
    )
    parser.add_argument(
        "--family",
        choices=["road", "rail", "both"],
        default="both",
        help="Which family to process",
    )
    parser.add_argument(
        "--mask",
        type=int,
        action="append",
        help="Process only this mask id (0..15). Repeat to run multiple masks.",
    )
    parser.add_argument(
        "--resume",
        action="store_true",
        help="Skip masks already marked complete in state.json and on disk",
    )
    parser.add_argument(
        "--init-seed",
        action="store_true",
        help="Generate/reuse Pixflux straight seed + contracts before mask processing",
    )
    parser.add_argument(
        "--force-reseed",
        action="store_true",
        help="Regenerate Pixflux straight seed and overwrite contracts for selected family",
    )
    parser.add_argument(
        "--rebuild-atlas",
        action="store_true",
        help="Rebuild the 4x4 atlas from tile_mask_00..15 after mask processing",
    )
    args = parser.parse_args()

    selected_families = FAMILY_PLANS
    if args.family != "both":
        selected_families = tuple(plan for plan in FAMILY_PLANS if plan.key == args.family)
    masks = parse_mask_args(args.mask)
    api_key = require_api_key()
    for family in selected_families:
        atlas_name = f"tileset_transport_{family.key}_64.png"
        process_family_masks(
            api_key=api_key,
            family=family,
            atlas_path=args.out_dir / atlas_name,
            contracts_out=args.contracts_out,
            state_path=args.state_path,
            masks=masks,
            resume=args.resume,
            init_seed=args.init_seed,
            force_reseed=args.force_reseed,
            rebuild_atlas=args.rebuild_atlas,
        )


if __name__ == "__main__":
    main()
