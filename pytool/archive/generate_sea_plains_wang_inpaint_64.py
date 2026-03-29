#!/usr/bin/env python3
"""
Generate 16× 64×64 sea↔plains corner-Wang tiles via PixelLab inpaint-v3 (async + poll).

**D4 symmetry:** Only **6** wang indices are geometrically distinct under rotation+flip (**0, 1, 3, 6, 7, 15**).
**Inpaint jobs** run only for **1, 3, 6, 7** (plus **0** / **15** = uniform base copies). Indices **2,4,5,8–14**
are **`derived_d4`**: transpose of the canonical source (`WANG_D4_CANONICAL_SOURCE`). Use **`--show-d4-symmetry`**.

**Edge contracts (128×64 → centre 64×64 for P|S only):** **P|S** / **S|P** as above; **P|P** / **S|S**
are **copies** of the base tiles (no two-tile seam).

**Wang — strips (`--compositing-mode=strips`):** Quadrant fill, **10px** contract strips per edge,
rectangular interior mask (`--contract-edge-depth`). **No rotation** of contract PNGs: **W–E** edges use
**128×64** contracts; **N–S** edges use **64×128** contracts (`ps_td` / `sp_td`).

**Wang — cross (default, `--compositing-mode=cross`):** **192×192** canvas; **N/E/S/W** arms = full **64×64**
contracts; **N/S** arms shifted **`--cross-ns-contract-inset`** px toward the center (**default 5**).
Center **transparent** until inpaint (overlapped **N/S** strips excluded from white mask). Optional **`--cross-corner-hints`**: **10×10** opaque
base-tile crops at the four corners of the center cell (**off** by default). **White** inpaint = full
center **64×64** minus those corner blocks when hints are on, optionally shrunk by **`--cross-inpaint-inset`**
(default **0**). API returns **192×192**, script **crops center 64×64** as tile. State uses **`cross_polling`**,
**`cross_job_id`**, **`cross_stuck`**, **`cross_failed`**.

**Intermediates (default: save / refresh):** **`--rewrite-intermediates`** defaults **on** — each Wang tile generation
writes or rebuilds **`composite_XX.png`** + **`mask_XX.png`** (cross: under **`intermediate/cross/`**). Use
**`--no-rewrite-intermediates`** to reuse existing files when present. **Uniform** (**0/15**) and **D4-derived**
indices also get these intermediates (same compositing layout as inpaint indices).

**Edge contracts:** **Eight** independent **P↔S** centre crops — `contract_ps_lr|rl|td|bt.png` and
`contract_sp_lr|rl|td|bt.png` (**128×64** + vertical seam mask for **lr/rl**; **64×128** + horizontal
seam mask for **td/bt**). Seam inpaint band width (**default 30** px, **`--contract-seam-band`**).
**No** runtime rotation or mirror between **ps** and **sp** assets.
Per heterogeneous job, **`contracts_128/inpaint_io/<key>_input.png`** is the API **composite**;
**`<key>_output.png`** is the full **128×64** / **64×128** API result (**centre 64×64** → `contract_*.png`).
**`<key>_mask.png`** is the seam mask sent with the input.

**`--skip-edge-prototypes`** skips contract generation and requires existing **`contracts_128/*.png`**.

**`--edge-prototypes-only --only-edge-contract <key>`** runs **one** heterogeneous inpaint job per invocation
(`ps_lr`, `ps_rl`, `ps_td`, `ps_bt`, `sp_lr`, `sp_rl`, `sp_td`, `sp_bt`) — avoids long batches when the API is slow.
**`--edge-contract-description`** (default: **rocky coast** seam in the masked band, **no** cliffs) is used
**only** for those edge jobs; **`--description`** applies to **Wang** tile inpaint only (same coast intent).

**Inpaint-v3 `crop_to_mask`:** default **true** ( **`--no-crop-to-mask`** to disable). Required so the API
respects mask geometry for edge contracts and Wang interiors; otherwise coast blends leak and tiles
do not meet cleanly at edges.

Spec: SPEC/ui/tileset/plains-sea-wang-inpaint-64.md, SPEC/ui/tileset/base-tiles-64.md (archived script; see SPEC/ui/tileset/plains-sea-wang-inpaint-64.md § Archived batch pipeline).
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
from typing import Any, Iterable

import requests
from PIL import Image

API_BASE = "https://api.pixellab.ai/v2"
TILE_SIZE = 64
HALF = 32
# 128×64 composite: two full 64×64 bases abutted; centre crop is 64×64 contract (W–E seam)
COMPOSITE_W = 128
COMPOSITE_H = 64
CENTRE_CROP_LR = (32, 0, 96, 64)  # centred on vertical seam at x=64
# 64×128 composite: top/bottom 64×64 bases; centre crop is 64×64 contract (N–S seam)
COMPOSITE_V_W = 64
COMPOSITE_V_H = 128
CENTRE_CROP_TD = (0, 32, 64, 96)  # centred on horizontal seam at y=64
# White inpaint band centered on the seam in edge-contract composites (128×64 / 64×128)
DEFAULT_CONTRACT_SEAM_BAND_PX = 30
MIN_CONTRACT_SEAM_BAND_PX = 2
MAX_CONTRACT_SEAM_BAND_PX = 126
# Outermost strip taken from each contract and pasted on the Wang tile edge (strips mode)
DEFAULT_CONTRACT_EDGE_DEPTH = 10
MIN_CONTRACT_EDGE_DEPTH = 1
MAX_CONTRACT_EDGE_DEPTH = TILE_SIZE // 2 - 1  # 31 on 64px tile → non-empty interior

# Cross layout: 3×3 grid of 64px cells; arms = contracts; center + corners transparent until inpaint
CROSS_CANVAS = 192
CROSS_CENTER_OFF = TILE_SIZE  # x/y offset of Wang cell in cross canvas
# Opaque base-tile hints at center-cell corners (cross mode composite only)
CORNER_HINT_PX = 10
DEFAULT_CROSS_INPAINT_INSET = 0
MIN_CROSS_INPAINT_INSET = 0
MAX_CROSS_INPAINT_INSET = 20
# Shift N/S cross arms toward center; exclude overlapping center rows from inpaint mask (max < TILE_SIZE/2)
DEFAULT_CROSS_NS_CONTRACT_INSET_PX = 5
MIN_CROSS_NS_CONTRACT_INSET_PX = 0
MAX_CROSS_NS_CONTRACT_INSET_PX = TILE_SIZE // 2 - 1  # 31 on 64px tile — keeps ≥1 inpaint row

# Wang tile inpaint (cross center or strips interior): rocky coast, normal land–ocean boundary (not cliffs).
DEFAULT_DESCRIPTION = (
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

# Edge-contract jobs: narrow masked seam, rocky coast only (no cliffs), match bases at seam.
DEFAULT_EDGE_CONTRACT_DESCRIPTION = (
    "pixel art top-down orthographic colonial strategy map terrain narrow seam only rocky coastline "
    "where grassland plains meets open deep ocean natural shoreline transition no cliffs no vertical "
    "rock walls match colors and style to existing plains and sea at seam edges stay within masked band"
)


def get_api_key() -> str:
    key = os.environ.get("PIXELLAB_API_KEY")
    if not key or not key.strip():
        print("PIXELLAB_API_KEY is not set", file=sys.stderr)
        sys.exit(1)
    return key.strip()


def wang_index_to_corners(idx: int) -> tuple[bool, bool, bool, bool]:
    """Returns (nw, ne, sw, se) True = plains (upper), False = sea (lower)."""
    if not 0 <= idx <= 15:
        raise ValueError(f"wang_index out of range: {idx}")
    nw = bool(idx & 8)
    ne = bool(idx & 4)
    sw = bool(idx & 2)
    se = bool(idx & 1)
    return nw, ne, sw, se


# Two-terrain corner Wang: 16 assignments. Under the dihedral group D4 (90° rotations + flips of the
# tile image), there are 6 orbits — so 6 canonical indices need “real” assets; the other 10 are
# duplicates up to orientation. Canonical = smallest wang_index in each orbit.
#
# Value: (source_wang_index, transpose_name). source is always canonical. IDENTITY = copy source.
# transpose_name matches PIL.Image.Transpose (except IDENTITY).
WANG_D4_CANONICAL_SOURCE: dict[int, tuple[int, str]] = {
    0: (0, "IDENTITY"),
    1: (1, "IDENTITY"),
    2: (1, "ROTATE_270"),
    3: (3, "IDENTITY"),
    4: (1, "ROTATE_90"),
    5: (3, "ROTATE_90"),
    6: (6, "IDENTITY"),
    7: (7, "IDENTITY"),
    8: (1, "ROTATE_180"),
    9: (6, "ROTATE_90"),
    10: (3, "ROTATE_270"),
    11: (7, "ROTATE_270"),
    12: (3, "ROTATE_180"),
    13: (7, "ROTATE_90"),
    14: (7, "ROTATE_180"),
    15: (15, "IDENTITY"),
}

WANG_D4_ORBIT_REPRESENTATIVES: frozenset[int] = frozenset({0, 1, 3, 6, 7, 15})

# Canonical indices 1, 3, 6, 7 call inpaint-v3; 0 / 15 are uniform base copies; all others are
# derived via WANG_D4_CANONICAL_SOURCE (no API).
WANG_INDICES_REQUIRE_INPAINT_API: frozenset[int] = frozenset({1, 3, 6, 7})

_TRANSPOSE_BY_D4_NAME: dict[str, Image.Transpose] = {
    "ROTATE_90": Image.Transpose.ROTATE_90,
    "ROTATE_180": Image.Transpose.ROTATE_180,
    "ROTATE_270": Image.Transpose.ROTATE_270,
    "FLIP_LEFT_RIGHT": Image.Transpose.FLIP_LEFT_RIGHT,
    "FLIP_TOP_BOTTOM": Image.Transpose.FLIP_TOP_BOTTOM,
    "TRANSPOSE": Image.Transpose.TRANSPOSE,
    "TRANSVERSE": Image.Transpose.TRANSVERSE,
}


def wang_d4_is_derived_index(idx: int) -> bool:
    src, _ = WANG_D4_CANONICAL_SOURCE[idx]
    return src != idx


def expand_wang_indices_with_sources(indices: Iterable[int]) -> list[int]:
    """Include each tile’s canonical source; order: all representatives first, then derived (sorted)."""
    need = set(indices)
    for i in list(need):
        need.add(WANG_D4_CANONICAL_SOURCE[i][0])
    reps = sorted(i for i in need if not wang_d4_is_derived_index(i))
    derived = sorted(i for i in need if wang_d4_is_derived_index(i))
    return reps + derived


def apply_wang_d4_transpose(img: Image.Image, transpose_name: str) -> Image.Image:
    if transpose_name == "IDENTITY":
        return img.copy()
    op = _TRANSPOSE_BY_D4_NAME.get(transpose_name)
    if op is None:
        raise ValueError(f"unknown D4 transpose name: {transpose_name!r}")
    return img.transpose(op)


def edge_kind(left_plain: bool, right_plain: bool) -> str:
    """Two-material edge along traversal: left → right (or top → bottom)."""
    if left_plain and right_plain:
        return "pp"
    if not left_plain and not right_plain:
        return "ss"
    if left_plain and not right_plain:
        return "ps"
    return "sp"


def contracts_subdir(edge_proto_root: Path) -> Path:
    return edge_proto_root / "contracts_128"


def edge_contract_inpaint_io_paths(contracts_dir: Path, path_key: str) -> tuple[Path, Path, Path]:
    """inpaint_io: input composite, seam mask, full-size API output (before centre crop)."""
    iod = contracts_dir / "inpaint_io"
    return (
        iod / f"{path_key}_input.png",
        iod / f"{path_key}_mask.png",
        iod / f"{path_key}_output.png",
    )


def hetero_contract_suffixes() -> tuple[str, ...]:
    return ("lr", "rl", "td", "bt")


# Path keys under contracts_128/ (heterogeneous centre crops only; not pp/ss).
HETERO_EDGE_CONTRACT_PATH_KEYS: frozenset[str] = frozenset(
    f"{a}_{b}" for a in ("ps", "sp") for b in hetero_contract_suffixes()
)


def contract_paths(edge_proto_root: Path) -> dict[str, Path]:
    d = contracts_subdir(edge_proto_root)
    out: dict[str, Path] = {
        "pp": d / "contract_pp_lr.png",
        "ss": d / "contract_ss_lr.png",
    }
    for hx in ("ps", "sp"):
        for suf in hetero_contract_suffixes():
            out[f"{hx}_{suf}"] = d / f"contract_{hx}_{suf}.png"
    return out


def assert_edge_contracts_present(edge_proto_root: Path) -> None:
    paths = contract_paths(edge_proto_root)
    missing = [p for p in paths.values() if not p.is_file()]
    if not missing:
        return
    print(
        "--skip-edge-prototypes: expected homogeneous pp/ss plus eight heterogeneous "
        f"contract_*.png under {contracts_subdir(edge_proto_root)!s}:",
        file=sys.stderr,
    )
    for p in missing:
        print(f"  - {p}", file=sys.stderr)
    print(
        "Generate once: --edge-prototypes-only, then rerun with --skip-edge-prototypes.",
        file=sys.stderr,
    )
    sys.exit(1)


def build_composite_128_pair(left_64: Image.Image, right_64: Image.Image) -> Image.Image:
    out = Image.new("RGBA", (COMPOSITE_W, COMPOSITE_H), (0, 0, 0, 255))
    out.paste(left_64, (0, 0))
    out.paste(right_64, (TILE_SIZE, 0))
    return out


def build_composite_64_vertical(top_64: Image.Image, bottom_64: Image.Image) -> Image.Image:
    out = Image.new("RGBA", (COMPOSITE_V_W, COMPOSITE_V_H), (0, 0, 0, 255))
    out.paste(top_64, (0, 0))
    out.paste(bottom_64, (0, TILE_SIZE))
    return out


def crop_centre_contract_lr(img_128x64: Image.Image) -> Image.Image:
    return img_128x64.crop(CENTRE_CROP_LR)


def crop_centre_contract_td(img_64x128: Image.Image) -> Image.Image:
    return img_64x128.crop(CENTRE_CROP_TD)


def crop_centre_contract_for_api_dims(img: Image.Image, api_w: int, api_h: int) -> Image.Image:
    if api_w == COMPOSITE_W and api_h == COMPOSITE_H:
        return crop_centre_contract_lr(img)
    if api_w == COMPOSITE_V_W and api_h == COMPOSITE_V_H:
        return crop_centre_contract_td(img)
    raise ValueError(f"unexpected API dimensions for centre crop: {api_w}×{api_h}")


def mask_vertical_seam_128x64(band_px: int) -> Image.Image:
    """Grayscale mask: white vertical band `band_px` wide, centered on x = 64."""
    if band_px < MIN_CONTRACT_SEAM_BAND_PX or band_px > MAX_CONTRACT_SEAM_BAND_PX:
        raise ValueError(
            f"contract seam band must be in [{MIN_CONTRACT_SEAM_BAND_PX}, {MAX_CONTRACT_SEAM_BAND_PX}], "
            f"got {band_px}",
        )
    mask = Image.new("L", (COMPOSITE_W, COMPOSITE_H), 0)
    px = mask.load()
    assert px is not None
    mid = COMPOSITE_W // 2
    half_lo = band_px // 2
    half_hi = band_px - half_lo
    x0, x1 = mid - half_lo, mid + half_hi
    for y in range(COMPOSITE_H):
        for x in range(max(0, x0), min(COMPOSITE_W, x1)):
            px[x, y] = 255
    return mask


def mask_horizontal_seam_64x128(band_px: int) -> Image.Image:
    """Grayscale mask: white horizontal band `band_px` tall, centered on y = 64."""
    if band_px < MIN_CONTRACT_SEAM_BAND_PX or band_px > MAX_CONTRACT_SEAM_BAND_PX:
        raise ValueError(
            f"contract seam band must be in [{MIN_CONTRACT_SEAM_BAND_PX}, {MAX_CONTRACT_SEAM_BAND_PX}], "
            f"got {band_px}",
        )
    mask = Image.new("L", (COMPOSITE_V_W, COMPOSITE_V_H), 0)
    px = mask.load()
    assert px is not None
    mid = COMPOSITE_V_H // 2
    half_lo = band_px // 2
    half_hi = band_px - half_lo
    y0, y1 = mid - half_lo, mid + half_hi
    for y in range(max(0, y0), min(COMPOSITE_V_H, y1)):
        for x in range(COMPOSITE_V_W):
            px[x, y] = 255
    return mask


def build_hard_128_ps(plains: Image.Image, sea: Image.Image) -> Image.Image:
    return build_composite_128_pair(plains, sea)


def synthetic_hetero_contract(key: str, plains: Image.Image, sea: Image.Image) -> Image.Image:
    """Hard centre crop (no inpaint), for dry-run / missing heterogeneous contracts."""
    if key == "ps_lr":
        return crop_centre_contract_lr(build_hard_128_ps(plains, sea))
    if key == "ps_rl":
        return crop_centre_contract_lr(build_composite_128_pair(sea, plains))
    if key == "ps_td":
        return crop_centre_contract_td(build_composite_64_vertical(plains, sea))
    if key == "ps_bt":
        return crop_centre_contract_td(build_composite_64_vertical(sea, plains))
    if key == "sp_lr":
        return crop_centre_contract_lr(build_composite_128_pair(sea, plains))
    if key == "sp_rl":
        return crop_centre_contract_lr(build_hard_128_ps(plains, sea))
    if key == "sp_td":
        return crop_centre_contract_td(build_composite_64_vertical(sea, plains))
    if key == "sp_bt":
        return crop_centre_contract_td(build_composite_64_vertical(plains, sea))
    raise ValueError(f"unknown hetero contract key {key!r}")


def load_contract_image(
    path: Path,
    contract_key: str,
    *,
    plains: Image.Image,
    sea: Image.Image,
    dry_run: bool,
) -> Image.Image:
    if path.is_file():
        return Image.open(path).convert("RGBA")
    if dry_run:
        if contract_key == "pp":
            return plains.copy()
        if contract_key == "ss":
            return sea.copy()
        return synthetic_hetero_contract(contract_key, plains, sea)
    raise FileNotFoundError(
        f"Missing contract {path} (run --edge-prototypes-only first, or drop --skip-edge-prototypes)",
    )


def contract_key_for_wang_edge(edge: str, kind: str) -> str:
    """Which 64×64 contract to use for this Wang edge (no rotation of heterogeneous PNGs)."""
    if kind in ("pp", "ss"):
        return kind
    if edge in ("top", "bottom"):
        return f"{kind}_lr"
    # North→south along the edge: ps = plains (north) → sea (south); sp = sea → plains.
    # Composites: ps_td = vertical(plains, sea); sp_td = vertical(sea, plains). Using sp_bt here
    # inverted the seam (P above S instead of S above P) for E/W arms and strips left/right.
    if kind == "ps":
        return "ps_td"
    if kind == "sp":
        return "sp_td"
    raise ValueError(f"contract_key_for_wang_edge: unknown kind {kind!r}")


def paste_edge_band_from_contract(
    target: Image.Image,
    src_64: Image.Image,
    edge: str,
    depth: int,
) -> None:
    """Paste `depth` pixels from the outer edge of oriented `src_64` onto `target`."""
    if edge == "top":
        band = src_64.crop((0, 0, TILE_SIZE, depth))
        target.paste(band, (0, 0))
    elif edge == "bottom":
        band = src_64.crop((0, TILE_SIZE - depth, TILE_SIZE, TILE_SIZE))
        target.paste(band, (0, TILE_SIZE - depth))
    elif edge == "left":
        band = src_64.crop((0, 0, depth, TILE_SIZE))
        target.paste(band, (0, 0))
    elif edge == "right":
        band = src_64.crop((TILE_SIZE - depth, 0, TILE_SIZE, TILE_SIZE))
        target.paste(band, (TILE_SIZE - depth, 0))
    else:
        raise ValueError(edge)


def build_wang_composite_overlay_contracts(
    base_quad: Image.Image,
    nw: bool,
    ne: bool,
    sw: bool,
    se: bool,
    *,
    cpaths: dict[str, Path],
    plains: Image.Image,
    sea: Image.Image,
    dry_run: bool,
    overlay_depth: int,
) -> Image.Image:
    img = base_quad.copy()
    top_k = edge_kind(nw, ne)
    bot_k = edge_kind(sw, se)
    left_k = edge_kind(nw, sw)
    right_k = edge_kind(ne, se)

    # Order: top, bottom, then left/right (corners overwritten by vertical edges)
    for edge, kind in (
        ("top", top_k),
        ("bottom", bot_k),
        ("left", left_k),
        ("right", right_k),
    ):
        ck = contract_key_for_wang_edge(edge, kind)
        cpath = cpaths[ck]
        c = load_contract_image(cpath, ck, plains=plains, sea=sea, dry_run=dry_run)
        paste_edge_band_from_contract(img, c, edge, overlay_depth)
    return img


def build_composite_64(
    idx: int,
    plains: Image.Image,
    sea: Image.Image,
) -> Image.Image:
    nw, ne, sw, se = wang_index_to_corners(idx)
    out = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (0, 0, 0, 255))
    quads: list[tuple[tuple[int, int, int, int], bool]] = [
        ((0, 0, HALF, HALF), nw),
        ((HALF, 0, TILE_SIZE, HALF), ne),
        ((0, HALF, HALF, TILE_SIZE), sw),
        ((HALF, HALF, TILE_SIZE, TILE_SIZE), se),
    ]
    for (x0, y0, x1, y1), use_plains in quads:
        src = plains if use_plains else sea
        patch = src.crop((0, 0, HALF, HALF))
        out.paste(patch, (x0, y0))
    return out


def build_interior_rect_inpaint_mask(contract_edge_depth: int) -> Image.Image:
    """
    L-mode: black = keep (matches contract strip overlay). White = inpaint.

    Interior is the axis-aligned rectangle not covered by `contract_edge_depth` px bands on each
    side (same depth as `paste_edge_band_from_contract`).
    """
    d = contract_edge_depth
    if d < MIN_CONTRACT_EDGE_DEPTH or d > MAX_CONTRACT_EDGE_DEPTH:
        raise ValueError(
            f"contract_edge_depth must be in [{MIN_CONTRACT_EDGE_DEPTH}, {MAX_CONTRACT_EDGE_DEPTH}]",
        )
    mask = Image.new("L", (TILE_SIZE, TILE_SIZE), 0)
    pixels = mask.load()
    assert pixels is not None
    for y in range(d, TILE_SIZE - d):
        for x in range(d, TILE_SIZE - d):
            pixels[x, y] = 255
    return mask


def mask_has_inpaint(mask: Image.Image) -> bool:
    lo, hi = mask.getextrema()
    return hi > 0


def arm_image_for_cross_arm(edge: str, contract_rgba: Image.Image) -> Image.Image:
    """
    Align the contract edge that touches the center cell.

    N/S arms use full **lr** contracts; bottom arm is **flipud** of top semantics.
    E/W arms use **ps_td** / **sp_td** (no rotation). The **left** arm meets the center on its
    **east** bitmap edge → **fliplr** so the correct N–S column faces inward (matches old
    rotate270+fliplr). The **right** arm meets the center on its **west** edge → **no** fliplr;
    mirroring here swapped sea/plains horizontally and produced a wrong vertical coast.
    """
    if edge == "bottom":
        return contract_rgba.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    if edge == "left":
        return contract_rgba.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    return contract_rgba


def paste_cross_center_corner_hints(
    img: Image.Image,
    nw: bool,
    ne: bool,
    sw: bool,
    se: bool,
    plains: Image.Image,
    sea: Image.Image,
) -> None:
    """Opaque 10×10 crops from base tiles at the four corners of the center Wang cell."""
    h = CORNER_HINT_PX
    cx, cy = CROSS_CENTER_OFF, CROSS_CENTER_OFF
    specs: list[tuple[bool, int, int, tuple[int, int, int, int]]] = [
        (nw, cx, cy, (0, 0, h, h)),
        (ne, cx + TILE_SIZE - h, cy, (TILE_SIZE - h, 0, TILE_SIZE, h)),
        (sw, cx, cy + TILE_SIZE - h, (0, TILE_SIZE - h, h, TILE_SIZE)),
        (
            se,
            cx + TILE_SIZE - h,
            cy + TILE_SIZE - h,
            (TILE_SIZE - h, TILE_SIZE - h, TILE_SIZE, TILE_SIZE),
        ),
    ]
    for upper, px0, py0, box in specs:
        src = plains if upper else sea
        hint = src.crop(box)
        img.paste(hint, (px0, py0))


def build_cross_composite(
    nw: bool,
    ne: bool,
    sw: bool,
    se: bool,
    *,
    cpaths: dict[str, Path],
    plains: Image.Image,
    sea: Image.Image,
    dry_run: bool,
    use_corner_hints: bool,
    ns_contract_inset_px: int,
) -> Image.Image:
    """192×192 RGBA: cross arms; outer corners transparent; optional 10×10 corner hints in center."""
    if (
        ns_contract_inset_px < MIN_CROSS_NS_CONTRACT_INSET_PX
        or ns_contract_inset_px > MAX_CROSS_NS_CONTRACT_INSET_PX
    ):
        raise ValueError(
            f"ns_contract_inset_px must be in "
            f"[{MIN_CROSS_NS_CONTRACT_INSET_PX}, {MAX_CROSS_NS_CONTRACT_INSET_PX}], "
            f"got {ns_contract_inset_px}",
        )
    clear = (0, 0, 0, 0)
    img = Image.new("RGBA", (CROSS_CANVAS, CROSS_CANVAS), clear)
    top_k = edge_kind(nw, ne)
    bot_k = edge_kind(sw, se)
    left_k = edge_kind(nw, sw)
    right_k = edge_kind(ne, se)
    y_top = ns_contract_inset_px
    y_bot = TILE_SIZE * 2 - ns_contract_inset_px
    placements: dict[str, tuple[int, int, str]] = {
        "top": (CROSS_CENTER_OFF, y_top, top_k),
        "left": (0, CROSS_CENTER_OFF, left_k),
        "right": (TILE_SIZE * 2, CROSS_CENTER_OFF, right_k),
        "bottom": (CROSS_CENTER_OFF, y_bot, bot_k),
    }
    for edge, (x0, y0, kind) in placements.items():
        ck = contract_key_for_wang_edge(edge, kind)
        c = load_contract_image(cpaths[ck], ck, plains=plains, sea=sea, dry_run=dry_run)
        arm = arm_image_for_cross_arm(edge, c)
        img.paste(arm, (x0, y0), arm)
    if use_corner_hints:
        paste_cross_center_corner_hints(img, nw, ne, sw, se, plains, sea)
    return img


def _cross_center_corner_mask_blocks() -> tuple[tuple[int, int, int, int], ...]:
    h = CORNER_HINT_PX
    cx, cy = CROSS_CENTER_OFF, CROSS_CENTER_OFF
    return (
        (cx, cy, cx + h, cy + h),
        (cx + TILE_SIZE - h, cy, cx + TILE_SIZE, cy + h),
        (cx, cy + TILE_SIZE - h, cx + h, cy + TILE_SIZE),
        (cx + TILE_SIZE - h, cy + TILE_SIZE - h, cx + TILE_SIZE, cy + TILE_SIZE),
    )


def build_cross_inpaint_mask(
    inset: int,
    *,
    use_corner_hints: bool,
    ns_contract_inset_px: int,
) -> Image.Image:
    """
    L-mode: black keep; white inpaint = center 64×64, optionally excluding CORNER_HINT_PX corners
    when ``use_corner_hints`` is true, then optionally eroded by ``inset`` from the center boundary.
    When ``ns_contract_inset_px`` > 0, exclude the top/bottom ``ns_contract_inset_px`` rows of the
    center cell (overlapped by shifted N/S arms).
    """
    if inset < MIN_CROSS_INPAINT_INSET or inset > MAX_CROSS_INPAINT_INSET:
        raise ValueError(
            f"cross inset must be in [{MIN_CROSS_INPAINT_INSET}, {MAX_CROSS_INPAINT_INSET}]",
        )
    if (
        ns_contract_inset_px < MIN_CROSS_NS_CONTRACT_INSET_PX
        or ns_contract_inset_px > MAX_CROSS_NS_CONTRACT_INSET_PX
    ):
        raise ValueError(
            f"ns_contract_inset_px must be in "
            f"[{MIN_CROSS_NS_CONTRACT_INSET_PX}, {MAX_CROSS_NS_CONTRACT_INSET_PX}]",
        )
    mask = Image.new("L", (CROSS_CANVAS, CROSS_CANVAS), 0)
    px = mask.load()
    assert px is not None
    cx0, cy0 = CROSS_CENTER_OFF, CROSS_CENTER_OFF
    x1, y1 = cx0 + TILE_SIZE, cy0 + TILE_SIZE
    corner_boxes = _cross_center_corner_mask_blocks() if use_corner_hints else ()
    ns_top = cy0 + ns_contract_inset_px
    ns_bot = cy0 + TILE_SIZE - ns_contract_inset_px

    def in_corner_block(x: int, y: int) -> bool:
        for a, b, c, d in corner_boxes:
            if a <= x < c and b <= y < d:
                return True
        return False

    def in_ns_contract_overlap(y: int) -> bool:
        if ns_contract_inset_px <= 0:
            return False
        return y < ns_top or y >= ns_bot

    for y in range(cy0, y1):
        for x in range(cx0, x1):
            if in_corner_block(x, y):
                continue
            if in_ns_contract_overlap(y):
                continue
            lx, ly = x - cx0, y - cy0
            if inset > 0 and (
                lx < inset or ly < inset or lx >= TILE_SIZE - inset or ly >= TILE_SIZE - inset
            ):
                continue
            px[x, y] = 255
    if not mask_has_inpaint(mask):
        raise ValueError(
            "cross inpaint mask is empty (try smaller --cross-inpaint-inset, "
            "--cross-ns-contract-inset, or --cross-corner-hints off; combinations can erase the center)",
        )
    return mask


def crop_center_tile_from_cross_canvas(img: Image.Image) -> Image.Image:
    return img.crop(
        (
            CROSS_CENTER_OFF,
            CROSS_CENTER_OFF,
            CROSS_CENTER_OFF + TILE_SIZE,
            CROSS_CENTER_OFF + TILE_SIZE,
        ),
    )


def cross_intermediate_paths(inter_dir: Path, idx: int) -> tuple[Path, Path]:
    root = inter_dir / "cross"
    return root / f"composite_{idx:02d}.png", root / f"mask_{idx:02d}.png"


def write_wang_tile_intermediates(
    idx: int,
    *,
    compositing_mode: str,
    inter_dir: Path,
    edge_proto_root: Path,
    plains_img: Image.Image,
    sea_img: Image.Image,
    nw: bool,
    ne: bool,
    sw: bool,
    se: bool,
    contract_edge_depth: int,
    cross_inpaint_inset: int,
    cross_corner_hints: bool,
    cross_ns_contract_inset_px: int,
    dry_run: bool,
    rewrite_intermediates: bool,
) -> tuple[Path, Path]:
    """Write ``composite_{idx}.png`` + ``mask_{idx}.png`` (cross under ``intermediate/cross/``, strips under ``intermediate/``)."""
    use_cross = compositing_mode == "cross"
    cpaths = contract_paths(edge_proto_root)
    if use_cross:
        comp_path, mask_path = cross_intermediate_paths(inter_dir, idx)
        comp_path.parent.mkdir(parents=True, exist_ok=True)
    else:
        comp_path = inter_dir / f"composite_{idx:02d}.png"
        mask_path = inter_dir / f"mask_{idx:02d}.png"

    have_inter = comp_path.is_file() and mask_path.is_file()
    if have_inter and not rewrite_intermediates:
        print(f"[{idx:02d}] reuse intermediate {comp_path.name} {mask_path.name}", flush=True)
        return comp_path, mask_path

    inter_dir.mkdir(parents=True, exist_ok=True)
    if use_cross:
        composite = build_cross_composite(
            nw,
            ne,
            sw,
            se,
            cpaths=cpaths,
            plains=plains_img,
            sea=sea_img,
            dry_run=dry_run,
            use_corner_hints=cross_corner_hints,
            ns_contract_inset_px=cross_ns_contract_inset_px,
        )
        mask = build_cross_inpaint_mask(
            cross_inpaint_inset,
            use_corner_hints=cross_corner_hints,
            ns_contract_inset_px=cross_ns_contract_inset_px,
        )
        if not mask_has_inpaint(mask):
            print(f"[{idx:02d}] internal error: empty cross inpaint mask", file=sys.stderr)
            sys.exit(1)
    else:
        base_quad = build_composite_64(idx, plains_img, sea_img)
        composite = build_wang_composite_overlay_contracts(
            base_quad,
            nw,
            ne,
            sw,
            se,
            cpaths=cpaths,
            plains=plains_img,
            sea=sea_img,
            dry_run=dry_run,
            overlay_depth=contract_edge_depth,
        )
        mask = build_interior_rect_inpaint_mask(contract_edge_depth)
        if not mask_has_inpaint(mask):
            print(f"[{idx:02d}] internal error: empty interior inpaint mask", file=sys.stderr)
            sys.exit(1)

    composite.save(comp_path)
    mask.save(mask_path)
    print(f"[{idx:02d}] wrote intermediate {comp_path} {mask_path}", flush=True)
    return comp_path, mask_path


def decode_cross_job_to_tile_png(job_body: dict) -> bytes:
    raw_png = decode_result_png(job_body, width=CROSS_CANVAS, height=CROSS_CANVAS)
    img = Image.open(io.BytesIO(raw_png)).convert("RGBA")
    cropped = crop_center_tile_from_cross_canvas(img)
    buf = io.BytesIO()
    cropped.save(buf, format="PNG")
    return buf.getvalue()


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


def decode_result_png(job_body: dict, *, width: int, height: int) -> bytes:
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


def decode_job_edge_contract_pngs(job_body: dict, *, api_w: int, api_h: int) -> tuple[bytes, bytes]:
    """Return (full API frame PNG bytes, centre 64×64 contract PNG bytes)."""
    full_png = decode_result_png(job_body, width=api_w, height=api_h)
    img = Image.open(io.BytesIO(full_png)).convert("RGBA")
    cropped = crop_centre_contract_for_api_dims(img, api_w, api_h)
    buf = io.BytesIO()
    cropped.save(buf, format="PNG")
    return full_png, buf.getvalue()


def _job_status(job: dict) -> str:
    return str(job.get("status") or (job.get("data") or {}).get("status") or "unknown")


def poll_until_done_stuck_or_failed(
    api_key: str,
    job_id: str,
    *,
    interval_s: float,
    submitted_at: float,
    stuck_after_s: float,
) -> tuple[dict | None, str]:
    while True:
        if time.time() - submitted_at >= stuck_after_s:
            print(
                f"job_id={job_id!r} stuck: no completion within {stuck_after_s}s since submit",
                flush=True,
            )
            return None, "stuck"
        r = requests.get(
            f"{API_BASE}/background-jobs/{job_id}",
            headers={"Authorization": f"Bearer {api_key}"},
            timeout=60,
        )
        if r.status_code != 200:
            print(
                f"poll GET background-jobs -> HTTP {r.status_code} body={r.text[:300]!r}",
                flush=True,
            )
            time.sleep(interval_s)
            continue
        job = r.json()
        status = _job_status(job)
        print(f"poll job_id={job_id!r} status={status!r}", flush=True)
        if status in ("failed", "error"):
            print("Job failed:", json.dumps(job, indent=2)[:4000], file=sys.stderr)
            return None, "failed"
        if status == "completed":
            return job, "completed"
        time.sleep(interval_s)


def corners_to_json_labels(nw: bool, ne: bool, sw: bool, se: bool) -> dict[str, str]:
    def lab(p: bool) -> str:
        return "upper" if p else "lower"

    return {"NW": lab(nw), "NE": lab(ne), "SW": lab(sw), "SE": lab(se)}


def load_state(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {"version": 1, "tiles": {}}
    data = json.loads(path.read_text(encoding="utf-8"))
    if "tiles" not in data:
        data["tiles"] = {}
    data.setdefault("version", 1)
    return data


def save_state(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(data, indent=2), encoding="utf-8")
    tmp.replace(path)


def default_out_dir(repo_root: Path) -> Path:
    return repo_root / "app/assets/images/terrain/base_64/wang_inpaint_sea_plains_64"


def hetero_contract_job_specs(
    plains: Image.Image,
    sea: Image.Image,
    seam_band_px: int,
) -> list[tuple[str, str, Image.Image, Image.Image, int, int]]:
    """state_key, path_key, composite RGBA, mask L, api_w, api_h."""
    vmask = mask_vertical_seam_128x64(seam_band_px)
    hmask = mask_horizontal_seam_64x128(seam_band_px)
    return [
        (
            "contract_ps_lr",
            "ps_lr",
            build_hard_128_ps(plains, sea),
            vmask.copy(),
            COMPOSITE_W,
            COMPOSITE_H,
        ),
        (
            "contract_ps_rl",
            "ps_rl",
            build_composite_128_pair(sea, plains),
            vmask.copy(),
            COMPOSITE_W,
            COMPOSITE_H,
        ),
        (
            "contract_ps_td",
            "ps_td",
            build_composite_64_vertical(plains, sea),
            hmask.copy(),
            COMPOSITE_V_W,
            COMPOSITE_V_H,
        ),
        (
            "contract_ps_bt",
            "ps_bt",
            build_composite_64_vertical(sea, plains),
            hmask.copy(),
            COMPOSITE_V_W,
            COMPOSITE_V_H,
        ),
        (
            "contract_sp_lr",
            "sp_lr",
            build_composite_128_pair(sea, plains),
            vmask.copy(),
            COMPOSITE_W,
            COMPOSITE_H,
        ),
        (
            "contract_sp_rl",
            "sp_rl",
            build_hard_128_ps(plains, sea),
            vmask.copy(),
            COMPOSITE_W,
            COMPOSITE_H,
        ),
        (
            "contract_sp_td",
            "sp_td",
            build_composite_64_vertical(sea, plains),
            hmask.copy(),
            COMPOSITE_V_W,
            COMPOSITE_V_H,
        ),
        (
            "contract_sp_bt",
            "sp_bt",
            build_composite_64_vertical(plains, sea),
            hmask.copy(),
            COMPOSITE_V_W,
            COMPOSITE_V_H,
        ),
    ]


def ensure_edge_contracts(
    api_key: str | None,
    *,
    plains: Image.Image,
    sea: Image.Image,
    edge_proto_root: Path,
    state: dict[str, Any],
    state_path: Path,
    edge_description: str,
    poll_interval: float,
    stuck_after_s: float,
    crop_to_mask: bool,
    rewrite: bool,
    seam_band_px: int,
    dry_run: bool = False,
    only_hetero_path_key: str | None = None,
) -> dict[str, Path]:
    """
    Build pp/ss plus eight heterogeneous 64×64 contracts under edge_proto_root/contracts_128/.
    Each ps_* / sp_* is an independent inpaint-v3 job (no runtime rotation or mirroring).

    If ``only_hetero_path_key`` is set, only that path key (e.g. ``ps_td``) is generated; pp/ss are
    still written if missing.
    """
    edge_proto_root.mkdir(parents=True, exist_ok=True)
    sub = contracts_subdir(edge_proto_root)
    sub.mkdir(parents=True, exist_ok=True)
    paths = contract_paths(edge_proto_root)
    ec = state.setdefault("edge_contracts", {})

    def write_pp_ss() -> None:
        plains.copy().save(paths["pp"])
        sea.copy().save(paths["ss"])
        print(
            "edge contracts: wrote contract_pp_lr.png contract_ss_lr.png (base tile copy, no seam)",
            flush=True,
        )

    if rewrite or not paths["pp"].is_file():
        write_pp_ss()
    elif not paths["ss"].is_file():
        write_pp_ss()

    if dry_run:
        print(
            "edge contracts: dry-run — synthetic heterogeneous centre crops if missing",
            flush=True,
        )
        for _sk, pk, comp_im, msk_im, _aw, _ah in hetero_contract_job_specs(plains, sea, seam_band_px):
            if only_hetero_path_key is not None and pk != only_hetero_path_key:
                continue
            p_out = paths[pk]
            if rewrite or not p_out.is_file():
                in_p, mask_p, _out_p = edge_contract_inpaint_io_paths(sub, pk)
                in_p.parent.mkdir(parents=True, exist_ok=True)
                comp_im.save(in_p)
                msk_im.save(mask_p)
                synthetic_hetero_contract(pk, plains, sea).save(p_out)
        save_state(state_path, state)
        return paths

    if api_key is None:
        print("API key required for P↔S contract inpaint (omit --dry-run)", file=sys.stderr)
        sys.exit(1)

    for state_key, path_key, comp_img, msk, api_w, api_h in hetero_contract_job_specs(
        plains, sea, seam_band_px
    ):
        if only_hetero_path_key is not None and path_key != only_hetero_path_key:
            continue
        p_out = paths[path_key]
        ent = ec.get(state_key, {}) if isinstance(ec.get(state_key), dict) else {}
        need_inpaint = rewrite or not p_out.is_file() or ent.get("phase") in ("stuck", "failed")

        if not need_inpaint:
            continue

        in_png, mask_png, out_png = edge_contract_inpaint_io_paths(sub, path_key)
        in_png.parent.mkdir(parents=True, exist_ok=True)
        comp_img.save(in_png)
        msk.save(mask_png)

        job_id = ent.get("job_id")
        sub_at = ent.get("submitted_at")
        ph = ent.get("phase")

        if (
            job_id
            and isinstance(sub_at, (int, float))
            and ph == "polling"
            and time.time() - float(sub_at) < stuck_after_s
        ):
            aw = int(ent.get("api_width", api_w))
            ah = int(ent.get("api_height", api_h))
            print(f"edge contract {state_key}: resume poll job_id={job_id!r}", flush=True)
            completed, outcome = poll_until_done_stuck_or_failed(
                api_key,
                str(job_id),
                interval_s=poll_interval,
                submitted_at=float(sub_at),
                stuck_after_s=stuck_after_s,
            )
            if outcome == "completed" and completed is not None:
                full_png, centre_png = decode_job_edge_contract_pngs(
                    completed, api_w=aw, api_h=ah
                )
                out_png.write_bytes(full_png)
                p_out.write_bytes(centre_png)
                ec[state_key] = {
                    "phase": "done",
                    "job_id": job_id,
                    "completed_at": time.time(),
                    "path": str(p_out.resolve()),
                }
                save_state(state_path, state)
                continue
            if outcome == "stuck":
                ec[state_key] = {**ent, "phase": "stuck", "last_stuck_at": time.time()}
                save_state(state_path, state)
                print(f"edge contract {state_key}: stuck; rerun to resubmit", flush=True)
                sys.exit(1)
            ec[state_key] = {**ent, "phase": "failed", "failed_at": time.time()}
            save_state(state_path, state)
            print(f"edge contract {state_key}: failed during resume poll", file=sys.stderr)
            sys.exit(1)

        print(
            f"edge contract {state_key}: submitting inpaint-v3 ({api_w}×{api_h}) → centre 64×64 ...",
            flush=True,
        )
        new_id = submit_inpaint_v3(
            api_key,
            description=edge_description,
            composite_path=in_png.resolve(),
            mask_path=mask_png.resolve(),
            width=api_w,
            height=api_h,
            crop_to_mask=crop_to_mask,
        )
        now = time.time()
        ec[state_key] = {
            "phase": "polling",
            "job_id": new_id,
            "submitted_at": now,
            "api_width": api_w,
            "api_height": api_h,
        }
        save_state(state_path, state)

        completed, outcome = poll_until_done_stuck_or_failed(
            api_key,
            new_id,
            interval_s=poll_interval,
            submitted_at=now,
            stuck_after_s=stuck_after_s,
        )
        if outcome == "completed" and completed is not None:
            full_png, centre_png = decode_job_edge_contract_pngs(
                completed, api_w=api_w, api_h=api_h
            )
            out_png.write_bytes(full_png)
            p_out.write_bytes(centre_png)
            ec[state_key] = {
                "phase": "done",
                "job_id": new_id,
                "submitted_at": now,
                "completed_at": time.time(),
                "path": str(p_out.resolve()),
            }
            save_state(state_path, state)
            continue

        if outcome == "stuck":
            ec[state_key] = {**ec[state_key], "phase": "stuck", "last_stuck_at": time.time()}
            save_state(state_path, state)
            print(f"edge contract {state_key}: stuck after submit; rerun to resubmit", flush=True)
            sys.exit(1)

        ec[state_key] = {**ec[state_key], "phase": "failed", "failed_at": time.time()}
        save_state(state_path, state)
        print(f"edge contract {state_key}: failed after submit", file=sys.stderr)
        sys.exit(1)

    save_state(state_path, state)
    return paths


def process_one_tile(
    api_key: str | None,
    idx: int,
    *,
    plains_path: Path,
    sea_path: Path,
    inter_dir: Path,
    out_dir: Path,
    edge_proto_root: Path,
    contract_edge_depth: int,
    compositing_mode: str,
    cross_inpaint_inset: int,
    cross_corner_hints: bool,
    cross_ns_contract_inset_px: int,
    state: dict[str, Any],
    state_path: Path,
    description: str,
    poll_interval: float,
    stuck_after_s: float,
    crop_to_mask: bool,
    dry_run: bool,
    force: bool,
    rewrite_intermediates: bool,
) -> None:
    key = str(idx)
    tiles: dict[str, Any] = state["tiles"]
    entry = tiles.get(key, {})
    out_png = out_dir / f"tile_{idx:02d}.png"
    use_cross = compositing_mode == "cross"

    if out_png.is_file() and not force:
        print(f"[{idx:02d}] skip: output exists {out_png}", flush=True)
        tiles[key] = {
            **entry,
            "wang_index": idx,
            "phase": "done",
            "output": str(out_png.resolve()),
            "job_id": entry.get("job_id"),
            "compositing_mode": entry.get("compositing_mode", compositing_mode),
        }
        save_state(state_path, state)
        return

    source_idx, d4_transpose = WANG_D4_CANONICAL_SOURCE[idx]
    nw, ne, sw, se = wang_index_to_corners(idx)
    corner_labels = corners_to_json_labels(nw, ne, sw, se)

    if source_idx != idx:
        inter_dir.mkdir(parents=True, exist_ok=True)
        out_dir.mkdir(parents=True, exist_ok=True)
        src_png = out_dir / f"tile_{source_idx:02d}.png"
        if not dry_run and not src_png.is_file():
            print(
                f"[{idx:02d}] missing source tile {src_png.name}; generate canonical "
                f"wang_index={source_idx} first (--only {source_idx})",
                file=sys.stderr,
            )
            sys.exit(1)
        plains_der = Image.open(plains_path).convert("RGBA")
        sea_der = Image.open(sea_path).convert("RGBA")
        if plains_der.size != (TILE_SIZE, TILE_SIZE) or sea_der.size != (TILE_SIZE, TILE_SIZE):
            print("plains and sea bases must be 64×64", file=sys.stderr)
            sys.exit(1)
        comp_path_d, mask_path_d = write_wang_tile_intermediates(
            idx,
            compositing_mode=compositing_mode,
            inter_dir=inter_dir,
            edge_proto_root=edge_proto_root,
            plains_img=plains_der,
            sea_img=sea_der,
            nw=nw,
            ne=ne,
            sw=sw,
            se=se,
            contract_edge_depth=contract_edge_depth,
            cross_inpaint_inset=cross_inpaint_inset,
            cross_corner_hints=cross_corner_hints,
            cross_ns_contract_inset_px=cross_ns_contract_inset_px,
            dry_run=dry_run,
            rewrite_intermediates=rewrite_intermediates,
        )
        if dry_run:
            tiles[key] = {
                "wang_index": idx,
                "phase": "dry_run",
                "d4_derived_from": source_idx,
                "d4_transpose": d4_transpose,
                "source_tile": str(src_png.resolve()),
                "corners": corner_labels,
                "composite": str(comp_path_d.resolve()),
                "mask": str(mask_path_d.resolve()),
                "note": "would transpose canonical tile (no inpaint)",
            }
            save_state(state_path, state)
            print(
                f"[{idx:02d}] dry-run: derive from tile_{source_idx:02d} via {d4_transpose}",
                flush=True,
            )
            return
        derived = apply_wang_d4_transpose(Image.open(src_png).convert("RGBA"), d4_transpose)
        derived.save(out_png)
        tiles[key] = {
            "wang_index": idx,
            "phase": "done",
            "output": str(out_png.resolve()),
            "d4_derived_from": source_idx,
            "d4_transpose": d4_transpose,
            "source_tile": str(src_png.resolve()),
            "corners": corner_labels,
            "compositing_mode": "derived_d4",
            "composite": str(comp_path_d.resolve()),
            "mask": str(mask_path_d.resolve()),
            "note": "D4 symmetry: oriented copy of canonical tile (no inpaint job)",
        }
        save_state(state_path, state)
        print(f"[{idx:02d}] wrote derived {d4_transpose} from tile_{source_idx:02d} -> {out_png}", flush=True)
        return

    plains_img = Image.open(plains_path).convert("RGBA")
    sea_img = Image.open(sea_path).convert("RGBA")
    if plains_img.size != (TILE_SIZE, TILE_SIZE) or sea_img.size != (TILE_SIZE, TILE_SIZE):
        print("plains and sea bases must be 64×64", file=sys.stderr)
        sys.exit(1)

    if idx == 0 and dry_run:
        tiles[key] = {
            "wang_index": idx,
            "phase": "dry_run",
            "note": "would copy sea base to tile_00.png",
            "corners": corners_to_json_labels(False, False, False, False),
        }
        save_state(state_path, state)
        print(f"[{idx:02d}] dry-run: would write uniform sea -> {out_png.name}", flush=True)
        return
    if idx == 15 and dry_run:
        tiles[key] = {
            "wang_index": idx,
            "phase": "dry_run",
            "note": "would copy plains base to tile_15.png",
            "corners": corners_to_json_labels(True, True, True, True),
        }
        save_state(state_path, state)
        print(f"[{idx:02d}] dry-run: would write uniform plains -> {out_png.name}", flush=True)
        return

    if idx == 0:
        inter_dir.mkdir(parents=True, exist_ok=True)
        out_dir.mkdir(parents=True, exist_ok=True)
        sea_img.save(out_png)
        comp_u, mask_u = write_wang_tile_intermediates(
            idx,
            compositing_mode=compositing_mode,
            inter_dir=inter_dir,
            edge_proto_root=edge_proto_root,
            plains_img=plains_img,
            sea_img=sea_img,
            nw=nw,
            ne=ne,
            sw=sw,
            se=se,
            contract_edge_depth=contract_edge_depth,
            cross_inpaint_inset=cross_inpaint_inset,
            cross_corner_hints=cross_corner_hints,
            cross_ns_contract_inset_px=cross_ns_contract_inset_px,
            dry_run=False,
            rewrite_intermediates=rewrite_intermediates,
        )
        tiles[key] = {
            "wang_index": idx,
            "phase": "done",
            "output": str(out_png.resolve()),
            "job_id": None,
            "corners": corners_to_json_labels(False, False, False, False),
            "composite": str(comp_u.resolve()),
            "mask": str(mask_u.resolve()),
            "note": "uniform sea — base tile copy",
        }
        save_state(state_path, state)
        print(f"[{idx:02d}] wrote uniform sea -> {out_png}", flush=True)
        return
    if idx == 15:
        inter_dir.mkdir(parents=True, exist_ok=True)
        out_dir.mkdir(parents=True, exist_ok=True)
        plains_img.save(out_png)
        comp_u, mask_u = write_wang_tile_intermediates(
            idx,
            compositing_mode=compositing_mode,
            inter_dir=inter_dir,
            edge_proto_root=edge_proto_root,
            plains_img=plains_img,
            sea_img=sea_img,
            nw=nw,
            ne=ne,
            sw=sw,
            se=se,
            contract_edge_depth=contract_edge_depth,
            cross_inpaint_inset=cross_inpaint_inset,
            cross_corner_hints=cross_corner_hints,
            cross_ns_contract_inset_px=cross_ns_contract_inset_px,
            dry_run=False,
            rewrite_intermediates=rewrite_intermediates,
        )
        tiles[key] = {
            "wang_index": idx,
            "phase": "done",
            "output": str(out_png.resolve()),
            "job_id": None,
            "corners": corners_to_json_labels(True, True, True, True),
            "composite": str(comp_u.resolve()),
            "mask": str(mask_u.resolve()),
            "note": "uniform plains — base tile copy",
        }
        save_state(state_path, state)
        print(f"[{idx:02d}] wrote uniform plains -> {out_png}", flush=True)
        return

    inter_dir.mkdir(parents=True, exist_ok=True)
    out_dir.mkdir(parents=True, exist_ok=True)

    comp_path, mask_path = write_wang_tile_intermediates(
        idx,
        compositing_mode=compositing_mode,
        inter_dir=inter_dir,
        edge_proto_root=edge_proto_root,
        plains_img=plains_img,
        sea_img=sea_img,
        nw=nw,
        ne=ne,
        sw=sw,
        se=se,
        contract_edge_depth=contract_edge_depth,
        cross_inpaint_inset=cross_inpaint_inset,
        cross_corner_hints=cross_corner_hints,
        cross_ns_contract_inset_px=cross_ns_contract_inset_px,
        dry_run=dry_run,
        rewrite_intermediates=rewrite_intermediates,
    )

    if dry_run:
        tiles[key] = {
            "wang_index": idx,
            "phase": "dry_run",
            "compositing_mode": compositing_mode,
            "cross_corner_hints": cross_corner_hints if use_cross else None,
            "cross_ns_contract_inset_px": cross_ns_contract_inset_px if use_cross else None,
            "composite": str(comp_path.resolve()),
            "mask": str(mask_path.resolve()),
            "corners": corner_labels,
        }
        save_state(state_path, state)
        print(f"[{idx:02d}] dry-run: no API call", flush=True)
        return

    if api_key is None:
        print("API key required unless --dry-run", file=sys.stderr)
        sys.exit(1)

    if use_cross:
        cross_job_id = entry.get("cross_job_id")
        cross_submitted_at = entry.get("cross_submitted_at")
        phase = entry.get("phase")
        if (
            cross_job_id
            and isinstance(cross_submitted_at, (int, float))
            and phase == "cross_polling"
            and entry.get("compositing_mode") == "cross"
            and bool(entry.get("cross_corner_hints", True)) == cross_corner_hints
            and int(entry.get("cross_ns_contract_inset_px", 0)) == cross_ns_contract_inset_px
            and time.time() - float(cross_submitted_at) < stuck_after_s
        ):
            print(f"[{idx:02d}] resuming cross poll cross_job_id={cross_job_id!r}", flush=True)
            completed, outcome = poll_until_done_stuck_or_failed(
                api_key,
                str(cross_job_id),
                interval_s=poll_interval,
                submitted_at=float(cross_submitted_at),
                stuck_after_s=stuck_after_s,
            )
            if outcome == "completed" and completed is not None:
                png = decode_cross_job_to_tile_png(completed)
                out_png.write_bytes(png)
                tiles[key] = {
                    "wang_index": idx,
                    "phase": "done",
                    "compositing_mode": "cross",
                    "cross_corner_hints": cross_corner_hints,
                    "cross_ns_contract_inset_px": cross_ns_contract_inset_px,
                    "output": str(out_png.resolve()),
                    "cross_job_id": cross_job_id,
                    "cross_submitted_at": cross_submitted_at,
                    "completed_at": time.time(),
                    "corners": corner_labels,
                    "composite": str(comp_path.resolve()),
                    "mask": str(mask_path.resolve()),
                    "api_width": CROSS_CANVAS,
                    "api_height": CROSS_CANVAS,
                }
                save_state(state_path, state)
                print(f"[{idx:02d}] wrote {out_png}", flush=True)
                return
            if outcome == "stuck":
                stuck_n = int(entry.get("cross_stuck_resubmit_count", 0)) + 1
                tiles[key] = {
                    **entry,
                    "phase": "cross_stuck",
                    "wang_index": idx,
                    "last_stuck_at": time.time(),
                    "cross_stuck_resubmit_count": stuck_n,
                    "corners": corner_labels,
                    "composite": str(comp_path.resolve()),
                    "mask": str(mask_path.resolve()),
                }
                save_state(state_path, state)
            elif outcome == "failed":
                tiles[key] = {
                    **entry,
                    "phase": "cross_failed",
                    "wang_index": idx,
                    "failed_at": time.time(),
                    "corners": corner_labels,
                }
                save_state(state_path, state)
                print(
                    f"[{idx:02d}] cross job failed during resume poll; continue (--only {idx} to retry)",
                    file=sys.stderr,
                )
                return

        print(f"[{idx:02d}] submitting inpaint-v3 (cross 192×192) ...", flush=True)
        new_job_id = submit_inpaint_v3(
            api_key,
            description=description,
            composite_path=comp_path.resolve(),
            mask_path=mask_path.resolve(),
            width=CROSS_CANVAS,
            height=CROSS_CANVAS,
            crop_to_mask=crop_to_mask,
        )
        now = time.time()
        tiles[key] = {
            "wang_index": idx,
            "phase": "cross_polling",
            "compositing_mode": "cross",
            "cross_corner_hints": cross_corner_hints,
            "cross_ns_contract_inset_px": cross_ns_contract_inset_px,
            "cross_job_id": new_job_id,
            "cross_submitted_at": now,
            "corners": corner_labels,
            "composite": str(comp_path.resolve()),
            "mask": str(mask_path.resolve()),
            "api_width": CROSS_CANVAS,
            "api_height": CROSS_CANVAS,
        }
        save_state(state_path, state)
        print(f"[{idx:02d}] cross_job_id={new_job_id!r} submitted_at={now}", flush=True)

        completed, outcome = poll_until_done_stuck_or_failed(
            api_key,
            new_job_id,
            interval_s=poll_interval,
            submitted_at=now,
            stuck_after_s=stuck_after_s,
        )
        if outcome == "completed" and completed is not None:
            png = decode_cross_job_to_tile_png(completed)
            out_png.write_bytes(png)
            tiles[key] = {
                "wang_index": idx,
                "phase": "done",
                "compositing_mode": "cross",
                "cross_corner_hints": cross_corner_hints,
                "cross_ns_contract_inset_px": cross_ns_contract_inset_px,
                "output": str(out_png.resolve()),
                "cross_job_id": new_job_id,
                "cross_submitted_at": now,
                "completed_at": time.time(),
                "corners": corner_labels,
                "composite": str(comp_path.resolve()),
                "mask": str(mask_path.resolve()),
                "api_width": CROSS_CANVAS,
                "api_height": CROSS_CANVAS,
            }
            save_state(state_path, state)
            print(f"[{idx:02d}] wrote {out_png}", flush=True)
            return

        if outcome == "stuck":
            prev_stuck = int(tiles[key].get("cross_stuck_resubmit_count", 0))
            tiles[key] = {
                **tiles[key],
                "phase": "cross_stuck",
                "last_stuck_at": time.time(),
                "cross_stuck_resubmit_count": prev_stuck + 1,
            }
            save_state(state_path, state)
            print(f"[{idx:02d}] cross marked stuck; rerun to resubmit", flush=True)
            return

        tiles[key] = {**tiles[key], "phase": "cross_failed", "failed_at": time.time()}
        save_state(state_path, state)
        print(
            f"[{idx:02d}] cross job failed after submit; continue (--only {idx} to retry)",
            file=sys.stderr,
        )
        return

    job_id = entry.get("job_id")
    submitted_at = entry.get("submitted_at")
    phase = entry.get("phase")

    if (
        job_id
        and isinstance(submitted_at, (int, float))
        and phase == "polling"
        and entry.get("compositing_mode", "strips") == "strips"
        and time.time() - float(submitted_at) < stuck_after_s
    ):
        print(f"[{idx:02d}] resuming poll job_id={job_id!r}", flush=True)
        completed, outcome = poll_until_done_stuck_or_failed(
            api_key,
            job_id,
            interval_s=poll_interval,
            submitted_at=float(submitted_at),
            stuck_after_s=stuck_after_s,
        )
        if outcome == "completed" and completed is not None:
            png = decode_result_png(completed, width=TILE_SIZE, height=TILE_SIZE)
            out_png.write_bytes(png)
            tiles[key] = {
                "wang_index": idx,
                "phase": "done",
                "compositing_mode": "strips",
                "output": str(out_png.resolve()),
                "job_id": job_id,
                "submitted_at": submitted_at,
                "completed_at": time.time(),
                "corners": corner_labels,
                "composite": str(comp_path.resolve()),
                "mask": str(mask_path.resolve()),
            }
            save_state(state_path, state)
            print(f"[{idx:02d}] wrote {out_png}", flush=True)
            return
        if outcome == "stuck":
            stuck_n = int(entry.get("stuck_resubmit_count", 0)) + 1
            tiles[key] = {
                **entry,
                "phase": "stuck",
                "wang_index": idx,
                "last_stuck_at": time.time(),
                "stuck_resubmit_count": stuck_n,
                "corners": corner_labels,
                "composite": str(comp_path.resolve()),
                "mask": str(mask_path.resolve()),
            }
            save_state(state_path, state)
        elif outcome == "failed":
            tiles[key] = {
                **entry,
                "phase": "failed",
                "wang_index": idx,
                "failed_at": time.time(),
                "corners": corner_labels,
            }
            save_state(state_path, state)
            print(f"[{idx:02d}] job failed during resume poll; continue (--only {idx} to retry)", flush=True)
            return

    print(f"[{idx:02d}] submitting inpaint-v3 ...", flush=True)
    new_job_id = submit_inpaint_v3(
        api_key,
        description=description,
        composite_path=comp_path.resolve(),
        mask_path=mask_path.resolve(),
        width=TILE_SIZE,
        height=TILE_SIZE,
        crop_to_mask=crop_to_mask,
    )
    now = time.time()
    tiles[key] = {
        "wang_index": idx,
        "phase": "polling",
        "compositing_mode": "strips",
        "job_id": new_job_id,
        "submitted_at": now,
        "corners": corner_labels,
        "composite": str(comp_path.resolve()),
        "mask": str(mask_path.resolve()),
    }
    save_state(state_path, state)
    print(f"[{idx:02d}] job_id={new_job_id!r} submitted_at={now}", flush=True)

    completed, outcome = poll_until_done_stuck_or_failed(
        api_key,
        new_job_id,
        interval_s=poll_interval,
        submitted_at=now,
        stuck_after_s=stuck_after_s,
    )
    if outcome == "completed" and completed is not None:
        png = decode_result_png(completed, width=TILE_SIZE, height=TILE_SIZE)
        out_png.write_bytes(png)
        tiles[key] = {
            "wang_index": idx,
            "phase": "done",
            "compositing_mode": "strips",
            "output": str(out_png.resolve()),
            "job_id": new_job_id,
            "submitted_at": now,
            "completed_at": time.time(),
            "corners": corner_labels,
            "composite": str(comp_path.resolve()),
            "mask": str(mask_path.resolve()),
        }
        save_state(state_path, state)
        print(f"[{idx:02d}] wrote {out_png}", flush=True)
        return

    if outcome == "stuck":
        prev_stuck = int(tiles[key].get("stuck_resubmit_count", 0))
        tiles[key] = {
            **tiles[key],
            "phase": "stuck",
            "last_stuck_at": time.time(),
            "stuck_resubmit_count": prev_stuck + 1,
        }
        save_state(state_path, state)
        print(f"[{idx:02d}] marked stuck; rerun to resubmit", flush=True)
        return

    tiles[key] = {**tiles[key], "phase": "failed", "failed_at": time.time()}
    save_state(state_path, state)
    print(f"[{idx:02d}] job failed after submit; continue (--only {idx} to retry)", flush=True)


def parse_only(s: str) -> set[int] | None:
    if not s.strip():
        return None
    out: set[int] = set()
    for part in s.split(","):
        part = part.strip()
        if not part:
            continue
        v = int(part)
        if not 0 <= v <= 15:
            print(f"--only value out of range 0-15: {v}", file=sys.stderr)
            sys.exit(1)
        out.add(v)
    return out


def print_wang_d4_symmetry_table() -> None:
    print(
        "Two-terrain corner Wang: 16 corner assignments; D4 (90° rotations + flips) → 6 orbits.\n",
        flush=True,
    )
    print(
        f"  Orbit representatives (generate once): {sorted(WANG_D4_ORBIT_REPRESENTATIVES)}",
        flush=True,
    )
    print(
        f"  Inpaint-v3 (mixed tiles): {sorted(WANG_INDICES_REQUIRE_INPAINT_API)}",
        flush=True,
    )
    print(
        f"  Uniform base copies (no inpaint): {sorted({0, 15})}\n",
        flush=True,
    )
    print("  wang_index → (source, PIL transpose)  [source = canonical in orbit]", flush=True)
    for i in range(16):
        src, op = WANG_D4_CANONICAL_SOURCE[i]
        if wang_d4_is_derived_index(i):
            role = "derive"
        elif i in WANG_INDICES_REQUIRE_INPAINT_API:
            role = "inpaint"
        else:
            role = "uniform_base"
        print(f"    {i:2d}  ({src:2d}, {op:17s})  {role}", flush=True)


def main() -> None:
    repo = Path(__file__).resolve().parent.parent
    default_b64 = repo / "app/assets/images/terrain/base_64"
    parser = argparse.ArgumentParser(
        description="Resumable 16-tile sea↔plains Wang inpaint at 64×64 (inpaint-v3)",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=default_out_dir(repo),
        help="Output root (intermediate/, out/, wang_inpaint_state.json)",
    )
    parser.add_argument(
        "--plains",
        type=Path,
        default=default_b64 / "plains_base_64.png",
        help="64×64 plains base PNG",
    )
    parser.add_argument(
        "--sea",
        type=Path,
        default=default_b64 / "sea_base_64.png",
        help="64×64 sea base PNG",
    )
    parser.add_argument(
        "--state-file",
        type=Path,
        default=None,
        help="Defaults to <out-dir>/wang_inpaint_state.json",
    )
    parser.add_argument("--description", type=str, default=DEFAULT_DESCRIPTION)
    parser.add_argument(
        "--edge-contract-description",
        type=str,
        default=DEFAULT_EDGE_CONTRACT_DESCRIPTION,
        help="inpaint-v3 text for heterogeneous edge contracts only (default: sharp cliff-style seam)",
    )
    parser.add_argument("--poll-interval", type=float, default=8.0)
    parser.add_argument(
        "--stuck-after-seconds",
        type=float,
        default=300.0,
        help="If job not completed within this wall time from submit, mark stuck and exit tile",
    )
    parser.add_argument(
        "--crop-to-mask",
        action=argparse.BooleanOptionalAction,
        default=True,
        help=(
            "inpaint-v3 crop_to_mask (default: true): constrain generation to masked regions for "
            "correct edge seams; use --no-crop-to-mask for legacy full-frame behavior"
        ),
    )
    parser.add_argument(
        "--only",
        type=str,
        default="",
        help="Comma-separated wang_index 0-15 to process",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Only write composites/masks; no API",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Regenerate even if tile output already exists",
    )
    parser.add_argument(
        "--rewrite-intermediates",
        action=argparse.BooleanOptionalAction,
        default=True,
        help=(
            "Rebuild composite/mask PNGs when generating each Wang tile (default: on); "
            "--no-rewrite-intermediates reuses existing composite_XX/mask_XX if present"
        ),
    )
    parser.add_argument(
        "--contract-edge-depth",
        type=int,
        default=DEFAULT_CONTRACT_EDGE_DEPTH,
        help=(
            f"Px strip taken from each contract edge and pasted on the Wang tile; inpaint mask is the "
            f"interior rectangle not covered by those strips ({MIN_CONTRACT_EDGE_DEPTH}-{MAX_CONTRACT_EDGE_DEPTH})"
        ),
    )
    parser.add_argument(
        "--contract-seam-band",
        type=int,
        default=DEFAULT_CONTRACT_SEAM_BAND_PX,
        help=(
            f"Edge-contract inpaint only: white band width (128×64 vertical strip / 64×128 horizontal strip) "
            f"centered on the terrain seam ({MIN_CONTRACT_SEAM_BAND_PX}-{MAX_CONTRACT_SEAM_BAND_PX} px)"
        ),
    )
    parser.add_argument(
        "--rewrite-edge-prototypes",
        action="store_true",
        help="Regenerate contracts in contracts_128/ (pp/ss + eight independent P↔S inpaint jobs)",
    )
    parser.add_argument(
        "--edge-prototypes-only",
        action="store_true",
        help="Only generate contracts_128/ (no Wang tiles); --dry-run uses hard crops + synthetic ps/sp",
    )
    parser.add_argument(
        "--only-edge-contract",
        type=str,
        default="",
        metavar="KEY",
        help=(
            "With --edge-prototypes-only: generate exactly one heterogeneous contract "
            f"({', '.join(sorted(HETERO_EDGE_CONTRACT_PATH_KEYS))}). "
            "Writes pp/ss if missing. Omit to run all eight P↔S jobs in sequence."
        ),
    )
    parser.add_argument(
        "--skip-edge-prototypes",
        action="store_true",
        help="Skip contract generation; require pp/ss + eight heterogeneous contract_*.png",
    )
    parser.add_argument(
        "--compositing-mode",
        type=str,
        choices=("strips", "cross"),
        default="cross",
        help=(
            "cross (default): 192×192 cross layout, inpaint center (cross_polling / cross_job_id); "
            "optional --cross-corner-hints. strips: 64×64 quadrant + contract strips (polling / job_id)"
        ),
    )
    parser.add_argument(
        "--cross-corner-hints",
        action=argparse.BooleanOptionalAction,
        default=False,
        help=(
            f"Cross mode: paste opaque {CORNER_HINT_PX}×{CORNER_HINT_PX} base crops at center-cell corners "
            f"and exclude them from the inpaint mask (default: off)"
        ),
    )
    parser.add_argument(
        "--cross-inpaint-inset",
        type=int,
        default=DEFAULT_CROSS_INPAINT_INSET,
        help=(
            "Cross mode only: shrink white inpaint from center-cell boundary by this many px "
            f"({MIN_CROSS_INPAINT_INSET}-{MAX_CROSS_INPAINT_INSET}); after corner-hint exclusion when "
            "--cross-corner-hints is on"
        ),
    )
    parser.add_argument(
        "--cross-ns-contract-inset",
        type=int,
        default=DEFAULT_CROSS_NS_CONTRACT_INSET_PX,
        metavar="PX",
        help=(
            "Cross mode only: shift N and S 64×64 contract arms toward the center by this many px "
            f"(default {DEFAULT_CROSS_NS_CONTRACT_INSET_PX}, range "
            f"{MIN_CROSS_NS_CONTRACT_INSET_PX}-{MAX_CROSS_NS_CONTRACT_INSET_PX}); "
            "overlapping center rows are excluded from the inpaint mask"
        ),
    )
    parser.add_argument(
        "--show-d4-symmetry",
        action="store_true",
        help="Print D4 orbit map (which indices inpaint vs derive) and exit",
    )
    args = parser.parse_args()

    if args.show_d4_symmetry:
        print_wang_d4_symmetry_table()
        return

    if args.edge_prototypes_only and args.skip_edge_prototypes:
        print("Cannot combine --edge-prototypes-only with --skip-edge-prototypes", file=sys.stderr)
        sys.exit(1)
    if args.skip_edge_prototypes and args.rewrite_edge_prototypes:
        print("Cannot combine --skip-edge-prototypes with --rewrite-edge-prototypes", file=sys.stderr)
        sys.exit(1)

    if not MIN_CONTRACT_EDGE_DEPTH <= args.contract_edge_depth <= MAX_CONTRACT_EDGE_DEPTH:
        print(
            f"--contract-edge-depth must be in [{MIN_CONTRACT_EDGE_DEPTH}, {MAX_CONTRACT_EDGE_DEPTH}], "
            f"got {args.contract_edge_depth}",
            file=sys.stderr,
        )
        sys.exit(1)

    if not MIN_CROSS_INPAINT_INSET <= args.cross_inpaint_inset <= MAX_CROSS_INPAINT_INSET:
        print(
            f"--cross-inpaint-inset must be in [{MIN_CROSS_INPAINT_INSET}, {MAX_CROSS_INPAINT_INSET}], "
            f"got {args.cross_inpaint_inset}",
            file=sys.stderr,
        )
        sys.exit(1)

    if not (
        MIN_CROSS_NS_CONTRACT_INSET_PX
        <= args.cross_ns_contract_inset
        <= MAX_CROSS_NS_CONTRACT_INSET_PX
    ):
        print(
            f"--cross-ns-contract-inset must be in "
            f"[{MIN_CROSS_NS_CONTRACT_INSET_PX}, {MAX_CROSS_NS_CONTRACT_INSET_PX}], "
            f"got {args.cross_ns_contract_inset}",
            file=sys.stderr,
        )
        sys.exit(1)

    if (
        args.contract_seam_band < MIN_CONTRACT_SEAM_BAND_PX
        or args.contract_seam_band > MAX_CONTRACT_SEAM_BAND_PX
    ):
        print(
            f"--contract-seam-band must be in [{MIN_CONTRACT_SEAM_BAND_PX}, {MAX_CONTRACT_SEAM_BAND_PX}], "
            f"got {args.contract_seam_band}",
            file=sys.stderr,
        )
        sys.exit(1)

    if args.edge_prototypes_only and args.only.strip():
        print("Note: --only is ignored with --edge-prototypes-only", flush=True)

    only_edge_contract = args.only_edge_contract.strip()
    if only_edge_contract:
        if not args.edge_prototypes_only:
            print(
                "--only-edge-contract requires --edge-prototypes-only",
                file=sys.stderr,
            )
            sys.exit(1)
        if only_edge_contract not in HETERO_EDGE_CONTRACT_PATH_KEYS:
            print(
                f"--only-edge-contract must be one of: {', '.join(sorted(HETERO_EDGE_CONTRACT_PATH_KEYS))}; "
                f"got {only_edge_contract!r}",
                file=sys.stderr,
            )
            sys.exit(1)

    out_dir_root = args.out_dir.resolve()
    inter_dir = out_dir_root / "intermediate"
    tiles_out = out_dir_root / "out"
    edge_proto_root = inter_dir / "edge_prototypes"
    state_path = (args.state_file or (out_dir_root / "wang_inpaint_state.json")).resolve()

    only = parse_only(args.only)
    raw_indices = sorted(only) if only is not None else list(range(16))
    indices = expand_wang_indices_with_sources(raw_indices)

    state = load_state(state_path)
    api_key = None if args.dry_run else get_api_key()

    requested_label = sorted(only) if only is not None else "0..15"
    idx_line = (
        "indices=(edge-prototypes-only; Wang loop skipped)"
        if args.edge_prototypes_only
        else f"requested={requested_label!r}  process_order={indices}"
    )
    edge_desc_log = args.edge_contract_description
    if len(edge_desc_log) > 140:
        edge_desc_log = edge_desc_log[:140] + "…"
    print(
        f"out_dir={out_dir_root}\nstate={state_path}\n{idx_line}\n"
        f"wang_d4: {len(WANG_D4_ORBIT_REPRESENTATIVES)} orbit reps "
        f"{sorted(WANG_D4_ORBIT_REPRESENTATIVES)}; "
        f"inpaint API indices {sorted(WANG_INDICES_REQUIRE_INPAINT_API)}\n"
        f"compositing_mode={args.compositing_mode}\n"
        f"contract_edge_depth={args.contract_edge_depth}\n"
        f"contract_seam_band={args.contract_seam_band}\n"
        f"cross_inpaint_inset={args.cross_inpaint_inset}\n"
        f"cross_ns_contract_inset={args.cross_ns_contract_inset}\n"
        f"cross_corner_hints={args.cross_corner_hints}\n"
        f"rewrite_intermediates={args.rewrite_intermediates}\n"
        f"stuck_after_seconds={args.stuck_after_seconds}\n"
        f"edge_contract_description={edge_desc_log!r}\n"
        f"edge_prototypes_only={args.edge_prototypes_only}\n"
        f"skip_edge_prototypes={args.skip_edge_prototypes}\n"
        f"only_edge_contract={only_edge_contract or '(all hetero)'}",
        flush=True,
    )

    if args.edge_prototypes_only:
        plains_pre = Image.open(args.plains.resolve()).convert("RGBA")
        sea_pre = Image.open(args.sea.resolve()).convert("RGBA")
        if plains_pre.size != (TILE_SIZE, TILE_SIZE) or sea_pre.size != (TILE_SIZE, TILE_SIZE):
            print("plains and sea bases must be 64×64", file=sys.stderr)
            sys.exit(1)
        ensure_edge_contracts(
            api_key,
            plains=plains_pre,
            sea=sea_pre,
            edge_proto_root=edge_proto_root,
            state=state,
            state_path=state_path,
            edge_description=args.edge_contract_description,
            poll_interval=args.poll_interval,
            stuck_after_s=args.stuck_after_seconds,
            crop_to_mask=args.crop_to_mask,
            rewrite=args.rewrite_edge_prototypes,
            seam_band_px=args.contract_seam_band,
            dry_run=args.dry_run,
            only_hetero_path_key=only_edge_contract or None,
        )
        print("Edge contracts only — done.", flush=True)
        return

    needs_edge_contracts = any(i in WANG_INDICES_REQUIRE_INPAINT_API for i in indices)
    if needs_edge_contracts and not args.dry_run:
        if api_key is None:
            print("API key required for mixed Wang tiles", file=sys.stderr)
            sys.exit(1)
        if args.skip_edge_prototypes:
            assert_edge_contracts_present(edge_proto_root)
            print("Skipping edge contract generation (using existing contracts_128/).", flush=True)
        else:
            plains_pre = Image.open(args.plains.resolve()).convert("RGBA")
            sea_pre = Image.open(args.sea.resolve()).convert("RGBA")
            if plains_pre.size != (TILE_SIZE, TILE_SIZE) or sea_pre.size != (TILE_SIZE, TILE_SIZE):
                print("plains and sea bases must be 64×64", file=sys.stderr)
                sys.exit(1)
            ensure_edge_contracts(
                api_key,
                plains=plains_pre,
                sea=sea_pre,
                edge_proto_root=edge_proto_root,
                state=state,
                state_path=state_path,
                edge_description=args.edge_contract_description,
                poll_interval=args.poll_interval,
                stuck_after_s=args.stuck_after_seconds,
                crop_to_mask=args.crop_to_mask,
                rewrite=args.rewrite_edge_prototypes,
                seam_band_px=args.contract_seam_band,
                dry_run=False,
                only_hetero_path_key=None,
            )

    for idx in indices:
        process_one_tile(
            api_key,
            idx,
            plains_path=args.plains.resolve(),
            sea_path=args.sea.resolve(),
            inter_dir=inter_dir,
            out_dir=tiles_out,
            edge_proto_root=edge_proto_root,
            contract_edge_depth=args.contract_edge_depth,
            compositing_mode=args.compositing_mode,
            cross_inpaint_inset=args.cross_inpaint_inset,
            cross_corner_hints=args.cross_corner_hints,
            cross_ns_contract_inset_px=args.cross_ns_contract_inset,
            state=state,
            state_path=state_path,
            description=args.description,
            poll_interval=args.poll_interval,
            stuck_after_s=args.stuck_after_seconds,
            crop_to_mask=args.crop_to_mask,
            dry_run=args.dry_run,
            force=args.force,
            rewrite_intermediates=args.rewrite_intermediates,
        )

    print("Done.", flush=True)


if __name__ == "__main__":
    main()
