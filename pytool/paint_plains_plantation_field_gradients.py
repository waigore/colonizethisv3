#!/usr/bin/env python3
"""Hand-painted field-gradient candidates for NW plantation plains (Refs #3961).

Keeps plantation base buildings/soil/path/alpha. Re-authors only yellow-green
field-highlight pixels with multi-stop vertical banding, mild horizontal drift,
ordered Bayer dither, and luminance shade from the base field mask.

Does **not** write shipped `app/assets/images/terrain/tile_plains_*.png` unless
`--promote` is given after PO locks a letter per crop. Tobacco is never retuned.

See SPEC/ui/layered-terrain-rendering.md § Plains plantation variants and
SPEC/ui/pytool-image-tools.md.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image

# 4×4 Bayer ordered dither thresholds in [0, 1).
_BAYER_4 = (
    (0 / 16, 8 / 16, 2 / 16, 10 / 16),
    (12 / 16, 4 / 16, 14 / 16, 6 / 16),
    (3 / 16, 11 / 16, 1 / 16, 9 / 16),
    (15 / 16, 7 / 16, 13 / 16, 5 / 16),
)

# Exactly 3 candidates per retune crop (PO sample gate). Stops: (t, RGB).
CANDIDATES: dict[str, dict[str, list[tuple[float, tuple[int, int, int]]]]] = {
    "sugar_cane": {
        "A_sage_olive": [
            (0.0, (78, 102, 58)),
            (0.35, (96, 122, 68)),
            (0.65, (110, 134, 76)),
            (1.0, (88, 112, 62)),
        ],
        "B_tea_green": [
            (0.0, (72, 108, 88)),
            (0.4, (90, 124, 100)),
            (0.7, (108, 138, 112)),
            (1.0, (82, 116, 94)),
        ],
        "C_warm_olive_cane": [
            (0.0, (92, 108, 52)),
            (0.35, (112, 128, 62)),
            (0.7, (128, 142, 74)),
            (1.0, (100, 118, 56)),
        ],
    },
    "cotton": {
        "A_soft_taupe": [
            (0.0, (148, 138, 118)),
            (0.4, (172, 162, 140)),
            (0.75, (188, 178, 156)),
            (1.0, (158, 150, 128)),
        ],
        "B_grey_fibre": [
            (0.0, (138, 136, 132)),
            (0.4, (160, 158, 152)),
            (0.75, (176, 174, 168)),
            (1.0, (148, 146, 142)),
        ],
        "C_warm_cream": [
            (0.0, (158, 142, 118)),
            (0.35, (178, 162, 136)),
            (0.7, (192, 176, 150)),
            (1.0, (168, 152, 128)),
        ],
    },
    "spices": {
        "A_cinnamon_umber": [
            (0.0, (108, 72, 42)),
            (0.35, (132, 90, 52)),
            (0.7, (148, 104, 62)),
            (1.0, (118, 80, 46)),
        ],
        "B_muted_paprika": [
            (0.0, (112, 62, 42)),
            (0.4, (136, 78, 52)),
            (0.75, (152, 92, 60)),
            (1.0, (120, 68, 46)),
        ],
        "C_ochre_turmeric": [
            (0.0, (118, 88, 40)),
            (0.35, (142, 108, 50)),
            (0.7, (158, 122, 58)),
            (1.0, (128, 96, 44)),
        ],
    },
}

LETTER_BY_ID: dict[str, dict[str, str]] = {
    crop: {key[0]: key for key in variants}
    for crop, variants in CANDIDATES.items()
}


def is_field_highlight(r: int, g: int, b: int, a: int) -> bool:
    if a < 16:
        return False
    return g > r + 8 and g > b + 8 and g >= 55 and r >= 40


def luminance(r: int, g: int, b: int) -> float:
    return 0.299 * r + 0.587 * g + 0.114 * b


def _lerp_rgb(
    a: tuple[int, int, int],
    b: tuple[int, int, int],
    t: float,
) -> tuple[float, float, float]:
    return (
        a[0] + (b[0] - a[0]) * t,
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
    )


def sample_stops(
    stops: list[tuple[float, tuple[int, int, int]]],
    t: float,
) -> tuple[float, float, float]:
    t = max(0.0, min(1.0, t))
    for i in range(len(stops) - 1):
        t0, c0 = stops[i]
        t1, c1 = stops[i + 1]
        if t <= t1 or i == len(stops) - 2:
            span = max(t1 - t0, 1e-6)
            return _lerp_rgb(c0, c1, (t - t0) / span)
    return (
        float(stops[-1][1][0]),
        float(stops[-1][1][1]),
        float(stops[-1][1][2]),
    )


def paint_field_gradient(
    src: Image.Image,
    stops: list[tuple[float, tuple[int, int, int]]],
    *,
    dither_strength: float = 6.0,
    drift_strength: float = 0.08,
) -> Image.Image:
    """Paint multi-stop field gradients onto field-highlight pixels only."""
    im = src.convert("RGBA")
    px = im.load()
    assert px is not None
    width, height = im.size
    field_lums = [
        luminance(*px[x, y][:3])
        for y in range(height)
        for x in range(width)
        if is_field_highlight(*px[x, y])
    ]
    if not field_lums:
        raise SystemExit("no field-highlight pixels found in base image")
    lo, hi = min(field_lums), max(field_lums)
    span = max(hi - lo, 1.0)

    out = im.copy()
    opx = out.load()
    assert opx is not None
    for y in range(height):
        for x in range(width):
            r, g, b, a = px[x, y]
            if not is_field_highlight(r, g, b, a):
                continue
            # Vertical banding with mild horizontal drift (not flat mid-tone).
            ty = y / max(height - 1, 1)
            tx = x / max(width - 1, 1)
            t = max(0.0, min(1.0, ty + (tx - 0.5) * drift_strength))
            fr, fg, fb = sample_stops(stops, t)
            shade = 0.72 + 0.56 * ((luminance(r, g, b) - lo) / span)
            dither = (_BAYER_4[y % 4][x % 4] - 0.5) * dither_strength
            opx[x, y] = (
                max(0, min(255, int(fr * shade + dither))),
                max(0, min(255, int(fg * shade + dither))),
                max(0, min(255, int(fb * shade + dither))),
                a,
            )
    return out


def field_mask_mean_rgb(
    im: Image.Image,
    *,
    mask_from: Image.Image | None = None,
) -> tuple[int, int, int]:
    """Mean RGB over field-highlight pixels.

    After gradient paint, cotton/spices no longer match the yellow-green base
    mask predicate — pass ``mask_from`` as the pre-paint base when measuring.
    """
    painted = im.convert("RGBA")
    mask_src = (mask_from or im).convert("RGBA")
    ppx = painted.load()
    mpx = mask_src.load()
    assert ppx is not None and mpx is not None
    width, height = painted.size
    rs, gs, bs, n = 0, 0, 0, 0
    for y in range(height):
        for x in range(width):
            if not is_field_highlight(*mpx[x, y]):
                continue
            r, g, b, _a = ppx[x, y]
            rs += r
            gs += g
            bs += b
            n += 1
    if n == 0:
        raise SystemExit("no field-highlight pixels for mean")
    return (rs // n, gs // n, bs // n)


def _alpha_bytes(im: Image.Image) -> list[int]:
    return [p[3] for p in im.convert("RGBA").get_flattened_data()]


def write_candidates(
    base: Path,
    out_dir: Path,
) -> dict[str, dict[str, tuple[int, int, int]]]:
    src = Image.open(base)
    if src.size != (64, 64):
        raise SystemExit(f"expected 64×64 base, got {src.size}")
    base_alpha = _alpha_bytes(src)
    out_dir.mkdir(parents=True, exist_ok=True)
    means: dict[str, dict[str, tuple[int, int, int]]] = {}
    for crop, variants in CANDIDATES.items():
        means[crop] = {}
        for variant_id, stops in variants.items():
            painted = paint_field_gradient(src, stops)
            if _alpha_bytes(painted) != base_alpha:
                raise SystemExit(f"alpha silhouette changed for {crop}/{variant_id}")
            path = out_dir / f"tile_plains_{crop}_{variant_id}.png"
            painted.save(path, optimize=True)
            mean = field_mask_mean_rgb(painted, mask_from=src)
            means[crop][variant_id] = mean
            print(f"wrote {path} mean={mean}")
    notes = {
        "refs": 3961,
        "note": "Candidates only; do not ship until PO locks a letter per crop.",
        "tobacco": "unchanged; not generated here",
        "field_mask_means": {
            crop: {vid: list(rgb) for vid, rgb in variants.items()}
            for crop, variants in means.items()
        },
    }
    (out_dir / "CANDIDATE_MEANS.json").write_text(
        json.dumps(notes, indent=2) + "\n",
        encoding="utf-8",
    )
    return means


def promote(
    candidate_dir: Path,
    app_terrain_dir: Path,
    picks: dict[str, str],
) -> None:
    """Copy PO-locked candidates into shipped terrain paths (tobacco skipped)."""
    for crop, letter in picks.items():
        if crop == "tobacco":
            raise SystemExit("tobacco must stay unchanged; omit from --promote")
        if crop not in LETTER_BY_ID:
            raise SystemExit(f"unknown crop {crop}")
        variant = LETTER_BY_ID[crop].get(letter.upper())
        if variant is None:
            raise SystemExit(f"crop {crop}: letter must be A, B, or C (got {letter})")
        src = candidate_dir / f"tile_plains_{crop}_{variant}.png"
        if not src.is_file():
            raise SystemExit(f"missing candidate PNG: {src}")
        dest = app_terrain_dir / f"tile_plains_{crop}.png"
        Image.open(src).save(dest, optimize=True)
        print(f"promoted {src.name} -> {dest}")


def _parse_promote(raw: str) -> dict[str, str]:
    picks: dict[str, str] = {}
    for part in raw.split(","):
        part = part.strip()
        if not part:
            continue
        if "=" not in part:
            raise SystemExit(
                f"bad --promote entry {part!r}; expected sugar_cane=A,cotton=B,spices=C",
            )
        crop, letter = part.split("=", 1)
        picks[crop.strip()] = letter.strip()
    return picks


def main() -> None:
    repo = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--base",
        type=Path,
        default=repo / "pytool/assets/terrain/tile_plains_plantation_base.png",
        help="Approved PixelLab plantation base PNG (64×64, RGBA)",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=repo
        / "pytool/assets/terrain/plantation_field_candidates_3961",
        help="Directory for candidate tile_plains_*_<variant>.png outputs",
    )
    parser.add_argument(
        "--promote",
        type=str,
        default="",
        help=(
            "After PO lock only: copy picks into app terrain "
            "(e.g. sugar_cane=A,cotton=B,spices=C). Does not touch tobacco."
        ),
    )
    parser.add_argument(
        "--app-terrain-dir",
        type=Path,
        default=repo / "app/assets/images/terrain",
        help="Shipped terrain dir used only with --promote",
    )
    args = parser.parse_args()
    if not args.base.is_file():
        raise SystemExit(f"base PNG not found: {args.base}")
    write_candidates(args.base, args.out_dir)
    if args.promote.strip():
        promote(args.out_dir, args.app_terrain_dir, _parse_promote(args.promote))


if __name__ == "__main__":
    main()
