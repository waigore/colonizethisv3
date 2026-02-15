# Economy Data Models

**SPEC/program** — Data structures for stockpiles and workers. Reference: [SPEC/game/stockpiles-and-production.md](../game/stockpiles-and-production.md), [SPEC/game/workers-and-population.md](../game/workers-and-population.md).

---

## Stockpile

**Player** holds **Stockpile** — map of commodity id → quantity.

```dart
// Conceptual; exact types in colonizethis_models
typedef Stockpile = Map<String, int>;  // commodityId -> quantity
```

- Extraction in provinces flows to owning player's stockpile each turn (via auto-transport).
- Production consumes from and produces into stockpile.
- No per-province commodity storage.

**Location:** colonizethis_models. Player entity extended with stockpile field. Auto-transport: [auto-transport.md](auto-transport.md).

---

## WorkerPool

Per-player population for production; distinct from Unit.

```dart
// Conceptual; exact types in colonizethis_models
class WorkerPool {
  int peasants;
  int apprentices;
  int journeymen;
  int masters;
  // Or: Map<WorkerTier, int>
}
```

- Tiers: Peasant (1 labour), Apprentice (4), Journeyman (6), Master (8).
- Recruiting: fabric → Peasant. Training: worker + paper + cash → next tier.
- Military/naval construction consumes a worker.
- Production uses labour: 1 labour per resource input.

**Location:** colonizethis_models. Per-player WorkerPool.

---

## Turn Flow

1. **Extraction phase:** Province tiles produce; resources flow to player stockpile (auto-transport).
2. **Production phase:** Consume commodities and labour from stockpile; produce outputs to stockpile.
3. **Consumption phase:** Workers, military, navy consume food and materials from stockpile.

---

## Package Responsibilities

- **colonizethis_models:** Stockpile type, WorkerPool type, Player.stockpile, Player.workerPool.
- **colonizethis_logic:** Extraction resolution, production resolution, transport algorithm, consumption. Config is program-level (no JSON rulesets in MVP).
