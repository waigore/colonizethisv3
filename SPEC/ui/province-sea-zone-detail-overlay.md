# Province and Sea Zone Detail Overlay

**SPEC/ui** — Detail overlay shown when the user selects a province or sea zone on the map. Integrates with [map-widget.md](map-widget.md) and [empire-overview.md](empire-overview.md). Province/sea zone identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Purpose

When the user taps/clicks a tile on the map widget, the in-game shell displays a detail overlay for the province (land) or sea zone (water) containing that tile. The overlay shows essential information; it is toggleable (tap again or close button) and responsive (side panel on desktop, bottom sheet with tabs on mobile).

---

## Interaction

- **Open:** User taps/clicks a province or sea zone on the map. The overlay appears and stays open.
- **Close:** User taps the close button, or taps the same province/sea zone again to toggle the overlay closed.
- **Switch:** Tapping a different province/sea zone updates the overlay content to the new selection.
- **Hover:** When the overlay is open, hovering over the map immediately updates the overlay to show the hovered province and, in the Tile section, the hovered tile’s details (coordinates, terrain, resources, prospected, improvements, roads/railroads, civilian units in province).
- **Data context:** All data is from the human player's view (visibility, prospecting, etc.).

---

## Layout and Responsiveness

- **Max height:** Overlay never occupies more than one-third of the screen height in the main game shell; Widgetbook map+overlay mock may use a fixed fraction (e.g. bottom half of the story area) to clearly demonstrate the interaction.
- **Desktop / larger screens:** In the main game shell, overlay appears as a side panel (e.g. right side). Content scrolls if needed.
- **Mobile / narrow viewports:** Overlay appears as a bottom sheet on top of the map. Content is organized in **tabs** (Political, Economic, Military, Civilian, Naval) so each tab fits within the one-third height constraint.
- **Tabs:** Political | Economic | Military | Civilian | Naval. On desktop, tabs may be shown as sections in a single scrollable panel if space allows; in Widgetbook, the "With map" story uses a simple bottom overlay to showcase interaction rather than full tab chrome.

---

## Province Overlay Content

### Tile (hovered tile details)

When the user hovers a tile on the map (with overlay open), this section shows that tile’s information. When no tile is hovered, it shows “Hover a tile to see details.”

- **Tile coordinates:** (x, y) in the region grid.
- **Terrain type:** From the tile map (e.g. plains, forest, hills).
- **Resource:** Resource id on that tile (or —).
- **Prospected:** Yes/no for the human player.
- **Improvement:** Improvement name and level (e.g. Farm L2) or —.
- **Road / railroad:** Road level (none, primitive, improved, port or railroad).
- **Civilian units (province):** Count of civilian units in the tile’s province.

#### Visibility and obfuscation (player-constrained views)

When the map widget is in **player-constrained visibility mode** and the overlay is driven by a tile or province that the human player has never seen, the overlay must obfuscate details rather than leaking information:

- **Per-tile (Tile section):**
  - For tiles whose `CellViewData.visibility` is `visible` or `fogged`, the Tile section shows full details as listed above.
  - For tiles whose `CellViewData.visibility` is `unrevealed`, the Tile section still shows the heading "Tile" but replaces all data fields (coordinates, terrain, resource, prospected, improvement, road/railroad, civilian units in province) with the literal placeholder text `???`.
- **Per-province (all sections):**
  - A province is treated as **fully unrevealed** when every tile in that province (all cells where `regionCellId` equals the province’s local id) has `visibility == TileVisibility.unrevealed` in the current `RegionMapViewData`.
  - When a fully unrevealed province is selected, the overlay may still open (taps are allowed), but all content sections (Tile, Political, Economic, Military, Civilian, Naval) must replace data values with the literal placeholder text `???` while still indicating that a province is selected.
  - Provinces that contain at least one tile with visibility `visible` or `fogged` are treated as **known**; the overlay shows full data for those provinces.

### Political

- Province name (or prefixed id fallback)
- Owner (Great Power, Minor Nation, Tribe, or "Unclaimed")

### Economic

- **Resources available:** List of resource ids present on tiles in the province (from `WorldState.resourceByTileKey` and `tileKeysByRegionAndProvince`).
- **Tiles yet to be prospected:** Count and list of tile coordinates `(x, y)` for mineral tiles (iron, copper, tin, coal, silver, gold, gems, diamonds) that are not in `playerProspectedTiles[humanPlayerId]`.
- **Improvements built:** List of tile coordinates `(x, y)` with improvement level > 0; show improvement type (Farm, Mine, etc.) and level per [extraction-and-improvements.md](../game/extraction-and-improvements.md) naming.
- **Improvements available:** List of tile coordinates `(x, y)` where the human player can build (tile has resource, improvement level < 4, tech allows, connectivity). Hover over a coordinate shows a secondary cursor/highlight on the map over that tile.

### Military

- **Regiments present:** Units in the province where `unitRoleForType(u.type) == UnitRole.military`. Show type and count (or list).

### Civilian

- **Civilian units present:** Units in the province that are not military (Explorer, Builder, Engineer, etc.). Show unit type, id, and **status** (idle, working, done; from `Unit.status` and `currentWork` if present).

### Naval

- **Ships in port:** Fleets that are **in port at this province** (attached to the province per [ships-and-naval.md](../game/ships-and-naval.md)). Implementation uses `Fleet.inPortAtProvinceId` (or equivalent); see ships-in-port helper in colonizethis_logic that returns fleets whose in-port province matches the selected province.

---

## Sea Zone Overlay Content

Similar structure where applicable:

- **Political:** Sea zone id/name (or prefixed id).
- **Economic:** N/A for sea zones.
- **Military:** N/A (land units only).
- **Civilian:** N/A.
- **Naval:** Fleets in this sea zone (owner, ship types, mission).

---

## Tile Coordinate Hover

When the overlay lists tile coordinates (e.g. improvements built/available), hovering over a coordinate entry causes a **secondary highlight** on the map: a cursor or outline appears over the corresponding tile. The map widget must support an optional `highlightedTileKey` (or `highlightedTileX`, `highlightedTileY`) prop and render the highlight. The overlay passes the hovered coordinate to the parent, which updates the map's highlight.

---

## Acceptance Criteria

- **Given** the user taps a province on the map, **when** the overlay is not shown, **then** the overlay appears with province content (Political, Economic, Military, Civilian, Naval).
- **Given** the overlay is shown for a province, **when** the user taps the same province again or the close button, **then** the overlay closes.
- **Given** the overlay is shown, **when** the user taps a different province, **then** the overlay content updates to the new province.
- **Given** the user taps a sea zone, **when** the overlay is not shown, **then** the overlay appears with sea zone content (Political, Naval).
- **Given** the overlay lists tile coordinates, **when** the user hovers over a coordinate, **then** a secondary highlight appears on the map over that tile.
- **Given** a mobile viewport, **when** the overlay is shown, **then** it appears as a bottom sheet with tabs and does not exceed one-third of screen height.
- **Given** a desktop viewport, **when** the overlay is shown, **then** it appears as a side panel.

- **Given** the map widget is in player-constrained visibility mode and the user hovers a tile whose `CellViewData.visibility` is `unrevealed`, **when** the overlay’s Tile section is rendered, **then** the UI layer shows the heading "Tile" and replaces all Tile data fields (coordinates, terrain, resource, prospected, improvement, road/railroad, civilian units in province) with the literal text `???`.

- **Given** the map widget is in player-constrained visibility mode and the user taps a province where every tile in that province has `CellViewData.visibility == TileVisibility.unrevealed`, **when** the overlay is shown for that province, **then** the UI layer displays all content sections (Tile, Political, Economic, Military, Civilian, Naval) with data values obfuscated as `???` while still indicating that a province is selected.

- **Given** the map widget is in player-constrained visibility mode and the user taps a province that contains at least one tile with `CellViewData.visibility` equal to `visible` or `fogged`, **when** the overlay is shown for that province, **then** the UI layer displays full province content (Political, Economic, Military, Civilian, Naval) without replacing values with `???`.

### Widgetbook

- **Given** the Province Overlay Widgetbook story "Standalone — province", **when** the story renders, **then** the overlay displays province content (Political, Economic, Military, Civilian, Naval) with demo data.
- **Given** the Province Overlay Widgetbook story "Standalone — sea zone", **when** the story renders, **then** the overlay displays sea zone content (Political, Naval).
- **Given** the Province Overlay Widgetbook story "With map — province selected", **when** the story renders, **then** the map fills the story area and, when a province is selected, a province detail overlay appears as a bottom sheet covering roughly the lower half of the map; tapping the same province again or the close button hides the overlay; tapping a different province updates the overlay content.
- **Given** the Province Overlay Widgetbook story "Standalone (mobile)", **when** the story renders, **then** the overlay uses tabs and does not exceed one-third of viewport height.

---

## Integration

- **Map widget:** [map-widget.md](map-widget.md). Uses `onProvinceSelected`; selection may be province or sea zone (regionCellId). Map widget supports `highlightedTileKey` for coordinate hover.
- **Ships in port:** Helper in colonizethis_logic returns fleets that are in port at a province (attachment: `inPortAtProvinceId` equals that province).
- **Catalog:** Register overlay component in app widget catalog when implemented.
