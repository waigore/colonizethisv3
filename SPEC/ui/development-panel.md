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
  CtTopBar (← Map, ui_icon_development.png, title "Development")
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
3. Per scope: province name; improvable commodity rows (icon, count, **Show**, **Assign**) or muted **No improvable resources**.

### Panel map

`CtRegionMap` for active region; **Show** sets `secondaryHighlightTileKeys` to improvable tile keys; pan/zoom enabled.

---

## Behavior

| Control | Outcome |
|---------|---------|
| Show | Highlights commodity improvable tiles on panel map. |
| Assign | Commits pending `build_improvement` for first idle Builder (stable unit id) on the priority tile (connected → lower level → tile key). When the chosen tile is not capital-connected, a warn dialog offers **Improve anyway**, **Road first** (Engineer `build_road` only), and **Cancel**. Disabled when no Builder, invalid target, or insufficient materials. |
| Region tab | Switches list + map region. |

Read model: `SPEC/program/development-panel-read-model.md`. Assign selection: `development_panel_assign.dart`; Road first: `development_panel_road_first.dart` in `colonizethis_orders`.

### Disconnected warn dialog

When Assign would commit improve on a tile that is not capital-connected:

| Control | Outcome |
|---------|---------|
| Improve anyway | Commits pending `build_improvement` only. |
| Road first | Commits pending `build_road` on the deterministic connectivity-advancing step (first idle Engineer by unit id; tile = first legal step on shortest owned-tile path toward connected network, preferring tiles closer to capital connection). Disabled with plain reason when no Engineer, no owned path, no legal road step, or insufficient materials. Does not auto-queue Builder improve. |
| Cancel | No order. |

Road-step selection: BFS on owned land tiles from the improve target toward any capital-connected tile; neighbor expansion tie-break by ascending tile key; first valid `build_road` tile along the path from the connection endpoint back toward the improve target. Per `SPEC/game/capital-and-connectivity.md`.

---

## Widgetbook

| Use case | Proves |
|----------|--------|
| Default — Old World | Overview + owned rows + map. |
| Narrow (360 dp) | Stacked list/map. |
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
