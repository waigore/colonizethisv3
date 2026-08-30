// CastIron-labour turn measure + turn-99 snapshot probes (Refs #2847 / #4602 Slice E).
// Split from `extraction_probes.dart`.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart'
    show AIWorldSnapshot;
import 'package:colonizethis_ai/src/planning/army_conquest_prep.dart'
    show regimentCountForPlayer;
import 'package:colonizethis_ai/src/planning/cast_iron_labour_gate.dart'
    show isCastIronLabourPopulationBoundForLockRecoverySeller;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'extraction_probes_feedstock_tiles.dart';
import 'supply_probes.dart';

/// Per-turn castIron-labour stage-localization measurement for one GP (Refs
/// #2847). Pure read-only over `(game, playerId)`.
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
/// diagnostic rollup (Refs #2847).
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
/// localization (Refs #2847).
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
