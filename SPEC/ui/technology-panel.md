# Technology Panel (Research Slots)

**Screen ID:** `GAME40001` — stable; do not reassign.
**SPEC/ui** — Technology panel: research slots and assignment. Implementation: `app/lib/features/game/screens/technology_screen.dart`.
**Widgetbook:** `Tech Tree` → `app/lib/widgetbook/catalog.dart`. Game rules: [tech-tree.md](../game/tech-tree.md), [research-state.md](../game/research-state.md). Placement: [tech-tree-widget.md](tech-tree-widget.md) (slots tab).

**Mockup:** [mockups/GAME40001-technology-panel.html](mockups/GAME40001-technology-panel.html)
---

## Widget contract

Technology screen hosts research slots UI: slot count from `player.researchSlots`; assignment updates `Orders.researchOrdersByPlayerId`.

---

## Trigger conditions

- **Toolbar / route:** Technology flow opened from in-game shell (Slots tab within technology screen).

---

## Layout / wireframe

### Top bar (dark editorial-monocle, all viewports)

- **Component:** `CtTopBar` (`SPEC/ui/pixel-art-ui-catalog.md` § Pixel-art component catalog → `CtTopBar` entry), supplied through the `topBar` slot of `CtGameFeatureScreenShell` so the screen reuses the shared `Scaffold` + `SafeArea` + `Column` body shell and retains `GameToUIBusListener` for live game wiring.
- **Back affordance:** `CtBackButton` chevron-left glyph followed by the muted label `Map` so the affordance reads `← Map`. The button's default behaviour calls `Navigator.maybePop()` and is a no-op when there is no prior route on the stack.
- **Icon + title:** Pixel-art technology icon `assets/icons/32/ui_icon_technology.png` rendered at 18 × 18 logical px between the back affordance and the title. The title literal is `Technology`, rendered in the dark-theme `titleMedium` slot (Cinzel display family per `AppThemes.editorialMonocle`).
- **Height + chrome:** Fixed `CtTopBar.height` (36 px), filled with `CtGradients.topBarGradient`, capped by a 1 px `EditorialMonoclePalette.accentDim` bottom border. Hard-coded colours are forbidden; all tokens resolve through `EditorialMonoclePalette`.
- **Trailing slot — Slots / Tree toggle:** A pair of pixel-art toggle chips occupies the `CtTopBar.trailing` slot in the order `Slots`, `Tree`. The selected chip paints a 1 px `EditorialMonoclePalette.accent` border with an accent-tinted background; the unselected chip paints a 1 px `EditorialMonoclePalette.border` outline with a transparent background. Tapping a chip swaps the body between the Slots panel (`TechnologyPanel`) and the Tree panel (`TechTreeWidget`) without unmounting the surrounding shell. Material `TabBar` / `Tab` / `ToggleButtons` / `ChoiceChip` are banned on this surface per `SPEC/ui/pixel-art-ui-catalog.md`.

### Body

- **Slots tab (default):** Scrollable `TechnologyPanel` containing the researched-tech grid and the four research slot cards per § Slot behaviour. Wrapped in a 16 dp padded `SingleChildScrollView` so long content scrolls within the body area below the top bar.
- **Tree tab:** Full-bleed `TechTreeWidget` (no inner padding) so the DAG visualization fills the available height.

Slots tab content: vertical list of slot rows (label, assigned tech + progress, Cancel / Choose tech). Choose-tech opens the dark editorial-monocle Choose-tech dialog (see § Choose-tech dialog) listing researchable techs only.

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| Technology route | Player opens Technology → Slots tab | Research slots panel visible. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Choose tech | Slot empty or re-assign | Opens filtered tech list | Assigns `ResearchOrder` on select. |
| Cancel | Slot assigned | Clears slot order | Progress lost on resolution per research-resolution. |

---

## States and variants

| Variant | Trigger | Render difference |
|---------|---------|-------------------|
| Empty chooser | No researchable techs | Message "No techs available to research". |
| Assigned slot | `ResearchOrder` present | Shows tech id + progress. |

---

## Components

- Technology screen widgets, choose-tech dialog, [tech-tree-widget.md](tech-tree-widget.md).

---

## Widgetbook

Folder: **Tech Tree** — stories for slots tab with fixture player research state.

- **Mid-game (half researched)** — desktop-width `TechnologyScreen` (Slots tab default) with half the catalog unlocked and one in-progress tech.
- **Mid-game slots (mobile)** — same fixture inside the shared `mobileViewport` frame (360 × 640 dp) per `SPEC/ui/mobile-adaptation.md` § 6 (Refs #2870 R22 / S9).

---

## Purpose

- **Placement:** Within the Technology flow (e.g. “Slots” tab). Shows the current player’s researched techs, research progress, and **research slots** for assigning techs to research.
- **Assignment:** Each slot allows the user to assign one tech to research (or clear the slot). The list of techs offered when choosing must be **researchable only** (prerequisites and discovery rules satisfied).

## Researchable set (assignment list)

The techs **choosable** for a slot are exactly:

- **Researchable:** Same rule as the tech tree: all tech prerequisites in the player’s `techUnlocked`, and for discovery techs (e.g. “Explorer finds Sugar”) the player must have **revealed** the required resource(s) per [tech-tree-new-world.md](../game/tech-tree-new-world.md). Derived via `researchableTechIds(techUnlocked, hasDiscoveredResource: …)` with `hasDiscoveredResource` supplied from game state (e.g. `hasRevealedResourceForPlayer(game, player.id, r)`).
- **Not already assigned:** A tech already assigned to another slot is not offered in the list (no duplicate assignment).
- **Not yet unlocked:** Techs in `techUnlocked` are not offered.

The panel does **not** show locked techs in the assignment list. When there are no choosable techs, the UI shows the message “No techs available to research”.

## Slot behaviour

- **Slots:** The Slots tab always renders exactly four slot cards in slot-index order regardless of `player.researchSlots`. The active slot count remains `player.researchSlots` (default 3; 4 with University); the locked-slot rule below covers the fourth card when the player has not researched University.
- **Locked slot 4 (University):** When `player.researchSlots` is `null` or strictly less than `4`, the fourth slot card renders as a **locked placeholder**:
  - The card body is rendered at exactly `0.45` opacity (the mockup `.slot-card[style="opacity:.45"]` value).
  - The slot header label reads exactly `"Slot 4 (University)"` (no other content in the header).
  - In place of the assigned-tech body / progress / empty-state, the card body shows exactly one footnote line `"Requires University tech"` in `--muted` italic.
  - The card renders no Cancel and no Choose tech action button.
  - The card emits no `ResearchOrder` mutations.
- Each active slot card (indices `0..player.researchSlots - 1`) shows label (e.g. “Slot 1”), assigned tech (if any) with progress, and actions: Cancel (if assigned), Choose tech.
- **Choose tech:** Opens the dark editorial-monocle Choose-tech dialog (see § Choose-tech dialog) listing only the choosable techs (researchable, not in another slot). Selecting a tech assigns it to that slot and closes the dialog.
- **Cancel:** Clears the slot (order removed); progress for that tech is lost on resolution per [research-resolution.md](../program/research-resolution.md).
- **Goal slot:** Out of scope for this spec; only assignment slots are defined here.

## Choose-tech dialog

The Choose-tech dialog is the dark editorial-monocle modal opened by the slot card "Choose tech" button. It is a `CtDialogShell`-based modal (no Material `AlertDialog`/`Dialog`/`showModalBottomSheet`/`ListTile` chrome) and follows the visual contract in `SPEC/ui/mockups/GAME40001-technology-panel.html` `.tech-dialog` / `.dialog-card`:

- **Frame:** `CtDialogShell` default 2 px `--accent-dim` border on all four sides; canonical panel gradient background; `maxWidth = 480` (catalog default).
- **Scrim (barrier):** The modal route `barrierColor` MUST resolve to `EditorialMonoclePalette.dialogScrim` (the `--dialog-scrim` token from `pixel-art-ui-catalog.md` § Dialog scrim). Hard-coded `Colors.black54` or hex literals are regressions.
- **Title row:** Single line `"Choose Tech — Slot N"` (where `N = slotIndex + 1`), rendered in the display font in `--accent`.
- **Option rows (when at least one choosable tech exists):** Vertical column where each option is a tappable row containing:
  - Tech category icon at 22 px (resolved via `techCategoryIconAssetPath`, omitted when null).
  - Tech display name in body font / `--fg` / 600 weight (per mockup `.t-name`).
  - Subtitle line in mono font / `--muted` carrying era, category, and cost in research points (existing `technologyPanel_pickSubtitle` content; rendered in mono / muted style per mockup `.t-cost`).
  - Tapping the row assigns that tech via `applyAssignTechToSlot` and closes the dialog.
- **Empty state (no choosable techs):** Single italic muted line `"No techs available to research"` (existing `technologyPanel_noTechsAvailable`) replaces the option list. The Close button (below) is still rendered.
- **Footer:** A single full-width `CtNinePatchButton` labelled `"Close"` (existing `common_close`) dismisses the dialog without mutating orders.
- **Implementation pin:** `app/lib/features/game/widgets/technology_panel_orders.dart` exposes `showChooseTechDialog(...)` (replacing the legacy `showChooseTechBottomSheet`). The dialog body widget is private to that file or co-located alongside it.

## Data

- **Player:** `Player.techUnlocked`, `Player.researchProgressByTechId`, `Player.researchSlots`.
- **Orders:** `Orders.researchOrdersByPlayerId[playerId]` — list of `ResearchOrder` (slotIndex, techId, funding). Assignment updates this; turn resolution applies it per [research-resolution.md](../program/research-resolution.md).
- **Game:** Required for discovery rule: visibility/revealed resources via `hasRevealedResourceForPlayer(game, player.id, resourceId)`.

## Acceptance criteria

- **Given** the user is on the Technology panel (slots tab) and taps “Choose tech” for a slot, **when** the assignment list is shown, **then** the list contains only techs that are researchable for the current player (all tech prerequisites in `techUnlocked`, and for discovery techs the player has revealed the required resource(s)) and that are not already assigned to another slot.

- **Given** the user is on the Technology panel and opens “Choose tech” for a slot, **when** there are no techs that are both researchable and not already in another slot, **then** the UI shows the message “No techs available to research” and does not list any techs.

- **Given** the user has opened the “Choose tech” list for a slot and the list is filtered to researchable techs only, **when** the user selects a tech from the list, **then** that tech is assigned to the slot, the dialog closes, and the orders are updated so the slot’s `ResearchOrder` has that tech id.

- **Given** the user has assigned tech A to slot 1, **when** the user opens “Choose tech” for slot 2, **then** tech A does not appear in the list for slot 2 (no duplicate assignment).

- **Given** the Technology panel is shown with a game that has world state and visibility, **when** the assignment list is computed, **then** discovery techs (e.g. discovery_of_sugar) are included only if the player has revealed the corresponding resource(s), using the same rule as the tech tree (`hasRevealedResourceForPlayer`).

- **Given** the Slots tab is rendered for any player, **when** the slot list is computed, **then** the UI layer renders exactly four slot cards in slot-index order regardless of `player.researchSlots`.

- **Given** `player.researchSlots` is `null` or strictly less than `4`, **when** the fourth slot card is rendered, **then** the UI layer renders the card body at opacity `0.45`, sets the header label to exactly `"Slot 4 (University)"`, shows exactly the footnote line `"Requires University tech"` in place of any assigned-tech / progress / empty-state content, and renders no Cancel and no Choose tech button on that card.

- **Given** `player.researchSlots` is greater than or equal to `4`, **when** the fourth slot card is rendered, **then** the UI layer renders the card at full opacity (not the locked `0.45`), uses the standard slot label `"Slot 4"`, and renders Cancel (when assigned) and Choose tech buttons as on the other active slots.

- **Top bar present (dark chrome):** **Given** the Technology screen is mounted for the viewed player on any viewport, **when** the screen builds its chrome, **then** the UI layer renders a `CtTopBar` instance above the body whose `title` equals `"Technology"`, whose `backButtonLabel` equals `"Map"`, and whose leading `icon` is the pixel-art asset `assets/icons/32/ui_icon_technology.png` sized 18 × 18 logical px (no fallback to the legacy `CtScreenShell` parchment chrome).

- **Top bar Material ban (regression guard):** **Given** the Technology screen is mounted on any viewport, **when** the widget tree is inspected, **then** the technology surface contains no Material `TabBar`, `Tab`, `Divider`, or `AppBar` widgets (catalog ban per `SPEC/ui/pixel-art-ui-catalog.md`).

- **Top bar Slots/Tree toggle present:** **Given** the Technology screen is mounted, **when** the top bar trailing slot builds, **then** the UI layer renders exactly two pixel-art toggle chips inside the `CtTopBar.trailing` slot in the order `Slots`, `Tree`, each tappable, and each carrying a stable key (`TechnologyScreen.slotsToggleKey`, `TechnologyScreen.treeToggleKey`) so widget tests can locate them without coupling to localized strings.

- **Slots is the default tab:** **Given** the Technology screen is first mounted, **when** the body builds, **then** the UI layer renders a `TechnologyPanel` (Slots body) and renders no `TechTreeWidget` until the player taps the Tree toggle.

- **Tree toggle swaps the body:** **Given** the Technology screen is mounted with the Slots tab active, **when** the player taps the `Tree` toggle chip in the top bar trailing slot, **then** the UI layer unmounts the `TechnologyPanel` and renders `TechTreeWidget` in the body; tapping the `Slots` toggle chip again restores the `TechnologyPanel` and unmounts the `TechTreeWidget`.

- **Given** the user is on the Technology panel and taps "Choose tech" for slot index `N - 1` (`N` in `1..4`), **when** the modal is shown, **then** the UI layer mounts a `CtDialogShell` modal whose route `barrierColor` is exactly `EditorialMonoclePalette.dialogScrim`, and renders the title row `"Choose Tech — Slot N"`. The UI layer mounts no Material `AlertDialog`, `Dialog`, `showModalBottomSheet`, or `ListTile` chrome on this route.

- **Given** the Choose-tech dialog is shown for a slot and the choosable-tech list is empty (no techs both researchable for the player and not already assigned to another slot), **when** the dialog body is rendered, **then** the UI layer renders exactly the line `"No techs available to research"` and a single `"Close"` `CtNinePatchButton`, and renders no option rows.

- **Given** the Choose-tech dialog is shown for a slot and the choosable-tech list is non-empty, **when** the user taps the `"Close"` `CtNinePatchButton`, **then** the UI layer pops the dialog route, the player's `Orders.researchOrdersByPlayerId` are unchanged, and no `ResearchOrder` mutation is dispatched via `onOrdersChanged`.

## Integration

- **Source of truth:** [tech-tree.md](../game/tech-tree.md), [research-state.md](../game/research-state.md), [tech-tree-new-world.md](../game/tech-tree-new-world.md). Resolution: [research-resolution.md](../program/research-resolution.md).
- **Consistency:** Assignment list uses the same `researchableTechIds` and discovery callback as the tech tree widget and order suggestion logic.
