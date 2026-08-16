# Development panel

**Screen ID:** `GAME80001` — stable; do not reassign.
**SPEC/ui** — Empire-wide improvable tile management. Implementation: `app/lib/features/game/screens/development/development_screen.dart`.
**Widgetbook:** `Development Panel` → `app/lib/widgetbook/catalog.dart`. Rules: [extraction-and-improvements.md](../game/extraction-and-improvements.md), [province-economic-extraction-available.md](province-economic-extraction-available.md). Mobile: [mobile-adaptation.md](mobile-adaptation.md). Refs #4175.

---

## Trigger conditions

- **Empire rail:** `development` button emits `NavigateToRouteEvent(Routes.development, {game, humanPlayerId})`.
- **Back:** `CtTopBar` `← Map` pops to game map.

---

## Layout / wireframe

```text
CtGameFeatureScreenShell
  CtTopBar (← Map, ui_icon_development.png, title "Development", trailing Counsel)
  body
    CtTabStrip [Old World | New World]
    overview_strip (Extraction projection, idle Builders/Engineers)
    LayoutBuilder
      wide (≥ kNarrowBreakpoint): Row [scope_list (flex 1) | panel_map (flex 1)]
      narrow: Column [scope_list | panel_map 240dp]
```

### Scope list (per region tab)

1. **Your provinces** — `RegionSectionHeader`; one card per owned province (never hidden).
2. **Purchased land** — separate section; rows grouped by source province with **Owner:** label.
3. Per scope: province name; improvable commodity rows per [development-assign-row.md](components/development-assign-row.md) (count, **Show**, **Assign**, muted preview when Assign is enabled) or muted **No improvable resources**.

### Panel map

`CtRegionMap` for active region in **player-constrained** visibility (`CtMapVisibilityMode.playerConstrained` + `playerViewForResources`); **province overlay** strokes enabled with standard edge-gating; **player-territory perimeter** outline (light stroke on outer land boundary, not internal province borders between own provinces). **Show** sets `secondaryHighlightTileKeys` to improvable tile keys and `selectedTileKey` to the auto-pick when a candidate exists; pan/zoom enabled.

### Overview — assigned civilians (Slice D)

Below idle Builder/Engineer counts, when the active region has Builders or Engineers with pending `WorkOrder` or in-progress `currentWork`, list each unit with work type, target location, and turn progress (same semantics as `civilian-units-panel.md` **Assigned to**).

---

## Behavior

| Control | Outcome |
|---------|---------|
| Counsel (header) | Emits `NavigateToRouteEvent(Routes.counsel, counselTab: 'development')` for [counsel-panel.md](counsel-panel.md) Development tab (Refs #4332). |
| Show / Assign | See [development-assign-row.md](components/development-assign-row.md). Connected Assign is one tap; disconnected opens Improve anyway / Road first / Cancel. |
| Region tab | Switches list + map region. |

Read model: `SPEC/program/development-panel-read-model.md`. Assign selection: `development_panel_assign.dart`; Road first: `development_panel_road_first.dart` in `colonizethis_orders`. Road-step BFS: [capital-and-connectivity.md](../game/capital-and-connectivity.md).

---

## Widgetbook

| Use case | Proves |
|----------|--------|
| Default — Old World | Overview + owned rows + map. |
| Default — Old World (mobile / wide) | Narrow stacked list/map and wide side-by-side layout. |
| Fog map — player-constrained visibility | Panel map with `fullyVisible`, `fogged`, and unrevealed tiles; territory perimeter outline; improvable counts exclude unrevealed intel. |
| Assigned civilians — overview rows | Overview lists pending Builder improve and in-progress Engineer road work with target + turn progress. |
| Assign preview enabled | Enabled Assign row shows place, `1 → 2`, and lumber + cast iron cost (Refs #4472). |
| Assign preview enabled (mobile) | Same preview wraps at 320–360 dp; Show/Assign stay tappable. |
| Disconnected dialog | Road first disabled reason + Improve anyway affordance. |

---

## Acceptance criteria (Slice A + B + C)

- Given the in-game shell, when the player opens **Development** from the empire rail, then `GAME80001` opens with OW/NW tabs and `← Map`.
- Given owned provinces in a region, when the tab renders, then **Your provinces** lists every owned province; empty improvable shows **No improvable resources**.
- Given purchased tiles, when the tab renders, then **Purchased land** groups under source province with owner name.
- Given improvable commodities, when a row renders, then counts match the read model and **Show** highlights tiles on the panel map.
- Given post-resolution state, when the overview renders, then Extraction shows effective per-commodity projection for the active region.
- Given two idle Builders and a valid improvable row, when the player taps **Assign**, then a pending `build_improvement` is committed for the first eligible Builder by unit id and the tile priority policy.
- Given insufficient materials for a would-be improve assign, when the panel updates, then affected **Assign** controls are disabled and the overview shows a shortage warning; when materials become sufficient, controls update live.
- Given the selected improve tile is not capital-connected, when the player taps **Assign**, then a warn dialog offers **Improve anyway**, **Road first**, and **Cancel**.
- Given **Improve anyway**, when confirmed, then only a pending Builder `build_improvement` is committed.
- Given a legal Engineer road step and idle Engineer with materials, when **Road first** is chosen, then only a pending `build_road` WorkOrder is committed.
- Given **Road first** is impossible, when the dialog opens, then **Road first** is disabled with a plain reason; **Cancel** leaves no new order.
- Given no idle Builder, when a row would Assign, then **Assign** is disabled with a plain-language reason.

## Acceptance criteria (Slice D)

- Given the panel map renders for a region with `unrevealed`, `fogged`, and `visible` tiles in `PlayerView`, when the map draws, then unrevealed cells are solid black, fogged cells are muted per `map-widget.md`, and visible cells show full terrain detail.
- Given an owned province with improvable tiles only on `unrevealed` cells, when the scope row renders, then it shows **No improvable resources** and offers no Assign/Show for hidden commodities.
- Given improvable tiles on both `fogged` and `visible` cells, when counts render, then only visibility-known tiles contribute to commodity counts and Show/Assign candidate sets.
- Given the human player owns contiguous land in the active region, when the panel map renders, then a light border outlines the outer perimeter of player-owned land cells (not internal borders between own provinces).
- Given a Builder with pending `build_improvement` and an Engineer with in-progress `build_road` in the active region, when the overview renders, then both appear in the assigned-civilians list with work type, target location, and turn progress per `civilian-units-panel.md`.
- Given the player assigns or cancels work from the panel, when drafts change, then assigned-civilian rows and idle counts update immediately without ending the turn.

## Acceptance criteria (Assign preview — Refs #4472)

Normative row copy, Show selected tile, waiver matching, disabled refusal, and one-tap connected commit: [development-assign-row.md](components/development-assign-row.md).

- Given `GAME80001` layout/behavior/variants change for Assign preview, when implementation merges, then this spec and Widgetbook **Assign preview enabled** stay bound to `GAME80001` (`UiScreenIds.developmentScreen`).
