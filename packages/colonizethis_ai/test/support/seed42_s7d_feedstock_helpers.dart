// S7-D feedstock decision-gate read-only probe helpers (Refs #2847).
//
// Extracted from `seed42_observer_conquest_s7d_diagnostic_test.dart` to keep
// that diagnostic test file at or below the repo non-comment line limit
// (`repo.dart_file_non_comment_line_size`). These are pure read-only scans over
// game state used by the H8-supply / H8-extraction stage-localization counters.
import 'package:colonizethis_ai/src/planning/recipe_scoring.dart'
    show feasibleRuns;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// True iff [playerId] owns at least one province tile that hosts a fabric
/// feedstock resource (a member of [feedstockIds]) and is still unimproved
/// (improvement level < 1) — i.e. a Builder target a lock-recovery seller could
/// extract to feed the `fabricFrom*` recipes. Read-only scan over owned
/// provinces; Refs #2847 H8-supply feedstock-stage diagnostic.
bool ownsUnimprovedFeedstockResourceTile(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final byProvince in ws.tileKeysByRegionAndProvince.values) {
    for (final entry in byProvince.entries) {
      final province = tryGetProvince(ws, entry.key);
      if (province == null || province.ownerId != playerId) continue;
      for (final tileKey in entry.value) {
        final resourceId = ws.resourceByTileKey[tileKey];
        if (resourceId == null || !feedstockIds.contains(resourceId)) {
          continue;
        }
        if (ws.tileState.improvementLevel(tileKey) < 1) return true;
      }
    }
  }
  return false;
}

/// True iff [playerId] owns at least one province tile that hosts a fabric
/// feedstock resource (a member of [feedstockIds]) that is already improved
/// (improvement level >= 1) — i.e. a Builder has finished extracting the tile.
///
/// Companion to [ownsUnimprovedFeedstockResourceTile] for the H8-extraction
/// execution-gap disambiguation (Refs #2847). When the feedstock-extraction
/// gate is active and an unimproved feedstock tile is owned all run, a near-zero
/// improved-tile count localizes the break to the routing / Builder-availability
/// stage (the Builder never finishes the improvement), whereas a high
/// improved-tile count alongside a near-zero `gpFeedstockInStockpileTurns`
/// localizes it to the extraction / transport-connectivity stage (the improved
/// tile yields no commodity into the stockpile because it is not extraction-
/// connected). Read-only scan over owned provinces.
bool ownsImprovedFeedstockResourceTile(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final byProvince in ws.tileKeysByRegionAndProvince.values) {
    for (final entry in byProvince.entries) {
      final province = tryGetProvince(ws, entry.key);
      if (province == null || province.ownerId != playerId) continue;
      for (final tileKey in entry.value) {
        final resourceId = ws.resourceByTileKey[tileKey];
        if (resourceId == null || !feedstockIds.contains(resourceId)) {
          continue;
        }
        if (ws.tileState.improvementLevel(tileKey) >= 1) return true;
      }
    }
  }
  return false;
}

/// True iff [playerId] owns at least one Builder unit that currently has no
/// work assigned (`currentWork == null`) — i.e. a Builder the Full-AI civilian
/// work selection could route onto a feedstock tile this turn.
///
/// Used by the H8-extraction execution-gap disambiguation (Refs #2847): a
/// near-zero count on feedstock-gate-active turns localizes the break to
/// Builder availability (no free Builder to route), distinguishing it from the
/// "Builder present but improvement never completes / extracts" cases. Read-only
/// scan over all world units.
bool hasIdleBuilderUnit(Game game, String playerId) {
  for (final unit in allUnitsFromWorld(game.worldState)) {
    if (unit.ownerId != playerId) continue;
    if (unit.type != kUnitTypeBuilder) continue;
    if (unit.currentWork == null) return true;
  }
  return false;
}

/// True iff [playerId] owns at least one non-home (field) army — an army the
/// stalled-expansion conquest army-move planner could march onto a conquest
/// target this turn.
///
/// Used by the H8-extraction acquisition-thread localization (Refs #2847):
/// when a flagged below-quota zero-NW lock-recovery seller has a non-null
/// `expandSellerFeedstockTileAcquisitionTarget` (the post-#3273 declare-war and
/// post-#3274 army-move bias have a feedstock province to pursue) yet never
/// completes the acquisition, a near-zero field-army count localizes the
/// residual to "no field army available to execute the march" (peer-war
/// regiment attrition), distinguishing it from "army present but the
/// march/capture never completes" downstream of the army-move bias. Mirrors
/// the field-army filter `runConquestArmyMovePlanner` applies
/// (`army.ownerId == playerId && !army.isHomeArmy`). Read-only scan over world
/// armies.
bool hasFieldArmy(Game game, String playerId) {
  for (final army in game.worldState.armies) {
    if (army.ownerId != playerId) continue;
    if (army.isHomeArmy) continue;
    return true;
  }
  return false;
}

/// True iff [playerId]'s stockpile can afford the level-0 `build_improvement`
/// material cost (the cost to raise an unimproved tile to level 1 — 1 lumber +
/// 1 cast iron, `work_order_costs.dart` § `workOrderCostBuildImprovement`).
///
/// The Full-AI civilian work-order validator rejects any `build_improvement`
/// candidate whose material cost the stockpile cannot cover
/// (`work_order_validator.dart` § `_validateWorkMaterialCosts`) **before** the
/// selection score boost (#3234) can bias it. A near-zero count on
/// feedstock-extraction-gate-active turns therefore localizes the
/// missing-candidate break to improvement affordability (the lumber /
/// cast-iron deadlock) rather than tile control, visibility, or occupancy.
/// Read-only over the player's stockpile; Refs #2847 H8-extraction.
bool affordsBuildImprovementLevelZero(Game game, String playerId) {
  final player = game.playerById(playerId);
  if (player == null) return false;
  final cost = workOrderCostBuildImprovement(0);
  for (final entry in cost.entries) {
    if (player.stockpile.quantityOf(entry.key) < entry.value) return false;
  }
  return true;
}

/// True iff [playerId]'s stockpile holds enough of the single [commodityId]
/// component to cover its share of the level-0 `build_improvement` material
/// cost (`work_order_costs.dart` § `workOrderCostBuildImprovement`).
///
/// [affordsBuildImprovementLevelZero] requires **every** component
/// simultaneously (1 lumber **and** 1 cast iron). When that combined counter
/// stays flat at zero on feedstock-extraction-gate-active turns, this
/// per-component probe localizes the binding shortfall to the exact missing
/// material — i.e. whether the GP is starved of `lumber`, of `castIron`, or of
/// both — during the gate window rather than only at the turn-99 snapshot.
/// Returns `false` if [commodityId] is not a component of the level-0 cost.
/// Read-only over the player's stockpile; Refs #2847 H8-extraction.
bool affordsBuildImprovementComponent(
  Game game,
  String playerId,
  String commodityId,
) {
  final player = game.playerById(playerId);
  if (player == null) return false;
  final required = workOrderCostBuildImprovement(0)[commodityId];
  if (required == null) return false;
  return player.stockpile.quantityOf(commodityId) >= required;
}

/// True iff [stockpile] holds enough of every input commodity to run at least
/// one full output run of **any** recipe in [recipes] (`inputQuantities`
/// satisfied for every key of that recipe).
///
/// Pure material-affordability check over a stockpile — the production-side
/// analogue of [affordsBuildImprovementLevelZero], but for a multi-input
/// production recipe rather than a level-0 `build_improvement`. It ignores
/// labour capacity, structure availability, and any planner gate, so it
/// measures only whether the **inputs** are on hand for a feasible run.
///
/// Used by the H8 castIron production-assignment localization (Refs #2847):
/// the diagnostic already tracks `gpCastIronProductionAssignedTurns` (the
/// outcome — did the economy planner actually assign a `castIron` recipe) and
/// `gpCastIronFeedstockHeldAtTurn99` (`timber` / `iron` on hand at the terminal
/// snapshot). A per-turn castIron **recipe-feasibility** counter built on this
/// helper splits a flat `gpCastIronProductionAssignedTurns == 0` into two
/// distinct causes: the recipe is **never materially feasible** (a feedstock /
/// extraction supply gap — no turn holds both `timber` and `iron`), versus the
/// recipe **is feasible yet never assigned** (a production-allocation / planner
/// gate downstream of supply). Mirrors the existing inline `fabricRecipes`
/// feasibility check so the two manufactured-input chains are measured the same
/// way. Pure over the supplied [stockpile]; no game-state mutation.
bool stockpileAffordsAnyProductionRecipe(
  Stockpile stockpile,
  List<ProductionRecipe> recipes,
) {
  for (final recipe in recipes) {
    final affordsAll = recipe.inputQuantities.entries.every(
      (e) => stockpile.quantityOf(e.key) >= e.value,
    );
    if (affordsAll) return true;
  }
  return false;
}

/// True iff [playerId] can run at least one full output run of any recipe in
/// [recipes] given **both** its stockpile inputs **and** its current effective
/// labour — the labour-aware analogue of [stockpileAffordsAnyProductionRecipe].
///
/// Mirrors the economy planner's own per-recipe feasibility test
/// (`economy_planner.dart` § `_allocateLabour` → `feasibleRuns`) by computing
/// `effectiveLabourForWorkers` from the same inputs the planner uses (the
/// player's `WorkerPool` + `Stockpile`, with land-regiment and ship upkeep food
/// reserved via `regimentTypeCountsForPlayer` / `shipTypeCountsForPlayer`) and
/// asking whether any recipe clears `feasibleRuns(...) > 0` against the **full**
/// effective labour for the turn.
///
/// Used by the H8 castIron production-allocation localization (Refs #2847 § H8;
/// S7-D castIron production-assignment, PR #3289 follow-up). The diagnostic
/// already tracks `gpCastIronRecipeFeasibleTurns` (material-only, via
/// [stockpileAffordsAnyProductionRecipe]). Splitting that material-feasible set
/// with this labour-aware counter resolves a flat
/// `gpCastIronProductionAssignedTurns == 0` on the material-feasible turns into
/// two distinct causes: the recipe is **labour-starved** (the seller's effective
/// labour, after mandatory food upkeep, cannot fund even one `labourPerOutput`
/// run, so the lever is effective-labour / food-reservation) versus the recipe
/// is **labour-feasible yet still never assigned** (an allocation-competition /
/// staging-gate cause downstream of raw labour). Because `feasibleRuns`
/// incorporates the stockpile material check too, a labour-feasible turn is
/// always a subset of a material-feasible turn. Pure read-only over
/// `(game, playerId)`; no game-state mutation.
bool stockpileAndLabourAffordAnyProductionRecipe(
  Game game,
  String playerId,
  List<ProductionRecipe> recipes,
) {
  if (recipes.isEmpty) return false;
  final player = game.playerById(playerId);
  if (player == null) return false;
  final effectiveLabour = effectiveLabourForWorkers(
    workers: player.workerPool,
    stockpile: player.stockpile,
    regimentCountsById: regimentTypeCountsForPlayer(game.worldState, playerId),
    shipCountsById: shipTypeCountsForPlayer(game.worldState, playerId),
  );
  for (final recipe in recipes) {
    if (feasibleRuns(
          recipe: recipe,
          stockpile: player.stockpile,
          remainingLabour: effectiveLabour,
        ) >
        0) {
      return true;
    }
  }
  return false;
}

/// Effective labour available to [playerId] this turn — the labour that
/// **food-fed** workers actually supply after mandatory food upkeep, computed
/// exactly as the economy planner does (`effectiveLabourForWorkers` over the
/// player's `WorkerPool` + `Stockpile`, with land-regiment and ship upkeep food
/// reserved first via `regimentTypeCountsForPlayer` /
/// `shipTypeCountsForPlayer`). Unfed workers strike and contribute no labour, so
/// this can be far below the raw population ceiling
/// ([playerRawLabourSupply]).
///
/// Companion to [stockpileAndLabourAffordAnyProductionRecipe] (Refs #2847 § H8;
/// S7-D castIron production-allocation). That boolean only reports *whether* any
/// recipe clears `feasibleRuns > 0`; this returns the underlying scalar so a
/// labour-starvation counter can compare it directly against a recipe's
/// `labourPerOutput`. Pure read-only over `(game, playerId)`; no mutation.
int playerEffectiveLabour(Game game, String playerId) {
  final player = game.playerById(playerId);
  if (player == null) return 0;
  return effectiveLabourForWorkers(
    workers: player.workerPool,
    stockpile: player.stockpile,
    regimentCountsById: regimentTypeCountsForPlayer(game.worldState, playerId),
    shipCountsById: shipTypeCountsForPlayer(game.worldState, playerId),
  );
}

/// Raw (food-ungated) labour supply ceiling for [playerId] — the labour every
/// owned worker would contribute if **all** were fed
/// (`WorkerPool.labourSupplyPerTurn`, the tier-weighted population sum). Unlike
/// [playerEffectiveLabour] it ignores food upkeep and the strike gate, so it is
/// the population ceiling against which a food shortfall is measured.
///
/// Used by the H8 castIron labour-starvation sub-cause split (Refs #2847): on a
/// material-feasible but labour-infeasible castIron turn
/// (`gpCastIronRecipeFeasibleTurns` high, `gpCastIronRecipeLabourFeasibleTurns`
/// zero), comparing this ceiling against the recipe's `labourPerOutput` forks
/// the cause into **food-starved** (ceiling >= one run, but
/// [playerEffectiveLabour] < one run, so workers exist yet too few are fed — the
/// next lever is food supply / food-reservation) versus **population-bound**
/// (ceiling itself < one run, so even fully fed the seller lacks the workers —
/// the next lever is worker growth / recruitment). Pure read-only.
int playerRawLabourSupply(Game game, String playerId) {
  final player = game.playerById(playerId);
  if (player == null) return 0;
  return player.workerPool.labourSupplyPerTurn;
}

/// Total quantity of the [foodCommodityIds] (e.g. `grain` + `meat`) held in
/// [playerId]'s stockpile — the food on hand to feed workers after land-military
/// and navy upkeep claim their share (`economy_consumption.dart` order:
/// military -> navy -> workers Masters->Journeymen->Apprentices->Peasants).
///
/// Used by the H8 castIron labour-starvation snapshot (Refs #2847): captured at
/// the terminal turn alongside [playerEffectiveLabour] /
/// [playerRawLabourSupply], a near-zero food balance on a food-starved seller
/// corroborates the food-supply lever over the recruitment lever. Returns 0 for
/// an empty id set or an unknown player. Pure read-only over the stockpile.
int playerFoodOnHand(
  Game game,
  String playerId,
  Set<String> foodCommodityIds,
) {
  if (foodCommodityIds.isEmpty) return 0;
  final player = game.playerById(playerId);
  if (player == null) return 0;
  var total = 0;
  for (final id in foodCommodityIds) {
    total += player.stockpile.quantityOf(id);
  }
  return total;
}

/// True iff [playerId] owns at least one province tile hosting one of
/// [feedstockIds] at **any** improvement level (improved or unimproved).
///
/// This is the tile-ownership precondition the lock-recovery-seller castIron
/// staging gate (`full_ai_civilian_work_selection_feedstock.dart` §
/// `selfLockRecoverySellerStageableImprovementInputs` →
/// `_ownsFeedstockResourceTile`) applies before it stages a domestic `castIron`
/// run: a below-quota zero-NW zero-regiment seller only stages `castIron` when
/// it still owns a `timber` / `iron` feedstock tile to extract from. The
/// existing [ownsUnimprovedFeedstockResourceTile] /
/// [ownsImprovedFeedstockResourceTile] probes split by improvement level; this
/// any-level probe mirrors the staging gate's own predicate exactly.
///
/// Used by the H8 castIron production-allocation localization (Refs #2847): on
/// the castIron material-feasible turns, a flat-zero count here while the seller
/// **holds** `timber` / `iron` commodities localizes the unfired staging gate to
/// **tile ownership** (the seller accumulated the feedstock by trade / past
/// extraction but no longer owns a resource tile, so the staging gate stays
/// shut), re-pointing the next behaviour slice to broaden the gate to fire on
/// held feedstock; a non-zero count instead clears tile ownership as the cause.
/// Read-only scan over owned provinces.
bool ownsFeedstockResourceTileAnyLevel(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final byProvince in ws.tileKeysByRegionAndProvince.values) {
    for (final entry in byProvince.entries) {
      final province = tryGetProvince(ws, entry.key);
      if (province == null || province.ownerId != playerId) continue;
      for (final tileKey in entry.value) {
        final resourceId = ws.resourceByTileKey[tileKey];
        if (resourceId != null && feedstockIds.contains(resourceId)) {
          return true;
        }
      }
    }
  }
  return false;
}

/// True iff [playerId] owns at least one idle Builder for which the work-order
/// engine **accepts** a `build_improvement` on an owned unimproved feedstock
/// tile (a member of [feedstockIds]) — i.e. `getValidWorkOrderTileKeys` (the
/// same validator chain `suggestWorkOrders` runs) actually emits a candidate
/// the Full-AI civilian selection could route the Builder onto this turn.
///
/// This is the decisive split for the H8-extraction missing-candidate
/// hypothesis (Refs #2847): with an idle Builder present
/// (`gpFeedstockGateIdleBuilderPresentTurns` == gate-active turns) and an
/// unimproved feedstock tile owned (`gpUnimprovedFeedstockTileOwnedTurns` ==
/// 100) yet `gpFeedstockGateImprovedTileOwnedTurns` == 0, a near-zero count
/// here confirms the work-order validator suppresses the candidate before any
/// selection boost applies (the #3234 boost only biases a candidate that
/// exists); a high count would instead re-point the break downstream to the
/// selection / orchestrator / phase-filter stage. Read-only —
/// `getValidWorkOrderTileKeys` does not mutate game state.
bool hasValidBuildImprovementOnUnimprovedFeedstockTile(
  Game game,
  MapTopology topology,
  String playerId,
  Set<String> feedstockIds, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final unit in allUnitsFromWorld(ws)) {
    if (unit.ownerId != playerId) continue;
    if (unit.type != kUnitTypeBuilder) continue;
    if (unit.currentWork != null) continue;
    final valid = getValidWorkOrderTileKeys(
      game,
      topology,
      playerId,
      unit.id,
      kWorkTargetBuildImprovement,
      const Orders(),
      tileMapByRegion: tileMapByRegion,
    );
    for (final tileKey in valid) {
      final resourceId = ws.resourceByTileKey[tileKey];
      if (resourceId == null || !feedstockIds.contains(resourceId)) continue;
      if (ws.tileState.improvementLevel(tileKey) < 1) return true;
    }
  }
  return false;
}
