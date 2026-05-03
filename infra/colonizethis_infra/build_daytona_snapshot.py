"""Build local Docker image and register a Daytona Snapshot (Refs #2065)."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

from colonizethis_infra.constants import DEFAULT_DAYTONA_SNAPSHOT_NAME, DEFAULT_LOCAL_IMAGE_TAG
from colonizethis_infra.snapshot_register import register_tools_snapshot


def _infra_dir() -> Path:
    return Path(__file__).resolve().parent.parent


def _docker_build(*, image_tag: str) -> None:
    infra = _infra_dir()
    dockerfile = infra / "Dockerfile"
    subprocess.run(
        [
            "docker",
            "build",
            "--platform",
            "linux/amd64",
            "-f",
            str(dockerfile),
            "-t",
            image_tag,
            str(infra),
        ],
        check=True,
    )


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(
        description="Build ColonizeThis Daytona tools image and register a Snapshot.",
    )
    p.add_argument(
        "--image-tag",
        default=DEFAULT_LOCAL_IMAGE_TAG,
        help=f"Local docker image tag after build (default: {DEFAULT_LOCAL_IMAGE_TAG}).",
    )
    p.add_argument("--skip-docker", action="store_true", help="Skip docker build (step 1).")
    p.add_argument(
        "--skip-register",
        action="store_true",
        help="Skip Daytona snapshot registration (step 2).",
    )
    p.add_argument(
        "--snapshot-name",
        default=os.environ.get("DAYTONA_SNAPSHOT_NAME", DEFAULT_DAYTONA_SNAPSHOT_NAME).strip(),
        help="Daytona Snapshot name (default from DAYTONA_SNAPSHOT_NAME or built-in default).",
    )
    p.add_argument(
        "--snapshot-cpu",
        type=int,
        default=None,
        help="Snapshot template CPU cores (use with --snapshot-memory-gib and --snapshot-disk-gib).",
    )
    p.add_argument(
        "--snapshot-memory-gib",
        type=int,
        default=None,
        help="Snapshot template RAM in GiB.",
    )
    p.add_argument(
        "--snapshot-disk-gib",
        type=int,
        default=None,
        help="Snapshot template disk in GiB.",
    )
    ns = p.parse_args(argv)

    sizing = (ns.snapshot_cpu, ns.snapshot_memory_gib, ns.snapshot_disk_gib)
    if any(v is not None for v in sizing):
        if any(v is None for v in sizing):
            print(
                "Snapshot sizing: pass all three of --snapshot-cpu, "
                "--snapshot-memory-gib, --snapshot-disk-gib, or omit all for defaults.",
                file=sys.stderr,
            )
            return 1
        from daytona import Resources

        snapshot_resources = Resources(cpu=ns.snapshot_cpu, memory=ns.snapshot_memory_gib, disk=ns.snapshot_disk_gib)
    else:
        snapshot_resources = None

    if not ns.skip_docker:
        _docker_build(image_tag=ns.image_tag)
        print(f"Docker image built: {ns.image_tag}", file=sys.stderr)

    if ns.skip_register:
        return 0

    if not os.environ.get("DAYTONA_API_KEY", "").strip():
        print(
            "DAYTONA_API_KEY is required for snapshot registration (step 2).",
            file=sys.stderr,
        )
        return 1

    from daytona import Daytona

    infra = _infra_dir()
    dockerfile = infra / "Dockerfile"
    daytona = Daytona()
    log_chunks: list[str] = []

    def on_logs(chunk: str) -> None:
        log_chunks.append(chunk)
        print(chunk, end="", file=sys.stderr)

    register_tools_snapshot(
        daytona,
        snapshot_name=ns.snapshot_name,
        dockerfile_path=dockerfile,
        on_logs=on_logs,
        resources=snapshot_resources,
    )
    print(f"Registered Daytona snapshot: {ns.snapshot_name}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
