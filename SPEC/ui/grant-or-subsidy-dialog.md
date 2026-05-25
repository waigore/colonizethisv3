# Grant or Subsidy Dialog

**Screen ID:** `DIPL20001` — stable; do not reassign.
**SPEC/ui** — Modal that lets the human player set the **amount** for a one-time grant or recurring subsidy toward a target faction, opened from [diplomacy-panel.md](diplomacy-panel.md). Game model: [diplomacy.md](../game/diplomacy.md). Orders contract: [orders.md](../program/orders.md). App wiring and events: [app-ui-wiring.md](../program/app-ui-wiring.md), [app-event-bus.md](../program/app-event-bus.md).

---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `GrantOrSubsidyDialog` | `StatelessWidget` | `game` (`Game`), `humanPlayerId` (`String`), `targetFactionId` (`String`), `isSubsidy` (`bool`), `bus` (`AppEventBus`) | Bus-registered modal (id `grant_or_subsidy`) opened by `DiplomacyPanel` via `OpenDialogEvent('grant_or_subsidy', {targetFactionId, isSubsidy})`. Emits exactly one `GrantOrSubsidySubmittedEvent` on submit. |

Implementation: `app/lib/features/game/widgets/diplomacy_dialogs.dart` (private `_GrantSubsidyAmountBody` holds the stepper state). Wrapped in `CtDialogShell`. The mode (`isSubsidy: true` vs `false`) drives both **title** and **step constant** (`setSubsidyAmountStep` vs `grantAidAmountStep` from `colonizethis_logic`). Dialog id constant: `grantOrSubsidyDialogId`.

---

## Layout / wireframe

```text
+--------------------------------------------------+
| Grant aid     (or)     Set subsidy               |  titleMedium
+--------------------------------------------------+
| Treasury: £8400   Step: £500                     |  bodySmall
|                                                  |
|         [ - ]    £ 1,000    [ + ]                |  amount stepper
|        (Treasury below minimum £500.)            |  shown only when canAdjust=false
|                                                  |
|              [ Cancel ]    [ Submit ]            |
+--------------------------------------------------+
```

- Title: `diplomacy_grantAid` when `isSubsidy == false`; `diplomacy_setSubsidy` when `isSubsidy == true` (`titleMedium`).
- Treasury / step row: `diplomacy_treasuryStep(treasury, step)` (`bodySmall`).
- Amount stepper: `Row` centered, `IconButton` (key `diplo_amount_minus`, icon `Icons.remove`), `Text(diplomacy_currencyAmount(amount))` (`titleLarge`), `IconButton` (key `diplo_amount_plus`, icon `Icons.add`). Both step buttons disable (`onPressed: null`) when `canAdjust == false` (treasury below one step).
- Below-minimum hint: `diplomacy_treasuryBelowMinimum(step)` (`bodySmall`, error color) shown only when `canAdjust == false`.
- Footer: right-aligned `Row` with `CtNinePatchButton` Cancel (`common_cancel`) and `CtNinePatchButton` Submit (`game_callToArms_submit`). Submit enabled only when `_canSubmit` is true.

---

## Trigger conditions

- Opened from `DiplomacyPanel` Grant Aid / Set Subsidy actions via `bus.emit(OpenDialogEvent(grantOrSubsidyDialogId, {targetFactionId, isSubsidy}))`. The panel itself must not call `showDialog` for this dialog (per [app-ui-wiring.md](../program/app-ui-wiring.md) § Banned: `Ref` / `BuildContext` / `Navigator` chains).
- Dialog builder `_buildGrantOrSubsidyDialog` (in `app_event_handler_scope_dialog_builders.dart`) resolves `humanPlayerId` via `resolveShellPanelPlayerId(shellPlayerContextProvider, game)`. Missing `currentGameProvider` yields `SizedBox.shrink()`.
- Initial amount: capped to `_maxAffordable()` (largest multiple of `step` not exceeding treasury) and snapped down to the configured default (`setSubsidyDefaultAmount` or `grantAidDefaultAmount`). When the snapped default is below one step, falls back to `_maxAffordable()`.

---

## States and variants

| State | Condition | UI |
|-------|-----------|-----|
| Grant mode | `isSubsidy == false` | Title `Grant aid`; step `grantAidAmountStep`; default `grantAidDefaultAmount`. |
| Subsidy mode | `isSubsidy == true` | Title `Set subsidy`; step `setSubsidyAmountStep`; default `setSubsidyDefaultAmount`. |
| Treasury OK | `treasury >= step` | Step buttons enabled; below-minimum hint not rendered; Submit enabled when amount lies in `[step, treasury]` and `amount % step == 0`. |
| Below minimum | `treasury < step` (i.e. `_maxAffordable() < step`) | Both step buttons disabled; below-minimum hint rendered in error color; Submit disabled. |
| Mid-range | User taps `+` / `-` | Amount snaps in `step` increments, clamped to `[step, _maxAffordable()]`. |

The dialog **does not** mutate game state. All effects flow through the emitted bus event.

---

## Navigation

| Action | Behavior |
|--------|----------|
| Cancel | `Navigator.of(context).pop()`; no event emitted. |
| Submit (enabled) | `Navigator.of(context).pop()` then `bus.emit(GrantOrSubsidySubmittedEvent(targetFactionId, amount, isSubsidy))`. The dialog pops first to avoid use-after-dispose if the listener triggers a navigation. |
| Submit (disabled) | No-op (`enabled: false` on the `CtNinePatchButton`). |

The `GrantOrSubsidySubmittedEvent` listener (`grant_or_subsidy_listener.dart`) materializes the corresponding diplomatic order; see [orders.md](../program/orders.md) § DiplomaticOrder.

---

## Components

- `CtDialogShell`, `CtNinePatchButton` (see `app/lib/widgets/`).
- Material: `IconButton`, `Icons.remove`, `Icons.add`, `Text`, `Row`, `Column`.
- Logic constants: `setSubsidyAmountStep`, `setSubsidyDefaultAmount`, `grantAidAmountStep`, `grantAidDefaultAmount` (from `colonizethis_logic`).
- Localized keys via `appL10n(context)`: `diplomacy_grantAid`, `diplomacy_setSubsidy`, `diplomacy_treasuryStep`, `diplomacy_currencyAmount`, `diplomacy_treasuryBelowMinimum`, `common_cancel`, `game_callToArms_submit`.

---

## Acceptance Criteria (Given–When–Then)

- Given `isSubsidy == false`, when `GrantOrSubsidyDialog` builds, then the UI layer renders the localized title for `diplomacy_grantAid` and uses `grantAidAmountStep` for stepper increments.

- Given `isSubsidy == true`, when `GrantOrSubsidyDialog` builds, then the UI layer renders the localized title for `diplomacy_setSubsidy` and uses `setSubsidyAmountStep` for stepper increments.

- Given the human player's `treasury >= grantAidAmountStep` and the dialog is in grant mode, when the dialog opens, then the initial `amount` equals `min(grantAidDefaultAmount, _maxAffordable())` snapped down to the nearest multiple of `grantAidAmountStep`, and the Submit `CtNinePatchButton.enabled` is `true`.

- Given the human player's `treasury < grantAidAmountStep`, when the dialog opens in grant mode, then both `IconButton(key: diplo_amount_minus)` and `IconButton(key: diplo_amount_plus)` have `onPressed == null`, the localized `diplomacy_treasuryBelowMinimum(grantAidAmountStep)` text is rendered, and Submit is disabled.

- Given a Submit-enabled state with amount `A`, when the user taps Submit, then `GrantOrSubsidyDialog` is popped first and the UI layer then emits exactly one `GrantOrSubsidySubmittedEvent` on the supplied bus with `targetFactionId == widget.targetFactionId`, `amount == A`, and `isSubsidy == widget.isSubsidy`.

- Given the user taps Cancel, when the gesture completes, then no `GrantOrSubsidySubmittedEvent` is emitted and the dialog is removed from the widget tree.

- Given the user taps `diplo_amount_plus` while `amount == _maxAffordable()`, when the gesture completes, then `amount` does not exceed `_maxAffordable()` (clamped to that ceiling).

---

## Widgetbook

Catalog folder: **Grant or Subsidy Dialog** (registered in `app/lib/widgetbook/catalog.dart`). Use cases:

1. **Grant mode — treasury sufficient:** Minimal `Game` + two players; human treasury 5000; demo opener calls `showDialog` with `isSubsidy: false`. Stepper opens at the snapped default amount.
2. **Subsidy mode — below minimum:** Minimal `Game` + two players; human treasury 100; demo opener calls `showDialog` with `isSubsidy: true`. Both step buttons disabled and below-minimum hint visible.

Automated widget tests: `app/test/diplomacy_dialogs_test.dart` (covers stepper, default amount, submit emit, treasury-below-minimum disable, and Cancel).
