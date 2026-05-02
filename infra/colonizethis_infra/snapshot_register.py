"""Register a Daytona Snapshot from the tools Dockerfile (Refs #2065)."""

from __future__ import annotations

from collections.abc import Callable
from pathlib import Path
from typing import Any


def register_tools_snapshot(
    daytona: Any,
    *,
    snapshot_name: str,
    dockerfile_path: Path,
    on_logs: Callable[[str], None],
) -> Any:
    """Call `daytona.snapshot.create` with declarative image from Dockerfile."""
    from daytona import CreateSnapshotParams, Image

    image = Image.from_dockerfile(str(dockerfile_path))
    params = CreateSnapshotParams(name=snapshot_name, image=image)
    return daytona.snapshot.create(params, on_logs=on_logs)
