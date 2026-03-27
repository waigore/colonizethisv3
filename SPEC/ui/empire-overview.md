# Empire Overview (in-game shell)

**SPEC/ui** — Main in-game screen for the Flutter app. Shown after game initialization succeeds. The player sees one or more region maps (tabs), each using the reusable map widget; province selection opens details (content TBD). This screen is the **in-game shell**: from here the player issues orders, ends turn, opens panels, and continues play. Desktop and mobile both use a tab system for regions; on mobile, one region per map (one tab per region).

---

## Purpose

- **Entry:** Reached from Game Initializing screen on success (or from Load Game when loading a save into play).
- **Role:** In-game shell. Map-centric view with region tabs; HUD/sidebar and panels (units, development, production, etc.) are defined by separate specs or later. This spec focuses on the map area and region switching.
- **Map:** Each region has its own map view. The reusable [map-widget](map-widget.md) is used for each; viewport is the widget size; pan, fixed zoom levels, smooth zoom; base layer (terrain, resources, improvements, towns, capitals) plus togglable political overlay; tap/click selects province and triggers a callback. Province details (what to show and where) are to be defined; the map widget only reports selection.

---

## Region tabs

- **Tabs:** One tab per region (e.g. "Old World", "New World"). Selecting a tab shows that region's map in the map area.
- **Desktop:** Tab bar visible; map widget fills the map area for the active region. Layout may include sidebar and HUD (separate spec).
- **Mobile:** One region per map. Same tab system: user switches regions via tabs. Each tab shows the full map widget for that region; no side-by-side regions on small screens. See [mobile-adaptation.md](mobile-adaptation.md) for touch targets and layout.
- **Cargo hold indicator:** In the same control row as the region tabs, the UI shows a non-interactive cargo hold indicator with a crate icon and a numeric value in the exact format `used/capacity` (no spaces). `capacity` is the total cargo holds from all ships in the human player's Home Fleet (`cargoHoldsForHomeFleet`), and `used` is the total overseas resources extracted for that player in the current world state (sum of `computeExtraction(...).overseas` values for the player). The indicator is global (single total, not per-region) and remains visible when switching region tabs.
- **Update contract:** The cargo hold indicator updates only when cargo-relevant game state changes (for example, fleet composition changes or extraction-relevant state changes) through the app's event bus/provider wiring; no animation or interaction is applied.

---

## Map area

- **Content:** One instance of the map widget per active view. When the user switches tabs, the map widget is updated or swapped to show the selected region's map.
- **Layers:** Base tile layer always; **province overlay** (province/sea boundary strokes), **province ownership** (Great Power land tint), and **political** overlay togglable by the user where the shell exposes them (see Map display options). **Base layer display mode** is controlled by a cycle button overlaid at the top-left of the map (see below).
- **Interaction:** Pan, zoom (fixed levels, smooth), tap/click for province selection. Map widget fires `onProvinceSelected`; the Empire overview screen responds (e.g. show province details in a panel or bottom sheet; content TBD).
- **Data:** Region map data from game state / view model (PlayerView or equivalent for human player). Province identity: prefixed id per [world-model-identity.md](../game/world-model-identity.md).

### Base layer display cycle (in-game map only)

- **Overlay:** A single toggle button is overlaid at the **top-left** of the map area. Icon only: pixel-art stacked layers icon (`ui_icon_layer_toggle.png` from [game-toolbar-icons.md](game-toolbar-icons.md)). The button cycles the map's base layer display mode; it is shown only on the in-game Empire overview map, not in Widgetbook or debug map stories.
- **Modes (cycle order):** 1) **terrain only** — no resource or improvement/road letters; 2) **terrain + resources** — resource letters (g, t, i, …) only; 3) **terrain + resources + improvements** — resource letters plus improvement and road labels (I0, R0, …). Each tap advances to the next mode; after the third, the next tap returns to the first.
- **Default at game start:** When the player enters the in-game shell (after init or load), the base layer display mode is **terrain + resources + improvements** (full letters).
- **Spec reference:** [map-widget.md](map-widget.md) § Base layer display mode.

### Home-to-capital button (in-game map only)

- **Overlay:** A second toggle button is overlaid at the **top-left** of the map area, directly **beneath** the base-layer cycle button. Icon only: pixel-art home/flag icon (`ui_icon_home_capital.png` from [game-toolbar-icons.md](game-toolbar-icons.md)). The button is shown only on the in-game Empire overview map, not in Widgetbook or debug map stories.
- **Target:** Always uses the **current human player** (same rule as for visibility and panels). If multiple players are marked `isHuman`, use the first; if none are marked, fall back to the first player in the list.
- **Behavior:** When tapped, the button **switches the active region** (Old World / New World) if necessary so that the map shows the human player's **capital region**, then **centers the camera** on the human player's **capital tile** and moves the **selection/highlight cursor** onto that tile. Capital identity comes from `Player.capitalTile` (tile key format `regionId|provinceId|x|y` per [world-model-identity.md](../game/world-model-identity.md) and [map-visualization.md](../program/map-visualization.md)).

### Map display options button and dialog (in-game map only)

- **Overlay:** A third button is overlaid at the **top-left** of the map area, directly **beneath** the home-to-capital button. Icon only: pixel-art gear icon (`ui_icon_map_options.png` from [game-toolbar-icons.md](game-toolbar-icons.md)). The button is shown only on the in-game Empire overview map, not in Widgetbook or debug map stories.
- **Dialog type:** Tapping the button opens a modal **“Map display options”** dialog that blocks interaction with the underlying map and closes when the user taps the dialog’s **Close** button, taps outside the dialog, or presses the back key.
- **Toggles:** The dialog contains **three** independent toggles (switch or checkbox): **“Show province overlay”** (province and sea-zone boundary strokes only), **“Show province ownership”** (Great Power land ownership tint at fixed alpha **0.65** per [map-widget.md](map-widget.md)), and **“Show province names”**. Each controls its own global layer for all in-game Empire overview maps in the current session (Old World and New World). No toggle affects another unless noted in [map-widget.md](map-widget.md) (e.g. political borders still require the province overlay for underlying strokes).
- **Default behavior:** At the start of a game session (after init or load), **Show province overlay**, **Show province ownership**, and **Show province names** are all **ON** by default. When the user changes any toggle, the new values are remembered for the remainder of the session and are reflected every time the dialog is reopened.
- **Effect on rendering:** When **Show province overlay** is ON, the map widget draws province and sea-zone boundary strokes per [map-widget.md](map-widget.md). When OFF, those strokes are not drawn. When **Show province ownership** is ON, the map draws the Great Power land tint per [map-widget.md](map-widget.md) § Province ownership (GP tint). When OFF, no GP tint is drawn. Hover selectors, hover province glows, capitals, ports, warp zone indicators, and (per the province-names toggle) labels remain according to their own toggles. When **Show province names** is ON, land province labels are drawn per [map-widget.md](map-widget.md) § Layer model (province names row). When OFF, no province name labels are drawn.

---

## Wireframe (conceptual)

```text
+------------------------------------------------------------------+
|  [ Old World ]  [ New World ]   (region tabs)    [ Layers ▼ ] …  |
+------------------------------------------------------------------+
| [r]                                                              |
|     Map widget (viewport = this area)                             |
|     – base: terrain [+ resources + improvements per cycle]       |
|     – overlay: boundaries / ownership tint / political (toggles) |
|     – pan / zoom / tap province                                   |
|     – [r] = base layer cycle (top-left overlay, in-game only)    |
+------------------------------------------------------------------+
|  (HUD / province details / panels — layout and content TBD)       |
+------------------------------------------------------------------+
```

On mobile: same tab row; map area fills available space; one region visible at a time; province details may be bottom sheet or full-screen overlay (TBD).

---

## Acceptance criteria

- **Given** the player has just completed game initialization (or loaded a save into play), **when** the app navigates to the in-game shell, **then** the Empire overview screen is shown with region tabs and the map widget for the active region (e.g. human capital's region first).
- **When** the user selects a different region tab, **then** the map area shows that region's map (one region per map; no side-by-side on mobile).
- **Given** the map widget is visible, **then** the user can pan, zoom (fixed levels, smooth), and toggle the political overlay; tap/click on a province invokes the selection callback and the screen can show province details (details content TBD).
- **Desktop and mobile:** Both use the same tab-based region switching; on mobile, one region per map and tab system only.
- **Given** the in-game shell control row is visible, **when** the UI renders region tabs, **then** the UI layer also renders a non-interactive cargo hold indicator beside the tabs with a crate icon and text formatted exactly as `used/capacity` (no spaces).
- **Given** the in-game shell control row is visible for a human player, **when** the cargo hold indicator is computed, **then** `used` equals the sum of that player's overseas extraction totals in the current world state and `capacity` equals the total home-fleet cargo holds for that player.
- **Given** the player switches between Old World and New World tabs, **when** the region tab changes, **then** the cargo hold indicator value remains a single global total and does not switch to per-region values.
- **Given** fleet composition or extraction-relevant state changes and the app event bus/provider flow publishes those changes into the in-game shell state, **when** the map controls rebuild, **then** the cargo hold indicator updates to the new `used/capacity` value without animation.
- **Given** the player has just entered the in-game shell (after init or load), **when** the map area is first shown, **then** the base layer display mode is terrain + resources + improvements (full letters visible).
- **Given** the Empire overview map is visible, **when** the user taps the base-layer cycle button at the top-left of the map area, **then** the map advances to the next mode in order: terrain only → terrain + resources → terrain + resources + improvements → terrain only (repeating).
- **Given** the Empire overview map is visible, **then** the base-layer cycle button is visible at the top-left of the map area and displays the stacked layers icon (icon-only).

- **Given** the Empire overview map is visible, **then** a second icon-only button with the home/flag icon is visible directly beneath the base-layer cycle button at the top-left of the map area.
- **Given** the Empire overview map is visible and the human player has a defined capital tile, **when** the user taps the h button, **then** the active region switches (if needed) to the human player's capital region and the map centers on the human player's capital tile with the selection/highlight cursor placed on that tile.

- **Given** the Empire overview map is visible, **then** a third icon-only button with the gear icon is visible directly beneath the home-to-capital button at the top-left of the map area.
- **Given** the Empire overview map is visible, **when** the user taps the third map display options button, **then** the UI layer shows a modal dialog titled `Map display options` with a dismiss action and the underlying map is not interactive until the dialog is closed.
- **Given** the Map display options dialog is visible for the first time in a game session, **then** the dialog shows toggle controls labelled `Show province overlay`, `Show province ownership`, and `Show province names`, all in the ON state.
- **Given** the Map display options dialog is visible, **when** the user toggles `Show province overlay` OFF, **then** the UI layer updates the global province-overlay visibility state so that all in-game Empire overview maps stop drawing province and sea-zone boundary strokes until `Show province overlay` is toggled ON again (the Great Power ownership tint is unchanged and follows `Show province ownership`).
- **Given** the user has toggled `Show province overlay` OFF in the Map display options dialog and then closed the dialog, **when** the user reopens the Map display options dialog in the same app session, **then** the `Show province overlay` toggle appears in the OFF state and the in-game maps continue to omit province and sea-zone boundary strokes.
- **Given** the Map display options dialog is visible, **when** the user toggles `Show province ownership` OFF, **then** the UI layer updates global state so all in-game Empire overview maps stop drawing the Great Power land ownership tint until `Show province ownership` is toggled ON again (boundary strokes are unchanged and follow `Show province overlay`).
- **Given** the user has toggled `Show province ownership` OFF and closed the dialog, **when** they reopen the Map display options dialog in the same session, **then** the `Show province ownership` toggle appears OFF and maps continue to omit the GP land tint.
- **Given** the Map display options dialog is visible, **when** the user toggles `Show province names` OFF, **then** the UI layer updates global state so all in-game Empire overview maps stop drawing land province name labels until the toggle is ON again.
- **Given** the user has toggled `Show province names` OFF and closed the dialog, **when** they reopen the dialog in the same session, **then** the `Show province names` toggle appears OFF and maps continue to omit province name labels.
- **Given** `Show province overlay` is OFF and `Show province names` is ON, **when** the map renders, **then** province name labels are still visible (no dependency on the province overlay toggle).
- **Given** `Show province ownership` is OFF and `Show province names` is ON, **when** the map renders, **then** province name labels are still visible (no dependency on the province ownership toggle).

---

## Integration

- **Map widget:** [map-widget.md](map-widget.md). Reusable Flame component; this screen supplies data and handles `onProvinceSelected` (and optional `onRegionViewChanged`).
- **Data and events:** Same packages and event systems as ctterm (colonizethis_logic, colonizethis_models, etc.). PlayerView or equivalent for human-player visibility. Game events may drive map updates or animations; see [game-events.md](../program/game-events.md) when wiring.
- **HUD, panels, orders:** Turn controls, unit panels, development, production, etc. are specified in [empire-buttons.md](empire-buttons.md) (toolbar actions) and [in-game-shell-narrow.md](in-game-shell-narrow.md) (narrow viewport: side menu, top bar). This spec defines the map-centric layout and region tabs.
- **Catalog:** Empire overview is a screen; map widget is registered as a reusable component. Register this screen in the app widget catalog when implemented.
