"""Resolve owner/repo/ref for HTTPS clone (Refs #2065)."""

from __future__ import annotations

import os
import re
import subprocess
from dataclasses import dataclass


@dataclass(frozen=True)
class CloneTarget:
    owner: str
    repo: str
    ref: str | None  # branch/tag name, or None for default branch


_GH_SSH = re.compile(
    r"^(?:git@github\.com:|ssh://git@github\.com/)"
    r"(?P<owner>[\w.-]+)/(?P<repo>[\w.-]+?)(?:\.git)?/?$",
)
_GH_HTTPS = re.compile(
    r"^https://github\.com/(?P<owner>[\w.-]+)/(?P<repo>[\w.-]+?)(?:\.git)?/?$",
)


def parse_github_repository(spec: str) -> tuple[str, str] | None:
    spec = spec.strip()
    if "/" not in spec:
        return None
    owner, _, repo = spec.partition("/")
    owner, repo = owner.strip(), repo.strip()
    if not owner or not repo or "/" in repo:
        return None
    return owner, repo


def infer_origin_from_git(cwd: str | None) -> tuple[str, str] | None:
    try:
        out = subprocess.run(
            ["git", "remote", "get-url", "origin"],
            check=True,
            capture_output=True,
            text=True,
            cwd=cwd,
            timeout=30,
        ).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return None
    m = _GH_SSH.match(out) or _GH_HTTPS.match(out)
    if not m:
        return None
    return m.group("owner"), m.group("repo").removesuffix(".git")


def resolve_clone_target(
    *,
    cwd: str | None,
    cli_repo: str | None,
    cli_ref: str | None,
) -> tuple[CloneTarget | None, str | None]:
    """Return (target, error)."""
    ref: str | None = None
    owner: str | None = None
    repo: str | None = None

    if cli_repo:
        parsed = parse_github_repository(cli_repo)
        if not parsed:
            return None, f"Invalid --repo value {cli_repo!r}; expected owner/repo."
        owner, repo = parsed
        ref = cli_ref.strip() if cli_ref and cli_ref.strip() else None
        return CloneTarget(owner=owner, repo=repo, ref=ref), None

    gr = os.environ.get("GITHUB_REPOSITORY")
    if gr and gr.strip():
        parsed = parse_github_repository(gr.strip())
        if not parsed:
            return None, f"Invalid GITHUB_REPOSITORY value {gr!r}; expected owner/repo."
        owner, repo = parsed
        ref = (
            cli_ref.strip()
            if cli_ref and cli_ref.strip()
            else (os.environ.get("GIT_REF", "").strip() or None)
        )
        return CloneTarget(owner=owner, repo=repo, ref=ref), None

    if os.environ.get("GITHUB_ACTIONS"):
        return (
            None,
            "Clone target unresolved: set --repo owner/repo (and optional --ref) or "
            "GITHUB_REPOSITORY (and optional GIT_REF). Local git inference is disabled in CI.",
        )

    inferred = infer_origin_from_git(cwd)
    if inferred:
        owner, repo = inferred
        ref = (
            cli_ref.strip()
            if cli_ref and cli_ref.strip()
            else (os.environ.get("GIT_REF", "").strip() or None)
        )
        return CloneTarget(owner=owner, repo=repo, ref=ref), None

    return (
        None,
        "Clone target unresolved: pass --repo owner/repo, set GITHUB_REPOSITORY, or run "
        "from a git checkout whose origin points at github.com (local dev only).",
    )


def https_clone_url(owner: str, repo: str) -> str:
    return f"https://github.com/{owner}/{repo}.git"


def is_probable_sha(ref: str) -> bool:
    return bool(re.fullmatch(r"[0-9a-fA-F]{7,40}", ref))
