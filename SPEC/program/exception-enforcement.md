# Exception Type Enforcement (AST)

## Purpose

Prevent generic exception usage in domain runtime code and enforce domain-specific exception types over time.

This spec defines a phased AST-based enforcement flow that is compatible with the current repository shape and CI workflow.

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
- `ctterm/lib/**`
- `tool/**/lib/**`

Generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`) are excluded.

## Implementation Contract (AST checker)

The repository uses an AST-based checker that:

1. Parses Dart files with analyzer.
2. Visits `ThrowExpression` nodes.
3. Detects `InstanceCreationExpression` for disallowed generic exception constructors.
4. Reports file + line + constructor name for each violation.
5. Fails CI when a violation is outside the migration allowlist.

## Rollout Model

### Phase 1 (this issue slice)

- Introduce checker and CI hook.
- Migrate setup domain (`packages/colonizethis_logic/lib/src/setup/**`) to `SetupValidationException`.
- Keep a temporary allowlist for legacy violations in other domains so new violations are still blocked.

### Phase 2+

- Remove allowlist entries incrementally by domain/package.
- Add domain-root exception families where missing.
- Keep checker mandatory in CI.

## Acceptance Criteria

- AST checker exists and runs from repository root.
- Checker scans all runtime domains listed above.
- New generic exception throws fail checks unless explicitly allowlisted.
- Setup domain migration uses `SetupValidationException` for validation failures.
