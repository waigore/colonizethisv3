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
- **CI / PR gate:** `dart run tool/check_app_hardcoded_ui_strings.dart` (see `SPEC/program/localization.md`) is the authoritative check: AST-based, includes multiline `Text` / `Tooltip` / input decoration / `Semantics` / `SnackBarAction` string slots listed there, and aligns suppressions with `// ignore: avoid_hardcoded_strings_in_widgets`.
- **IDE:** `hardcoded_strings_lint` remains configured for editor feedback; do not rely on it alone as the merge gate.
- Do not use broad suppressions such as `ignore_for_file` for hardcoded-string lint in UI files.

## Allowed literal exceptions (narrow)
- Non-user-visible technical identifiers are allowed (e.g. route IDs, analytics/event keys, protocol/message keys).
- Asset/path/config literals are allowed where the string is not user-facing copy.
- Short symbol tokens are allowed where localization does not apply (for example punctuation-only or operator-like tokens).
- Localized strings that are user-visible copy are not exempt solely because they appear in debug, widgetbook, or dev-facing screens under `app/lib/**`.

## Acceptance criteria
- **AC1:** Any visible UI string in `app/lib/**` is sourced from `AppLocalizations`.
- **AC2:** Parameterized/dynamic UI copy uses `AppLocalizations` parameters (no in-widget interpolation for user-visible strings).
- **AC3:** Tooltips, dialogs, and screen titles are localized.

