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
- For production-panel stockpile preview:
  - `String playerId` — viewed player id
  - `Map<String, int> desiredOutputByRecipe` — desired output sliders (recipe id → output units) for the viewed player only
  - Optional `Map<String, Map<CommodityId, int>> extractedByPlayerId` for tests/debug previews with known extraction totals (when omitted, extraction is resolved from tile maps + connectivity)

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
- `stockpileNetDeltaByCommodity` (production panel preview): per-commodity net delta `after - before` after the economy preview phases below for the viewed player.

Optionally, when feasible (currently deferred; fields exist on `ProjectedEffects` but are not yet populated):

- `extractionByCommodity` — projected extraction per commodity

**Production panel stockpile preview (implemented):** `colonizethis_logic` exposes `previewStockpileNetDeltaByCommodityForPlayer` and `applyEconomyPhasesForPreview`, which first apply pending stockpile costs in the same order the live Build / work resolver uses: (1) unresolved `Orders.recruitWorkerOrdersByPlayerId` (affordability-checked via the same `canAffordRecruitWorker` / `applyRecruitWorkerCostDeduction` helpers as the worker pool sub-phase, sequential per player; deducts treasury, paper or fabric, and the consumed peasant per the GDD cost row), (2) unresolved `Orders.buildUnitOrdersByPlayerId` (affordability-checked, sequential per player, on the worker-pool-adjusted preview clone), then (3) unresolved material-backed work targets in `Orders.workOrdersByPlayerId` (`build_improvement`, `upgrade_town`, `build_road`, `build_port`, `build_fort`, `build_rail`) using the same material cost and guards as the work phase’s `applyStandardWorkOrder` for each target, sequential per player, after unit-build deductions on the preview clone. Then Extraction → Riches-to-treasury → Consumption → Production run on a copy of the passed `Game` (no turn advance). Used by the Flutter production panel per [production-panel.md](../ui/production-panel.md).

**Phased breakdown (implemented):** `EconomyPreviewStockpilePhase` enum (`pendingBuildCosts`, `extraction`, `richesToTreasury`, `consumption`, `production`) and `previewStockpilePhaseDeltasByCommodityForPlayer` with the **same parameters** as `previewStockpileNetDeltaByCommodityForPlayer`. Returns a map from each phase to per-commodity deltas (zeros omitted). Implementation runs the same private preview steps as `applyEconomyPhasesForPreview` in `turn_resolver.dart` (`economyPreviewStockpilePhaseDeltasForPlayer`). **Invariant:** for every commodity id, the sum of the phase deltas equals the net delta from `previewStockpileNetDeltaByCommodityForPlayer` for the same inputs.

---

## Per-player projection

When projecting for a single player: merge that player's orders with empty or placeholder orders for other players so the dry-run can complete. Cross-player effects (combat, diplomacy) require merged orders from all players. For build/work-only feedback, per-player projection in isolation may suffice if the API supports it.

**ctdev Running Game:** For each GP tab, `SimGameController` builds one merged `Orders` value: for every Great Power, use that GP’s entry in `pendingOrdersByPlayerId` if present, otherwise `Orders()` (all maps empty). Then call `projectOrderEffects(..., playerId: <viewed GP>)`. If no GP has any pending orders yet for the turn, the UI shows no projection (em dash).

---

## Production panel stockpile preview phases

For the production-panel Available-grid parenthetical deltas, the projection is not allocation-only arithmetic. The projection runs the same build-cost and economy semantics as live resolver for these phases and order:

0. `Pending build costs` — unresolved `recruitWorkerOrdersByPlayerId` (affordability checked via the same worker pool cost helpers as the live Build / work worker-pool sub-phase, sequential per player; deducts treasury, paper or fabric, and the consumed peasant per the GDD cost row), then unresolved `buildUnitOrdersByPlayerId` (affordability checked, sequential deduction per player, on the worker-pool-adjusted preview clone), then unresolved `workOrdersByPlayerId` entries for stockpile-material targets `build_improvement`, `upgrade_town`, `build_road`, `build_port`, `build_fort`, `build_rail` (material cost from `workOrderMaterialCost` with target-specific level inputs from current world state, same unit idle/type/target validation as work phase; sequential per player after unit-build deductions on the preview clone). Non-stockpile work targets are excluded from this phase (`explore`, `prospect`, `steal_tech`, `counter_spy`, `purchase_land`).

1. `Extraction` (land + overseas delivered by cargo/interception ordering)
2. `Riches-to-treasury`
3. `Consumption`
4. `Production`

All non-viewed players use empty production assignments in this preview path unless another caller explicitly sets assignments for them.

---

## Determinism

Same inputs → same outputs. No RNG in the projection path unless the turn resolver uses a seed; if so, the projection must use a fixed or passed seed for reproducibility.

---

## Acceptance Criteria

- Given a loaded game, topology, unresolved `Orders`, and `tileMapByRegion` (or an explicit `extractedByPlayerId` override), when `previewStockpileNetDeltaByCommodityForPlayer` runs for player `P`, then for every commodity id `c`, the returned delta equals `stockpileAfter[c] - stockpileBefore[c]` where `stockpileAfter` is from applying exactly `Pending build costs -> Extraction -> Riches-to-treasury -> Consumption -> Production` preview phases for `P`.
- Given a player `P` with `currentOrders.recruitWorkerOrdersByPlayerId[P] = [RecruitWorkerOrder(targetTier: t1), ...]` where each order satisfies the live `canAffordRecruitWorker` rule (tech, peasants, treasury, materials) on the running preview state, when `applyEconomyPhasesForPreview` runs for that `Game` and `currentOrders`, then for player `P` on the preview clone the System deducts the per-order treasury cost from `player.treasury`, deducts every per-order `materialCosts` entry from `player.stockpile`, decrements `player.workerPool.peasants` by `1` for every order whose row has `consumesPeasant == true`, increments `player.workerPool` for the corresponding `targetTier` by `1` per order, and applies these deductions **before** any pending `BuildUnitOrder` or material work order deductions for `P`.
- Given a queued `RecruitWorkerOrder` for player `P` whose `canAffordRecruitWorker` check returns `canAfford: false` on the running preview state (e.g. zero peasants for a non-peasant tier or insufficient treasury / paper / fabric or required tech locked), when `applyEconomyPhasesForPreview` runs, then the preview clone for `P` does not deduct that order's treasury, materials, or peasant, and does not increment any worker tier for that order.
- Given `currentOrders` for player `P` containing both a queued `RecruitWorkerOrder` and `BuildUnitOrder` entries that each consume a peasant such that only the first ordering can be afforded against `pool.peasants`, when `applyEconomyPhasesForPreview` runs, then the recruit-worker order is applied first on the preview clone (matching the live Build / work resolver order) and the subsequent `BuildUnitOrder` sees the post-recruit peasant count for its affordability check.
- Given `desiredOutputByRecipe` for player `P`, when `assignedRecipesFromDesiredOutput` runs, then it returns only assignments with positive labour and known recipe ids, with `assignedLabour = desiredOutput * labourPerOutput` for each returned recipe.
- Given a game with multiple players and only player `P` has desired output entries, when `previewStockpileNetDeltaByCommodityForPlayer` runs, then production assignments for every non-`P` player are treated as empty for this preview.
- Given fixed `Game`, topology, tile maps (or `extractedByPlayerId`), and assignments for player `P`, when `previewStockpilePhaseDeltasByCommodityForPlayer` runs, then for every commodity id `c`, the sum of deltas over `EconomyPreviewStockpilePhase.values` equals the value returned by `previewStockpileNetDeltaByCommodityForPlayer` for `c`, or zero if that key is omitted from the net map.
