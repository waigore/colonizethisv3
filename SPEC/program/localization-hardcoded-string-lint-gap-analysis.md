# Hardcoded UI string enforcement (app)

## Scope
- Package: `app`
- Paths: `app/lib/**`
- Supplemental lint: `hardcoded_strings_lint` (`avoid_hardcoded_strings_in_widgets`)

## Findings
- `dart run custom_lint` / `flutter analyze` in `app/` often report **no** hardcoded-string diagnostics for real violations (workspace / parser shape).
- Non-const widget calls such as `Text('…')` are represented as **`MethodInvocation`** (not `InstanceCreationExpression`) under `parseString`; a repo checker must handle both, plus `const` constructor calls as ICE.

## Repo gate (authoritative)
- **Tool:** `tool/check_app_hardcoded_ui_strings.dart` — `dart run tool/check_app_hardcoded_ui_strings.dart` from the repo root.
- **Method:** Dart AST via `package:analyzer` `parseString`; visits `MethodInvocation` (unqualified or import-prefix call) and `InstanceCreationExpression` for: `Text`, `SelectableText`, `Tooltip` (`message:`), `InputDecoration` (`labelText`, `hintText`).
- **Multiline:** Arguments split across lines are covered because the visitor uses expression nodes, not line regexes.
- **Interpolations:** String literals with static segments inside `${}` are flagged (user-visible template text must move to ARB-parameterized messages).
- **Tests:** `test/check_app_hardcoded_ui_strings_test.dart`.

## Decision
- Keep `hardcoded_strings_lint` in `app/` for IDE assistance.
- Treat the Dart AST script + Quality workflow step as the **hard** merge gate for hardcoded UI copy in the covered widget slots.
