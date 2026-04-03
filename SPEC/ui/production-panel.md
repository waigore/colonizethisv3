# Production Panel

**SPEC/ui** — Flutter production panel for allocating resources and workers to material production. Game rules: [stockpiles-and-production.md](../game/stockpiles-and-production.md), [production-recipes.md](../game/production-recipes.md), [workers-and-population.md](../game/workers-and-population.md). Mobile: [mobile-adaptation.md](mobile-adaptation.md).

## Overview

The production panel lets the player allocate production by setting **desired output** per recipe. Required inputs and labour are derived automatically and shown. Two subpanels: (1) available resources, materials, and workers; (2) sliders for each producible material with derived requirements and validation feedback.

## Resource and Worker Icons

Asset filenames and style for commodities and workers appear in [game-toolbar-icons.md](game-toolbar-icons.md) § Resource & Worker Icons (Production Panel); bundle paths are `assets/icons/<filename>` with `StrictAssetIcon` / `ResourceIconCache` per that spec. **Usage:** (1) **Available** — icon before each commodity/worker line; (2) **Allocation** — icon before the **output** commodity name on each recipe row (input materials are listed by name in parentheses).

## Layout

### Desktop / wide viewport (e.g. width ≥ 600 dp)

- **Subpanel 1 — Available (left):** Compact layout with:
  - **Header row:** Title **Available** (left) and a **text** button **Breakdown** (right), same control family as **Reset** on Allocation (`CtNinePatchButton` with a `Text` child — no icon-only entry). Opens a read-only **commodity breakdown** dialog.
  - **Food, Raw Materials, Manufactured sections:** Each displayed in a **3-column grid**. Each cell shows: icon, commodity name, quantity, and **optional** net change in parentheses (e.g. `Timber: 100 (-10)`) when the projected end-of-turn quantity differs from the current stockpile for that commodity.
  - **Workers section:** Displayed in a **2-column grid**. Each cell shows: icon, worker type, and count.
  - **Effective labour:** Bold line at bottom of workers section.
  - Read-only display of stockpile quantities and net changes from current allocations.
- **Subpanel 2 — Allocation (right):** One row per recipe: left, output icon + name and inputs in parentheses; **right-aligned** on that row, `max · bottleneck` (`max` = slider cap; `bottleneck` = limiting commodity **display name** or **Labour**). Next row: slider; **right-aligned** numeric desired output. Summary lines below retain total labour / insufficient-labour warning. **Inset:** Allocation subpanel uses **extra right padding** so `max · bottleneck` and the numeric column are not clipped by the nine-patch frame.
- Subpanels are laid out in a **row** (Available | Allocation) to conserve horizontal space.

### Mobile / narrow viewport (e.g. width < 600 dp)

- The same two subpanels are **vertically stacked** to conserve space: Available first, then Allocation.
- The Available subpanel maintains 3-column resource grids and 2-column worker grid for compactness.
- The panel is scrollable (e.g. `SingleChildScrollView`) so all content is reachable on short viewports. No unreachable content.
- Breakpoint aligns with responsive behavior described in [mobile-adaptation.md](mobile-adaptation.md) (narrow layout when horizontal layout would be cramped).

## Data

- **Available:** From `Player.stockpile`, `Player.workerPool`. Per-commodity net change from logic preview helper (`previewStockpileNetDeltaByCommodityForPlayer` — see [order-projections.md](../program/order-projections.md)). Effective labour from logic (`effectiveLabourForWorkers`). Commodity list from [commodity-catalog.md](../game/commodity-catalog.md); recipes from [production-recipes.md](../game/production-recipes.md).
- **Map inputs:** `MapTopology` and `tileMapByRegion` from the same cached map data the running game uses for turn resolution (e.g. app `GameService.getMapData(game.id)`). The production **screen** may supply optional overrides so tests do not need Hive (`panelTopologyOverride` / `panelTileMapByRegionOverride`). Widgetbook may pass an empty topology and null tile maps (extraction preview zero).
- **Allocation:** UI holds desired output per recipe (recipe id → integer ≥ 0). Converted to `List<AssignedRecipe>` for the turn resolver: for each recipe, `assignedLabour = desiredOutput * recipe.labourPerOutput`.

## Behaviour

- Sliders adjust desired output; recipe labels display **icon + output commodity name** followed by **icon + input commodities** in parentheses (e.g. "🪵 Lumber (🪵 timber ×2)").
- **Reset:** A "Reset" button clears all slider allocations to zero.
- **Validation:** Slider max = same **max** as the affordance readout: min of labour headroom (excluding this recipe) and each input’s stock headroom (excluding this recipe), after subtracting **other** recipes’ committed inputs/labour; then clamp 0–`kProductionAllocationSliderCap` (50). Recalculates on **any** allocation change. No desired output above that max. If **total** required labour > effective labour, show error styling and “capped next turn” message.
- **Affordance bottleneck:** Tightest of labour + **all** recipe inputs (catalog display names; labour label **Labour**). **Ties:** first tied **input** in `inputQuantities` iteration order; if no input ties, **Labour**.
- **Net Changes:** The Available panel displays the **projected net change per commodity** for the **upcoming** economy slice of turn resolution—**Extraction → Riches-to-treasury → Consumption → Production**—using the **same rules** as the live resolver ([stockpiles-and-production.md](../game/stockpiles-and-production.md), [turn-resolution-phases.md](../program/turn-resolution-phases.md), [extraction-pipeline.md](../program/extraction-pipeline.md)). Land and overseas extraction are combined into one delivered amount per commodity before consumption. Inputs: current `Game` (including fleets for overseas interception ordering), `MapTopology`, `tileMapByRegion` (when omitted or empty, extraction from tiles is skipped—same as resolver), current human **desired output** map converted to production assignments for that player only. **Mid-turn stability:** The preview uses the **current** world state only (no lookahead for Build/work or Movement that has not yet run). Riches appear as stockpile decreases (and treasury is not shown in this panel). If the net change for a commodity is **zero**, the parentheses are **omitted** (show quantity only).
- **Commodity breakdown dialog:** Read-only table (`CtDialogShell`, scrollable horizontally and vertically on small viewports). **Columns:** **Commodity**, then **Extraction**, **Riches to treasury**, **Consumption**, **Production** (same order as preview phases), then **Total**. Rows use the same commodity groupings as Available (Food; Raw Materials limited to inputs used in recipes; Manufactured). Cell values are signed integers (`+n`, `-n`, or `0`). **Total** for each row equals the Available parenthetical net delta for that commodity (or `0` when the main panel omits parentheses). **Live updates:** While the dialog is open, changing allocation via sliders or **Reset** on the main panel recomputes all cells from `productionDesiredOutputProvider` without closing the dialog. **Close** dismisses the dialog. No editing of allocations inside the dialog.
- **Comfort headroom (slider track):** On each recipe slider, the track segment from the **thumb to the max** end may use a **deeper purple** than the filled (0→thumb) segment. This is a **comfort signal** only (colour cue; no extra icon). It is **on** when all of the following hold: (1) **desired output < max** for that row (including **desired = 0** when **max > 0**); (2) **strict slack** on **labour** available to this row after other recipes: `remainingLabour > desired × labourPerOutput`; (3) **strict slack** on **every recipe input**: for each input commodity, `remainingStock (after other recipes) > desired × inputPerOutput`. If any check fails, the thumb→max segment uses the default unfilled track styling. Recalculates whenever allocations or stock change. **Colours:** Filled segment = existing primary (semi-transparent); comfort segment = **deeper purple** than the filled segment (fixed UI purple, not theme primary).
- When the player advances the turn, the app passes the current allocation as production assignments for the human player to the turn resolver (`defaultAssignmentsByPlayerId`). Assignment is not persisted in the save (app state only) unless extended later.
- The turn resolver still runs as many complete recipe runs as inputs and labour allow (per production-recipes.md).

## Acceptance Criteria

- **Available:** Food / Raw Materials / Manufactured in **3-column** grids (icon, name, qty, net change in parentheses **only when non-zero**); Workers **2-column** + effective labour; icons 32×32 per [game-toolbar-icons.md](game-toolbar-icons.md).
- **Net change correctness:** Given a loaded `Game`, matching topology and tile maps, and a human production desired-output map, When the UI builds the Available grid for that player, Then each shown parenthetical delta equals the difference between that player’s stockpile **after** `applyEconomyPhasesForPreview` and **before** it, per commodity, for phases Extraction → Riches-to-treasury → Consumption → Production with that player’s assignments; other players run the same phases with empty default assignments unless specified elsewhere.
- **Allocation:** Each recipe: output icon + name; inputs in parentheses; **right-aligned** `max · bottleneck` (not clipped by panel frame); slider row with **right-aligned** desired number. **max** equals slider cap (Behaviour). Changing **any** recipe’s allocation updates **every** row’s **max** / **bottleneck**. **Comfort headroom:** thumb→max track segment is deeper purple iff Behaviour **Comfort headroom** rules are satisfied; otherwise default track colour.
- **Preview parity:** Given map data from `GameService` cache for the current game and a viewed player, when the Production screen renders Available rows, then each parenthetical delta equals the corresponding commodity value from `previewStockpileNetDeltaByCommodityForPlayer(...)` for that player and current desired outputs.
- **Zero-delta formatting:** Given a commodity whose preview net delta is 0, when the Available row renders, then the row omits the parenthetical delta text.
- **Reset** clears all sliders. **Next turn** passes human assignments to the turn resolver. **Labour line** uses error colour + cap message when total required labour > effective.
- **Narrow (<600 dp):** stack subpanels, scroll, keep grid column counts. **Wide (≥600 dp):** Available | Allocation in a row.
- **Breakdown entry:** Given the Production screen with map data and a viewed player, when the Available header renders on wide or narrow viewports, then the breakdown control is a visible **text** button labeled **Breakdown** (not icon-only).
- **Breakdown table parity:** Given the breakdown dialog open for the current preview inputs, when the table renders, then for every commodity row **Extraction + Riches to treasury + Consumption + Production** equals the **Total** column and matches `previewStockpileNetDeltaByCommodityForPlayer` for that commodity (or **Total** `0` when the net map omits that id).
- **Breakdown live update:** Given the breakdown dialog is open, when the player changes any allocation slider or presses **Reset** on the main panel, then phase and total cells refresh to match the new preview without closing the dialog.

## Integration

- Shown from the in-game shell (e.g. bottom toolbar). Game screen passes current game and human player; panel reads/writes allocation via app state (e.g. Riverpod provider) so nextTurn can pass `defaultAssignmentsByPlayerId`.
- Widgetbook: at least one use case with full availability and one with partial availability; at least one mobile viewport use case per [mobile-adaptation.md](mobile-adaptation.md). Production stories use `ProviderScope` and the same preview helpers as the app so **Breakdown** opens a live dialog.
