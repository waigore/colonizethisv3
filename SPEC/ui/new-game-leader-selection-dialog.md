# New Game Leader Selection Dialog

**Screen ID:** `DLG10001` — stable; do not reassign.
**SPEC/ui** — Modal that captures the six-slot **nation + leader** lineup plus seed, infinite-mode, and terrain variation for a new game. Implementation: `app/lib/features/shell/new_game_leader_selection_dialog.dart`.
**Widgetbook:** `New Game Leader Selection Dialog` → `app/lib/widgetbook/catalog.dart`. Parent: [game-setup.md](game-setup.md). After confirm: [game-initializing.md](game-initializing.md). App wiring: [app-ui-wiring.md](../program/app-ui-wiring.md), [app-event-bus.md](../program/app-event-bus.md).

**Mockup:** [mockups/DLG10001-leader-selection-dialog.html](mockups/DLG10001-leader-selection-dialog.html)
---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `NewGameLeaderSelectionDialog` | `StatefulWidget` | `baseConfig` (`GameSetupConfig`), `naming` (`ResolvedNamingConfig`), `initialLeaderByGpId` (`Map<String, String>`), `onCancel` (`VoidCallback`), `onConfirmed` (`void Function(List<String>, Map<String, String>, int, bool, double)`) | Bus-registered modal (id `new_game_leader_selection`) opened by the shell New Game button via `OpenDialogEvent(newGameLeaderSelectionDialogId)`. Invokes `onConfirmed` with the chosen lineup and parameters; the scope's builder then kicks off `runNewGameSetupAfterLeaderPick`. |

Implementation: `app/lib/features/shell/new_game_leader_selection_dialog.dart`. Wrapped in `CtDialogShell` (`maxWidth: 480`, `maxHeight: 720`). Six slots are fixed (`_kNumSlots == 6`); slot 0 is the human player (`shell_newGame_playerYou`), slots 1–5 are AI (`shell_newGame_playerAi`). Dialog id constant: `newGameLeaderSelectionDialogId`.

---

## Layout / wireframe

```text
+----------------------------------------------------------+
| Choose nations and leaders                               |  titleMedium
| Choose six great powers and a leader variant for each... |  intro body
|                                                          |
|  Slot 1 (You)                                            |
|  [ ◇ Nation v ]  [ Leader v ]                            |
|  Slot 2                                                  |
|  [ ◇ Nation v ]  [ Leader v ]                            |
|  ...                                                     |
|  Slot 6                                                  |
|  [ ◇ Nation v ]  [ Leader v ]                            |
|                                                          |
|  Game seed                                               |  bodySmall (w600)
|  [ <text>                              ]                 |  TextField (numeric)
|  Helper text                                             |  caption
|                                                          |
|  [ ] Infinite mode (no victory condition)                |  CheckboxListTile
|       Helper text                                        |
|                                                          |
|  Terrain variation: 50%                                  |
|  [ ───────●────────────────────────── ]   slider 0..1    |
|  Helper text                                             |
|                                                          |
|              [ Cancel ]    [ Start ]                     |
+----------------------------------------------------------+
```

- Header: `shell_leaderDialog_title` (`titleMedium`) + `shell_leaderDialog_intro` (14 pt body).
- Slots: six `Column` rows in fixed top-down order; each row hosts a slot label, then a `Row` with two `Expanded(CtDropdown<String>)` — nation on the left, leader on the right.
  - Nation dropdown items show a `GpDefaultMapColorSwatch(greatPowerId: id)` leading icon and `naming.gpById(id)?.countryName` label. Items are filtered per slot: only IDs not already chosen in another slot, plus the slot's own current value.
  - Leader dropdown items are the chosen nation's `leaderVariants` by id, labelled by `LeaderVariant.name`. Selection defaults to `defaultLeaderVariantId`.
- Seed input: `shell_leaderDialog_seedLabel`, numeric `TextField` (controller seeded with `baseConfig.seed.toString()`), helper `shell_leaderDialog_seedHelper`. Submit value parsed by `parseSeedInput`.
- Infinite mode: `CheckboxListTile` with leading control, primary `shell_leaderDialog_infiniteModeLabel`, secondary `shell_leaderDialog_infiniteModeHelper`.
- Terrain variation: label `shell_leaderDialog_terrainVariationLabel(percent)` (percent = `(value * 100).round()`), `CtSlider(min: 0.0, max: 1.0, divisions: 20)`, helper `shell_leaderDialog_terrainVariationHelper`. Default `defaultTerrainVariation == 0.5`.
- Footer: right-aligned `Row` with `CtNinePatchButton` Cancel (`common_cancel`) and `CtNinePatchButton` Start (`common_start`). Start enabled only when `_startEnabled == true`.

---

## Trigger conditions

- Opened by the shell New Game button via `bus.emit(OpenDialogEvent(newGameLeaderSelectionDialogId))`. The shell builder `_buildNewGameLeaderSelectionDialog` (`app_event_handler_scope_dialog_builders.dart`) constructs `baseConfig` from `GameSetupConfig.defaultConfig` (or the E2E template when `kCtE2EEnabled`), seeds `initialLeaderByGpId` from each `GpId`'s `defaultLeaderVariantId`, and wires `onCancel` / `onConfirmed`.
- `selectedGreatPowerIds` from `baseConfig` provides the initial slot ordering when its length equals `_kNumSlots`; otherwise the dialog falls back to `GameSetupConfig.defaultConfig.selectedGreatPowerIds`.
- The dialog **does not** mutate game state; on confirm it invokes `widget.onConfirmed` and pops itself first to avoid use-after-dispose during the setup launch.

---

## States and variants

| State | Condition | UI |
|-------|-----------|-----|
| Initial / default | All six slots populated with their `defaultLeaderVariantId` and the default seed | Start enabled. |
| Slot empty | Any `_orderedGpIdsBySlot[i].isEmpty` | Start disabled (`_startEnabled == false`). |
| Slot duplicate | Same GP id appears in more than one slot | Start disabled (`_startEnabled == false`). |
| Missing leader variants | `_leaderByGpId[id]` not in `gp.leaderVariants` for any slot | Start disabled (`_startEnabled == false`). |
| Slot reassignment | User picks a new nation for slot i | `_orderedGpIdsBySlot[i]` updates; `_leaderByGpId[newId]` resets to `defaultLeaderVariantId`. |
| Leader change | User picks a new leader variant for slot i | `_leaderByGpId[effectiveGpId]` updates only. |
| Infinite toggled | `CheckboxListTile.value` changes | `_infiniteMode` updates; no other side effects. |
| Terrain change | `CtSlider.onChanged` fires | `_terrainVariation` updates and the label percent rerenders. |

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| `OpenDialogEvent(newGameLeaderSelectionDialogId)` | Shell New Game from [`shell-screen.md`](shell-screen.md) | Bus-registered dialog mounts with `baseConfig` and `naming`. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Cancel | Always | `widget.onCancel` | Dialog popped; no `onConfirmed`. |
| Start | All six slots have nations (`_startEnabled`) | `widget.onConfirmed(...)` after `parseSeedInput` | Scope runs `runNewGameSetupAfterLeaderPick`. |
| Start (disabled) | Any slot empty | — | No-op. |

---

## Components

- `CtDialogShell`, `CtDropdown`, `CtNinePatchButton`, `CtSlider`, `GpDefaultMapColorSwatch` (see `app/lib/widgets/`).
- Material: `TextField`, `CheckboxListTile`, `Row`, `Column`, `Padding`, `Text`.
- Helpers: `NewGameLeaderSelectionDialog.parseSeedInput`, `defaultTerrainVariation`.
- Localized keys via `appL10n(context)`: `shell_leaderDialog_title`, `shell_leaderDialog_intro`, `shell_leaderDialog_seedLabel`, `shell_leaderDialog_seedHelper`, `shell_leaderDialog_infiniteModeLabel`, `shell_leaderDialog_infiniteModeHelper`, `shell_leaderDialog_terrainVariationLabel`, `shell_leaderDialog_terrainVariationHelper`, `shell_leaderDialog_selectLeaderHint`, `shell_newGame_playerYou`, `shell_newGame_playerAi`, `shell_newGame_selectNation`, `common_cancel`, `common_start`.

---

## Acceptance Criteria (Given–When–Then)

- Given `baseConfig.selectedGreatPowerIds.length == 6`, when `NewGameLeaderSelectionDialog` builds, then the UI layer renders exactly six slot rows whose initial nation dropdown values equal `baseConfig.selectedGreatPowerIds` in order.

- Given the dialog has just opened with all six slots populated and each slot's `_leaderByGpId[id]` equal to `gp.defaultLeaderVariantId`, when the user looks at the Start button, then the Start `CtNinePatchButton.enabled` is `true`.

- Given the user changes slot 0's nation to a GP currently selected in slot 1, when the change is applied, then both slots end up with distinct nations (the prior slot 1 falls back to the next allowed id) so `_startEnabled` remains computable, and the `_leaderByGpId[newId]` is set to that GP's `defaultLeaderVariantId`.

- Given the dialog has any slot with `_orderedGpIdsBySlot[i].isEmpty`, when the Start button is read, then `CtNinePatchButton.enabled` is `false` and tapping Start does not invoke `widget.onConfirmed`.

- Given the user enters seed text `"abc"` and the dialog is otherwise startable, when the user taps Start, then `NewGameLeaderSelectionDialog.parseSeedInput("abc") == 42` and `widget.onConfirmed` receives `seed == 42`.

- Given the user enters seed text `"  99 "` and the dialog is otherwise startable, when the user taps Start, then `NewGameLeaderSelectionDialog.parseSeedInput("  99 ") == 99` and `widget.onConfirmed` receives `seed == 99`.

- Given the user moves the terrain-variation slider to a normalized value `v`, when `widget.onConfirmed` is invoked, then its `terrainVariation` argument equals `v` (in `[0.0, 1.0]`).

- Given the user toggles the infinite-mode checkbox to `true` and the dialog is otherwise startable, when the user taps Start, then `widget.onConfirmed` receives `infiniteMode == true`.

- Given the user taps Cancel, when the gesture completes, then `widget.onCancel` is invoked exactly once and `widget.onConfirmed` is not invoked.

---

## Widgetbook

Catalog folder: **New Game Leader Selection Dialog** (registered in `app/lib/widgetbook/catalog.dart`). Use cases:

1. **Default — six slots populated:** Opens with `GameSetupConfig.defaultConfig.selectedGreatPowerIds`, default leader variants for each, seed `42`, infinite mode off, terrain variation `0.5`. Start is enabled.
2. **Initial — empty slot regression:** Same wiring as default but with `selectedGreatPowerIds` length 0; demonstrates that Start is disabled until the user picks a nation for every slot.

Automated widget tests: `app/test/new_game_leader_selection_dialog_test.dart` (covers six-slot rendering, default ordering, seed parsing, infinite-mode toggle, terrain-variation slider, Cancel, slot reassignment, and Start payload).
