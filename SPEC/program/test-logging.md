# Test logging

**SPEC/program** — How logging is configured when tests run. Runtime logging policy: [logging/logging.md](logging/logging.md); ctdev file/Sim Log: [ctdev-logging.md](ctdev-logging.md).

---

## Goal

When tests are run (e.g. via `tool/test_coverage.py` or `dart test` / `flutter test`), application log output must not be written to stdout so that test results stay readable.

---

## Approach: colonizethis_test package

- A shared dev-only package **colonizethis_test** provides the test (and Flutter test) entrypoints used by all tests.
- On load, it sets `Logger.level = Level.off` so the `logger` package produces no output in that isolate.
- Every test file imports `package:colonizethis_test/test.dart` instead of `package:test/test.dart`. Flutter test files add `package:flutter_test/flutter_test.dart` as well.
- **Import order:** `package:colonizethis_test/test.dart` must be the first import (or immediately after `dart:` imports) so that `Logger.level = Level.off` runs before any package that uses `Logger` is loaded.
- Convention: **all new test files** use this import first so logging stays off by default when tests run.

---

## Package layout

- **packages/colonizethis_test/** — Dev-only package, not published.
- **lib/test.dart** — Sets `Logger.level = Level.off`, then exports `package:test/test.dart`. Use for all tests (Dart and Flutter); Flutter test files add `package:flutter_test/flutter_test.dart` for widget APIs.
- For **Flutter** widget/integration tests: import `package:colonizethis_test/test.dart` first (to suppress logs), then `package:flutter_test/flutter_test.dart` for test APIs.

Any package or app that has tests adds **colonizethis_test** as a **dev_dependency**. Dart test files use only `package:colonizethis_test/test.dart`. Flutter test files use that import first, then `package:flutter_test/flutter_test.dart`.

**If log output still appears:** Some test runners may load dependencies in an order where logger-using packages are initialized before colonizethis_test. The package sets both `Logger.level = Level.off` and `Logger.defaultFilter` to a no-op filter so that any Logger created after the init will not output.

**test_coverage.py:** When running tests via `tool/test_coverage.py`, console output is **whitelisted**: only lines that look like Dart/Flutter test runner output (pass/fail counts, test names, Expected/Actual/Which, summary) are printed. All other lines (logger, print, loading chatter) are suppressed so only test results are visible.

---

## Coverage

- Run **`tool/test_coverage.py`** to run all package and app tests with coverage. Output is written to each package’s `coverage/` and optionally merged to `coverage_merged/` when `lcov` is installed. The script prints a per-package and overall line-coverage summary.
- To enforce a minimum line coverage, run **`tool/check_coverage_threshold.sh [threshold] [dir1 [dir2 ...]]`** after `tool/test_coverage.py`. If no directories are given, all app, ctdev, and packages are checked. Example: `tool/check_coverage_threshold.sh 90`. To check only a specific target: `tool/check_coverage_threshold.sh 90 packages/colonizethis_logic`. **Logic, map, and AI packages** are checked at **90%** in the quality gate; a **91%** target is documented for future raises. The script exits with code 1 if any checked target is below the threshold.
- **App coverage:** The app package has an **85% line-coverage target** across the entire **`app/lib/`** tree. All application code under `lib/` (widgets, configuration, core services, providers, and feature modules) is in scope for this gate.
- When you run **`tool/run_quality_gate_tests.sh`**, the script runs **`flutter test test/ --coverage`** in `app/` (widget/unit tests only; **`integration_test/`** is excluded — see [e2e-integration-tests.md](e2e-integration-tests.md)) and then **`tool/check_coverage_threshold.sh 85 app`**, which enforces that overall `app/lib/` coverage is at or above 85%. To verify app coverage after `tool/test_coverage.py`: `tool/check_coverage_threshold.sh 85 app`.
- **Improving app coverage:** Add tests in `app/test/` that exercise both UI and non-UI code under `app/lib/` (widgets, feature screens, providers, services, and helpers). Cover uncovered branches in high-value flows (main menu, game setup, production and diplomacy panels, core providers and services). See UI specs under `SPEC/ui/` and existing integration tests in `app/test/` for acceptance criteria and flows to exercise.

---

## Verifying the quality gate

The GitHub workflow **.github/workflows/quality.yml** runs the same test scope as `tool/test_coverage.py` but in split steps with `--reporter=compact` (pass/fail only). You can verify it locally in either of these ways:

1. **Run the same steps locally:** From the repo root, run **`tool/run_quality_gate_tests.sh`**. This runs the same commands as the workflow (packages Dart, app Flutter, ctdev Flutter, tool packages Dart, coverage gate, sim_scenarios). Requires `dart`, `flutter`, and `lcov`.
2. **Run the workflow with act:** If [act](https://github.com/nektos/act) is installed, run `act pull_request -n` (dry run) or `act pull_request` to execute the Quality job locally.
3. **Trigger CI:** Push to a branch and open a PR against `main` or `dev`; the Quality job runs on the push.
