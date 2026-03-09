# Production Panel

**SPEC/ui** — Flutter production panel for allocating resources and workers to material production. Game rules: [stockpiles-and-production.md](../game/stockpiles-and-production.md), [production-recipes.md](../game/production-recipes.md), [workers-and-population.md](../game/workers-and-population.md). Mobile: [mobile-adaptation.md](mobile-adaptation.md).

## Overview

The production panel lets the player allocate production by setting **desired output** per recipe. Required inputs and labour are derived automatically and shown. Two subpanels: (1) available resources, materials, and workers; (2) sliders for each producible material with derived requirements and validation feedback.

## Layout

### Desktop / wide viewport (e.g. width ≥ 600 dp)

- **Subpanel 1 — Available (left):** List of commodities in the player stockpile grouped by category (Food, Raw Materials, Manufactured), with worker pool below (by tier; total and effective labour). Each commodity shows current stockpile quantity and net change from current allocations (e.g. "Timber: 100 (-20)"). Read-only.
- **Subpanel 2 — Allocation (right):** One row per production recipe: label showing output and inputs (e.g. "Lumber (timber ×2)"), slider for desired output, and validation feedback when labour is insufficient.
- Subpanels are laid out in a **row** (Available | Allocation) to conserve horizontal space.

### Mobile / narrow viewport (e.g. width < 600 dp)

- The same two subpanels are **vertically stacked** to conserve space: Available first, then Allocation.
- The panel is scrollable (e.g. `SingleChildScrollView`) so all content is reachable on short viewports. No unreachable content.
- Breakpoint aligns with responsive behavior described in [mobile-adaptation.md](mobile-adaptation.md) (narrow layout when horizontal layout would be cramped).

## Data

- **Available:** From `Player.stockpile`, `Player.workerPool`. Effective labour from logic (`effectiveLabourForWorkers`). Commodity list from [commodity-catalog.md](../game/commodity-catalog.md); recipes from [production-recipes.md](../game/production-recipes.md).
- **Allocation:** UI holds desired output per recipe (recipe id → integer ≥ 0). Converted to `List<AssignedRecipe>` for the turn resolver: for each recipe, `assignedLabour = desiredOutput * recipe.labourPerOutput`.

## Behaviour

- Sliders adjust desired output; recipe labels display output commodity followed by input commodities in parentheses (e.g. "Lumber (timber ×2)").
- **Reset:** A "Reset" button clears all slider allocations to zero.
- **Validation:** Each recipe slider is capped at the **achievable runs** considering both current stockpile inputs AND labour already allocated to other recipes. The slider maximum is recalculated dynamically as other allocations change. The UI does not accept a desired output above that cap. When total required labour across all recipes exceeds effective labour, the UI shows **insufficient labour** and displays a warning that production will be capped next turn.
- **Net Changes:** The Available panel displays expected net change for each commodity based on current allocations, shown in parentheses (positive for production, negative for consumption).
- When the player advances the turn, the app passes the current allocation as production assignments for the human player to the turn resolver (`defaultAssignmentsByPlayerId`). Assignment is not persisted in the save (app state only) unless extended later.
- The turn resolver still runs as many complete recipe runs as inputs and labour allow (per production-recipes.md).

## Acceptance Criteria

- **Given** the user opens the production panel, **when** viewing the Available subpanel, **then** the UI layer shows commodity groups (Food, Raw Materials, Manufactured) with stockpile quantities for all commodities from the commodity catalog, and worker pool tiers (peasants, apprentices, journeymen, masters) plus effective labour.

- **Given** the user opens the production panel with active allocations, **when** viewing the Available subpanel, **then** each commodity displays its current quantity followed by the expected net change in parentheses (e.g. "Timber: 100 (-20)").

- **Given** the user is on the Allocation subpanel, **when** viewing the recipe labels, **then** each label shows the output commodity name followed by input commodities in parentheses (e.g. "Lumber (timber ×2)").

- **Given** the user is on the Allocation subpanel, **when** the user moves a slider for a recipe, **then** the UI layer enforces the slider maximum at the achievable runs for that recipe, considering both current stockpile inputs and labour already allocated to other recipes.

- **Given** the user taps the Reset button, **when** viewing the Allocation subpanel, **then** all sliders are set to zero and the allocation state is cleared.

- **Given** the user has set desired outputs and closes the panel, **when** the user presses Next turn, **then** the system passes the corresponding production assignments for the human player to the turn resolver and production runs accordingly.

- **Given** the total required labour across all recipes exceeds the player's effective labour, **when** the user views the Allocation subpanel, **then** the UI layer shows total required labour vs effective labour in error colour and a message that production will be capped next turn.

- **Given** the viewport width is less than 600 dp (narrow/mobile), **when** the production panel is displayed, **then** the UI layer stacks the Available subpanel above the Allocation subpanel in a single column and makes the content scrollable so all content is reachable.

- **Given** the viewport width is at least 600 dp (wide), **when** the production panel is displayed, **then** the UI layer shows the Available subpanel and the Allocation subpanel side by side in a row.

## Integration

- Shown from the in-game shell (e.g. bottom toolbar). Game screen passes current game and human player; panel reads/writes allocation via app state (e.g. Riverpod provider) so nextTurn can pass `defaultAssignmentsByPlayerId`.
- Widgetbook: at least one use case with full availability and one with partial availability; at least one mobile viewport use case per [mobile-adaptation.md](mobile-adaptation.md).
