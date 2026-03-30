#!/usr/bin/env python3
"""
Paste a finished Wang tile (64×64) into the center cell of its 192×192 cross composite for
transition QA. Spec: SPEC/ui/pytool-image-tools.md, tileset specs under SPEC/ui/tileset/.

**Incremental (default):** ``tiles/tile_XX.png`` over ``intermediate/composite_XX.png``.

**Legacy batch tree:** ``out/tile_XX.png`` over ``intermediate/cross/composite_XX.png``.

If the composite is missing and synthesis is allowed, loads the archived generator from
``pytool/archive/generate_sea_plains_wang_inpaint_64.py`` (requires ``contracts_128/`` on disk).
"""
from __future__ import annotations

import argparse
import importlib.util
import sys
from pathlib import Path

from PIL import Image

CROSS_CANVAS = 192
CROSS_CENTER_OFF = 64
TILE_SIZE = 64


def repo_root_from_here() -> Path:
    return Path(__file__).resolve().parent.parent


def default_incremental_root(repo: Path) -> Path:
    return repo / "app/assets/images/terrain/base_64/wang_incremental"


def default_base_64_dir(repo: Path) -> Path:
    return repo / "app/assets/images/terrain/base_64"


def load_archived_generator():
    """Load archived batch generator by path (not on default pytool package path)."""
    archive = Path(__file__).resolve().parent / "archive" / "generate_sea_plains_wang_inpaint_64.py"
    if not archive.is_file():
        print(f"Archived generator missing: {archive}", file=sys.stderr)
        sys.exit(1)
    spec = importlib.util.spec_from_file_location("gen_sea_plains_archived", archive)
    if spec is None or spec.loader is None:
        print("Could not load archived generator module spec", file=sys.stderr)
        sys.exit(1)
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


def synthesize_cross_from_contracts(
    idx: int,
    *,
    root: Path,
    plains_path: Path,
    sea_path: Path,
    cross_corner_hints: bool,
    cross_ns_contract_inset_px: int,
) -> Image.Image:
    gen = load_archived_generator()
    edge_proto_root = root / "intermediate" / "edge_prototypes"
    gen.assert_edge_contracts_present(edge_proto_root)
    nw, ne, sw, se = gen.wang_index_to_corners(idx)
    plains = Image.open(plains_path).convert("RGBA")
    sea = Image.open(sea_path).convert("RGBA")
    if plains.size != (TILE_SIZE, TILE_SIZE) or sea.size != (TILE_SIZE, TILE_SIZE):
        print("plains and sea bases must be 64×64", file=sys.stderr)
        sys.exit(1)
    cpaths = gen.contract_paths(edge_proto_root)
    return gen.build_cross_composite(
        nw,
        ne,
        sw,
        se,
        cpaths=cpaths,
        plains=plains,
        sea=sea,
        dry_run=False,
        use_corner_hints=cross_corner_hints,
        ns_contract_inset_px=cross_ns_contract_inset_px,
    )


def detect_layout(root: Path) -> str:
    """Return 'incremental' if tiles/ exists, else 'batch'."""
    if (root / "tiles").is_dir():
        return "incremental"
    return "batch"


def tile_and_composite_paths(
    layout: str, root: Path, idx: int
) -> tuple[Path, Path, Path]:
    """Return (tile_path, composite_path, default_preview_out)."""
    if layout == "incremental":
        tile = root / "tiles" / f"tile_{idx:02d}.png"
        comp = root / "intermediate" / f"composite_{idx:02d}.png"
        prev = root / "intermediate" / f"preview_tile_{idx:02d}_in_cross.png"
    else:
        tile = root / "out" / f"tile_{idx:02d}.png"
        comp = root / "intermediate" / "cross" / f"composite_{idx:02d}.png"
        prev = root / "intermediate" / "cross" / f"preview_tile_{idx:02d}_in_cross.png"
    return tile, comp, prev


def write_one_preview(
    idx: int,
    *,
    root: Path,
    layout: str | None,
    plains_path: Path,
    sea_path: Path,
    output_path: Path | None,
    synthesize_if_missing: bool,
    cross_corner_hints: bool,
    cross_ns_contract_inset_px: int,
) -> bool:
    lay = layout or detect_layout(root)
    tile_path, comp_path, default_prev = tile_and_composite_paths(lay, root, idx)
    out_path = output_path.resolve() if output_path else default_prev

    if not tile_path.is_file():
        print(f"[{idx:02d}] skip: missing tile {tile_path}", flush=True)
        return False

    if comp_path.is_file():
        base = Image.open(comp_path).convert("RGBA")
        source = "saved composite"
    elif synthesize_if_missing:
        if lay != "batch":
            print(
                f"[{idx:02d}] skip: missing {comp_path} (synthesis only for batch + contracts_128)",
                flush=True,
            )
            return False
        gen = load_archived_generator()
        if not gen.MIN_CROSS_NS_CONTRACT_INSET_PX <= cross_ns_contract_inset_px <= gen.MAX_CROSS_NS_CONTRACT_INSET_PX:
            print(
                f"--cross-ns-contract-inset must be in "
                f"[{gen.MIN_CROSS_NS_CONTRACT_INSET_PX}, {gen.MAX_CROSS_NS_CONTRACT_INSET_PX}]",
                file=sys.stderr,
            )
            sys.exit(1)
        base = synthesize_cross_from_contracts(
            idx,
            root=root,
            plains_path=plains_path,
            sea_path=sea_path,
            cross_corner_hints=cross_corner_hints,
            cross_ns_contract_inset_px=cross_ns_contract_inset_px,
        )
        source = "synthesized composite (archived)"
    else:
        print(f"Missing composite: {comp_path}", file=sys.stderr)
        sys.exit(1)

    if base.size != (CROSS_CANVAS, CROSS_CANVAS):
        print(f"Expected {CROSS_CANVAS}×{CROSS_CANVAS} composite, got {base.size}", file=sys.stderr)
        sys.exit(1)

    tile = Image.open(tile_path).convert("RGBA")
    if tile.size != (TILE_SIZE, TILE_SIZE):
        print(f"Expected {TILE_SIZE}×{TILE_SIZE} tile, got {tile.size}", file=sys.stderr)
        sys.exit(1)

    merged = base.copy()
    merged.paste(tile, (CROSS_CENTER_OFF, CROSS_CENTER_OFF), tile)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    merged.save(out_path, format="PNG")
    print(f"[{idx:02d}] Wrote {out_path} ({source})", flush=True)
    return True


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Overlay tile on cross composite center for transition QA.",
    )
    parser.add_argument(
        "--wang-index",
        type=int,
        default=None,
        metavar="N",
        help="0–15 (default 1 when not using --all; omit with --all)",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Write preview for every index 0–15 that has a tile",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=None,
        help="Wang run root (default: app/.../wang_incremental)",
    )
    parser.add_argument(
        "--layout",
        choices=("incremental", "batch", "auto"),
        default="auto",
        help="Tile/composite layout (default: auto from --out-dir)",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="Output PNG (single --wang-index only)",
    )
    parser.add_argument(
        "--no-synthesize-composite",
        action="store_true",
        help="Require saved composite; for batch only, do not build from contracts_128",
    )
    parser.add_argument(
        "--cross-corner-hints",
        action=argparse.BooleanOptionalAction,
        default=False,
        help="When synthesizing (batch): paste 10×10 corner hints",
    )
    parser.add_argument(
        "--cross-ns-contract-inset",
        type=int,
        default=8,
        metavar="PX",
        help="When synthesizing (batch): N/S arm inset px (validated against archived generator)",
    )
    args = parser.parse_args()
    repo = repo_root_from_here()
    root = args.out_dir.resolve() if args.out_dir else default_incremental_root(repo)
    b64 = default_base_64_dir(repo)
    plains_path = b64 / "plains_base_64.png"
    sea_path = b64 / "sea_base_64.png"

    lay: str | None = None if args.layout == "auto" else args.layout
    synthesize = not args.no_synthesize_composite

    if args.all:
        if args.wang_index is not None:
            print("Do not pass --wang-index with --all", file=sys.stderr)
            sys.exit(1)
        if args.output is not None:
            print("Do not pass -o/--output with --all", file=sys.stderr)
            sys.exit(1)
        n = 0
        for idx in range(16):
            if write_one_preview(
                idx,
                root=root,
                layout=lay,
                plains_path=plains_path,
                sea_path=sea_path,
                output_path=None,
                synthesize_if_missing=synthesize,
                cross_corner_hints=args.cross_corner_hints,
                cross_ns_contract_inset_px=args.cross_ns_contract_inset,
            ):
                n += 1
        print(f"Done. {n} preview(s).", flush=True)
        return

    idx = 1 if args.wang_index is None else args.wang_index
    if not 0 <= idx <= 15:
        print(f"--wang-index must be 0–15, got {idx}", file=sys.stderr)
        sys.exit(1)

    if synthesize and (lay or detect_layout(root)) == "batch":
        gen = load_archived_generator()
        if not gen.MIN_CROSS_NS_CONTRACT_INSET_PX <= args.cross_ns_contract_inset <= gen.MAX_CROSS_NS_CONTRACT_INSET_PX:
            print(
                f"--cross-ns-contract-inset must be in "
                f"[{gen.MIN_CROSS_NS_CONTRACT_INSET_PX}, {gen.MAX_CROSS_NS_CONTRACT_INSET_PX}]",
                file=sys.stderr,
            )
            sys.exit(1)

    write_one_preview(
        idx,
        root=root,
        layout=lay,
        plains_path=plains_path,
        sea_path=sea_path,
        output_path=args.output,
        synthesize_if_missing=synthesize,
        cross_corner_hints=args.cross_corner_hints,
        cross_ns_contract_inset_px=args.cross_ns_contract_inset,
    )


if __name__ == "__main__":
    main()
