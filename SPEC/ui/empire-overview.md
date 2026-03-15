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

---

## Map area

- **Content:** One instance of the map widget per active view. When the user switches tabs, the map widget is updated or swapped to show the selected region's map.
- **Layers:** Base tile layer always; political overlay (borders) togglable by the user (layer controls on this screen or in a shared toolbar).
- **Interaction:** Pan, zoom (fixed levels, smooth), tap/click for province selection. Map widget fires `onProvinceSelected`; the Empire overview screen responds (e.g. show province details in a panel or bottom sheet; content TBD).
- **Data:** Region map data from game state / view model (PlayerView or equivalent for human player). Province identity: prefixed id per [world-model-identity.md](../game/world-model-identity.md).

---

## Wireframe (conceptual)

```text
+------------------------------------------------------------------+
|  [ Old World ]  [ New World ]   (region tabs)    [ Layers ▼ ] …  |
+------------------------------------------------------------------+
|                                                                  |
|                    Map widget (viewport = this area)              |
|                    – base: terrain, resources, improvements,    |
|                      towns, capitals                             |
|                    – overlay: political borders (if enabled)      |
|                    – pan / zoom / tap province                   |
|                                                                  |
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

---

## Integration

- **Map widget:** [map-widget.md](map-widget.md). Reusable Flame component; this screen supplies data and handles `onProvinceSelected` (and optional `onRegionViewChanged`).
- **Data and events:** Same packages and event systems as ctterm (colonizethis_logic, colonizethis_models, etc.). PlayerView or equivalent for human-player visibility. Game events may drive map updates or animations; see [game-events.md](../program/game-events.md) when wiring.
- **HUD, panels, orders:** Turn controls, unit panels, development, production, etc. are specified in [empire-buttons.md](empire-buttons.md) (toolbar actions) and [in-game-shell-narrow.md](in-game-shell-narrow.md) (narrow viewport: side menu, top bar). This spec defines the map-centric layout and region tabs.
- **Catalog:** Empire overview is a screen; map widget is registered as a reusable component. Register this screen in the app widget catalog when implemented.
