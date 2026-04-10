# Hardcoded UI String Lint Gap Analysis (app)

## Scope
- Package: `app`
- Paths reviewed: `app/lib/**`
- Primary lint: `hardcoded_strings_lint` (`avoid_hardcoded_strings_in_widgets`)

## Findings
- `dart run custom_lint` / `flutter analyze` may still report no hardcoded-string findings for some real literals (package coverage varies by pattern and version).
- **CI enforcement:** `tool/check_app_hardcoded_ui_strings.py` runs in the Quality workflow and in `tool/run_quality_gate_tests.sh`, with multiline-safe patterns for `Text`/`SelectableText`, dialog `title`/`content`, `Tooltip.message`, `Semantics.label`, `labelText`/`hintText`, named `label:` string parameters, and `_buildSection` titles. Generated `app/lib/l10n/app_localizations*.dart` files are excluded.

## Regression tests
- `pytool/test_check_app_hardcoded_ui_strings.py` exercises the script via `CT_HARDCODE_UI_CHECK_WORKSPACE` (run: `python3 pytool/test_check_app_hardcoded_ui_strings.py`).

## Decision
- Keep `hardcoded_strings_lint` as the primary analyzer plugin; extend the Python gate when new UI literal shapes appear that must be zero-tolerance.
