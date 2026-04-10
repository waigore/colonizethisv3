# Repo lint (unified CLI)

**SPEC/program** — Single entrypoint for **repository-wide** convention checks that are not `dart analyze` / `custom_lint` (those stay IDE- and analyzer-driven).

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/ct_repo_lint_manifest.yaml` | Lists **rules** with stable **`rule_id`**, **group**, human title, SPEC path, and how to invoke the checker |
| `tool/ct_repo_lint.dart` | Orchestrator: loads manifest, runs rules in order, stops on first failure |
| `tool/ct_repo_lint_lib.dart` | Parse/execute helpers (also covered by `test/ct_repo_lint_test.dart`) |
| `tool/ct_repo_lint_scan_contract.dart` | **Shared scan contract:** (1) `collectRepoLintDomainDartFiles` + predicates for exception / disallowed-AST-style **`lib/`** trees; (2) `repoLintIdentifierLiteralScanRoots`, `collectRepoLintDartFilesUnderRelativeRoots`, and `repoLintIdentifierLiteralShouldSkipFile` for tech / work-target / civilian literal checkers (`test/ct_repo_lint_scan_contract_test.dart`) |

## Rule IDs and groups

Each rule has a stable `rule_id` (prefix `repo.`). **Groups** (non-exhaustive): `structure`, `architecture`, `identifiers`, `exceptions`, `game_invariants`, `ui_i18n`. Violation text from underlying tools should include **file path and line** (and column when the checker provides it). The orchestrator prints a banner `--- [rule_id] title ---` before each subprocess so logs stay attributable.

## CI contract

- **Quality workflow:** One step runs `dart run tool/ct_repo_lint.dart` after OrderEngine codegen verification. Gates that are **not** bundled repo-lint rules stay separate (e.g. `tool/verify_order_engine_codegen.sh`, coverage thresholds, `custom_lint`, package tests).
- **App UI string gate:** Rule `repo.app_hardcoded_ui_strings` runs only when `CT_REPO_LINT_INCLUDE_APP` is exactly `true` (workflow sets this from path filters when app/package paths changed).

## PR incremental scans

Rules marked `pr_incremental: true` in the manifest receive `--files <csv>` when `GITHUB_BASE_REF` is set and `git fetch` / `git diff origin/<base>...HEAD -- '*.dart'` succeeds and yields paths—matching the previous inline `quality.yml` behavior. Use `--force-full-scan` to disable incremental arguments locally or in scripts.

## Adding or changing rules

Do **not** add new top-level `tool/check_*.dart` **entrypoints** for CI without updating this SPEC and the manifest. Prefer:

1. Add a row under `rules:` in `tool/ct_repo_lint_manifest.yaml` with a new stable `rule_id`.
2. Implement or extend logic in a **library** or existing checker module; keep a single `main()` wrapper only if required for `dart run`, and wire it from the manifest.
3. When a new checker scans the **same domain `lib/` tree** as exception / disallowed-AST enforcement, reuse **`collectRepoLintDomainDartFiles`** (and related predicates) from **`tool/ct_repo_lint_scan_contract.dart`**. When it matches **tech / work-target / civilian** literal scans (`app`, `ctterm`, `packages`, `tool` trees, `lib/`-gated, fixture-dir markers), reuse **`repoLintIdentifierLiteralScanRoots`** and **`repoLintIdentifierLiteralShouldSkipFile`** with a checker-local `excludedPaths` set.
4. Align wording with `colonizethis_exception_lint` (and similar) when the same policy exists in the analyzer.

## CLI options

`dart run tool/ct_repo_lint.dart --help` — `--list`, `--rule`, `--group`, `--manifest`, `--verbose`, `--force-full-scan`.

## Follow-ups (out of scope for initial landing)

- SARIF output for GitHub annotations.
- Align **canonical province tile-key** and **app hardcoded UI string** checkers with the same contract patterns where it reduces duplication without changing coverage.
- Optionally lift shared roots into the manifest once all consumers read it.

## Acceptance criteria

- Given the repository root as cwd, when CI runs `dart run tool/ct_repo_lint.dart` with the workflow env, then all manifest rules applicable to that job execute and failures surface with `rule_id` in the orchestrator banner.
- Given a contributor adds a convention, when they follow CONTRIBUTING and this doc, then they register the rule in the manifest rather than adding a new standalone Quality workflow step for the same concern.
