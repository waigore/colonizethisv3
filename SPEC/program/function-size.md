# Function size (repo lint)

**SPEC/program** — AST gate for oversized function and method declarations in
runtime domain Dart code.

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_function_size.dart` | Analyzer-based checker and CLI |

## Scan scope

The checker walks `collectRepoLintDomainDartFiles` and then scopes to
`packages/colonizethis_logic/lib/src/**` for this phase.

Tests and generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`) remain
excluded by the shared scan contract.

## Measurement contract

- A function is measured by source lines from declaration start to declaration
  end (inclusive).
- Blank lines are excluded.
- Single-line comments that begin with `//` are excluded.
- All other lines count, including braces and block-comment lines.
- Failure threshold is measured line count **>200**.

## Acceptance criteria

- Given repository root as cwd, when CI runs `dart run tool/ct_repo_lint.dart`,
  then rule `repo.function_size` runs and fails on any symbol measured over 200
  lines with no per-file or per-symbol exemptions.
