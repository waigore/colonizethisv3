#!/usr/bin/env python3
"""Map-harmony scoring and PO pick parsing for plantation field retune (#3961).

Scores hand-painted field-gradient candidates against Old World plains reference
tiles (grain / meat / horses) plus locked tobacco. Lower score = subtler / more
harmonious at field-mask mean RGB.

Does not ship assets; use with ``finalize_plantation_field_retune_3961.py`` after
PO locks letters.
"""

from __future__ import annotations

import importlib.util
import json
import math
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PAINT_SCRIPT = REPO / "pytool/paint_plains_plantation_field_gradients.py"
DEFAULT_CANDIDATES = REPO / "pytool/assets/terrain/plantation_field_candidates_3961"
DEFAULT_TERRAIN = REPO / "app/assets/images/terrain"
PLANTATION_BASE = REPO / "pytool/assets/terrain/tile_plains_plantation_base.png"
REQUIRED_CROPS = ("sugar_cane", "cotton", "spices")
OW_REFERENCE_KEYS = ("grain", "meat", "horses")
TOBACCO_MEAN = (128, 108, 42)
# Shipped jarring field means (base-mask) before retune; used as soft move-away hint.
CURRENT_JARRING_MEANS: dict[str, tuple[int, int, int]] = {
    "sugar_cane": (151, 218, 80),
    "cotton": (233, 231, 217),
    "spices": (227, 119, 50),
}
PO_LOCK_HEADER = re.compile(r"PO\s+LOCK\s+#?3961", re.IGNORECASE)
PICK_LINE = re.compile(
    r"^\s*(?:[-*]\s*)?(sugar_cane|cotton|spices)\s*(?:→|:|=)\s*([ABC])\b",
    re.IGNORECASE | re.MULTILINE,
)
PICK_INLINE = re.compile(
    r"(sugar_cane|cotton|spices)\s*=\s*([ABC])\b",
    re.IGNORECASE,
)


def _load_paint_module():
    spec = importlib.util.spec_from_file_location(
        "paint_plains_plantation_field_gradients",
        PAINT_SCRIPT,
    )
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


def rgb_distance(a: tuple[int, int, int], b: tuple[int, int, int]) -> float:
    return math.sqrt(
        (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2,
    )


def chroma(rgb: tuple[int, int, int]) -> float:
    r, g, b = rgb
    return math.sqrt((r - g) ** 2 + (g - b) ** 2 + (b - r) ** 2)


def field_mask_mean_from_png(
    png_path: Path,
    *,
    mask_from: Path | None = None,
    paint_mod=None,
) -> tuple[int, int, int]:
    paint = paint_mod or _load_paint_module()
    from PIL import Image

    im = Image.open(png_path)
    mask_im = Image.open(mask_from) if mask_from else im
    return paint.field_mask_mean_rgb(im, mask_from=mask_im)


def load_ow_reference_means(
    terrain_dir: Path = DEFAULT_TERRAIN,
    *,
    paint_mod=None,
) -> list[tuple[int, int, int]]:
    means: list[tuple[int, int, int]] = []
    for key in OW_REFERENCE_KEYS:
        path = terrain_dir / f"tile_plains_{key}.png"
        if not path.is_file():
            raise SystemExit(f"missing OW reference tile: {path}")
        means.append(field_mask_mean_from_png(path, paint_mod=paint_mod))
    return means


def load_candidate_means(candidate_dir: Path = DEFAULT_CANDIDATES) -> dict:
    path = candidate_dir / "CANDIDATE_MEANS.json"
    if not path.is_file():
        raise SystemExit(f"missing {path}")
    data = json.loads(path.read_text(encoding="utf-8"))
    means = data.get("field_mask_means")
    if not isinstance(means, dict):
        raise SystemExit(f"invalid field_mask_means in {path}")
    return means


def letter_for_variant_id(variant_id: str) -> str:
    return variant_id[0].upper()


def variant_id_for_letter(
    crop: str,
    letter: str,
    *,
    letter_by_id: dict[str, dict[str, str]] | None = None,
) -> str:
    paint = _load_paint_module()
    mapping = letter_by_id or paint.LETTER_BY_ID
    variant = mapping[crop].get(letter.upper())
    if variant is None:
        raise SystemExit(f"{crop}: letter must be A, B, or C (got {letter})")
    return variant


def harmony_score(
    rgb: tuple[int, int, int],
    crop: str,
    *,
    ow_means: list[tuple[int, int, int]],
    tobacco_mean: tuple[int, int, int] = TOBACCO_MEAN,
    jarring_mean: dict[str, tuple[int, int, int]] | None = None,
) -> float:
    """Lower is better: closer to OW/tobacco peers, lower chroma, away from jarring."""
    jarring = jarring_mean or CURRENT_JARRING_MEANS
    harmony_refs = list(ow_means) + [tobacco_mean]
    harmony = min(rgb_distance(rgb, ref) for ref in harmony_refs)
    chroma_penalty = chroma(rgb) * 0.15
    move_from_jarring = -rgb_distance(rgb, jarring[crop]) * 0.05
    return harmony + chroma_penalty + move_from_jarring


def rank_candidates_for_crop(
    crop: str,
    variants: dict[str, list[int]],
    *,
    ow_means: list[tuple[int, int, int]],
) -> list[tuple[str, str, tuple[int, int, int], float]]:
    ranked: list[tuple[str, str, tuple[int, int, int], float]] = []
    for variant_id, rgb_list in variants.items():
        rgb = (int(rgb_list[0]), int(rgb_list[1]), int(rgb_list[2]))
        letter = letter_for_variant_id(variant_id)
        score = harmony_score(rgb, crop, ow_means=ow_means)
        ranked.append((letter, variant_id, rgb, score))
    ranked.sort(key=lambda row: row[3])
    return ranked


def recommend_picks(
    candidate_means: dict | None = None,
    *,
    candidate_dir: Path = DEFAULT_CANDIDATES,
    terrain_dir: Path = DEFAULT_TERRAIN,
) -> dict[str, str]:
    means = candidate_means or load_candidate_means(candidate_dir)
    ow_means = load_ow_reference_means(terrain_dir)
    picks: dict[str, str] = {}
    for crop in REQUIRED_CROPS:
        crop_means = means.get(crop)
        if not isinstance(crop_means, dict):
            raise SystemExit(f"no means for {crop}")
        ranked = rank_candidates_for_crop(crop, crop_means, ow_means=ow_means)
        picks[crop] = ranked[0][0]
    return picks


def format_picks(picks: dict[str, str]) -> str:
    return ",".join(f"{crop}={picks[crop]}" for crop in REQUIRED_CROPS)


def parse_po_picks_from_text(text: str) -> dict[str, str] | None:
    """Parse PO letter lock from issue comment or reply text.

    Accepts a ``PO LOCK #3961`` block with ``crop: A`` lines, or inline
    ``sugar_cane=A,cotton=B,spices=A`` anywhere in the text.
    """
    if not text.strip():
        return None
    picks: dict[str, str] = {}
    if PO_LOCK_HEADER.search(text):
        for crop, letter in PICK_LINE.findall(text):
            picks[crop.lower()] = letter.upper()
    for crop, letter in PICK_INLINE.findall(text):
        picks[crop.lower()] = letter.upper()
    if set(picks) == set(REQUIRED_CROPS):
        return {crop: picks[crop] for crop in REQUIRED_CROPS}
    return None


def describe_recommendation(
    *,
    candidate_dir: Path = DEFAULT_CANDIDATES,
    terrain_dir: Path = DEFAULT_TERRAIN,
) -> str:
    means = load_candidate_means(candidate_dir)
    ow_means = load_ow_reference_means(terrain_dir)
    ow_centroid = tuple(
        sum(ref[i] for ref in ow_means) / len(ow_means) for i in range(3)
    )
    lines = [
        "## Harmony recommendation (Refs #3961)",
        "",
        "Automated map-harmony scoring vs OW `grain` / `meat` / `horses` field means "
        f"{ow_means} and locked tobacco `{TOBACCO_MEAN}`. Lower score = subtler / closer peers.",
        "",
        f"**Recommended picks:** `{format_picks(recommend_picks(means))}`",
        "",
        "Per-crop ranking:",
    ]
    picks = recommend_picks(means)
    for crop in REQUIRED_CROPS:
        ranked = rank_candidates_for_crop(crop, means[crop], ow_means=ow_means)
        lines.append(f"### {crop}")
        for letter, variant_id, rgb, score in ranked:
            marker = " **← recommended**" if letter == picks[crop] else ""
            lines.append(
                f"- **{letter}** `{variant_id}` mean `{rgb}` score `{score:.1f}` "
                f"chroma `{chroma(rgb):.1f}` dist OW centroid `{rgb_distance(rgb, ow_centroid):.1f}`"
                f"{marker}",
            )
        lines.append("")
    lines.extend(
        [
            "**PO lock:** reply with one letter per crop (or reject with criteria), e.g.:",
            "",
            "```",
            "PO LOCK #3961",
            f"sugar_cane: {picks['sugar_cane']}",
            f"cotton: {picks['cotton']}",
            f"spices: {picks['spices']}",
            "```",
            "",
            "Or inline: `"
            + format_picks(picks)
            + "`. After lock, implementer runs "
            "`finalize_plantation_field_retune_3961.py --picks … --update-goldens`.",
        ],
    )
    return "\n".join(lines)
