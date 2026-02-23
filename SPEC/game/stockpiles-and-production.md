# Stockpiles & Production

## Overview
Centralized commodity storage and multi-phase production flow per player. Province identity and lookup (e.g. owned provinces, extraction locations) follow [world-model-identity.md](world-model-identity.md).

## Rules

### Stockpiles
Each player holds one **stockpile** — a map of commodity → quantity. There is no per-province storage. All extraction, production, trade, and consumption flows through the player's central stockpile.

Per Imperialism II: "commodities produced in these terrain tiles move to your warehouse" — the warehouse is the player's centralized stockpile.

### Production Flow
1. **Extraction:** Terrain tiles in owned provinces produce resources per improvement level. Resources are transported (auto-transport) to the player's stockpile.
2. **Riches-to-treasury:** Riches (e.g. gold) in the stockpile convert to treasury at base price and are removed from the stockpile. Phase order: Extraction → Riches-to-treasury → Production → Consumption (see [economy-models.md](../program/economy-models.md) and [turn-resolution-phases.md](../program/turn-resolution-phases.md)).
3. **Production:** Industry consumes commodities (inputs) from stockpile and labour from the WorkerPool to produce materials. Outputs added to stockpile.
4. **Consumption:** Workers, military, and navy consume food and materials from stockpile.

### Capacity
Capacity for all commodities is infinite; no limit on the amount of each commodity for the player.

### Relations
- **Player** → **Stockpile** (commodity quantities).
- Extraction in provinces → owning player's stockpile (via transport network).
- Production: stockpile inputs (commodities) + WorkerPool labour → stockpile outputs.


## Interactions
- [commodity-catalog.md](commodity-catalog.md) — commodity definitions
- [production-recipes.md](production-recipes.md) — recipe inputs/outputs
- [extraction-and-improvements.md](extraction-and-improvements.md) — extraction yields
- [workers-and-population.md](workers-and-population.md) — labour and consumption
- [world-model.md](world-model.md) — province ownership, transport
- [world-model-identity.md](world-model-identity.md) — province id format and lookup
- Program: [economy-models.md](../program/economy-models.md) — data structures
- Program: [turn-resolution-phases.md](../program/turn-resolution-phases.md) — phase order
