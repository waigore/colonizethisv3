#!/usr/bin/env python3
"""
Incremental 64×64 corner-Wang plains↔sea tiles with edge reuse (inpaint-v3).

**Generated set:** `state/incremental_state.json` → `completed_wang_indices` (bootstrap: tile files on disk
if state missing). Indices without a `tile_{jj}.png` are ignored.

**Arm (edge contract):** side **x** of target **T** uses **`tile_{jj}`** only if **jj** is in the generated set
(excluding **T**) and **T2**'s edge **opposite(x)** has the same corner pair as **T**'s edge **x**. Else arm
empty + mask inpaint.

**Center 16px fill bands:** side **x** is filled from **`tile_{jj}`** only if **jj** is in that set and **T2**'s
edge **x** matches **T**'s edge **x**; crop **x** from **T2**, paste into center, mask keep. Layout neighbors
are irrelevant.

**Inpaint-v3:** optional **baked init** (see SPEC/ui/tileset/plains-sea-wang-inpaint-64.md): coarse plains/sea guide is merged
into the **`inpainting_image`** raster (API rejects separate **`init_image`** on v3).

**Second pass:** **`--refine-center-island II`** — **64×64** canvas, **white mask** only on the inner **32×32**
(tile coords **[16,48)**); default prompt stresses **continuity** with the fixed **16px** rim (keeps rim for edges).

No **`contracts_128/`**. Spec: SPEC/ui/tileset/wang-incremental-edge-contracts-64.md (+ artifacts part).
"""
from __future__ import annotations

import argparse
import base64
from collections import deque
import io
import json
import logging
import os
import re
import shutil
import sys
import time
from pathlib import Path
from typing import Any

import requests
from PIL import Image, ImageDraw

LOG = logging.getLogger("pytool.wang_incremental_64")

API_BASE = "https://api.pixellab.ai/v2"
TILE = 64
SUB = 16
TOOL_VERSION = "1.7.2"

# Grayscale mask feather (inpaint-v3): only these indices get a soft handoff from keep→inpaint.
# Init guide still uses the binary mask built in build_heterogeneous_cross_assets.
# NOTE: As of 2026-03, inpaint-v3 jobs failed twice with a feathered L mask for wang_index 11
# ("Generation failed"); keep empty until PixelLab confirms grayscale mask support.
WANG_MASK_FEATHER_PX: dict[int, int] = {}

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

# Full replacement strings for specific wang_index values when --description is not passed.
# (11: three plains, one sea — bias interior grassland. 4: three sea, one plains — bias interior sea.)
# (14: three plains, sea SE — east edge is plains-to-sea; bias interior to continue that water/shore westward.)
# Second pass: inner 32×32 only (`--refine-center-island`). Default unless `--description` is set.
DEFAULT_CENTER_ISLAND_REFINE_DESCRIPTION = (
    VERBATIM_WANG_INPAINT_DESCRIPTION
    + " "
    "the inner thirty-two-pixel square is framed on all sides by the final tile treat that fixed "
    "ring as authoritative ground truth extend the same land sea balance shoreline directions and "
    "texture vocabulary inward with no thematic shift if the ring already implies open water "
    "between land cues shape one coherent water passage consistent with those pixels if it implies "
    "a bay pocket coast or strait follow that reading do not impose a layout that disagrees with the "
    "kept border smooth joins no jagged stair-step seams at the mask edge"
)

WANG_INDEX_INPAINT_DESCRIPTION_OVERRIDES: dict[int, str] = {
    4: (
        VERBATIM_WANG_INPAINT_DESCRIPTION
        + " "
        "this tile is mostly open sea with only one grassland corner favor sea across the masked "
        "interior extend water smoothly from sea corners and sea edges keep plains grassland cues "
        "tight to the northeast land corner only do not push a large grassland mass into the "
        "center no straight hard coast cutting through the middle transition sea to shore gently "
        "over many pixels"
    ),
    11: (
        VERBATIM_WANG_INPAINT_DESCRIPTION
        + " "
        "this tile is mostly grassland with only one sea corner favor plains across the masked "
        "interior extend grassland smoothly from land corners and land edges keep open sea tight "
        "to the northeast sea cues only do not push a large sea blob into the center no straight "
        "hard shoreline cutting through the middle transition land to sea gently over many pixels"
    ),
    14: (
        VERBATIM_WANG_INPAINT_DESCRIPTION
        + " "
        "this pattern is three grassland corners with open sea only at southeast the kept east "
        "sixteen-pixel column already shows plains toward the north grading into sea toward the "
        "south and the southeast anchor is sea treat that eastern and southeastern water as "
        "authoritative extend the same open sea hue value texture and shoreline vocabulary "
        "westward and slightly northward into the masked interior over several pixels do not "
        "isolate the inner square as unrelated grassland that hard-cuts off or ignores the visible "
        "sea along the east match the sea strip at the mask boundary smoothly no bright rim or "
        "abrupt land block against eastern water"
    ),
}


def resolve_inpaint_description(
    wang_index: int,
    cli_description: str | None,
) -> tuple[str, bool]:
    """Return (api description, description_verbatim for meta: true only if default verbatim string)."""
    if cli_description is not None:
        return cli_description, False
    override = WANG_INDEX_INPAINT_DESCRIPTION_OVERRIDES.get(wang_index)
    if override is not None:
        return override, False
    return VERBATIM_WANG_INPAINT_DESCRIPTION, True

CORNER_NAMES = ("nw", "ne", "sw", "se")
PASTE_POS = {"nw": (0, 0), "ne": (48, 0), "sw": (0, 48), "se": (48, 48)}
CROP_BOX = {
    "nw": (0, 0, SUB, SUB),
    "ne": (TILE - SUB, 0, TILE, SUB),
    "sw": (0, TILE - SUB, SUB, TILE),
    "se": (TILE - SUB, TILE - SUB, TILE, TILE),
}

# Cross-style API canvas (same geometry as generate_sea_plains_wang_inpaint_64.py cross mode).
CROSS_CANVAS = 192
CROSS_CENTER = TILE  # 64 — Wang cell origin in cross image

# Full 64×64 arm paste top-left (flush to center cell; no N/S arm inset).
ARM_PASTE_XY = {
    "n": (CROSS_CENTER, 0),
    "s": (CROSS_CENTER, CROSS_CENTER + TILE),
    "w": (0, CROSS_CENTER),
    "e": (CROSS_CENTER + TILE, CROSS_CENTER),
}


TILE_NAME_RE = re.compile(r"^tile_(\d+)\.png$")


def configure_logging(*, verbose: bool) -> None:
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(levelname)s [%(name)s] %(message)s",
        stream=sys.stderr,
        force=True,
    )


def corners_from_wang_index(ii: int) -> tuple[bool, bool, bool, bool]:
    nw = (ii & 8) != 0
    ne = (ii & 4) != 0
    sw = (ii & 2) != 0
    se = (ii & 1) != 0
    return nw, ne, sw, se


def ps(a: bool, b: bool) -> str:
    return ("P" if a else "S") + ("P" if b else "S")


def rel_path(path: Path, base: Path) -> str:
    try:
        return str(path.resolve().relative_to(base.resolve())).replace("\\", "/")
    except ValueError:
        return str(path.resolve())


def get_api_key() -> str:
    key = os.environ.get("PIXELLAB_API_KEY")
    if not key or not key.strip():
        LOG.error("PIXELLAB_API_KEY is not set")
        sys.exit(1)
    LOG.debug("API key present (length=%d)", len(key.strip()))
    return key.strip()


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


def discover_completed(tiles_dir: Path) -> set[int]:
    out: set[int] = set()
    if not tiles_dir.is_dir():
        return out
    for p in tiles_dir.iterdir():
        m = TILE_NAME_RE.match(p.name)
        if not m:
            continue
        v = int(m.group(1))
        if 0 <= v <= 15:
            out.add(v)
    LOG.info("discovered completed tiles: %s", sorted(out))
    return out


OPPOSITE_SIDE: dict[str, str] = {"n": "s", "s": "n", "w": "e", "e": "w"}


def load_completed_wang_indices_from_state(run_dir: Path) -> list[int] | None:
    p = run_dir / "state" / "incremental_state.json"
    if not p.is_file():
        return None
    doc = json.loads(p.read_text(encoding="utf-8"))
    raw = doc.get("completed_wang_indices")
    if not isinstance(raw, list):
        return None
    out: list[int] = []
    for x in raw:
        if isinstance(x, int) and 0 <= x <= 15:
            out.append(x)
    return out


def generated_indices_with_files(run_dir: Path, tiles_dir: Path) -> set[int]:
    """Indices from incremental state (or disk discovery if no state) that have `tile_{jj}.png`."""
    from_state = load_completed_wang_indices_from_state(run_dir)
    if from_state is not None:
        raw = set(from_state)
    else:
        raw = discover_completed(tiles_dir)
    return {jj for jj in raw if (tiles_dir / f"tile_{jj:02d}.png").is_file()}


def donor_pool_for_target(run_dir: Path, tiles_dir: Path, target_ii: int) -> set[int]:
    """Generated-set donors for building tile `target_ii` (excludes `target_ii`)."""
    g = generated_indices_with_files(run_dir, tiles_dir)
    g.discard(target_ii)
    return g


def arm_edge_contract_donor(ii: int, side: str, donor_pool: set[int]) -> int | None:
    """Lowest jj in pool whose edge opposite(side) matches target ii's edge side."""
    need = edge_signatures(ii)[side]
    opp = OPPOSITE_SIDE[side]
    for jj in sorted(donor_pool):
        if edge_signatures(jj)[opp] == need:
            return jj
    return None


def center_fill_edge_donor(ii: int, side: str, donor_pool: set[int]) -> int | None:
    """Lowest jj in pool whose edge `side` matches target ii's edge `side` (same orientation)."""
    need = edge_signatures(ii)[side]
    for jj in sorted(donor_pool):
        if edge_signatures(jj)[side] == need:
            return jj
    return None


def edge_contract_donors_dict(ii: int, donor_pool: set[int]) -> dict[str, int | None]:
    return {s: arm_edge_contract_donor(ii, s, donor_pool) for s in ("n", "e", "s", "w")}


def donor_reuse_extra_edges(donors: dict[str, int | None]) -> int:
    """Arms from pool minus distinct donor indices — higher when the same jj supplies multiple sides."""
    jj_list = [donors[s] for s in ("n", "e", "s", "w") if donors[s] is not None]
    if not jj_list:
        return 0
    return len(jj_list) - len(set(jj_list))


def edge_signatures(ii: int) -> dict[str, str]:
    nw, ne, sw, se = corners_from_wang_index(ii)
    return {
        "n": ps(nw, ne),
        "e": ps(ne, se),
        "s": ps(sw, se),
        "w": ps(nw, sw),
    }


def open_arm_label(side: str, target_sig: str) -> str:
    """Reason for an empty arm: no generated tile whose opposite edge matches this signature."""
    return f"open_edge:no_opposite_match_sig_{side}_{target_sig}"


def context_arm_count_for_ordering(ii: int, donor_pool: set[int]) -> int:
    """Count of sides that receive a pasted arm (edge-contract donor exists)."""
    return sum(
        1 for s in ("n", "e", "s", "w") if arm_edge_contract_donor(ii, s, donor_pool) is not None
    )


def choose_next_tile(
    layout: list[list[int]],
    completed: set[int],
    run_dir: Path,
    tiles_dir: Path,
) -> tuple[int, int, int, int] | None:
    candidates: list[tuple[int, int, int, int, int]] = []
    for r in range(4):
        for c in range(4):
            ii = layout[r][c]
            if ii in completed:
                continue
            pool = donor_pool_for_target(run_dir, tiles_dir, ii)
            k = context_arm_count_for_ordering(ii, pool)
            donors = edge_contract_donors_dict(ii, pool)
            reuse = donor_reuse_extra_edges(donors)
            candidates.append((k, reuse, ii, r, c))
    if not candidates:
        return None
    candidates.sort(key=lambda t: (-t[0], -t[1], t[2], t[3], t[4]))
    k, reuse, ii, r, c = candidates[0]
    LOG.info(
        "next tile: wang_index=%d layout=(%d,%d) k_context_arms=%d donor_reuse_extra=%d",
        ii,
        r,
        c,
        k,
        reuse,
    )
    return ii, r, c, k


def layout_cell_for_index(layout: list[list[int]], ii: int) -> tuple[int, int]:
    for r in range(4):
        for c in range(4):
            if layout[r][c] == ii:
                return r, c
    LOG.error("wang_index %d not found in reference_layout", ii)
    sys.exit(1)


def black_rect(draw: ImageDraw.ImageDraw, l: int, u: int, r_ex: int, b_ex: int) -> None:
    """Black keep region matching PIL paste/crop [l,u,r_ex,b_ex) → inclusive draw."""
    draw.rectangle([l, u, r_ex - 1, b_ex - 1], fill=0)


def paste_anchors(
    composite: Image.Image,
    mask: Image.Image,
    plains: Image.Image,
    sea: Image.Image,
    corners: tuple[bool, bool, bool, bool],
    *,
    log_details: bool = True,
) -> None:
    draw = ImageDraw.Draw(mask)
    for i, name in enumerate(CORNER_NAMES):
        use_plains = corners[i]
        src = plains if use_plains else sea
        terrain = "plains" if use_plains else "sea"
        crop = src.crop(CROP_BOX[name])
        x, y = PASTE_POS[name]
        if log_details:
            LOG.info(
                "  anchor %s: %s crop_box=%s paste=(%d,%d)",
                name,
                terrain,
                CROP_BOX[name],
                x,
                y,
            )
        composite.paste(crop, (x, y))
        black_rect(draw, x, y, x + SUB, y + SUB)


def paste_center_fill_edges(
    composite: Image.Image,
    mask: Image.Image,
    ii: int,
    donor_pool: set[int],
    tiles_dir: Path,
) -> set[str]:
    """
    For each side, if some jj in donor_pool has the same edge-x signature as ii, paste jj's edge-x
    band into the Wang cell and mark keep on mask. Order N,S,W,E; anchors pasted after overwrite corners.
    """
    filled: set[str] = set()
    cx, cy = CROSS_CENTER, CROSS_CENTER
    md = ImageDraw.Draw(mask)
    for side in ("n", "s", "w", "e"):
        jj = center_fill_edge_donor(ii, side, donor_pool)
        if jj is None:
            continue
        tpath = tiles_dir / f"tile_{jj:02d}.png"
        im = Image.open(tpath).convert("RGBA")
        assert_base_size(im, tpath)
        if side == "n":
            strip = im.crop((0, 0, TILE, SUB))
            composite.paste(strip, (cx, cy), strip)
            black_rect(md, cx, cy, cx + TILE, cy + SUB)
        elif side == "s":
            strip = im.crop((0, TILE - SUB, TILE, TILE))
            composite.paste(strip, (cx, cy + TILE - SUB), strip)
            black_rect(md, cx, cy + TILE - SUB, cx + TILE, cy + TILE)
        elif side == "w":
            strip = im.crop((0, 0, SUB, TILE))
            composite.paste(strip, (cx, cy), strip)
            black_rect(md, cx, cy, cx + SUB, cy + TILE)
        else:
            strip = im.crop((TILE - SUB, 0, TILE, TILE))
            composite.paste(strip, (cx + TILE - SUB, cy), strip)
            black_rect(md, cx + TILE - SUB, cy, cx + TILE, cy + TILE)
        im.close()
        filled.add(side)
    return filled


def build_cross_inpaint_mask() -> Image.Image:
    """192×192 L: black keep (entire arm slots + anchor corners); white = center interior only."""
    mask = Image.new("L", (CROSS_CANVAS, CROSS_CANVAS), 0)
    px = mask.load()
    assert px is not None
    c0, c1 = CROSS_CENTER, CROSS_CENTER + TILE
    for y in range(c0, c1):
        for x in range(c0, c1):
            lx, ly = x - c0, y - c0
            in_anchor = (
                (lx < SUB and ly < SUB)
                or (lx >= TILE - SUB and ly < SUB)
                or (lx < SUB and ly >= TILE - SUB)
                or (lx >= TILE - SUB and ly >= TILE - SUB)
            )
            if not in_anchor:
                px[x, y] = 255
    lo, hi = mask.getextrema()
    if hi == 0:
        LOG.error("cross inpaint mask has no white pixels")
        sys.exit(1)
    return mask


def build_heterogeneous_cross_assets(
    *,
    plains: Image.Image,
    sea: Image.Image,
    ii: int,
    donor_pool: set[int],
    tiles_dir: Path,
) -> tuple[Image.Image, Image.Image, Image.Image, int, dict[str, str]]:
    """192×192 composite + mask; arms and center fill bands from generated-set edge rules only.

    **Open** arms (no donor): composite leaves that arm transparent; mask keeps the arm slot **black**
    (keep) so PixelLab **inpaint** is only the **center-cell** white region, not the full 64×64 arm.
    """
    nw, ne, sw, se = corners_from_wang_index(ii)
    sigs = edge_signatures(ii)
    composite = Image.new("RGBA", (CROSS_CANVAS, CROSS_CANVAS), (0, 0, 0, 0))
    arm_sources: dict[str, str] = {}
    k_pool = 0
    # Sides with no opposite-edge donor: empty composite; mask arm slot stays keep (not white).
    arms_inpaint_open: list[str] = []
    for side in ("n", "e", "s", "w"):
        x, y = ARM_PASTE_XY[side]
        jj = arm_edge_contract_donor(ii, side, donor_pool)
        if jj is not None:
            tpath = tiles_dir / f"tile_{jj:02d}.png"
            final = Image.open(tpath).convert("RGBA")
            assert_base_size(final, tpath)
            arm_sources[side] = f"tile_{jj:02d}"
            LOG.info(
                "  arm %s: tile_%02d sig=%s paste=(%d,%d) (opposite edge match)",
                side,
                jj,
                sigs[side],
                x,
                y,
            )
            composite.paste(final, (x, y), final)
            final.close()
            k_pool += 1
            continue
        label = open_arm_label(side, sigs[side])
        arm_sources[side] = label
        arms_inpaint_open.append(side)
        LOG.info(
            "  arm %s: (empty) %s sig=%s paste=(%d,%d) mask=keep open slot",
            side,
            label,
            sigs[side],
            x,
            y,
        )

    mask = build_cross_inpaint_mask()

    fill_sides = paste_center_fill_edges(composite, mask, ii, donor_pool, tiles_dir)
    if fill_sides:
        LOG.info(
            "  center fill edges (same-orientation match): %s (%dpx, mask keep)",
            ",".join(sorted(fill_sides)),
            SUB,
        )

    for i, name in enumerate(CORNER_NAMES):
        use_plains = (nw, ne, sw, se)[i]
        src = plains if use_plains else sea
        terrain = "plains" if use_plains else "sea"
        crop = src.crop(CROP_BOX[name])
        ax, ay = PASTE_POS[name]
        cx, cy = CROSS_CENTER + ax, CROSS_CENTER + ay
        LOG.info(
            "  anchor %s: %s crop_box=%s paste=(%d,%d) (cross center)",
            name,
            terrain,
            CROP_BOX[name],
            cx,
            cy,
        )
        composite.paste(crop, (cx, cy))

    anchors_only = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    paste_anchors(
        anchors_only,
        Image.new("L", (TILE, TILE), 255),
        plains,
        sea,
        (nw, ne, sw, se),
        log_details=False,
    )
    kept, inpaint_px = mask_stats(mask)
    LOG.info(
        "mask summary (192×192): keep_pixels=%d inpaint_pixels=%d k_pasted_arms=%d "
        "arms_inpaint_open=%s",
        kept,
        inpaint_px,
        k_pool,
        arms_inpaint_open or "[]",
    )
    return composite, mask, anchors_only, k_pool, arm_sources


def build_homogeneous_intermediate_64(
    plains: Image.Image,
    sea: Image.Image,
    ii: int,
) -> tuple[Image.Image, Image.Image, Image.Image]:
    """64×64 anchors-only composite + mask for homogeneous tiles (no API)."""
    corners = corners_from_wang_index(ii)
    composite = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    mask = Image.new("L", (TILE, TILE), 255)
    anchors_only = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    paste_anchors(composite, mask, plains, sea, corners, log_details=True)
    paste_anchors(
        anchors_only,
        Image.new("L", (TILE, TILE), 255),
        plains,
        sea,
        corners,
        log_details=False,
    )
    return composite, mask, anchors_only


def mask_stats(mask: Image.Image) -> tuple[int, int]:
    hist = mask.histogram()
    kept = hist[0] if hist else 0
    w, h = mask.size
    return kept, w * h - kept


def feather_inpaint_mask_l_from_keep(mask: Image.Image, feather_px: int) -> Image.Image:
    """Return a new L mask: keep pixels stay 0; inpaint ramps 255×(dist/feather_px) for 1≤dist≤feather_px.

    ``dist`` is 4-connected grid distance from the pixel to the nearest keep pixel (<128 in ``mask``).
    Inpaint pixels farther than ``feather_px`` from keep stay at 255. Unreachable inpaint (should not
    occur on cross masks) is set to 255.
    """
    if feather_px < 1:
        return mask.copy()
    m = mask.convert("L")
    w, h = m.size
    px = m.load()
    assert px is not None
    keep: list[list[bool]] = [[px[x, y] < 128 for x in range(w)] for y in range(h)]
    dist: list[list[int]] = [[-1] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()
    for y in range(h):
        for x in range(w):
            if keep[y][x]:
                dist[y][x] = 0
                q.append((x, y))
    while q:
        x, y = q.popleft()
        d0 = dist[y][x]
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and dist[ny][nx] < 0:
                dist[ny][nx] = d0 + 1
                q.append((nx, ny))
    out = Image.new("L", (w, h))
    opx = out.load()
    assert opx is not None
    fp = float(feather_px)
    for y in range(h):
        for x in range(w):
            if keep[y][x]:
                opx[x, y] = 0
                continue
            d = dist[y][x]
            if d < 0:
                opx[x, y] = 255
            elif d > feather_px:
                opx[x, y] = 255
            else:
                opx[x, y] = max(1, min(255, int(round(255.0 * float(d) / fp))))
    return out


def _lerp_rgb(
    a: tuple[int, int, int], b: tuple[int, int, int], t: float
) -> tuple[int, int, int]:
    t = max(0.0, min(1.0, t))
    return (
        int(round(a[0] + (b[0] - a[0]) * t)),
        int(round(a[1] + (b[1] - a[1]) * t)),
        int(round(a[2] + (b[2] - a[2]) * t)),
    )


def _terrain_center_rgb(plains: Image.Image, sea: Image.Image, upper: bool) -> tuple[int, int, int]:
    src = plains if upper else sea
    return src.convert("RGB").getpixel((TILE // 2, TILE // 2))


def build_inpaint_init_guide_192(
    composite: Image.Image,
    mask: Image.Image,
    plains: Image.Image,
    sea: Image.Image,
    ii: int,
) -> Image.Image:
    """192×192 RGBA for PixelLab ``init_image``: bilinear plains/sea tint in masked areas, composite on top.

    Only **white** mask pixels are tinted (heterogeneous runs: **center cell** interior only; **open**
    arm slots stay mask **keep**). Per-pixel RGB: center = full Wang bilinear; arm rows/columns use
    the same lerp formulas if those pixels were ever white. ``alpha_composite`` preserves pasted arms,
    anchors, and center fill bands.
    """
    if composite.size != (CROSS_CANVAS, CROSS_CANVAS) or mask.size != (CROSS_CANVAS, CROSS_CANVAS):
        LOG.error("init guide: expected %d×%d composite and mask", CROSS_CANVAS, CROSS_CANVAS)
        sys.exit(1)
    nw, ne, sw, se = corners_from_wang_index(ii)
    cnw = _terrain_center_rgb(plains, sea, nw)
    cne = _terrain_center_rgb(plains, sea, ne)
    csw = _terrain_center_rgb(plains, sea, sw)
    cse = _terrain_center_rgb(plains, sea, se)
    guide = Image.new("RGBA", (CROSS_CANVAS, CROSS_CANVAS), (0, 0, 0, 0))
    gpx = guide.load()
    mpx = mask.load()
    assert gpx is not None and mpx is not None
    c0, c1 = CROSS_CENTER, CROSS_CENTER + TILE
    denom = float(TILE - 1) if TILE > 1 else 1.0
    for y in range(CROSS_CANVAS):
        for x in range(CROSS_CANVAS):
            if mpx[x, y] < 128:
                continue
            rgb: tuple[int, int, int]
            if c0 <= x < c1 and c0 <= y < c1:
                lx, ly = x - c0, y - c0
                tx = lx / denom
                ty = ly / denom
                top = _lerp_rgb(cnw, cne, tx)
                bot = _lerp_rgb(csw, cse, tx)
                rgb = _lerp_rgb(top, bot, ty)
            elif c0 <= x < c1 and y < c0:
                tx = (x - c0) / denom
                rgb = _lerp_rgb(cnw, cne, tx)
            elif c0 <= x < c1 and y >= c1:
                tx = (x - c0) / denom
                rgb = _lerp_rgb(csw, cse, tx)
            elif x < c0 and c0 <= y < c1:
                ty = (y - c0) / denom
                rgb = _lerp_rgb(cnw, csw, ty)
            elif x >= c1 and c0 <= y < c1:
                ty = (y - c0) / denom
                rgb = _lerp_rgb(cne, cse, ty)
            else:
                continue
            gpx[x, y] = (*rgb, 255)
    comp_rgba = composite.convert("RGBA")
    return Image.alpha_composite(guide, comp_rgba)


def build_center_island_inpaint_mask_64() -> Image.Image:
    """64×64 L: black keep on the outer 16px ring; white = inner 32×32 (same as hetero cross interior)."""
    mask = Image.new("L", (TILE, TILE), 0)
    dr = ImageDraw.Draw(mask)
    # PIL: bottom-right of rectangle is exclusive → [16,48) × [16,48)
    # Inclusive PIL coords → 32×32 cells at 16..47
    dr.rectangle([SUB, SUB, TILE - SUB - 1, TILE - SUB - 1], fill=255)
    lo, hi = mask.getextrema()
    if hi == 0:
        LOG.error("center-island mask has no white pixels")
        sys.exit(1)
    return mask


def build_inpaint_init_guide_64_center_island(
    tile_rgba: Image.Image,
    mask_64: Image.Image,
    plains: Image.Image,
    sea: Image.Image,
    ii: int,
) -> Image.Image:
    """Bilinear Wang-corner tint under the inner island, then alpha-composite current tile (like 192× guide)."""
    if tile_rgba.size != (TILE, TILE) or mask_64.size != (TILE, TILE):
        LOG.error("center-island guide: expected %d×%d tile and mask", TILE, TILE)
        sys.exit(1)
    nw, ne, sw, se = corners_from_wang_index(ii)
    cnw = _terrain_center_rgb(plains, sea, nw)
    cne = _terrain_center_rgb(plains, sea, ne)
    csw = _terrain_center_rgb(plains, sea, sw)
    cse = _terrain_center_rgb(plains, sea, se)
    guide = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    gpx = guide.load()
    mpx = mask_64.load()
    assert gpx is not None and mpx is not None
    denom = float(TILE - 1) if TILE > 1 else 1.0
    for y in range(TILE):
        for x in range(TILE):
            if mpx[x, y] < 128:
                continue
            tx = x / denom
            ty = y / denom
            top = _lerp_rgb(cnw, cne, tx)
            bot = _lerp_rgb(csw, cse, tx)
            rgb = _lerp_rgb(top, bot, ty)
            gpx[x, y] = (*rgb, 255)
    comp_rgba = tile_rgba.convert("RGBA")
    return Image.alpha_composite(guide, comp_rgba)


def run_center_island_refine_pass(
    *,
    run_dir: Path,
    layout: list[list[int]],
    tiles_dir: Path,
    inter_dir: Path,
    meta_dir: Path,
    ii: int,
    plains_img: Image.Image,
    sea_img: Image.Image,
    plains_path: Path,
    sea_path: Path,
    crop_to_mask: bool,
    cli_description: str | None,
    dry_run: bool,
    poll_interval: float,
    max_polls: int,
    init_image_strength: int,
    no_init_image: bool,
) -> None:
    """Re-inpaint inner 32×32 of an existing tile at 64×64 API canvas; outer ring stays fixed."""
    out_tile = tiles_dir / f"tile_{ii:02d}.png"
    if not out_tile.is_file():
        LOG.error("center-island refine requires existing %s", out_tile)
        sys.exit(1)

    if cli_description is not None:
        description = cli_description
        desc_verbatim = False
    else:
        description = DEFAULT_CENTER_ISLAND_REFINE_DESCRIPTION
        desc_verbatim = False

    tile_im = Image.open(out_tile).convert("RGBA")
    assert_base_size(tile_im, out_tile)

    mask_64 = build_center_island_inpaint_mask_64()
    mask_path = inter_dir / f"mask_{ii:02d}_center_island.png"
    mask_64.save(mask_path)
    kept, inpaint_px = mask_stats(mask_64)
    LOG.info(
        "center-island refine wang_index=%d: mask 64×64 keep=%d inpaint=%d (inner 32×32)",
        ii,
        kept,
        inpaint_px,
    )

    init_path: Path | None = None
    if no_init_image:
        inpaint_src = out_tile
        LOG.info("center-island refine: inpainting_image=%s (no baked init guide)", out_tile.name)
    else:
        guide = build_inpaint_init_guide_64_center_island(
            tile_im, mask_64, plains_img, sea_img, ii
        )
        init_path = inter_dir / f"init_guide_{ii:02d}_center_island.png"
        guide.save(init_path)
        guide.close()
        inpaint_src = init_path
        LOG.info("wrote %s (submitted as inpainting_image)", init_path.name)

    mask_64.close()
    tile_im.close()

    r, c = layout_cell_for_index(layout, ii)
    meta_path = meta_dir / f"meta_{ii:02d}.json"
    prev: dict[str, Any] = {}
    if meta_path.is_file():
        prev = json.loads(meta_path.read_text(encoding="utf-8"))

    refine_block: dict[str, Any] = {
        "tool_version": TOOL_VERSION,
        "api_canvas": TILE,
        "inner_region_tile_px": [SUB, SUB, TILE - SUB - 1, TILE - SUB - 1],
        "description": description,
        "description_verbatim": desc_verbatim,
        "mask_relpath": rel_path(mask_path, run_dir),
        "inpainting_input_relpath": rel_path(inpaint_src, run_dir),
        "init_baked_into_inpaint_input": not no_init_image,
        "init_image_strength": None if no_init_image else init_image_strength,
        "crop_to_mask": crop_to_mask,
        "plains_base": rel_path(plains_path, run_dir),
        "sea_base": rel_path(sea_path, run_dir),
        "layout_row": r,
        "layout_col": c,
    }
    prev["center_island_refine"] = refine_block
    prev["tool_version"] = TOOL_VERSION

    if dry_run:
        meta_path.write_text(json.dumps(prev, indent=2), encoding="utf-8")
        LOG.info("dry run: skip API for center-island refine")
        return

    api_key = get_api_key()
    job_id = submit_inpaint_v3(
        api_key,
        description=description,
        inpainting_image_path=inpaint_src,
        mask_path=mask_path,
        api_w=TILE,
        api_h=TILE,
        crop_to_mask=crop_to_mask,
    )
    refine_block["job_id"] = job_id
    prev["job_id"] = job_id
    prev["last_pass"] = "center_island_refine"
    meta_path.write_text(json.dumps(prev, indent=2), encoding="utf-8")
    LOG.info("updated meta job_id=%r (center-island refine)", job_id)

    done = poll_until_done(
        api_key,
        job_id,
        interval_s=poll_interval,
        max_attempts=max_polls,
    )
    png = decode_job_to_tile_png(done, api_wh=TILE)
    out_tile.write_bytes(png)

    completed = discover_completed(tiles_dir)
    write_edge_index(run_dir, completed)
    update_reference_png(run_dir, layout, ii, out_tile)
    write_incremental_state(run_dir, completed, ii, job_id)
    LOG.info("center-island refine complete → %s", out_tile)


def rebuild_edge_index(completed: set[int]) -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    for jj in sorted(completed):
        nw, ne, sw, se = corners_from_wang_index(jj)
        entries.append(
            {
                "source_wang_index": jj,
                "side": "n",
                "signature": ps(nw, ne),
                "signature_kind": "horizontal",
            }
        )
        entries.append(
            {
                "source_wang_index": jj,
                "side": "e",
                "signature": ps(ne, se),
                "signature_kind": "vertical",
            }
        )
        entries.append(
            {
                "source_wang_index": jj,
                "side": "s",
                "signature": ps(sw, se),
                "signature_kind": "horizontal",
            }
        )
        entries.append(
            {
                "source_wang_index": jj,
                "side": "w",
                "signature": ps(nw, sw),
                "signature_kind": "vertical",
            }
        )
    return entries


def write_edge_index(run_dir: Path, completed: set[int]) -> None:
    entries = rebuild_edge_index(completed)
    path = run_dir / "state" / "edge_index.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(entries, indent=2), encoding="utf-8")
    LOG.info("wrote %s (%d entries)", path, len(entries))


def write_incremental_state(
    run_dir: Path,
    completed: set[int],
    last_ii: int | None,
    last_job: str | None,
) -> None:
    path = run_dir / "state" / "incremental_state.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    doc = {
        "tool_version": TOOL_VERSION,
        "completed_wang_indices": sorted(completed),
        "last_completed_wang_index": last_ii,
        "last_job_id": last_job,
    }
    path.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    LOG.info("wrote %s", path)


def update_reference_png(run_dir: Path, layout: list[list[int]], ii: int, tile_png: Path) -> None:
    ref_path = run_dir / "reference.png"
    if not ref_path.is_file():
        LOG.warning("reference.png missing; skip paste for wang_index=%d", ii)
        return
    r, c = layout_cell_for_index(layout, ii)
    ref = Image.open(ref_path).convert("RGBA")
    if ref.size != (256, 256):
        LOG.error("reference.png must be 256×256, got %s", ref.size)
        sys.exit(1)
    cell = Image.open(tile_png).convert("RGBA")
    assert_base_size(cell, tile_png)
    ref.paste(cell, (c * 64, r * 64))
    ref.save(ref_path)
    ref.close()
    cell.close()
    LOG.info("updated reference.png cell (%d,%d) with tile_%02d", r, c, ii)


def png_file_to_b64_field(path: Path) -> dict[str, str]:
    raw = path.read_bytes()
    b64 = base64.standard_b64encode(raw).decode("ascii")
    LOG.debug("base64 %s: raw_bytes=%d", path.name, len(raw))
    return {"type": "base64", "base64": b64, "format": "png"}


def submit_inpaint_v3(
    api_key: str,
    *,
    description: str,
    inpainting_image_path: Path,
    mask_path: Path,
    api_w: int,
    api_h: int,
    crop_to_mask: bool,
) -> str:
    url = f"{API_BASE}/inpaint-v3"
    LOG.info(
        "inpaint-v3 submit: %s size=%d×%d crop_to_mask=%s description_len=%d inpaint_src=%s",
        url,
        api_w,
        api_h,
        crop_to_mask,
        len(description),
        inpainting_image_path.name,
    )
    payload: dict[str, Any] = {
        "description": description,
        "inpainting_image": {
            "image": png_file_to_b64_field(inpainting_image_path),
            "size": {"width": api_w, "height": api_h},
        },
        "mask_image": {
            "image": png_file_to_b64_field(mask_path),
            "size": {"width": api_w, "height": api_h},
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
        LOG.error("inpaint-v3 failed: HTTP %s %s", resp.status_code, resp.text[:2000])
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
        LOG.error("Could not find image base64: %s", json.dumps(job_body, indent=2)[:4000])
        sys.exit(1)
    if "," in b64:
        b64 = b64.split(",", 1)[-1]
    raw = base64.standard_b64decode(b64)
    if raw.startswith(b"\x89PNG\r\n\x1a\n"):
        LOG.info("decode result: PNG %d bytes", len(raw))
        return raw
    expected = width * height * 4
    if len(raw) == expected:
        LOG.info("decode result: raw RGBA %d bytes → PNG", len(raw))
        img = Image.frombytes("RGBA", (width, height), raw)
        out = io.BytesIO()
        img.save(out, format="PNG")
        return out.getvalue()
    LOG.error("Unexpected payload length %d (expected PNG or %d RGBA)", len(raw), expected)
    sys.exit(1)


def decode_job_to_tile_png(job_body: dict, *, api_wh: int) -> bytes:
    """Decode API job → final 64×64 tile PNG (center-crop when api_wh is cross canvas)."""
    raw_png = decode_result_png(job_body, width=api_wh, height=api_wh)
    if api_wh != CROSS_CANVAS:
        return raw_png
    img = Image.open(io.BytesIO(raw_png)).convert("RGBA")
    cropped = img.crop(
        (CROSS_CENTER, CROSS_CENTER, CROSS_CENTER + TILE, CROSS_CENTER + TILE),
    )
    buf = io.BytesIO()
    cropped.save(buf, format="PNG")
    return buf.getvalue()


def poll_until_done(
    api_key: str,
    job_id: str,
    *,
    interval_s: float,
    max_attempts: int,
) -> dict:
    LOG.info("poll job_id=%r interval=%ss max_attempts=%d", job_id, interval_s, max_attempts)
    for attempt in range(max_attempts):
        r = requests.get(
            f"{API_BASE}/background-jobs/{job_id}",
            headers={"Authorization": f"Bearer {api_key}"},
            timeout=60,
        )
        if r.status_code != 200:
            LOG.warning(
                "poll %d/%d: HTTP %s",
                attempt + 1,
                max_attempts,
                r.status_code,
            )
            time.sleep(interval_s)
            continue
        job = r.json()
        status = job.get("status") or (job.get("data") or {}).get("status") or "unknown"
        LOG.info("poll %d/%d: status=%r", attempt + 1, max_attempts, status)
        if status in ("failed", "error"):
            LOG.error("Job failed: %s", json.dumps(job, indent=2)[:4000])
            sys.exit(1)
        if status == "completed":
            LOG.info("job completed after %d poll(s)", attempt + 1)
            return job
        time.sleep(interval_s)
    LOG.error("Timeout waiting for job %s", job_id)
    sys.exit(1)


def save_optional_arms(
    run_dir: Path,
    *,
    ii: int,
    donor_pool: set[int],
    tiles_dir: Path,
) -> None:
    """Write edges/arm_{ii}_{side}_{sig}_tile_{jj}.png for each pasted arm donor."""
    edges = run_dir / "edges"
    edges.mkdir(parents=True, exist_ok=True)
    sigs = edge_signatures(ii)
    for side in ("n", "e", "s", "w"):
        jj = arm_edge_contract_donor(ii, side, donor_pool)
        if jj is None:
            continue
        tpath = tiles_dir / f"tile_{jj:02d}.png"
        to_save = Image.open(tpath).convert("RGBA")
        out = edges / f"arm_{ii:02d}_{side}_{sigs[side]}_tile_{jj:02d}.png"
        to_save.save(out)
        to_save.close()
        LOG.info("wrote optional arm %s", out)


def ensure_seeded_homogeneous_tiles(
    tiles_dir: Path,
    plains_path: Path,
    sea_path: Path,
) -> None:
    """Copy sea/plains bases to tile_00 / tile_15 when missing so the edge pool always has SS and PP arms."""
    tiles_dir.mkdir(parents=True, exist_ok=True)
    base = tiles_dir.parent
    t0 = tiles_dir / "tile_00.png"
    t15 = tiles_dir / "tile_15.png"
    if not t0.is_file():
        shutil.copy(sea_path, t0)
        LOG.info("seeded %s ← sea base (wang_index 0 SSSS)", rel_path(t0, base))
    if not t15.is_file():
        shutil.copy(plains_path, t15)
        LOG.info("seeded %s ← plains base (wang_index 15 PPPP)", rel_path(t15, base))


def paste_homogeneous_tiles_on_reference(
    run_dir: Path,
    layout: list[list[int]],
    tiles_dir: Path,
) -> None:
    """Paste seeded 0/15 into reference.png cells when those indices appear in the layout."""
    ref_path = run_dir / "reference.png"
    if not ref_path.is_file():
        return
    present = {cell for row in layout for cell in row}
    for ii in (0, 15):
        if ii not in present:
            continue
        tp = tiles_dir / f"tile_{ii:02d}.png"
        if tp.is_file():
            update_reference_png(run_dir, layout, ii, tp)


def run_init(run_dir: Path, *, plains_path: Path, sea_path: Path) -> None:
    run_dir.mkdir(parents=True, exist_ok=True)
    layout = [[r * 4 + c for c in range(4)] for r in range(4)]
    (run_dir / "reference_layout.json").write_text(
        json.dumps({"wang_index": layout}, indent=2),
        encoding="utf-8",
    )
    LOG.info("wrote reference_layout.json (wang_index 0–15 row-major)")
    ref = Image.new("RGBA", (256, 256), (255, 255, 255, 255))
    ref.save(run_dir / "reference.png")
    LOG.info("wrote reference.png 256×256 #FFFFFF")
    for sub in ("tiles", "intermediate", "meta", "state", "edges"):
        (run_dir / sub).mkdir(parents=True, exist_ok=True)
    tiles_dir = run_dir / "tiles"
    ensure_seeded_homogeneous_tiles(tiles_dir, plains_path, sea_path)
    paste_homogeneous_tiles_on_reference(run_dir, layout, tiles_dir)
    completed = discover_completed(tiles_dir)
    write_incremental_state(run_dir, completed, None, None)
    LOG.info("init complete: %s", run_dir)


def load_layout(run_dir: Path) -> list[list[int]]:
    p = run_dir / "reference_layout.json"
    if not p.is_file():
        LOG.error("Missing %s (use --init)", p)
        sys.exit(1)
    data = json.loads(p.read_text(encoding="utf-8"))
    grid = data.get("wang_index")
    if not isinstance(grid, list) or len(grid) != 4 or any(
        not isinstance(row, list) or len(row) != 4 for row in grid
    ):
        LOG.error("reference_layout.json: wang_index must be 4×4 nested list")
        sys.exit(1)
    out: list[list[int]] = []
    for row in grid:
        rlist: list[int] = []
        for v in row:
            if not isinstance(v, int) or not 0 <= v <= 15:
                LOG.error("invalid wang_index cell: %r", v)
                sys.exit(1)
            rlist.append(v)
        out.append(rlist)
    return out


def main() -> None:
    repo = Path(__file__).resolve().parent.parent
    default_base = repo / "app/assets/images/terrain/base_64"
    default_run_dir = default_base / "wang_incremental"

    p = argparse.ArgumentParser(
        description="Incremental 64×64 Wang tiles (generated-set edge contracts + inpaint-v3). See SPEC/ui/tileset/wang-incremental-edge-contracts-64.md"
    )
    p.add_argument(
        "--run-dir",
        type=Path,
        default=default_run_dir,
        help=(
            "Run directory (reference_layout.json, reference.png, tiles/, …). "
            f"Default: {default_run_dir.relative_to(repo)}"
        ),
    )
    p.add_argument(
        "--init",
        action="store_true",
        help="Create run-dir + default 4×4 layout + white reference.png + seed tile_00/tile_15 from bases",
    )
    p.add_argument(
        "--plains",
        type=Path,
        default=default_base / "plains_base_64_v5.png",
        help="64×64 plains base",
    )
    p.add_argument(
        "--sea",
        type=Path,
        default=default_base / "sea_base_64.png",
        help="64×64 sea base",
    )
    p.add_argument(
        "--description",
        type=str,
        default=None,
        help="inpaint-v3 text (default: verbatim Wang § SPEC/ui/tileset/plains-sea-wang-inpaint-64.md)",
    )
    p.add_argument("--dry-run", action="store_true", help="Write intermediates + meta; no API")
    p.add_argument("--verbose", "-v", action="store_true")
    p.add_argument("--poll-interval", type=float, default=8.0)
    p.add_argument("--max-polls", type=int, default=200)
    p.add_argument(
        "--max-tiles",
        type=int,
        default=1,
        help="Max tiles to generate this invocation (default: 1)",
    )
    p.add_argument(
        "--only",
        type=int,
        default=None,
        help="Force wang_index 0–15 (must appear in reference_layout)",
    )
    p.add_argument("--no-crop-to-mask", action="store_true")
    p.add_argument(
        "--no-init-image",
        action="store_true",
        help="Do not send init_image / init_image_strength to inpaint-v3",
    )
    p.add_argument(
        "--init-image-strength",
        type=int,
        default=450,
        metavar="N",
        help=(
            "Recorded in meta when init is enabled (1–999; PixelLab UI docs). "
            "inpaint-v3 does not accept init_image JSON — guidance is baked into inpainting_image."
        ),
    )
    p.add_argument(
        "--save-strips",
        action="store_true",
        help="Write edges/arm_{ii}_{side}_{sig}_*.png (each 64×64 arm as composited)",
    )
    p.add_argument(
        "--no-resume",
        action="store_true",
        help="Do not poll an existing job_id from meta when tile PNG is missing (resubmit)",
    )
    p.add_argument(
        "--refine-center-island",
        type=int,
        default=None,
        metavar="II",
        help=(
            "Re-inpaint only the inner 32×32 of an existing tile_II (64×64 tile, inclusive coords "
            "x,y in [16,47]); 16px outer ring stays fixed. 64×64 inpaint-v3 canvas. Default prompt "
            "extends the ring's land/sea theme inward; override with --description."
        ),
    )
    args = p.parse_args()
    configure_logging(verbose=args.verbose)

    if not args.no_init_image and (
        args.init_image_strength < 1 or args.init_image_strength > 999
    ):
        LOG.error("--init-image-strength must be between 1 and 999 inclusive")
        sys.exit(1)

    run_dir = args.run_dir.resolve()
    plains_path = args.plains.resolve()
    sea_path = args.sea.resolve()

    if args.init:
        if not plains_path.is_file() or not sea_path.is_file():
            LOG.error("plains and sea bases must exist for --init: %s %s", plains_path, sea_path)
            sys.exit(1)
        run_init(run_dir, plains_path=plains_path, sea_path=sea_path)
        if args.max_tiles == 0 and args.only is None:
            return

    layout = load_layout(run_dir)
    ref_png = run_dir / "reference.png"
    if not ref_png.is_file():
        LOG.error("Missing reference.png in %s", run_dir)
        sys.exit(1)

    tiles_dir = run_dir / "tiles"
    inter_dir = run_dir / "intermediate"
    meta_dir = run_dir / "meta"
    tiles_dir.mkdir(parents=True, exist_ok=True)
    inter_dir.mkdir(parents=True, exist_ok=True)
    meta_dir.mkdir(parents=True, exist_ok=True)

    if not plains_path.is_file() or not sea_path.is_file():
        LOG.error("plains and sea bases must exist: %s %s", plains_path, sea_path)
        sys.exit(1)

    ensure_seeded_homogeneous_tiles(tiles_dir, plains_path, sea_path)
    paste_homogeneous_tiles_on_reference(run_dir, layout, tiles_dir)

    plains_img = Image.open(plains_path).convert("RGBA")
    sea_img = Image.open(sea_path).convert("RGBA")
    assert_base_size(plains_img, plains_path)
    assert_base_size(sea_img, sea_path)

    completed = discover_completed(tiles_dir)
    write_edge_index(run_dir, completed)

    crop_to_mask = not args.no_crop_to_mask
    cli_description: str | None = None
    if args.description is not None:
        cli_description = args.description.strip()
        if not cli_description:
            LOG.error("--description must not be empty")
            sys.exit(1)
        LOG.info("using custom --description for all tiles (length=%d)", len(cli_description))
    api_key: str | None = None

    if args.refine_center_island is not None:
        rii = args.refine_center_island
        if not 0 <= rii <= 15:
            LOG.error("--refine-center-island must be between 0 and 15 inclusive")
            sys.exit(1)
        run_center_island_refine_pass(
            run_dir=run_dir,
            layout=layout,
            tiles_dir=tiles_dir,
            inter_dir=inter_dir,
            meta_dir=meta_dir,
            ii=rii,
            plains_img=plains_img,
            sea_img=sea_img,
            plains_path=plains_path,
            sea_path=sea_path,
            crop_to_mask=crop_to_mask,
            cli_description=cli_description,
            dry_run=args.dry_run,
            poll_interval=args.poll_interval,
            max_polls=args.max_polls,
            init_image_strength=args.init_image_strength,
            no_init_image=args.no_init_image,
        )
        plains_img.close()
        sea_img.close()
        LOG.info("finished --refine-center-island")
        return

    processed = 0
    last_ii: int | None = None
    last_job: str | None = None

    while processed < args.max_tiles or args.only is not None:
        if args.only is not None:
            ii = args.only
            r, c = layout_cell_for_index(layout, ii)
            _pool = donor_pool_for_target(run_dir, tiles_dir, ii)
            k = context_arm_count_for_ordering(ii, _pool)
            _reuse = donor_reuse_extra_edges(edge_contract_donors_dict(ii, _pool))
            LOG.info(
                "forced --only wang_index=%d layout=(%d,%d) k_context=%d donor_reuse_extra=%d",
                ii,
                r,
                c,
                k,
                _reuse,
            )
            args.only = None
        else:
            nxt = choose_next_tile(layout, completed, run_dir, tiles_dir)
            if nxt is None:
                LOG.info("no missing tiles; done")
                break
            ii, r, c, k = nxt

        out_tile = tiles_dir / f"tile_{ii:02d}.png"
        meta_path = meta_dir / f"meta_{ii:02d}.json"

        if out_tile.is_file():
            LOG.info("skip wang_index=%d: %s exists", ii, out_tile)
            continue

        description, description_verbatim = resolve_inpaint_description(ii, cli_description)
        if ii in WANG_INDEX_INPAINT_DESCRIPTION_OVERRIDES and cli_description is None:
            LOG.info(
                "wang_index=%d: using built-in description override (length=%d)",
                ii,
                len(description),
            )

        # Resume incomplete inpaint job (meta job_id, no tile yet)
        if meta_path.is_file() and not args.no_resume and not args.dry_run:
            prev = json.loads(meta_path.read_text(encoding="utf-8"))
            resume_id = prev.get("job_id")
            if isinstance(resume_id, str) and resume_id and not resume_id.startswith("copy:"):
                if api_key is None:
                    api_key = get_api_key()
                LOG.info("resume poll job_id=%r for wang_index=%d", resume_id, ii)
                done = poll_until_done(
                    api_key,
                    resume_id,
                    interval_s=args.poll_interval,
                    max_attempts=args.max_polls,
                )
                api_wh = int(prev.get("api_canvas", TILE))
                if api_wh not in (TILE, CROSS_CANVAS):
                    LOG.warning("meta api_canvas=%s invalid; assuming %d", api_wh, CROSS_CANVAS)
                    api_wh = CROSS_CANVAS
                png = decode_job_to_tile_png(done, api_wh=api_wh)
                out_tile.write_bytes(png)
                prev["output"] = rel_path(out_tile, run_dir)
                meta_path.write_text(json.dumps(prev, indent=2), encoding="utf-8")
                completed.add(ii)
                write_edge_index(run_dir, completed)
                update_reference_png(run_dir, layout, ii, out_tile)
                last_ii = ii
                last_job = resume_id
                write_incremental_state(run_dir, completed, last_ii, last_job)
                processed += 1
                continue

        donor_pool = donor_pool_for_target(run_dir, tiles_dir, ii)
        donors = edge_contract_donors_dict(ii, donor_pool)
        LOG.info(
            "edge_contract_donors n=%s e=%s s=%s w=%s (opposite-edge match in generated set)",
            donors["n"],
            donors["e"],
            donors["s"],
            donors["w"],
        )

        if args.save_strips and ii not in (0, 15):
            save_optional_arms(
                run_dir,
                ii=ii,
                donor_pool=donor_pool,
                tiles_dir=tiles_dir,
            )

        job_id: str | None = None

        # Homogeneous: copy base (plains-sea-wang-inpaint-64.md); intermediates = anchors only
        if ii in (0, 15):
            name = "SSSS" if ii == 0 else "PPPP"
            LOG.info("wang_index=%d (%s): copy %s base → tile (no API)", ii, name, "sea" if ii == 0 else "plains")
            composite, mask, anchors_only = build_homogeneous_intermediate_64(
                plains_img,
                sea_img,
                ii,
            )
            comp_path = inter_dir / f"composite_{ii:02d}.png"
            mask_path = inter_dir / f"mask_{ii:02d}.png"
            anch_path = inter_dir / f"anchors_{ii:02d}.png"
            composite.save(comp_path)
            mask.save(mask_path)
            anchors_only.save(anch_path)
            composite.close()
            mask.close()
            anchors_only.close()
            LOG.info("wrote %s %s %s", comp_path, mask_path, anch_path)
            if ii == 0:
                shutil.copy(sea_path, out_tile)
                job_id = "copy:sea_base"
            else:
                shutil.copy(plains_path, out_tile)
                job_id = "copy:plains_base"
        else:
            composite, mask, anchors_only, _k_pool, arm_sources = build_heterogeneous_cross_assets(
                plains=plains_img,
                sea=sea_img,
                ii=ii,
                donor_pool=donor_pool,
                tiles_dir=tiles_dir,
            )
            comp_path = inter_dir / f"composite_{ii:02d}.png"
            mask_path = inter_dir / f"mask_{ii:02d}.png"
            anch_path = inter_dir / f"anchors_{ii:02d}.png"
            init_path: Path | None = None
            init_rgba: Image.Image | None = None
            init_strength: int | None = None
            mask_feather_px: int | None = WANG_MASK_FEATHER_PX.get(ii)
            if not args.no_init_image:
                init_rgba = build_inpaint_init_guide_192(
                    composite, mask, plains_img, sea_img, ii
                )
                init_path = inter_dir / f"init_guide_{ii:02d}.png"
                init_rgba.save(init_path)
                init_strength = int(args.init_image_strength)
                LOG.info(
                    "wrote %s (submitted as inpainting_image; v3 rejects separate init_image JSON)",
                    init_path,
                )
            if mask_feather_px is not None:
                mask_for_api = feather_inpaint_mask_l_from_keep(mask, mask_feather_px)
                LOG.info(
                    "wang_index=%d: API mask feather %d px from keep edge "
                    "(init guide used binary mask only)",
                    ii,
                    mask_feather_px,
                )
            else:
                mask_for_api = mask
            composite.save(comp_path)
            mask_for_api.save(mask_path)
            anchors_only.save(anch_path)
            LOG.info("wrote %s %s %s", comp_path, mask_path, anch_path)
            composite.close()
            if mask_for_api is not mask:
                mask_for_api.close()
            mask.close()
            anchors_only.close()

            arms_inpaint_open = sorted(
                s for s, lbl in arm_sources.items() if lbl.startswith("open_edge:")
            )
            meta_partial = {
                "wang_index": ii,
                "layout_row": r,
                "layout_col": c,
                "k": k,
                "donors": donors,
                "arm_sources": arm_sources,
                "arms_inpaint_open": arms_inpaint_open,
                "signatures": edge_signatures(ii),
                "api_canvas": CROSS_CANVAS,
                "tool_version": TOOL_VERSION,
                "crop_to_mask": crop_to_mask,
                "description_verbatim": description_verbatim,
                "description": description,
                "plains_base": rel_path(plains_path, run_dir),
                "sea_base": rel_path(sea_path, run_dir),
                "composite": rel_path(comp_path, run_dir),
                "mask": rel_path(mask_path, run_dir),
                "mask_feather_px": mask_feather_px,
                "anchors": rel_path(anch_path, run_dir),
                "init_guide": rel_path(init_path, run_dir) if init_path is not None else None,
                "init_image_strength": init_strength,
                "init_baked_into_inpaint_input": init_path is not None,
                "inpainting_input": rel_path(
                    init_path if init_path is not None else comp_path, run_dir
                ),
                "output": rel_path(out_tile, run_dir),
                "job_id": None,
            }
            meta_path.write_text(json.dumps(meta_partial, indent=2), encoding="utf-8")
            LOG.info("wrote %s", meta_path)

            if args.dry_run:
                if init_rgba is not None:
                    init_rgba.close()
                LOG.info("dry run: skip API for wang_index=%d", ii)
                processed += 1
                continue

            if api_key is None:
                api_key = get_api_key()
            inpaint_src = init_path if init_path is not None else comp_path
            try:
                job_id = submit_inpaint_v3(
                    api_key,
                    description=description,
                    inpainting_image_path=inpaint_src,
                    mask_path=mask_path,
                    api_w=CROSS_CANVAS,
                    api_h=CROSS_CANVAS,
                    crop_to_mask=crop_to_mask,
                )
            finally:
                if init_rgba is not None:
                    init_rgba.close()
            meta_partial["job_id"] = job_id
            meta_path.write_text(json.dumps(meta_partial, indent=2), encoding="utf-8")
            LOG.info("updated meta job_id=%r", job_id)

            done = poll_until_done(
                api_key,
                job_id,
                interval_s=args.poll_interval,
                max_attempts=args.max_polls,
            )
            png = decode_job_to_tile_png(done, api_wh=CROSS_CANVAS)
            out_tile.write_bytes(png)
            meta_partial["output"] = rel_path(out_tile, run_dir)
            meta_path.write_text(json.dumps(meta_partial, indent=2), encoding="utf-8")

        if ii in (0, 15):
            meta_doc = {
                "wang_index": ii,
                "layout_row": r,
                "layout_col": c,
                "k": k,
                "donors": donors,
                "api_canvas": TILE,
                "tool_version": TOOL_VERSION,
                "signatures": edge_signatures(ii),
                "crop_to_mask": crop_to_mask,
                "description_verbatim": description_verbatim,
                "description": description,
                "plains_base": rel_path(plains_path, run_dir),
                "sea_base": rel_path(sea_path, run_dir),
                "composite": rel_path(inter_dir / f"composite_{ii:02d}.png", run_dir),
                "mask": rel_path(inter_dir / f"mask_{ii:02d}.png", run_dir),
                "anchors": rel_path(inter_dir / f"anchors_{ii:02d}.png", run_dir),
                "output": rel_path(out_tile, run_dir),
                "job_id": job_id,
            }
            meta_path.write_text(json.dumps(meta_doc, indent=2), encoding="utf-8")
            LOG.info("wrote %s", meta_path)

        completed.add(ii)
        write_edge_index(run_dir, completed)
        update_reference_png(run_dir, layout, ii, out_tile)
        last_ii = ii
        last_job = str(job_id) if job_id else None
        write_incremental_state(run_dir, completed, last_ii, last_job)
        LOG.info("completed wang_index=%d → %s", ii, out_tile)

        processed += 1
        if args.max_tiles > 0 and processed >= args.max_tiles:
            break

    plains_img.close()
    sea_img.close()
    LOG.info("finished batch")


if __name__ == "__main__":
    main()
