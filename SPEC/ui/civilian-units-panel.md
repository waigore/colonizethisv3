# Civilian Units Panel

**SPEC/ui** — Panel that lists all civilian units under the human player's control and supports locating them on the map. Integrates with [empire-overview.md](empire-overview.md), [map-widget.md](map-widget.md), and [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md). Game model: [civilian-units.md](../game/civilian-units.md), [world-model.md](../game/world-model.md). Province identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Purpose

The civilian units panel gives the player a single place to see every civilian unit they control: status, location (province + region), and current assignment (when not idle). Selecting a unit in the panel highlights that unit's tile on the map, pans/centers the map on it, and switches the region tab if needed so the player sees the unit right away.

---

## Scope: which units are shown

- **Included:** All units owned by the human player that are **civilian** per the game model: Explorer, Builder, Engineer, Spy, Merchant, Rail Builder. Identification uses the same rule as development and TUI (e.g. `unitRoleForType(unit.type)` is not military and not naval; units have `tileKey`).
- **Excluded:** Military regiments and naval units. Units owned by other players or by Minor Nations/Tribes are not shown.
- **Data source:** Units from `WorldState` for all regions (e.g. `oldWorld.units` and `newWorld.units`), filtered by `ownerId == humanPlayerId` and civilian type. Province and region for each unit are derived from `Unit.tileKey` (prefixed format `regionId|provinceId|x|y`).

---

## Panel placement and opening

- **Access:** The panel is opened from the in-game shell **toolbar**, in the same way as the Production panel (e.g. a toolbar button such as "Civilian Units" or "Units" that opens the panel).
- **Presentation:** The panel **appears from the bottom** as a **bottom sheet** that slides up from the bottom edge (same pattern as the province/sea zone detail overlay on narrow viewports; see [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md)). This applies on both desktop and narrow viewports so behaviour is consistent and the map remains visible above.
- **Max height:** Bottom sheet is constrained (e.g. up to one-third of screen height on narrow, or similar cap on wide) so the map stays visible; content scrolls inside the sheet.
- **Mobile / narrow viewport:** Same bottom-sheet presentation; touch targets per [mobile-adaptation.md](mobile-adaptation.md).

---

## Grouping and sort order

- **Group by region:** Units are grouped by region (e.g. Old World, New World). Each group shows a region heading; under it, the list of civilian units in that region.
- **Initial sort:** Within each region, units are listed in a stable order (e.g. by province name then unit type then unit id). No user-facing sort or filter controls; the initial order is sufficient.

---

## Per-unit row content

For each civilian unit, the panel shows:

| Field        | Source | Notes |
|-------------|--------|--------|
| **Status**  | `Unit.status` | One of: `idle`, `working`, `done`. Display as short label (e.g. "Idle", "Working", "Done"). |
| **Location**| `Unit.tileKey` | **Province name only** (no raw id). Province name from game data (e.g. `Province.displayName` for the province derived from `tileKey`). **Always show the region** with the location (e.g. "Old World — London" or "New World — Mexica") so the player knows which map tab the unit is in. |
| **Assigned to** | `Unit.currentWork` when `status == working` | If idle or done: show "—" or "Idle". If working: show work target (e.g. `build_improvement`, `explore`, `prospect`) and target location (province name + region); optionally progress (e.g. "2/5 turns") from `currentWork.remainingTurns` / `totalTurns`. |

- **Unit identity:** Each row is associated with one `Unit` (e.g. `unit.id`). Show unit type (Explorer, Builder, etc.) and a short id or label so the player can tell units apart.
- **Clickable row:** The entire row (or a dedicated "Locate" control) is the click target for "highlight this unit's tile on the map and pan/center to it".
- **Assign (idle only):** For each unit with `Unit.status == idle` and no pending work order for this turn, the row shows an **Assign** button. Clicking it opens a menu of **allowed work orders** for that unit type only (per [civilian-units.md](../game/civilian-units.md) Work Order Summary and `workOrderTargetsByUnitType`). After the user selects an order from the menu, the shell enters **work-target selection mode**: the shell computes valid target tiles once using `getValidWorkOrderTileKeysWithVisibility` (or equivalent), caches the result, and passes it to the map widget. The map shows **valid target tiles** with a **flashing yellow selector** and an **orange hover cursor** (see [map-widget.md](map-widget.md) § Work target selection mode). The user may **switch region tabs** to select a target in the other region. Clicking a **valid** tile commits the work order and exits selection mode. For **province-level** orders (`explore`, `steal_tech`, `counter_spy`), the clicked tile is translated to the province (e.g. `regionId|provinceId|0|0`) per [orders.md](../program/orders.md). **Back-out:** Clicking a non-valid tile, clicking empty area, or clicking the **cancel button** (cross icon overlay on the map) cancels the assignment flow without submitting an order.
- **Cancel (units with work):** For each unit that has either (1) a **pending** work order this turn (in the current orders list) or (2) **in-progress** work (`Unit.status == working`, `Unit.currentWork != null`), the row shows a **Cancel** control. Before cancelling, the UI layer shows a **confirm dialog** (e.g. "Cancel this work order?"). On confirm: **pending** — remove the work order from the player's orders for this turn; **in-progress** — the system clears `Unit.currentWork` and sets `Unit.status` to idle for that unit (no material refund). Implementation of in-progress cancel: see [development-resolution.md](../program/development-resolution.md) and/or [orders.md](../program/orders.md).

---

## Map highlight and pan/center on unit selection

- **When** the user clicks a unit row in the civilian units panel, **then** the UI layer: (1) sets the map's **highlighted tile** to that unit's `tileKey`; (2) **pans and centers** the map viewport so that the unit's tile is visible and centered; (3) **switches the active region tab** to the unit's region if it differs from the current tab.
- **Contract:** The map widget supports `highlightedTileKey` per [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md) and an optional "center on tile" (e.g. `centerOnTileKey` or callback) so the shell can request pan/center when a unit is selected from the panel.
- **Clearing:** Highlight remains until the user selects another unit, selects a province/tile elsewhere, or closes the panel (implementation may keep or clear highlight on panel close).

---

## Empty state

- When the human player has **no** civilian units, the panel still opens and shows an empty state message (e.g. "No civilian units") so the entry point is always available and the behaviour is consistent.

---

## Data and identity

- **Province lookup:** Always use prefixed province id (`regionId|provinceId`) derived from `Unit.tileKey` per [world-model-identity.md](../game/world-model-identity.md). Never use bare province id alone. **Display:** Use province **name** only (e.g. `Province.displayName` from the game's region data); do not show raw province id or prefixed id to the user.
- **Region display:** When showing location, always include the region (e.g. "Old World", "New World") so the player can correlate with the map tabs.
- **Work target labels:** Work targets come from `CurrentWork.workTarget` (e.g. `build_improvement`, `explore`). UI may show human-readable labels (e.g. "Build improvement", "Explore") from a small mapping; raw id is acceptable for MVP.

---

## Acceptance criteria

- **Given** the user is on the in-game shell (Empire overview), **when** the user opens the Civilian Units panel, **then** the UI layer displays a panel that lists every civilian unit owned by the human player (Explorer, Builder, Engineer, Spy, Merchant, Rail Builder), and each row shows that unit's status, location (province name + region), and assigned-to information (or "—" when idle).

- **Given** the Civilian Units panel is open and at least one unit has `Unit.status == working` and `Unit.currentWork != null`, **when** the user views the row for that unit, **then** the UI layer shows the work target (e.g. from `currentWork.workTarget`), the target location (province name + region derived from `currentWork.tileKey`), and optionally progress (e.g. remaining turns / total turns).

- **Given** the Civilian Units panel is open and the human player has zero civilian units, **when** the panel is displayed, **then** the UI layer shows an empty state message (e.g. "No civilian units") and does not show any unit rows.

- **Given** the Civilian Units panel is open and the user clicks a unit row (or a "Locate" control for that unit), **when** that unit has a non-null `tileKey`, **then** the UI layer sets the map's highlighted tile to that unit's `tileKey`, pans and centers the map so that tile is visible and centered, and switches the active region tab to the unit's region if it differs from the current tab.

- **Given** the user has just selected a unit in the Civilian Units panel whose `tileKey` is in region R and the visible map tab is for a different region, **when** the panel triggers locate, **then** the UI layer switches the active region tab to R so the correct map is shown, then applies the highlight and pan/center on that map.

- **Given** the panel lists units from more than one region, **when** displaying each unit's location, **then** the UI layer shows the **province name** (from game data, e.g. `Province.displayName`) and the **region** (e.g. "Old World", "New World"); the UI layer does not show raw province id or prefixed id to the user.

- **Given** the panel is displayed, **when** there are civilian units in more than one region, **then** the UI layer groups units by region with a region heading for each group and lists units within each group in a stable order (e.g. by province name, then unit type, then unit id).

- **Given** the user opens the Civilian Units panel, **when** the panel is displayed, **then** the UI layer presents it as a **bottom sheet** that appears from the bottom edge (slides up), so the map remains visible above; on narrow viewports layout and touch targets follow [mobile-adaptation.md](mobile-adaptation.md).

- **Given** the Civilian Units panel is open and a unit has `Unit.status == idle` and no pending work order for the human player this turn, **when** the user views that unit's row, **then** the UI layer shows an **Assign** button (or equivalent control).

- **Given** the user clicked **Assign** for an idle civilian unit, **when** the order menu is shown, **then** the UI layer displays only work order targets allowed for that unit type (per game model); the user may select one or dismiss the menu.

- **Given** the user opened the Assign menu for a civilian unit, **when** a work target has no valid tiles available for that unit this turn (computed from order suggestions at turn start), **then** the UI layer grays out that work target option and the user cannot select it; valid work targets remain enabled.

- **Given** the user selected a work order from the Assign menu, **when** the shell is in work-target selection mode, **then** the map highlights **valid target tiles** with a flashing yellow selector; the hover cursor changes to orange; the user may switch region tabs; clicking a valid tile submits the work order and exits selection mode; clicking a non-valid tile, empty area, or the cancel button(× overlay) exits selection mode without submitting.

- **Given** province-level orders (`explore`, `steal_tech`, `counter_spy`), **when** the user clicks a tile on the map in work-target selection mode, **then** the UI layer derives the province from the clicked tile key and submits the work order with the canonical province-level tile key (e.g. `regionId|provinceId|0|0`) per orders spec.

- **Given** the Civilian Units panel is open and a unit has a pending work order this turn or has `Unit.status == working` with `Unit.currentWork != null`, **when** the user views that unit's row, **then** the UI layer shows a **Cancel** control.

- **Given** the user clicked **Cancel** for a unit with work (pending or in-progress), **when** the UI layer responds, **then** it first shows a confirm dialog (e.g. "Cancel this work order?"); on confirm, pending work is removed from orders and in-progress work is cleared (unit status idle, currentWork cleared; no refund); on dismiss, no change.

---

## Integration

- **In-game shell:** Panel is opened from the Empire overview toolbar; the shell provides current game state, human player id, and current-turn orders (so the panel can show Assign only for idle units without a pending work order and can add/remove work orders). The shell owns work-target selection mode: when the user selects an order from the Assign menu, the shell **computes valid tile keys once** (using `getValidWorkOrderTileKeysWithVisibility`), **caches the result**, and passes the cached set to the map widget. The shell handles tile click (submit order or back-out). The shell (or a parent component) owns the map's `highlightedTileKey` state and passes it to the map widget when the user selects a unit in the panel; the shell also requests pan/center and region tab switch.
- **Map widget:** [map-widget.md](map-widget.md). Must support a `highlightedTileKey` (or equivalent) prop for tile highlight and a way to request "center on tile" (e.g. `centerOnTileKey` or callback). For work-target selection, the map supports **flashing yellow selectors for valid tiles**, **orange cursor for hover**, **cancel button overlay**, and **onTileSelected** (tile key); click outside valid tiles, click cancel button, or dismiss in panel cancels the flow. Hover events during selection mode update the cursor position but do NOT trigger validation or cancellation. See [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md).
- **Game model:** [civilian-units.md](../game/civilian-units.md), [world-model.md](../game/world-model.md). Unit roles: colonizethis_data `unit_roles` (e.g. `unitRoleForType`) to determine civilian vs military/naval.
- **Catalog:** Register the Civilian Units panel in the app widget catalog when implemented.

---

## Widgetbook

- **Standalone story:** A Widgetbook use case shows the Civilian Units panel **standalone** (panel only, no map). Uses demo data (e.g. a game with a subset of civilian units) so the list, grouping, status, location (province name + region), and assigned-to content can be reviewed in isolation.
- **With map story:** A Widgetbook use case shows the Civilian Units panel **in tandem with the map** with the panel **at the bottom** (same placement as province overlay "With map"): map above, panel below in a column, using a real generated map and initialized game (e.g. `getDebugInitGameResult()`). The story demonstrates: listing units grouped by region with province name and region; clicking a unit to highlight and pan/center the map and switch region tab; **Assign** and **Cancel** flows.
- **As bottom sheet story:** A Widgetbook use case shows a toolbar button that opens the Civilian Units panel as a **modal bottom sheet** (slide up from the bottom), matching in-game shell behaviour.
- **Acceptance criteria (Widgetbook):**
  - **Given** the Widgetbook "Civilian Units Panel" folder is open, **when** the user selects the "Standalone" use case, **then** the UI layer displays only the Civilian Units panel (no map) with demo data, so that layout and row content (status, location as province name + region, assigned-to) can be verified.
  - **Given** the Widgetbook "Civilian Units Panel" folder is open, **when** the user selects the "With map" use case, **then** the UI layer displays the map above and the Civilian Units panel **at the bottom** (bottom placement like province overlay), built from a real generated map and initialized game (`getDebugInitGameResult()`), and the user can locate units, assign work, and cancel work so that the full flow is demonstrable.
  - **Given** the Widgetbook "Civilian Units Panel" folder is open, **when** the user selects the "As bottom sheet" use case and taps the button, **then** the panel opens as a bottom sheet that slides up from the bottom edge.
