# Production Panel

**SPEC/ui** — Flutter production panel for allocating resources and workers to material production. Game rules: [stockpiles-and-production.md](../game/stockpiles-and-production.md), [production-recipes.md](../game/production-recipes.md), [workers-and-population.md](../game/workers-and-population.md). Mobile: [mobile-adaptation.md](mobile-adaptation.md).

## Overview

The production panel lets the player allocate production by setting **desired output** per recipe. Required inputs and labour are derived automatically and shown. Two subpanels: (1) available resources, materials, and workers; (2) sliders for each producible material with derived requirements and validation feedback.

## Resource and Worker Icons

Each commodity and worker tier has a unique pixel-art icon (32×32) following the style defined in [game-toolbar-icons.md](game-toolbar-icons.md).

### Icon Asset Names

| Icon ID | Filename | Description |
|---------|----------|-------------|
| **Food** |||
| grain | `ui_icon_com_grain.png` | Wheat sheaf or grain bundle |
| meat | `ui_icon_com_meat.png` | Meat cut or ham |
| **Raw Materials** |||
| timber | `ui_icon_com_timber.png` | Wooden log |
| iron | `ui_icon_com_iron.png` | Iron ore chunk or ingot |
| wool | `ui_icon_com_wool.png` | Wool bundle or fleece |
| cotton | `ui_icon_com_cotton.png` | Cotton boll |
| coal | `ui_icon_com_coal.png` | Coal lump |
| sugar_cane | `ui_icon_com_sugar_cane.png` | Sugar cane stalk |
| tobacco | `ui_icon_com_tobacco.png` | Tobacco leaf |
| furs | `ui_icon_com_furs.png` | Fur pelt |
| copper | `ui_icon_com_copper.png` | Copper ingot |
| tin | `ui_icon_com_tin.png` | Tin ingot |
| horses | `ui_icon_com_horses.png` | Horse head |
| **Manufactured** |||
| lumber | `ui_icon_com_lumber.png` | Stack of lumber planks |
| cast_iron | `ui_icon_com_cast_iron.png` | Cast iron product |
| fabric | `ui_icon_com_fabric.png` | Fabric bolt or cloth roll |
| refined_sugar | `ui_icon_com_refined_sugar.png` | Sugar loaf |
| cigars | `ui_icon_com_cigars.png` | Cigar bundle |
| fur_hats | `ui_icon_com_fur_hats.png` | Fur hat |
| steel | `ui_icon_com_steel.png` | Steel ingot |
| paper | `ui_icon_com_paper.png` | Paper scroll or sheet |
| bronze | `ui_icon_com_bronze.png` | Bronze ingot |
| **Workers** |||
| peasant | `ui_icon_worker_peasant.png` | Peasant worker |
| apprentice | `ui_icon_worker_apprentice.png` | Apprentice worker |
| journeyman | `ui_icon_worker_journeyman.png` | Journeyman worker |
| master | `ui_icon_worker_master.png` | Master craftsman |

### Icon Style

Icons follow the style defined in [game-toolbar-icons.md](game-toolbar-icons.md):
- Size: 32×32 pixels
- Format: PNG with RGBA transparency
- Outline: `single color outline`
- Shading: `medium shading`
- Detail: `medium detail`
- View: `high top-down` (orthographic)
- Style lock: Match color palette from `ui_main_menu_button.png`

### Icon Usage

Icons appear in two contexts:
1. **Available subpanel:** Before each commodity and worker quantity line
2. **Allocation subpanel:** Before each commodity name in recipe labels (output and inputs)

## Layout

### Desktop / wide viewport (e.g. width ≥ 600 dp)

- **Subpanel 1 — Available (left):** Compact layout with:
  - **Food, Raw Materials, Manufactured sections:** Each displayed in a **3-column grid**. Each cell shows: icon, commodity name, quantity, and net change (e.g. "🔄 Timber: 100 (-20)").
  - **Workers section:** Displayed in a **2-column grid**. Each cell shows: icon, worker type, and count.
  - **Effective labour:** Bold line at bottom of workers section.
  - Read-only display of stockpile quantities and net changes from current allocations.
- **Subpanel 2 — Allocation (right):** One row per production recipe: label showing output icon with commodity name and input icons with names (e.g. "🪵 Lumber (🪵 timber ×2)"), slider for desired output, and validation feedback when labour is insufficient.
- Subpanels are laid out in a **row** (Available | Allocation) to conserve horizontal space.

### Mobile / narrow viewport (e.g. width < 600 dp)

- The same two subpanels are **vertically stacked** to conserve space: Available first, then Allocation.
- The Available subpanel maintains 3-column resource grids and 2-column worker grid for compactness.
- The panel is scrollable (e.g. `SingleChildScrollView`) so all content is reachable on short viewports. No unreachable content.
- Breakpoint aligns with responsive behavior described in [mobile-adaptation.md](mobile-adaptation.md) (narrow layout when horizontal layout would be cramped).

## Data

- **Available:** From `Player.stockpile`, `Player.workerPool`. Effective labour from logic (`effectiveLabourForWorkers`). Commodity list from [commodity-catalog.md](../game/commodity-catalog.md); recipes from [production-recipes.md](../game/production-recipes.md).
- **Allocation:** UI holds desired output per recipe (recipe id → integer ≥ 0). Converted to `List<AssignedRecipe>` for the turn resolver: for each recipe, `assignedLabour = desiredOutput * recipe.labourPerOutput`.

## Behaviour

- Sliders adjust desired output; recipe labels display **icon + output commodity name** followed by **icon + input commodities** in parentheses (e.g. "🪵 Lumber (🪵 timber ×2)").
- **Reset:** A "Reset" button clears all slider allocations to zero.
- **Validation:** Each recipe slider is capped at the **achievable runs** considering both current stockpile inputs AND labour already allocated to other recipes. The slider maximum is recalculated dynamically as other allocations change. The UI does not accept a desired output above that cap. When total required labour across all recipes exceeds effective labour, the UI shows **insufficient labour** and displays a warning that production will be capped next turn.
- **Net Changes:** The Available panel displays expected net change for each commodity based on current allocations, shown in parentheses (positive for production, negative for consumption).
- When the player advances the turn, the app passes the current allocation as production assignments for the human player to the turn resolver (`defaultAssignmentsByPlayerId`). Assignment is not persisted in the save (app state only) unless extended later.
- The turn resolver still runs as many complete recipe runs as inputs and labour allow (per production-recipes.md).

## Acceptance Criteria

- **Given** the user opens the production panel, **when** viewing the Available subpanel, **then** the UI layer shows commodity groups (Food, Raw Materials, Manufactured) in a 3-column grid layout with stockpile quantities and icons for all commodities from the commodity catalog, and worker pool tiers (peasants, apprentices, journeymen, masters) in a 2-column grid layout plus effective labour.

- **Given** the user opens the production panel, **when** viewing any commodity or worker entry, **then** the UI displays the corresponding 32×32 pixel-art icon before the name, matching the style from [game-toolbar-icons.md](game-toolbar-icons.md).

- **Given** the user opens the production panel with active allocations, **when** viewing the Available subpanel, **then** each commodity displays its icon, name, current quantity, followed by the expected net change in parentheses (e.g. "🪵 Timber: 100 (-20)").

- **Given** the user is on the Allocation subpanel, **when** viewing the recipe labels, **then** each label shows the output icon and commodity name followed by input icons and commodity names in parentheses (e.g. "🪵 Lumber (🪵 timber ×2)").

- **Given** the user is on the Allocation subpanel, **when** the user moves a slider for a recipe, **then** the UI layer enforces the slider maximum at the achievable runs for that recipe, considering both current stockpile inputs and labour already allocated to other recipes.

- **Given** the user taps the Reset button, **when** viewing the Allocation subpanel, **then** all sliders are set to zero and the allocation state is cleared.

- **Given** the user has set desired outputs and closes the panel, **when** the user presses Next turn, **then** the system passes the corresponding production assignments for the human player to the turn resolver and production runs accordingly.

- **Given** the total required labour across all recipes exceeds the player's effective labour, **when** the user views the Allocation subpanel, **then** the UI layer shows total required labour vs effective labour in error colour and a message that production will be capped next turn.

- **Given** the viewport width is less than 600 dp (narrow/mobile), **when** the production panel is displayed, **then** the UI layer stacks the Available subpanel above the Allocation subpanel in a single column and makes the content scrollable so all content is reachable, while maintaining 3-column resource grids and 2-column worker grid.

- **Given** the viewport width is at least 600 dp (wide), **when** the production panel is displayed, **then** the UI layer shows the Available subpanel and the Allocation subpanel side by side in a row.

## Integration

- Shown from the in-game shell (e.g. bottom toolbar). Game screen passes current game and human player; panel reads/writes allocation via app state (e.g. Riverpod provider) so nextTurn can pass `defaultAssignmentsByPlayerId`.
- Widgetbook: at least one use case with full availability and one with partial availability; at least one mobile viewport use case per [mobile-adaptation.md](mobile-adaptation.md).
