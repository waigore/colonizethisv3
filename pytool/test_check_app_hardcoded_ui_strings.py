"""Tests for tool/check_app_hardcoded_ui_strings.py.

Run from repo root: python3 pytool/test_check_app_hardcoded_ui_strings.py
"""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

_REPO = Path(__file__).resolve().parents[1]
_SCRIPT = _REPO / "tool" / "check_app_hardcoded_ui_strings.py"


def _run_checker(workspace: Path) -> int:
    env = {**os.environ, "CT_HARDCODE_UI_CHECK_WORKSPACE": str(workspace)}
    proc = subprocess.run(
        [sys.executable, str(_SCRIPT)],
        env=env,
        cwd=str(_REPO),
        capture_output=True,
        text=True,
    )
    return proc.returncode


class TestHardcodedUiStrings(unittest.TestCase):
    def test_passes_when_no_string_literal_in_text(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            lib = root / "app" / "lib"
            lib.mkdir(parents=True)
            (lib / "a.dart").write_text(
                "import 'p';\nvoid f() { Text(l10n.foo); }\n",
                encoding="utf-8",
            )
            self.assertEqual(_run_checker(root), 0)

    def test_fails_on_text_with_quoted_literal(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            lib = root / "app" / "lib"
            lib.mkdir(parents=True)
            (lib / "a.dart").write_text(
                'import "p";\nvoid f() { Text("Hello"); }\n',
                encoding="utf-8",
            )
            self.assertEqual(_run_checker(root), 1)

    def test_skips_generated_app_localizations_dart(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            lib = root / "app" / "lib" / "l10n"
            lib.mkdir(parents=True)
            (lib / "app_localizations_en.dart").write_text(
                'const x = "Generated English";\n',
                encoding="utf-8",
            )
            self.assertEqual(_run_checker(root), 0)


if __name__ == "__main__":
    unittest.main()
