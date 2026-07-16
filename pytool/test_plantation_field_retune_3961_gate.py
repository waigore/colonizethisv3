#!/usr/bin/env python3
"""Quality gate: plantation field-retune pytool tests (Refs #3961).

Runs paint, finalize, and PO review-strip unittest modules in one CI step.
No network; requires Pillow and committed candidate PNGs.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PYTOOL = REPO / "pytool"
TESTS = (
    "test_paint_plains_plantation_field_gradients.py",
    "test_finalize_plantation_field_retune_3961.py",
    "test_render_plantation_po_review_strip_3961.py",
)


def main() -> None:
    for name in TESTS:
        path = PYTOOL / name
        if not path.is_file():
            raise SystemExit(f"missing gate test module: {path}")
        print(f"=== {name} ===", flush=True)
        result = subprocess.run([sys.executable, str(path)], check=False)
        if result.returncode != 0:
            raise SystemExit(result.returncode)
    print("plantation field retune gate: OK", flush=True)


if __name__ == "__main__":
    main()
