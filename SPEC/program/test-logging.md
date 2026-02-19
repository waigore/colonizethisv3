# Test logging

**SPEC/program** — How logging is configured when tests run. See [ctdev-logging.md](ctdev-logging.md) for runtime logging.

---

## Goal

When tests are run (e.g. via `tool/test_coverage.sh` or `dart test` / `flutter test`), application log output must not be written to stdout so that test results stay readable.

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

**If log output still appears:** Some test runners may load dependencies in an order where logger-using packages are initialized before colonizethis_test. The package sets both `Logger.level = Level.off` and `Logger.defaultFilter` to a no-op filter so that any Logger created after the init will not output. For CI or coverage runs, you can pipe test output and filter out logger-style lines (e.g. lines containing `│` or `logic:`/`map:`/`save:`).

---

## Coverage

- Run **`tool/test_coverage.sh`** to run all package and app tests with coverage. Output is written to each package’s `coverage/` and optionally merged to `coverage_merged/` when `lcov` is installed. The script prints a per-package and overall line-coverage summary.
- To enforce a minimum line coverage (e.g. 90%), run **`tool/check_coverage_threshold.sh [threshold]`** after `tool/test_coverage.sh`. Example: `tool/check_coverage_threshold.sh 90`. It exits with code 1 if any package is below the threshold.
