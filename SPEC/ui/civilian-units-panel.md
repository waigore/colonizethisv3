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
- **Desktop / wide viewport:** Panel appears as a side panel (e.g. right side) or bottom sheet so the map remains visible. Max height or scroll so content fits.
- **Mobile / narrow viewport:** Panel appears as a bottom sheet or full-width overlay so it is usable on small screens. See [mobile-adaptation.md](mobile-adaptation.md) for touch targets.

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

- **Given** the user opens the Civilian Units panel on a narrow viewport (e.g. width < 600 dp), **when** the panel is displayed, **then** the UI layer presents the panel in a layout appropriate for mobile (e.g. bottom sheet or full-width overlay) per [mobile-adaptation.md](mobile-adaptation.md).

---

## Integration

- **In-game shell:** Panel is opened from the Empire overview toolbar; the shell provides current game state and human player id. The shell (or a parent component) owns the map's `highlightedTileKey` state and passes it to the map widget when the user selects a unit in the panel; the shell also requests pan/center and region tab switch.
- **Map widget:** [map-widget.md](map-widget.md). Must support a `highlightedTileKey` (or equivalent) prop for tile highlight and a way to request "center on tile" (e.g. `centerOnTileKey` or callback); see [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md).
- **Game model:** [civilian-units.md](../game/civilian-units.md), [world-model.md](../game/world-model.md). Unit roles: colonizethis_data `unit_roles` (e.g. `unitRoleForType`) to determine civilian vs military/naval.
- **Catalog:** Register the Civilian Units panel in the app widget catalog when implemented.

---

## Widgetbook

- **Standalone story:** A Widgetbook use case shows the Civilian Units panel **standalone** (panel only, no map). Uses demo data (e.g. a game with a subset of civilian units) so the list, grouping, status, location (province name + region), and assigned-to content can be reviewed in isolation.
- **With map story:** A Widgetbook use case shows the Civilian Units panel **in tandem with the map**: an actual generated map and initialized game (same as map widget debug mode: `getDebugInitGameResult()`). The story demonstrates opening the panel, listing units grouped by region with province name and region, and clicking a unit to highlight and pan/center the map on that unit's tile and switch region tab when needed.
- **Acceptance criteria (Widgetbook):**
  - **Given** the Widgetbook "Civilian Units Panel" folder is open, **when** the user selects the "Standalone" use case, **then** the UI layer displays only the Civilian Units panel (no map) with demo data, so that layout and row content (status, location as province name + region, assigned-to) can be verified.
  - **Given** the Widgetbook "Civilian Units Panel" folder is open, **when** the user selects the "With map" use case, **then** the UI layer displays the panel alongside a map built from a real generated map and initialized game (`getDebugInitGameResult()`), and clicking a unit row highlights that unit's tile on the map, pans/centers the map on that tile, and switches the region tab if the unit is in the other region.
