// S7-D feedstock decision-gate read-only probe helpers (Refs #2847).
//
// Extracted from `seed42_observer_conquest_s7d_diagnostic_test.dart` to keep
// that diagnostic test file at or below the repo non-comment line limit
// (`repo.dart_file_non_comment_line_size`). These are pure read-only scans over
// game state used by the H8-supply / H8-extraction stage-localization counters.
import 'package:colonizethis_ai/src/perception/perception_snapshot.dart'
    show AIWorldSnapshot;
import 'package:colonizethis_ai/src/planning/army_conquest_prep.dart'
    show regimentCountForPlayer;
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart'
    show ObserverGoalPhase;
import 'package:colonizethis_ai/src/planning/cast_iron_labour_gate.dart'
    show
        isCastIronLabourPopulationBoundForLockRecoverySeller,
        otherGreatPowerFabricHeld;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_ai/src/planning/recipe_scoring.dart'
    show feasibleRuns;
import 'package:colonizethis_ai/src/planning/planning_imports.dart'
    show ownsFeedstockResourceTile;
import 'package:colonizethis_ai/src/planning/treasury_planner.dart'
    show kTreasuryOfferPriorityUrgent, otherGreatPowerOfferableFabricHeld;
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// True iff [playerId] owns at least one province tile that hosts a fabric
/// feedstock resource (a member of [feedstockIds]) whose improvement level
/// satisfies [improvementMatches]. Shared owned-province tile scan backing the
/// three `ownsFeedstock*` probes so the loop lives in one place; an empty
/// [feedstockIds] never matches. Read-only over `(game, playerId)`; no
/// game-state mutation.
bool scanOwnedFeedstockTiles(
  Game game,
  String playerId,
  Set<String> feedstockIds,
  bool Function(int improvementLevel) improvementMatches,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final byProvince in ws.tileKeysByRegionAndProvince.values) {
    for (final entry in byProvince.entries) {
      final province = ws.tryGetProvince(entry.key);
      if (province == null || province.ownerId != playerId) continue;
      for (final tileKey in entry.value) {
        final resourceId = ws.resourceByTileKey[tileKey];
        if (resourceId == null || !feedstockIds.contains(resourceId)) {
          continue;
        }
        if (improvementMatches(ws.tileState.improvementLevel(tileKey))) {
          return true;
        }
      }
    }
  }
  return false;
}

/// True iff [playerId] owns at least one province tile that hosts a fabric
/// feedstock resource (a member of [feedstockIds]) and is still unimproved
/// (improvement level < 1) — i.e. a Builder target a lock-recovery seller could
/// extract to feed the `fabricFrom*` recipes. Read-only scan over owned
/// provinces; Refs #2847 H8-supply feedstock-stage diagnostic.
bool ownsUnimprovedFeedstockResourceTile(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) => scanOwnedFeedstockTiles(
  game,
  playerId,
  feedstockIds,
  (improvementLevel) => improvementLevel < 1,
);

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
) => scanOwnedFeedstockTiles(
  game,
  playerId,
  feedstockIds,
  (improvementLevel) => improvementLevel >= 1,
);

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
int playerFoodOnHand(Game game, String playerId, Set<String> foodCommodityIds) {
  if (foodCommodityIds.isEmpty) return 0;
  final player = game.playerById(playerId);
  if (player == null) return 0;
  var total = 0;
  for (final id in foodCommodityIds) {
    total += player.stockpile.quantityOf(id);
  }
  return total;
}

/// True iff [playerId]'s fully-fed raw labour ceiling ([playerRawLabourSupply])
/// is **below** [castIronMinLabourPerOutput] — i.e. even if the locked seller
/// won every `timber` / `iron` deal its castIron-feedstock bids chase (or
/// extracted that feedstock outright), the only `castIron` recipe still could
/// not run a single output against its labour ceiling.
///
/// The S7-D castIron-feedstock order-matching counters
/// (`gpCastIronFeedstockBidsEmitted` high, `gpCastIronFeedstockDealsAsBuyer`
/// zero) show a below-quota zero-NW lock-recovery seller bidding `timber` /
/// `iron` for a domestic `castIron` run whose bids never cross, now that
/// affluent suppliers finally *offer* the feedstock
/// (`gpCastIronFeedstockOffersEmitted` non-zero — the historical "no surplus to
/// release" finding is stale once the supplier feedstock-extraction routing
/// landed). This helper backs the counter that proves that order-matching gap is
/// **off the critical path**: with a raw labour ceiling below `castIron`'s
/// `labourPerOutput` (5), filling the feedstock bids could never yield a
/// labour-feasible `castIron` run, so the binding constraint remains the
/// seller's worker population — not feedstock supply or offer-tier alignment. It
/// generalises `gpCastIronLabourPopulationBoundTurns` (measured only on castIron
/// *material*-feasible turns, which a seller that never holds both feedstocks —
/// e.g. gp3 — never reaches) to the feedstock-extraction-gate-active turns where
/// the seller is still *bidding* the feedstock. Returns `false` when
/// [castIronMinLabourPerOutput] is not positive (no recipe means the labour
/// ceiling is trivially sufficient). Pure read-only over `(game, playerId)`; no
/// game-state mutation.
bool castIronFeedstockExtractionLabourFutile(
  Game game,
  String playerId,
  int castIronMinLabourPerOutput,
) {
  if (castIronMinLabourPerOutput <= 0) return false;
  return playerRawLabourSupply(game, playerId) < castIronMinLabourPerOutput;
}

/// Increments the per-GP [key] entry of a `<String, int>` diagnostic [counter]
/// by one, treating an absent entry as zero. Shared by the S7-D diagnostic to
/// keep its many per-turn counter bumps to a single line each.
void bumpCounter(Map<String, int> counter, String key) =>
    counter[key] = (counter[key] ?? 0) + 1;

/// Builds a fresh zero-initialised per-GP `<String, int>` diagnostic counter
/// map keyed by every id in [gpIds]. Shared by the S7-D diagnostic to keep its
/// many counter declarations to a single line each (the inline
/// `{for (final gpId in gpIds) gpId: 0}` literal otherwise wraps to three
/// physical lines per counter, pushing the test file over the repo non-comment
/// line limit).
Map<String, int> zeroPerGpCounter(List<String> gpIds) => {
  for (final gpId in gpIds) gpId: 0,
};

/// Per-turn castIron-labour stage-localization measurement for one GP (Refs
/// #2847). Pure read-only over `(game, playerId)`: bundles the boolean flags
/// the S7-D diagnostic increments each turn so the caller only applies counter
/// bumps. Mirrors the inline measurement it replaced exactly —
///
///   * `peasantRecruitGate` / `peasantRecruitAffordable` —
///     [castIronLabourPeasantRecruitProbe] (the #3303 boost localization).
///   * `holdsFabricFeedstock` — any [fabricFeedstockIds] held in the stockpile.
///   * `fabricRecipeFeasible` — any [fabricRecipes] materially runnable.
///   * `fabricRecipeLabourFeasible` — any [fabricRecipes] runnable against the
///     seller's full effective labour too
///     ([stockpileAndLabourAffordAnyProductionRecipe]). Always a subset of
///     `fabricRecipeFeasible`. A near-zero count here while
///     `fabricRecipeFeasible` is high localizes the unbuilt peasant-recruit
///     `fabric` to **labour starvation of the fabric recipe itself**
///     (`fabric_from_*` carries `labourPerOutput == 2`, above a lock-recovery
///     seller's effective labour of 1), i.e. the #3303/#3315 peasant-recruit
///     boost is a circular deadlock: growing castIron labour needs a peasant,
///     the peasant needs `fabric`, and `fabric` itself needs labour the seller
///     does not have — so the lever cannot be domestic `fabric` and must grow
///     raw population by a non-`fabric` path.
///   * `castIronMaterialFeasible` — any [castIronRecipes] materially runnable
///     ([stockpileAffordsAnyProductionRecipe]); the labour / food / tile flags
///     below are only meaningful (non-false) when this holds.
///   * `castIronLabourFeasible` — material-feasible **and** labour-feasible
///     ([stockpileAndLabourAffordAnyProductionRecipe]).
///   * `castIronLabourFoodStarved` / `castIronLabourPopulationBound` — the
///     material-feasible-but-labour-infeasible fork keyed on
///     [castIronMinLabourPerOutput] vs [playerRawLabourSupply] (fully-fed
///     ceiling would fund a run vs ceiling itself below one run); both false
///     when [castIronMinLabourPerOutput] is not positive.
///   * `castIronOwnsFeedstockTile` — owns a castIron feedstock tile at any
///     level ([ownsFeedstockResourceTileAnyLevel]).
///
/// All flags are false for an unknown player. No game-state mutation.
({
  bool peasantRecruitGate,
  bool peasantRecruitAffordable,
  bool holdsFabricFeedstock,
  bool fabricRecipeFeasible,
  bool fabricRecipeLabourFeasible,
  bool castIronMaterialFeasible,
  bool castIronLabourFeasible,
  bool castIronLabourFoodStarved,
  bool castIronLabourPopulationBound,
  bool castIronOwnsFeedstockTile,
})
seed42S7dCastIronLabourTurnMeasure({
  required Game game,
  required String playerId,
  required Set<String> fabricFeedstockIds,
  required List<ProductionRecipe> fabricRecipes,
  required List<ProductionRecipe> castIronRecipes,
  required Set<String> castIronFeedstockIds,
  required int castIronMinLabourPerOutput,
}) {
  const none = (
    peasantRecruitGate: false,
    peasantRecruitAffordable: false,
    holdsFabricFeedstock: false,
    fabricRecipeFeasible: false,
    fabricRecipeLabourFeasible: false,
    castIronMaterialFeasible: false,
    castIronLabourFeasible: false,
    castIronLabourFoodStarved: false,
    castIronLabourPopulationBound: false,
    castIronOwnsFeedstockTile: false,
  );
  final player = game.playerById(playerId);
  if (player == null) return none;
  final recruit = castIronLabourPeasantRecruitProbe(game, playerId);
  final holdsFabricFeedstock = fabricFeedstockIds.any(
    (id) => player.stockpile.quantityOf(id) > 0,
  );
  final fabricRecipeFeasible = fabricRecipes.any(
    (recipe) => recipe.inputQuantities.entries.every(
      (e) => player.stockpile.quantityOf(e.key) >= e.value,
    ),
  );
  // Labour-aware fabric feasibility (Refs #2847 § S7-D fabric circular-labour
  // localization). A subset of `fabricRecipeFeasible`: a fabric run needs both
  // its feedstock on hand AND `labourPerOutput` effective labour. Skipped when
  // the cheaper material check already failed.
  final fabricRecipeLabourFeasible =
      fabricRecipeFeasible &&
      stockpileAndLabourAffordAnyProductionRecipe(
        game,
        playerId,
        fabricRecipes,
      );
  final castIronMaterialFeasible = stockpileAffordsAnyProductionRecipe(
    player.stockpile,
    castIronRecipes,
  );
  var castIronLabourFeasible = false;
  var foodStarved = false;
  var populationBound = false;
  var ownsTile = false;
  if (castIronMaterialFeasible) {
    castIronLabourFeasible = stockpileAndLabourAffordAnyProductionRecipe(
      game,
      playerId,
      castIronRecipes,
    );
    if (!castIronLabourFeasible && castIronMinLabourPerOutput > 0) {
      if (playerRawLabourSupply(game, playerId) >= castIronMinLabourPerOutput) {
        foodStarved = true;
      } else {
        populationBound = true;
      }
    }
    ownsTile = ownsFeedstockResourceTileAnyLevel(
      game,
      playerId,
      castIronFeedstockIds,
    );
  }
  return (
    peasantRecruitGate: recruit.gateActive,
    peasantRecruitAffordable: recruit.affordable,
    holdsFabricFeedstock: holdsFabricFeedstock,
    fabricRecipeFeasible: fabricRecipeFeasible,
    fabricRecipeLabourFeasible: fabricRecipeLabourFeasible,
    castIronMaterialFeasible: castIronMaterialFeasible,
    castIronLabourFeasible: castIronLabourFeasible,
    castIronLabourFoodStarved: foodStarved,
    castIronLabourPopulationBound: populationBound,
    castIronOwnsFeedstockTile: ownsTile,
  );
}

/// Builds the per-GP turn-99 snapshot field map cached for the S7-D
/// diagnostic rollup (Refs #2847). Pure read-only construction over
/// `(game, playerId, snap)`: the conquest/colonial/threat snapshot fields, the
/// treasury and regiment trajectory, the cheapest-regiment treasury floor, and
/// the castIron labour-starvation corroboration trio (effective food-fed
/// labour, raw fully-fed ceiling, and [foodCommodityIds] on hand at the
/// terminal turn). Extracted to keep the diagnostic test file at or below the
/// repo non-comment line limit; no game-state mutation.
Map<String, Object?> seed42S7dTurn99SnapshotFields({
  required Game game,
  required String playerId,
  required AIWorldSnapshot snap,
  required Set<String> foodCommodityIds,
}) {
  final player = game.playerById(playerId);
  return <String, Object?>{
    'oldWorldProvincesOwned': snap.conquest.oldWorldProvincesOwned,
    'invadableProvinceCount': snap.conquest.invadableProvinceIdsSorted.length,
    'nwInvadableCount': snap.colonial.invadableNewWorldProvinceIdsSorted.length,
    'atWarWith': snap.threats.atWarWith.toList()..sort(),
    'adjacentOwnerFactionIdsSorted':
        snap.conquest.adjacentOwnerFactionIdsSorted,
    'treasury': player?.treasury,
    'regimentCount': regimentCountForPlayer(game, playerId),
    'cheapestRegimentBuildTreasuryCost': cheapestRegimentBuildTreasuryCost(),
    'effectiveLabour': playerEffectiveLabour(game, playerId),
    'rawLabourSupply': playerRawLabourSupply(game, playerId),
    'foodOnHand': playerFoodOnHand(game, playerId, foodCommodityIds),
  };
}

/// Read-only probe for the #3303 castIron-labour peasant-recruit boost
/// localization (Refs #2847). Returns whether the boost's distinguishing gate
/// predicate `isCastIronLabourPopulationBoundForLockRecoverySeller` holds for
/// [playerId] this turn, and — when it does — whether the seller can actually
/// pay the peasant `RecruitWorkerOrder` cost row
/// (`WorkerActionEconomyCatalog.peasant`, which costs 2 `fabric`) via
/// `canAffordRecruitWorker`.
///
/// The `affordable == false` branch (gate active yet cost unpayable) isolates
/// the suspected circular dependency that renders the #3303 boost a structural
/// no-op: recruiting the peasant that would grow castIron labour itself needs
/// `fabric`, the very downstream commodity the castIron chain exists to
/// unblock. `affordable` is `false` when the gate is inactive. Pure read-only
/// over `(game, playerId)`; no game-state mutation.
({bool gateActive, bool affordable}) castIronLabourPeasantRecruitProbe(
  Game game,
  String playerId,
) {
  if (!isCastIronLabourPopulationBoundForLockRecoverySeller(
    game: game,
    playerId: playerId,
  )) {
    return (gateActive: false, affordable: false);
  }
  final player = game.playerById(playerId);
  if (player == null) return (gateActive: true, affordable: false);
  final affordable = canAffordRecruitWorker(
    player,
    const RecruitWorkerOrder(targetTier: WorkerTier.peasant),
    player.workerPool,
    player.stockpile,
    player.treasury,
  ).canAfford;
  return (gateActive: true, affordable: affordable);
}

/// True iff [playerId] owns at least one province tile hosting one of
/// [feedstockIds] at **any** improvement level (improved or unimproved).
///
/// This is the tile-ownership precondition the lock-recovery-seller castIron
/// staging gate (`full_ai_civilian_work_selection_feedstock.dart` §
/// `selfLockRecoverySellerStageableImprovementInputs` →
/// [ownsFeedstockResourceTile]) applies before it stages a domestic `castIron`
/// run: a below-quota zero-NW zero-regiment seller only stages `castIron` when
/// it still owns a `timber` / `iron` feedstock tile to extract from. The
/// existing [ownsUnimprovedFeedstockResourceTile] /
/// [ownsImprovedFeedstockResourceTile] probes split by improvement level; this
/// any-level probe delegates to the production symbol via [planning_imports].
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
) => ownsFeedstockResourceTile(game, playerId, feedstockIds);

/// Structural-invariant assertions over the S7-D diagnostic per-GP counter
/// maps (Refs #2847). Extracted from
/// `seed42_observer_conquest_s7d_diagnostic_test.dart` to keep that file at or
/// below the repo non-comment line limit (`repo.dart_file_non_comment_line_size`).
///
/// The diagnostic deliberately does not pin arm-fire counts so the planner can
/// be tuned freely without churn here; these assertions only guard the
/// instrumentation itself (the counters partition / bound each other as their
/// definitions require). Each `[gpId]` map is expected to contain an entry for
/// every id in [gpIds].
void assertSeed42S7dStructuralInvariants({
  required List<String> gpIds,
  required Map<String, Map<ObserverGoalPhase, int>> phaseCounts,
  required Map<String, int> rebuildReadyNoBuildTurns,
  required Map<String, int> rebuildReadyNoBuildMissingInputTurns,
  required Map<String, int> rebuildReadyNoBuildInputsPresentTurns,
  required Map<String, int> feedstockExtractionGateActiveTurns,
  required Map<String, int> feedstockGateIdleBuilderPresentTurns,
  required Map<String, int> feedstockGateImprovedTileOwnedTurns,
  required Map<String, int> feedstockGateValidBuildImprovementCandidateTurns,
  required Map<String, int> feedstockGateImprovementCostAffordableTurns,
  required Map<String, int> feedstockGateImprovementLumberAffordableTurns,
  required Map<String, int> feedstockGateImprovementCastIronAffordableTurns,
  required Map<String, int> feedstockAcquisitionTargetActiveTurns,
  required Map<String, int> feedstockAcquisitionTargetWithFieldArmyTurns,
  required Map<String, int> castIronLabourPeasantRecruitGateTurns,
  required Map<String, int> castIronLabourPeasantRecruitAffordableTurns,
  required Map<String, int> castIronLabourPeasantRecruitFabricStarvedTurns,
  required Map<String, int>
  castIronLabourPeasantRecruitMarketFabricStarvedTurns,
  required Map<String, int>
  castIronLabourPeasantRecruitMarketFabricUnofferedTurns,
  required Map<String, int> castIronLabourPeasantRecruitFabricBidEmittedTurns,
  required Map<String, int> castIronLabourPeasantRecruitFabricBidAbsentTurns,
  required Map<String, int> castIronLabourPeasantRecruitFabricDealAsBuyerTurns,
  required Map<String, int> fabricRecipeFeasibleTurns,
  required Map<String, int> fabricRecipeLabourFeasibleTurns,
  required Map<String, int> castIronMarketOfferPresentTurns,
  required Map<String, int> castIronMarketOfferAbsentTurns,
  required Map<String, int> castIronFeedstockExtractionLabourFutileTurns,
}) {
  for (final gpId in gpIds) {
    expect(
      phaseCounts[gpId]!.values.fold<int>(0, (a, b) => a + b),
      100,
      reason: '$gpId phase-count total should equal turn count',
    );
    // Refs #2847 H8: structural invariant on the conversion-gap split.
    // Every rebuild-ready turn with no military build is attributed to
    // exactly one of the two mutually exclusive sub-causes, so the parts
    // must sum to the whole. This guards the instrumentation itself
    // without pinning the (freely tunable) per-GP counts.
    expect(
      rebuildReadyNoBuildMissingInputTurns[gpId]! +
          rebuildReadyNoBuildInputsPresentTurns[gpId]!,
      rebuildReadyNoBuildTurns[gpId],
      reason:
          '$gpId rebuild-ready no-build turns must split into '
          'missing-input + inputs-present sub-causes',
    );
    // Refs #2847 H8-extraction: the disambiguation sub-counters are each
    // measured only on a feedstock-gate-active turn, so neither can exceed
    // the gate-active total. Guards the instrumentation gating itself
    // without pinning the (freely tunable) per-GP counts.
    expect(
      feedstockGateIdleBuilderPresentTurns[gpId]!,
      lessThanOrEqualTo(feedstockExtractionGateActiveTurns[gpId]!),
      reason:
          '$gpId idle-Builder-present turns cannot exceed the '
          'feedstock-extraction-gate-active turns',
    );
    expect(
      feedstockGateImprovedTileOwnedTurns[gpId]!,
      lessThanOrEqualTo(feedstockExtractionGateActiveTurns[gpId]!),
      reason:
          '$gpId improved-feedstock-tile-owned turns cannot exceed the '
          'feedstock-extraction-gate-active turns',
    );
    // Refs #2847 H8-extraction missing-candidate disambiguation: both
    // sub-counters are measured only on a feedstock-gate-active turn, so
    // neither can exceed the gate-active total. Guards the instrumentation
    // gating itself without pinning the (freely tunable) per-GP counts.
    expect(
      feedstockGateValidBuildImprovementCandidateTurns[gpId]!,
      lessThanOrEqualTo(feedstockExtractionGateActiveTurns[gpId]!),
      reason:
          '$gpId valid-feedstock-build_improvement-candidate turns cannot '
          'exceed the feedstock-extraction-gate-active turns',
    );
    expect(
      feedstockGateImprovementCostAffordableTurns[gpId]!,
      lessThanOrEqualTo(feedstockExtractionGateActiveTurns[gpId]!),
      reason:
          '$gpId feedstock improvement-cost-affordable turns cannot exceed '
          'the feedstock-extraction-gate-active turns',
    );
    // Refs #2847 H8-extraction per-component affordability split: each
    // per-material counter is measured only on a gate-active turn, and the
    // combined (lumber AND castIron) counter can never exceed either
    // component on its own. Guards the localization instrumentation without
    // pinning the (freely tunable) per-GP counts.
    expect(
      feedstockGateImprovementLumberAffordableTurns[gpId]!,
      lessThanOrEqualTo(feedstockExtractionGateActiveTurns[gpId]!),
      reason:
          '$gpId feedstock improvement-lumber-affordable turns cannot '
          'exceed the feedstock-extraction-gate-active turns',
    );
    expect(
      feedstockGateImprovementCastIronAffordableTurns[gpId]!,
      lessThanOrEqualTo(feedstockExtractionGateActiveTurns[gpId]!),
      reason:
          '$gpId feedstock improvement-castIron-affordable turns cannot '
          'exceed the feedstock-extraction-gate-active turns',
    );
    expect(
      feedstockGateImprovementCostAffordableTurns[gpId]!,
      lessThanOrEqualTo(feedstockGateImprovementLumberAffordableTurns[gpId]!),
      reason:
          '$gpId combined improvement-cost-affordable turns cannot exceed '
          'the lumber-component-affordable turns (combined requires both)',
    );
    expect(
      feedstockGateImprovementCostAffordableTurns[gpId]!,
      lessThanOrEqualTo(feedstockGateImprovementCastIronAffordableTurns[gpId]!),
      reason:
          '$gpId combined improvement-cost-affordable turns cannot exceed '
          'the castIron-component-affordable turns (combined requires both)',
    );
    // Refs #2847 H8-extraction acquisition-thread localization: the
    // field-army subset is recorded only on an acquisition-target-active
    // turn, so it can never exceed the active total, and neither counter
    // can exceed the 100-turn run. Guards the instrumentation gating itself
    // without pinning the (freely tunable) per-GP counts.
    expect(
      feedstockAcquisitionTargetWithFieldArmyTurns[gpId]!,
      lessThanOrEqualTo(feedstockAcquisitionTargetActiveTurns[gpId]!),
      reason:
          '$gpId acquisition-target-with-field-army turns cannot exceed '
          'the acquisition-target-active turns',
    );
    expect(
      feedstockAcquisitionTargetActiveTurns[gpId]!,
      lessThanOrEqualTo(100),
      reason:
          '$gpId acquisition-target-active turns cannot exceed the '
          '100-turn run length',
    );
    // Refs #2847 peasant-recruit localization: the affordable and
    // fabric-starved sub-counters partition the #3303 gate-active turns,
    // and the gate total cannot exceed the 100-turn run. Guards the
    // instrumentation gating itself without pinning the (freely tunable)
    // per-GP counts.
    expect(
      castIronLabourPeasantRecruitAffordableTurns[gpId]! +
          castIronLabourPeasantRecruitFabricStarvedTurns[gpId]!,
      castIronLabourPeasantRecruitGateTurns[gpId],
      reason:
          '$gpId peasant-recruit gate-active turns must split into '
          'affordable + fabric-starved sub-causes',
    );
    expect(
      castIronLabourPeasantRecruitGateTurns[gpId]!,
      lessThanOrEqualTo(100),
      reason:
          '$gpId peasant-recruit gate-active turns cannot exceed the '
          '100-turn run length',
    );
    // Refs #2847 § S7-D market-fabric localization: the market-fabric-starved
    // counter is a strict refinement of the fabric-starved turns (gate active
    // AND recruit unpayable AND no other GP holds fabric), so it can never
    // exceed the fabric-starved total. Guards the instrumentation gating
    // itself without pinning the (freely tunable) per-GP counts.
    expect(
      castIronLabourPeasantRecruitMarketFabricStarvedTurns[gpId]!,
      lessThanOrEqualTo(castIronLabourPeasantRecruitFabricStarvedTurns[gpId]!),
      reason:
          '$gpId peasant-recruit market-fabric-starved turns cannot exceed '
          'the fabric-starved turns (market-starved requires fabric-starved)',
    );
    // Refs #2847 § S7-D market-fabric offer/acquisition localization: the
    // market-fabric-unoffered counter is also a subset of the fabric-starved
    // turns (gate active AND recruit unpayable AND holders present yet none
    // offerable), AND it is mutually exclusive with the market-fabric-starved
    // counter (one requires `otherGreatPowerFabricHeld <= 0`, the other
    // `> 0`), so the two offer-side subsets together cannot exceed the
    // fabric-starved total. Guards the instrumentation gating itself without
    // pinning the (freely tunable) per-GP counts.
    expect(
      castIronLabourPeasantRecruitMarketFabricUnofferedTurns[gpId]!,
      lessThanOrEqualTo(castIronLabourPeasantRecruitFabricStarvedTurns[gpId]!),
      reason:
          '$gpId peasant-recruit market-fabric-unoffered turns cannot exceed '
          'the fabric-starved turns (unoffered requires fabric-starved)',
    );
    expect(
      castIronLabourPeasantRecruitMarketFabricStarvedTurns[gpId]! +
          castIronLabourPeasantRecruitMarketFabricUnofferedTurns[gpId]!,
      lessThanOrEqualTo(castIronLabourPeasantRecruitFabricStarvedTurns[gpId]!),
      reason:
          '$gpId market-fabric-starved and market-fabric-unoffered turns are '
          'disjoint fabric-starved subsets, so their sum cannot exceed the '
          'fabric-starved total',
    );
    // Refs #2847 § S7-D buyer-side fabric acquisition: bid-emitted and
    // bid-absent counters are each measured only on fabric-starved turns with
    // offerable counterparty supply, so neither can exceed the fabric-starved
    // total; deals-as-buyer cannot exceed bid-emitted turns on the same axis.
    expect(
      castIronLabourPeasantRecruitFabricBidEmittedTurns[gpId]!,
      lessThanOrEqualTo(castIronLabourPeasantRecruitFabricStarvedTurns[gpId]!),
      reason:
          '$gpId peasant-recruit fabric-bid-emitted turns cannot exceed the '
          'fabric-starved turns',
    );
    expect(
      castIronLabourPeasantRecruitFabricBidAbsentTurns[gpId]!,
      lessThanOrEqualTo(castIronLabourPeasantRecruitFabricStarvedTurns[gpId]!),
      reason:
          '$gpId peasant-recruit fabric-bid-absent turns cannot exceed the '
          'fabric-starved turns',
    );
    expect(
      castIronLabourPeasantRecruitFabricBidEmittedTurns[gpId]! +
          castIronLabourPeasantRecruitFabricBidAbsentTurns[gpId]!,
      lessThanOrEqualTo(castIronLabourPeasantRecruitFabricStarvedTurns[gpId]!),
      reason:
          '$gpId fabric-bid-emitted and fabric-bid-absent turns are disjoint '
          'buyer-side subsets of offerable-supply fabric-starved turns',
    );
    expect(
      castIronLabourPeasantRecruitFabricDealAsBuyerTurns[gpId]!,
      lessThanOrEqualTo(
        castIronLabourPeasantRecruitFabricBidEmittedTurns[gpId]!,
      ),
      reason:
          '$gpId peasant-recruit fabric deals-as-buyer turns cannot exceed '
          'fabric-bid-emitted turns on the same axis',
    );
    // Refs #2847 § S7-D fabric circular-labour localization: a fabric run is
    // labour-feasible only when it is also materially feasible
    // (`feasibleRuns` incorporates the input check), so the labour-feasible
    // count can never exceed the material-feasible count. Guards the
    // instrumentation without pinning the (freely tunable) per-GP counts.
    expect(
      fabricRecipeLabourFeasibleTurns[gpId]!,
      lessThanOrEqualTo(fabricRecipeFeasibleTurns[gpId]!),
      reason:
          '$gpId fabric labour-feasible turns cannot exceed the fabric '
          'material-feasible turns (labour-feasible requires material-feasible)',
    );
    // Refs #2847 § castIron market-supply wall: every feedstock-extraction
    // gate-active turn is classified as exactly one of castIron-offer-present
    // or castIron-offer-absent, so the two partition the gate-active total.
    // Guards the instrumentation gating itself without pinning the (freely
    // tunable) per-GP counts.
    expect(
      castIronMarketOfferPresentTurns[gpId]! +
          castIronMarketOfferAbsentTurns[gpId]!,
      feedstockExtractionGateActiveTurns[gpId],
      reason:
          '$gpId castIron market-offer present + absent turns must partition '
          'the feedstock-extraction-gate-active turns',
    );
    // Refs #2847 § S7-D castIron-feedstock order-matching off-critical path:
    // the labour-futile counter is measured only on a feedstock-extraction-
    // gate-active turn (raw labour ceiling below the castIron labourPerOutput),
    // so it can never exceed the gate-active total. Guards the instrumentation
    // gating itself without pinning the (freely tunable) per-GP counts.
    expect(
      castIronFeedstockExtractionLabourFutileTurns[gpId]!,
      lessThanOrEqualTo(feedstockExtractionGateActiveTurns[gpId]!),
      reason:
          '$gpId castIron-feedstock-extraction labour-futile turns cannot '
          'exceed the feedstock-extraction-gate-active turns',
    );
  }
}

/// Tallies the per-GP submitted trade-order counters for one turn from the
/// merged order list the resolver will apply (Refs #2924 Step 0). Mirrors the
/// inline scan it replaced: each offer bumps [tradeOfferCount] (plus
/// [tradeUrgentOfferCount] / [improvementInputOffersEmitted] /
/// [castIronFeedstockOffersEmitted] where the order qualifies); each bid bumps
/// [tradeBidCount] (plus the regiment- / improvement-input and castIron-
/// feedstock bid counters where the commodity matches). Carry-forward
/// world-market re-injections are excluded by construction — the caller passes
/// only the AI-emitted merged orders. Read-only over the supplied maps except
/// for the counter bumps. Extracted to keep the diagnostic test file at or
/// below the repo non-comment line limit.
void recordSeed42S7dTradeOrderCounters({
  required List<String> gpIds,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
  required Set<String> regimentInputCommodityIds,
  required Set<String> improvementInputCommodityIds,
  required Set<String> castIronFeedstockIds,
  required Map<String, int> tradeOfferCount,
  required Map<String, int> tradeUrgentOfferCount,
  required Map<String, int> tradeBidCount,
  required Map<String, int> improvementInputOffersEmitted,
  required Map<String, int> castIronFeedstockOffersEmitted,
  required Map<String, int> regimentInputBidsEmitted,
  required Map<String, int> improvementInputBidsEmitted,
  required Map<String, int> castIronFeedstockBidsEmitted,
}) {
  for (final gpId in gpIds) {
    final tradeOrders = tradeOrdersByPlayerId[gpId];
    if (tradeOrders == null) continue;
    for (final order in tradeOrders) {
      _recordSeed42S7dTradeOrderCounter(
        gpId: gpId,
        order: order,
        regimentInputCommodityIds: regimentInputCommodityIds,
        improvementInputCommodityIds: improvementInputCommodityIds,
        castIronFeedstockIds: castIronFeedstockIds,
        tradeOfferCount: tradeOfferCount,
        tradeUrgentOfferCount: tradeUrgentOfferCount,
        tradeBidCount: tradeBidCount,
        improvementInputOffersEmitted: improvementInputOffersEmitted,
        castIronFeedstockOffersEmitted: castIronFeedstockOffersEmitted,
        regimentInputBidsEmitted: regimentInputBidsEmitted,
        improvementInputBidsEmitted: improvementInputBidsEmitted,
        castIronFeedstockBidsEmitted: castIronFeedstockBidsEmitted,
      );
    }
  }
}

/// Records the per-GP counter bumps for a single merged [order] (Refs #2924
/// Step 0). Extracted from [recordSeed42S7dTradeOrderCounters] so the scan loop
/// stays within the repo control-flow nesting-depth limit; behavior is
/// identical to the inline offer/bid handling it replaced. Read-only over the
/// supplied sets except for the counter bumps.
void _recordSeed42S7dTradeOrderCounter({
  required String gpId,
  required TradeOrder order,
  required Set<String> regimentInputCommodityIds,
  required Set<String> improvementInputCommodityIds,
  required Set<String> castIronFeedstockIds,
  required Map<String, int> tradeOfferCount,
  required Map<String, int> tradeUrgentOfferCount,
  required Map<String, int> tradeBidCount,
  required Map<String, int> improvementInputOffersEmitted,
  required Map<String, int> castIronFeedstockOffersEmitted,
  required Map<String, int> regimentInputBidsEmitted,
  required Map<String, int> improvementInputBidsEmitted,
  required Map<String, int> castIronFeedstockBidsEmitted,
}) {
  if (order.type == TradeOrderType.offer) {
    bumpCounter(tradeOfferCount, gpId);
    if (order.priority >= kTreasuryOfferPriorityUrgent) {
      bumpCounter(tradeUrgentOfferCount, gpId);
    }
    if (improvementInputCommodityIds.contains(order.commodityId)) {
      bumpCounter(improvementInputOffersEmitted, gpId);
    }
    if (castIronFeedstockIds.contains(order.commodityId)) {
      bumpCounter(castIronFeedstockOffersEmitted, gpId);
    }
    return;
  }
  if (order.type != TradeOrderType.bid) return;
  bumpCounter(tradeBidCount, gpId);
  if (regimentInputCommodityIds.contains(order.commodityId)) {
    bumpCounter(regimentInputBidsEmitted, gpId);
  }
  if (improvementInputCommodityIds.contains(order.commodityId)) {
    bumpCounter(improvementInputBidsEmitted, gpId);
  }
  if (castIronFeedstockIds.contains(order.commodityId)) {
    bumpCounter(castIronFeedstockBidsEmitted, gpId);
  }
}

/// Records buyer-side `fabric` bid emission for the S7-D peasant-recruit
/// localization (Refs #2847 § buyer-side fabric acquisition). On each
/// fabric-starved gp this turn with offerable counterparty fabric supply
/// (`otherGreatPowerOfferableFabricHeld > 0`), bumps [emittedTurns] when the gp
/// emitted a `fabric` bid in [tradeOrdersByPlayerId], else [absentTurns].
/// Read-only over `(game, tradeOrdersByPlayerId)` except the counter bumps;
/// extracted to keep the diagnostic test file at or below the repo non-comment
/// line limit.
void recordSeed42S7dFabricBidCounters({
  required Game game,
  required Set<String> fabricStarvedThisTurn,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
  required Map<String, int> emittedTurns,
  required Map<String, int> absentTurns,
}) {
  const fabricCommodityId = 'fabric';
  for (final gpId in fabricStarvedThisTurn) {
    if (otherGreatPowerOfferableFabricHeld(game, gpId) <= 0) continue;
    final tradeOrders = tradeOrdersByPlayerId[gpId];
    final emittedFabricBid =
        tradeOrders != null &&
        tradeOrders.any(
          (order) =>
              order.type == TradeOrderType.bid &&
              order.commodityId == fabricCommodityId,
        );
    if (emittedFabricBid) {
      bumpCounter(emittedTurns, gpId);
    } else {
      bumpCounter(absentTurns, gpId);
    }
  }
}

/// Records castIron market-offer presence/absence for the S7-D
/// feedstock-extraction localization (Refs #2847 § castIron market-supply
/// wall). On each gp whose regiment-build-input feedstock-extraction gate is
/// active this turn ([feedstockGateActiveThisTurn]), scans
/// [tradeOrdersByPlayerId] for any *other* faction emitting a
/// [castIronCommodityId] offer this turn and bumps [presentTurns] when one
/// exists, else [absentTurns].
///
/// The level-0 `build_improvement` cost a locked seller must clear to extract
/// its fabric feedstock requires one unit of the manufactured `castIron`
/// (`work_order_costs.dart` § `workOrderCostBuildImprovement`). The treasury
/// planner's direct-acquisition branch
/// (`treasury_regiment_bootstrap.dart` Pass 1 → `_marketHasStandingOfferSupplyFromOthers`)
/// only bids `castIron` directly when some other Great Power offers it;
/// otherwise it falls back to bidding the production feedstock (`timber` +
/// `iron`) for a domestic run. A flat-zero [presentTurns] across the run proves
/// the direct-acquisition branch is permanently closed — every Great Power
/// consumes its `castIron` for Old World military builds and never offers a
/// surplus (corroborated by `gpCastIronHeldAtTurn99 == 0` for every GP) — so
/// the only remaining path to the improvement input is the domestic castIron
/// run, which the labour-aware `gpCastIronRecipeLabourFeasibleTurns == 0`
/// counter shows is itself labour-walled (`castIron` `labourPerOutput` exceeds
/// a lock-recovery seller's effective labour). Read-only over the supplied maps
/// except the counter bumps; extracted to keep the diagnostic test file at or
/// below the repo non-comment line limit.
void recordSeed42S7dCastIronMarketOfferCounters({
  required Set<String> feedstockGateActiveThisTurn,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
  required String castIronCommodityId,
  required Map<String, int> presentTurns,
  required Map<String, int> absentTurns,
}) => recordSeed42S7dOtherFactionOfferCounters(
  activeThisTurn: feedstockGateActiveThisTurn,
  tradeOrdersByPlayerId: tradeOrdersByPlayerId,
  commodityId: castIronCommodityId,
  presentTurns: presentTurns,
  absentTurns: absentTurns,
);

/// Shared other-faction sell-offer present/absent tally backing the castIron
/// and `fabric` market-offer recorders (Refs #2847). For each gp in
/// [activeThisTurn], scans [tradeOrdersByPlayerId] for any *other* faction
/// emitting a [commodityId] sell offer this turn and bumps [presentTurns] when
/// one exists, else [absentTurns]. The gp's own offer never counts as supply,
/// and bids (demand) are ignored. Read-only over the supplied maps except the
/// counter bumps; extracted so the two single-commodity recorders share one
/// scan loop.
void recordSeed42S7dOtherFactionOfferCounters({
  required Set<String> activeThisTurn,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
  required String commodityId,
  required Map<String, int> presentTurns,
  required Map<String, int> absentTurns,
}) {
  for (final gpId in activeThisTurn) {
    var offeredByOther = false;
    for (final entry in tradeOrdersByPlayerId.entries) {
      if (entry.key == gpId) continue;
      final offered = entry.value.any(
        (order) =>
            order.type == TradeOrderType.offer &&
            order.commodityId == commodityId,
      );
      if (offered) {
        offeredByOther = true;
        break;
      }
    }
    if (offeredByOther) {
      bumpCounter(presentTurns, gpId);
    } else {
      bumpCounter(absentTurns, gpId);
    }
  }
}

/// Records `fabric` market-offer presence/absence for the S7-D peasant-recruit
/// fabric localization (Refs #2847 § fabric offer-side split).
///
/// On each gp whose castIron-labour peasant-recruit fabric market path is
/// active this turn ([fabricMarketPathActiveThisTurn]), scans
/// [tradeOrdersByPlayerId] for any *other* faction emitting a `fabric` offer
/// and bumps [presentTurns] when one exists, else [absentTurns].
///
/// Complements [otherGreatPowerFabricHeld] (gross holdings) and
/// [otherGreatPowerOfferableFabricHeld] (planner-scope offerable proxy): a
/// positive holdings / offerable total with a flat-zero [presentTurns] across
/// the run localizes the closed market door to the **trade-order emission**
/// layer (holders retain `fabric` in stockpile but never emit a sell offer)
/// rather than to buyer-side bid/match. Read-only over the supplied maps except
/// the counter bumps; extracted to keep the diagnostic test file at or below
/// the repo non-comment line limit.
void recordSeed42S7dFabricMarketOfferCounters({
  required Set<String> fabricMarketPathActiveThisTurn,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
  required Map<String, int> presentTurns,
  required Map<String, int> absentTurns,
}) => recordSeed42S7dOtherFactionOfferCounters(
  activeThisTurn: fabricMarketPathActiveThisTurn,
  tradeOrdersByPlayerId: tradeOrdersByPlayerId,
  commodityId: 'fabric',
  presentTurns: presentTurns,
  absentTurns: absentTurns,
);

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

/// Applies the per-turn castIron-labour stage-localization counter bumps for one
/// GP from a [seed42S7dCastIronLabourTurnMeasure] result [ci] (Refs #2847).
///
/// Mirrors the inline counter cascade it replaced exactly: the #3303
/// peasant-recruit gate / affordability split (adding fabric-starved GPs to
/// [fabricStarvedThisTurn] and forking the market-fabric-starved vs
/// market-fabric-unoffered sub-causes off `game`), the fabric feedstock /
/// recipe feasibility counters, and the castIron material / labour-fork /
/// owns-feedstock-tile counters. Extracted to keep the diagnostic test file at
/// or below the repo non-comment line limit
/// (`repo.dart_file_non_comment_line_size`); read-only over `game` except the
/// supplied counter-map / set bumps.
void recordSeed42S7dCastIronLabourCounters({
  required Game game,
  required String gpId,
  required ({
    bool peasantRecruitGate,
    bool peasantRecruitAffordable,
    bool holdsFabricFeedstock,
    bool fabricRecipeFeasible,
    bool fabricRecipeLabourFeasible,
    bool castIronMaterialFeasible,
    bool castIronLabourFeasible,
    bool castIronLabourFoodStarved,
    bool castIronLabourPopulationBound,
    bool castIronOwnsFeedstockTile,
  })
  ci,
  required Set<String> fabricStarvedThisTurn,
  required Map<String, int> castIronLabourPeasantRecruitGateTurns,
  required Map<String, int> castIronLabourPeasantRecruitAffordableTurns,
  required Map<String, int> castIronLabourPeasantRecruitFabricStarvedTurns,
  required Map<String, int>
  castIronLabourPeasantRecruitMarketFabricStarvedTurns,
  required Map<String, int>
  castIronLabourPeasantRecruitMarketFabricUnofferedTurns,
  required Map<String, int> feedstockInStockpileTurns,
  required Map<String, int> fabricRecipeFeasibleTurns,
  required Map<String, int> fabricRecipeLabourFeasibleTurns,
  required Map<String, int> castIronRecipeFeasibleTurns,
  required Map<String, int> castIronRecipeLabourFeasibleTurns,
  required Map<String, int> castIronLabourFoodStarvedTurns,
  required Map<String, int> castIronLabourPopulationBoundTurns,
  required Map<String, int> castIronFeasibleOwnsFeedstockTileTurns,
}) {
  if (ci.peasantRecruitGate) {
    bumpCounter(castIronLabourPeasantRecruitGateTurns, gpId);
    if (ci.peasantRecruitAffordable) {
      bumpCounter(castIronLabourPeasantRecruitAffordableTurns, gpId);
    } else {
      bumpCounter(castIronLabourPeasantRecruitFabricStarvedTurns, gpId);
      fabricStarvedThisTurn.add(gpId);
      recordSeed42S7dPeasantRecruitFabricMarketSubCause(
        game: game,
        gpId: gpId,
        marketFabricStarvedTurns:
            castIronLabourPeasantRecruitMarketFabricStarvedTurns,
        marketFabricUnofferedTurns:
            castIronLabourPeasantRecruitMarketFabricUnofferedTurns,
      );
    }
  }
  if (ci.holdsFabricFeedstock) {
    bumpCounter(feedstockInStockpileTurns, gpId);
  }
  if (ci.fabricRecipeFeasible) {
    bumpCounter(fabricRecipeFeasibleTurns, gpId);
    if (ci.fabricRecipeLabourFeasible) {
      bumpCounter(fabricRecipeLabourFeasibleTurns, gpId);
    }
  }
  if (ci.castIronMaterialFeasible) {
    bumpCounter(castIronRecipeFeasibleTurns, gpId);
    // Split the material-feasible turns by the planner's labour gate and by the
    // staging gate's tile-ownership precondition.
    recordSeed42S7dCastIronLabourFork(
      gpId: gpId,
      castIronLabourFeasible: ci.castIronLabourFeasible,
      castIronLabourFoodStarved: ci.castIronLabourFoodStarved,
      castIronLabourPopulationBound: ci.castIronLabourPopulationBound,
      castIronRecipeLabourFeasibleTurns: castIronRecipeLabourFeasibleTurns,
      castIronLabourFoodStarvedTurns: castIronLabourFoodStarvedTurns,
      castIronLabourPopulationBoundTurns: castIronLabourPopulationBoundTurns,
    );
    if (ci.castIronOwnsFeedstockTile) {
      bumpCounter(castIronFeasibleOwnsFeedstockTileTurns, gpId);
    }
  }
}

/// Records the peasant-recruit fabric-starved market sub-cause split for [gpId]
/// (Refs #2847 § S7-D market-fabric localization).
///
/// Of the fabric-starved recruit turns, bumps [marketFabricStarvedTurns] when no
/// other great power holds any `fabric` to sell (the recruit `fabric` can be
/// neither produced nor bought), else bumps [marketFabricUnofferedTurns] when
/// holders exist but every one withholds its `fabric` via the regiment-rebuild
/// offer-retention carve-out (the market door is closed at the offer/retention
/// layer, not at holdings). Read-only over `game` except the counter bumps.
void recordSeed42S7dPeasantRecruitFabricMarketSubCause({
  required Game game,
  required String gpId,
  required Map<String, int> marketFabricStarvedTurns,
  required Map<String, int> marketFabricUnofferedTurns,
}) {
  if (otherGreatPowerFabricHeld(game, gpId) <= 0) {
    bumpCounter(marketFabricStarvedTurns, gpId);
    return;
  }
  if (otherGreatPowerOfferableFabricHeld(game, gpId) <= 0) {
    bumpCounter(marketFabricUnofferedTurns, gpId);
  }
}

/// Records the castIron material-feasible labour fork for [gpId] (Refs #2847
/// § S7-D).
///
/// On a material-feasible turn, bumps exactly one of the three labour-stage
/// counters following the planner's labour-gate precedence: labour-feasible,
/// else food-starved, else population-bound. A material-feasible turn that is
/// none of these (e.g. another labour gate) bumps no labour-stage counter.
void recordSeed42S7dCastIronLabourFork({
  required String gpId,
  required bool castIronLabourFeasible,
  required bool castIronLabourFoodStarved,
  required bool castIronLabourPopulationBound,
  required Map<String, int> castIronRecipeLabourFeasibleTurns,
  required Map<String, int> castIronLabourFoodStarvedTurns,
  required Map<String, int> castIronLabourPopulationBoundTurns,
}) {
  if (castIronLabourFeasible) {
    bumpCounter(castIronRecipeLabourFeasibleTurns, gpId);
    return;
  }
  if (castIronLabourFoodStarved) {
    bumpCounter(castIronLabourFoodStarvedTurns, gpId);
    return;
  }
  if (castIronLabourPopulationBound) {
    bumpCounter(castIronLabourPopulationBoundTurns, gpId);
  }
}
