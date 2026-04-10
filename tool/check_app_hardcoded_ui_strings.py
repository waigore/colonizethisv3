#!/usr/bin/env python3
"""Fail when app/lib contains hardcoded user-visible UI string literals.

Primary lint is hardcoded_strings_lint, but this script closes known gaps
(multiline widgets, Semantics/Tooltip ordering, indirect labels, section titles).
Generated l10n outputs under app/lib/l10n/ are excluded.
"""

from __future__ import annotations

import os
import pathlib
import re
import sys
from collections.abc import Iterator


ROOT = pathlib.Path(__file__).resolve().parents[1]


def _workspace_root() -> pathlib.Path:
    override = os.environ.get("CT_HARDCODE_UI_CHECK_WORKSPACE")
    if override:
        return pathlib.Path(override).resolve()
    return ROOT


def _app_lib() -> pathlib.Path:
    return _workspace_root() / "app" / "lib"

# Normal Dart single-line string literals (no raw multiline ''' strings in UI checks).
_DART_QUOTED = r"(['\"])(?P<lit>(?:[^\\'\"\n]|\\.)*?)\1"

ALLOWED_LITERAL_PATTERNS = (
    re.compile(r"^\s*$"),
    re.compile(r"^[\W_]{1,2}$"),  # symbols, punctuation (incl. Unicode dash)
    re.compile(r"^[a-z]+_[a-z0-9_]+$"),  # technical identifiers
    re.compile(r"^[A-Z][A-Z0-9_]+$"),  # constant-like tokens
    re.compile(r"^/[\w/\-.]+$"),  # paths
)

# Multiline-safe patterns (full file, DOTALL). Quote captured as (?P<q>...).
MULTILINE_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    (
        "text_widget",
        re.compile(
            rf"\b(?:Text|SelectableText)\s*\(\s*{_DART_QUOTED}",
            re.DOTALL,
        ),
    ),
    (
        "dialog_title",
        re.compile(
            rf"\btitle:\s*(?:const\s+)?Text\s*\(\s*{_DART_QUOTED}",
            re.DOTALL,
        ),
    ),
    (
        "dialog_content",
        re.compile(
            rf"\bcontent:\s*(?:const\s+)?Text\s*\(\s*{_DART_QUOTED}",
            re.DOTALL,
        ),
    ),
    (
        "tooltip_message",
        re.compile(
            rf"\bTooltip\s*\(\s*[\s\S]{{0,2000}}?message\s*:\s*{_DART_QUOTED}",
            re.DOTALL,
        ),
    ),
    (
        "semantics_label",
        re.compile(
            rf"\bSemantics\s*\(\s*[\s\S]{{0,2000}}?label\s*:\s*{_DART_QUOTED}",
            re.DOTALL,
        ),
    ),
    (
        "input_label_text",
        re.compile(rf"\blabelText:\s*{_DART_QUOTED}", re.DOTALL),
    ),
    (
        "input_hint_text",
        re.compile(rf"\bhintText:\s*{_DART_QUOTED}", re.DOTALL),
    ),
    (
        "named_label_string",
        re.compile(
            rf"(?<![\w.])\blabel\s*:\s*{_DART_QUOTED}",
            re.DOTALL,
        ),
    ),
    (
        "build_section_title",
        re.compile(rf"\b_buildSection\s*\(\s*{_DART_QUOTED}", re.DOTALL),
    ),
)

_SINGLE_LINE_PATTERNS = (
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


def _line_starts(text: str) -> list[int]:
    starts = [0]
    for i, ch in enumerate(text):
        if ch == "\n":
            starts.append(i + 1)
    return starts


def _offset_to_line(line_starts: list[int], offset: int) -> int:
    lo, hi = 0, len(line_starts)
    while lo < hi:
        mid = (lo + hi) // 2
        if line_starts[mid] <= offset:
            lo = mid + 1
        else:
            hi = mid
    return lo


def _file_skipped_by_ignore_for_file(head: str) -> bool:
    return "ignore_for_file: avoid_hardcoded_strings_in_widgets" in head


def _ignored_lines(lines: list[str]) -> set[int]:
    ignored: set[int] = set()
    for idx, line in enumerate(lines, start=1):
        if "ignore: avoid_hardcoded_strings_in_widgets" in line:
            ignored.add(idx)
    return ignored


def _should_scan_dart(path: pathlib.Path) -> bool:
    rel = path.relative_to(_app_lib())
    parts = rel.parts
    if parts[0:1] == ("l10n",) and path.name.startswith("app_localizations"):
        return False
    return True


def iter_dart_files() -> list[pathlib.Path]:
    base = _app_lib()
    if not base.is_dir():
        return []
    return sorted(p for p in base.rglob("*.dart") if _should_scan_dart(p))


def _multiline_violations(
    path: pathlib.Path, text: str, lines: list[str], ignored: set[int]
) -> list[tuple[int, str]]:
    line_starts = _line_starts(text)
    seen_spans: set[tuple[int, int]] = set()
    violations: list[tuple[int, str]] = []

    for _name, pattern in MULTILINE_PATTERNS:
        for m in pattern.finditer(text):
            lit = m.group("lit")
            if is_allowed_literal(lit):
                continue
            start = m.start()
            line_no = _offset_to_line(line_starts, start)
            if line_no in ignored:
                continue
            end = m.end()
            span = (start, end)
            if span in seen_spans:
                continue
            seen_spans.add(span)
            line_text = lines[line_no - 1] if 0 < line_no <= len(lines) else ""
            violations.append((line_no, line_text.rstrip()))

    violations.sort(key=lambda t: t[0])
    return violations


def _legacy_line_violations(lines: list[str], ignored: set[int]) -> list[tuple[int, str]]:
    violations: list[tuple[int, str]] = []
    for idx, line in enumerate(lines, start=1):
        if idx in ignored:
            continue
        for pattern in _SINGLE_LINE_PATTERNS:
            match = pattern.search(line)
            if not match:
                continue
            literal = match.group(2).strip()
            if is_allowed_literal(literal):
                continue
            violations.append((idx, line.rstrip()))
            break
    return violations


def check_file(path: pathlib.Path) -> list[tuple[int, str]]:
    text = path.read_text(encoding="utf-8")
    head = "\n".join(text.splitlines()[:45])
    if _file_skipped_by_ignore_for_file(head):
        return []

    lines = text.splitlines()
    ignored = _ignored_lines(lines)

    merged: dict[int, str] = {}
    for line_no, snippet in _multiline_violations(path, text, lines, ignored):
        merged[line_no] = snippet
    for line_no, snippet in _legacy_line_violations(lines, ignored):
        merged.setdefault(line_no, snippet)
    return sorted(merged.items(), key=lambda kv: kv[0])


def iter_violations() -> Iterator[tuple[pathlib.Path, int, str]]:
    for dart_file in iter_dart_files():
        for line_no, snippet in check_file(dart_file):
            yield dart_file, line_no, snippet


def main() -> int:
    all_violations = list(iter_violations())

    if not all_violations:
        print("check_app_hardcoded_ui_strings: no violations found.")
        return 0

    print("Hardcoded UI string violations found in app/lib:")
    for path, line_no, snippet in all_violations:
        rel = path.relative_to(_workspace_root())
        print(f"- {rel}:{line_no}: {snippet}")
    print(
        f"\nTotal violations: {len(all_violations)}. "
        "Move user-visible strings to AppLocalizations/ARB."
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
