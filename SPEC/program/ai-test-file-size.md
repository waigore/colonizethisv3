# AI planning / support_test file size (`repo.ai_test_file_size`)

## Purpose

Keep ungated `packages/colonizethis_ai/test/planning/**` and
`test/support_test/**` Dart files from silently re-growing past 300 physical
lines after Phase-16 densify (Refs #4602). Basename-allowlist suite gates miss
hosts such as `goal_manager_test.dart`.

## Scope

- **In scope:** every `*.dart` file under
  `packages/colonizethis_ai/test/planning/` and
  `packages/colonizethis_ai/test/support_test/`.
- **Out of scope:** `test/support/**` (`repo.ai_test_support_file_size` /
  `repo.ai_s7d_support_suite_size`), `test/observer/**`
  (`repo.ai_observer_suite_size`). Those trees still use a 400 ceiling until
  Slice E densify.
- **Ceiling:** **300 physical lines** per file.
- **Allowlist:** none; split with topic-named `*_cases.dart` / named hosts. Do
  not add `*_partN_test.dart`.

## Enforcement

| Item | Location |
|------|----------|
| Checker | `tool/check_ai_test_file_size.dart` |
| Unit tests | `test/check_ai_test_file_size_test.dart` |
| Manifest rule | `repo.ai_test_file_size` in `tool/ct_repo_lint_manifest.yaml` (`pr_incremental: true`) |

## Acceptance criteria

- Given every in-scope planning / support_test Dart file has ≤300 physical
  lines, when `dart run tool/ct_repo_lint.dart` runs rule `repo.ai_test_file_size`,
  then the rule passes and exits `0` (Refs #4602).
- Given an in-scope file exceeds 300 physical lines, when the rule runs, then
  the run fails listing the offending file and exits `1` (Refs #4602).
- Given a file under `test/observer/` or `test/support/`, when the rule runs,
  then that file is excluded.
