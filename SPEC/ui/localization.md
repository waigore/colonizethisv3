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
- **No hard-coded UI copy** in widgets: do not write string literals directly into `Text(...)`, `Tooltip.message`, `AlertDialog` titles/actions, etc.
- UI copy must come from `AppLocalizations` methods/getters.
- Dynamic UI copy must be localized using parameterized messages (e.g. `endTurnConfirm(turnNumber)`), not string interpolation in the widget.
- Where the same phrasing appears in multiple places, reuse the same localization key.

## Acceptance criteria
- **AC1:** Any visible UI string in `app/lib/**` is sourced from `AppLocalizations`.
- **AC2:** Parameterized/dynamic UI copy uses `AppLocalizations` parameters (no in-widget interpolation for user-visible strings).
- **AC3:** Tooltips, dialogs, and screen titles are localized.

