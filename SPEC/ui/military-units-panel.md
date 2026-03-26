# Military Units Panel

**SPEC/ui** — Panel that lists all regiments and ships owned by the human player, grouped in a single tree by region then by province (land) or sea zone (naval). Supports locating each entry on the map. Integrates with [empire-overview.md](empire-overview.md), [map-widget.md](map-widget.md). Game model: [military-units.md](../game/military-units.md), [ships-and-naval.md](../game/ships-and-naval.md), [world-model.md](../game/world-model.md). Province identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Purpose

The military units panel gives the player a single place to see every regiment and ship they control: aggregated by type with count, plus medals (regiments), status, and location. The tree mixes land (provinces with regiment types) and naval (sea zones with ship types). Selecting a row centers the map on the province's town tile (land) or a port tile adjacent to the sea zone (naval), and switches the region tab if needed.

---

## Scope: what is shown

- **Regiments:** All units owned by the human player that are **military** per the game model (`unitRoleForType(unit.type) == UnitRole.military`). Sourced from `WorldState` for all regions (`oldWorld.units`, `newWorld.units`). Grouped by region, then by province; within each province, **one row per regiment type** with **count** (e.g. "Musketeers: 2").
- **Ships:** All fleets owned by the human player from `WorldState.fleets`. Grouped by region, then by **sea zone**; within each sea zone, **one row per ship type** with **count** (e.g. "Carrack: 2"). Count is the number of ships of that type in that sea zone (sum across fleets in that zone).
- **Excluded:** Civilian units, units or fleets owned by other players or Minor Nations/Tribes.

---

## Panel placement and opening

- **Access:** The panel is opened from the in-game shell **toolbar** via a dedicated button (e.g. "Military Units"), in the same way as the Civilian Units panel.
- **Desktop / wide viewport:** Panel appears as a side panel or bottom sheet so the map remains visible. Max height or scroll so content fits.
- **Mobile / narrow viewport:** Panel appears as a bottom sheet or full-width overlay per [mobile-adaptation.md](mobile-adaptation.md).
- **Train button:** Header includes a **Train** button in the same position/pattern as [civilian-units-panel.md](civilian-units-panel.md). On tap, the panel route is popped and the UI layer emits `OpenDialogEvent(trainMilitaryDialogId)` to open [train-military-dialog.md](train-military-dialog.md).

---

## Tree structure and grouping

- **One tree:** Units are shown in a **single tree** that mixes land and naval. Top level: **region** (e.g. Old World, New World). Under each region: **location nodes** — either **provinces** (for regiments) or **sea zones** (for fleets). Under each province: **regiment-type rows** (type name + count). Under each sea zone: **ship-type rows** (type name + count).
- **Order:** Within a region, locations are listed in a stable order (e.g. province/sea zone by display name or id). Within a province or sea zone, type rows are in a stable order (e.g. by type id). No user-facing sort or filter controls.

---

## Per-row content

**Regiment row (under a province):**

| Field    | Source | Notes |
|----------|--------|--------|
| **Type** | Unit type id | Human-readable regiment name (e.g. "Musketeers"). |
| **Count**| Aggregated | Number of regiments of this type in this province. |
| **Medals** | `Unit.medals` | Shown for experience (0–4). When multiple units: show range (e.g. "0–2") or single value if all same. |
| **Status** | `Unit.status` | One of: Idle, Working, Done. When multiple units: show one representative (e.g. if any Working, show "Working"). |

**Ship row (under a sea zone):**

| Field    | Source | Notes |
|----------|--------|--------|
| **Type** | Ship type id | Human-readable ship name (e.g. "Carrack"). |
| **Count** | Aggregated | Number of ships of this type in this sea zone. |
| **Status** | `Fleet.mission` | None, Patrol, Blockade, Beachhead, Defend. When multiple fleets in same zone with different missions: show one representative or "Mixed". |

- **Location label:** Each province or sea zone node shows a **location label**: province name + region (land), or sea zone id/name + region (naval). Use province **display name** and region label (e.g. "Old World", "New World"); do not show raw ids to the user where avoidable.
- **Clickable row:** Each regiment-type row and ship-type row is clickable. Clicking triggers **locate**: set map highlighted tile, pan/center the map on the target tile, and switch the active region tab if the location is in a different region.

---

## Map highlight and pan/center on selection

- **Regiments:** The target tile for a province is the **province's town tile**: `Province.townTileKey` when present; otherwise the first tile in that province from `tileKeysByRegionAndProvince` (or equivalent). Always use prefixed province id for lookup per [world-model-identity.md](../game/world-model-identity.md).
- **Ships:** The target tile for a sea zone is a **port tile adjacent to that sea zone**: any tile key from `WorldState.portsByProvinceSeaboard` whose key corresponds to that sea zone (e.g. key format `fullProvinceId|seaZoneId`; match sea zone part). If multiple ports border the zone, use the first deterministically.
- **When** the user clicks a row, **then** the UI layer: (1) sets the map's **highlighted tile** to that tile key; (2) **pans and centers** the map viewport on that tile; (3) **switches the active region tab** to the location's region if it differs from the current tab.
- **Contract:** Same as Civilian Units panel: map widget supports `highlightedTileKey` and `centerOnTileKey` (or callback) so the shell can request pan/center.

---

## Empty state

- When the human player has **no** regiments and **no** ships (no fleets), the panel still opens and shows an empty state message (e.g. "No military units") so the entry point is always available.

---

## Data and identity

- **Province lookup:** Always use prefixed province id (`regionId|localId`) per [world-model-identity.md](../game/world-model-identity.md). Display province **name** (e.g. `Province.displayName`); do not show raw province id to the user.
- **Sea zone:** Fleet has `regionId` and `seaZoneId` (may be prefixed or local). Match to `portsByProvinceSeaboard` keys to resolve a port tile for centering. Display sea zone with region so the player can correlate with the map.

---

## Acceptance criteria

- **Given** the user is on the in-game shell (Empire overview), **when** the user opens the Military Units panel, **then** the UI layer displays a panel that lists all regiments and ships owned by the human player in a single tree grouped by region, then by province (regiments) or sea zone (ships), with one row per regiment type or ship type showing type name, count, and (for regiments) medals and status, and (for ships) mission as status.

- **Given** the Military Units panel is open and the user clicks a regiment-type row under a province, **when** a town tile (or first tile) for that province can be resolved, **then** the UI layer sets the map's highlighted tile to that tile key, pans and centers the map on that tile, and switches the active region tab to the province's region if it differs from the current tab.

- **Given** the Military Units panel is open and the user clicks a ship-type row under a sea zone, **when** a port tile adjacent to that sea zone can be resolved from `portsByProvinceSeaboard`, **then** the UI layer sets the map's highlighted tile to that tile key, pans and centers the map on that tile, and switches the active region tab to the sea zone's region if it differs from the current tab.

- **Given** the human player has zero regiments and zero ships (no fleets), **when** the panel is displayed, **then** the UI layer shows an empty state message (e.g. "No military units") and does not show any tree content.

- **Given** the panel is displayed with at least one region containing provinces with regiments or sea zones with ships, **when** the user views the tree, **then** the UI layer shows region headings, under each region location nodes (province name + region, or sea zone + region), and under each location type rows with type name, count, and status (and medals for regiments).

- **Given** the user opens the Military Units panel on a narrow viewport (e.g. width < 600 dp), **when** the panel is displayed, **then** the UI layer presents the panel in a layout appropriate for mobile per [mobile-adaptation.md](mobile-adaptation.md).

- **Given** the Military Units panel is open, **when** the user taps the Train button, **then** the UI layer closes the panel and emits `OpenDialogEvent(trainMilitaryDialogId)` so the Train Military dialog opens via `AppEventBus` wiring (the panel does not call `showDialog` directly).

---

## Integration

- **In-game shell:** Panel is opened from the Empire overview toolbar; the shell provides current game state and human player id. The shell owns the map's `highlightedTileKey` and `centerOnTileKey` state and passes them to the map widget when the user selects a row in the panel; the shell also requests pan/center and region tab switch.
- **Map widget:** [map-widget.md](map-widget.md). Same contract as Civilian Units panel for highlight and center-on-tile.
- **Game model:** [military-units.md](../game/military-units.md), [ships-and-naval.md](../game/ships-and-naval.md), [world-model.md](../game/world-model.md). Unit roles: colonizethis_data `unitRoleForType` / `isMilitaryUnit`. Fleets: `WorldState.fleets`.
- **Catalog:** Register the Military Units panel in the app widget catalog when implemented.

---

## Widgetbook

- **Standalone story:** A Widgetbook use case shows the Military Units panel **standalone** (panel only, no map). Uses demo data (e.g. a game with a subset of regiments and fleets) so the tree, grouping, type rows, counts, medals, and status can be reviewed in isolation.
- **With map story:** A Widgetbook use case shows the Military Units panel **in tandem with the map**: an actual generated map and initialized game (same as map widget debug mode: `getDebugInitGameResult()`). The story demonstrates opening the panel, listing the tree (regions, provinces/sea zones, type rows), and clicking a regiment row or ship row to highlight and pan/center the map on the province town tile or sea-zone port tile and switch region tab when needed.
- **Acceptance criteria (Widgetbook):**
  - **Given** the Widgetbook "Military Units Panel" folder is open, **when** the user selects the "Standalone" use case, **then** the UI layer displays only the Military Units panel with demo data, so that tree layout and row content (type, count, medals, status) can be verified.
  - **Given** the Widgetbook "Military Units Panel" folder is open, **when** the user selects the "With map" use case, **then** the UI layer displays the panel alongside a map built from a real generated map and initialized game (`getDebugInitGameResult()`), and clicking a regiment-type or ship-type row highlights the corresponding tile on the map, pans/centers the map on that tile, and switches the region tab if the location is in the other region.
