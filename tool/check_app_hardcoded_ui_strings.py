#!/usr/bin/env python3
"""Fail when app/lib contains hardcoded user-visible UI string literals.

Primary lint is hardcoded_strings_lint, but this script closes known gaps
by checking common widget/UI literal patterns directly in source lines.
"""

from __future__ import annotations

import pathlib
import re
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]
APP_LIB = ROOT / "app" / "lib"

ALLOWED_LITERAL_PATTERNS = (
    re.compile(r"^\s*$"),
    re.compile(r"^[\W_]{1,2}$"),  # symbols, punctuation
    re.compile(r"^[a-z]+_[a-z0-9_]+$"),  # technical identifiers
    re.compile(r"^[A-Z][A-Z0-9_]+$"),  # constant-like tokens
    re.compile(r"^/[\w/\-.]+$"),  # paths
)

# Widget/UI call patterns where direct string literals are disallowed.
UI_LITERAL_PATTERNS = (
    re.compile(r"""Text\(\s*(['"])(.+?)\1"""),
    re.compile(r"""Tooltip\(\s*message:\s*(['"])(.+?)\1"""),
    re.compile(r"""labelText:\s*(['"])(.+?)\1"""),
    re.compile(r"""hintText:\s*(['"])(.+?)\1"""),
    re.compile(r"""title:\s*Text\(\s*(['"])(.+?)\1"""),
    re.compile(r"""content:\s*Text\(\s*(['"])(.+?)\1"""),
)


def is_allowed_literal(value: str) -> bool:
    if len(value) <= 2:
        return True
    return any(pattern.match(value) for pattern in ALLOWED_LITERAL_PATTERNS)


def iter_dart_files() -> list[pathlib.Path]:
    return sorted(APP_LIB.rglob("*.dart"))


def check_file(path: pathlib.Path) -> list[tuple[int, str]]:
    violations: list[tuple[int, str]] = []
    lines = path.read_text(encoding="utf-8").splitlines()
    for idx, line in enumerate(lines, start=1):
        if "ignore: avoid_hardcoded_strings_in_widgets" in line:
            continue
        if "ignore_for_file: avoid_hardcoded_strings_in_widgets" in line:
            continue
        for pattern in UI_LITERAL_PATTERNS:
            match = pattern.search(line)
            if not match:
                continue
            literal = match.group(2).strip()
            if is_allowed_literal(literal):
                continue
            violations.append((idx, line.rstrip()))
            break
    return violations


def main() -> int:
    all_violations: list[tuple[pathlib.Path, int, str]] = []
    for dart_file in iter_dart_files():
        for line_no, snippet in check_file(dart_file):
            all_violations.append((dart_file, line_no, snippet))

    if not all_violations:
        print("check_app_hardcoded_ui_strings: no violations found.")
        return 0

    print("Hardcoded UI string violations found in app/lib:")
    for path, line_no, snippet in all_violations:
        rel = path.relative_to(ROOT)
        print(f"- {rel}:{line_no}: {snippet}")
    print(
        f"\nTotal violations: {len(all_violations)}. "
        "Move user-visible strings to AppLocalizations/ARB."
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
