# Stockpiles and Production

**SPEC/game** — Centralized commodity storage and production flow. Derived from GDD 04, TDD 04. See [world-model.md](world-model.md) for core entities.

---

## Stockpiles

**Stockpiles are centralized repositories that live with the Player.** Resources are always collected and produced centrally, even though extraction happens in provinces.

- Each **Player** holds one **Stockpile** — a map of commodity id → quantity.
- There is **no per-province storage** of produced goods. All commodities reside in the player's central stockpile.
- Extraction in provinces flows to the owning player's stockpile each turn (via auto-transport).
- Production consumes from and produces into the player's stockpile.
- Trade, workers, military, and navy all draw from the stockpile.

Per Imperialism II 02-economy (GDD reference): "commodities produced in these terrain tiles move to your warehouse" — the warehouse is the player's centralized stockpile.

---

## Production Flow

1. **Extraction phase:** Terrain tiles (owned provinces) produce resources per improvement level. Resources are collected and transported (auto-transport) to the player's stockpile.
2. **Production phase:** Industry consumes commodities from stockpile (inputs) and labour (from workers) to produce materials. Outputs are added to stockpile.
3. **Consumption phase:** Workers, military, and navy consume food and materials from stockpile.

Capacity limits may apply per commodity or total; configurable per era. Overflow rules: excess sold at market or discarded (per design).

---

## Relations

- **Player** → **Stockpile** (commodity quantities).
- Extraction in provinces → owning player's stockpile (via transport network).
- Production: stockpile inputs + labour → stockpile outputs.

---

## Implementation

Data structures and turn-resolution hooks in [economy-models.md](../program/economy-models.md). Commodity catalog and recipes: [commodity-catalog.md](commodity-catalog.md), [production-recipes.md](production-recipes.md). Models in colonizethis_models; logic in colonizethis_logic. Config is program-level (no JSON rulesets in MVP).
