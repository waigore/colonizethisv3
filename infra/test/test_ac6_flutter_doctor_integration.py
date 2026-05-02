"""AC6: optional flutter doctor in Docker (Refs #2065)."""

from __future__ import annotations

import os
import shutil
import subprocess

import pytest

from colonizethis_infra.constants import DEFAULT_LOCAL_IMAGE_TAG


@pytest.mark.daytona_integration
def test_flutter_doctor_android_and_linux() -> None:
    if os.environ.get("RUN_INFRA_FLUTTER_DOCTOR") != "1":
        pytest.skip("Set RUN_INFRA_FLUTTER_DOCTOR=1 to run AC6 Docker integration.")
    if not shutil.which("docker"):
        pytest.skip("docker not available")

    image = os.environ.get("INFRA_DOCKER_IMAGE", DEFAULT_LOCAL_IMAGE_TAG)
    r = subprocess.run(
        [
            "docker",
            "run",
            "--rm",
            image,
            "bash",
            "-lc",
            "flutter doctor -v",
        ],
        check=False,
        capture_output=True,
        text=True,
        timeout=600,
    )
    out = (r.stdout or "") + (r.stderr or "")
    assert r.returncode == 0, out
    lo = out.lower()
    assert "android" in lo
    assert "linux" in lo
