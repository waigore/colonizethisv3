"""SANDBOX_AGENT empty/whitespace treated as unset (Refs #2065)."""

from __future__ import annotations

import pytest

from colonizethis_infra import run_sandbox_agent


def test_whitespace_sandbox_agent_falls_back_to_argv(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("AGENT", raising=False)
    monkeypatch.delenv("CT_AGENT", raising=False)
    monkeypatch.setenv("SANDBOX_AGENT", "   ")
    monkeypatch.setenv("CURSOR_API_KEY", "k")
    monkeypatch.setenv("DAYTONA_API_KEY", "d")
    monkeypatch.setenv("GITHUB_TOKEN", "t")
    monkeypatch.setenv("GITHUB_REPOSITORY", "o/r")

    class _Sb:
        def wait_for_sandbox_start(self, timeout: float | None = None) -> None:
            return None

        @property
        def git(self) -> object:
            return self

        def clone(self, **kwargs: object) -> None:
            return None

        @property
        def process(self) -> object:
            return self

        def exec(self, command: str, cwd: str | None = None, env: dict[str, str] | None = None) -> object:
            return type("R", (), {"exit_code": 0})()

    class _D:
        def create(self, params: object, timeout: float = 60) -> object:
            return _Sb()

    code, err = run_sandbox_agent.run_pipeline(
        argv_agent="cursor",
        cli_repo=None,
        cli_ref=None,
        prompt="x",
        cwd=None,
        daytona_factory=_D,
    )
    assert err is None and code == 0
