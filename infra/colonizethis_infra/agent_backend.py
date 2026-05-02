"""Resolve SANDBOX_AGENT / --agent backend (Refs #2065)."""

from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class AgentBackend:
    """Resolved agent CLI kind."""

    name: str  # "cursor" | "opencode"


def _trimmed_env(name: str) -> str | None:
    raw = os.environ.get(name)
    if raw is None:
        return None
    s = raw.strip()
    return s if s else None


def _reject_legacy_agent_env_aliases() -> str | None:
    """Return error message if forbidden env vars are set."""
    if _trimmed_env("AGENT"):
        return (
            "Environment variable AGENT is set; ColonizeThis does not use AGENT for "
            "sandbox backend selection. Unset AGENT and use SANDBOX_AGENT "
            "(cursor|opencode) and/or --agent instead."
        )
    if _trimmed_env("CT_AGENT"):
        return (
            "Environment variable CT_AGENT is set; use SANDBOX_AGENT "
            "(cursor|opencode) and/or --agent instead."
        )
    return None


def resolve_agent_backend(*, argv_agent: str | None) -> tuple[AgentBackend | None, str | None]:
    """Return (backend, error_message). error_message → print to stderr and exit non-zero."""
    legacy = _reject_legacy_agent_env_aliases()
    if legacy:
        return None, legacy

    if argv_agent is not None:
        a = argv_agent.strip().lower()
        if a in ("cursor", "opencode"):
            return AgentBackend(name=a), None
        return (
            None,
            f"Invalid --agent value {argv_agent!r}. Legal values: cursor, opencode.",
        )

    env_agent = _trimmed_env("SANDBOX_AGENT")
    if env_agent is None:
        return None, None

    e = env_agent.lower()
    if e in ("cursor", "opencode"):
        return AgentBackend(name=e), None
    return (
        None,
        f"Invalid SANDBOX_AGENT value {env_agent!r}. Legal values: cursor, opencode.",
    )


def usage_missing_backend_error() -> str:
    return (
        "No agent backend selected. Set one of:\n"
        "  --agent cursor|opencode\n"
        "  SANDBOX_AGENT=cursor or SANDBOX_AGENT=opencode\n"
        "(--agent overrides SANDBOX_AGENT when both are set.)"
    )


def resolve_opencode_model() -> str:
    from colonizethis_infra.constants import OPENCODE_DEFAULT_MODEL

    return _trimmed_env("OPENCODE_MODEL") or OPENCODE_DEFAULT_MODEL


def require_cursor_api_key() -> str | None:
    if not _trimmed_env("CURSOR_API_KEY"):
        return "CURSOR_API_KEY is required when the agent backend is cursor."
    return None


def require_opencode_api_key() -> str | None:
    if not _trimmed_env("OPENCODE_API_KEY"):
        return "OPENCODE_API_KEY is required when the agent backend is opencode."
    return None


