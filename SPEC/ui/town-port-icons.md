# Town and Port Icons — SPEC/ui/town-port-icons.md

**SPEC/ui** — Pixel art icons for towns and ports on the map widget. Renders **town** icons at `province.townTileKey` and **port** icons at authoritative port tiles from `portsByProvinceSeaboard`, with an offset rule when the port shares a tile with the town or capital. Tapping either icon emits `OpenProvinceDetailPanelEvent` via the app event bus. Replaces the legacy blue-square port markers. Design contract: GitHub [#1361](https://github.com/waigore/colonizethisv3/issues/1361).

---

## Overview

Towns and ports are displayed as distinct pixel art icons on the map when the province has a `townTileKey`. Town and port markers both use 64×64 assets. Port provinces render **two** icons: the town glyph on the canonical town tile and the port glyph on a computed drawable cell (see below).

| Icon Type | Description | Asset File |
|-----------|-------------|------------|
| **Port** | Harbor/port icon | `ui_icon_com_port.png` (64 folder) |
| **Town (all towns)** | Town/village icon for inland and coastal towns | `ui_icon_com_town_inland_64.png` |

---

## Asset Files

Icons are stored in `app/assets/icons/64/` following the existing resource icon naming convention.

| Icon | File | Description |
|------|------|-------------|
| Port | `ui_icon_com_port.png` | Harbor with ships/anchors |
| Town (all towns) | `ui_icon_com_town_inland_64.png` | Upscaled inland village/house cluster |

### Asset and Render Requirements

- **Format:** Town icon is 64×64 PNG with RGBA transparency; port icon is 64×64 PNG.
- **Style:** Colonial-era pixel art matching `ui_icon_com_*.png` resource icons
- **Background:** Transparent (no circular badge or background shape)
- **Positioning:** Town icon renders at 64×64 centered on the town tile; port icon renders at native 64×64.

---

## Rendering

### Position — town icon

On the tile from `province.townTileKey` (same centering as before):
- `cx = townTileX * cellSize + cellSize / 2`
- `cy = townTileY * cellSize + cellSize / 2`

**Town glyph:** always `town_inland_64` for all towns (inland and sea-touching). This applies even when the province is a port (port uses a separate icon).

### Position — port icon (drawable cell)

Authoritative port location comes from `WorldState.portsByProvinceSeaboard` values (tile key `regionId|localProvinceId|x|y`).

1. If the port tile key is **not** equal to `townTileKey` and **not** equal to the faction **capital** tile key for that province (when a capital exists), the port icon is drawn **on the port tile**.
2. If the port tile **equals** `townTileKey` **or** the capital tile key, the port icon is **not** stacked on that land cell. Scan **orthogonal** neighbors of the **town** tile in fixed order **North, East, South, West** and draw on the first cell whose map cell id belongs to a **sea zone** in topology (`seaZoneIds`).
3. If no such sea cell exists, **fall back** to the port tile (co-located with town/capital markers).

Implementation populates `TownMarkerView.portIconX` / `portIconY` when `isPort` is true (`colonizethis_map` `computePortIconCellForMap`).

### View data (`TownMarkerView`)

| Field | Meaning |
|-------|--------|
| `x`, `y` | Town tile (canonical) |
| `provinceId` | **Local** province id (e.g. `p1`) for prefixed bus events |
| `isPort` | Province has a port in `portsByProvinceSeaboard` |
| `isCoastal` | Sea-touching and **not** a port (legacy semantic for tests/tools) |
| `touchesSea` | Province has a P↔S edge; drives **town** coastal vs inland glyph |
| `portIconX`, `portIconY` | Set when `isPort`; drawable cell for **port** sprite |

### Visibility

- Town icon uses visibility of the **town** cell and applies regardless of province ownership (player, AI, unowned), subject only to visibility/fog rules.
- Port icon uses visibility of the **port drawable** cell (typically sea when offset).
- Fogged tiles render icons at reduced opacity; unrevealed tiles show no icon.

### Layer Order

Icons are rendered in the same layer as capitals and warp zone indicators:

1. Base tiles (terrain)
2. Resource icons
3. Improvement/road labels
4. Province/sea zone borders
5. Hover province glow
6. Political faction borders
7. **Capitals** (gold circles - unchanged)
8. **Town** glyphs, then **port** glyphs (ports drawn after towns so the harbor icon reads on top when stacked on fallback)
9. Warp zone indicators
10. Hover selector
11. Valid tile glow / highlighted tile

### Coastal detection (map view builder)

Coastal provinces are derived from topology edges where exactly one endpoint is in `seaZoneIds` from sea-zone nodes (not from string prefixes like `sea`).

### Port Marker Change

The legacy blue filled square port markers (`_paintPorts` method) are **removed**. Port rendering uses the `port` pixel icon at `portIconX`/`portIconY` for provinces with ports.

---

## Interactivity

### Tap Behavior

When the user taps a town or port icon:

1. The map widget emits `OpenProvinceDetailPanelEvent(provinceId)` via `AppEventBus`
2. The event carries the **prefixed province id** (e.g., `"oldWorld|p1"`)
3. No callback is used for this communication — event bus only

### Hit Testing

- A tap resolves to a grid cell; **town hit** if `(x,y)` matches `TownMarkerView.x/y` or **port hit** if it matches `portIconX/portIconY` when `isPort`.
- Port and town hits share the same **`OpenProvinceDetailPanelEvent`** / detail flow (equivalent to tapping the town).

### No Hover State

Unlike resource icons, town/port icons do not have a distinct hover state (scale, brightness change). The province border glow and selector already provide hover feedback.

---

## Event Bus Integration

### New Event

```dart
/// Request to open the province/sea zone detail overlay for [provinceId].
/// Emitted by the map widget when user taps a town or port icon.
/// SPEC/ui/province-sea-zone-detail-overlay.md.
class OpenProvinceDetailPanelEvent extends UIActionEvent {
  const OpenProvinceDetailPanelEvent(this.provinceId);
  final String provinceId;
}
```

### Event Flow

```
[CtRegionMap] tap on town/port icon
    ↓
emit OpenProvinceDetailPanelEvent(provinceId) via AppEventBus
    ↓
[GameMapArea] listens on bus.on<OpenProvinceDetailPanelEvent>()
    ↓
Updates _selectedDetailId via setState()
    ↓
[GameMapCanvasStack] re-renders with new selectedDetailId
    ↓
ProvinceSeaZoneDetailOverlay shown
```

### Coupling

- `CtRegionMap` (Flame component) has NO coupling to `ProvinceSeaZoneDetailOverlay`
- `CtRegionMap` only knows about `AppEventBus` interface
- `GameMapArea` listens to bus and manages state independently
- The event bus is injectable via Riverpod for testing

---

## Acceptance Criteria (Given–When–Then)

### Icon Rendering

- **Given** a province with `townTileKey` and a port whose tile differs from town and capital, **when** the map renders, **then** the `port` icon is at `portIconX/portIconY` matching that port tile and the town glyph is on the town tile.
- **Given** a port whose tile equals **town** or **capital** and an orthogonal sea cell exists in N→E→S→W order from the town tile, **when** the map renders, **then** `portIconX/portIconY` is that sea cell.
- **Given** that co-location case with **no** qualifying sea neighbor, **when** the map renders, **then** `portIconX/portIconY` fall back to the port tile.
- **Given** a province with `townTileKey` that **touches sea** (topology), **when** the map renders, **then** the `town_inland_64` glyph is on the town tile (including port provinces).
- **Given** a province with `townTileKey` that does **not** touch sea, **when** the map renders, **then** the `town_inland_64` glyph is on the town tile.
- **Given** a province with `townTileKey` (player-owned or non-player-owned), **when** the map renders in full visibility mode, **then** a town icon is displayed for that province.
- **Given** a province with `townTileKey` set that is coastal **non-port**, **when** the map renders, **then** `isCoastal` is true on `TownMarkerView` and only the town icon is shown (no port sprite).
- **Given** a province without a town (`townTileKey` is null), **when** the map renders, **then** no town icon is displayed for that province.
- **Given** a non-player province with `townTileKey` in full visibility mode, **when** the map renders, **then** its town icon is displayed.
- **Given** player-constrained visibility mode for a non-player province with `townTileKey`, **when** the town tile visibility is `visible` or `fogged`, **then** the town icon is displayed (fogged styling applies); **when** `unrevealed`, **then** no icon is shown.
- **Given** a map widget in player-constrained visibility mode, **when** a town icon is on a fogged tile, **then** the icon is rendered at reduced opacity.
- **Given** a map widget in player-constrained visibility mode, **when** a town icon is on an unrevealed tile, **then** no icon is rendered.

### Icon Replacement

- **Given** the map renders a port marker, **when** the new pixel art icons are implemented, **then** the legacy blue square port marker is no longer rendered for provinces with ports.
- **Given** the map renders a port, **when** the icon is rendered, **then** the `port` icon visually identifies it as a trade hub.
- **Given** the map renders a coastal town (non-port coastal province), **when** the icon is rendered, **then** it uses the same inland town icon as inland towns.

### Interactivity

- **Given** the user taps the town tile or the port drawable tile for that marker, **when** the tap resolves to that cell, **then** the map emits `OpenProvinceDetailPanelEvent` with the correct prefixed province id via `AppEventBus`.
- **Given** the user taps on a town or port icon, **when** the icon is tapped, **then** no callback is invoked — only the event bus event is emitted.
- **Given** the user taps on a town or port icon, **when** the `AppEventBus` is not connected, **then** the app does not crash (event is fire-and-forget).

### Event Bus Coupling

- **Given** `CtRegionMap` is configured with an `AppEventBus`, **when** a town icon is tapped, **then** `CtRegionMap` has no direct reference to `ProvinceSeaZoneDetailOverlay`.
- **Given** `GameMapArea` listens to `OpenProvinceDetailPanelEvent`, **when** the event is emitted, **then** `GameMapArea` updates its `selectedDetailId` state independently.

---

## Implementation Notes

### Icon Loading

Icons are loaded via the existing `ResourceIconCache` pattern:
- `TownIconCache` singleton for town/coastal icons
- Icons loaded in `onLoad()` of `CtRegionMapComponent`
- Cache stores `Map<String, Image>` keyed by icon type (`port`, `town_inland_64`)

### Existing Code Changes

1. **`region_map_component.dart`** (render parts: `SPEC/program/map-region-map-render.md`):
   - Add `onTownIconTapped` callback parameter
   - Replace `_paintPorts()` with `_paintTowns()` method
   - Add `_getTownAtTile()` helper for tap detection
   - Add `Image` fields for town icons via `TownIconCache`

2. **`ct_region_map.dart`**:
   - Accept `AppEventBus` provider
   - Pass bus to `CtRegionMapComponent`
   - Wire `onTownIconTapped` to emit `OpenProvinceDetailPanelEvent` via bus

3. **`game_map_canvas_stack.dart`**:
   - Accept `AppEventBus` provider
   - Pass bus to `CtRegionMap`

4. **`game_map_area.dart`**:
   - Subscribe to `OpenProvinceDetailPanelEvent` via bus
   - Pass bus to `GameMapCanvasStack`

5. **`app_events.dart`**:
   - Add `OpenProvinceDetailPanelEvent` class

---

## Dependencies

- `app/assets/icons/64/ui_icon_com_port.png`
- `app/assets/icons/64/ui_icon_com_town_inland_64.png`
- `AppEventBus` from `colonizethis_models`
