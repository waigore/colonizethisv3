"""AC5: OpenCode default model and OPENCODE_MODEL override (Refs #2065)."""

from __future__ import annotations

import pytest

from colonizethis_infra.agent_backend import resolve_opencode_model
from colonizethis_infra.constants import OPENCODE_DEFAULT_MODEL
from colonizethis_infra import run_sandbox_agent


def test_default_model_matches_ci_opencode_workflow() -> None:
    assert OPENCODE_DEFAULT_MODEL == "opencode-go/qwen3.6-plus"


def test_resolve_opencode_model_default(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("OPENCODE_MODEL", raising=False)
    assert resolve_opencode_model() == OPENCODE_DEFAULT_MODEL


def test_resolve_opencode_model_override(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("OPENCODE_MODEL", "custom/model")
    assert resolve_opencode_model() == "custom/model"


def test_opencode_command_uses_resolved_model(monkeypatch: pytest.MonkeyPatch) -> None:
    from colonizethis_infra.agent_backend import AgentBackend

    monkeypatch.delenv("OPENCODE_MODEL", raising=False)
    cmd = run_sandbox_agent._agent_process_command(AgentBackend(name="opencode"), "hello world")
    assert "-m " in cmd
    assert OPENCODE_DEFAULT_MODEL in cmd
    assert "hello world" in cmd
