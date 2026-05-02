"""AC3: HTTPS clone URL and resolution order (Refs #2065)."""

from __future__ import annotations

import os

import pytest

from colonizethis_infra.clone_target import (
    https_clone_url,
    parse_github_repository,
    resolve_clone_target,
)


def test_https_clone_url() -> None:
    assert https_clone_url("waigore", "colonizethisv3") == "https://github.com/waigore/colonizethisv3.git"


def test_parse_github_repository() -> None:
    assert parse_github_repository("waigore/colonizethisv3") == ("waigore", "colonizethisv3")
    assert parse_github_repository("bad") is None


def test_resolve_cli_repo_wins(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("GITHUB_REPOSITORY", "env/wrong")
    t, err = resolve_clone_target(cwd=None, cli_repo="cli/right", cli_ref="dev")
    assert err is None and t is not None
    assert (t.owner, t.repo, t.ref) == ("cli", "right", "dev")


def test_resolve_github_repository_with_ref_override(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("GITHUB_REPOSITORY", "o/r")
    monkeypatch.delenv("GIT_REF", raising=False)
    t, err = resolve_clone_target(cwd=None, cli_repo=None, cli_ref="topic/branch")
    assert err is None and t is not None
    assert t.ref == "topic/branch"


def test_ci_blocks_git_inference(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("GITHUB_ACTIONS", "true")
    monkeypatch.delenv("GITHUB_REPOSITORY", raising=False)
    _, err = resolve_clone_target(cwd=os.getcwd(), cli_repo=None, cli_ref=None)
    assert err is not None
    assert "CI" in err or "GITHUB_REPOSITORY" in err
