# Game Setup

**Screen ID:** `SHEL20001` — stable; do not reassign.
**SPEC/ui** — Game Setup screen (CtGameSetup). Implementation: `app/lib/widgets/game_setup.dart`.
**Widgetbook:** `Game Setup` → `app/lib/widgetbook/catalog.dart`. Authority: UXD 03b.

---

## Widget contract

The CtGameSetup widget is presentational and accepts the following parameters. The **shell** (or parent) supplies config and naming and handles navigation. There are **six player slots**; slot 0 is the **human player**, slots 1–5 are **AI**. For each slot the user selects **nation (GP)** then **leader**; leaders are tied to the selected nation. Nations and leaders already chosen in one slot are not available in another (no duplicate nations).

| Parameter | Type | Description |
|-----------|------|-------------|
| `variant` | `plain` \| `pixelArt` | Both variants use the **same pixel-art component catalog** (CtNinePatchButton, CtDropdown, CtScreenShell). **plain:** colonial colour theme only (no background illustration). **pixelArt:** reuses main menu pixel-art background and button assets per UXD 02/03a. |
| `state` | `default` \| `loading` | **default:** Start Game and dropdowns enabled. **loading:** Start Game disabled; nation and leader dropdowns **disabled**; a loading indicator **must** be visible; Back remains enabled. |
| `naming` | `ResolvedNamingConfig` | All GP country names and leader variants (colonizethis_data). Used to populate nation and leader dropdowns. |
| `initialOrderedGpIds` | `List<String>` | Length 6. Initial nation (gpId) per slot; **empty string denotes unselected**. When the screen loads with all entries empty (e.g. `["", "", "", "", "", ""]`), all nation/leader choices are unselected; the shell should pass this for a fresh setup. |
| `initialLeaderVariantByGpId` | `Map<String, String>` | Initial leader variant per gpId (gpId → variantId). When the screen loads with all choices unselected, this is empty. When a slot’s nation changes, leader resets to default for that nation. |
| `onStartGame` | `void Function(List<String> orderedGpIdsForSlots, Map<String, String> leaderVariantByGpId)` | Invoked when user taps Start Game. Widget passes ordered list of 6 gpIds (slot 0 = human, 1–5 = AI) and leader map; shell builds GameSetupConfig and creates game. |
| `onBack` | callback | Invoked when user taps Back; shell navigates to Main Menu. |

---

## Trigger conditions

- **Entry:** Shell pushes Game Setup after New Game / leader-selection per [`app-ui-wiring.md`](../program/app-ui-wiring.md).
- **Back:** `onBack` returns to main menu.

---

## How this spec satisfies UXD 03b

**User stories.** The user lands here from Main Menu "New Game". **On load, all nation and leader choices are unselected** (each slot shows e.g. "Select nation" / "Select leader"). They see six player slots: **Player 1 (You)** (human) and **Players 2–6 (AI)**. For each slot they select a **nation** (GP) from a dropdown, then a **leader** for that nation. **Start Game is disabled until every slot has both a nation and a leader selected.** Nations/leaders already selected in another slot are excluded from other dropdowns so no two players share a nation. Changing a slot’s nation updates that slot’s leader options to that nation’s variants (and resets to the default leader for that nation). Tapping **Start Game** creates the game with slot 0 as human and slots 1–5 as AI; **Back** returns to Main Menu. Shell wires callbacks and owns navigation. Config semantics: [SPEC/game/game-setup.md](../game/game-setup.md), [game-setup-pipeline.md](../program/game-setup-pipeline.md).

**Acceptance criteria (Given–When–Then).**

- **Visibility:** Given the user navigated from Main Menu via New Game, the UI layer shows the Game Setup screen with title, six player-slot rows, Start Game button, and Back button. Slot 1 is labeled as the human player (e.g. "Player 1 (You)"); slots 2–6 are labeled as AI (e.g. "Player 2 (AI)" … "Player 6 (AI)"). Each row has a nation dropdown and a leader dropdown rendered with pixel-art compatible components (CtDropdown, CtNinePatchButton); **no Material buttons or dropdowns are used.**
- **Initial state unselected:** Given the screen is loaded with all nation/leader choices unselected (e.g. `initialOrderedGpIds` is six empty strings and `initialLeaderVariantByGpId` is empty), the UI layer shows each slot with no nation and no leader selected (e.g. nation dropdown shows "Select nation", leader dropdown shows "Select leader" or is disabled). Start Game is disabled.
- **Start disabled until complete:** Given state is default, when one or more slots have no nation selected or no leader selected (or leader not yet chosen for a selected nation), the UI layer keeps Start Game disabled. When the user has selected a nation and a leader for all six slots, the UI layer enables Start Game.
- **No duplicate nations:** Given the current slot selections, when the user opens the nation dropdown for any slot, the dropdown lists only nations not already selected in another slot. Selecting a nation in one slot removes it from the nation options in every other slot.
- **Leader follows nation:** Given a slot has a selected nation, when the user changes that slot’s nation, the UI layer updates the leader dropdown to that nation’s leader variants and sets the selected leader to the default variant for that nation. The previous nation’s leader selection is no longer shown for that slot.
- **Leader uniqueness:** Leaders are per nation; once a nation is assigned to a slot, the leader dropdown for that slot shows only that nation’s variants. No separate “leader taken” rule across slots because each slot has a distinct nation.
- **Start:** Given state is default and **all six slots have both a nation and a leader selected**, when the user taps Start Game, the widget invokes `onStartGame` once with (1) a list of six gpIds in slot order (index 0 = human, 1–5 = AI) and (2) a map gpId → leaderVariantId for each of those gpIds. The shell builds GameSetupConfig (e.g. selectedGreatPowerIds = that list, leaderVariantByGpId = that map), creates the game, and navigates.
- **Back:** When the user taps Back, the widget invokes `onBack` once; the shell navigates to Main Menu.
- **Loading:** Given state is loading, the Start Game control is disabled; a loading indicator is visible; nation and leader dropdowns are disabled; tapping Back remains enabled.

**Interaction.** The widget holds per-slot state (ordered list of six gpIds and leader variant per gpId) and exposes it via `onStartGame(orderedGpIdsForSlots, leaderVariantByGpId)`. No routing logic lives in the widget.

**App flow after Start Game.** When the user taps Start Game, the shell builds GameSetupConfig and starts game initialization. The shell shows progress per [Game initialization (new game)](game-initializing.md) (coarse steps; modal or full screen). On success the shell navigates to the [Empire overview](empire-overview.md) (in-game shell). On failure the shell shows an error dialog with retry (new seed) per that spec, not silent navigation to Main Menu.

**Automated tests.** Widget tests in `app/test/screen_spec_acceptance_test.dart` assert the acceptance criteria above (visibility, initial state, Start disabled until complete, no duplicate nations, leader follows nation, onStartGame/onBack payloads, loading state). Run: `flutter test test/screen_spec_acceptance_test.dart` from the app package.

---

## Shell new game dialog (`NewGameLeaderSelectionDialog`)

**Flutter app shell** implements the same **six-slot** nation/leader semantics as `CtGameSetup` inside a **modal dialog** opened from Main Menu (bus id `new_game_leader_selection`). Full-screen `CtGameSetup` remains the catalog/widget contract for UXD 03b and tests; the shell path is dialog-based for current product. See [new-game-leader-selection-dialog.md](new-game-leader-selection-dialog.md) for the authoritative widget contract, layout, states, and ACs.

| Element | Requirement |
|--------|-------------|
| Slots | Six rows: slot 0 = human (**Player 1 (You)**), slots 1–5 = AI (**Player 2–6 (AI)**). Each row: **slot label**, then **one horizontal row** with nation and leader pickers side-by-side (equal width, 8 dp gap) to save vertical space. |
| Nation picker | Per slot, `CtDropdown` of Great Powers. **No duplicate nations** across slots (options exclude GPs taken in other slots; changing assignments follows the same exclusion rules as `CtGameSetup`). **Default map colour** (`greatPowerDefaultColorRgb` in colonizethis_data / GDD 09): small filled rectangle **left of the nation name** in the closed control and in each list row. |
| Leader picker | Per slot (same row as nation), leaders for that slot’s nation only; changing nation resets leader to that nation’s default variant. |
| Initial load | **Implicit default:** slot order starts as **`GameSetupConfig.defaultConfig.selectedGreatPowerIds`** (six distinct GPs). Leaders default to each nation’s default variant. **Start** is enabled when all slots have valid nations and leaders (true on open with default data). |
| Game / world seed | Numeric field **below** the slot rows. Initial display **42** (from template `GameSetupConfig.seed`). **0** = random (time-based effective seed when setup runs; see [game-setup-pipeline.md](../program/game-setup-pipeline.md)). Any other non-negative integer is reproducible. **Empty or unparsable** on Start → **42**. **Negative** input on Start → **42**. Short **localized helper** beside/near the field explains 0 vs fixed seed. The dialog does **not** show the resolved effective seed. |
| Infinite mode | Checkbox **below** the seed field, default **unchecked**. Label **Infinite mode (turns progress past 1800)** with short helper. Immutable after game creation. |
| Terrain variation | Slider **below** the infinite-mode checkbox, range `0.0`–`1.0` with step `0.05`, default **`0.5`**. Label **Terrain variation** with short helper "Higher values produce more mixed terrain (0 keeps legacy clumps)". Drives `GameSetupConfig.terrainVariation` (and ultimately `TileMapParams.terrainVariation` for both Old World and New World map generation). Immutable after game creation. |
| Actions | **Start** closes the dialog and passes **`(orderedGreatPowerIds, leaderVariantByGpId, seed, infiniteMode, terrainVariation)`** to the shell; shell builds `GameSetupConfig` (including **`seed`**, **`infiniteMode`**, and **`terrainVariation`**) and runs [Game initializing](game-initializing.md). **Cancel** dismisses without starting setup. |

**Layout (shell dialog + `CtDialogShell`).** The dialog is framed by **`CtDialogShell`**: frame height follows content up to `maxHeight`; when taller, the **entire** body (slots, seed, actions) scrolls as **one** vertical scroll—there is **no** separate fixed-height scroll region that only wraps the six slot rows on large viewports. On tall viewports, all six slot rows are visible without scrolling inside a slot-only panel.

**Acceptance criteria (shell dialog).**

- **Given** the user opened New Game from the main menu, **when** the dialog is shown, **then** six slot rows appear; each row shows the slot label and **nation + leader dropdowns on one line**; Cancel, Start, and the seed field; initial nations match the program default six GPs and leaders match defaults; nation pickers show the GP colour swatch beside each nation label.
- **Given** the dialog is open, **when** the user changes a slot’s nation, **then** that slot’s leader list updates to that nation’s variants and the selected leader becomes that nation’s default unless the user picks another.
- **Given** the dialog is open, **when** the user opens a nation dropdown, **then** only GPs not assigned to **other** slots are listed (plus the current slot’s nation).
- **Given** the user taps Start, **when** the handler runs, **then** it receives the six gpIds in slot order, the leader map for those ids, and an integer **`seed` ≥ 0** (default **42** when the field is unchanged), and game initialization proceeds as in [game-initializing.md](game-initializing.md).
- **Given** the dialog is open with the default seed field, **when** the user taps Start without editing the seed, **then** the UI layer passed **`seed == 42`**, helper text for the seed field is visible, and **`GameSetupConfig.seed`** in the template matches that value.
- **Given** the user cleared the seed field or entered a negative value, **when** the user taps Start, **then** the shell uses **`GameSetupConfig.seed == 42`**.
- **Given** the dialog is open with the default terrain-variation slider value, **when** the user taps Start without moving the slider, **then** the UI layer passes **`terrainVariation == 0.5`** and **`GameSetupConfig.terrainVariation`** in the template equals **`0.5`**.
- **Given** the user moves the terrain-variation slider to its leftmost position, **when** the user taps Start, **then** the UI layer passes **`terrainVariation == 0.0`** and the resulting Old World / New World maps are generated with the noise perturbation pass bypassed (byte-identical to legacy generation per [tile-map-gen-algorithm.md § Pass 6b.5](../program/tile-map-gen-algorithm.md)).

**Automated tests.** Widget tests cover the dialog (defaults, swatch presence, Start payload, shell scroll/layout) and shell integration (`app/test/shell_screen_test.dart`); `app/test/ct_dialog_shell_test.dart` covers shared `CtDialogShell` sizing and scroll.

---

## Layout / wireframe

Positions, layout, and hierarchy (per UXD 03b; 44 dp min touch targets).

**Default:**

```text
+------------------------------------------------------+
|                  Game Setup                          |
|                                                      |
|  Player 1 (You)    [ Select nation ▼ ] [ Select leader ▼ ] |
|  Player 2 (AI)     [ Select nation ▼ ] [ Select leader ▼ ] |
|  ... (all six slots initially unselected)            |
|                                                      |
|  [ Start Game ]  (disabled until all slots complete)  |
|  [ Back ]                                            |
+------------------------------------------------------+
```

When the user has selected a nation and leader for every slot, Start Game becomes enabled. Nation dropdown for a slot lists "Select nation" (empty) plus GPs not selected in other slots. Leader dropdown lists "Select leader" (empty) until a nation is chosen, then that nation’s variants. When nation changes, leader resets to that nation’s default.

**Loading:** Same layout; Start Game disabled; a visible loading indicator ("Starting…" label and/or spinner) is required; Back enabled.

**Regions (UXD 07–style):** canvas full-screen; title_region ("Game Setup"); slots_region (scrollable: six rows, each with slot label, nation dropdown, leader dropdown); buttons_region (Start Game, Back); loading_region is present in `loading` state.

**Layout (pixel-art variant):** Content column constrained to **max width 400 dp**; Start/Back use main menu button asset. Content centered. Slots may scroll on small screens.

**Mobile:** See [mobile-adaptation.md](mobile-adaptation.md). The screen scrolls (slots + buttons inside `SingleChildScrollView`). Below 500 dp width, each player-slot row uses a **stacked layout**: slot label on one line, nation dropdown full width, leader dropdown full width below. Above 500 dp, one row: label | nation | leader. Safe area and 44 dp touch targets apply.

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| Shell / setup route | After leader dialog or direct setup navigation | `CtGameSetup` mounted with `naming` and slot config. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Start Game | All slots filled; `state != loading` | `onStartGame` | Shell runs game init → game route. |
| Back | `state != loading` | `onBack` | Returns to prior screen. |

---

## States and variants

| ID | Variant | Trigger | Render difference |
|----|---------|---------|-------------------|
| `SHEL20001` | `default` | `state == default` | Dropdowns and Start enabled. |
| `SHEL20001` | `loading` | `state == loading` | Start disabled; loading indicator; dropdowns disabled. |

---

## Pixel-art assets

For current product, reuse main menu assets: `ui_main_menu_button.png` for Start Game and Back. Dropdowns and list use theme styling. Style lock: UXD 02.

---

## Components

- `CtGameSetup`, `CtDropdown`, `CtNinePatchButton`, `CtScreenShell` — see [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md).
- `app/widget_catalog.json` entry: CtGameSetup (category: screen).

---

## Widgetbook

Folder: **Game Setup**. Use cases: **Default**, **Loading** per states table.

---

## Acceptance criteria

See **How this spec satisfies UXD 03b** and shell dialog section for Given–When–Then ACs.
