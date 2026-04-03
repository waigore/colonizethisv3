# Stockpiles & Production

## Overview
Centralized commodity storage and multi-phase production flow per player. Province identity and lookup (e.g. owned provinces, extraction locations) follow [world-model-identity.md](world-model-identity.md).

## Rules

### Stockpiles
Each player holds one **stockpile** — a map of commodity → quantity. There is no per-province storage. All extraction, production, trade, and consumption flows through the player's central stockpile.

Per Imperialism II: "commodities produced in these terrain tiles move to your warehouse" — that line is **narrative consolidation** only: the game still uses a single central aggregate, not simulated warehouse buildings or depots.

### Strategic abstraction (not warehouse logistics)

The stockpile is an **in-game abstraction** of a nation’s **strategic resource pool** — what the economy can draw on for production, trade, consumption, and military upkeep. **Warehouse logistics** (storage buildings, per-site capacity, inland distribution of bulk goods, spoilage in silos, etc.) are **not modeled** and are intentionally out of scope. Unbounded quantities reflect this abstraction, not a claim about infinite physical sheds.

### Production Flow
1. **Extraction:** Terrain tiles in owned provinces produce resources per improvement level. Resources are transported (auto-transport) to the player's stockpile.
2. **Riches-to-treasury:** Riches (e.g. gold) in the stockpile convert to treasury at base price and are removed from the stockpile. Phase order: Extraction → Riches-to-treasury → **Consumption → Production** (see [economy-models.md](../program/economy-models.md) and [turn-resolution-phases.md](../program/turn-resolution-phases.md)).
3. **Consumption:** Workers, military, and navy consume food (and worker luxuries per tier). Strike rules: [workers-and-population.md](workers-and-population.md).
4. **Production:** Industry consumes commodities (inputs) from the **post-Consumption** stockpile and uses **idle labour** (`WorkerIdleCounts`) to produce materials. Outputs are added to stockpile. Labour is **not** removed from the WorkerPool by production itself; each turn’s production is capped by **assigned labour** and by idle labour for that turn (per workers-and-population.md and [economy-models.md](../program/economy-models.md)).

For UI preview of upcoming stockpile changes in the production panel, the same four-phase order above is used by a dry-run projection API; preview must not use allocation-only recipe arithmetic.

### Capacity
By design, the central stockpile is **permanently unbounded**: no per-commodity cap, no aggregate cap, and no ruleset-defined storage limits. Only per-turn **cargo** limits apply to **overseas delivery** (throughput), not to how much can be held once delivered ([auto-transport.md](../program/auto-transport.md)). This matches the strategic-abstraction model above: there is no warehouse simulation to cap the aggregate.

### Relations
- **Player** → **Stockpile** (commodity quantities).
- Extraction in provinces → owning player's stockpile (via transport network). Province and tile identity (owned provinces, extraction locations) follow [world-model-identity.md](world-model-identity.md) for province id format and region-scoped lookup.
- Production: stockpile inputs (commodities) + WorkerPool labour capacity (via per-turn assignments and effective labour) → stockpile outputs; WorkerPool population is not decremented by running production.

---

## Acceptance Criteria

- Given a player owns one or more provinces and has at least one extractable resource tile connected to the capital as described in [extraction-and-improvements.md](extraction-and-improvements.md)  
  When the System runs the Extraction phase of turn resolution  
  Then the System sums the effective yields from all connected tiles for that player by commodity id and increases the player’s central stockpile quantities by exactly those sums without storing any additional per-province stockpile values.

- Given a player has a non-negative integer quantity of each commodity in the central stockpile and central stockpile storage is unbounded by design (no warehouse maximum)  
  When any phase (Extraction, Riches-to-treasury, Production, or Consumption) adjusts stockpile quantities during a turn  
  Then the System allows stockpile quantities to grow without applying any storage caps, storage-related discards, or automatic market sales triggered by a full warehouse, and ensures all adjustments preserve non-negative integer quantities for each commodity within engine integer limits.

- Given a player has enough input commodities and **idle labour** after Consumption to run one or more production recipes defined in [production-recipes.md](production-recipes.md)  
  When the System executes the Production phase for that player  
  Then the System consumes the required input quantities from the stockpile, uses assigned labour (capped by **WorkerIdleCounts** / idle labour for that turn) to limit the number of recipe runs **without decrementing the WorkerPool headcounts**, adds the recipe outputs to the same central stockpile, and records which recipes ran so that a subsequent inspection can verify that input and output quantities satisfy each recipe’s definitions.

- Given a player has workers and other consumers (such as army and navy) that require food and materials as described in [workers-and-population.md](workers-and-population.md)  
  When the System executes the Consumption phase  
  Then the System deducts required food and materials from the player’s central stockpile in the specified order, applies food and luxury strike rules **without removing workers** for missing food, and does not attempt to deduct from any non-existent per-province storage.

- Given a Great Power’s current `Game` state, map topology and tile maps as used for turn resolution, and that player’s production assignment derived from the production panel’s desired-output sliders  
  When the UI layer requests a per-commodity stockpile delta preview for that player before the player ends the turn  
  Then the System computes the delta as the difference in that player’s central stockpile after and before applying **only** the phases Extraction → Riches-to-treasury → Consumption → Production in order, using the same rules as live turn resolution (including combined land/overseas extraction delivery, riches removal from the stockpile, consumption, then production with post-consumption idle labour), and returns **no entry** for commodities whose net change is zero.

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
