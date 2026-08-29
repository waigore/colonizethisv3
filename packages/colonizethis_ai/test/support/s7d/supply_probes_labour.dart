// S7-D feedstock labour / population probes (Refs #2847 / #4602 Slice E).
// Split from `supply_probes_afford.dart`.

import 'package:colonizethis_ai/src/planning/recipe_scoring.dart'
    show feasibleRuns;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// True iff [playerId] can run at least one full output run of any recipe in
/// [recipes] given **both** its stockpile inputs **and** its current effective
/// labour — the labour-aware analogue of [stockpileAffordsAnyProductionRecipe].
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

/// Effective labour available to [playerId] this turn after mandatory food upkeep.
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

/// Raw (food-ungated) labour supply ceiling for [playerId].
int playerRawLabourSupply(Game game, String playerId) {
  final player = game.playerById(playerId);
  if (player == null) return 0;
  return player.workerPool.labourSupplyPerTurn;
}

/// Total quantity of the [foodCommodityIds] held in [playerId]'s stockpile.
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

/// True iff [playerId]'s raw labour ceiling is below [castIronMinLabourPerOutput].
bool castIronFeedstockExtractionLabourFutile(
  Game game,
  String playerId,
  int castIronMinLabourPerOutput,
) {
  if (castIronMinLabourPerOutput <= 0) return false;
  return playerRawLabourSupply(game, playerId) < castIronMinLabourPerOutput;
}
