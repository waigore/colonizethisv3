// S7-D feedstock affordability / labour probes (Refs #2847 / #4602 Slice E).

import 'package:colonizethis_ai/src/planning/recipe_scoring.dart'
    show feasibleRuns;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// True iff [playerId]'s stockpile can afford the level-0 `build_improvement`
/// material cost (the cost to raise an unimproved tile to level 1 — 1 lumber +
/// 1 cast iron, `work_order_costs.dart` § `workOrderCostBuildImprovement`).
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
/// (`economy_planner_labour.dart` § `allocateLabour` → `feasibleRuns`) by computing
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
    foodCounts: MilitaryNavyFoodCounts(
      regimentCountsById: regimentTypeCountsForPlayer(
        game.worldState,
        playerId,
      ),
      shipCountsById: shipTypeCountsForPlayer(game.worldState, playerId),
    ),
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
    foodCounts: MilitaryNavyFoodCounts(
      regimentCountsById: regimentTypeCountsForPlayer(
        game.worldState,
        playerId,
      ),
      shipCountsById: shipTypeCountsForPlayer(game.worldState, playerId),
    ),
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
