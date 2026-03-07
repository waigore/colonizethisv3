# Order Projections API

**SPEC/program** — Projects the effects of all unresolved orders submitted by a player (or all players) for the current turn. Dry-run of full turn resolution; no world state mutation. Reference: [order-engine.md](order-engine.md), [turn-resolution-phases.md](turn-resolution-phases.md).

---

## Responsibility

colonizethis_logic (extend OrderEngine or a dedicated service) provides an API that runs a dry-run `resolveTurnForGame` and returns projected state at end of turn. Used by the Running Game Screen's Player tabs for "expected extraction + production" and similar feedback.

---

## Inputs

- `Game` — current world state
- `Orders` — unresolved orders for the current turn (per player or merged)
- `MapTopology` — for movement and extraction
- `Map<String, TileMapResult> tileMapByRegion` — for extraction (required; empty map yields no extraction)
- Optional: `defaultAssignments` for production phase

---

## Process

1. Copy `Game` (or work on a clone; no mutation of the real world state).
2. Call `resolveTurnForGame` with the given orders, topology, and tile maps.
3. Compare before/after state and return projected effects.

---

## Output

`ProjectedEffects` (or equivalent) extended with:

- `workerCount` — total workers after resolution
- `treasuryDelta` — change in treasury
- `stockpile` or `stockpileDeltas` — commodity quantities (or deltas) after resolution
- `unitLocations` — map of unit id → province id after movement

- `productionByRecipe` — when projection runs with production assignments (`defaultAssignments`), recipe id → quantity produced for the projected player (optional; null or empty when no assignments or production skipped).

Optionally, when feasible (currently deferred; fields exist on `ProjectedEffects` but are not yet populated):

- `extractionByCommodity` — projected extraction per commodity

---

## Per-player projection

When projecting for a single player: merge that player's orders with empty or placeholder orders for other players so the dry-run can complete. Cross-player effects (combat, diplomacy) require merged orders from all players. For build/work-only feedback, per-player projection in isolation may suffice if the API supports it.

---

## Determinism

Same inputs → same outputs. No RNG in the projection path unless the turn resolver uses a seed; if so, the projection must use a fixed or passed seed for reproducibility.

---

## Acceptance Criteria

- **No Mutation:** Given a Game and Orders, when `projectedEffects` is called, then the original Game state is not modified; a copy or clone is used for the dry-run.

- **Worker Count:** Given orders that include build orders for civilian units requiring workers, when projecting effects, then the returned `ProjectedEffects.workerCount` reflects the expected worker pool after resolution (accounting for worker consumption in unit builds).

- **Treasury Delta:** Given orders that have build costs, work costs, or grants, when projecting effects, then `ProjectedEffects.treasuryDelta` equals the sum of all treasury changes (costs are negative, grants are positive).

- **Stockpile Deltas:** Given work orders for improvements or purchases, when projecting effects with tile maps provided, then `ProjectedEffects.stockpileDeltas` contains the net change per commodity (materials consumed for builds are negative, extraction yields are positive).

- **Unit Locations:** Given move orders for units, when projecting effects, then `ProjectedEffects.unitLocations` maps each moved unit's id to its destination province id.

- **Empty Tile Maps:** Given `tileMapByRegion` is empty or null, when projecting effects, then extraction yields zero and `ProjectedEffects.extractionByCommodity` is empty or null; the dry-run completes without error.

- **Determinism:** Given identical inputs (Game, Orders, topology, tile maps), when projecting effects multiple times, then the outputs are identical (no RNG or side effects).
