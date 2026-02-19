# Stockpiles & Production

## Overview
Centralized commodity storage and multi-phase production flow per player.

## Rules

### Stockpiles
Each player holds one **stockpile** — a map of commodity → quantity. There is no per-province storage. All extraction, production, trade, and consumption flows through the player's central stockpile.

Per Imperialism II: "commodities produced in these terrain tiles move to your warehouse" — the warehouse is the player's centralized stockpile.

### Production Flow
1. **Extraction:** Terrain tiles in owned provinces produce resources per improvement level. Resources are transported (auto-transport) to the player's stockpile.
2. **Production:** Industry consumes commodities (inputs) and labour (workers) from stockpile to produce materials. Outputs added to stockpile.
3. **Consumption:** Workers, military, and navy consume food and materials from stockpile.

### Capacity
Capacity limits may apply per commodity or total; configurable per era. Overflow: excess sold at market or discarded (per design).

### Relations
- **Player** → **Stockpile** (commodity quantities).
- Extraction in provinces → owning player's stockpile (via transport network).
- Production: stockpile inputs + labour → stockpile outputs.

## Configurable Values

| Parameter | Default | Notes |
|-----------|---------|-------|
| Capacity per commodity | TBD | Per era |
| Overflow behavior | Sell at market | Configurable |

## Interactions
- [commodity-catalog.md](commodity-catalog.md) — commodity definitions
- [production-recipes.md](production-recipes.md) — recipe inputs/outputs
- [extraction-and-improvements.md](extraction-and-improvements.md) — extraction yields
- [workers-and-population.md](workers-and-population.md) — labour and consumption
- [world-model.md](world-model.md) — province ownership, transport
- Program: [economy-models.md](../program/economy-models.md) — data structures
- Program: [turn-resolution-phases.md](../program/turn-resolution-phases.md) — phase order
