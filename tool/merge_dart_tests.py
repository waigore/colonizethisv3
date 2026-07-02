#!/usr/bin/env python3
"""Merge multiple Dart test files into one (groups only, deduped imports)."""

from __future__ import annotations

import re
import sys
from pathlib import Path


def extract_imports_and_body(content: str) -> tuple[list[str], str, list[str]]:
    """Return (imports, main_body, file_level_directives)."""
    lines = content.splitlines()
    imports: list[str] = []
    directives: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if line.startswith('//') and 'ignore_for_file' in line:
            directives.append(lines[i])
            i += 1
            continue
        if line.startswith('import ') or line.startswith('export '):
            imports.append(lines[i])
            i += 1
            continue
        if line == '' or line.startswith('///') or line.startswith('//'):
            i += 1
            continue
        break

    rest = '\n'.join(lines[i:])
    match = re.search(r'void\s+main\s*\(\s*\)\s*\{', rest)
    if not match:
        raise ValueError('No void main() found')
    start = match.end()
    # Find matching closing brace for main
    depth = 1
    pos = start
    while pos < len(rest) and depth > 0:
        if rest[pos] == '{':
            depth += 1
        elif rest[pos] == '}':
            depth -= 1
        pos += 1
    body = rest[start : pos - 1].strip()
    return imports, body, directives


def merge_test_files(
    output: Path,
    inputs: list[Path],
    *,
    extra_imports: list[str] | None = None,
    header_comment: str | None = None,
) -> None:
    all_imports: list[str] = []
    all_directives: list[str] = []
    bodies: list[str] = []

    for path in inputs:
        content = path.read_text()
        imports, body, directives = extract_imports_and_body(content)
        all_imports.extend(imports)
        all_directives.extend(directives)
        bodies.append(body)

    if extra_imports:
        all_imports.extend(extra_imports)

    # Dedupe imports/directives preserving order
    seen: set[str] = set()
    unique_imports: list[str] = []
    for imp in all_imports:
        if imp not in seen:
            seen.add(imp)
            unique_imports.append(imp)

    seen_d: set[str] = set()
    unique_directives: list[str] = []
    for d in all_directives:
        if d not in seen_d:
            seen_d.add(d)
            unique_directives.append(d)

    parts: list[str] = []
    if header_comment:
        parts.append(header_comment)
    parts.extend(unique_directives)
    if unique_directives:
        parts.append('')
    parts.extend(unique_imports)
    parts.append('')
    parts.append('void main() {')
    for body in bodies:
        parts.append(body)
        parts.append('')
    parts.append('}')

    output.write_text('\n'.join(parts) + '\n')
    print(f'Wrote {output} ({len(inputs)} files merged)')


def main() -> None:
    if len(sys.argv) < 3:
        print('Usage: merge_dart_tests.py <output.dart> <input1.dart> ...')
        sys.exit(1)
    output = Path(sys.argv[1])
    inputs = [Path(p) for p in sys.argv[2:]]
    merge_test_files(output, inputs)


if __name__ == '__main__':
    main()
