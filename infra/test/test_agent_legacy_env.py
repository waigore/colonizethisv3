"""Reject AGENT / CT_AGENT aliases (Refs #2065)."""

from __future__ import annotations

import pytest

from colonizethis_infra import run_sandbox_agent


def test_agent_env_rejected(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("AGENT", "cursor")
    monkeypatch.setenv("SANDBOX_AGENT", "cursor")
    monkeypatch.setenv("CURSOR_API_KEY", "k")
    monkeypatch.setenv("DAYTONA_API_KEY", "d")
    monkeypatch.setenv("GITHUB_TOKEN", "t")
    monkeypatch.setenv("GITHUB_REPOSITORY", "o/r")

    code, err = run_sandbox_agent.run_pipeline(
        argv_agent=None,
        cli_repo=None,
        cli_ref=None,
        prompt="x",
        cwd=None,
        daytona_factory=lambda: None,
    )
    assert code == 1
    assert err and "AGENT" in err and "SANDBOX_AGENT" in err
