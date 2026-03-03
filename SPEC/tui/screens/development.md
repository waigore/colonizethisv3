# Development Screen

**SPEC/tui/screens/development.md** — TUI-specific Development screen per SPEC/tui/ctterm.md.

**Screen ID:** 100009

## Overview

Development screen for managing civilian unit work orders (Builders, Engineers). Displays working units, allows assigning work tasks (improvements, roads, ports, forts, rails), and shows work progress. Reference: [SPEC/program/development-resolution.md](../../program/development-resolution.md), [SPEC/game/civilian-units.md](../../game/civilian-units.md).

## UI/UX

- **Layout:** Split view - civilian unit list on left, work assignment panel on right (or stacked on narrow terminals).
- **Navigation:** Back to In-Game Shell via Escape key.
- **Unit display:** Show civilian units with current work status and progress.
- **Keyboard-first:** All actions via keyboard shortcuts.

## Functionality

### Civilian Unit List Display

- **Given** the user opens the Development screen
- **When** viewing the civilian unit list
- **Then** display each civilian unit showing:
  - Province location (using prefixed province id per SPEC/game/world-model-identity.md)
  - Unit type (Builder, Engineer)
  - Current status (idle/working)
  - Current work target and progress (if working)

### Select Civilian Unit

- **Given** the user is on the Development screen
- **When** they navigate to a civilian unit and select it
- **Then** show detailed information:
  - Unit type and stats
  - Current position
  - Current work (if any) with remaining turns
  - Available work targets for this unit

### Assign Work Order

- **Given** the user has selected an idle civilian unit
- **When** they assign a work order (build_improvement, build_road, build_port, build_fort, build_rail, upgrade_town)
- **Then** the order is validated:
  - Check unit type eligibility for work target
  - Check target tile exists and is owned by player
  - Check terrain eligibility for the work type
  - Check tech prerequisites (e.g., Road Construction for transport level 2)
  - Check material availability (costs deducted on assignment)
- **And** display validation result (accepted/rejected with reason)

### Work Progress Display

- **Given** a civilian unit is working
- **When** viewing the unit in the list
- **Then** show:
  - Work target type
  - Target tile location
  - Progress: remaining turns / total turns
  - Visual indicator of completion percentage

### Cancel Work Order

- **Given** the user has selected a working civilian unit
- **When** they choose to cancel the current work
- **Then** clear the work order:
  - Set status to idle
  - Clear currentWork
  - Note: materials are NOT refunded (per SPEC/program/development-resolution.md)
- **And** update the display

### Work Completion

- **Given** a civilian unit completes its work
- **When** the Build/Work phase resolves
- **Then** the work effect is applied:
  - build_improvement: increase improvement level on tile
  - upgrade_town: increase province town development level
  - build_road: set/upgrade transport level (0→1→2)
  - build_port: create port mapping, set transport level 4
  - build_fort: increase province fort level
  - build_rail: upgrade road to railroad (transport level 4)
- **And** display completion notification via game events

### Order Validation Feedback

- **Given** the user assigns a work order
- **When** the order is validated
- **Then** show feedback:
  - Accepted: work started, materials deducted, visual confirmation with total turns
  - Rejected: error message with reason (e.g., "Invalid: insufficient lumber", "Invalid: Road Construction tech required for level 2 roads")

### Work target summary and map context

- **Given** a civilian unit has an active `WorkOrder` with `target` and `targetTileKey`  
- **When** the user views that unit in the Development screen detail panel  
- **Then** the UI shows a **work target summary row** that includes:  
  - The human-readable work name derived from the work target id (e.g. `Build Improvement`, `Build Fort`)  
  - When known from rules, the structure or improvement being built (e.g. current and next improvement level, or fort level).

- **Given** the Development screen has access to the game’s tile maps  
- **When** a `WorkOrder.targetTileKey` or a candidate target tile is highlighted (during selection)  
- **Then** a **mini map context panel** shows a **resource-layer map** centered on that tile (using the same resources view as the in-game shell), and updates its center whenever the highlighted tile changes.

### Mini-map highlighting and viewport (20×20)

- **Given** the Development screen is in tile-selection mode for an idle civilian unit and a chosen work target  
- **When** the UI renders the mini map context panel for the currently highlighted candidate tile  
- **Then** the mini map uses a **20×20** resources-layer viewport centered on that tile (clamped to the region bounds) so that surrounding tiles, including tiles outside the province, are visible for context.

- **Given** the mini map is showing a 20×20 resources-layer viewport and a candidate tile is highlighted in the tile list  
- **When** the highlighted tile belongs to province `P`  
- **Then** the mini map visually distinguishes tiles as follows:  
  - The highlighted tile’s glyph is drawn with a **bright foreground color**  
  - All other tiles in province `P` are drawn with the **normal map foreground color**  
  - Tiles that are not in province `P` are drawn with a **dim/gray foreground color**, without changing their underlying characters.

- **Given** the UI is in tile-selection mode and the user moves the highlighted tile up or down using ArrowUp/ArrowDown or j/k  
- **When** the highlighted tile changes  
- **Then** the mini map recenters its 20×20 viewport on the new highlighted tile and updates the bright/province/dim coloring in real time.

### Province-first tile selection (TUI)

- **Given** the UI is in tile-selection flow for an idle civilian unit and a chosen work target  
- **When** the system computes candidate tiles  
- **Then** it groups them by province into a list of candidate provinces where each province:  
  - Is owned by the human player  
  - Has at least one eligible tile (full tile key `regionId|provinceLocalId|x|y` that is fully visible to the human player).

- **Given** the UI has grouped candidate tiles by province  
- **When** tile selection begins for a chosen work target and unit  
- **Then** the initially selected province is the builder’s current province when it is in the candidate list, otherwise the first candidate province, and the initially selected tile is the first eligible tile in that province.

- **Given** the UI is in **province selection mode** within tile selection  
- **When** the user presses **ArrowUp/ArrowDown** or **j/k**  
- **Then** the highlighted province moves up or down within the candidate province list, wrapping at the ends, and the highlighted tile index resets to the first tile in the newly selected province.

- **Given** the UI is in province selection mode  
- **When** the user presses **Enter**  
- **Then** the UI switches to **tile selection mode** for the highlighted province, showing only tiles from that province in the tile list.

- **Given** the UI is in tile selection mode for a specific province  
- **When** the user presses **ArrowUp/ArrowDown** or **j/k**  
- **Then** the highlighted tile moves up or down within that province’s tile list, wrapping at the ends, and the mini map context re-centers on the newly highlighted tile.

- **Given** the UI is in tile selection mode for a specific province and a tile is highlighted  
- **When** the user presses **Enter**  
- **Then** the UI creates or updates the current turn’s `Orders` so that the human player’s `workOrdersByPlayerId` contains a `WorkOrder` for that unit with `target` equal to the chosen work target and `targetTileKey` equal to the highlighted tile’s full tile key, and exits back to normal navigation mode.

- **Given** the UI is in tile-selection flow (either province selection mode or tile selection mode)  
- **When** the user presses **Escape**  
- **Then** the UI steps one level back in the flow (tile → province → work-type selection) without changing any existing `WorkOrder`.

### Sliding-window province and tile lists (80×24)

- **Given** the terminal is 80×24 and the UI is in **province selection mode** with more candidate provinces than can visibly fit in the detail panel  
- **When** the user moves the highlighted province up or down using **ArrowUp/ArrowDown** or **j/k**  
- **Then** the province list behaves as a **sliding window**: the highlighted province is always kept within the visible window, and the window scrolls as needed so that the highlight never disappears off-screen.

- **Given** the UI is in province selection mode and the candidate province list is longer than the visible window  
- **When** not all provinces fit on-screen at once  
- **Then** the rendered province list includes textual scroll indicators (for example, a single `...` row at the top and/or bottom) to show that there are additional provinces above or below the visible window.

- **Given** the terminal is 80×24 and the UI is in **tile selection mode** for a specific province with more candidate tiles than can visibly fit in the detail panel  
- **When** the user moves the highlighted tile up or down using **ArrowUp/ArrowDown** or **j/k**  
- **Then** the tile list behaves as a **sliding window**: the highlighted tile is always kept within the visible window, and the window scrolls as needed so that the highlight never disappears off-screen.

- **Given** the UI is in tile selection mode for a specific province and the candidate tile list is longer than the visible window  
- **When** not all tiles fit on-screen at once  
- **Then** the rendered tile list includes textual scroll indicators (for example, a single `...` row at the top and/or bottom) to show that there are additional tiles above or below the visible window.

### Unit-specific Available Work highlighting

- **Given** the user has selected a civilian unit in the Development screen  
- **When** the UI renders the **Available Work** list  
- **Then** it visually distinguishes work targets that are valid for that unit type (e.g. Builder vs Engineer vs Rail Builder) according to `SPEC/game/civilian-units.md`, for example by using a brighter color for allowed targets and a dimmer color for disallowed targets.

- **Given** the user selects a different type of civilian unit (e.g. switching from Builder to Engineer)  
- **When** the Available Work list is re-rendered  
- **Then** the highlighting updates so that only the targets valid for that unit type are shown as available, and other targets remain visible but clearly de-emphasized.

### Work-type and tile selection (TUI)

- **Given** the user has selected an idle civilian unit on the Development screen  
- **When** they view the **Available Work** section in the detail panel  
- **Then** each work target row shows the work name and its hotkey (for example, `[i] Build Improvement`, `[r] Build Road`, `[p] Build Port`, `[f] Build Fort`, `[R] Build Rail`, `[u] Upgrade Town`), and the set of rows highlighted as available depends on the civilian type (Builder, Engineer, Rail Builder).

- **Given** the user has selected an idle civilian unit and the Available Work list is visible  
- **When** the user presses one of the hotkeys **i**, **r**, **p**, **f**, **R**, or **u**  
- **Then** the UI treats this as choosing that work type from the Available Work panel, records the corresponding **work target id** (`build_improvement`, `build_road`, `build_port`, `build_fort`, `build_rail`, or `upgrade_town`) for that unit, and transitions directly into **province-first tile-selection mode** without showing a separate generic \"select work target\" prompt.

- **Given** the UI is in tile-selection mode for an idle civilian unit and a chosen work target  
- **When** the system computes candidate tiles  
- **Then** it builds a list of **candidate tile keys** where each tile:  
  - Has a `targetTileKey` in full format `regionId|provinceLocalId|x|y` per `SPEC/game/world-model-identity.md`  
  - Belongs to a province owned by the human player (province `ownerId` equals the human player id)  
  - Is fully visible to the human player (player visibility map marks the tile as `fullyVisible`).

- **Given** the UI is in tile-selection mode with one or more candidate tiles available  
- **When** the user presses **ArrowUp/ArrowDown** or **j/k**  
- **Then** the currently highlighted candidate tile moves up or down within the candidate list, wrapping at the ends.

- **Given** the UI is in tile-selection mode for an idle civilian unit and a chosen work target, and a candidate tile is highlighted  
- **When** the user presses **Enter**  
- **Then** the UI creates or updates the current turn's `Orders` so that the human player's `workOrdersByPlayerId` contains exactly one new `WorkOrder` for that unit with:  
  - `unitId` equal to the selected unit's id  
  - `target` equal to the chosen work target id  
  - `targetTileKey` equal to the highlighted candidate tile's full tile key `regionId|provinceLocalId|x|y`  
- **And** the UI exits tile-selection mode back to normal navigation mode and shows a one-line confirmation that includes the work target name and the target tile's province name and coordinates.

- **Given** the UI is in tile-selection mode for an idle civilian unit and a chosen work target  
- **When** the user presses **Escape**  
- **Then** the UI exits tile-selection mode and returns to **work-type selection mode** for the same unit without changing any `WorkOrder`.

## Acceptance Criteria

- [ ] Development screen displays title
- [ ] Civilian units are listed with province, type, status
- [ ] Working units show progress (remaining/total turns)
- [ ] User can select a civilian unit via keyboard
- [ ] Selected unit shows detail panel with work info
- [ ] Available Work section shows each work target with its hotkey (e.g. `[i] Build Improvement`) and highlights only those targets valid for the selected civilian type
- [ ] Pressing a work-target hotkey while an idle civilian is selected immediately starts province-first tile selection for that work target
- [ ] After choosing a work type, the UI enters tile-selection mode and shows a list of candidate tiles owned by the human player, with full tile keys `regionId|provinceLocalId|x|y` and each tile row including province name, coordinates, and terrain/resource glyphs
- [ ] In tile-selection mode, ArrowUp/ArrowDown and j/k move the highlighted tile; Enter confirms the target tile and Escape returns to work-type selection without assigning work
- [ ] Confirming a tile creates a WorkOrder for that unit with target equal to the chosen work target id and targetTileKey equal to the chosen tile's full tile key
- [ ] Units with active WorkOrders show non-idle status in the list and display target + target tile in the detail panel
- [ ] Validation feedback from the core logic, when present, is shown as a one-line message describing accepted or rejected work
- [ ] Work target summary row in the detail panel reflects the selected work type and, when known, the structure or improvement being built
- [ ] A mini map context panel is shown when a work target tile is available and centers its **resources-layer** view on the highlighted tile, updating as the highlighted tile changes
- [ ] Tile selection is performed province-first, then tile-within-province, defaulting to the builder’s current province when possible
- [ ] The Available Work list clearly highlights only those work targets that are valid for the currently selected civilian unit type
- [ ] When there are more candidate provinces than fit in the visible window at 80×24, the province list uses a sliding window so that the highlighted province stays visible and shows `...` indicators above and/or below when content is off-screen
- [ ] When there are more candidate tiles than fit in the visible window at 80×24, the tile list uses a sliding window so that the highlighted tile stays visible and shows `...` indicators above and/or below when content is off-screen
- [ ] User can cancel working unit's orders (no refund)
- [ ] Work completion applies correct effect per work type
- [ ] Escape key returns to In-Game Shell
- [ ] Works on narrow terminals (stacked layout fallback)

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Arrow keys / j/k | Navigate civilian unit list |
| Enter / Space | Select unit |
| i | Assign build_improvement order |
| r | Assign build_road order |
| p | Assign build_port order |
| f | Assign build_fort order |
| R | Assign build_rail order |
| u | Assign upgrade_town order |
| x | Cancel current work order |
| Escape | Back to In-Game Shell |

## TUI-Specific Cases

- **Given** the terminal is 80×24
- **When** the user opens the Development screen
- **Then** the panel is shown and the map remains in the shell

- **Given** the terminal is narrow (< 60 columns)
- **When** the user opens the Development screen
- **Then** use stacked layout (unit list above detail panel) instead of split view
