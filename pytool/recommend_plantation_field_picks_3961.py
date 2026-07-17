#!/usr/bin/env python3
"""Print map-harmony plantation field pick recommendation (Refs #3961).

Scores committed candidates under ``plantation_field_candidates_3961/`` against
shipped OW plains reference tiles. Does not modify app terrain.

See SPEC/ui/pytool-image-tools.md § recommend_plantation_field_picks_3961.py.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

_PYTOOL = Path(__file__).resolve().parent
if str(_PYTOOL) not in sys.path:
    sys.path.insert(0, str(_PYTOOL))

from plantation_field_harmony_3961 import (
    DEFAULT_CANDIDATES,
    DEFAULT_TERRAIN,
    describe_recommendation,
    format_picks,
    parse_po_picks_from_text,
    recommend_picks,
)

REPO = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--candidate-dir",
        type=Path,
        default=DEFAULT_CANDIDATES,
    )
    parser.add_argument(
        "--terrain-dir",
        type=Path,
        default=DEFAULT_TERRAIN,
    )
    parser.add_argument(
        "--parse-text",
        type=str,
        default="",
        help="Parse PO lock from comment text; prints picks or exits 2 if incomplete",
    )
    parser.add_argument(
        "--markdown",
        action="store_true",
        help="Emit issue-comment markdown (default: picks line only)",
    )
    args = parser.parse_args()
    if args.parse_text.strip():
        picks = parse_po_picks_from_text(args.parse_text)
        if picks is None:
            raise SystemExit(2)
        print(format_picks(picks))
        return
    if args.markdown:
        print(
            describe_recommendation(
                candidate_dir=args.candidate_dir,
                terrain_dir=args.terrain_dir,
            ),
        )
        return
    picks = recommend_picks(candidate_dir=args.candidate_dir, terrain_dir=args.terrain_dir)
    print(format_picks(picks))


if __name__ == "__main__":
    main()
