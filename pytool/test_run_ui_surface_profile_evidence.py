"""Regression tests for tool/run_ui_surface_profile_evidence.sh helpers."""

from __future__ import annotations

import re
import subprocess
import unittest

_UI_SURFACE_OPEN = re.compile(r"ui_surface_open surface=\S+[^\n]*")


def _extract_ui_surface_open_lines(log_text: str) -> list[str]:
    """Mirror post-drive evidence extraction in run_ui_surface_profile_evidence.sh."""
    return [m.group(0) for m in _UI_SURFACE_OPEN.finditer(log_text)]


_AWK = (
    "-F•",
    "/android/ { gsub(/^[ \\t]+|[ \\t]+$/, \"\", $2); if ($2 != \"\") { print $2; exit } }",
)


def _resolve_android_device_id_from_devices_output(output: str) -> str:
    """Mirror _resolve_android_device_id() in run_ui_surface_profile_evidence.sh."""
    result = subprocess.run(
        ["awk", *_AWK],
        input=output,
        text=True,
        capture_output=True,
        check=True,
    )
    return result.stdout.strip()


class RunUiSurfaceProfileEvidenceTests(unittest.TestCase):
    def test_multiword_emulator_name_resolves_emulator_id(self) -> None:
        line = (
            "sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x64 • "
            "Android 14 (API 34) (emulator)"
        )
        self.assertEqual(
            _resolve_android_device_id_from_devices_output(line),
            "emulator-5554",
        )

    def test_legacy_single_token_device_name_still_resolves(self) -> None:
        line = (
            "emulator • emulator-5556 • android-x86 • Android 14 (API 34) (emulator)"
        )
        self.assertEqual(
            _resolve_android_device_id_from_devices_output(line),
            "emulator-5556",
        )

    def test_skips_non_android_lines(self) -> None:
        output = "\n".join(
            [
                "Linux (desktop) • linux • linux-x64 • Ubuntu 22.04",
                "sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x64 • Android 14",
            ]
        )
        self.assertEqual(
            _resolve_android_device_id_from_devices_output(output),
            "emulator-5554",
        )

    def test_extracts_ui_surface_open_from_android_logcat_section(self) -> None:
        log = "\n".join(
            [
                "Running profile drive...",
                "All tests passed!",
                "",
                "=== adb logcat (ui_surface_open) ===",
                (
                    "I/flutter (12345): ui_surface_open surface=development "
                    "elapsed_ms=412 budget_ms=1000 host=android_emulator_profile"
                ),
                (
                    "I/flutter (12345): ui_surface_open surface=development "
                    "elapsed_ms=88 budget_ms=1000 host=android_emulator_profile warm=1"
                ),
            ]
        )
        lines = _extract_ui_surface_open_lines(log)
        self.assertEqual(len(lines), 2)
        self.assertIn("host=android_emulator_profile", lines[0])
        self.assertIn("warm=1", lines[1])


if __name__ == "__main__":
    unittest.main()
