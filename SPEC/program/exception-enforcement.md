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
3. Detects disallowed generic throws: `ArgumentError` / `Exception` as `InstanceCreationExpression` (e.g. `throw const ArgumentError(...)`) or as implicit-constructor `MethodInvocation` with a null target (e.g. `throw ArgumentError(...)` / `throw Exception(...)`), and `ArgumentError.value(...)` (static `MethodInvocation` on `ArgumentError`).
4. Reports file + line + disallowed form for each violation.
5. Fails CI on violations (Phase 2+ may introduce an explicit path allowlist for documented interop boundaries).

## Rollout Model

### Phase 1 (implemented)

- Introduce checker and CI hook.
- Migrate setup domain (`packages/colonizethis_logic/lib/src/setup/**`) to `SetupValidationException`.
- Add package-local validation exception types in map/data/models/ui/ctterm/tool runtime code and migrate existing generic throws in those domains.

### Phase 2+

- Expand to broader thrown-type validation policy per domain (e.g. path glob → allowed base types).
- Keep checker mandatory in CI and apply the same migration pattern to any newly introduced runtime packages.

## Acceptance Criteria

- AST checker exists and runs from repository root.
- Checker scans all runtime domains listed above.
- New generic exception throws fail checks unless explicitly allowlisted.
- Setup domain migration uses `SetupValidationException` for validation failures.
