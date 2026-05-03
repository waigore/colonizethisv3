"""Unit tests for Daytona egress CIDR resolution (Refs #2065)."""

from __future__ import annotations

import pytest

from colonizethis_infra import network_allowlist


def test_truncate_cidr_allowlist_csv() -> None:
    s = ",".join(f"{i}.0.0.0/32" for i in range(20))
    out = network_allowlist.truncate_cidr_allowlist_csv(s)
    assert len(out.split(",")) == 10


def test_prioritized_round_robin_dns_then_hosts(monkeypatch: pytest.MonkeyPatch) -> None:
    def fake_ips(host: str) -> set[str]:
        if host == "pub.dev":
            return {f"10.0.0.{i}" for i in range(1, 20)}
        if host == "github.com":
            return {"20.0.0.1"}
        return set()

    monkeypatch.setattr(network_allowlist, "ipv4_addresses_for_host", fake_ips)
    out = network_allowlist.prioritized_ipv4_egress_cidrs(
        ("pub.dev", "github.com"),
        extra_resolver_ips=(),
    )
    parts = out.split(",")
    assert len(parts) == 10
    assert parts[:4] == ["1.1.1.1/32", "1.0.0.1/32", "8.8.8.8/32", "8.8.4.4/32"]
    assert "20.0.0.1/32" in parts
    assert parts[-1].startswith("10.0.0.")


def test_ipv4_cidrs_for_hosts_dedupes_and_sorts(monkeypatch: pytest.MonkeyPatch) -> None:
    def fake_ips(host: str) -> set[str]:
        if host == "a.example":
            return {"10.0.0.2", "10.0.0.1"}
        if host == "b.example":
            return {"10.0.0.1"}
        return set()

    monkeypatch.setattr(network_allowlist, "ipv4_addresses_for_host", fake_ips)
    out = network_allowlist.ipv4_cidrs_for_hosts(("a.example", "b.example"))
    assert out == "10.0.0.1/32,10.0.0.2/32"


def test_run_pipeline_respects_daytona_flutter_egress_allowlist_env(monkeypatch: pytest.MonkeyPatch) -> None:
    from colonizethis_infra import run_sandbox_agent

    monkeypatch.delenv("AGENT", raising=False)
    monkeypatch.delenv("CT_AGENT", raising=False)
    monkeypatch.setenv("SANDBOX_AGENT", "opencode")
    monkeypatch.setenv("OPENCODE_API_KEY", "k")
    monkeypatch.setenv("DAYTONA_API_KEY", "d")
    monkeypatch.setenv("GITHUB_TOKEN", "t")
    monkeypatch.setenv("GITHUB_REPOSITORY", "o/r")
    monkeypatch.setenv("DAYTONA_FLUTTER_EGRESS_ALLOWLIST_CIDRS", "203.0.113.7/32")

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
    assert p.network_block_all is False
    assert p.network_allow_list == "203.0.113.7/32"
