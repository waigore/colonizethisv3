"""Create a Daytona sandbox, clone the repo, run Cursor or OpenCode (Refs #2065)."""

from __future__ import annotations

import argparse
import os
import shlex
import sys
from collections.abc import Callable
from typing import Any

from colonizethis_infra.agent_backend import (
    AgentBackend,
    require_cursor_api_key,
    require_opencode_api_key,
    resolve_agent_backend,
    resolve_opencode_model,
    usage_missing_backend_error,
)
from colonizethis_infra.clone_target import CloneTarget, https_clone_url, is_probable_sha, resolve_clone_target
from colonizethis_infra.constants import DEFAULT_DAYTONA_SNAPSHOT_NAME


def _snapshot_name() -> str:
    raw = os.environ.get("DAYTONA_SNAPSHOT_NAME", "").strip()
    return raw or DEFAULT_DAYTONA_SNAPSHOT_NAME


def _clone_into_sandbox(sandbox: object, target: CloneTarget, github_token: str) -> None:
    url = https_clone_url(target.owner, target.repo)
    path = "workspace/colonizethis"
    ref = target.ref
    branch: str | None = None
    commit_id: str | None = None
    if ref:
        if is_probable_sha(ref):
            commit_id = ref
        else:
            branch = ref
    sandbox.git.clone(
        url=url,
        path=path,
        branch=branch,
        commit_id=commit_id,
        username="x-access-token",
        password=github_token,
    )


def _agent_process_command(backend: AgentBackend, prompt: str) -> str:
    if backend.name == "cursor":
        return "agent -p " + shlex.quote(prompt)
    model = resolve_opencode_model()
    return "opencode run -m " + shlex.quote(model) + " " + shlex.quote(prompt)


def _exec_env_for_backend(backend: AgentBackend) -> dict[str, str]:
    """Pass only provider secrets/settings; remote sandbox supplies PATH/HOME."""
    env: dict[str, str] = {}
    if backend.name == "cursor":
        k = os.environ.get("CURSOR_API_KEY", "").strip()
        if k:
            env["CURSOR_API_KEY"] = k
    if backend.name == "opencode":
        k = os.environ.get("OPENCODE_API_KEY", "").strip()
        if k:
            env["OPENCODE_API_KEY"] = k
        m = os.environ.get("OPENCODE_MODEL", "").strip()
        if m:
            env["OPENCODE_MODEL"] = m
    return env


def run_pipeline(
    *,
    argv_agent: str | None,
    cli_repo: str | None,
    cli_ref: str | None,
    prompt: str,
    cwd: str | None,
    daytona_factory: Callable[[], Any],
) -> tuple[int, str | None]:
    """Return (exit_code, stderr_snippet_for_tests)."""
    backend, err = resolve_agent_backend(argv_agent=argv_agent)
    if err:
        return 1, err
    if backend is None:
        return 1, usage_missing_backend_error()

    if backend.name == "cursor":
        kerr = require_cursor_api_key()
        if kerr:
            return 1, kerr
    else:
        kerr = require_opencode_api_key()
        if kerr:
            return 1, kerr

    if not os.environ.get("DAYTONA_API_KEY", "").strip():
        return 1, "DAYTONA_API_KEY is required."

    token = os.environ.get("GITHUB_TOKEN", "").strip()
    if not token:
        return 1, "GITHUB_TOKEN is required."

    target, cerr = resolve_clone_target(cwd=cwd, cli_repo=cli_repo, cli_ref=cli_ref)
    if cerr or target is None:
        return 1, cerr or "Clone target unresolved."

    from colonizethis_infra.network_allowlist import (
        flutter_pub_egress_allowlist_cidrs as _resolve_egress_cidrs,
        truncate_cidr_allowlist_csv,
    )
    from daytona import CreateSandboxFromSnapshotParams

    daytona = daytona_factory()
    allow = os.environ.get("DAYTONA_FLUTTER_EGRESS_ALLOWLIST_CIDRS", "").strip()
    if allow:
        allow = truncate_cidr_allowlist_csv(allow)
    else:
        allow = _resolve_egress_cidrs()
    if allow:
        # Allowlist CIDRs for pub/GitHub edges while keeping general egress open so
        # DNS (UDP) and other endpoints work; Daytona still receives the whitelist for policy.
        params = CreateSandboxFromSnapshotParams(
            snapshot=_snapshot_name(),
            env_vars={},
            auto_stop_interval=0,
            network_block_all=False,
            network_allow_list=allow,
        )
    else:
        params = CreateSandboxFromSnapshotParams(
            snapshot=_snapshot_name(),
            env_vars={},
            auto_stop_interval=0,
            network_block_all=False,
        )
    sandbox = daytona.create(params, timeout=0)
    sandbox.wait_for_sandbox_start(timeout=0)

    _clone_into_sandbox(sandbox, target, token)

    cmd = _agent_process_command(backend, prompt)
    env = _exec_env_for_backend(backend)
    result = sandbox.process.exec(cmd, cwd="workspace/colonizethis", env=env)
    return result.exit_code, None


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Run Cursor or OpenCode in a Daytona sandbox after cloning the repo.",
    )
    parser.add_argument("--agent", choices=("cursor", "opencode"), default=None)
    parser.add_argument("--repo", default=None, help="owner/repo override (see SPEC/program/daytona-sandbox.md).")
    parser.add_argument("--ref", default=None, help="Optional branch, tag, or commit SHA to clone.")
    parser.add_argument("prompt", nargs=argparse.REMAINDER, help="Prompt text (pass after -- if it starts with '-').")
    ns = parser.parse_args(argv)
    prompt_parts = ns.prompt
    if prompt_parts and prompt_parts[0] == "--":
        prompt_parts = prompt_parts[1:]
    prompt = " ".join(prompt_parts).strip()
    if not prompt:
        print("Missing prompt: provide words or use -- separator.", file=sys.stderr)
        return 1

    from daytona import Daytona

    code, err = run_pipeline(
        argv_agent=ns.agent,
        cli_repo=ns.repo,
        cli_ref=ns.ref,
        prompt=prompt,
        cwd=os.getcwd(),
        daytona_factory=Daytona,
    )
    if err:
        print(err, file=sys.stderr)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
