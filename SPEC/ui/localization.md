# Localization (UI copy)

## Goal
All user-visible copy in the Flutter app is localized via Flutter’s built-in i18n mechanism (`gen_l10n` → `AppLocalizations`), with `en` as the initial and fallback locale.

## Scope
- **Applies to:** `app/lib/**` UI (Flutter widgets, Flame overlays implemented as Flutter widgets, menus, dialogs, tooltips).
- **Includes:**
  - Buttons, tabs, headers, section labels.
  - Tooltips and helper text.
  - Dialog titles/bodies/action labels.
  - User-visible error strings.
  - Dynamic UI strings with inserted values (turn numbers, names, counts).
  - UI-visible “game content” strings as presented to the user (resource/unit/tech labels and descriptions shown in UI).
- **Excludes:** internal logs, debug-only developer diagnostics not shown to the user (unless they are displayed in UI).

## Usage rules
- **No hard-coded UI copy** in widgets: do not write string literals directly into the slots visited by the CI gate (`SPEC/program/localization.md`): `Text` / `SelectableText`, `Tooltip.message`, `InputDecoration` `labelText` / `hintText`, `Semantics` `label` / `value` / `hint` / `tooltip`, and `SnackBarAction.label`. Dialogs and other composites should use localized children (e.g. `Text(l10n.…)`), which the gate catches via those nested slots.
- UI copy must come from `AppLocalizations` methods/getters.
- Dynamic UI copy must be localized using parameterized messages (e.g. `endTurnConfirm(turnNumber)`), not string interpolation in the widget.
- Where the same phrasing appears in multiple places, reuse the same localization key.
- **CI / PR gate:** `dart run tool/ct_repo_lint.dart` with the app rule enabled (see `SPEC/program/localization.md` and `SPEC/program/repo-lint.md`) invokes `tool/check_app_hardcoded_ui_strings.dart` — the authoritative AST check, including multiline `Text` / `Tooltip` / input decoration / `Semantics` / `SnackBarAction` string slots listed there, with suppressions aligned to `// ignore: avoid_hardcoded_strings_in_widgets`.
- **IDE:** `hardcoded_strings_lint` remains configured for editor feedback; do not rely on it alone as the merge gate.
- Do not use broad suppressions such as `ignore_for_file` for hardcoded-string lint in UI files.

## Allowed literal exceptions (narrow)
- Non-user-visible technical identifiers are allowed (e.g. route IDs, analytics/event keys, protocol/message keys).
- Asset/path/config literals are allowed where the string is not user-facing copy.
- Short symbol tokens are allowed where localization does not apply (for example punctuation-only or operator-like tokens).
- Localized strings that are user-visible copy are not exempt solely because they appear in debug, widgetbook, or dev-facing screens under `app/lib/**`.

## Acceptance criteria (Given–When–Then)

- **AC1 — Visible UI strings sourced from `AppLocalizations`.** Given any Flutter widget under `app/lib/**` that exposes user-visible copy through one of the CI-gated slots listed in `SPEC/program/localization.md` (`Text` / `SelectableText` content, `Tooltip.message`, `InputDecoration.labelText` / `hintText`, `Semantics.label` / `value` / `hint` / `tooltip`, `SnackBarAction.label`), when `tool/check_app_hardcoded_ui_strings.dart` is executed via `dart run tool/ct_repo_lint.dart` with the app rule enabled, then every such slot resolves to a value sourced from `AppLocalizations` (no bare string literal that is not on the allowed-literal exception list, and no `ignore_for_file` suppression) and the lint exits with code `0`.
- **AC2 — Parameterized/dynamic UI copy uses `AppLocalizations` parameters.** Given any user-visible string under `app/lib/**` that interpolates runtime values (turn numbers, names, counts, etc.), when the widget is rendered, then the string is produced by calling an `AppLocalizations` method that accepts the runtime values as parameters (for example `l10n.endTurnConfirm(turnNumber)`), and no widget composes the localized string via Dart string interpolation, `+` concatenation, or `StringBuffer` writes on the user-visible side.
- **AC3 — Tooltips, dialog text, and screen titles are localized.** Given any tooltip (`Tooltip.message`), dialog title or body (`AlertDialog` / `SimpleDialog` / custom dialog headers and content), or screen-title element rendered under `app/lib/**`, when the widget tree is built, then every user-visible string in those positions is sourced from `AppLocalizations` (subject to the **Allowed literal exceptions** list above), and `tool/check_app_hardcoded_ui_strings.dart` reports zero violations for those slots.

