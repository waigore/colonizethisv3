"""AC4: cursor backend requires CURSOR_API_KEY before Daytona (Refs #2065)."""

from __future__ import annotations

import pytest

from colonizethis_infra import run_sandbox_agent


def test_cursor_missing_key_returns_error(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("AGENT", raising=False)
    monkeypatch.delenv("CT_AGENT", raising=False)
    monkeypatch.delenv("CURSOR_API_KEY", raising=False)
    monkeypatch.setenv("SANDBOX_AGENT", "cursor")
    monkeypatch.setenv("DAYTONA_API_KEY", "dummy")
    monkeypatch.setenv("GITHUB_TOKEN", "dummy")
    monkeypatch.setenv("GITHUB_REPOSITORY", "o/r")

    def boom() -> object:
        raise AssertionError("Daytona should not be constructed when CURSOR_API_KEY is missing")

    code, err = run_sandbox_agent.run_pipeline(
        argv_agent=None,
        cli_repo=None,
        cli_ref=None,
        prompt="hi",
        cwd=None,
        daytona_factory=boom,
    )
    assert code == 1
    assert err is not None
    assert "CURSOR_API_KEY" in err


def test_invalid_sandbox_agent_value(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("AGENT", raising=False)
    monkeypatch.delenv("CT_AGENT", raising=False)
    monkeypatch.setenv("SANDBOX_AGENT", "vscode")
    code, err = run_sandbox_agent.run_pipeline(
        argv_agent=None,
        cli_repo=None,
        cli_ref=None,
        prompt="hi",
        cwd=None,
        daytona_factory=lambda: None,
    )
    assert code == 1
    assert err and "SANDBOX_AGENT" in err and "vscode" in err
