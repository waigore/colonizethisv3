"""Usage error when neither --agent nor SANDBOX_AGENT resolves (Refs #2065)."""

from __future__ import annotations

import pytest

from colonizethis_infra import run_sandbox_agent


def test_missing_backend_before_daytona(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("AGENT", raising=False)
    monkeypatch.delenv("CT_AGENT", raising=False)
    monkeypatch.delenv("SANDBOX_AGENT", raising=False)
    monkeypatch.setenv("DAYTONA_API_KEY", "x")
    monkeypatch.setenv("GITHUB_TOKEN", "x")
    monkeypatch.setenv("GITHUB_REPOSITORY", "o/r")

    def boom() -> object:
        raise AssertionError("Daytona must not run without backend")

    code, err = run_sandbox_agent.run_pipeline(
        argv_agent=None,
        cli_repo=None,
        cli_ref=None,
        prompt="hi",
        cwd=None,
        daytona_factory=boom,
    )
    assert code == 1
    assert err and "SANDBOX_AGENT" in err and "--agent" in err


def test_argv_agent_overrides_sandbox_agent(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("AGENT", raising=False)
    monkeypatch.delenv("CT_AGENT", raising=False)
    monkeypatch.setenv("SANDBOX_AGENT", "opencode")
    monkeypatch.setenv("CURSOR_API_KEY", "should-not-be-required")
    monkeypatch.setenv("OPENCODE_API_KEY", "ok")
    monkeypatch.setenv("DAYTONA_API_KEY", "d")
    monkeypatch.setenv("GITHUB_TOKEN", "t")
    monkeypatch.setenv("GITHUB_REPOSITORY", "o/r")

    calls: list[str] = []

    class _Sb:
        def wait_for_sandbox_start(self, timeout: float | None = None) -> None:
            return None

        @property
        def git(self) -> object:
            return self

        def clone(self, **kwargs: object) -> None:
            calls.append("clone")

        @property
        def process(self) -> object:
            return self

        def exec(self, command: str, cwd: str | None = None, env: dict[str, str] | None = None) -> object:
            calls.append(command)
            return type("R", (), {"exit_code": 0})()

    class _D:
        def create(self, params: object, timeout: float = 60) -> object:
            return _Sb()

    code, err = run_sandbox_agent.run_pipeline(
        argv_agent="cursor",
        cli_repo=None,
        cli_ref=None,
        prompt="p",
        cwd=None,
        daytona_factory=_D,
    )
    assert err is None
    assert code == 0
    assert any("agent -p" in c for c in calls)
