#!/usr/bin/env python3
"""
Write ``intermediate/anchors_{ii}.png`` (64×64 QA rasters) for Wang indices using the same
logic as ``wang_incremental_64.py`` — no API, no composite/mask/init_guide, no meta.

Donor arms for heterogeneous indices use ``donor_pool_for_target`` (incremental state or tiles on disk).

Spec: SPEC/ui/tileset/wang-incremental-edge-contracts-64-artifacts.md (anchors_{ii}.png).
"""
from __future__ import annotations

import argparse
import importlib.util
import logging
import sys
from pathlib import Path

from PIL import Image

LOG = logging.getLogger("pytool.wang_anchors_64")


def _load_wang_incremental_module():
    here = Path(__file__).resolve().parent
    path = here / "wang_incremental_64.py"
    spec = importlib.util.spec_from_file_location("wang_incremental_64", path)
    if spec is None or spec.loader is None:
        LOG.error("cannot load %s", path)
        sys.exit(1)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def configure_logging(*, verbose: bool) -> None:
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(level=level, format="%(levelname)s %(name)s: %(message)s")
    wi_log = logging.getLogger("pytool.wang_incremental_64")
    wi_log.setLevel(logging.DEBUG if verbose else logging.WARNING)


def main() -> None:
    repo = Path(__file__).resolve().parent.parent
    default_base = repo / "app/assets/images/terrain/base_64"
    default_run_dir = default_base / "wang_incremental"

    p = argparse.ArgumentParser(
        description=(
            "Regenerate anchors_{ii}.png (64×64) for incremental Wang runs; "
            "same corner crops as wang_incremental_64.py."
        )
    )
    p.add_argument(
        "--run-dir",
        type=Path,
        default=default_run_dir,
        help=f"Run directory with tiles/ (default: {default_run_dir.relative_to(repo)})",
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
        "--inter-dir",
        type=Path,
        default=None,
        help="Output directory (default: <run-dir>/intermediate)",
    )
    p.add_argument(
        "--only",
        type=int,
        default=None,
        metavar="II",
        help="Only wang_index II (0–15)",
    )
    p.add_argument("--verbose", "-v", action="store_true")
    args = p.parse_args()
    configure_logging(verbose=args.verbose)

    wi = _load_wang_incremental_module()

    run_dir = args.run_dir.resolve()
    plains_path = args.plains.resolve()
    sea_path = args.sea.resolve()
    tiles_dir = run_dir / "tiles"
    inter_dir = (args.inter_dir or (run_dir / "intermediate")).resolve()

    if not plains_path.is_file() or not sea_path.is_file():
        LOG.error("plains and sea bases must exist: %s %s", plains_path, sea_path)
        sys.exit(1)
    if not tiles_dir.is_dir():
        LOG.error("missing tiles directory: %s", tiles_dir)
        sys.exit(1)

    inter_dir.mkdir(parents=True, exist_ok=True)

    plains_img = Image.open(plains_path).convert("RGBA")
    sea_img = Image.open(sea_path).convert("RGBA")
    wi.assert_base_size(plains_img, plains_path)
    wi.assert_base_size(sea_img, sea_path)

    indices: list[int]
    if args.only is not None:
        if not 0 <= args.only <= 15:
            LOG.error("--only must be 0–15")
            sys.exit(1)
        indices = [args.only]
    else:
        indices = list(range(16))

    try:
        for ii in indices:
            anch_path = inter_dir / f"anchors_{ii:02d}.png"
            if ii in (0, 15):
                _c, _m, anchors_only = wi.build_homogeneous_intermediate_64(
                    plains_img, sea_img, ii
                )
            else:
                donor_pool = wi.donor_pool_for_target(run_dir, tiles_dir, ii)
                _comp, _mask, anchors_only, _k, _arms = wi.build_heterogeneous_cross_assets(
                    plains=plains_img,
                    sea=sea_img,
                    ii=ii,
                    donor_pool=donor_pool,
                    tiles_dir=tiles_dir,
                )
            anchors_only.save(anch_path)
            anchors_only.close()
            LOG.info("wrote %s", anch_path)
    finally:
        plains_img.close()
        sea_img.close()


if __name__ == "__main__":
    main()
