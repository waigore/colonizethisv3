# Game Setup

**Screen ID:** `SHEL20001` — stable; do not reassign.
**SPEC/ui** — Game Setup screen (CtGameSetup). Implementation: `app/lib/widgets/game_setup.dart`.
**Widgetbook:** `Game Setup` → `app/lib/widgetbook/catalog.dart`. Authority: UXD 03b.

**Mockup:** [mockups/SHEL20001-game-setup.html](mockups/SHEL20001-game-setup.html)
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

Visibility and slot labels:

- Given the user navigated to Game Setup from the Main Menu via **New Game**, when the screen mounts, then the UI layer renders the screen title, six player-slot rows, the **Start Game** button, and the **Back** button.
- Given the Game Setup screen is mounted with six player slots, when the slot labels render, then slot 0 displays a localized human-player label of the form "Player 1 (You)".
- Given the Game Setup screen is mounted with six player slots, when the slot labels render, then slots 1–5 display localized AI labels of the form "Player 2 (AI)", "Player 3 (AI)", "Player 4 (AI)", "Player 5 (AI)", and "Player 6 (AI)" in that order.
- Given any player-slot row in Game Setup, when its dropdowns and surrounding controls render, then the UI layer uses `CtDropdown` for the nation and leader pickers and `CtNinePatchButton` for action controls, and the screen mounts no Material `DropdownButton`, `DropdownMenu`, `ElevatedButton`, or `TextButton` widgets.

Header chrome (dark editorial-monocle, `pixelArt` variant):

- Given the screen mounts in the `pixelArt` variant, when the header region renders, then the UI layer paints, in order from top to bottom, the eyebrow text resolved from `gameSetup_eyebrow` (uppercased, 0.22em letter-spacing, colour resolved from `EditorialMonoclePalette.muted`), the title text resolved from `gameSetup_title` (display font from `Theme.of(context).textTheme.headlineMedium`, colour resolved from `EditorialMonoclePalette.accent`, with a single shadow whose colour resolves from `EditorialMonoclePalette.accentBright`), the intro text resolved from `gameSetup_intro` (italic, colour resolved from `EditorialMonoclePalette.muted`), and a `CtBrassDivider` instance.
- Given the screen mounts in the `plain` variant, when the header region renders, then the UI layer renders the title text resolved from `gameSetup_title` (theme `headlineSmall` style with no accent override and no glow shadow) and mounts no `CtBrassDivider`, no eyebrow text, and no intro text.

Initial unselected state:

- Given the widget is constructed with `initialOrderedGpIds` equal to six empty strings and `initialLeaderVariantByGpId` empty, when the screen renders, then each slot's nation dropdown shows the localized placeholder "Select nation" with no nation pre-selected.
- Given the widget is constructed with `initialOrderedGpIds` equal to six empty strings and `initialLeaderVariantByGpId` empty, when the screen renders, then each slot's leader dropdown either shows the localized placeholder "Select leader" or is rendered in a disabled state until a nation is selected for that slot.
- Given the widget is constructed with `initialOrderedGpIds` equal to six empty strings and `initialLeaderVariantByGpId` empty, when the screen renders, then the UI layer renders **Start Game** in its disabled state.

Start-button gating:

- Given the screen is in `state: default` and at least one of the six slots has no nation selected, no leader selected, or a selected nation but no chosen leader, when the action row renders, then the UI layer renders **Start Game** in its disabled state.
- Given the screen is in `state: default` and all six slots have both a nation and a leader selected, when the slot state change that completes the last unselected slot is committed, then the UI layer renders **Start Game** in its enabled state without further input.

Nation uniqueness across slots:

- Given a set of current slot selections in which one or more GP nations are already assigned to other slots, when the user opens the nation dropdown for any slot, then the dropdown lists only GP nations not already selected in another slot (plus the current slot's own nation if any).
- Given a slot has been assigned a new nation, when the selection is committed, then the UI layer removes that nation id from every other slot's nation-dropdown option list for any subsequent open.

Leader follows nation:

- Given a slot already has a nation selected, when the user changes that slot's nation to a different GP, then the UI layer rebuilds the slot's leader dropdown using the new nation's leader variants and sets the selected leader to that new nation's default variant.
- Given the user changed a slot's nation, when the slot's leader dropdown rebuilds, then the previous nation's leader variants are not listed for that slot and the previously selected leader id is not retained for that slot.

Leader uniqueness derives from nation uniqueness:

- Given a slot has a nation assigned, when the user opens that slot's leader dropdown, then the UI layer lists only the leader variants registered to that nation's `gpId` in `ResolvedNamingConfig`, and the UI layer applies no separate cross-slot "leader taken" exclusion (per-slot leader uniqueness follows from the no-duplicate-nations rule).

Start handler payload and shell wiring:

- Given the screen is in `state: default` and all six slots have both a nation and a leader selected, when the user taps **Start Game**, then the widget invokes `onStartGame` exactly once, passing (1) a `List<String>` of six gpIds in slot order (index 0 = human, indices 1–5 = AI) and (2) a `Map<String, String>` of gpId → leaderVariantId covering each of those six gpIds.
- Given the shell has wired `onStartGame`, when `onStartGame` fires with the six gpIds and the leader-variant map, then the shell builds a `GameSetupConfig` with `selectedGreatPowerIds` equal to the list and `leaderVariantByGpId` equal to the map, creates the game, and navigates to [Game initializing](game-initializing.md) per the [App flow after Start Game](#app-flow-after-start-game) section.

Back navigation:

- Given the Game Setup screen is rendered in any `state` where the **Back** button is enabled, when the user taps **Back**, then the widget invokes `onBack` exactly once and the shell navigates to the Main Menu.

Loading state:

- Given the widget is constructed with `state: loading`, when the screen renders, then the UI layer renders **Start Game** in its disabled state.
- Given the widget is constructed with `state: loading`, when the screen renders, then the UI layer renders a visible loading indicator inside the screen body and the localized **"Generating world…"** label resolved from `gameSetup_loadingGeneratingWorld` (per Wireframe § Loading: dim-scrim overlay over header + slot rows, spinner + label in front).
- Given the widget is constructed with `state: loading`, when the screen renders, then every slot's nation and leader dropdowns are disabled and tapping them opens no list.
- Given the widget is constructed with `state: loading`, when the screen renders, then the **Back** button remains enabled and tappable.

Loading overlay chrome (Refs #2868 § R15; `pixelArt` and `plain` variants):

- Given the widget is constructed with `state: loading`, when the screen renders, then the UI layer wraps the header + slot-rows region in an [`Opacity`] widget with opacity equal to **0.4** so the underlying content reads as dimmed.
- Given the widget is constructed with `state: loading`, when the screen renders, then the UI layer wraps the same header + slot-rows region in an [`IgnorePointer`] with `ignoring: true` so the dimmed slot dropdowns and brass chrome cannot receive taps.
- Given the widget is constructed with `state: loading`, when the screen renders, then the UI layer paints a [`Positioned.fill`] scrim layer over the dimmed region whose colour resolves from `EditorialMonoclePalette.dialogScrim` (the canonical modal-scrim token).
- Given the widget is constructed with `state: loading`, when the screen renders, then the UI layer renders a centered `Column` in front of the scrim containing a `CtLoadingIndicator` (48 px, `EditorialMonoclePalette.accent`) followed by the localized **"Generating world…"** label resolved from `gameSetup_loadingGeneratingWorld` (key `gameSetupLoadingLabel`).
- Given the widget is constructed with `state: default_`, when the screen renders, then the UI layer renders no scrim, no `IgnorePointer(ignoring: true)` wrapper around the slot rows, and no centered loading label widget (the dim-overlay chrome is gated to `state: loading`).
- Given the widget is constructed with `state: loading`, when the user taps the **Back** button, then the **Back** button's `onBack` callback fires once because the **Back** button paints outside the scrim layer (the scrim only covers the header + slot rows region, not the action buttons).

Slot-row chrome and swatch dots (issue #2868 § R7/R9/R10; pixelArt variant):

- Given the widget is constructed with `variant: pixelArt`, when the screen renders, then each of the six player-slot rows is wrapped in a `Container` that paints the dark-theme row gradient (`CtGradients.rowGradient`) and a 1.5 px brass border on all four sides (top/bottom borders + left/right edge strips, color `EditorialMonoclePalette.accentDim`).
- Given the widget is constructed with `variant: plain`, when the screen renders, then no slot row paints the 1.5 px `EditorialMonoclePalette.accentDim` border chrome (the chrome is gated to the `pixelArt` variant; the plain variant keeps the pre-#2868 theme-only layout).
- Given any slot has a nation selected, when the slot's nation dropdown closed trigger renders, then the UI layer renders the GP map-colour swatch (`GpDefaultMapColorSwatch`) immediately preceding the nation label, using the `greatPowerDefaultColorRgb` mapping for that gpId.
- Given the user opens any slot's nation dropdown, when the picker list renders, then every non-empty option row renders a leading `GpDefaultMapColorSwatch` matching that option's gpId; the empty "Select nation" row renders no swatch.
- Given any slot has no nation selected (`gpId == ''`), when the slot's leader dropdown renders, then the UI layer wraps the dropdown in an `Opacity` widget with `opacity == 0.4` and an `IgnorePointer(ignoring: true)`, so the dropdown is visually dimmed and tapping it does not open the picker.
- Given a slot transitions from no-nation to a selected-nation state, when the slot rebuilds, then the leader dropdown is no longer wrapped in the `Opacity(0.4)` + `IgnorePointer` wrappers and accepts taps to open the leader picker.

Action buttons and back link (issue #2868 § R12/R13/R14; `pixelArt` variant):

- Given the widget is constructed with `variant: pixelArt`, when the screen renders, then the action row places a **Cancel** affordance and a **Start Game** `CtNinePatchButton` side-by-side in a single horizontal [`Row`] (with the Cancel button on the left and Start Game on the right, each at equal flex), and a separate back link (see below) renders beneath that row. The two-affordance pair mirrors the canonical `[Cancel] [Start Game]` action row in `SPEC/ui/mockups/SHEL20001-game-setup.html` § `.actions` and the standalone `.back-link` text link below it.
- Given the widget is constructed with `variant: pixelArt`, when the Cancel affordance renders, then the UI layer paints a tappable surface with a vertical gradient from `EditorialMonoclePalette.surface` (top) to `EditorialMonoclePalette.bgDeep` (bottom), a 1 px `EditorialMonoclePalette.border` outline, a localized label resolved from `gameSetup_cancel` ("Cancel") rendered in `EditorialMonoclePalette.muted`, and a minimum tap-target height of `48 dp`. Tapping the Cancel affordance invokes the widget's `onBack` callback exactly once (the Cancel and back link share the same destination per the mockup, where both `.cancel-btn` and `.back-link` call `handleCancel()`).
- Given the widget is constructed with `variant: pixelArt`, when the Start Game button renders in either enabled or disabled state, then the UI layer uses the canonical `CtNinePatchButton` chrome (`CtGradients.buttonGradient` surface + four 10×10 px brass corner brackets in `EditorialMonoclePalette.accent` + engraved `EditorialMonoclePalette.accent` text per `SPEC/ui/pixel-art-ui-catalog.md` § *CtNinePatchButton*). The wood-panel-gradient requirement in `SPEC/ui/mockups/SHEL20001-game-setup.html` § `.start-btn` is satisfied by reusing this canonical primary chrome rather than diverging into a screen-specific paint.
- Given the widget is constructed with `variant: pixelArt`, when the back-link region renders below the action row, then the UI layer renders a horizontal [`Row`] containing exactly one `CtBackButton` (28 × 28 dp tap target, 16 × 16 dp chevron-left glyph) followed by a localized label resolved from `gameSetup_backToMainMenu` ("Back to Main Menu") in `EditorialMonoclePalette.muted`. Tapping either the `CtBackButton` glyph or the link text invokes the widget's `onBack` callback exactly once. The label `Text` is wrapped in a `Flexible` and uses `maxLines: 1` + `softWrap: false` + `overflow: TextOverflow.ellipsis` so the row honours [mobile-adaptation.md](mobile-adaptation.md) § 7 (no `RenderFlex` overflow at `kMinViewportWidth`); above that envelope the `mainAxisSize: min` row keeps the back link centered and the label takes its intrinsic width.
- Given the widget is constructed with `variant: plain`, when the screen renders, then the action region preserves the pre-#2868 layout (a single-column stack of **Start Game** followed by **Back**, both rendered as full-width `CtNinePatchButton`s wrapped by `_GameSetupMenuButton`) — the `pixelArt` Cancel / two-up row / back-link chrome is not introduced into the plain variant tree.
- Given the widget is constructed with `state: loading` and `variant: pixelArt`, when the screen renders, then the Cancel affordance, the `CtBackButton` glyph, and the back-link text all paint outside the loading scrim and remain enabled and tappable; tapping the Cancel affordance or either back-link affordance invokes the widget's `onBack` callback (preserving the existing **Loading state** AC that the back affordance stays enabled while the world is generating).

Narrow-viewport slot-row stacking and action-button retention (issue #2868 § R16/R17; both variants unless noted):

- Given the widget is constructed with `variant: pixelArt` and the rendering viewport has width strictly less than `kGameSetupNarrowBreakpoint` (500 dp, defined in `app/lib/config/constants.dart`), when the screen renders, then each of the six player-slot rows lays out the slot label, nation dropdown, and leader dropdown as a vertically-stacked `Column` (slot label on the first line, nation dropdown full width on the second line, leader dropdown full width on the third line), and no slot row body mounts a horizontal `Row` containing all three controls.
- Given the widget is constructed with `variant: pixelArt` and the rendering viewport has width greater than or equal to `kGameSetupNarrowBreakpoint` (500 dp), when the screen renders, then each of the six player-slot rows lays out the slot label, nation dropdown, and leader dropdown side-by-side in a single horizontal `Row` (label | nation dropdown | leader dropdown), and no slot row body mounts a vertically-stacked `Column` containing all three controls.
- Given the widget is constructed with `variant: pixelArt` and the rendering viewport has width strictly less than `kGameSetupNarrowBreakpoint` (500 dp), when the screen renders, then the action region keeps the same single content-column layout used at wider viewports — the Cancel and Start Game affordances remain side-by-side in a single horizontal `Row` (each at equal flex) and the `_GameSetupBackLink` region remains beneath that row; the UI layer does not stack Cancel above Start Game and does not reflow the back link inline with the action row.
- Given the widget is constructed with `variant: plain` and the rendering viewport has width strictly less than `kGameSetupNarrowBreakpoint` (500 dp), when the screen renders, then each of the six player-slot rows lays out the slot label, nation dropdown, and leader dropdown as a vertically-stacked `Column` (label / nation / leader), matching the narrow stacking applied to the `pixelArt` variant so both variants honor the 500 dp breakpoint defined in `kGameSetupNarrowBreakpoint`.

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

**Default (dark editorial-monocle, `pixelArt` variant):**

```text
+--------------------------------------------------------+
|  NEW CAMPAIGN                                          |   ← eyebrow_region
|  Game Setup                                            |   ← title_region (accent + glow)
|  Choose six great powers and a leader variant for each.|   ← intro_region (italic, muted)
|  ─────────────◆─────────────                          |   ← divider_region (CtBrassDivider)
|                                                        |
|  Player 1 (You)    [ Select nation ▼ ] [ Select leader ▼ ] |
|  Player 2 (AI)     [ Select nation ▼ ] [ Select leader ▼ ] |
|  ... (all six slots initially unselected)              |
|                                                        |
|  [ Cancel ] [ Start Game ]   ← actions_region (Start disabled until all slots complete)
|  ‹ Back to Main Menu         ← back_link_region (CtBackButton + link text)
+--------------------------------------------------------+
```

In the `plain` variant the action region preserves the pre-#2868 single-column stack (full-width Start Game, then Back) — no Cancel button, no back-link row, no `CtBackButton`. The dual back affordance (Cancel + Back link) is gated to the `pixelArt` chrome.

The header chrome (eyebrow + title + intro + divider) is the dark editorial-monocle redesign per `pixel-art-ui-catalog.md` § Editorial-monocle palette. The eyebrow renders the localized `gameSetup_eyebrow` string in uppercase, **muted** color, and 0.22em letter-spacing. The title renders the localized `gameSetup_title` using the catalog display font (Cinzel via `Theme.of(context).textTheme.headlineMedium`) painted in `EditorialMonoclePalette.accent` with a subtle text-shadow glow that resolves from `EditorialMonoclePalette.accentBright` (no hard-coded hex). The intro renders the localized `gameSetup_intro` in italic, **muted** color. The `CtBrassDivider` from `Refs #2859` separates the header from the slot rows.

When the user has selected a nation and leader for every slot, Start Game becomes enabled. Nation dropdown for a slot lists "Select nation" (empty) plus GPs not selected in other slots. Leader dropdown lists "Select leader" (empty) until a nation is chosen, then that nation’s variants. When nation changes, leader resets to that nation’s default.

**Loading:** Same column layout; Start Game disabled; **Back remains enabled and tappable**. The header + slot-rows region is dimmed (`Opacity(0.4)` + `IgnorePointer(ignoring: true)`) and covered by an `EditorialMonoclePalette.dialogScrim` scrim. A centered loading affordance — `CtLoadingIndicator` (48 px, `EditorialMonoclePalette.accent`) above the localized **"Generating world…"** label (key `gameSetup_loadingGeneratingWorld`) — paints in front of the scrim. The scrim only covers the dimmed region; the action buttons (Start Game, Back) paint below it so the Back button remains tappable.

**Regions (UXD 07–style):** canvas full-screen; `eyebrow_region` ("NEW CAMPAIGN"), `title_region` ("Game Setup"), `intro_region` (one-line intro), `divider_region` (`CtBrassDivider`), `slots_region` (scrollable: six rows, each with slot label, nation dropdown, leader dropdown). In the `pixelArt` variant the action affordances split into `actions_region` (one horizontal row containing the Cancel surface and the Start Game `CtNinePatchButton`) and a separate `back_link_region` below (a `CtBackButton` glyph plus the "Back to Main Menu" link text). In the `plain` variant a single `buttons_region` keeps the legacy stacked layout (Start Game above Back). `loading_region` is present in `loading` state.

**Variant rendering (header chrome).** The dark editorial-monocle header chrome is tied to the `pixelArt` variant (catalog-aligned). The `plain` variant remains a theme-only fallback for Widgetbook/debug (no eyebrow, no glow, no brass divider) per the table below; the existing widget contract (callbacks, `state`, `naming`, slot list) is unchanged for both variants.

| Element | `plain` variant | `pixelArt` variant |
|---------|-----------------|--------------------|
| Eyebrow ("NEW CAMPAIGN") | Hidden | Visible: uppercase, muted, 0.22em letter-spacing |
| Title ("Game Setup") | `Theme.of(context).textTheme.headlineSmall` (theme default colour, no glow) | Display font + `EditorialMonoclePalette.accent` colour + subtle glow shadow from `EditorialMonoclePalette.accentBright` |
| Intro text | Hidden | Visible: italic, muted |
| Brass divider | Hidden | `CtBrassDivider` between header and slot rows |

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

Folder: **Game Setup**. Use cases:

- **Default** — plain variant, default state, desktop viewport.
- **Loading** — plain variant, loading state, desktop viewport.
- **Default (pixel)** — pixelArt variant, default state, desktop viewport.
- **Loading (pixel)** — pixelArt variant, loading state, desktop viewport.
- **Default (mobile)** — plain variant, default state, 360 × 640 dp mobile viewport (below `kGameSetupNarrowBreakpoint`; exercises the stacked slot-row layout from the narrow-viewport AC block above).
- **Default (mobile, pixel)** — pixelArt variant, default state, 360 × 640 dp mobile viewport (exercises the dark editorial-monocle chrome under the same narrow stacking; SPEC § *Narrow-viewport slot-row stacking and action-button retention*).
- **Loading (mobile, pixel)** — pixelArt variant, loading state, 360 × 640 dp mobile viewport (exercises the loading scrim under the narrow layout; SPEC § *Narrow-viewport slot-row stacking and action-button retention* + *Loading overlay chrome*).
- **All slots selected (pixel)** — pixelArt variant, default state, desktop viewport with every slot pre-filled with a great power and that power's default leader variant (exercises the happy-path Start Game enabled state and the GP map-colour swatches on every closed nation trigger; SPEC § *Slot-row chrome and swatch dots* R9).

---

## Acceptance criteria

See **How this spec satisfies UXD 03b** and shell dialog section for Given–When–Then ACs.
