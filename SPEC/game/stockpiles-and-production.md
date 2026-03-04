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
3. **Production:** Industry consumes commodities (inputs) from stockpile and uses labour from the WorkerPool to produce materials. Outputs are added to stockpile. Labour is **not** removed from the WorkerPool by production itself; instead, each turn’s production is capped by **assigned labour** and by the worker pool’s effective labour (per [workers-and-population.md](workers-and-population.md) and [economy-models.md](../program/economy-models.md)).
4. **Consumption:** Workers, military, and navy consume food and materials from stockpile.

### Capacity
Capacity for all commodities is infinite; no limit on the amount of each commodity for the player.

### Relations
- **Player** → **Stockpile** (commodity quantities).
- Extraction in provinces → owning player's stockpile (via transport network). Province and tile identity (owned provinces, extraction locations) follow [world-model-identity.md](world-model-identity.md) for province id format and region-scoped lookup.
- Production: stockpile inputs (commodities) + WorkerPool labour capacity (via per-turn assignments and effective labour) → stockpile outputs; WorkerPool population is not decremented by running production.

---

## Acceptance Criteria

- Given a player owns one or more provinces and has at least one extractable resource tile connected to the capital as described in [extraction-and-improvements.md](extraction-and-improvements.md)  
  When the System runs the Extraction phase of turn resolution  
  Then the System sums the effective yields from all connected tiles for that player by commodity id and increases the player’s central stockpile quantities by exactly those sums without storing any additional per-province stockpile values.

- Given a player has a non-negative integer quantity of each commodity in the central stockpile and the active ruleset does not define any stockpile capacity limits  
  When any phase (Extraction, Riches-to-treasury, Production, or Consumption) adjusts stockpile quantities during a turn  
  Then the System allows stockpile quantities to grow without applying any hard caps, discards, or automatic market sales, and ensures all adjustments preserve non-negative integer quantities for each commodity.

- Given a player has enough input commodities and available labour capacity in the WorkerPool to run one or more production recipes defined in [production-recipes.md](production-recipes.md)  
  When the System executes the Production phase for that player  
  Then the System consumes the required input quantities from the stockpile, uses assigned labour (capped by effective WorkerPool labour for that turn) to limit the number of recipe runs **without decrementing the WorkerPool**, adds the recipe outputs to the same central stockpile, and records which recipes ran so that a subsequent inspection can verify that input and output quantities satisfy each recipe’s definitions.

- Given a player has workers and other consumers (such as army and navy) that require food and materials as described in [workers-and-population.md](workers-and-population.md)  
  When the System executes the Consumption phase  
  Then the System deducts required food and materials from the player’s central stockpile in the specified order, removes workers that starve when their required food cannot be met, and does not attempt to deduct from any non-existent per-province storage.

---

## Interactions
- [commodity-catalog.md](commodity-catalog.md) — commodity definitions
- [production-recipes.md](production-recipes.md) — recipe inputs/outputs
- [extraction-and-improvements.md](extraction-and-improvements.md) — extraction yields
- [workers-and-population.md](workers-and-population.md) — labour and consumption
- [world-model.md](world-model.md) — province ownership, transport
- [world-model-identity.md](world-model-identity.md) — province id format and lookup
- Program: [economy-models.md](../program/economy-models.md) — data structures
- Program: [turn-resolution-phases.md](../program/turn-resolution-phases.md) — phase order
