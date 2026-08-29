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
MAX_SEAM_DELTA = 2

MASK_N = 1
MASK_E = 2
MASK_S = 4
MASK_W = 8
CARDINALS = (("N", MASK_N), ("E", MASK_E), ("S", MASK_S), ("W", MASK_W))

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_ATLAS_OUT_DIR = REPO_ROOT / "pytool/out/transport_overlay_atlases_64"
DEFAULT_CONTRACTS_OUT = REPO_ROOT / "pytool/out/transport_edge_contracts_64"
DEFAULT_STATE_PATH = DEFAULT_CONTRACTS_OUT / "state.json"
SHIPPED_TILESET_DIR = REPO_ROOT / "app/assets/images/terrain/tilesets"


@dataclass(frozen=True)
class FamilyPlan:
    key: str
    seed_prompt: str
    center_fill_prompt: str


FAMILY_PLANS = (
    FamilyPlan(
        key="road",
        seed_prompt=(
            "pixel art top-down worn earth track straight segment, muted olive-brown palette "
            "matching ColonizeThis sea/plains terrain tileset, centered 14px wide corridor, "
            "64x64 tile, transparent background, stippled pixel texture not sandy yellow, "
            "no grass lot outside the corridor, crisp strategy game overlay"
        ),
        center_fill_prompt=(
            "connect the existing 14px earth-track corridor through the plus-shaped interior only. "
            "muted olive-brown pixel stipple matching terrain palette, no asphalt, no sandy path, "
            "keep transparent background."
        ),
    ),
    FamilyPlan(
        key="rail",
        seed_prompt=(
            "pixel art top-down railroad straight segment, muted grey steel rails and brown "
            "wooden ties, palette matching ColonizeThis terrain (no purple wood, no pier decking), "
            "centered 14px wide corridor, 64x64 tile, transparent background, "
            "no ballast platform or bridge deck"
        ),
        center_fill_prompt=(
            "connect the existing 14px rail corridor through the plus-shaped interior only. "
            "even brown wooden ties and dark steel rails, muted grey bed, no purple planks, "
            "keep transparent background."
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


def _force_corridor_wrap_ns(image: Image.Image) -> None:
    px = image.load()
    for x in range(CORRIDOR_START, CORRIDOR_END):
        px[x, TILE - 1] = px[x, 0]


def _force_corridor_wrap_ew(image: Image.Image) -> None:
    px = image.load()
    for y in range(CORRIDOR_START, CORRIDOR_END):
        px[TILE - 1, y] = px[0, y]


def _extend_corridor_to_edges(image: Image.Image) -> None:
    px = image.load()
    opaque_rows = [
        y
        for y in range(TILE)
        if any(px[x, y][3] > 0 for x in range(CORRIDOR_START, CORRIDOR_END))
    ]
    if not opaque_rows:
        return
    first = opaque_rows[0]
    last = opaque_rows[-1]
    for y in range(first):
        for x in range(CORRIDOR_START, CORRIDOR_END):
            px[x, y] = px[x, first]
    for y in range(last + 1, TILE):
        for x in range(CORRIDOR_START, CORRIDOR_END):
            px[x, y] = px[x, last]


def _corridor_row_opaque_count(px: Any, y: int) -> int:
    return sum(1 for x in range(CORRIDOR_START, CORRIDOR_END) if px[x, y][3] > 0)


def maybe_repeat_corridor_period(image: Image.Image) -> None:
    """Tile a mid-corridor period so sparse edge caps (e.g. rail ties) wrap."""
    px = image.load()
    opaque_counts = [_corridor_row_opaque_count(px, y) for y in range(TILE)]
    sparse_edge = opaque_counts[0] <= 4 and opaque_counts[TILE - 1] <= 4
    dense_mid = max(opaque_counts[16:48]) >= CORRIDOR_PX - 1
    if not (sparse_edge and dense_mid):
        return
    best_p = 0
    best_score = 0.0
    for period in range(4, 13):
        score = 0
        samples = 0
        for y in range(18, 50 - period):
            samples += 1
            if opaque_counts[y] == opaque_counts[y + period]:
                score += 1
        if samples == 0:
            continue
        ratio = score / samples
        if ratio > best_score:
            best_score = ratio
            best_p = period
    if best_p == 0 or best_score < 0.5:
        return
    start = max(
        range(18, 49 - best_p),
        key=lambda origin: (
            sum(opaque_counts[origin : origin + best_p]),
            opaque_counts[origin],
        ),
    )
    period_rows = [
        [px[x, start + offset] for x in range(CORRIDOR_START, CORRIDOR_END)]
        for offset in range(best_p)
    ]
    for y in range(TILE):
        src = period_rows[y % best_p]
        for index, x in enumerate(range(CORRIDOR_START, CORRIDOR_END)):
            px[x, y] = src[index]


def normalize_straight(seed: Image.Image) -> Image.Image:
    normalized = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    column = seed.crop((CORRIDOR_START, 0, CORRIDOR_END, TILE))
    normalized.paste(column, (CORRIDOR_START, 0), column)
    _extend_corridor_to_edges(normalized)
    maybe_repeat_corridor_period(normalized)
    _force_corridor_wrap_ns(normalized)
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
    _force_corridor_wrap_ew(horiz)
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


def pixel_in_mask_plus(mask: int, x: int, y: int) -> bool:
    if mask == 0:
        return False
    on_v = CORRIDOR_START <= x < CORRIDOR_END
    on_h = CORRIDOR_START <= y < CORRIDOR_END
    need_v = (mask & (MASK_N | MASK_S)) != 0
    need_h = (mask & (MASK_E | MASK_W)) != 0
    if on_v and need_v:
        y_min = 0 if (mask & MASK_N) else (CORRIDOR_START if need_h else HALF)
        y_max = TILE if (mask & MASK_S) else (CORRIDOR_END if need_h else HALF)
        if y_min <= y < y_max:
            return True
    if on_h and need_h:
        x_min = 0 if (mask & MASK_W) else (CORRIDOR_START if need_v else HALF)
        x_max = TILE if (mask & MASK_E) else (CORRIDOR_END if need_v else HALF)
        if x_min <= x < x_max:
            return True
    return False


def clip_to_mask_plus(tile: Image.Image, mask: int) -> Image.Image:
    out = tile.copy()
    dest = out.load()
    for y in range(TILE):
        for x in range(TILE):
            if dest[x, y][3] > 0 and not pixel_in_mask_plus(mask, x, y):
                dest[x, y] = (0, 0, 0, 0)
    return out


def fill_transparent_plus_pixels(tile: Image.Image, mask: int) -> Image.Image:
    out = tile.copy()
    dest = out.load()
    changed = True
    while changed:
        changed = False
        updates: list[tuple[int, int, tuple[int, int, int, int]]] = []
        for y in range(TILE):
            for x in range(TILE):
                if dest[x, y][3] > 0 or not pixel_in_mask_plus(mask, x, y):
                    continue
                for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
                    nx = x + dx
                    ny = y + dy
                    if 0 <= nx < TILE and 0 <= ny < TILE and dest[nx, ny][3] > 0:
                        updates.append((x, y, dest[nx, ny]))
                        break
        for x, y, color in updates:
            if dest[x, y][3] == 0:
                dest[x, y] = color
                changed = True
    return out


def plus_leak_count(tile: Image.Image, mask: int) -> int:
    px = tile.load()
    leak = 0
    for y in range(TILE):
        for x in range(TILE):
            if px[x, y][3] > 0 and not pixel_in_mask_plus(mask, x, y):
                leak += 1
    return leak


def inpaint_mask_for_mask(mask: int) -> Image.Image:
    image = Image.new("L", (TILE, TILE), 0)
    px = image.load()
    inset = 2
    for y in range(inset, TILE - inset):
        for x in range(inset, TILE - inset):
            if pixel_in_mask_plus(mask, x, y):
                px[x, y] = 255
    return image


def center_mask_for_inpaint() -> Image.Image:
    return inpaint_mask_for_mask(MASK_N | MASK_E | MASK_S | MASK_W)


def finalize_mask_tile(tile: Image.Image, mask: int, contract_base: Image.Image) -> Image.Image:
    if mask == 0:
        return Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    reinforced = reinforce_contract_edges(tile, contract_base)
    filled = fill_transparent_plus_pixels(reinforced, mask)
    return clip_to_mask_plus(filled, mask)


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
    dest = out.load()
    src = contract_base.load()
    for x in range(TILE):
        dest[x, 0] = src[x, 0]
        dest[x, TILE - 1] = src[x, TILE - 1]
    for y in range(TILE):
        dest[0, y] = src[0, y]
        dest[TILE - 1, y] = src[TILE - 1, y]
    for y in range(TILE):
        for x in range(TILE):
            pixel = src[x, y]
            if pixel[3] > 0:
                dest[x, y] = pixel
    return out


def has_any_alpha_pixels(image: Image.Image) -> bool:
    alpha = image.getchannel("A")
    return alpha.getbbox() is not None


def verify_written_tile(tile_path: Path, *, mask: int) -> None:
    if not tile_path.is_file():
        raise RuntimeError(f"Expected generated tile missing on disk: {tile_path}")
    with Image.open(tile_path) as tile_file:
        tile = tile_file.convert("RGBA")
    if tile.size != (TILE, TILE):
        raise RuntimeError(
            f"Generated tile {tile_path.name} has unexpected size {tile.size}; expected {(TILE, TILE)}",
        )
    has_alpha = has_any_alpha_pixels(tile)
    if mask == 0 and has_alpha:
        raise RuntimeError(
            f"mask=0 tile should be fully transparent but found opaque pixels: {tile_path.name}",
        )
    if mask != 0 and not has_alpha:
        raise RuntimeError(
            f"mask={mask} tile is fully transparent; generation failed: {tile_path.name}",
        )


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
    inpaint_mask_for_mask(MASK_N | MASK_E | MASK_S | MASK_W).save(
        family_contract_dir / "center_mask.png",
    )


def load_contract_assets(family_contract_dir: Path) -> dict[str, Image.Image]:
    straight_path = family_contract_dir / "straight_seed_normalized.png"
    if not straight_path.is_file():
        raise RuntimeError(
            f"Missing {straight_path}. Run with --init-seed for this family first.",
        )
    straight = Image.open(straight_path).convert("RGBA")
    return build_contracts(straight)


def refresh_normalized_seed_and_contracts(family_contract_dir: Path) -> dict[str, Image.Image]:
    straight_path = family_contract_dir / "straight_seed_normalized.png"
    if not straight_path.is_file():
        raise RuntimeError(
            f"Missing {straight_path}. Run with --init-seed for this family first.",
        )
    seed = Image.open(straight_path).convert("RGBA")
    straight = normalize_straight(seed)
    contracts = build_contracts(straight)
    family_contract_dir.mkdir(parents=True, exist_ok=True)
    straight.save(straight_path)
    for dir_key, image in contracts.items():
        image.save(family_contract_dir / f"edge_contract_{dir_key}.png")
    inpaint_mask_for_mask(MASK_N | MASK_E | MASK_S | MASK_W).save(
        family_contract_dir / "center_mask.png",
    )
    return contracts


def merge_inpaint_into_plus(
    composed: Image.Image,
    inpainted: Image.Image,
    mask: int,
) -> Image.Image:
    mixed = composed.copy()
    dest = mixed.load()
    src = inpainted.load()
    for y in range(TILE):
        for x in range(TILE):
            if dest[x, y][3] == 0 and pixel_in_mask_plus(mask, x, y) and src[x, y][3] > 0:
                dest[x, y] = src[x, y]
    return mixed


def refresh_family_tiles_from_seed(family_contract_dir: Path) -> None:
    contracts = refresh_normalized_seed_and_contracts(family_contract_dir)
    for mask in range(16):
        tile_path = family_contract_dir / f"tile_mask_{mask:02d}.png"
        composed = compose_mask_contract(mask, contracts)
        final_tile = finalize_mask_tile(composed, mask, composed)
        final_tile.save(tile_path)
        verify_written_tile(tile_path, mask=mask)


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


def resolve_user_path(path: Path) -> Path:
    if path.is_absolute():
        return path.resolve()
    parts = path.parts
    if parts and parts[0] in ("pytool", "app"):
        return (REPO_ROOT / path).resolve()
    return (Path.cwd() / path).resolve()


def refuse_shipped_out_dir(out_dir: Path, *, allow_shipped: bool) -> None:
    resolved = out_dir.resolve()
    shipped = SHIPPED_TILESET_DIR.resolve()
    if resolved == shipped and not allow_shipped:
        print(
            "Refusing to write transport atlases into shipped UI tilesets "
            f"({shipped}). Use the default candidate directory "
            f"{DEFAULT_ATLAS_OUT_DIR} or pass --allow-shipped-out-dir.",
            file=sys.stderr,
        )
        sys.exit(2)


def _pixel_channel_delta(left: tuple[int, ...], right: tuple[int, ...]) -> int:
    return max(abs(left[i] - right[i]) for i in range(4))


def edge_pixels(tile: Image.Image, cardinal: str) -> list[tuple[int, int, int, int]]:
    px = tile.load()
    if cardinal == "N":
        return [px[x, 0] for x in range(TILE)]
    if cardinal == "S":
        return [px[x, TILE - 1] for x in range(TILE)]
    if cardinal == "W":
        return [px[0, y] for y in range(TILE)]
    if cardinal == "E":
        return [px[TILE - 1, y] for y in range(TILE)]
    raise ValueError(f"unknown cardinal {cardinal}")


def corridor_edge_indices(cardinal: str) -> range:
    del cardinal
    return range(CORRIDOR_START, CORRIDOR_END)


def complementary_cardinal(cardinal: str) -> str:
    return {"N": "S", "S": "N", "E": "W", "W": "E"}[cardinal]


def check_family_seams(
    family_contract_dir: Path,
    *,
    max_delta: int = MAX_SEAM_DELTA,
) -> list[str]:
    errors: list[str] = []
    contracts = load_contract_assets(family_contract_dir)
    tiles: dict[int, Image.Image] = {}
    for mask in range(16):
        tile_path = family_contract_dir / f"tile_mask_{mask:02d}.png"
        if not tile_path.is_file():
            errors.append(f"missing {tile_path.name}")
            continue
        tiles[mask] = Image.open(tile_path).convert("RGBA")

    if errors:
        return errors

    for mask, tile in tiles.items():
        if mask == 0:
            continue
        for cardinal, bit in CARDINALS:
            if mask & bit == 0:
                continue
            tile_edge = edge_pixels(tile, cardinal)
            contract_edge = edge_pixels(contracts[cardinal], cardinal)
            for index, (actual, expected) in enumerate(zip(tile_edge, contract_edge, strict=True)):
                if _pixel_channel_delta(actual, expected) > max_delta:
                    errors.append(
                        f"{family_contract_dir.name} mask={mask} {cardinal} edge "
                        f"index={index} delta>{max_delta}",
                    )
                    break
            opaque = False
            for index in corridor_edge_indices(cardinal):
                if tile_edge[index][3] > 0:
                    opaque = True
                    break
            if not opaque:
                errors.append(
                    f"{family_contract_dir.name} mask={mask} {cardinal} "
                    "14px corridor edge is fully transparent",
                )
        leak = plus_leak_count(tile, mask)
        if leak > 0:
            errors.append(
                f"{family_contract_dir.name} mask={mask} has {leak} opaque pixels "
                "outside the 14px plus",
            )

    pair_masks = {"N": MASK_N, "S": MASK_S, "E": MASK_E, "W": MASK_W}
    for cardinal, bit in CARDINALS:
        opposite = complementary_cardinal(cardinal)
        opposite_bit = pair_masks[opposite]
        left_mask = next((m for m in range(1, 16) if m & bit), None)
        right_mask = next((m for m in range(1, 16) if m & opposite_bit), None)
        if left_mask is None or right_mask is None:
            continue
        left_edge = edge_pixels(tiles[left_mask], cardinal)
        right_edge = edge_pixels(tiles[right_mask], opposite)
        for index, (left, right) in enumerate(zip(left_edge, right_edge, strict=True)):
            if _pixel_channel_delta(left, right) > max_delta:
                errors.append(
                    f"{family_contract_dir.name} complementary {cardinal}↔{opposite} "
                    f"edge index={index} delta>{max_delta}",
                )
                break
    return errors


def extract_atlas_tile(atlas: Image.Image, mask: int) -> Image.Image:
    row = mask // ATLAS_COLS
    col = mask % ATLAS_COLS
    left = col * TILE
    top = row * TILE
    return atlas.crop((left, top, left + TILE, top + TILE)).convert("RGBA")


def check_atlas_seams(atlas_path: Path, *, max_delta: int = MAX_SEAM_DELTA) -> list[str]:
    errors: list[str] = []
    if not atlas_path.is_file():
        return [f"missing atlas {atlas_path}"]
    with Image.open(atlas_path) as atlas_file:
        atlas = atlas_file.convert("RGBA")
    if atlas.size != (ATLAS_COLS * TILE, ATLAS_ROWS * TILE):
        return [f"{atlas_path.name} size {atlas.size} != {(ATLAS_COLS * TILE, ATLAS_ROWS * TILE)}"]
    tiles = {mask: extract_atlas_tile(atlas, mask) for mask in range(16)}
    pair_masks = {"N": MASK_N, "S": MASK_S, "E": MASK_E, "W": MASK_W}
    for cardinal, bit in CARDINALS:
        opposite = complementary_cardinal(cardinal)
        opposite_bit = pair_masks[opposite]
        left_mask = next((m for m in range(1, 16) if m & bit), None)
        right_mask = next((m for m in range(1, 16) if m & opposite_bit), None)
        if left_mask is None or right_mask is None:
            continue
        left_edge = edge_pixels(tiles[left_mask], cardinal)
        right_edge = edge_pixels(tiles[right_mask], opposite)
        for index, (left, right) in enumerate(zip(left_edge, right_edge, strict=True)):
            if _pixel_channel_delta(left, right) > max_delta:
                errors.append(
                    f"{atlas_path.name} complementary {cardinal}↔{opposite} "
                    f"edge index={index} delta>{max_delta}",
                )
                break
        opaque = False
        for index in corridor_edge_indices(cardinal):
            if left_edge[index][3] > 0:
                opaque = True
                break
        if not opaque:
            errors.append(
                f"{atlas_path.name} mask={left_mask} {cardinal} "
                "14px corridor edge is fully transparent",
            )
    for mask, tile in tiles.items():
        if mask == 0:
            continue
        leak = plus_leak_count(tile, mask)
        if leak > 0:
            errors.append(
                f"{atlas_path.name} mask={mask} has {leak} opaque pixels "
                "outside the 14px plus",
            )
    return errors


QA_LAYOUTS: dict[str, list[tuple[int, int, int]]] = {
    "straight_ns": [(0, 0, 5), (0, 1, 5), (0, 2, 5)],
    "straight_ew": [(0, 0, 10), (1, 0, 10), (2, 0, 10)],
    "corner": [(0, 0, 6), (1, 0, 12), (1, 1, 3)],
    "tee": [(0, 1, 10), (1, 1, 13), (2, 1, 10), (1, 0, 5)],
    "cross": [(1, 0, 5), (0, 1, 10), (1, 1, 15), (2, 1, 10), (1, 2, 5)],
    "path": [(0, 1, 10), (1, 1, 14), (1, 2, 5), (1, 3, 5)],
}


def write_qa_composites(family_contract_dir: Path, out_dir: Path) -> None:
    family = family_contract_dir.name
    tiles: dict[int, Image.Image] = {}
    for mask in range(16):
        tile_path = family_contract_dir / f"tile_mask_{mask:02d}.png"
        if not tile_path.is_file():
            raise RuntimeError(f"Cannot write QA composites; missing {tile_path}")
        tiles[mask] = Image.open(tile_path).convert("RGBA")
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, cells in QA_LAYOUTS.items():
        cols = max(cell[0] for cell in cells) + 1
        rows = max(cell[1] for cell in cells) + 1
        canvas = Image.new("RGBA", (cols * TILE, rows * TILE), (32, 48, 32, 255))
        for col, row, mask in cells:
            tile = tiles[mask]
            canvas.paste(tile, (col * TILE, row * TILE), tile)
        dest = out_dir / f"qa_{family}_{name}.png"
        canvas.save(dest)
        print(f"[{family}] wrote QA composite {dest}")


def parse_mask_args(mask_values: list[int] | None) -> list[int]:
    if not mask_values:
        return list(range(16))
    masks = sorted(set(mask_values))
    for mask in masks:
        if mask < 0 or mask > 15:
            raise ValueError(f"--mask must be in [0,15], got {mask}")
    return masks


def process_family_masks(
    api_key: str | None,
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
    process_masks: bool,
    write_qa: bool,
) -> None:
    family_contract_dir = contracts_out / family.key
    family_contract_dir.mkdir(parents=True, exist_ok=True)
    if init_seed or force_reseed:
        if not api_key:
            raise RuntimeError("PIXELLAB_API_KEY is required for --init-seed / --force-reseed")
        seed_and_write_contracts(
            api_key,
            family,
            family_contract_dir,
            force_reseed=force_reseed,
        )

    if process_masks:
        if not api_key:
            raise RuntimeError("PIXELLAB_API_KEY is required to generate mask tiles")
        contracts = load_contract_assets(family_contract_dir)
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
                    inpaint_mask_for_mask(mask),
                    family.center_fill_prompt,
                )
                mixed = merge_inpaint_into_plus(composed, inpainted, mask)
                final_tile = finalize_mask_tile(mixed, mask, composed)

            final_tile.save(tile_out)
            verify_written_tile(tile_out, mask=mask)
            completed.add(mask)
            family_state["completed_masks"] = sorted(completed)
            family_state["updated_at_epoch_s"] = int(time.time())
            save_state(state_path, state)
            print(f"[{family.key}] wrote+verified {tile_out.name}")

    if rebuild_atlas:
        refresh_family_tiles_from_seed(family_contract_dir)
        build_atlas_from_tiles(family_contract_dir, atlas_path)
        seam_errors = check_family_seams(family_contract_dir)
        if seam_errors:
            raise RuntimeError(
                "Candidate seam check failed:\n" + "\n".join(seam_errors),
            )
    if write_qa:
        write_qa_composites(family_contract_dir, atlas_path.parent)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate road/rail 64px transport overlay atlases via Pixflux + inpaint-v3",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=DEFAULT_ATLAS_OUT_DIR,
        help="Output directory for atlas PNG files (default: candidate folder, not shipped UI)",
    )
    parser.add_argument(
        "--contracts-out",
        type=Path,
        default=DEFAULT_CONTRACTS_OUT,
        help="Debug output path for per-mask/contract PNGs",
    )
    parser.add_argument(
        "--state-path",
        type=Path,
        default=DEFAULT_STATE_PATH,
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
    parser.add_argument(
        "--write-qa-composites",
        action="store_true",
        help="Write straight/corner/T/cross/path composites next to the atlas",
    )
    parser.add_argument(
        "--allow-shipped-out-dir",
        action="store_true",
        help="Allow --out-dir to target app/assets/images/terrain/tilesets (disabled by default)",
    )
    args = parser.parse_args()

    out_dir = resolve_user_path(args.out_dir)
    contracts_out = resolve_user_path(args.contracts_out)
    state_path = resolve_user_path(args.state_path)
    refuse_shipped_out_dir(out_dir, allow_shipped=args.allow_shipped_out_dir)

    seed_only = (
        (args.init_seed or args.force_reseed)
        and args.mask is None
        and not args.resume
        and not args.rebuild_atlas
    )
    rebuild_only = (
        args.rebuild_atlas
        and args.mask is None
        and not args.init_seed
        and not args.force_reseed
        and not args.resume
    )
    process_masks = not seed_only and not rebuild_only
    need_api = seed_only or process_masks or args.init_seed or args.force_reseed

    selected_families = FAMILY_PLANS
    if args.family != "both":
        selected_families = tuple(plan for plan in FAMILY_PLANS if plan.key == args.family)
    masks = parse_mask_args(args.mask)
    api_key = require_api_key() if need_api else None
    write_qa = args.write_qa_composites or args.rebuild_atlas
    for family in selected_families:
        atlas_name = f"tileset_transport_{family.key}_64.png"
        process_family_masks(
            api_key=api_key,
            family=family,
            atlas_path=out_dir / atlas_name,
            contracts_out=contracts_out,
            state_path=state_path,
            masks=masks,
            resume=args.resume,
            init_seed=args.init_seed,
            force_reseed=args.force_reseed,
            rebuild_atlas=args.rebuild_atlas,
            process_masks=process_masks,
            write_qa=write_qa,
        )


if __name__ == "__main__":
    main()
