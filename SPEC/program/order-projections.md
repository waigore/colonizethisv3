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
- `stockpileNetDeltaByCommodity` (production panel preview): per-commodity net delta `after - before` after pending build/train order-cost preview and the economy preview phases below for the viewed player.

Optionally, when feasible (currently deferred; fields exist on `ProjectedEffects` but are not yet populated):

- `extractionByCommodity` — projected extraction per commodity

**Production panel stockpile preview (implemented):** `colonizethis_logic` exposes `previewStockpileNetDeltaByCommodityForPlayer` and `applyEconomyPhasesForPreview`. The production panel preview path first applies unresolved pending build/train order deductions from `Orders.buildUnitOrdersByPlayerId` (same affordability and deduction semantics as build-phase application), then runs Extraction → Riches-to-treasury → Consumption → Production on a copy of the passed `Game` (no turn advance). Used by the Flutter production panel per [production-panel.md](../ui/production-panel.md).

**Phased breakdown (implemented):** `EconomyPreviewStockpilePhase` enum (`pendingBuildTrainCosts`, `extraction`, `richesToTreasury`, `consumption`, `production`) and `previewStockpilePhaseDeltasByCommodityForPlayer` with the **same parameters** as `previewStockpileNetDeltaByCommodityForPlayer`. Returns a map from each phase to per-commodity deltas (zeros omitted). Implementation runs pending build/train deduction preview, then the same private economy preview steps as `applyEconomyPhasesForPreview` in `turn_resolver.dart` (`economyPreviewStockpilePhaseDeltasForPlayer`). **Invariant:** for every commodity id, the sum of all phase deltas equals the net delta from `previewStockpileNetDeltaByCommodityForPlayer` for the same inputs.

---

## Per-player projection

When projecting for a single player: merge that player's orders with empty or placeholder orders for other players so the dry-run can complete. Cross-player effects (combat, diplomacy) require merged orders from all players. For build/work-only feedback, per-player projection in isolation may suffice if the API supports it.

**ctdev Running Game:** For each GP tab, `SimGameController` builds one merged `Orders` value: for every Great Power, use that GP’s entry in `pendingOrdersByPlayerId` if present, otherwise `Orders()` (all maps empty). Then call `projectOrderEffects(..., playerId: <viewed GP>)`. If no GP has any pending orders yet for the turn, the UI shows no projection (em dash).

---

## Production panel stockpile preview phases

For the production-panel Available-grid parenthetical deltas, the projection is not allocation-only arithmetic. The projection runs pending build/train order deductions and then the same economy semantics as live resolver for these phases and order:

1. `Pending build/train costs` (from unresolved `Orders.buildUnitOrdersByPlayerId`)
2. `Extraction` (land + overseas delivered by cargo/interception ordering)
3. `Riches-to-treasury`
4. `Consumption`
5. `Production`

All non-viewed players use empty production assignments in this preview path unless another caller explicitly sets assignments for them.

---

## Determinism

Same inputs → same outputs. No RNG in the projection path unless the turn resolver uses a seed; if so, the projection must use a fixed or passed seed for reproducibility.

---

## Acceptance Criteria

- Given a loaded game, topology, unresolved `Orders`, and `tileMapByRegion` (or an explicit `extractedByPlayerId` override), when `previewStockpileNetDeltaByCommodityForPlayer` runs for player `P`, then for every commodity id `c`, the returned delta equals `stockpileAfter[c] - stockpileBefore[c]` where `stockpileAfter` is from applying exactly `Pending build/train costs -> Extraction -> Riches-to-treasury -> Consumption -> Production` preview phases for `P`.
- Given `desiredOutputByRecipe` for player `P`, when `assignedRecipesFromDesiredOutput` runs, then it returns only assignments with positive labour and known recipe ids, with `assignedLabour = desiredOutput * labourPerOutput` for each returned recipe.
- Given a game with multiple players and only player `P` has desired output entries, when `previewStockpileNetDeltaByCommodityForPlayer` runs, then production assignments for every non-`P` player are treated as empty for this preview.
- Given fixed `Game`, topology, tile maps (or `extractedByPlayerId`), and assignments for player `P`, when `previewStockpilePhaseDeltasByCommodityForPlayer` runs, then for every commodity id `c`, the sum of deltas over `EconomyPreviewStockpilePhase.values` equals the value returned by `previewStockpileNetDeltaByCommodityForPlayer` for `c`, or zero if that key is omitted from the net map.
