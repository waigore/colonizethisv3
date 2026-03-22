# Town and Port Icons — SPEC/ui/town-port-icons.md

**SPEC/ui** — Pixel art icons for towns and ports on the map widget. Renders town/port indicators as tappable 32×32 pixel art icons positioned at the town's tile location. Tapping an icon emits `OpenProvinceDetailPanelEvent` via the app event bus for decoupled province selection. Replaces the legacy blue-square port markers.

---

## Overview

Towns and ports are displayed as distinct 32×32 pixel art icons on the map. Each icon is tappable and triggers province selection via the app event bus.

| Icon Type | Description | Asset File |
|-----------|-------------|------------|
| **Port** | Harbor/port icon | `ui_icon_com_port.png` |
| **Inland Town** | Town/village icon (no port access) | `ui_icon_com_town_inland.png` |
| **Coastal Town** | Town with port access | `ui_icon_com_town_coastal.png` |

---

## Asset Files

Icons are stored in `app/assets/icons/` following the existing resource icon naming convention.

| Icon | File | Description |
|------|------|-------------|
| Port | `ui_icon_com_port.png` | Harbor with ships/anchors |
| Inland Town | `ui_icon_com_town_inland.png` | Village/house cluster |
| Coastal Town | `ui_icon_com_town_coastal.png` | Town with port/water indication |

### Asset Requirements

- **Format:** 32×32 PNG with RGBA transparency
- **Style:** Colonial-era pixel art matching `ui_icon_com_*.png` resource icons
- **Background:** Transparent (no circular badge or background shape)
- **Positioning:** Icons render at native 32×32 resolution, positioned at the town's tile center

---

## Rendering

### Position

Icons are rendered at the tile coordinate specified by `province.townTileKey`:
- `cx = townTileX * cellSize + cellSize / 2`
- `cy = townTileY * cellSize + cellSize / 2`
- Icon is centered on this point (16×16 offset from center)

### Visibility

- Icons are subject to tile visibility rules (visible/fogged/unrevealed) same as resource icons
- Fogged tiles render icons at reduced opacity
- Unrevealed tiles show no icon

### Layer Order

Icons are rendered in the same layer as capitals and warp zone indicators:

1. Base tiles (terrain)
2. Resource icons
3. Improvement/road labels
4. Province/sea zone borders
5. Hover province glow
6. Political faction borders
7. **Capitals** (gold circles - unchanged)
8. **Towns and Ports** (pixel art icons - this spec)
9. Warp zone indicators
10. Hover selector
11. Valid tile glow / highlighted tile

### Icon Selection Logic

For each province with a town (`province.townTileKey != null`):

```
IF province.isPort (has port facility):
  → Render `port` icon
ELSE IF province.isCoastal (touches sea but no port):
  → Render `town_coastal` icon
ELSE:
  → Render `town_inland` icon
```

**Field definitions:**
- `isPort`: Province has a port facility (province id appears in `portsByProvinceSeaboard`).
- `isCoastal`: Province touches sea (has P<->S edge in topology) but is not a port.

### Port Marker Change

The legacy blue filled square port markers (`_paintPorts` method) are **removed**. Port rendering is now handled exclusively by the `port` icon on provinces that have ports.

---

## Interactivity

### Tap Behavior

When the user taps a town or port icon:

1. The map widget emits `OpenProvinceDetailPanelEvent(provinceId)` via `AppEventBus`
2. The event carries the **prefixed province id** (e.g., `"oldWorld|p1"`)
3. No callback is used for this communication — event bus only

### Hit Testing

- Tap hit testing for icons uses a radius of `cellSize / 2` around the icon center
- If tap is within icon hit radius AND on a tile with `townTileKey`, emit selection event
- Icons do not block province tap selection on the same tile

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

- **Given** a province with `townTileKey` set that is a port (has port facility), **when** the map renders, **then** the `port` icon is displayed at the town's tile position.
- **Given** a province with `townTileKey` set that is coastal (touches sea but no port), **when** the map renders, **then** the `town_coastal` icon is displayed at the town's tile position.
- **Given** a province with `townTileKey` set that is inland (does not touch sea), **when** the map renders, **then** the `town_inland` icon is displayed at the town's tile position.
- **Given** a province without a town (`townTileKey` is null), **when** the map renders, **then** no town icon is displayed for that province.
- **Given** a map widget in player-constrained visibility mode, **when** a town icon is on a fogged tile, **then** the icon is rendered at reduced opacity.
- **Given** a map widget in player-constrained visibility mode, **when** a town icon is on an unrevealed tile, **then** no icon is rendered.

### Icon Replacement

- **Given** the map renders a port marker, **when** the new pixel art icons are implemented, **then** the legacy blue square port marker is no longer rendered for provinces with ports.
- **Given** the map renders a port, **when** the icon is rendered, **then** the `port` icon visually identifies it as a trade hub.
- **Given** the map renders a coastal town (non-port coastal province), **when** the icon is rendered, **then** the `town_coastal` icon visually distinguishes it from an inland town.

### Interactivity

- **Given** the user taps on a town or port icon, **when** the tap is within the icon's hit radius, **then** the map emits `OpenProvinceDetailPanelEvent` with the correct prefixed province id via `AppEventBus`.
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
- Cache stores `Map<String, Image>` keyed by icon type (`port`, `town_inland`, `town_coastal`)

### Existing Code Changes

1. **`region_map_component.dart`**:
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

- `app/assets/icons/ui_icon_com_port.png`
- `app/assets/icons/ui_icon_com_town_inland.png`
- `app/assets/icons/ui_icon_com_town_coastal.png`
- `AppEventBus` from `colonizethis_models`
