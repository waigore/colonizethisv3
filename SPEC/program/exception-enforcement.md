# Exception Type Enforcement (AST)

## Purpose

Prevent generic exception usage in domain runtime code and enforce domain-specific exception types over time.

This spec defines a phased AST-based enforcement flow that is compatible with the current repository shape and CI workflow.

**Umbrella policy:** `SPEC/program/repo-lint.md` forbids violation allowlists for `repo.*` rules. `repo.custom_exceptions` must not load keyed waiver YAML or other tables whose purpose is to waive failures for specific symbols or files while CI passes.

## Source Of Truth

- Game logic behavior remains defined by `SPEC/game/**`.
- Architecture and quality gates are defined here in `SPEC/program/**`.
- UI and AI exception usage follows the same program-level enforcement policy in their runtime packages.

## Policy

### Runtime domain code must not throw generic exceptions

In runtime domain files (non-test):

- `throw ArgumentError(...)` is disallowed.
- `throw ArgumentError.value(...)` is disallowed.
- `throw Exception(...)` is disallowed.

Use a domain-specific exception type instead (for example setup validation in logic uses `SetupValidationException`).

### Domain coverage

Enforcement applies to runtime code across:

- `packages/**/lib/**`
- `app/lib/**`
- `ctdev/lib/**`
- `tool/**/lib/**`

Generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`) are excluded.

## Implementation Contract (AST checker + custom_lint)

The repository enforces the same policy in two places (shared implementation in `packages/colonizethis_exception_lint`):

1. **CI / CLI:** Quality runs `dart run tool/ct_repo_lint.dart` (rule `repo.custom_exceptions`; see [repo-lint.md](repo-lint.md)), which invokes `tool/check_custom_exceptions.dart`. Direct run: `dart run tool/check_custom_exceptions.dart` (also `melos run check_custom_exceptions`). File discovery uses `tool/ct_repo_lint_scan_contract.dart` (`collectRepoLintDomainDartFiles`, including package `test/` and `integration_test/` per [repo-lint.md](repo-lint.md) scan contract), same as the disallowed-AST checker.
2. **IDE / analyzer:** `custom_lint` with package `colonizethis_exception_lint`, wired in every workspace package that contains scoped runtime `lib/` code (see each package `pubspec.yaml` + `analysis_options.yaml`). Run locally per package via `dart run custom_lint`, or `bash tool/run_custom_lint_domain_exceptions.sh` for all wired packages. CI runs the same script after the root checker.

### `test/` and `integration_test/` (GitHub #2014)

**Target parity:** For every package wired by `tool/run_custom_lint_domain_exceptions.sh`, **`test/`** and **`integration_test/`** should reach the **same analyzer diagnostic bar as `lib/`** (zero `error`-severity issues from `custom_lint` / analyzer for those rules), with the same generated-file exclusions as runtime code. **Land enforcement in phased PRs** so `dev` stays green: fix violations before or with any CI tightening; see [repo-lint.md](repo-lint.md) section *Test and `integration_test/` static analysis scope* for mergeability and analyzer vs binary-tool semantics.

The checker:

1. Parses Dart files with analyzer.
2. Visits `ThrowExpression` nodes.
3. Detects disallowed generic throws: `ArgumentError` / `Exception` as `InstanceCreationExpression` (e.g. `throw const ArgumentError(...)`) or as implicit-constructor `MethodInvocation` with a null target (e.g. `throw ArgumentError(...)` / `throw Exception(...)`), and `ArgumentError.value(...)` (static `MethodInvocation` on `ArgumentError`).
4. Reports file + line + disallowed form for each violation.
5. Fails CI on violations. Any future broader thrown-type policy must follow `SPEC/program/repo-lint.md`: **scope-only** exclusions (whole paths, generated trees, env-gated scan roots) are allowed; **keyed** per-symbol or per-file waiver tables are not.

## Rollout Model

### Phase 1 (implemented)

- Introduce checker and CI hook.
- Add `colonizethis_exception_lint` (`custom_lint` plugin) for in-editor diagnostics aligned with the checker.
- Migrate setup domain (`packages/colonizethis_logic/lib/src/setup/**`) to `SetupValidationException`.
- Add package-local validation exception types in ai/map/data/models/ui/tool runtime code and migrate existing generic throws in those domains.

### Phase 2+

- Expand to broader thrown-type validation per domain using additional AST rules or closed declaration surfaces, without introducing keyed violation waivers (see `SPEC/program/repo-lint.md`).
- Keep checker mandatory in CI and apply the same migration pattern to any newly introduced runtime packages.

## Acceptance Criteria

- Given repository root as cwd, when a maintainer runs `dart run tool/check_custom_exceptions.dart` (or `dart run tool/ct_repo_lint.dart` for rule `repo.custom_exceptions`), then the checker executes and exits `0` only when no scanned in-scope file contains a forbidden generic throw.
- Given a workspace package `packages/*/lib/**/*.dart` file that contains `throw ArgumentError(...)`, `throw ArgumentError.value(...)`, or `throw Exception(...)`, when the checker scans that file, then the run fails and output includes that file path, line number, and the disallowed exception form.
- Given a repository layout that includes a legacy keyed-waiver-shaped YAML file under `tool/` (for example a decoy `legacy_custom_exception_waiver_table.yaml`), when `runCheckCustomExceptions` runs, then the checker still fails if an in-scope file violates the policy, because no keyed waiver data is loaded.
- Given the same rules are wired as `custom_lint` in workspace packages, when a developer analyzes scoped `lib/` code in the IDE, then diagnostics align with the CI checker for the same patterns.
- Given setup validation code in `packages/colonizethis_logic/lib/src/setup/**`, when validation must signal failure, then it uses `SetupValidationException` (or another domain-specific type), not `ArgumentError` / `Exception` as defined in [Policy](#policy).
