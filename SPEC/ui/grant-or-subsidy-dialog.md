# Grant or Subsidy Dialog

**Screen ID:** `DIPL20001` — stable; do not reassign.
**SPEC/ui** — Modal that lets the human player set the **amount** for a one-time grant or recurring subsidy toward a target faction, opened from [diplomacy-panel.md](diplomacy-panel.md). Game model: [diplomacy.md](../game/diplomacy.md). Orders contract: [orders.md](../program/orders.md). App wiring and events: [app-ui-wiring.md](../program/app-ui-wiring.md), [app-event-bus.md](../program/app-event-bus.md).

**Mockup:** [mockups/DIPL20001-grant-or-subsidy-dialog.html](mockups/DIPL20001-grant-or-subsidy-dialog.html)
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
| Grant aid     (or)     Set subsidy               |  display + --accent + 0.05em
+--------------------------------------------------+
| Treasury: £8400   Step: £500                     |  body + --muted
| ------------------------------------------------ |  1 px --border thin divider
|                                                  |
|         [ − ]    £ 1,000    [ + ]                |  stepper (− muted on --bg-deep / + accent on --surface-lite)
|        (Treasury below minimum £500.)            |  italic --danger, shown only when canAdjust=false
|                                                  |
|              [ Cancel ]    [ Submit ]            |
+--------------------------------------------------+
```

- **Frame:** Wrapped in `CtDialogShell` (2 px `--accent-dim` border, `surface-lite → surface → bg-deep` gradient surface; see [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) § *CtDialogShell*).
- **Title:** `diplomacy_grantAid` when `isSubsidy == false`; `diplomacy_setSubsidy` when `isSubsidy == true`. Rendered with the dark-theme `titleMedium` slot (display font / `Cinzel` / `Iowan Old Style` per [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) § Editorial-monocle palette font stacks), the canonical `EditorialMonoclePalette.accent` color, and `letterSpacing == titleFontSize * 0.05` so the spacing scales with theme text-scale overrides (mirrors the dialog-title convention used by other DLG*/OVL* surfaces under #2867). Stable widget key `Key('grantOrSubsidyDialogTitle')`.
- **Treasury / step row:** `diplomacy_treasuryStep(treasury, step)`, rendered with the dark-theme `bodySmall` slot and `EditorialMonoclePalette.muted` color. Stable widget key `Key('grantOrSubsidyDialogTreasury')`.
- **Thin divider:** A 1 dp solid horizontal divider in `EditorialMonoclePalette.border` separates the treasury row from the stepper, matching [mockups/DIPL20001-grant-or-subsidy-dialog.html](mockups/DIPL20001-grant-or-subsidy-dialog.html) `.divider-thin`. Implemented as a `Container` of fixed `height == 1` whose `decoration.color` resolves to `EditorialMonoclePalette.border`. Stable widget key `Key('grantOrSubsidyDialogThinDivider')`.
- **Amount stepper:** Centered `Row` with three children:
  - **Minus button:** keyed `diplo_amount_minus`. Surface fill `EditorialMonoclePalette.bgDeep`, 1 dp `EditorialMonoclePalette.border` outline, label `−` (U+2212) painted in `EditorialMonoclePalette.muted` using a monospace `TextStyle`. Disabled (`onPressed == null`) when `canAdjust == false`.
  - **Amount:** `Text(diplomacy_currencyAmount(amount))` rendered with the dark-theme `headlineSmall` slot (display font), color `EditorialMonoclePalette.fg`, `letterSpacing == amountFontSize * 0.04`, minimum content width 80 dp. Stable widget key `Key('grantOrSubsidyDialogAmount')`.
  - **Plus button:** keyed `diplo_amount_plus`. Surface fill `EditorialMonoclePalette.surfaceLite`, 1 dp `EditorialMonoclePalette.accentDim` outline, label `+` painted in `EditorialMonoclePalette.accent` using a monospace `TextStyle`. Disabled (`onPressed == null`) when `canAdjust == false`.
- **Below-minimum hint:** `diplomacy_treasuryBelowMinimum(step)` rendered with the dark-theme `bodySmall` slot, color `EditorialMonoclePalette.danger`, `fontStyle == FontStyle.italic`. Shown only when `canAdjust == false`. Stable widget key `Key('grantOrSubsidyDialogWarning')`.
- **Footer:** Right-aligned `Row` with `CtNinePatchButton` Cancel (`common_cancel`) and `CtNinePatchButton` Submit (`game_callToArms_submit`). Submit enabled only when `_canSubmit` is true. (Cancel keeps the standard brass label; Submit follows the catalog `CtNinePatchButton` enabled/disabled treatment.)

All colors resolve from `EditorialMonoclePalette` tokens; no hard-coded hex literals are permitted in the implementation (mirrors the regression guard pattern adopted by other DLG*/OVL* dark-chrome slices under #2867).

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
- `EditorialMonoclePalette` (`app/lib/config/editorial_monocle_palette.dart`) — title/treasury/amount/divider/warning/stepper colors.
- Flutter primitives: `Text`, `Row`, `Column`, `Container`, `InkWell`/`GestureDetector` for the bespoke stepper buttons keyed `diplo_amount_minus` / `diplo_amount_plus` (the dialog no longer uses Material `IconButton` or `Icons.remove` / `Icons.add` — the chrome paints `−` / `+` glyphs per [mockups/DIPL20001-grant-or-subsidy-dialog.html](mockups/DIPL20001-grant-or-subsidy-dialog.html)).
- Logic constants: `setSubsidyAmountStep`, `setSubsidyDefaultAmount`, `grantAidAmountStep`, `grantAidDefaultAmount` (from `colonizethis_logic`).
- Localized keys via `appL10n(context)`: `diplomacy_grantAid`, `diplomacy_setSubsidy`, `diplomacy_treasuryStep`, `diplomacy_currencyAmount`, `diplomacy_treasuryBelowMinimum`, `common_cancel`, `game_callToArms_submit`.

---

## Acceptance Criteria (Given–When–Then)

- Given `isSubsidy == false`, when `GrantOrSubsidyDialog` builds, then the UI layer renders the localized title for `diplomacy_grantAid` and uses `grantAidAmountStep` for stepper increments.

- Given `isSubsidy == true`, when `GrantOrSubsidyDialog` builds, then the UI layer renders the localized title for `diplomacy_setSubsidy` and uses `setSubsidyAmountStep` for stepper increments.

- Given the human player's `treasury >= grantAidAmountStep` and the dialog is in grant mode, when the dialog opens, then the initial `amount` equals `min(grantAidDefaultAmount, _maxAffordable())` snapped down to the nearest multiple of `grantAidAmountStep`, and the Submit `CtNinePatchButton.enabled` is `true`.

- Given the human player's `treasury < grantAidAmountStep`, when the dialog opens in grant mode, then the widgets keyed `diplo_amount_minus` and `diplo_amount_plus` both have `onTap == null` / `enabled == false`, the widget keyed `grantOrSubsidyDialogWarning` renders the localized `diplomacy_treasuryBelowMinimum(grantAidAmountStep)` text, and Submit is disabled.

- Given a Submit-enabled state with amount `A`, when the user taps Submit, then `GrantOrSubsidyDialog` is popped first and the UI layer then emits exactly one `GrantOrSubsidySubmittedEvent` on the supplied bus with `targetFactionId == widget.targetFactionId`, `amount == A`, and `isSubsidy == widget.isSubsidy`.

- Given the user taps Cancel, when the gesture completes, then no `GrantOrSubsidySubmittedEvent` is emitted and the dialog is removed from the widget tree.

- Given the user taps `diplo_amount_plus` while `amount == _maxAffordable()`, when the gesture completes, then `amount` does not exceed `_maxAffordable()` (clamped to that ceiling).

### Dark editorial-monocle chrome (#2863 S6)

- **Title color + letter-spacing:** Given `GrantOrSubsidyDialog` is mounted in either mode, when the widget keyed `grantOrSubsidyDialogTitle` is inspected, then `Text.style.color` resolves to `EditorialMonoclePalette.accent` and `Text.style.letterSpacing` equals `style.fontSize * 0.05` (within 1e-6 dp).

- **Title regression guard (negative):** Given `GrantOrSubsidyDialog` is mounted, when the widget keyed `grantOrSubsidyDialogTitle` is inspected, then `Text.style.color` is **not** the default `textTheme.titleMedium.color` resolved from the ambient `ThemeData` (i.e. the dark chrome override is applied — not the bare theme slot).

- **Treasury color:** Given `GrantOrSubsidyDialog` is mounted, when the widget keyed `grantOrSubsidyDialogTreasury` is inspected, then `Text.style.color` resolves to `EditorialMonoclePalette.muted`.

- **Thin divider:** Given `GrantOrSubsidyDialog` is mounted, when the widget keyed `grantOrSubsidyDialogThinDivider` is inspected, then it is a `Container` whose `constraints` resolve to `height == 1.0` and whose `decoration` paints `EditorialMonoclePalette.border` (regression guard: no `Divider` widget from Material chrome is used).

- **Amount color + letter-spacing:** Given `GrantOrSubsidyDialog` is mounted, when the widget keyed `grantOrSubsidyDialogAmount` is inspected, then `Text.style.color` resolves to `EditorialMonoclePalette.fg` and `Text.style.letterSpacing` equals `style.fontSize * 0.04` (within 1e-6 dp).

- **Warning style:** Given the treasury is below the minimum step (`canAdjust == false`), when the widget keyed `grantOrSubsidyDialogWarning` is inspected, then `Text.style.color` resolves to `EditorialMonoclePalette.danger` and `Text.style.fontStyle` equals `FontStyle.italic`.

- **No Material AlertDialog leak (regression guard):** Given `GrantOrSubsidyDialog` is mounted, when the widget subtree is inspected, then no `AlertDialog`, `ListTile`, or `Card` widget is in the descendant tree (the dialog renders inside `CtDialogShell` only, matching `SPEC/ui/pixel-art-ui-catalog.md` § Material design ban).

### 320 dp viewport pin (#2870 S8/S10)

- **Grant mode @ 320×640 (positive):** Given the viewport width equals `kMinViewportWidth` (320 dp) and the height is at least 640 dp, and the dialog is mounted in grant mode (`isSubsidy: false`) against a two-GP `Game` fixture with the human GP's `treasury == 5 * grantAidAmountStep` (so both stepper buttons are enabled and the below-minimum hint stays unmounted), when the dialog renders inside the running editorial-monocle theme, then `WidgetTester.takeException()` returns `null`, the keyed `grantOrSubsidyDialogTitle` renders the `Grant aid` text, the keyed `grantOrSubsidyDialogTreasury` body row renders, the keyed `grantOrSubsidyDialogThinDivider` divider mounts, the keyed `grantOrSubsidyDialogAmount` label and both keyed stepper buttons (`diplo_amount_minus` / `diplo_amount_plus`) mount inside the centered stepper `Row`, the keyed `grantOrSubsidyDialogWarning` is **absent**, and the trailing right-aligned `Cancel` + `Submit` `CtNinePatchButton` labels render — all within the ~288 dp `CtDialogShell` content column (`maxWidth: 480` clamped by outer `Dialog.insetPadding: 16` × 2) without horizontal overflow.

- **Subsidy mode @ 320×640 (positive):** Given the same viewport and fixture but `isSubsidy: true`, when the dialog renders, then `WidgetTester.takeException()` returns `null`, the title slot flips to `Set subsidy`, the keyed `grantOrSubsidyDialogWarning` is absent (treasury comfortably exceeds the smaller `setSubsidyAmountStep == 100`), and both `Cancel` and `Submit` `CtNinePatchButton` labels render within the ~288 dp content column without horizontal overflow.

- **Below-minimum branch @ 320×640 (positive):** Given the same viewport but the human GP's `treasury == grantAidAmountStep - 1` and the dialog is mounted in grant mode (`isSubsidy: false`), when the dialog renders, then `WidgetTester.takeException()` returns `null`, the keyed `grantOrSubsidyDialogWarning` mounts (the optional `_BelowMinimumWarning` row), and the trailing right-aligned `Cancel` + `Submit` `CtNinePatchButton` labels continue to render within the ~288 dp content column without horizontal overflow.

- **Wide negative control:** Given the viewport is `1024 × 768` dp and the dialog is mounted in grant mode against the same `5 * grantAidAmountStep` fixture, when the dialog renders, then `WidgetTester.takeException()` returns `null` and the title + Cancel + Submit labels render — keeping the 320 dp positive pins meaningful by catching upstream regressions in the host overflow contract.

Pinning test: `app/test/grant_or_subsidy_dialog_320dp_min_viewport_test.dart`. The same contract is summarized in [mobile-adaptation.md](mobile-adaptation.md) § 7 (Minimum-viewport pin).

---

## Widgetbook

Catalog folder: **Grant or Subsidy Dialog** (registered in `app/lib/widgetbook/catalog.dart`). Use cases:

1. **Grant mode — treasury sufficient:** Minimal `Game` + two players; human treasury 5000; demo opener calls `showDialog` with `isSubsidy: false`. Stepper opens at the snapped default amount.
2. **Subsidy mode — below minimum:** Minimal `Game` + two players; human treasury 100; demo opener calls `showDialog` with `isSubsidy: true`. Both step buttons disabled and below-minimum hint visible.

Automated widget tests: `app/test/diplomacy_dialogs_test.dart` (covers stepper, default amount, submit emit, treasury-below-minimum disable, and Cancel); `app/test/grant_or_subsidy_dialog_320dp_min_viewport_test.dart` (320 dp minimum-viewport pin per § 320 dp viewport pin above).
