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
| Choose nations and leaders                               |  --accent, 0.05em
| ────── ◆ ──────                                          |  CtBrassDivider
| Choose six great powers and a leader variant for each... |  --muted italic intro
|                                                          |
|  Slot 1 (You)                                            |  --accent-dim w600
|  [ ◇ Nation v ]  [ Leader v ]                            |
|  Slot 2                                                  |  --muted regular
|  [ ◇ Nation v ]  [ Leader v ]                            |
|  ...                                                     |
|  Slot 6                                                  |
|  [ ◇ Nation v ]  [ Leader v ]                            |
|                                                          |
|  Game seed                                               |  --accent-dim w600
|  [ <text>                              ]                 |  TextField (numeric, --border idle / --accent focus)
|  Helper text                                             |  --muted helper
|                                                          |
|  [ ] Infinite mode (no victory condition)                |  CheckboxListTile (accent active, border idle)
|       Helper text                                        |  --muted helper
|                                                          |
|  Terrain variation: 50%                                  |  --accent-dim w600
|  [ ───────●────────────────────────── ]   slider 0..1    |
|  Helper text                                             |  --muted helper
|                                                          |
|              [ Cancel ]    [ Start ]                     |
+----------------------------------------------------------+
```

- Dialog chrome wraps in `CtDialogShell` (`maxWidth: 480`, `maxHeight: 720`), painting the dark editorial-monocle frame (#2867 R1) from `EditorialMonoclePalette`.
- Header chrome (#2867 R2 + R21):
  - Title `shell_leaderDialog_title`, keyed `ValueKey<String>('leaderSelectionDialogTitle')`, color `EditorialMonoclePalette.accent`, `letterSpacing == fontSize * 0.05`, `FontWeight.w600`.
  - `CtBrassDivider` keyed `ValueKey<String>('leaderSelectionDialogBrassDivider')` between title and intro.
  - Intro `shell_leaderDialog_intro`, keyed `ValueKey<String>('leaderSelectionDialogIntro')`, color `EditorialMonoclePalette.muted`, `FontStyle.italic`.
- Slots: six `Column` rows in fixed top-down order; each row hosts a slot label, then the slot pickers body. Slot 0 (`shell_newGame_playerYou`) label uses `EditorialMonoclePalette.accentDim` with `FontWeight.w600`; AI slots use `EditorialMonoclePalette.muted` regular weight. The slot pickers body is responsive at the same `kGameSetupNarrowBreakpoint` (500 dp) used by [`CtGameSetup`](game-setup.md):
  - Wide viewport (`MediaQuery.sizeOf(context).width >= kGameSetupNarrowBreakpoint`, 500 dp): one horizontal `Row` with two `Expanded(CtDropdown<String>)` — nation on the left, leader on the right.
  - Narrow viewport (`MediaQuery.sizeOf(context).width < kGameSetupNarrowBreakpoint`, 500 dp): a vertical `Column` with the nation dropdown full width on the first line and the leader dropdown full width on the second line, beneath the slot label. Mirrors [`CtGameSetup`](game-setup.md) § Narrow-viewport slot-row stacking and [mobile-adaptation.md](mobile-adaptation.md) § 4 Game Setup so the dialog and full-screen surface honour the same 500 dp rule.
  - Nation dropdown items show a `GpDefaultMapColorSwatch(greatPowerId: id)` leading icon and `naming.gpById(id)?.countryName` label. Items are filtered per slot: only IDs not already chosen in another slot, plus the slot's own current value.
  - Leader dropdown items are the chosen nation's `leaderVariants` by id, labelled by `LeaderVariant.name`. Selection defaults to `defaultLeaderVariantId`.
- Seed input: `shell_leaderDialog_seedLabel` (`accentDim`, w600), numeric `TextField` (controller seeded with `baseConfig.seed.toString()`; idle/enabled border `EditorialMonoclePalette.border` 1px, focused border `EditorialMonoclePalette.accent` 2px, text color `EditorialMonoclePalette.fg`), helper `shell_leaderDialog_seedHelper` (`EditorialMonoclePalette.muted`). Submit value parsed by `parseSeedInput`.
- Infinite mode: `CheckboxListTile` with leading control; `activeColor: EditorialMonoclePalette.accent`, `checkColor: EditorialMonoclePalette.bgDeep`, idle `side: BorderSide(color: EditorialMonoclePalette.border)`; primary `shell_leaderDialog_infiniteModeLabel` (`EditorialMonoclePalette.fg`), secondary `shell_leaderDialog_infiniteModeHelper` (`EditorialMonoclePalette.muted`).
- Terrain variation: label `shell_leaderDialog_terrainVariationLabel(percent)` (percent = `(value * 100).round()`, color `EditorialMonoclePalette.accentDim` w600), `CtSlider(min: 0.0, max: 1.0, divisions: 20)`, helper `shell_leaderDialog_terrainVariationHelper` (`EditorialMonoclePalette.muted`). Default `defaultTerrainVariation == 0.5`.
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

- `CtDialogShell`, `CtBrassDivider`, `CtDropdown`, `CtNinePatchButton`, `CtSlider`, `GpDefaultMapColorSwatch` (see `app/lib/widgets/`).
- `EditorialMonoclePalette` tokens: `accent`, `accentDim`, `muted`, `fg`, `border`, `bgDeep` (no hex literals in widget source per #2867 R1).
- Material (chrome host only): `TextField`, `CheckboxListTile`, `Row`, `Column`, `Padding`, `Text`.
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

### Narrow-viewport slot pickers stacking

- Given the dialog is open and `MediaQuery.sizeOf(context).width >= kGameSetupNarrowBreakpoint` (500 dp), when any of the six slot rows render, then the slot body mounts a single horizontal `Row` containing both the nation `CtDropdown<String>` and the leader `CtDropdown<String>` side-by-side (each at equal flex), and the slot body does not mount a vertically-stacked `Column` containing both dropdowns.

- Given the dialog is open and `MediaQuery.sizeOf(context).width < kGameSetupNarrowBreakpoint` (500 dp), when any of the six slot rows render, then the slot body mounts a vertical `Column` with the slot label on the first line, the nation `CtDropdown<String>` full width on the second line, and the leader `CtDropdown<String>` full width on the third line, and the slot body does not mount a horizontal `Row` containing both dropdowns side-by-side. This mirrors the narrow-viewport stacking AC for [`CtGameSetup`](game-setup.md) so both Game Setup surfaces honour the same 500 dp rule defined by [mobile-adaptation.md](mobile-adaptation.md) § 4.

### Dark editorial-monocle chrome (#2867 S6)

- Given the dialog is open, when the title `Text` keyed `ValueKey<String>('leaderSelectionDialogTitle')` is inspected, then its `style.color` equals `EditorialMonoclePalette.accent` and `style.letterSpacing` equals `style.fontSize * 0.05` within `1e-9` (so theme text-scale overrides preserve the canonical 0.05em ratio per #2867 R2).

- Given the dialog is open, when the widget tree is scanned, then exactly one `CtBrassDivider` keyed `ValueKey<String>('leaderSelectionDialogBrassDivider')` is rendered and its `top` Y-coordinate is greater than or equal to the title `Text`'s `bottom` Y-coordinate (chrome ordering per #2867 R21).

- Given the dialog is open, when the intro `Text` keyed `ValueKey<String>('leaderSelectionDialogIntro')` is inspected, then its `style.color` equals `EditorialMonoclePalette.muted` and `style.fontStyle` equals `FontStyle.italic`.

- Given the dialog is open under any theme, when the title `Text` is inspected, then its `style.color` is NOT equal to `AppThemes.colonial.textTheme.titleMedium?.color` (regression guard: dropping the EditorialMonoclePalette override would surface the colonial titleMedium color instead of the canonical `--accent` token).

---

## Widgetbook

Catalog folder: **New Game Leader Selection Dialog** (registered in `app/lib/widgetbook/catalog.dart`). Use cases:

1. **Default — six slots populated:** Opens with `GameSetupConfig.defaultConfig.selectedGreatPowerIds`, default leader variants for each, seed `42`, infinite mode off, terrain variation `0.5`. Start is enabled.
2. **Initial — empty slot regression:** Same wiring as default but with `selectedGreatPowerIds` length 0; demonstrates that Start is disabled until the user picks a nation for every slot.

Automated widget tests: `app/test/new_game_leader_selection_dialog_test.dart` (covers six-slot rendering, default ordering, seed parsing, infinite-mode toggle, terrain-variation slider, Cancel, slot reassignment, and Start payload).
