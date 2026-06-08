#!/usr/bin/env python3
"""
Compute the transitive-downstream set of packages whose tests must run
when one or more colonizethis packages change.

Reads each package's pubspec.yaml to discover bare-name dependencies on
other colonizethis_* packages (production deps only, not dev_dependencies).

Accepts per-package change flags via --changed-<name>=true|false.
Outputs a JSON array of package directory names (e.g. ["colonizethis_logic","colonizethis_ai"])
to stdout.

When invoked with no changed packages the output includes all packages.

Packages outside the six core packages (colonizethis_models, _data, _save,
_map, _logic, _ai) are ignored because they do not run in the package_tests
CI job.

Example:
  python3 tool/compute_package_test_plan.py \
      --changed-data=true --changed-ai=true
  # Package names may be full (colonizethis_data) or short (data).
"""

import json
import os
import re
import sys

PACKAGES_DIR = "packages"

CORE_PACKAGES = [
    "colonizethis_models",
    "colonizethis_data",
    "colonizethis_save",
    "colonizethis_map",
    "colonizethis_world",
    "colonizethis_combat",
    "colonizethis_economy",
    "colonizethis_diplomacy",
    "colonizethis_setup",
    "colonizethis_orders",
    "colonizethis_logic",
    "colonizethis_ai",
]


def read_production_deps(pkg: str) -> set[str]:
    """Return the set of colonizethis_* package names that *pkg* depends on
    in its `dependencies:` block (excluding dev_dependencies)."""
    pubspec = os.path.join(PACKAGES_DIR, pkg, "pubspec.yaml")
    deps: set[str] = set()
    if not os.path.exists(pubspec):
        return deps

    in_deps = False

    with open(pubspec, encoding="utf-8") as fh:
        for line in fh:
            stripped = line.rstrip()

            if stripped == "dependencies:":
                in_deps = True
                continue

            if not in_deps:
                continue

            # Section boundary — leave dependencies block
            if stripped and not stripped[0].isspace():
                in_deps = False
                continue

            # dev_dependencies starts while still inside dependencies indent
            if stripped.startswith("dev_dependencies:"):
                in_deps = False  # do not parse dev deps as production
                continue

            m = re.match(r"^\s+(\S+):", stripped)
            if m and m.group(1).startswith("colonizethis_"):
                deps.add(m.group(1))

    return deps


def build_reverse_dep_graph() -> dict[str, set[str]]:
    """Return {pkg: set of packages that depend on pkg} for all core packages."""
    rev: dict[str, set[str]] = {pkg: set() for pkg in CORE_PACKAGES}

    for pkg in CORE_PACKAGES:
        for dep in read_production_deps(pkg):
            if dep in rev:
                rev[dep].add(pkg)

    return rev


def transitive_downstream(changed: set[str], rev_graph: dict[str, set[str]]) -> list[str]:
    """BFS from *changed* through rev_graph; return sorted list of
    packages that must be tested (changed + downstream)."""
    visited: set[str] = set()
    queue: list[str] = sorted(changed)

    while queue:
        pkg = queue.pop(0)
        if pkg in visited:
            continue
        visited.add(pkg)
        for downstream in rev_graph.get(pkg, set()):
            if downstream not in visited:
                queue.append(downstream)

    return sorted(visited)


SHORT_TO_FULL: dict[str, str] = {
    "models": "colonizethis_models",
    "data": "colonizethis_data",
    "save": "colonizethis_save",
    "map": "colonizethis_map",
    "world": "colonizethis_world",
    "combat": "colonizethis_combat",
    "economy": "colonizethis_economy",
    "diplomacy": "colonizethis_diplomacy",
    "logic": "colonizethis_logic",
    "ai": "colonizethis_ai",
}


def parse_args() -> set[str]:
    """Parse --changed-<name>=true CLI flags; return set of changed package names.

    Accepts both long names (--changed-colonizethis_ai=true) and short names
    (--changed-ai=true)."""
    changed: set[str] = set()
    for arg in sys.argv[1:]:
        m = re.match(r"^--changed-(\S+)=(true|false)$", arg)
        if m and m.group(2) == "true":
            name = m.group(1)
            if name in CORE_PACKAGES:
                changed.add(name)
            elif name in SHORT_TO_FULL:
                changed.add(SHORT_TO_FULL[name])
    return changed


def main() -> None:
    changed = parse_args()

    if changed:
        rev_graph = build_reverse_dep_graph()
        result = transitive_downstream(changed, rev_graph)
    else:
        result = list(CORE_PACKAGES)

    print(json.dumps(result))


if __name__ == "__main__":
    main()
