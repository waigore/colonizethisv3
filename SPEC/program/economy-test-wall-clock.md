# Economy test wall-clock gate

**SPEC/program** — Optional performance enforcement for the `packages/colonizethis_economy` `dart test` suite. Tracks the dedup/fixture-hoisting work in GitHub #3661 so the wall-clock gains are not silently regressed. Test logging policy: [test-logging.md](test-logging.md).

---

## Responsibility

`tool/check_economy_test_wall_clock.sh` measures the wall-clock time of the economy package test suite and compares it against a configurable ceiling. It is a thin facade: it shells out to `dart test`, computes a median over repeated runs, and applies a deterministic comparison. It owns no game or economy logic.

The gate exists because the economy suite's cost is dominated by repeated heavy fixture construction; #3661 deduplicated suites and hoisted shared fixtures to bring the wall-clock down. This tool locks in that gain.

## Modes

- **Advisory (default):** Measure and report; always exit `0`. A median over the ceiling prints a `WARN` line. Intended for CI runners whose absolute timing is noisy.
- **Enforce (opt-in):** Set `ECONOMY_TEST_TIMING_ENFORCE=1`. A median strictly greater than the ceiling exits `1`; otherwise exit `0`.
- **Skip:** Set `SKIP_ECONOMY_TEST_TIMING=1`. The tool prints a skip notice and exits `0` without measuring.

## Configuration

| Variable | Default | Meaning |
|---|---|---|
| `ECONOMY_TEST_TIMING_CEILING_SECONDS` | `25` | Inclusive upper bound for the median measured wall-clock (seconds). |
| `ECONOMY_TEST_TIMING_RUNS` | `3` | Number of `dart test` runs measured; the median is compared. Must be an odd integer `>= 1`. |
| `ECONOMY_TEST_TIMING_ENFORCE` | unset | When `1`, over-ceiling is a hard failure. |
| `SKIP_ECONOMY_TEST_TIMING` | unset | When `1`, skip measurement entirely. |
| `ECONOMY_TEST_TIMING_MEASURED_SECONDS` | unset | Test/CI hook: bypass running `dart test` and treat this value as the median measurement. Used to exercise the deterministic comparison path. |

The ceiling is a runner-relative ceiling, not the dev-class baseline from #3661 (≈2.25 s). It is set generously so the default advisory mode never produces false alarms; tighten only when enforcing on calibrated hardware.

## Acceptance criteria

- Given `SKIP_ECONOMY_TEST_TIMING=1`, when the tool runs, then the tool prints a skip notice and exits with code `0` without invoking `dart test`.
- Given `ECONOMY_TEST_TIMING_MEASURED_SECONDS=10` and `ECONOMY_TEST_TIMING_CEILING_SECONDS=25` (no enforce), when the tool runs, then the tool prints a pass line and exits with code `0`.
- Given `ECONOMY_TEST_TIMING_MEASURED_SECONDS=40` and `ECONOMY_TEST_TIMING_CEILING_SECONDS=25` and enforce unset, when the tool runs, then the tool prints a `WARN` line and exits with code `0`.
- Given `ECONOMY_TEST_TIMING_MEASURED_SECONDS=40`, `ECONOMY_TEST_TIMING_CEILING_SECONDS=25`, and `ECONOMY_TEST_TIMING_ENFORCE=1`, when the tool runs, then the tool prints a failure line and exits with code `1`.
- Given `ECONOMY_TEST_TIMING_MEASURED_SECONDS=25` and `ECONOMY_TEST_TIMING_CEILING_SECONDS=25` and `ECONOMY_TEST_TIMING_ENFORCE=1`, when the tool runs, then the tool treats the value as within budget (equal is allowed) and exits with code `0`.

## Integration

- **Owner:** `tool/check_economy_test_wall_clock.sh`; regression coverage in `tool/test_check_economy_test_wall_clock.sh`.
- **CI:** Invoked in advisory mode from the nightly integration gate ([test-logging.md](test-logging.md), `.github/workflows/nightly.yml`) so it reports without blocking PRs.
- **Local:** Run `bash tool/check_economy_test_wall_clock.sh` from the repo root. See [../../docs/project-tools.md](../../docs/project-tools.md).

## Constraints

- The tool must not leave run artifacts: it runs `dart test` **without** `--coverage`, so no `coverage/` tree is produced.
- The comparison must be deterministic for fixed inputs (median + ceiling), independent of the measurement mechanism.
- Operational output goes to stdout; the tool emits no application logging.
