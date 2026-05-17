# CI and rules (reference)

## Rule routing (summary)

Authoritative index: **`AGENTS.md`** (“Rule location” / tables). Rules live in **`.cursor/rules/*.mdc`**. When scanning `app/` or `packages/<pkg>/lib/**`:

| Concern | Typical rule file |
|---------|-------------------|
| SPEC-first, doc boundaries | `colonizethis-spec-required.mdc` |
| Flutter vs Flame, typing, logging, province ids, `AppEventBus` | `colonizethis-core-principles.mdc` |
| Logic ↔ AI dependency direction | `colonizethis-logic-ai-decoupling.mdc` |
| Folders, extraction, naming | `colonizethis-component-structure.mdc` |
| Review checklist | `colonizethis-code-review.mdc` |
| Widget/Flame lifecycle | `colonizethis-lifecycle.mdc` |
| Tests, coverage expectations | `colonizethis-testing.mdc` |
| E2E / integration tests | `colonizethis-e2e-ui-stability.mdc` |
| UI specs / widgets | `colonizethis-ui-design.mdc` |
| Assets / pubspec | `colonizethis-assets.mdc` |
| AC quality in SPEC | `colonizethis-acceptance-criteria.mdc` |

Read the **frontmatter `globs`** on each `.mdc` when unsure; multiple rules can apply additively.

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
