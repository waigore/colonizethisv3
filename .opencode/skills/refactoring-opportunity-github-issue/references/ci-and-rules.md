# CI and rules (reference)

## Rule routing (summary)

Use the canonical routing map at `.cursor/rules/routing-index.md` for:

- applicability matrix (which rules apply in each context),
- precedence (always-applied baseline + context overlays), and
- non-duplication expectations for pointers vs policy text.

Normative policy wording lives only in `.cursor/rules/*.mdc`. OpenCode references should link to those files instead of restating policy clauses.

## Existing CI gates (extension points)

Primary workflow: **`.github/workflows/quality.yml`**.

| Area | Typical extension |
|------|-------------------|
| Repo-wide conventions, manifest-driven rules | `dart run tool/ct_repo_lint.dart` — `tool/ct_repo_lint_manifest.yaml`, implementation under `tool/ct_repo_lint_lib.dart` |
| Long `switch` / string dispatch | `dart tool/check_long_string_switches.dart` (already in app cache job) |
| Domain exception patterns | `bash tool/run_custom_lint_domain_exceptions.sh`, package `packages/colonizethis_exception_lint` |
| AST policy tests (examples) | `dart test test/check_disallowed_ast_patterns_test.dart`, other `test/check_*_test.dart` steps in `quality` job |
| App analyze | `app` job: `flutter analyze` (errors only) |
| Coverage | `tool/check_coverage_threshold.sh` with package paths |

When suggesting a new invariant, first grep or read **`tool/ct_repo_lint_manifest.yaml`** and **`test/check_*`** for a similar rule.

## AST-first preference

1. **`analyzer` / `custom_lint`** — best for stable Dart semantics and IDE alignment.
2. **`ct_repo_lint` manifest** — good for path-scoped, text/AST hybrid conventions already centralized.
3. **Dedicated `tool/*.dart` + small test** — when the check is repo-specific and needs `analyzer` package or custom traversal; mirror existing `check_*` tests.

Avoid proposing slow or flaky checks (full integration runs as the *only* enforcement for a simple style rule).
