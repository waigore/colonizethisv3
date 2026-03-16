from __future__ import annotations

import argparse
import json
import os
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, Iterator, Mapping, MutableMapping, Optional, Tuple


REPO_ROOT_SENTINELS = {".git", "melos.yaml", "pubspec.yaml", "SPEC"}

IGNORE_DIR_NAMES = {
    ".git",
    ".dart_tool",
    ".idea",
    ".vscode",
    "build",
    ".venv",
    "venv",
    ".env",
    ".tox",
    ".mypy_cache",
    ".pytest_cache",
    "__pycache__",
}


CODE_EXT_LANGUAGE: Mapping[str, str] = {
    ".dart": "Dart",
    ".py": "Python",
    ".yaml": "YAML",
    ".yml": "YAML",
    ".json": "JSON",
    ".md": "Markdown",
    ".toml": "TOML",
    ".xml": "XML",
}

ASSET_EXT_TYPE: Mapping[str, str] = {
    ".png": "Image",
    ".jpg": "Image",
    ".jpeg": "Image",
    ".gif": "Image",
    ".webp": "Image",
    ".wav": "Audio",
    ".mp3": "Audio",
    ".ogg": "Audio",
    ".flac": "Audio",
    ".yarn": "Data",
    ".json": "Data",
}


@dataclass(frozen=True)
class PackageInfo:
    name: str
    root: Path


@dataclass(frozen=True)
class FileClassification:
    category: str
    language_or_type: str
    package_name: str
    is_test: bool


def find_repo_root(start: Path) -> Path:
    current = start.resolve()
    for parent in [current, *current.parents]:
        entries = {entry.name for entry in parent.iterdir()} if parent.is_dir() else set()
        if REPO_ROOT_SENTINELS & entries:
            return parent
    # Fallback to the original start if no sentinel is found.
    return current


def discover_packages(repo_root: Path) -> Tuple[PackageInfo, ...]:
    packages: list[PackageInfo] = []
    for dirpath, _dirnames, filenames in os.walk(repo_root):
        if "pubspec.yaml" not in filenames:
            continue
        pubspec_path = Path(dirpath) / "pubspec.yaml"
        name = _extract_pubspec_name(pubspec_path) or pubspec_path.parent.name
        packages.append(PackageInfo(name=name, root=pubspec_path.parent.resolve()))
    # Sort by root path length so we can choose the deepest (most specific) match.
    packages.sort(key=lambda p: len(str(p.root)))
    return tuple(packages)


def _extract_pubspec_name(pubspec_path: Path) -> Optional[str]:
    try:
        with pubspec_path.open("r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if line.startswith("name:"):
                    # Handle formats like "name: value" or "name:  value"
                    _, value = line.split("name:", 1)
                    value = value.strip().strip('"').strip("'")
                    return value or None
    except OSError:
        return None
    return None


class PackageIndex:
    def __init__(self, packages: Iterable[PackageInfo], repo_root: Path) -> None:
        # Sort by descending path length so the first match is the innermost package.
        self._packages = sorted(packages, key=lambda p: len(str(p.root)), reverse=True)
        self._repo_root = repo_root.resolve()

    def resolve(self, path: Path) -> str:
        info = self.resolve_info(path)
        return info.name if info is not None else "__no_package__"

    def resolve_info(self, path: Path) -> Optional[PackageInfo]:
        for pkg in self._packages:
            try:
                path.relative_to(pkg.root)
            except ValueError:
                continue
            # Skip the synthetic root workspace package; we only want concrete subpackages/apps.
            if pkg.root.resolve() == self._repo_root:
                continue
            return pkg
        return None


def iter_files(root: Path) -> Iterator[Path]:
    root = root.resolve()
    for dirpath, dirnames, filenames in os.walk(root):
        # Skip any subtree that is inside a virtual environment directory.
        dirpath_parts = Path(dirpath).parts
        if any(part in {".venv", "venv"} for part in dirpath_parts):
            continue
        # In-place filter of directories to skip ignored dirs.
        dirnames[:] = [d for d in dirnames if d not in IGNORE_DIR_NAMES]
        for filename in filenames:
            yield Path(dirpath).resolve() / filename


def classify_file(path: Path, repo_root: Path, pkg_index: PackageIndex) -> Optional[FileClassification]:
    try:
        rel = path.resolve().relative_to(repo_root.resolve())
    except ValueError:
        # Skip files that are not actually under the repository root (e.g. symlinks into system dirs).
        return None
    parts = rel.parts
    ext = path.suffix.lower()

    if parts and parts[0] == "SPEC":
        category = "spec"
        language = CODE_EXT_LANGUAGE.get(ext, "Unknown")
    elif "assets" in parts:
        category = "asset"
        language = ASSET_EXT_TYPE.get(ext, "Other")
    else:
        if ext in CODE_EXT_LANGUAGE:
            # Only count Python files that live under known repo-owned tool roots.
            if ext == ".py":
                top = parts[0] if parts else ""
                if top not in {"pytool", "tool"}:
                    return None
            category = "code"
            language = CODE_EXT_LANGUAGE[ext]
        else:
            return None

    pkg_info = pkg_index.resolve_info(path)
    package_name = pkg_info.name if pkg_info is not None else "__no_package__"
    is_test = _is_test_file(path, pkg_info.root) if pkg_info is not None else False
    return FileClassification(
        category=category,
        language_or_type=language,
        package_name=package_name,
        is_test=is_test,
    )


def _is_test_file(path: Path, package_root: Path) -> bool:
    """Heuristically determine whether a file is a test file within a Dart package."""
    try:
        rel_to_pkg = path.resolve().relative_to(package_root.resolve())
    except ValueError:
        return False

    parts = rel_to_pkg.parts
    if not parts:
        return False

    # Common Dart test directories.
    first_segment = parts[0]
    if first_segment in {"test", "integration_test", "widget_test"}:
        return True

    # Dart test file naming convention.
    if path.suffix == ".dart" and path.name.endswith("_test.dart"):
        return True

    return False


def count_lines(path: Path) -> int:
    try:
        with path.open("r", encoding="utf-8", errors="ignore") as f:
            return sum(1 for _ in f)
    except OSError:
        return 0


def _inc(counter: MutableMapping[str, int], key: str, files: int, lines: int) -> None:
    files_key = f"{key}__files"
    lines_key = f"{key}__lines"
    counter[files_key] = counter.get(files_key, 0) + files
    counter[lines_key] = counter.get(lines_key, 0) + lines


def _ensure_nested(
    mapping: MutableMapping[str, MutableMapping[str, int]],
    outer: str,
) -> MutableMapping[str, int]:
    if outer not in mapping:
        mapping[outer] = {}
    return mapping[outer]


def aggregate_stats(
    files: Iterable[Path],
    repo_root: Path,
    pkg_index: PackageIndex,
) -> Dict[str, object]:
    totals: Dict[str, int] = {}
    by_language: Dict[str, Dict[str, int]] = {}
    by_package: Dict[str, Dict[str, int]] = {}
    by_package_language: Dict[str, Dict[str, int]] = {}
    by_role: Dict[str, Dict[str, int]] = {}
    by_package_role: Dict[str, Dict[str, int]] = {}

    total_files = 0
    total_lines = 0

    for path in files:
        classification = classify_file(path, repo_root=repo_root, pkg_index=pkg_index)
        if classification is None:
            continue

        lines = count_lines(path)
        total_files += 1
        total_lines += lines

        role = "test" if classification.is_test and classification.category == "code" else "main"

        # Overall totals by category.
        _inc(totals, classification.category, files=1, lines=lines)

        # Overall totals by role (code only distinguishes main vs test).
        if classification.category == "code":
            role_bucket = _ensure_nested(by_role, role)
            _inc(role_bucket, "code", files=1, lines=lines)

        # By language within category.
        lang_bucket = _ensure_nested(by_language, classification.category)
        key = f"{classification.language_or_type}"
        _inc(lang_bucket, key, files=1, lines=lines)

        # By package and category.
        pkg_bucket = _ensure_nested(by_package, classification.package_name)
        _inc(pkg_bucket, classification.category, files=1, lines=lines)

        # By package and language.
        pkg_lang_bucket = _ensure_nested(by_package_language, classification.package_name)
        lang_key = f"{classification.language_or_type}"
        _inc(pkg_lang_bucket, lang_key, files=1, lines=lines)

        # By package and role (code only).
        if classification.category == "code":
            pkg_role_bucket = _ensure_nested(by_package_role, classification.package_name)
            _inc(pkg_role_bucket, role, files=1, lines=lines)

    return {
        "total": {"files": total_files, "lines": total_lines},
        "totals": _normalize_counter_map(totals),
        "by_language": {cat: _normalize_counter_map(data) for cat, data in by_language.items()},
        "by_package": {pkg: _normalize_counter_map(data) for pkg, data in by_package.items()},
        "by_package_language": {
            pkg: _normalize_counter_map(data) for pkg, data in by_package_language.items()
        },
        "by_role": _normalize_counter_map(by_role),
        "by_package_role": {pkg: _normalize_counter_map(data) for pkg, data in by_package_role.items()},
    }


def _normalize_counter_map(raw: Mapping[str, int]) -> Dict[str, Dict[str, int]]:
    """Convert flattened `key__files` / `key__lines` into `{key: {files, lines}}`."""
    result: Dict[str, Dict[str, int]] = defaultdict(lambda: {"files": 0, "lines": 0})
    for k, v in raw.items():
        if k.endswith("__files"):
            base = k[: -len("__files")]
            result[base]["files"] = v
        elif k.endswith("__lines"):
            base = k[: -len("__lines")]
            result[base]["lines"] = v
    return dict(result)


def _format_human_readable(stats: Mapping[str, object]) -> str:
    lines: list[str] = []

    total = stats.get("total", {})
    lines.append("=== Project File & Line Stats ===")
    lines.append(
        f"Total: {total.get('files', 0)} files, {total.get('lines', 0)} lines",
    )
    lines.append("")

    totals = stats.get("totals", {})
    if isinstance(totals, Mapping) and totals:
        lines.append("By category:")
        for category, data in sorted(totals.items()):
            if not isinstance(data, Mapping):
                continue
            files_count = data.get("files", 0)
            line_count = data.get("lines", 0)
            lines.append(f"- {category}: {files_count} files, {line_count} lines")
        lines.append("")

    by_language = stats.get("by_language", {})
    if isinstance(by_language, Mapping) and by_language:
        lines.append("By language within category:")
        for category, lang_map in sorted(by_language.items()):
            lines.append(f"{category}:")
            if not isinstance(lang_map, Mapping):
                continue
            for language, data in sorted(lang_map.items()):
                if not isinstance(data, Mapping):
                    continue
                files_count = data.get("files", 0)
                line_count = data.get("lines", 0)
                lines.append(
                    f"  - {language}: {files_count} files, {line_count} lines",
                )
        lines.append("")

    by_package = stats.get("by_package", {})
    if isinstance(by_package, Mapping) and by_package:
        lines.append("By package (totals):")
        for package, cat_map in sorted(by_package.items()):
            if package == "__no_package__":
                continue
            if not isinstance(cat_map, Mapping):
                continue
            parts: list[str] = []
            for category, data in sorted(cat_map.items()):
                if not isinstance(data, Mapping):
                    continue
                files_count = data.get("files", 0)
                line_count = data.get("lines", 0)
                parts.append(f"{category}={files_count} files/{line_count} lines")
            joined = ", ".join(parts) if parts else "no categorized files"
            lines.append(f"- {package}: {joined}")
        lines.append("")

    by_package_role = stats.get("by_package_role", {})
    if isinstance(by_package_role, Mapping) and by_package_role:
        lines.append("By package (code: main vs test):")
        for package, role_map in sorted(by_package_role.items()):
            if package == "__no_package__":
                continue
            if not isinstance(role_map, Mapping):
                continue
            main_data = role_map.get("main", {})
            test_data = role_map.get("test", {})
            main_files = main_data.get("files", 0) if isinstance(main_data, Mapping) else 0
            main_lines = main_data.get("lines", 0) if isinstance(main_data, Mapping) else 0
            test_files = test_data.get("files", 0) if isinstance(test_data, Mapping) else 0
            test_lines = test_data.get("lines", 0) if isinstance(test_data, Mapping) else 0
            lines.append(
                f"- {package}: main={main_files} files/{main_lines} lines, "
                f"test={test_files} files/{test_lines} lines",
            )
        lines.append("")

    by_package_language = stats.get("by_package_language", {})
    if isinstance(by_package_language, Mapping) and by_package_language:
        lines.append("By package and language (code/spec):")
        for package, lang_map in sorted(by_package_language.items()):
            lines.append(f"{package}:")
            if not isinstance(lang_map, Mapping):
                continue
            for language, data in sorted(lang_map.items()):
                if not isinstance(data, Mapping):
                    continue
                files_count = data.get("files", 0)
                line_count = data.get("lines", 0)
                lines.append(
                    f"  - {language}: {files_count} files, {line_count} lines",
                )

    return "\n".join(lines)


def main(argv: Optional[Iterable[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Summarize code, asset, and spec files in the ColonizeThis repo, "
            "with file and line counts by category, language, and Dart package."
        ),
    )
    parser.add_argument(
        "--root",
        type=str,
        default=None,
        help="Repository root (defaults to auto-detected from current working directory).",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON instead of human-readable text.",
    )
    args = parser.parse_args(list(argv) if argv is not None else None)

    start = Path(args.root) if args.root else Path.cwd()
    repo_root = find_repo_root(start)
    packages = discover_packages(repo_root)
    pkg_index = PackageIndex(packages, repo_root=repo_root)

    stats = aggregate_stats(iter_files(repo_root), repo_root=repo_root, pkg_index=pkg_index)

    if args.json:
        print(json.dumps(stats, indent=2, sort_keys=True))
    else:
        print(_format_human_readable(stats))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

