# Production Screen

**SPEC/tui/screens/production.md** — TUI-specific Production screen per SPEC/tui/ctterm.md.

**Screen ID:** 100010

## Overview

Production screen for managing resource extraction, stockpile viewing, and industry production. Displays connected extraction tiles, current stockpile contents, production recipes, and worker allocation. Reference: [SPEC/game/stockpiles-and-production.md](../../game/stockpiles-and-production.md), [SPEC/program/extraction-pipeline.md](../../program/extraction-pipeline.md).

## UI/UX

- **Layout:** Three-column or stacked view showing extraction tiles, stockpile contents, and production recipes.
- **Navigation:** Back to In-Game Shell via Escape key.
- **Display:** Show connected tiles with extraction yields, commodity stockpiles, and active production.
- **Keyboard-first:** All actions via keyboard shortcuts.

## Functionality

### Stockpile Display

- **Given** the user opens the Production screen
- **When** viewing the stockpile
- **Then** display each commodity with current quantity:
  - All commodities from [SPEC/game/commodity-catalog.md](../../game/commodity-catalog.md)
  - Quantities as non-negative integers
  - Highlight commodities at zero

### Extraction Tiles Display

- **Given** the user opens the Production screen
- **When** viewing connected extraction tiles
- **Then** display each connected tile showing:
  - Province location (using prefixed province id per SPEC/game/world-model-identity.md)
  - Tile coordinates
  - Resource type
  - Improvement level
  - Transport level (road/port)
  - Yield per turn (calculated as min(improvement, tech cap, transport, town development))

### Extraction Summary

- **Given** the user is on the Production screen
- **When** viewing extraction summary
- **Then** show:
  - Total land extraction by commodity
  - Total overseas extraction by commodity (if any)
  - Number of connected tiles
  - Any cargo limit warnings (if overseas exceeds home fleet capacity)

### Production Recipes Display

- **Given** the user opens the Production screen
- **When** viewing production recipes
- **Then** display each recipe from [SPEC/game/production-recipes.md](../../game/production-recipes.md) showing:
  - Recipe name
  - Input commodities and required quantities
  - Output commodities and produced quantities
  - Labour required (from WorkerPool)
  - Running status (active/inactive based on available inputs and labour)

### Production Activation

- **Given** the user has selected an inactive production recipe
- **When** they choose to activate it
- **Then** validate:
  - Check input commodities available in stockpile
  - Check labour available in WorkerPool
  - If valid: mark recipe as active, consume inputs, deduct labour
  - Display validation result (accepted/rejected with reason)

### Production Deactivation

- **Given** the user has selected an active production recipe
- **When** they choose to deactivate it
- **Then**:
  - Mark recipe as inactive
  - Stop consuming inputs and labour next turn
  - Note: consumed inputs are NOT refunded

### Worker Pool View

- **Given** the user opens the Production screen
- **When** viewing worker pool
- **Then** show:
  - Total available workers
  - Workers assigned to extraction (per SPEC/game/workers-and-population.md)
  - Workers assigned to production (sum across active recipes)
  - Idle workers

### Production Phase Result

- **Given** the Production phase runs during turn resolution
- **When** the system processes active recipes
- **Then**:
  - Consume input commodities from stockpile
  - Consume labour from WorkerPool
  - Add output commodities to stockpile
  - Display production results via game events

### Consumption Phase Info

- **Given** the user is on the Production screen
- **When** viewing consumption information
- **Then** show:
  - Food consumption per turn (workers, army, navy)
  - Material consumption per turn (army, navy)
  - Warning if stockpile may go negative next turn

## Acceptance Criteria

- [ ] Production screen displays title
- [ ] Stockpile shows all commodities with quantities
- [ ] Connected extraction tiles are listed with yields
- [ ] Land vs overseas extraction totals shown
- [ ] Production recipes displayed with inputs/outputs
- [ ] User can select a production recipe via keyboard
- [ ] User can activate inactive recipe (validates inputs/labour)
- [ ] User can deactivate active recipe (no refund)
- [ ] Worker pool display shows available/assigned/idle
- [ ] Consumption warnings shown when stockpile may go negative
- [ ] Escape key returns to In-Game Shell
- [ ] Works on narrow terminals (stacked layout fallback)

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Arrow keys / j/k | Navigate extraction tiles, stockpile, recipes |
| Tab / Shift+Tab | Switch between panels (extraction/stockpile/production) |
| Enter / Space | Select recipe |
| a | Activate selected recipe |
| d | Deactivate selected recipe |
| w | Toggle extraction worker assignment (stub) |
| Escape | Back to In-Game Shell |

## TUI-Specific Cases

- **Given** the terminal is 80×24
- **When** the user opens the Production screen
- **Then** show three panels: extraction tiles, stockpile, production

- **Given** the terminal is narrow (< 60 columns)
- **When** the user opens the Production screen
- **Then** use stacked layout (extraction → stockpile → production) instead of three-column view
