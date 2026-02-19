# Economy Data Models

## Responsibility

Defines core data structures for the player economy: stockpiles, worker pools, and the turn-level economic flow. Game rules: [stockpiles-and-production.md](../game/stockpiles-and-production.md), [workers-and-population.md](../game/workers-and-population.md).

---

## Data Model

### Stockpile

Per-player map of commodity id → quantity. No per-province storage. Extraction, production, and consumption all operate on this structure.

### WorkerPool

Per-player population for production, distinct from military/civilian units. Tier definitions and labour values are specified in game/workers-and-population.md.

---

## Algorithm / Flow

Turn economic phases (in order):

1. **Extraction:** Province tiles produce; resources flow to player stockpile via auto-transport. Per game/extraction-and-improvements.md.
2. **Riches-to-treasury:** Riches in stockpile convert to treasury at base price; removed from stockpile.
3. **Production:** Consume commodities and labour; produce outputs to stockpile. Per game/stockpiles-and-production.md.
4. **Consumption:** Military regiments consume food upkeep first, then workers and navy consume food and materials from remainder. Military food shortfalls reduce morale/strength rather than removing regiments.

---

## Integration

| Aspect | Detail |
|---|---|
| Phase | Spans extraction through consumption |
| Upstream | Extraction pipeline, game rules (stockpiles-and-production, workers-and-population) |
| Downstream | Player treasury, military morale, production output |

**Package locations:**

- Models (Stockpile, WorkerPool, Player fields): colonizethis_models.
- Resolution logic (extraction, production, transport, consumption): colonizethis_logic.

---

## Constraints

- Stockpile and WorkerPool types must be serializable for save/load.
- Worker tier definitions, labour values, recruiting/training rules are defined in game/workers-and-population.md; this module references them.
- Config is program-level (no JSON rulesets in MVP).
