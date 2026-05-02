"""AC2: snapshot registration calls SDK with name, image, on_logs (Refs #2065)."""

from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock

from colonizethis_infra.constants import DEFAULT_DAYTONA_SNAPSHOT_NAME
from colonizethis_infra.snapshot_register import register_tools_snapshot


def test_register_tools_snapshot_calls_create_with_params() -> None:
    daytona = MagicMock()
    dockerfile = Path(__file__).resolve().parent.parent / "Dockerfile"
    log_lines: list[str] = []

    def on_logs(chunk: str) -> None:
        log_lines.append(chunk)

    register_tools_snapshot(
        daytona,
        snapshot_name=DEFAULT_DAYTONA_SNAPSHOT_NAME,
        dockerfile_path=dockerfile,
        on_logs=on_logs,
    )

    daytona.snapshot.create.assert_called_once()
    call = daytona.snapshot.create.call_args
    assert call is not None
    params = call.args[0]
    assert params.name == DEFAULT_DAYTONA_SNAPSHOT_NAME
    assert call.kwargs.get("on_logs") is on_logs
    on_logs("log-chunk")
    assert log_lines == ["log-chunk"]
    # Image is declarative (from Dockerfile path).
    from daytona import Image

    assert isinstance(params.image, Image)
