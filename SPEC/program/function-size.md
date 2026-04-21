# Function size (repo lint)

**SPEC/program** — AST gate for oversized function and method declarations in
runtime domain Dart code.

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_function_size.dart` | Analyzer-based checker and CLI |
| `tool/function_size_allowlist.yaml` | Grandfathered `(file, symbol)` rows with a shrink-only `max_measured_lines` cap |

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

## Allowlist contract (shrink-only)

`tool/function_size_allowlist.yaml` uses:

```yaml
allowed_over_20:
  - file: packages/foo/lib/src/example.dart
    symbol: someFunction
    max_measured_lines: 42
```

- If a symbol is allowlisted, the checker allows it only while measured lines
  stay `<= max_measured_lines`.
- The top-level key name remains `allowed_over_20` for backward compatibility.
- If measured lines grow above the listed max, the checker fails.
- New allowlist rows are not a default fix; prefer extracting helpers and
  reducing measured lines.

## Acceptance criteria

- Given repository root as cwd, when CI runs `dart run tool/ct_repo_lint.dart`,
  then rule `repo.function_size` runs and fails on any non-allowlisted symbol
  measured over 200 lines with file, line, and symbol in output.
- Given an allowlisted symbol and measured lines below or equal to its
  `max_measured_lines`, when the checker runs, then it does not fail for that
  symbol.
- Given an allowlisted symbol whose measured lines exceed its
  `max_measured_lines`, when the checker runs, then it fails for that symbol.
