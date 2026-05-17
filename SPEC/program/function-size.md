# Function size (repo lint)

**SPEC/program** — AST gate for oversized function and method declarations in
runtime domain Dart code.

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_function_size.dart` | Analyzer-based checker and CLI |

## Scan scope

The checker walks `collectRepoLintDomainDartFiles` and scopes to:

- `packages/*/lib/**`
- `app/lib/core/services/app_event_handler_debug_*.dart`

Generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`) and fixture/golden path markers from `repoLintFixtureDirPathMarkers` remain excluded by the shared scan contract (`tool/ct_repo_lint_scan_contract.dart`).

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
- Given a repository layout that includes a legacy keyed waiver YAML file under
  `tool/` (any filename; not read by the checker), when rule `repo.function_size`
  runs on an oversized symbol, then the run still fails because thresholds are
  enforced without loading keyed waiver data.
