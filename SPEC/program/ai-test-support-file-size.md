# AI test support file size (`repo.ai_test_support_file_size`)

## Purpose

Keep `packages/colonizethis_ai/test/support/**` modules small and topic-focused so expand-peace and other planning pins stay maintainable after Phase-12 god-module splits (Refs #4291).

## Scope

- **In scope:** every `*.dart` file under `packages/colonizethis_ai/test/support/` **except** `test/support/s7d/**` (gated by `repo.ai_s7d_support_suite_size`). Observer campaign suites under `test/observer/` are gated separately by `repo.ai_observer_suite_size` (250 physical; Refs #4530, #4669).
- **Ceiling:** **250 physical lines** per file (Phase 17 Slice E, Refs #4669).
- **Allowlist:** empty shrink-only grandfather; stale entries fail CI.

## Enforcement

| Item | Location |
|------|----------|
| Checker | `tool/check_ai_test_support_file_size.dart` |
| Unit tests | `test/check_ai_test_support_file_size_test.dart` |
| Manifest rule | `repo.ai_test_support_file_size` in `tool/ct_repo_lint_manifest.yaml` |

## Acceptance criteria

- Given every in-scope support module has ≤250 physical lines, when `dart run tool/ct_repo_lint.dart` runs rule `repo.ai_test_support_file_size`, then the rule passes and exits `0` (Refs #4291, #4669).
- Given an in-scope support module exceeds 250 physical lines, when the rule runs, then the run fails listing the offending file and exits `1` (Refs #4291, #4669).
- Given a file under `test/support/s7d/`, when the rule runs, then that file is excluded (S7D gate owns it).
