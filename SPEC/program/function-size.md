# Function size (repo lint)

**SPEC/program** — AST gate for oversized function and method declarations in
runtime domain Dart code.

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_function_size.dart` | Analyzer-based checker and CLI |
| `tool/function_size_allowlist.yaml` | **Legacy:** grandfathered `(file, symbol)` rows for symbols still over 200 measured lines; shrink-only until rows are retired |

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

## Legacy allowlist contract (shrink-only)

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
- Only symbols currently measured above 200 belong in this legacy file.
- If measured lines grow above the listed max, the checker fails.
- New allowlist rows are disallowed by default; prefer extracting helpers and
  reducing measured lines, then deleting legacy rows.

## Acceptance criteria

- Given repository root as cwd, when CI runs `dart run tool/ct_repo_lint.dart`,
  then rule `repo.function_size` runs and fails on any symbol measured over 200
  lines unless that symbol appears in the legacy allowlist with a sufficient
  shrink-only `max_measured_lines` cap.
- Given an allowlisted symbol and measured lines below or equal to its
  `max_measured_lines`, when the checker runs, then it does not fail for that
  symbol.
- Given an allowlisted symbol whose measured lines exceed its
  `max_measured_lines`, when the checker runs, then it fails for that symbol.
