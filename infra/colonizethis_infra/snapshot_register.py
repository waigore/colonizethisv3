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
    resources: Any | None = None,
) -> Any:
    """Call `daytona.snapshot.create` with declarative image from Dockerfile.

    When ``resources`` is set (Daytona ``Resources``), sandboxes created from this
    snapshot use that CPU / memory (GiB) / disk (GiB) template unless the API
    overrides it.
    """
    from daytona import CreateSnapshotParams, Image

    image = Image.from_dockerfile(str(dockerfile_path))
    params = CreateSnapshotParams(name=snapshot_name, image=image, resources=resources)
    return daytona.snapshot.create(params, on_logs=on_logs)
