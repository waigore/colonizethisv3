# Map Widget (reusable)

**SPEC/ui** — Reusable 2D tile-map component for the Flutter app. Renders one region's map with a base tile layer and optional overlays; viewport sized to the widget; pan and zoom with fixed zoom levels and smooth zooming. Tap/click exposes province selection via callbacks. Implemented as a **Flame** component to support animation of individual tiles and other assets. Data and events align with shared packages and event systems (same as ctterm); this spec is for the app only.

---

## Responsibility

- Display a **full** region map (one region per widget instance).
- **Viewport:** The visible area is the widget's layout size. Map extent is the full 2D tile grid; user pans and zooms to see it.
- **Base layer:** Single 2D tile layer: terrain, resources, improvements, towns, capitals.
- **Overlays:** Political ownership (borders) as a **separate overlay** on top; user can toggle overlay visibility.
- **Interaction:** Pan; fixed zoom levels with smooth zooming; tap/click to select a province (callbacks; province details content TBD elsewhere).
- **Animation:** Widget supports animation of individual tiles and other assets (e.g. highlights, build progress); Flame is the implementation fit.

---

## Layer model

| Layer | Content | Togglable |
|-------|---------|-----------|
| **Base (tile)** | Terrain, resources, improvements, towns, capitals. | Optional per-sublayer if needed; at minimum base is always on. |
| **Political** | Political borders (ownership). Drawn on top of base. | Yes. User can turn political overlay on/off. |

Data source for tiles and ownership: shared view model (e.g. `RegionMapViewData` / game + tile maps per [map-visualization.md](../program/map-visualization.md)). Province and tile identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Viewport, scale, pan, zoom

- **Viewport:** Exactly the size of the map widget in the layout. No intrinsic minimum; parent constrains the widget.
- **Scale:** Fixed scale at any time (e.g. 1 tile = N logical pixels). **Fixed zoom levels:** Only discrete zoom levels are allowed; no free-form scale.
- **Pan:** User can pan to move the visible region over the full map (drag or gesture). Map is larger than viewport when zoomed in.
- **Zoom:** Smooth zooming between fixed zoom levels (e.g. pinch or buttons). Transition is smooth; final scale snaps to a zoom level.
- **Full map:** The component always has the full region map in memory/logic; viewport is a window over it.

---

## Callbacks (contract)

The map widget exposes callbacks so the parent (e.g. Empire overview) can react; it does not define province-detail content.

| Callback | Purpose |
|----------|---------|
| **onProvinceSelected** | Invoked when the user taps/clicks a province (e.g. with prefixed province id). Province details (what to show, where) are defined by the parent/screen; the map widget only reports selection. |
| **onRegionViewChanged** | Optional: viewport or zoom level changed (e.g. for syncing with sidebar or URL). |

Details of what “province details” shows are **not** defined in this spec; the screen that embeds the map defines that. The map widget only supports selection via these callbacks.

---

## Animation

- The widget **supports** animation of individual tiles and other assets (e.g. tile highlight, building animation, unit pulse).
- Implementation uses **Flame** so that per-tile and per-asset animations can be driven by game events or timers without blocking the UI. Animation API (e.g. “play tile animation at tileKey”) is implementation-defined; this spec only requires that the component is built so such animation is feasible.

---

## Layout and reuse

- **Reusable:** The map widget is a single reusable component. It is used by the Empire overview screen (one instance per region when a region is active). It may be reused elsewhere (e.g. debug or other screens) with the same contract.
- **One region per instance:** Each widget instance displays one region's map (e.g. Old World or New World). Region id (or equivalent) is a parameter; data is supplied for that region only.
- **Desktop and mobile:** Same component; parent controls size. On mobile, one region per map with region switching via tabs (see [empire-overview.md](empire-overview.md)).

---

## Acceptance criteria

- **Given** a map widget with a region's data, **when** the widget is laid out, **then** the viewport matches the widget size and shows the base tile layer (terrain, resources, improvements, towns, capitals) at the current zoom level.
- **When** the political overlay is enabled, **then** political borders are drawn on top of the base layer; when disabled, they are not.
- **When** the user pans, **then** the visible portion of the map updates; the full map remains pannable within the fixed scale.
- **When** the user zooms, **then** only fixed zoom levels are used and zooming is smooth between levels.
- **When** the user taps/clicks a province, **then** the widget invokes the provided province-selection callback with an identifier (e.g. prefixed province id); the widget does not render province details itself.
- **Given** the component is implemented with Flame, **then** it is possible to drive per-tile or per-asset animations from external events or timers.

---

## Integration

- **Data:** Uses shared view models and game state (e.g. `RegionMapViewData`, Game, topology, tile maps). See [map-visualization.md](../program/map-visualization.md), [player-view.md](../program/player-view.md) for visibility when needed.
- **Flame/Flutter:** Flame for the map canvas and animations; Flutter for shell and overlays. Per [repo-and-packages.md](../program/repo-and-packages.md): Flame owns game canvas and in-game pixel-art UI; communicate via state and callbacks.
- **Catalog:** Once implemented, register in app widget catalog (e.g. CtRegionMap or similar; category: game/map, Flame component).
