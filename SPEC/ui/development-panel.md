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
3. Per scope: province name; improvable commodity rows (icon, count, **Show**, **Assign** disabled until Slice B) or muted **No improvable resources**.

### Panel map

`CtRegionMap` for active region; **Show** sets `secondaryHighlightTileKeys` to improvable tile keys; pan/zoom enabled.

---

## Behavior

| Control | Outcome |
|---------|---------|
| Show | Highlights commodity improvable tiles on panel map. |
| Assign | Slice B — pending `build_improvement` (disabled in Slice A with reason). |
| Region tab | Switches list + map region. |

Read model: `SPEC/program/development-panel-read-model.md`.

---

## Widgetbook

| Use case | Proves |
|----------|--------|
| Default — Old World | Overview + owned rows + map. |
| Narrow (360 dp) | Stacked list/map. |

---

## Acceptance criteria (Slice A)

- Given the in-game shell, when the player opens **Development** from the empire rail, then `GAME80001` opens with OW/NW tabs and `← Map`.
- Given owned provinces in a region, when the tab renders, then **Your provinces** lists every owned province; empty improvable shows **No improvable resources**.
- Given purchased tiles, when the tab renders, then **Purchased land** groups under source province with owner name.
- Given improvable commodities, when a row renders, then counts match the read model and **Show** highlights tiles on the panel map.
- Given post-resolution state, when the overview renders, then Extraction shows effective per-commodity projection for the active region.
