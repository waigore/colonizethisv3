#!/usr/bin/env python3
"""Finalize PO-locked plantation field retune (Refs #3961).

After PO picks A/B/C per crop on the issue, this script:
1. Promotes candidate PNGs into shipped app terrain (tobacco unchanged).
2. Patches SPEC + golden-test mid-tone pins from measured field-mask means.
3. Prints the golden refresh command (not run automatically).

Does **not** run without explicit `--picks`. Use `--dry-run` to preview patches.

See SPEC/ui/pytool-image-tools.md § finalize_plantation_field_retune_3961.py.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import math
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PAINT_SCRIPT = REPO / "pytool/paint_plains_plantation_field_gradients.py"
DEFAULT_CANDIDATES = (
    REPO / "pytool/assets/terrain/plantation_field_candidates_3961"
)
SPEC_LAYERED = REPO / "SPEC/ui/layered-terrain-rendering.md"
GOLDEN_TEST = REPO / "app/test/plains_plantation_terrain_goldens_test.dart"
TOBACCO_MEAN = (128, 108, 42)
REQUIRED_CROPS = ("sugar_cane", "cotton", "spices")
PLANTATION_KEYS = ("sugar_cane", "tobacco", "cotton", "spices")
# Matches app/test/plains_plantation_terrain_goldens_test.dart pairwise check.
MIN_PAIRWISE_RGB_DISTANCE = 26.0


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


def load_candidate_means(candidate_dir: Path) -> dict[str, dict[str, list[int]]]:
    path = candidate_dir / "CANDIDATE_MEANS.json"
    if not path.is_file():
        raise SystemExit(f"missing {path}; run paint_plains_plantation_field_gradients.py")
    data = json.loads(path.read_text(encoding="utf-8"))
    means = data.get("field_mask_means")
    if not isinstance(means, dict):
        raise SystemExit(f"invalid field_mask_means in {path}")
    return means


def resolve_locked_means(
    candidate_means: dict[str, dict[str, list[int]]],
    picks: dict[str, str],
    *,
    letter_by_id: dict[str, dict[str, str]],
) -> dict[str, tuple[int, int, int]]:
    """Map crop stem -> mean RGB for PO-locked letters."""
    if set(picks) != set(REQUIRED_CROPS):
        missing = set(REQUIRED_CROPS) - set(picks)
        extra = set(picks) - set(REQUIRED_CROPS)
        if missing:
            raise SystemExit(f"--picks missing crops: {sorted(missing)}")
        if extra:
            raise SystemExit(f"--picks has unknown crops: {sorted(extra)}")
    out: dict[str, tuple[int, int, int]] = {}
    for crop, letter in picks.items():
        variant = letter_by_id[crop].get(letter.upper())
        if variant is None:
            raise SystemExit(f"{crop}: letter must be A, B, or C (got {letter})")
        crop_means = candidate_means.get(crop)
        if not isinstance(crop_means, dict):
            raise SystemExit(f"no means for {crop} in CANDIDATE_MEANS.json")
        rgb = crop_means.get(variant)
        if not isinstance(rgb, list) or len(rgb) != 3:
            raise SystemExit(f"missing mean for {crop}/{variant}")
        out[crop] = (int(rgb[0]), int(rgb[1]), int(rgb[2]))
    out["tobacco"] = TOBACCO_MEAN
    return out


def format_midtone_clause(means: dict[str, tuple[int, int, int]]) -> str:
    parts = [
        f"sugar_cane `({means['sugar_cane'][0]},{means['sugar_cane'][1]},{means['sugar_cane'][2]})`",
        f"tobacco `({means['tobacco'][0]},{means['tobacco'][1]},{means['tobacco'][2]})`",
        f"cotton `({means['cotton'][0]},{means['cotton'][1]},{means['cotton'][2]})`",
        f"spices `({means['spices'][0]},{means['spices'][1]},{means['spices'][2]})`",
    ]
    return (
        "- **Field mask mean RGB (hand-painted, PO-approved):** "
        + "; ".join(parts)
        + "."
    )


def patch_spec_midtones(spec_path: Path, means: dict[str, tuple[int, int, int]]) -> str:
    text = spec_path.read_text(encoding="utf-8")
    new_line = format_midtone_clause(means)
    pattern = re.compile(
        r"- \*\*(?:PIL field mid-tones|Field mask mean RGB)[^\n]+\n",
    )
    if not pattern.search(text):
        raise SystemExit(f"mid-tone line not found in {spec_path}")
    updated = pattern.sub(new_line + "\n", text, count=1)
    pipeline_old = (
        "**PO sample gate (in progress):** subtler sugar_cane / cotton / spices "
        "fields must use hand-painted field gradients via "
        "`pytool/paint_plains_plantation_field_gradients.py` (3 candidates/crop "
        "under `pytool/assets/terrain/plantation_field_candidates_3961/`); tobacco "
        "stays; final SPEC mid-tones + shipped PNGs update only after PO locks a "
        "letter per crop (`--promote`)."
    )
    pipeline_new = (
        "**PO-approved hand-painted fields:** sugar_cane / cotton / spices shipped "
        "from `paint_plains_plantation_field_gradients.py --promote` via "
        "`finalize_plantation_field_retune_3961.py`; tobacco unchanged. "
        "`recolour_plains_plantation_tiles.py` is legacy pre-retune only."
    )
    if pipeline_old not in updated:
        raise SystemExit("plantation pipeline paragraph not found for patch")
    updated = updated.replace(pipeline_old, pipeline_new, 1)
    spec_path.write_text(updated, encoding="utf-8")
    return new_line


def rgb_distance(a: tuple[int, int, int], b: tuple[int, int, int]) -> float:
    return math.sqrt(
        (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2,
    )


def validate_plantation_picks(
    means: dict[str, tuple[int, int, int]],
    *,
    min_pairwise: float = MIN_PAIRWISE_RGB_DISTANCE,
) -> list[str]:
    """Return human-readable validation errors; empty when picks pass golden pins."""
    errors: list[str] = []
    for i, a in enumerate(PLANTATION_KEYS):
        for b in PLANTATION_KEYS[i + 1 :]:
            dist = rgb_distance(means[a], means[b])
            if dist < min_pairwise:
                errors.append(
                    f"{a} vs {b}: RGB distance {dist:.1f} < {min_pairwise}",
                )
    return errors


def refresh_plantation_goldens(*, repo_root: Path = REPO) -> None:
    """Run flutter golden refresh for plantation terrain strip."""
    app_dir = repo_root / "app"
    test_path = "test/plains_plantation_terrain_goldens_test.dart"
    subprocess.run(
        ["flutter", "test", test_path, "--update-goldens"],
        cwd=app_dir,
        check=True,
    )


def patch_golden_test_midtones(
    test_path: Path,
    means: dict[str, tuple[int, int, int]],
) -> None:
    text = test_path.read_text(encoding="utf-8")
    key_map = {
        "tile_plains_sugar_cane": means["sugar_cane"],
        "tile_plains_tobacco": means["tobacco"],
        "tile_plains_cotton": means["cotton"],
        "tile_plains_spices": means["spices"],
    }
    for key, rgb in key_map.items():
        pattern = re.compile(
            rf"('{re.escape(key)}': )\(\d+, \d+, \d+\)",
        )
        repl = rf"\g<1>({rgb[0]}, {rgb[1]}, {rgb[2]})"
        text, n = pattern.subn(repl, text, count=1)
        if n != 1:
            raise SystemExit(f"could not patch {key} in {test_path}")
    test_path.write_text(text, encoding="utf-8")


def main() -> None:
    paint = _load_paint_module()
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--picks",
        required=True,
        help="PO lock, e.g. sugar_cane=A,cotton=B,spices=C",
    )
    parser.add_argument(
        "--candidate-dir",
        type=Path,
        default=DEFAULT_CANDIDATES,
    )
    parser.add_argument(
        "--app-terrain-dir",
        type=Path,
        default=REPO / "app/assets/images/terrain",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print actions without writing files",
    )
    parser.add_argument(
        "--validate-only",
        action="store_true",
        help="Check pairwise field-mean distinctness; no file writes",
    )
    parser.add_argument(
        "--update-goldens",
        action="store_true",
        help="After apply, run flutter test --update-goldens for plantation strip",
    )
    args = parser.parse_args()
    if args.update_goldens and (args.dry_run or args.validate_only):
        raise SystemExit("--update-goldens requires apply mode (no --dry-run/--validate-only)")
    picks = paint._parse_promote(args.picks)
    candidate_means = load_candidate_means(args.candidate_dir)
    locked_means = resolve_locked_means(
        candidate_means,
        picks,
        letter_by_id=paint.LETTER_BY_ID,
    )
    print("PO-locked field mask means:")
    for crop in PLANTATION_KEYS:
        rgb = locked_means[crop]
        print(f"  {crop}: {rgb}")
    print(f"SPEC line: {format_midtone_clause(locked_means)}")
    validation_errors = validate_plantation_picks(locked_means)
    if validation_errors:
        print("validation FAILED:")
        for err in validation_errors:
            print(f"  - {err}")
        raise SystemExit(1)
    print("validation OK: plantation field means are pairwise distinct")
    if args.validate_only:
        return
    if args.dry_run:
        print("dry-run: no files written")
        return
    paint.promote(args.candidate_dir, args.app_terrain_dir, picks)
    patch_spec_midtones(SPEC_LAYERED, locked_means)
    patch_golden_test_midtones(GOLDEN_TEST, locked_means)
    if args.update_goldens:
        print("refreshing plantation goldens...")
        refresh_plantation_goldens()
        print("goldens updated")
    else:
        print(
            "\nNext: refresh plantation golden from app/:\n"
            "  cd app && flutter test test/plains_plantation_terrain_goldens_test.dart "
            "--update-goldens\n"
            "Or re-run with --update-goldens after PO lock."
        )


if __name__ == "__main__":
    main()
