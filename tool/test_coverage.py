#!/usr/bin/env python3
"""
Run all tests with coverage (packages, app, ctdev, tool/*). Exit immediately on first test failure.
Merge lcov files and print per-target + overall coverage. See SPEC/program/test-logging.md.

Sets SUPPRESS_IMAGE_VIEWER=1 for all test runs (Dart and Flutter) so image preview does not open.
"""
from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
# Filter test output: box-drawing, common emoji, and ctdev-logging prefixes (SPEC/program/ctdev-logging.md).
LOG_FILTER = re.compile(
    r"[\u250c\u251c\u2500\u2514\u2502]|\u2139|\u1f41b|\u26a0\ufe0f"
    r"|ctdev: |logic: |ai: |data: |map: |save: "
)

PACKAGES = [
    "packages/colonizethis_models",
    "packages/colonizethis_data",
    "packages/colonizethis_save",
    "packages/colonizethis_logic",
    "packages/colonizethis_ai",
    "packages/colonizethis_map",
]
TOOL_PACKAGES = [
    "tool/sim_scenarios",
    "tool/sim_combat_montecarlo",
    "tool/sim_combat",
    "tool/generate_map",
    "tool/init_game",
    "tool/sim_economy",
    "tool/show_tech",
    "tool/run_observer_game",
]


def filter_log(lines: str) -> str:
    return "\n".join(line for line in lines.splitlines() if not LOG_FILTER.search(line))


def run(cmd: list[str], cwd: Path, env: dict | None = None) -> tuple[int, str]:
    env = {**os.environ, **(env or {})}
    result = subprocess.run(
        cmd,
        cwd=cwd,
        capture_output=True,
        text=True,
        env=env,
    )
    out = (result.stdout or "") + (result.stderr or "")
    return result.returncode, out


def run_tests_dart(rel_dir: str, env: dict | None = None) -> int:
    dir_path = ROOT / rel_dir
    if not (dir_path / "test").is_dir():
        return 0
    code, out = run(["dart", "test", "--coverage=coverage"], cwd=dir_path, env=env)
    print(filter_log(out), end="")
    if code != 0:
        return code
    run(
        [
            "dart",
            "run",
            "coverage:format_coverage",
            "--lcov",
            "-i",
            "coverage",
            "-o",
            "coverage/lcov.info",
            "--report-on=lib",
            "--package=.",
        ],
        cwd=dir_path,
        env=env,
    )
    return 0


def run_tests_flutter(rel_dir: str, env: dict | None = None) -> int:
    dir_path = ROOT / rel_dir
    code, out = run(["flutter", "test", "--coverage"], cwd=dir_path, env=env)
    print(filter_log(out), end="")
    return code


def lcov_summary(lcov_path: Path) -> str | None:
    if not lcov_path.is_file():
        return None
    try:
        result = subprocess.run(
            ["lcov", "--summary", str(lcov_path)],
            capture_output=True,
            text=True,
            cwd=ROOT,
        )
        if result.returncode != 0:
            return None
        return result.stdout
    except FileNotFoundError:
        return None


def parse_lcov_line_coverage(lcov_path: Path) -> tuple[int, int] | None:
    """Return (hit_lines, total_lines) or None."""
    if not lcov_path.is_file():
        return None
    hit, total = 0, 0
    with open(lcov_path) as f:
        for line in f:
            if line.startswith("DA:"):
                total += 1
                if int(line.split(",", 1)[1].strip()) > 0:
                    hit += 1
    return (hit, total) if total else None


def summarize_lcov_parsed(lcov_path: Path) -> str:
    data = parse_lcov_line_coverage(lcov_path)
    if data is None:
        return "(no data or unreadable)"
    hit, total = data
    pct = (100.0 * hit / total) if total else 0
    return f"lines......: {pct:.1f}% ({hit}/{total})"


def main() -> int:
    env = {**os.environ, "SUPPRESS_IMAGE_VIEWER": "1"}

    for rel in PACKAGES:
        code = run_tests_dart(rel, env=env)
        if code != 0:
            print(f"Tests failed in {rel} (exit {code})", file=sys.stderr)
            return code

    if (ROOT / "app").is_dir():
        code = run_tests_flutter("app", env=env)
        if code != 0:
            print("Tests failed in app", file=sys.stderr)
            return code

    if (ROOT / "ctdev" / "test").is_dir():
        code = run_tests_flutter("ctdev", env=env)
        if code != 0:
            print("Tests failed in ctdev", file=sys.stderr)
            return code

    for rel in TOOL_PACKAGES:
        code = run_tests_dart(rel, env=env)
        if code != 0:
            print(f"Tests failed in {rel} (exit {code})", file=sys.stderr)
            return code

    coverage_files: list[Path] = []
    for rel in ["app", "ctdev"] + PACKAGES + TOOL_PACKAGES:
        p = ROOT / rel / "coverage" / "lcov.info"
        if p.is_file() and parse_lcov_line_coverage(p) is not None:
            coverage_files.append(p)

    has_lcov = shutil.which("lcov")

    print("\n=== Coverage breakdown ===")
    for rel in ["app", "ctdev"] + PACKAGES + TOOL_PACKAGES:
        p = ROOT / rel / "coverage" / "lcov.info"
        if not p.is_file():
            continue
        print(f"--- {rel} ---")
        if has_lcov:
            summary = lcov_summary(p)
            if summary:
                for line in summary.splitlines():
                    if "lines" in line or "source" in line:
                        print(line)
            else:
                print(summarize_lcov_parsed(p))
        else:
            print(summarize_lcov_parsed(p))

    if not coverage_files:
        print("\nNo lcov.info files found.")
        print("Per-target coverage: app/coverage/, ctdev/coverage/, packages/*/coverage/, tool/*/coverage/")
        return 0

    merge_dir = ROOT / "coverage_merged"
    merge_dir.mkdir(exist_ok=True)
    merge_file = merge_dir / "all.info"

    if has_lcov:
        merge_args = ["lcov"] + [x for f in coverage_files for x in ["-a", str(f)]] + ["-o", str(merge_file)]
        if subprocess.run(merge_args, cwd=ROOT).returncode == 0:
            subprocess.run(
                [
                    "lcov",
                    "-q",
                    "--remove",
                    str(merge_file),
                    "*.g.dart",
                    "*.freezed.dart",
                    "-o",
                    str(merge_file),
                ],
                cwd=ROOT,
                capture_output=True,
            )
            print("\n--- Overall (merged) ---")
            subprocess.run(["lcov", "--summary", str(merge_file)], cwd=ROOT)
            print("Per-target coverage: app/coverage/, ctdev/coverage/, packages/*/coverage/, tool/*/coverage/")
            print(f"Merged: {merge_file}")
        else:
            print("\nOverall merge failed. Per-target coverage is still available above.")
            print("Per-target coverage: app/coverage/, ctdev/coverage/, packages/*/coverage/, tool/*/coverage/")
    else:
        total_hit = total_lines = 0
        for p in coverage_files:
            data = parse_lcov_line_coverage(p)
            if data:
                total_hit += data[0]
                total_lines += data[1]
        if total_lines:
            pct = 100.0 * total_hit / total_lines
            print("\n--- Overall (merged, approximated) ---")
            print(f"lines......: {pct:.1f}% ({total_hit}/{total_lines})")
        print("Install lcov for exact merged summary and exclusion of generated files.")
        print("Per-target coverage: app/coverage/, ctdev/coverage/, packages/*/coverage/, tool/*/coverage/")

    return 0


if __name__ == "__main__":
    sys.exit(main())
