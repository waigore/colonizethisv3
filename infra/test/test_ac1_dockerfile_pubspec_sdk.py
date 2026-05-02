"""AC1 supplementary: pubspec environment.sdk lower bound vs Dockerfile marker (Refs #2065)."""

from __future__ import annotations

import re
from pathlib import Path

import yaml


def _repo_root() -> Path:
    return Path(__file__).resolve().parent.parent.parent


def _infra_dockerfile() -> Path:
    return Path(__file__).resolve().parent.parent / "Dockerfile"


def test_pubspec_sdk_lower_bound_at_least_3_11() -> None:
    pub = yaml.safe_load((_repo_root() / "pubspec.yaml").read_text(encoding="utf-8"))
    env = pub.get("environment", {}).get("sdk", "")
    m = re.search(r">=\s*(\d+)\.(\d+)", env)
    assert m, f"Could not parse lower SDK bound from {env!r}"
    major, minor = int(m.group(1)), int(m.group(2))
    assert (major, minor) >= (3, 11)


def test_dockerfile_ct_pubspec_sdk_marker_matches() -> None:
    text = _infra_dockerfile().read_text(encoding="utf-8")
    m = re.search(r"^#\s*CT_PUBSPEC_SDK_LOWER_BOUND=(\d+)\.(\d+)\.(\d+)", text, re.MULTILINE)
    assert m, "Dockerfile must contain CT_PUBSPEC_SDK_LOWER_BOUND comment for AC1 static gate"
    major, minor = int(m.group(1)), int(m.group(2))
    assert (major, minor) >= (3, 11)
