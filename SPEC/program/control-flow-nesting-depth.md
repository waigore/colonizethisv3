# Control-flow nesting depth (repo lint)

**SPEC/program** — AST gate for excessive `if` / `for` / `while` / `do` / `switch` nesting inside each function or method body.

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_control_flow_nesting_depth.dart` | Analyzer visitor and CLI |
| `tool/control_flow_nesting_depth_allowlist.yaml` | Grandfathered `file` + `symbol` pairs still at depth ≥4 (do **not** add rows; refactor instead) |

## Scan scope

Same domain trees as other repo-lint AST rules: `collectRepoLintDomainDartFiles` (`packages/**/lib`, `app/lib`, `ctdev/lib`, `tool/**/lib`), excluding tests and generated `*.g.dart` / `*.freezed.dart` / `*.mocks.dart`.

## Counting rules

- **Depth** is the maximum stack depth while visiting control-flow nodes in a single executable body (method, constructor, or function). Closures and local `FunctionDeclaration` bodies are analyzed separately.
- **Counted nodes:** `IfStatement`, `ForStatement` / `ForElement`, `WhileStatement`, `DoStatement`, `SwitchStatement` (including `switch` members).
- **Guard `if`:** An `if` whose `then` is only an early exit (`return`, `continue`, `break`, or `throw` / `throw;`) and has **no** `else` does **not** increase depth (including short chains of such `if`s). Any other `if` increases depth for its `then` and `else` branches.
- **Closures:** `FunctionExpression` bodies are **not** folded into the enclosing method’s depth.

## Thresholds

- **Warning:** max depth ≥ **3** (summary line only unless `CT_NESTING_DEPTH_VERBOSE=1`).
- **Failure:** max depth ≥ **4** unless the `(file, symbol)` pair is listed under `allowed_depth_ge4` in the allowlist.

## Acceptance criteria

- Given the repository root as cwd, when CI runs `dart run tool/ct_repo_lint.dart`, then rule `repo.control_flow_nesting_depth` executes and a max depth ≥4 outside the allowlist fails the run with file, line, and symbol in the checker output.
