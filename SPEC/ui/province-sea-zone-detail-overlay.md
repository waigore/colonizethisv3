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

- **Max height:** Overlay never occupies more than one-third of the screen height.
- **Desktop / larger screens:** Overlay appears as a side panel (e.g. right side). Content scrolls if needed.
- **Mobile / narrow viewports:** Overlay appears as a bottom sheet. Content is organized in **tabs** (Political, Economic, Military, Civilian, Naval) so each tab fits within the one-third height constraint.
- **Tabs:** Political | Economic | Military | Civilian | Naval. On desktop, tabs may be shown as sections in a single scrollable panel if space allows.

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

- **Ships in port:** Fleets in sea zones adjacent to the province's port(s). Per [ships-and-naval.md](../game/ships-and-naval.md): home fleet and sea-going fleets in the capital port sea zone or other port sea zones count as "in port" at that province. Implementation uses `portsByProvinceSeaboard` and `WorldState.fleets`; see ships-in-port helper in colonizethis_logic.

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

### Widgetbook

- **Given** the Province Overlay Widgetbook story "Standalone — province", **when** the story renders, **then** the overlay displays province content (Political, Economic, Military, Civilian, Naval) with demo data.
- **Given** the Province Overlay Widgetbook story "Standalone — sea zone", **when** the story renders, **then** the overlay displays sea zone content (Political, Naval).
- **Given** the Province Overlay Widgetbook story "With map — province selected", **when** the story renders, **then** the map and overlay appear side by side; the overlay shows the selected province; tapping the map toggles or updates selection.
- **Given** the Province Overlay Widgetbook story "Standalone (mobile)", **when** the story renders, **then** the overlay uses tabs and does not exceed one-third of viewport height.

---

## Integration

- **Map widget:** [map-widget.md](map-widget.md). Uses `onProvinceSelected`; selection may be province or sea zone (regionCellId). Map widget supports `highlightedTileKey` for coordinate hover.
- **Ships in port:** Helper in colonizethis_logic returns fleets in port at a province.
- **Catalog:** Register overlay component in app widget catalog when implemented.
