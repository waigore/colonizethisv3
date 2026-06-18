# New Game Leader Selection Dialog

**Screen ID:** `DLG10001` — stable; do not reassign.
**SPEC/ui** — Modal that captures the six-slot **nation + leader** lineup plus seed, infinite-mode, and terrain variation for a new game. Implementation: `app/lib/features/shell/new_game_leader_selection_dialog.dart`.
**Widgetbook:** `New Game Leader Selection Dialog` → `app/lib/widgetbook/catalog.dart`. After confirm: [game-initializing.md](game-initializing.md). App wiring: [app-ui-wiring.md](../program/app-ui-wiring.md), [app-event-bus.md](../program/app-event-bus.md).

**Mockup:** [mockups/DLG10001-leader-selection-dialog.html](mockups/DLG10001-leader-selection-dialog.html)
---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `NewGameLeaderSelectionDialog` | `StatefulWidget` | `baseConfig` (`GameSetupConfig`), `naming` (`ResolvedNamingConfig`), `initialLeaderByGpId` (`Map<String, String>`), `blessedProfileNames` (`List<String>`), `onCancel` (`VoidCallback`), `onConfirmed` (`void Function(List<String>, Map<String, String>, int, bool, double, Map<String, String?>)`) | Bus-registered modal (id `new_game_leader_selection`) opened by the shell New Game button via `OpenDialogEvent(newGameLeaderSelectionDialogId)`. Invokes `onConfirmed` with the chosen lineup, parameters, and per-AI-slot blessed profile names; the scope's builder then kicks off `runNewGameSetupAfterLeaderPick`. |

Implementation: `app/lib/features/shell/new_game_leader_selection_dialog.dart`. Wrapped in `CtDialogShell` (`maxWidth: 540`, `maxHeight: 720`) matching the authoritative mockup `.dialog-shell{max-width:540px}`. Six slots are fixed (`_kNumSlots == 6`); each slot heading reads `Slot N` (`shell_leaderDialog_slotLabel`); slot 0 is the human player and additionally shows a `YOU` tag (`shell_leaderDialog_slotYouTag`, uppercased via presentation style), slots 1–5 are AI. Dialog id constant: `newGameLeaderSelectionDialogId`.

**Tuned AI profile selector (Refs #3444):** each AI slot (1–5) renders a third `CtDropdown<String>` — the **AI Profile** picker (hint `shell_leaderDialog_aiProfileLabel`) — beneath/beside its nation + leader pickers. Its items are the **Normal** sentinel (`normalProfileChoiceId == ''`, labelled `shell_leaderDialog_aiProfileNormal`) followed by each blessed profile name from `blessedProfileNames` (sorted, supplied from the asset manifest). The human slot (0) renders **no** profile picker (`profileDropdown == null`). Selection is held in `_profileBySlot` (`Map<int, String?>`, slot index → profile name; `Normal`/empty removes the entry). On confirm, `_aiProfileByGpIdForCallback` maps slots 1–5 to `Map<String, String?>` keyed by each slot's Great Power id (only non-empty selections are emitted) and passes it as the sixth `onConfirmed` argument. `blessedProfileNames` empty → every AI slot still shows the picker but its only item is **Normal**.

---

## Layout / wireframe

```text
+----------------------------------------------------------+
|              Choose nations and leaders                  |  --accent, centered, 0.05em
|   Choose six great powers and a leader variant for each  |  --muted italic, centered
|                    ────── ◆ ──────                       |  CtBrassDivider (below header text)
|                                                          |
| ┌──────────────────────────────────────────────────────┐|  slot-row chrome: surface→bg-deep
| │ Slot 1  YOU                                            ││  gradient, accent-dim top/bottom border,
| │ [ ◇ Nation v ]  [ Leader v ]                           ││  8/10 dp padding; 6 dp inter-row gap
| └──────────────────────────────────────────────────────┘|
| ┌──────────────────────────────────────────────────────┐|
| │ Slot 2                                                 ││  --muted regular
| │ [ ◇ Nation v ]  [ Leader v ]                           ││
| │ AI Profile: [ Normal v ]                               ││  inline label + dropdown (AI slots 1-5)
| └──────────────────────────────────────────────────────┘|
|  ...                                                     |
|                                                          |
|  Game seed                                               |  --fg w600
|  [ <text>                              ]                 |  TextField (numeric, --border idle / --accent focus)
|  Enter 0 for a random seed                               |  --muted helper
|                                                          |
|  [=O] Infinite mode (no victory condition)               |  CtToggleSwitch + label
|       The game will continue indefinitely                |  --muted helper
|                                                          |
|  Terrain variation:                        50%           |  static label + live mono percent
|  [ ───────●────────────────────────── ]   slider 0..1    |
|  0% flat — 100% extreme                                  |  --muted helper
|                                                          |
|              [ Cancel ]    [ Start ]                     |
+----------------------------------------------------------+
```

- Dialog chrome wraps in `CtDialogShell` (`maxWidth: 540`, `maxHeight: 720`), painting the dark editorial-monocle frame (#2867 R1) from `EditorialMonoclePalette`. `maxWidth` matches the mockup `.dialog-shell{max-width:540px}`.
- Header chrome (#2867 R2 + R21), centered (`CrossAxisAlignment.center`, `textAlign: TextAlign.center`), in mockup order title → intro → divider:
  - Title `shell_leaderDialog_title`, keyed `ValueKey<String>('leaderSelectionDialogTitle')`, color `EditorialMonoclePalette.accent`, `letterSpacing == fontSize * 0.05`, `FontWeight.w600`.
  - Intro `shell_leaderDialog_intro`, keyed `ValueKey<String>('leaderSelectionDialogIntro')`, color `EditorialMonoclePalette.muted`, `FontStyle.italic`.
  - `CtBrassDivider` keyed `ValueKey<String>('leaderSelectionDialogBrassDivider')` beneath the title + intro.
- Slots: six rows in fixed top-down order separated by a 6 dp gap (`.slots-list{gap:6px}`). Each row is a `DecoratedBox` with the mockup `.slot-row` chrome — a vertical `surface → bgDeep` gradient and 1 dp `EditorialMonoclePalette.accentDim` top + bottom borders, padded 8 dp vertical / 10 dp horizontal — hosting the slot heading then the slot pickers body. The heading reads `Slot N` (`shell_leaderDialog_slotLabel`); slot 0 also renders a `YOU` tag (`shell_leaderDialog_slotYouTag`, uppercased via style) and uses `EditorialMonoclePalette.accentDim` `FontWeight.w600`; AI slots use `EditorialMonoclePalette.muted` regular weight. The slot pickers body is responsive at `kLeaderSelectionNarrowBreakpoint` (540 dp):
  - Wide viewport (`MediaQuery.sizeOf(context).width >= kLeaderSelectionNarrowBreakpoint`, 540 dp): one horizontal `Row` with two `Expanded(CtDropdown<String>)` — nation on the left, leader on the right.
  - Narrow viewport (`MediaQuery.sizeOf(context).width < kLeaderSelectionNarrowBreakpoint`, 540 dp): a vertical `Column` with the nation dropdown full width on the first line and the leader dropdown full width on the second line, beneath the slot label. See [mobile-adaptation.md](mobile-adaptation.md) § 4 New game leader selection.
  - Nation dropdown items show a `GpDefaultMapColorSwatch(greatPowerId: id)` leading icon and `naming.gpById(id)?.countryName` label. Items are filtered per slot: only IDs not already chosen in another slot, plus the slot's own current value.
  - Leader dropdown items are the chosen nation's `leaderVariants` by id, labelled by `LeaderVariant.name`. Selection defaults to `defaultLeaderVariantId`.
  - AI Profile line (AI slots 1–5 only; `_SlotPickersBody.profileLine != null`) renders full-width on its own line **below** the nation/leader row in both viewports as a `Row` of an inline `AI Profile:` label (`shell_leaderDialog_aiProfileInlineLabel`, mockup `.profile-line`) and an `Expanded(CtDropdown<String>)`. Dropdown items are the `Normal` sentinel (`normalProfileChoiceId == ''`, labelled `shell_leaderDialog_aiProfileNormal`) plus each `blessedProfileNames` entry; hint `shell_leaderDialog_aiProfileLabel`. The human slot (0) passes `profileLine == null`, so its body has no profile line.
- Seed input: `shell_leaderDialog_seedLabel` ("Game seed", `accentDim`, w600), numeric `TextField` (controller seeded with `baseConfig.seed.toString()`; idle/enabled border `EditorialMonoclePalette.border` 1px, focused border `EditorialMonoclePalette.accent` 2px, text color `EditorialMonoclePalette.fg`), helper `shell_leaderDialog_seedHelper` ("Enter 0 for a random seed", `EditorialMonoclePalette.muted`). Submit value parsed by `parseSeedInput`.
- Infinite mode: `CtToggleSwitch` (no Material `CheckboxListTile`) beside the label `shell_leaderDialog_infiniteModeLabel` ("Infinite mode (no victory condition)", `EditorialMonoclePalette.fg` w600), with helper `shell_leaderDialog_infiniteModeHelper` ("The game will continue indefinitely", `EditorialMonoclePalette.muted`) indented beneath, per mockup `.toggle-row` / `.toggle-hint`.
- Terrain variation: a `Row` with the static label `shell_leaderDialog_terrainVariationLabel` ("Terrain variation:", `accentDim` w600) and the live mono percent value `shell_leaderDialog_terrainVariationValue(percent)` (percent = `(value * 100).round()`, keyed `ValueKey<String>('leaderSelectionDialogTerrainVariationValue')`, `accentDim`, tabular figures); the label flexes so it wraps rather than overflowing at 320 dp. Below: `CtSlider(min: 0.0, max: 1.0, divisions: 20)` and helper `shell_leaderDialog_terrainVariationHelper` ("0% flat — 100% extreme", `EditorialMonoclePalette.muted`). Default `defaultTerrainVariation == 0.5`.
- Footer: right-aligned `Row` with `CtNinePatchButton` Cancel (`common_cancel`) and `CtNinePatchButton` Start (`common_start`). Start enabled only when `_startEnabled == true`.
- Duplicate slot validation feedback (#2867 R19): when the slot's currently-selected Great Power id (`_orderedGpIdsBySlot[slotIndex]`) also appears in at least one other slot's ordered list, the nation `CtDropdown<String>` is wrapped in a `DecoratedBox` keyed `ValueKey<String>('newGameLeaderDialogSlotDuplicateBorder_<slotIndex>')` whose `Border.all` resolves to `EditorialMonoclePalette.danger` at `NewGameLeaderSelectionDialog.duplicateSlotBorderWidth` (1 dp). Non-duplicate slots render the nation dropdown directly without that wrapper.

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
| Slot duplicate | Same GP id appears in more than one slot | Start disabled (`_startEnabled == false`). Every duplicate slot's nation `CtDropdown<String>` is wrapped in a `DecoratedBox` keyed `ValueKey<String>('newGameLeaderDialogSlotDuplicateBorder_<slotIndex>')` that paints a `EditorialMonoclePalette.danger` `Border.all` at `NewGameLeaderSelectionDialog.duplicateSlotBorderWidth` (1 dp). |
| Missing leader variants | `_leaderByGpId[id]` not in `gp.leaderVariants` for any slot | Start disabled (`_startEnabled == false`). |
| Slot reassignment | User picks a new nation for slot i | `_orderedGpIdsBySlot[i]` updates; `_leaderByGpId[newId]` resets to `defaultLeaderVariantId`. |
| Leader change | User picks a new leader variant for slot i | `_leaderByGpId[effectiveGpId]` updates only. |
| Infinite toggled | `CtToggleSwitch.value` changes | `_infiniteMode` updates; no other side effects. |
| Terrain change | `CtSlider.onChanged` fires | `_terrainVariation` updates and the mono percent value rerenders. |
| AI slot (1–5) | `slotIndex > 0` | Slot body mounts the AI Profile line (`profileLine != null`): inline `AI Profile:` label + `CtDropdown<String>` with `Normal` + every `blessedProfileNames` entry. |
| Human slot (0) | `slotIndex == 0` | Slot body mounts **no** AI Profile line (`profileLine == null`); only nation + leader pickers render. |
| No blessed profiles | `blessedProfileNames.isEmpty` | Each AI slot's profile dropdown still renders but offers only the `Normal` item. |
| Profile chosen | User picks a blessed name for slot i | `_profileBySlot[i]` set to that name; emitted on confirm as `aiProfileByGpId[gpId]`. |
| Profile reset to Normal | User picks `Normal` (empty value) for slot i | `_profileBySlot.remove(i)`; that slot's gpId is absent from the emitted `aiProfileByGpId`. |

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
| Start | All six slots have nations (`_startEnabled`) | `widget.onConfirmed(..., aiProfileByGpId)` after `parseSeedInput` | Scope runs `runNewGameSetupAfterLeaderPick`; `aiProfileByGpId` (slots 1–5, non-empty selections only) forwarded into `GameSetupConfig.aiProfileByGpId`. |
| Start (disabled) | Any slot empty | — | No-op. |
| AI Profile dropdown (slots 1–5) | Always (when shown) | `setState` updating `_profileBySlot[slotIndex]` | Non-empty value stored; `Normal`/empty removes the slot entry. No game state mutated until Start. |

---

## Components

- `CtDialogShell`, `CtBrassDivider`, `CtDropdown`, `CtNinePatchButton`, `CtSlider`, `CtToggleSwitch`, `GpDefaultMapColorSwatch` (see `app/lib/widgets/`).
- `EditorialMonoclePalette` tokens: `accent`, `accentDim`, `muted`, `fg`, `border`, `bgDeep`, `surface` (no hex literals in widget source per #2867 R1).
- Material (chrome host only): `TextField`, `DecoratedBox`, `Row`, `Column`, `Flexible`, `Padding`, `Text` (the infinite-mode control is the custom `CtToggleSwitch`, not Material `CheckboxListTile`).
- Helpers: `NewGameLeaderSelectionDialog.parseSeedInput`, `defaultTerrainVariation`.
- Localized keys via `appL10n(context)`: `shell_leaderDialog_title`, `shell_leaderDialog_intro`, `shell_leaderDialog_slotLabel`, `shell_leaderDialog_slotYouTag`, `shell_leaderDialog_seedLabel`, `shell_leaderDialog_seedHelper`, `shell_leaderDialog_infiniteModeLabel`, `shell_leaderDialog_infiniteModeHelper`, `shell_leaderDialog_terrainVariationLabel`, `shell_leaderDialog_terrainVariationValue`, `shell_leaderDialog_terrainVariationHelper`, `shell_leaderDialog_selectLeaderHint`, `shell_leaderDialog_aiProfileInlineLabel`, `shell_leaderDialog_aiProfileLabel`, `shell_leaderDialog_aiProfileNormal`, `shell_newGame_selectNation`, `common_cancel`, `common_start`.

---

## Acceptance Criteria (Given–When–Then)

- Given `baseConfig.selectedGreatPowerIds.length == 6`, when `NewGameLeaderSelectionDialog` builds, then the UI layer renders exactly six slot rows whose initial nation dropdown values equal `baseConfig.selectedGreatPowerIds` in order.

- Given the dialog has just opened with all six slots populated and each slot's `_leaderByGpId[id]` equal to `gp.defaultLeaderVariantId`, when the user looks at the Start button, then the Start `CtNinePatchButton.enabled` is `true`.

- Given the user changes slot 0's nation to a GP currently selected in slot 1, when the change is applied, then both slots end up with distinct nations (the prior slot 1 falls back to the next allowed id) so `_startEnabled` remains computable, and the `_leaderByGpId[newId]` is set to that GP's `defaultLeaderVariantId`.

- Given the dialog has any slot with `_orderedGpIdsBySlot[i].isEmpty`, when the Start button is read, then `CtNinePatchButton.enabled` is `false` and tapping Start does not invoke `widget.onConfirmed`.

- Given the user enters seed text `"abc"` and the dialog is otherwise startable, when the user taps Start, then `NewGameLeaderSelectionDialog.parseSeedInput("abc") == 42` and `widget.onConfirmed` receives `seed == 42`.

- Given the user enters seed text `"  99 "` and the dialog is otherwise startable, when the user taps Start, then `NewGameLeaderSelectionDialog.parseSeedInput("  99 ") == 99` and `widget.onConfirmed` receives `seed == 99`.

- Given the user moves the terrain-variation slider to a normalized value `v`, when `widget.onConfirmed` is invoked, then its `terrainVariation` argument equals `v` (in `[0.0, 1.0]`).

- Given the user toggles the infinite-mode `CtToggleSwitch` to `true` and the dialog is otherwise startable, when the user taps Start, then `widget.onConfirmed` receives `infiniteMode == true`.

- Given the user taps Cancel, when the gesture completes, then `widget.onCancel` is invoked exactly once and `widget.onConfirmed` is not invoked.

### Tuned AI profile selector (Refs #3444)

- Given the dialog is open with `blessedProfileNames == ['aggressive_v2']` and a viewport tall enough to render all six slots, when the slot rows build, then each AI slot (1–5) mounts an AI Profile `CtDropdown<String>` whose items are exactly `['', 'aggressive_v2']` (the `Normal` sentinel first), and slot 0 mounts no AI Profile dropdown.

- Given the dialog is open with `blessedProfileNames == ['aggressive_v2']`, when the user has not changed any profile dropdown and taps Start, then `widget.onConfirmed` receives an `aiProfileByGpId` argument that is empty (no AI slot defaults to a blessed profile).

- Given the dialog is open with `blessedProfileNames == ['aggressive_v2']`, when the user selects `aggressive_v2` in one AI slot's profile dropdown and taps Start, then `widget.onConfirmed` receives an `aiProfileByGpId` whose values contain `'aggressive_v2'` keyed by that slot's Great Power id.

- Given an AI slot's profile dropdown currently holds a blessed name, when the user re-selects the `Normal` option (empty value `normalProfileChoiceId`) and taps Start, then that slot's Great Power id is absent from the emitted `aiProfileByGpId` (the entry is removed, not emitted as `null`).

### Narrow-viewport slot pickers stacking

- Given the dialog is open and `MediaQuery.sizeOf(context).width >= kLeaderSelectionNarrowBreakpoint` (540 dp), when any of the six slot rows render, then the slot body mounts a single horizontal `Row` containing both the nation `CtDropdown<String>` and the leader `CtDropdown<String>` side-by-side (each at equal flex), and the slot body does not mount a vertically-stacked `Column` containing both dropdowns.

- Given the dialog is open and `MediaQuery.sizeOf(context).width < kLeaderSelectionNarrowBreakpoint` (540 dp), when any of the six slot rows render, then the slot body mounts a vertical `Column` with the slot label on the first line, the nation `CtDropdown<String>` full width on the second line, and the leader `CtDropdown<String>` full width on the third line, and the slot body does not mount a horizontal `Row` containing both dropdowns side-by-side (per [mobile-adaptation.md](mobile-adaptation.md) § 4).

- Given the viewport size is exactly `Size(kMinViewportWidth, 640)` (320 × 640 dp) and the dialog is rendered with `baseConfig = GameSetupConfig.defaultConfig`, `naming = defaultNamingConfig`, and the default per-GP leader-variant map, when the dialog builds, then `WidgetTester.takeException()` returns `null` (no `RenderFlex` overflow exception surfaces through the framework), every one of the six slot rows mounts the stacked column body keyed `ValueKey<String>('newGameLeaderDialogSlotPickersColumn')` (so `find.byKey(...).evaluate().length == 6`), no slot mounts the wide row body keyed `ValueKey<String>('newGameLeaderDialogSlotPickersRow')`, the dialog title `Choose nations and leaders`, the six slot headings `Slot 1` through `Slot 6` (slot 1 additionally showing the `YOU` tag), and the trailing `Cancel` and `Start` `CtNinePatchButton` labels all render within the ~268 dp `CtDialogShell` content column, and every rendered `CtNinePatchButton` reports a rendered height `>= kMinTouchTargetSize` (44 dp) per [mobile-adaptation.md](mobile-adaptation.md) § 1. Pinned by `app/test/mobile_320dp_min_viewport_test.dart` group `SPEC/ui/mobile-adaptation.md § 7 — NewGameLeaderSelectionDialog @ 320 dp` (Refs #2870 S7/S8/S10).

### Duplicate slot validation feedback (#2867 R19)

- Given the dialog is open and at least two slots share the same Great Power id (`_orderedGpIdsBySlot[i] == _orderedGpIdsBySlot[j]` for some `i != j`, ignoring empty ids), when each affected slot row builds, then the nation `CtDropdown<String>` of every duplicate slot is wrapped in a `DecoratedBox` keyed `ValueKey<String>('newGameLeaderDialogSlotDuplicateBorder_<slotIndex>')` painting a 1 dp `EditorialMonoclePalette.danger` `Border.all`, and the Start `CtNinePatchButton.enabled` remains `false` (mirrors `_startEnabled` rejecting duplicates).

- Given the dialog is open and every populated slot holds a unique Great Power id, when the slot rows build, then no `DecoratedBox` keyed with the `'newGameLeaderDialogSlotDuplicateBorder_'` prefix is mounted under any slot row (negative AC: the danger border is only painted for duplicates).

- Given the dialog opens with `baseConfig.selectedGreatPowerIds` containing a duplicate Great Power id, when the user changes the duplicate slot's nation to a previously unused id via the nation dropdown, then the danger-border wrapper for that slot unmounts on the next build (no `ValueKey<String>('newGameLeaderDialogSlotDuplicateBorder_<slotIndex>')` remains for the now-unique slot) and the Start `CtNinePatchButton.enabled` flips to `true` once all six slots hold unique non-empty ids.

### Dark editorial-monocle chrome (#2867 S6)

- Given the dialog is open, when the title `Text` keyed `ValueKey<String>('leaderSelectionDialogTitle')` is inspected, then its `style.color` equals `EditorialMonoclePalette.accent` and `style.letterSpacing` equals `style.fontSize * 0.05` within `1e-9` (so theme text-scale overrides preserve the canonical 0.05em ratio per #2867 R2).

- Given the dialog is open, when the widget tree is scanned, then exactly one `CtBrassDivider` keyed `ValueKey<String>('leaderSelectionDialogBrassDivider')` is rendered and its `top` Y-coordinate is greater than or equal to the title `Text`'s `bottom` Y-coordinate (chrome ordering per #2867 R21).

- Given the dialog is open, when the intro `Text` keyed `ValueKey<String>('leaderSelectionDialogIntro')` is inspected, then its `style.color` equals `EditorialMonoclePalette.muted` and `style.fontStyle` equals `FontStyle.italic`.

- Given the dialog is open under any theme, when the title `Text` is inspected, then its `style.color` is NOT equal to `AppThemes.colonial.textTheme.titleMedium?.color` (regression guard: dropping the EditorialMonoclePalette override would surface the colonial titleMedium color instead of the canonical `--accent` token).

---

## Widgetbook

Catalog folder: **New Game Leader Selection Dialog** (registered in `app/lib/widgetbook/catalog.dart` via `app/lib/widgetbook/catalog_part4.dart`). Use cases:

1. **Default — six slots populated:** Opens with `GameSetupConfig.defaultConfig.selectedGreatPowerIds`, default leader variants for each, seed `42`, infinite mode off, terrain variation `0.5`, `blessedProfileNames: const []`. Start is enabled; each AI slot's profile dropdown shows only `Normal`.
2. **Duplicate slot regression — England in slots 1 and 6:** Opens with `selectedGreatPowerIds` set to `['england', 'france', 'spain', 'portugal', 'netherlands', 'england']` so slot 1 and slot 6 share the same Great Power id. Demonstrates the duplicate slot validation feedback contract (#2867 R19): both duplicate slot rows wrap their nation `CtDropdown` in the keyed 1 dp `EditorialMonoclePalette.danger` `DecoratedBox`, and Start stays disabled until the duplicate is resolved.
3. **Tuned AI profiles available:** Opens with the default lineup and `blessedProfileNames: const ['aggressive_v2', 'defensive_v1']`. Demonstrates the per-AI-slot AI Profile dropdown (Refs #3444): AI slots 1–5 each render an AI Profile `CtDropdown` listing `Normal` + the two blessed names, while the human slot (0) shows no profile dropdown.
4. **Default (mobile):** Renders the dialog inside the 360 × 640 dp `mobileViewport` frame for narrow-layout review per [mobile-adaptation.md](mobile-adaptation.md) § 6.

Automated widget tests:

- `app/test/new_game_leader_selection_dialog_test.dart` — six-slot rendering, default ordering, seed parsing, infinite-mode toggle, terrain-variation slider, Cancel, slot reassignment, Start payload, the 540 dp wide↔narrow slot-pickers boundary, the duplicate slot validation feedback contract (positive: duplicate slot's nation dropdown carries the danger-border wrapper; negative: no danger-border wrapper when all six slots are unique; recovery: replacing the duplicate clears the wrapper and re-enables Start), and the tuned AI profile selector (AI slots show the `Normal` + blessed-name dropdown, default Start emits an empty `aiProfileByGpId`, selecting a blessed name forwards it keyed by gpId).
- `app/test/mobile_320dp_min_viewport_test.dart` group `SPEC/ui/mobile-adaptation.md § 7 — NewGameLeaderSelectionDialog @ 320 dp` — minimum-viewport pin (Refs #2870 S7/S8/S10): no `RenderFlex` overflow at 320 × 640 dp, every slot renders the stacked column body (no wide row body), title + six `Slot N` headings (slot 1 with `YOU` tag) + Cancel + Start labels visible, every rendered `CtNinePatchButton` ≥ 44 dp tall, and a 1024 × 768 negative regression sentinel that flips the contract so the wide row body is the only one mounted.
