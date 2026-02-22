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
2. **Riches-to-treasury:** Riches in stockpile convert to treasury at base price; removed from stockpile. The list of riches commodity ids and base prices is defined in package **colonizethis_data** ([riches_prices.dart](../../packages/colonizethis_data/lib/src/riches_prices.dart): `richesCommodityIds`, `richesBasePrice`). Scenario overrides may apply a **richesCashMultiplier** (e.g. 1.5) to the treasury conversion; see [turn-resolution-phase-details.md](turn-resolution-phase-details.md) (Riches to treasury) and resolution API.
3. **Production:** Consume commodities and labour; produce outputs to stockpile. Per game/stockpiles-and-production.md.
4. **Consumption:** Military regiments consume food upkeep first, then workers and navy consume food and materials from remainder. Military food shortfalls reduce morale/strength rather than removing regiments. Feeding coverage (military-first) is converted to a morale/strength modifier used in combat; see [turn-resolution-phase-details.md](turn-resolution-phase-details.md) (Consumption) and [combat-resolution.md](combat-resolution.md), [military-strength.md](military-strength.md).

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

## Acceptance criteria and testing

- **Phase order:** Extraction → Riches → Production → Consumption is fixed and tested (e.g. turn resolver and integration tests).
- **Serialization:** Stockpile and WorkerPool are serializable for save/load; tests cover round-trip or snapshot behaviour.
- **Riches:** Conversion uses base price from colonizethis_data; riches are removed from stockpile; optional richesCashMultiplier scales treasury delta when provided.
- **Consumption:** Military fed first, then workers/navy; military shortfalls yield feeding coverage used in combat (e.g. ConsumptionResult.fullyFedRegiments / coverage ratio → morale multiplier per turn-resolution-phase-details).
- **Production:** Inputs and labour consumed; outputs added to stockpile; insufficient input skips or partial per recipe spec.

Unit tests: Stockpile/WorkerPool serialization; resolveRichesToTreasury; resolveConsumption (military-first, worker feeding, starve order); resolveProduction. Integration: turn resolver runs phases in order; consumption result flows to combat morale where applicable.

---

## Constraints

- Stockpile and WorkerPool types must be serializable for save/load.
- Worker tier definitions, labour values, recruiting/training rules are defined in game/workers-and-population.md; this module references them.
- **Config:** Program-level in MVP (no JSON rulesets for economy in MVP). Economy-related config (worker tiers, riches list/prices) may move to ruleset per [ruleset-config.md](ruleset-config.md) in a later phase.
