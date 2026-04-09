# Hardcoded UI String Lint Gap Analysis (app)

## Scope
- Package: `app`
- Paths reviewed: `app/lib/**`
- Primary lint: `hardcoded_strings_lint` (`avoid_hardcoded_strings_in_widgets`)

## Findings
- Running `dart run custom_lint` in `app/` returns no violations.
- Running `flutter analyze` in `app/` also shows no hardcoded-string findings.
- A direct code scan still shows user-visible string literals in multiple UI files (for example combat and panel/dialog widgets).

## Gap classification
- **False-negative gap:** Primary lint currently does not report expected violations for this codebase configuration.
- **Coverage risk:** Relying only on this lint does not satisfy zero-tolerance localization enforcement for `app/lib/**`.

## First migration slice completed
- Combat UI literals were migrated to ARB/AppLocalizations in:
  - `app/lib/features/game/combat/quick_battle_action_selector.dart`
  - `app/lib/features/game/combat/combat_mode_choice_dialog.dart`
  - `app/lib/features/game/combat/quick_battle_result_dialog.dart`
  - `app/lib/features/game/combat/quick_battle_screen.dart`

## Remaining likely-affected slices (from code scan)
- Game widgets/panels and dialogs under:
  - `app/lib/features/game/widgets/**`
  - `app/lib/features/game/dialogue/**`
  - `app/lib/features/game/flame/**` (Flutter-widget overlays/dialog shells)
- App/menu/debug UI under:
  - `app/lib/widgets/**`
  - `app/lib/widgetbook/**`

## Decision for follow-up
- Keep `hardcoded_strings_lint` as primary configured lint (`S2` satisfied).
- Treat this document as evidence for `S4`: custom project checks are required to close lint coverage gaps and enforce zero tolerance.
