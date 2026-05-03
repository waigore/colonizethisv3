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


def test_run_pipeline_sandbox_uses_allowlist_when_cidrs_resolved(monkeypatch: pytest.MonkeyPatch) -> None:
    """When CIDR allowlist is non-empty, pass it with network_block_all=False (DNS + pub.dev friendly)."""
    monkeypatch.delenv("AGENT", raising=False)
    monkeypatch.delenv("CT_AGENT", raising=False)
    monkeypatch.delenv("DAYTONA_FLUTTER_EGRESS_ALLOWLIST_CIDRS", raising=False)
    monkeypatch.setenv("SANDBOX_AGENT", "opencode")
    monkeypatch.setenv("OPENCODE_API_KEY", "k")
    monkeypatch.setenv("DAYTONA_API_KEY", "d")
    monkeypatch.setenv("GITHUB_TOKEN", "t")
    monkeypatch.setenv("GITHUB_REPOSITORY", "o/r")

    monkeypatch.setattr(
        "colonizethis_infra.network_allowlist.flutter_pub_egress_allowlist_cidrs",
        lambda: "8.8.8.8/32,9.9.9.9/32",
    )

    captured: list[object] = []

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
            captured.append(params)
            return _Sb()

    code, err = run_sandbox_agent.run_pipeline(
        argv_agent=None,
        cli_repo=None,
        cli_ref=None,
        prompt="p",
        cwd=None,
        daytona_factory=_D,
    )
    assert err is None
    assert code == 0
    assert len(captured) == 1
    p = captured[0]
    assert getattr(p, "network_block_all", None) is False
    assert getattr(p, "network_allow_list", None) == "8.8.8.8/32,9.9.9.9/32"


def test_run_pipeline_sandbox_opens_egress_when_allowlist_empty(monkeypatch: pytest.MonkeyPatch) -> None:
    """If no CIDRs resolve, fall back to network_block_all=False (no allowlist string)."""
    monkeypatch.delenv("AGENT", raising=False)
    monkeypatch.delenv("CT_AGENT", raising=False)
    monkeypatch.delenv("DAYTONA_FLUTTER_EGRESS_ALLOWLIST_CIDRS", raising=False)
    monkeypatch.setenv("SANDBOX_AGENT", "opencode")
    monkeypatch.setenv("OPENCODE_API_KEY", "k")
    monkeypatch.setenv("DAYTONA_API_KEY", "d")
    monkeypatch.setenv("GITHUB_TOKEN", "t")
    monkeypatch.setenv("GITHUB_REPOSITORY", "o/r")

    monkeypatch.setattr(
        "colonizethis_infra.network_allowlist.flutter_pub_egress_allowlist_cidrs",
        lambda: "",
    )

    captured: list[object] = []

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
            captured.append(params)
            return _Sb()

    code, err = run_sandbox_agent.run_pipeline(
        argv_agent=None,
        cli_repo=None,
        cli_ref=None,
        prompt="p",
        cwd=None,
        daytona_factory=_D,
    )
    assert err is None
    assert code == 0
    p = captured[0]
    assert getattr(p, "network_block_all", None) is False
    assert getattr(p, "network_allow_list", None) in (None, "")
