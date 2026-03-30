#!/usr/bin/env python3
"""
Legal 4×4 reference_layout.json for corner Wang tiles 0–15 (each once).

Constraints: SPEC/ui/tileset/wang-reference-legal-layout-64.md
"""
from __future__ import annotations

import argparse
import json
import logging
import random
import sys
from pathlib import Path
from typing import Final

LOG = logging.getLogger("pytool.wang_reference_legal_layout_64")

GRID: Final[int] = 4
N_TILES: Final[int] = 16
TILE: Final[int] = 64


def corners_from_wang_index(ii: int) -> tuple[bool, bool, bool, bool]:
    """nw, ne, sw, se — True = plains, False = sea (matches wang_incremental_64 / SPEC)."""
    nw = (ii & 8) != 0
    ne = (ii & 4) != 0
    sw = (ii & 2) != 0
    se = (ii & 1) != 0
    return nw, ne, sw, se


def build_compatibility_tables() -> tuple[list[list[bool]], list[list[bool]]]:
    """can_right[a][b]: a left of b; can_down[a][b]: a above b."""
    can_right = [[False] * N_TILES for _ in range(N_TILES)]
    can_down = [[False] * N_TILES for _ in range(N_TILES)]
    for a in range(N_TILES):
        anw, ane, asw, ase = corners_from_wang_index(a)
        for b in range(N_TILES):
            bnw, bne, bsw, bse = corners_from_wang_index(b)
            can_right[a][b] = ane == bnw and ase == bsw
            can_down[a][b] = asw == bnw and ase == bne
    return can_right, can_down


def layout_to_grid(layout: list[list[int]]) -> list[list[int]]:
    return [[int(layout[r][c]) for c in range(GRID)] for r in range(GRID)]


def validate_layout(
    grid: list[list[int]],
    *,
    can_right: list[list[bool]],
    can_down: list[list[bool]],
) -> bool:
    seen: set[int] = set()
    for r in range(GRID):
        for c in range(GRID):
            v = grid[r][c]
            if v in seen or not (0 <= v < N_TILES):
                return False
            seen.add(v)
    if len(seen) != N_TILES:
        return False
    for r in range(GRID):
        for c in range(GRID - 1):
            a, b = grid[r][c], grid[r][c + 1]
            if not can_right[a][b]:
                return False
    for r in range(GRID - 1):
        for c in range(GRID):
            a, b = grid[r][c], grid[r + 1][c]
            if not can_down[a][b]:
                return False
    return True


def count_compatible_at(
    r: int,
    c: int,
    grid: list[list[int | None]],
    *,
    can_right: list[list[bool]],
    can_down: list[list[bool]],
    used: list[bool],
) -> int:
    n = 0
    for t in range(N_TILES):
        if used[t]:
            continue
        if c > 0:
            w = grid[r][c - 1]
            if w is not None and not can_right[w][t]:
                continue
        if r > 0:
            north = grid[r - 1][c]
            if north is not None and not can_down[north][t]:
                continue
        n += 1
    return n


def forward_check_ok(
    grid: list[list[int | None]],
    *,
    can_right: list[list[bool]],
    can_down: list[list[bool]],
    used: list[bool],
) -> bool:
    for r in range(GRID):
        for c in range(GRID):
            if grid[r][c] is not None:
                continue
            if count_compatible_at(r, c, grid, can_right=can_right, can_down=can_down, used=used) == 0:
                return False
    return True


def solve_legal_layout(
    *,
    can_right: list[list[bool]],
    can_down: list[list[bool]],
    rng: random.Random,
    forward_checking: bool,
) -> list[list[int]] | None:
    grid: list[list[int | None]] = [[None] * GRID for _ in range(GRID)]
    used = [False] * N_TILES
    order = [(r, c) for r in range(GRID) for c in range(GRID)]

    def backtrack(k: int) -> bool:
        if k == len(order):
            return True
        r, c = order[k]
        candidates = [t for t in range(N_TILES) if not used[t]]
        rng.shuffle(candidates)
        for t in candidates:
            if c > 0:
                w = grid[r][c - 1]
                if w is not None and not can_right[w][t]:
                    continue
            if r > 0:
                n = grid[r - 1][c]
                if n is not None and not can_down[n][t]:
                    continue
            grid[r][c] = t
            used[t] = True
            if forward_checking and not forward_check_ok(
                grid, can_right=can_right, can_down=can_down, used=used
            ):
                grid[r][c] = None
                used[t] = False
                continue
            if backtrack(k + 1):
                return True
            grid[r][c] = None
            used[t] = False
        return False

    if not backtrack(0):
        return None
    out: list[list[int]] = []
    for r in range(GRID):
        row: list[int] = []
        for c in range(GRID):
            v = grid[r][c]
            if v is None:
                raise RuntimeError("incomplete grid")
            row.append(v)
        out.append(row)
    return out


def write_layout_json(path: Path, grid: list[list[int]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    doc = {"wang_index": grid}
    path.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    LOG.info("wrote %s", path)


def rebuild_reference_png(run_dir: Path, grid: list[list[int]]) -> None:
    from PIL import Image

    ref_path = run_dir / "reference.png"
    tiles_dir = run_dir / "tiles"
    ref = Image.new("RGBA", (256, 256), (255, 255, 255, 255))
    for r in range(GRID):
        for c in range(GRID):
            ii = grid[r][c]
            tp = tiles_dir / f"tile_{ii:02d}.png"
            if not tp.is_file():
                continue
            cell = Image.open(tp).convert("RGBA")
            if cell.size != (TILE, TILE):
                cell.close()
                raise SystemExit(f"{tp} must be {TILE}×{TILE}, got {cell.size}")
            ref.paste(cell, (c * TILE, r * TILE))
            cell.close()
    ref.save(ref_path)
    ref.close()
    LOG.info("wrote %s from tiles/ + layout", ref_path)


def configure_logging(*, verbose: bool) -> None:
    logging.basicConfig(
        level=logging.DEBUG if verbose else logging.INFO,
        format="%(levelname)s [%(name)s] %(message)s",
        stream=sys.stderr,
        force=True,
    )


def main() -> None:
    repo = Path(__file__).resolve().parent.parent
    default_run = repo / "app/assets/images/terrain/base_64/wang_incremental"

    p = argparse.ArgumentParser(
        description="Generate legal 4×4 wang_index reference_layout.json (SPEC/ui/tileset/wang-reference-legal-layout-64.md)"
    )
    p.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Write JSON here (default: <run-dir>/reference_layout.json)",
    )
    p.add_argument(
        "--run-dir",
        type=Path,
        default=default_run,
        help=f"Run directory (default: {default_run.relative_to(repo)})",
    )
    p.add_argument("--seed", type=int, default=42, help="RNG seed for candidate tile order")
    p.add_argument(
        "--no-forward-checking",
        action="store_true",
        help="Disable forward checking (slower on average)",
    )
    p.add_argument(
        "--update-reference",
        action="store_true",
        help="Rebuild reference.png from tiles/ using the new layout",
    )
    p.add_argument("-v", "--verbose", action="store_true")
    args = p.parse_args()
    configure_logging(verbose=args.verbose)

    run_dir = args.run_dir.resolve()
    out_path = args.output.resolve() if args.output else (run_dir / "reference_layout.json")

    can_r, can_d = build_compatibility_tables()
    rng = random.Random(int(args.seed))
    grid = solve_legal_layout(
        can_right=can_r,
        can_down=can_d,
        rng=rng,
        forward_checking=not args.no_forward_checking,
    )
    if grid is None:
        LOG.error("No legal layout found (UNSAT for 16 tiles on 4×4 with these rules).")
        sys.exit(2)
    if not validate_layout(grid, can_right=can_r, can_down=can_d):
        LOG.error("Internal error: solver returned invalid layout")
        sys.exit(3)

    write_layout_json(out_path, grid)
    LOG.info("legal layout:\n%s", json.dumps(grid, indent=2))

    if args.update_reference:
        rebuild_reference_png(run_dir, grid)


if __name__ == "__main__":
    main()
