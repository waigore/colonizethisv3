# Quick Battle Result Dialog

**SPEC/ui** — Modal dialog that presents the outcome of a Quick Battle. Game model: [quick-battle.md](../game/quick-battle.md). Resolver: [quick-battle-resolution.md](../program/quick-battle-resolution.md). Dialog wiring: [app-ui-wiring.md](../program/app-ui-wiring.md). Sibling: [combat-mode-choice-dialog.md](combat-mode-choice-dialog.md).

---

## Widget contract

`QuickBattleResultDialog` is a presentational `StatelessWidget` (`app/lib/features/game/combat/quick_battle_result_dialog.dart`) wrapped in a `CtDialogShell`.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `result` | `QuickBattleResult` | yes | Output of `resolveQuickBattle` (winner, casualties, `provinceFlips`, etc.). |
| `attackerName` | `String` | no (default `'Attacker'`) | Display name of the attacker; used in winner text and casualty rows. |
| `defenderName` | `String` | no (default `'Defender'`) | Display name of the defender. |

The widget owns no internal state. It pops itself via `Navigator.of(context).pop()` when the user taps OK.

---

## Trigger conditions

- The dialog is opened via `OpenDialogEvent(quickBattleResultDialogId, params)` where `quickBattleResultDialogId == 'quick_battle_result'` (declared in `app/lib/core/services/app_event_handler_scope.dart`). The builder for this id is registered in `app/lib/core/services/app_event_handler_scope_dialog_builders.dart` and constructs the dialog from the event `params`.
- Required params:
  - `result: QuickBattleResult` — when missing, the builder renders `SizedBox.shrink()` (no dialog content).
  - `attackerName: String?` — defaults to `'Attacker'` when absent.
  - `defenderName: String?` — defaults to `'Defender'` when absent.
- The dialog is typically opened by the combat phase orchestrator after [quick-battle-screen.md](quick-battle-screen.md) calls its `onComplete`, or after a headless / observer Quick Battle completes.

---

## Layout / wireframe

```text
+------------------------------------------------+
| CtDialogShell                                  |
| +--------------------------------------------+ |
| | <Winner text>                (titleMedium) | |
| |                                            | |
| | (Optional) Province captured!  (bold)      | |
| |                                            | |
| | <Attacker> casualties: <attackerCount>     | |
| | <Defender> casualties: <defenderCount>     | |
| |                                            | |
| |                                    [ OK ]  | |
| +--------------------------------------------+ |
+------------------------------------------------+
```

- Outer container: `CtDialogShell`.
- Inner column: `Column(mainAxisSize: min, crossAxisAlignment: start)`.
- Winner text uses `Theme.of(context).textTheme.titleMedium` and is built from `appL10n(context).quickBattle_battleResult(<winnerString>)`, where `<winnerString>` is one of:
  - `quickBattle_attackerWins(attackerName)` — when `result.winner == QuickBattleWinner.attacker`.
  - `quickBattle_defenderHolds(defenderName)` — when `result.winner == QuickBattleWinner.defender`.
  - `quickBattle_mutualExhaustion` — when `result.winner == QuickBattleWinner.mutualExhaustion`.
- 8 dp gap, then conditionally render `quickBattle_provinceCaptured` (`fontWeight: bold`) only when `result.provinceFlips == true`.
- 8 dp gap, then two casualty rows:
  - `appL10n(context).quickBattle_casualties(attackerName, result.attackerCasualties.length)`.
  - `appL10n(context).quickBattle_casualties(defenderName, result.defenderCasualties.length)`.
- 16 dp gap, then `Align(alignment: centerRight)` containing a single `CtNinePatchButton` labeled `appL10n(context).quickBattle_ok`.

---

## States and variants

| Outcome | Trigger | Render |
|---------|---------|--------|
| Attacker wins | `result.winner == QuickBattleWinner.attacker` | Winner text from `quickBattle_attackerWins(attackerName)`. Province-capture line shown only when `result.provinceFlips == true`. |
| Defender holds | `result.winner == QuickBattleWinner.defender` | Winner text from `quickBattle_defenderHolds(defenderName)`. Province-capture line is suppressed (defender holds implies no flip). |
| Mutual exhaustion | `result.winner == QuickBattleWinner.mutualExhaustion` | Winner text from `quickBattle_mutualExhaustion`. Province-capture line is suppressed. |
| Province flip | `result.provinceFlips == true` | Bold `quickBattle_provinceCaptured` line rendered above casualty counts. |
| No flip | `result.provinceFlips == false` | Province-capture line is omitted from the tree. |
| Empty casualties | Either side's `casualties.length == 0` | Casualty row still shown with count `0`. |

The dialog is modal; it does not auto-dismiss.

---

## Navigation

- **Entry:** `OpenDialogEvent(quickBattleResultDialogId, params)` from the combat phase orchestrator.
- **Exit on OK tap:** `Navigator.of(context).pop()`. The dialog does not emit any `AppEvent`; downstream consumers track battle outcome through the resolver result that was already applied to `WorldState`, not through the OK tap.
- **Hardware back / dismiss:** Standard modal route dismissal pops the dialog without applying any side effects (the resolver result was applied upstream).

---

## Components

- `CtDialogShell` (`app/lib/widgets/ct_dialog_shell.dart`).
- `CtNinePatchButton` (`app/lib/widgets/ct_nine_patch_button.dart`).
- Localized strings via `appL10n(context).quickBattle_*`.
- No Material buttons.

---

## Acceptance Criteria (Given–When–Then)

- Given the dialog is opened with `result.winner == QuickBattleWinner.attacker`, `result.provinceFlips == true`, `attackerName: 'Castile'`, `defenderName: 'England'`,
  When the UI layer renders the dialog,
  Then the title text is `quickBattle_battleResult(quickBattle_attackerWins('Castile'))`, a bold `quickBattle_provinceCaptured` line is rendered, and two casualty rows are rendered using `quickBattle_casualties('Castile', ...)` and `quickBattle_casualties('England', ...)`.

- Given the dialog is opened with `result.winner == QuickBattleWinner.defender` and `result.provinceFlips == false`,
  When the UI layer renders the dialog,
  Then the title text is `quickBattle_battleResult(quickBattle_defenderHolds(<defenderName>))` and no `quickBattle_provinceCaptured` line is in the widget tree.

- Given the dialog is opened with `result.winner == QuickBattleWinner.mutualExhaustion`,
  When the UI layer renders the dialog,
  Then the title text equals `quickBattle_battleResult(quickBattle_mutualExhaustion)`, no `quickBattle_provinceCaptured` line is rendered, and the casualty rows are still present.

- Given the dialog is mounted on a navigator,
  When the user taps the OK `CtNinePatchButton`,
  Then `Navigator.of(context).pop()` is called exactly once and the dialog emits no `AppEvent`.

- Given the dialog builder receives event params with `result == null`,
  When the dialog id `quick_battle_result` is dispatched through `OpenDialogEvent`,
  Then the builder returns `SizedBox.shrink()` (per `app_event_handler_scope_dialog_builders.dart`) and no Quick Battle dialog appears on screen.

- Given the dialog is opened with `attackerName` and `defenderName` omitted,
  When the UI layer renders the dialog,
  Then the casualty rows interpolate the literal strings `Attacker` and `Defender` (via the `String` defaults on the widget contract).

- Given the dialog is mounted,
  When the UI layer renders the widget tree,
  Then there is exactly one `CtDialogShell`, zero Material `ElevatedButton`, `TextButton`, or `OutlinedButton`, and exactly one `CtNinePatchButton` labeled with `quickBattle_ok`.

---

## Widgetbook

Catalog directory: `Quick Battle Result Dialog` (registered in `app/lib/widgetbook/catalog.dart`). At least one default use case constructs a `QuickBattleResultDialog` with a sample `QuickBattleResult` (attacker wins, `provinceFlips: true`, two attacker casualty ids, one defender casualty id). Additional use cases for defender hold and mutual exhaustion are encouraged.
