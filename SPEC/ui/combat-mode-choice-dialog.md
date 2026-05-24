# Combat Mode Choice Dialog

**SPEC/ui** — Modal dialog that lets the player pick between Auto-Resolve and Quick Battle for an upcoming combat. Game model: [quick-battle.md](../game/quick-battle.md), [siege-mechanics.md](../game/siege-mechanics.md). Resolver: [quick-battle-resolution.md](../program/quick-battle-resolution.md). Dialog wiring: [app-ui-wiring.md](../program/app-ui-wiring.md). Follow-up screen: [quick-battle-screen.md](quick-battle-screen.md).

---

## Widget contract

`CombatModeChoiceDialog` is a presentational `StatelessWidget` (`app/lib/features/game/combat/combat_mode_choice_dialog.dart`) wrapped in a `CtDialogShell`.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `bus` | `AppEventBus` | yes | Bus used to emit `CombatModeChosenEvent(CombatMode)` once the player picks a mode. |
| `provinceName` | `String` | yes | Display name of the contested province; rendered in the dialog title. May be empty (`''`) if upstream did not resolve a name; in that case the title shows the localized template with no name interpolated. |
| `isCapitalSiege` | `bool` | yes | When `true`, the dialog forces Quick Battle as the only option (auto-resolve is hidden); when `false`, both options are offered. |

The widget owns no internal state. It pops itself via `Navigator.of(context).pop()` once the user picks a mode.

---

## Trigger conditions

- The dialog is opened via `OpenDialogEvent(combatModeChoiceDialogId, params)` where `combatModeChoiceDialogId == 'combat_mode_choice'` (declared in `app/lib/core/services/app_event_handler_scope.dart`). The builder for this id is registered in `app/lib/core/services/app_event_handler_scope_dialog_builders.dart` and constructs the dialog with `provinceName` and `isCapitalSiege` from the event `params`.
- Required params:
  - `provinceName: String` — display name of the contested province.
  - `isCapitalSiege: bool` — `true` for capital sieges per [siege-mechanics.md](../game/siege-mechanics.md).
- The dialog must not be opened by direct `showDialog` calls from feature panels; cross-cutting opening is bus-driven per [app-ui-wiring.md](../program/app-ui-wiring.md).

---

## Layout / wireframe

### Regular province (`isCapitalSiege == false`)

```text
+------------------------------------------------+
| CtDialogShell                                  |
| +--------------------------------------------+ |
| | Combat at <provinceName>     (titleMedium) | |
| |                                            | |
| | Choose how to resolve this combat.         | |
| |                                            | |
| |               [ Auto-Resolve ] [ Quick Battle ] | |
| +--------------------------------------------+ |
+------------------------------------------------+
```

### Capital siege (`isCapitalSiege == true`)

```text
+------------------------------------------------+
| CtDialogShell                                  |
| +--------------------------------------------+ |
| | Combat at <provinceName>     (titleMedium) | |
| |                                            | |
| | Capital sieges must be resolved with       | |
| | Quick Battle.                              | |
| |                                            | |
| |                              [ Quick Battle ] | |
| +--------------------------------------------+ |
+------------------------------------------------+
```

- Outer container: `CtDialogShell`.
- Inner column: `Column(mainAxisSize: min, crossAxisAlignment: start)`.
- Title: `Text` styled `Theme.of(context).textTheme.titleMedium`, rendered via `appL10n(context).quickBattle_combatAt(provinceName)`.
- 8 dp gap, then explanatory body text:
  - `appL10n(context).quickBattle_capitalSiegeQuickBattleOnly` when `isCapitalSiege == true`.
  - `appL10n(context).quickBattle_chooseCombatMode` otherwise.
- 16 dp gap, then a `Row(mainAxisAlignment: end)` with action buttons:
  - Regular: `[ Auto-Resolve ]` (`appL10n(context).quickBattle_autoResolve`) followed by 8 dp spacer and `[ Quick Battle ]` (`appL10n(context).quickBattle_quickBattle`).
  - Capital siege: only `[ Quick Battle ]`.
- Buttons are `CtNinePatchButton`s; Material buttons are not permitted.

---

## States and variants

| State | Trigger | Render |
|-------|---------|--------|
| Default (regular) | `isCapitalSiege == false` | Body text from `quickBattle_chooseCombatMode`; both action buttons visible. |
| Capital siege | `isCapitalSiege == true` | Body text from `quickBattle_capitalSiegeQuickBattleOnly`; only Quick Battle button visible. Auto-Resolve button is **omitted from the tree**, not merely disabled. |
| Empty province name | `provinceName == ''` | Title still renders the localized `quickBattle_combatAt` template; the empty string is interpolated as-is. |

The dialog is modal; it does not auto-dismiss without a player choice.

---

## Navigation

- **Entry:** `OpenDialogEvent(combatModeChoiceDialogId, params)` from the combat phase orchestrator.
- **Exit on Auto-Resolve tap (regular only):** Emit `CombatModeChosenEvent(CombatMode.autoResolve)` on the supplied `bus`, then call `Navigator.of(context).pop()`.
- **Exit on Quick Battle tap:** Emit `CombatModeChosenEvent(CombatMode.quickBattle)` on the supplied `bus`, then call `Navigator.of(context).pop()`.
- The dialog does not push or pop other routes. Downstream wiring (e.g., opening [quick-battle-screen.md](quick-battle-screen.md)) is owned by the listener of `CombatModeChosenEvent`, not the dialog.

---

## Components

- `CtDialogShell` (`app/lib/widgets/ct_dialog_shell.dart`).
- `CtNinePatchButton` (`app/lib/widgets/ct_nine_patch_button.dart`).
- Localized strings via `appL10n(context).quickBattle_*`.
- `AppEventBus` (`packages/colonizethis_models`) for emitting `CombatModeChosenEvent`.
- No Material buttons.

---

## Acceptance Criteria (Given–When–Then)

- Given the dialog is opened via `OpenDialogEvent(combatModeChoiceDialogId, {'provinceName': 'Lisbon', 'isCapitalSiege': false})`,
  When the UI layer renders the dialog,
  Then the dialog displays the title `Combat at Lisbon` (localized template), the body text from `quickBattle_chooseCombatMode`, and exactly two `CtNinePatchButton`s labeled with `quickBattle_autoResolve` and `quickBattle_quickBattle`.

- Given the dialog is opened with `isCapitalSiege: true`,
  When the UI layer renders the dialog,
  Then the body text comes from `quickBattle_capitalSiegeQuickBattleOnly`, only one `CtNinePatchButton` labeled with `quickBattle_quickBattle` is present, and no Auto-Resolve button is in the widget tree.

- Given the dialog is mounted with `isCapitalSiege: false` and a bus listener subscribed to `CombatModeChosenEvent`,
  When the user taps the Auto-Resolve button,
  Then the dialog emits exactly one `CombatModeChosenEvent(CombatMode.autoResolve)` on the supplied bus and pops itself off the navigator stack.

- Given the dialog is mounted with `isCapitalSiege: false` and a bus listener subscribed to `CombatModeChosenEvent`,
  When the user taps the Quick Battle button,
  Then the dialog emits exactly one `CombatModeChosenEvent(CombatMode.quickBattle)` on the supplied bus and pops itself off the navigator stack.

- Given the dialog is mounted with `isCapitalSiege: true` and a bus listener subscribed to `CombatModeChosenEvent`,
  When the user taps the Quick Battle button,
  Then the dialog emits exactly one `CombatModeChosenEvent(CombatMode.quickBattle)` and pops itself.

- Given the dialog is mounted,
  When the UI layer renders the widget tree,
  Then there is exactly one `CtDialogShell` and zero Material `ElevatedButton`, `TextButton`, or `OutlinedButton` widgets in the dialog subtree.

---

## Widgetbook

Catalog directory: `Combat Mode Choice Dialog` (registered in `app/lib/widgetbook/catalog.dart`). Required use cases:

1. **Regular province** — `provinceName: 'Lisbon'`, `isCapitalSiege: false`; both buttons visible.
2. **Capital siege** — `provinceName: 'Madrid'`, `isCapitalSiege: true`; Quick Battle only.

Each use case wires a fresh `AppEventBus.create()` so the catalog story does not leak `CombatModeChosenEvent` listeners between runs.
