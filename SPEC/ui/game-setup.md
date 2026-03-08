# Game Setup

**SPEC/ui** — Game Setup screen. Authority: UXD 03b (Game Setup). Catalog widget: CtGameSetup.

---

## Widget contract

The CtGameSetup widget is presentational and accepts the following parameters. The **shell** (or parent) supplies config and naming and handles navigation. There are **six player slots**; slot 0 is the **human player**, slots 1–5 are **AI**. For each slot the user selects **nation (GP)** then **leader**; leaders are tied to the selected nation. Nations and leaders already chosen in one slot are not available in another (no duplicate nations).

| Parameter | Type | Description |
|-----------|------|-------------|
| `variant` | `plain` \| `pixelArt` | **plain:** standard Flutter/colonial theme. **pixelArt:** reuses main menu button asset per UXD 02. |
| `state` | `default` \| `loading` | **default:** Start Game and dropdowns enabled. **loading:** Start disabled, optional loading indicator; Back remains enabled. |
| `naming` | `ResolvedNamingConfig` | All GP country names and leader variants (colonizethis_data). Used to populate nation and leader dropdowns. |
| `initialOrderedGpIds` | `List<String>` | Length 6. Initial nation (gpId) per slot; **empty string denotes unselected**. When the screen loads with all entries empty (e.g. `["", "", "", "", "", ""]`), all nation/leader choices are unselected; the shell should pass this for a fresh setup. |
| `initialLeaderVariantByGpId` | `Map<String, String>` | Initial leader variant per gpId (gpId → variantId). When the screen loads with all choices unselected, this is empty. When a slot’s nation changes, leader resets to default for that nation. |
| `onStartGame` | `void Function(List<String> orderedGpIdsForSlots, Map<String, String> leaderVariantByGpId)` | Invoked when user taps Start Game. Widget passes ordered list of 6 gpIds (slot 0 = human, 1–5 = AI) and leader map; shell builds GameSetupConfig and creates game. |
| `onBack` | callback | Invoked when user taps Back; shell navigates to Main Menu. |

---

## How this spec satisfies UXD 03b

**User stories.** The user lands here from Main Menu "New Game". **On load, all nation and leader choices are unselected** (each slot shows e.g. "Select nation" / "Select leader"). They see six player slots: **Player 1 (You)** (human) and **Players 2–6 (AI)**. For each slot they select a **nation** (GP) from a dropdown, then a **leader** for that nation. **Start Game is disabled until every slot has both a nation and a leader selected.** Nations/leaders already selected in another slot are excluded from other dropdowns so no two players share a nation. Changing a slot’s nation updates that slot’s leader options to that nation’s variants (and resets to the default leader for that nation). Tapping **Start Game** creates the game with slot 0 as human and slots 1–5 as AI; **Back** returns to Main Menu. Shell wires callbacks and owns navigation. Config semantics: [SPEC/game/game-setup.md](../game/game-setup.md), [game-setup-pipeline.md](../program/game-setup-pipeline.md).

**Acceptance criteria (Given–When–Then).**

- **Visibility:** Given the user navigated from Main Menu via New Game, the UI layer shows the Game Setup screen with title, six player-slot rows, Start Game button, and Back button. Slot 1 is labeled as the human player (e.g. "Player 1 (You)"); slots 2–6 are labeled as AI (e.g. "Player 2 (AI)" … "Player 6 (AI)"). Each row has a nation dropdown and a leader dropdown.
- **Initial state unselected:** Given the screen is loaded with all nation/leader choices unselected (e.g. `initialOrderedGpIds` is six empty strings and `initialLeaderVariantByGpId` is empty), the UI layer shows each slot with no nation and no leader selected (e.g. nation dropdown shows "Select nation", leader dropdown shows "Select leader" or is disabled). Start Game is disabled.
- **Start disabled until complete:** Given state is default, when one or more slots have no nation selected or no leader selected (or leader not yet chosen for a selected nation), the UI layer keeps Start Game disabled. When the user has selected a nation and a leader for all six slots, the UI layer enables Start Game.
- **No duplicate nations:** Given the current slot selections, when the user opens the nation dropdown for any slot, the dropdown lists only nations not already selected in another slot. Selecting a nation in one slot removes it from the nation options in every other slot.
- **Leader follows nation:** Given a slot has a selected nation, when the user changes that slot’s nation, the UI layer updates the leader dropdown to that nation’s leader variants and sets the selected leader to the default variant for that nation. The previous nation’s leader selection is no longer shown for that slot.
- **Leader uniqueness:** Leaders are per nation; once a nation is assigned to a slot, the leader dropdown for that slot shows only that nation’s variants. No separate “leader taken” rule across slots because each slot has a distinct nation.
- **Start:** Given state is default and **all six slots have both a nation and a leader selected**, when the user taps Start Game, the widget invokes `onStartGame` once with (1) a list of six gpIds in slot order (index 0 = human, 1–5 = AI) and (2) a map gpId → leaderVariantId for each of those gpIds. The shell builds GameSetupConfig (e.g. selectedGreatPowerIds = that list, leaderVariantByGpId = that map), creates the game, and navigates.
- **Back:** When the user taps Back, the widget invokes `onBack` once; the shell navigates to Main Menu.
- **Loading:** Given state is loading, the Start Game control is disabled and (optionally) a loading indicator is visible; nation and leader dropdowns may be disabled; tapping Back remains enabled.

**Interaction.** The widget holds per-slot state (ordered list of six gpIds and leader variant per gpId) and exposes it via `onStartGame(orderedGpIdsForSlots, leaderVariantByGpId)`. No routing logic lives in the widget.

**Automated tests.** Widget tests in `app/test/screen_spec_acceptance_test.dart` assert the acceptance criteria above (visibility, initial state, Start disabled until complete, no duplicate nations, leader follows nation, onStartGame/onBack payloads, loading state). Run: `flutter test test/screen_spec_acceptance_test.dart` from the app package.

---

## Wireframe

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

**Loading:** Same layout; Start Game disabled; optional "Starting…" or spinner; Back enabled.

**Regions (UXD 07–style):** canvas full-screen; title_region ("Game Setup"); slots_region (scrollable: six rows, each with slot label, nation dropdown, leader dropdown); buttons_region (Start Game, Back); optional loading_region when state is loading.

**Layout (pixel-art variant):** Content column constrained to **max width 400 dp**; Start/Back use main menu button asset. Content centered. Slots may scroll on small screens.

**Mobile:** See [mobile-adaptation.md](mobile-adaptation.md). The screen scrolls (slots + buttons inside `SingleChildScrollView`). Below 500 dp width, each player-slot row uses a **stacked layout**: slot label on one line, nation dropdown full width, leader dropdown full width below. Above 500 dp, one row: label | nation | leader. Safe area and 44 dp touch targets apply.

---

## Pixel-art assets

For MVP, reuse main menu assets: `ui_main_menu_button.png` for Start Game and Back. Dropdowns and list use theme styling. If a dedicated game-setup panel is added later, add a row here and PixelLab prompts. Style lock: UXD 02.

---

## Widget catalog

Once implemented, register in `app/widget_catalog.json` as CtGameSetup (category: screen, source: pipeline), with `dart_file_path` and `widgetbook_story_path`: "Game Setup".
