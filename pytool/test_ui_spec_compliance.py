"""Tests for ui_spec_compliance.py (issue #2784 rubric)."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPT = REPO_ROOT / "pytool" / "ui_spec_compliance.py"


def test_all_in_scope_specs_class_c() -> None:
    result = subprocess.run(
        [sys.executable, str(SCRIPT)],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    assert "Compliant (Class C): 20/20" in result.stdout
