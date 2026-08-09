# Data package — test file physical line size (repo lint)

**SPEC/program** — repository lint gate that caps physical line count for
`packages/colonizethis_data/test/**` Dart files.

## Motivation

Wave-4 densify (#4121) extracted large scenario tables from
`civilian_build_scoring_test.dart` and `combat_config_test.dart` into
`test/support/` helpers. This gate prevents those suites from re-growing past
review-friendly size, mirroring `repo.economy_test_file_size` and
`repo.save_test_file_size`.

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_data_test_file_size.dart` | Checker and CLI entrypoint |
| `tool/ct_repo_lint_manifest.yaml` (`repo.data_test_file_size`) | Rule registration |

## Scan scope

All `.dart` files under `packages/colonizethis_data/test/**` recursively.
Support helpers under `test/support/` share the same ceiling.

## Ceiling

**400 physical lines** per file (empty shrink-only grandfather allowlist).

## Acceptance criteria

- Given every `.dart` file under `packages/colonizethis_data/test/**` is at or
  below 400 physical lines, when `dart run tool/ct_repo_lint.dart` runs rule
  `repo.data_test_file_size`, then the rule passes and exits `0` (Refs #4121, #4292).
- Given a data test file exceeds 400 physical lines and is not on the
  grandfather allowlist, when the checker runs, then the run fails listing the
  offending path and exits `1` (Refs #4121).
- Given a stale grandfather allowlist entry (missing file), when the checker
  runs, then the run fails with a stale-entry message and exits `1` (Refs
  #4121).
