import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../economy/economy_consumption.dart';
import '../economy/economy_extraction.dart';
import '../economy/economy_production.dart';
import '../economy/economy_riches_to_treasury.dart';
import '../economy/resource_extractor.dart';
import '../economy/sea_transport.dart';
import '../world/connectivity_resolver.dart';
import '../world/unit_lookup.dart';

/// Builds production assignments from desired output map (recipe id -> units).
/// Unknown recipe ids and non-positive desired values are ignored.
List<AssignedRecipe> assignedRecipesFromDesiredOutput(
  Map<String, int> desiredOutputByRecipe,
) {
  final assignments = <AssignedRecipe>[];
  for (final entry in desiredOutputByRecipe.entries) {
    if (entry.value <= 0) continue;
    final recipe = ProductionRecipesCatalog.byId[entry.key];
    if (recipe == null) continue;
    final assignedLabour = entry.value * recipe.labourPerOutput;
    if (assignedLabour <= 0) continue;
    assignments.add(
      AssignedRecipe(recipeId: entry.key, assignedLabour: assignedLabour),
    );
  }
  return assignments;
}

/// Applies economy phases for preview without mutating [game]:
/// Extraction -> Riches-to-treasury -> Consumption -> Production.
Game applyEconomyPhasesForPreview({
  required Game game,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  Map<String, List<AssignedRecipe>> assignmentsByPlayerId = const {},
}) {
  var state = game;

  if (extractedByPlayerId.isNotEmpty) {
    state = applyExtractionForPlayers(state, extractedByPlayerId);
  } else if (tileMapByRegion.isNotEmpty) {
    final connectivity = resolveConnectivity(
      game: state,
      tileMapByRegion: tileMapByRegion,
      topology: topology,
    );
    final extraction = computeExtraction(
      game: state,
      tileMapByRegion: tileMapByRegion,
      connectivityResult: connectivity,
      techCapForPlayerAndResource: (playerId, resourceId) {
        final player = state.playerById(playerId);
        return extractionCapForResourceForUnlocked(
          player?.techUnlocked,
          resourceId,
        );
      },
      techCapForPlayer: (playerId) {
        final player = state.playerById(playerId);
        return extractionCapForUnlocked(player?.techUnlocked);
      },
    );
    var stateWithFleets = state;
    final extractedPlayers = <Player>[];
    var extractionSeed =
        (state.globalGameSeed ?? 0) ^
        (state.worldState.turnState.turnNumber * kDeterministicHashMixPrime32);
    for (final player in state.players) {
      var stockpile = player.stockpile;
      final totals = extraction[player.id];
      if (totals != null) {
        stockpile = applyExtractionToStockpile(stockpile, totals.land);
        var overseasDelivered = allocateOverseasToStockpile(
          totals.overseas,
          cargoHolds: cargoHoldsForHomeFleet(state, player.id),
        );
        if (overseasDelivered.isNotEmpty) {
          extractionSeed =
              (extractionSeed * kDeterministicLcgMultiplierGlibc +
                  kDeterministicLcgIncrementGlibc) &
              kDeterministicLcg31Mask;
          final interception = applyTradeInterception(
            stateWithFleets,
            player.id,
            overseasDelivered,
            seed: extractionSeed ^ player.id.hashCode,
          );
          overseasDelivered = interception.reducedDelivered;
          stateWithFleets = stateWithFleets.copyWith(
            worldState: stateWithFleets.worldState.copyWith(
              fleets: interception.updatedFleets,
            ),
          );
        }
        stockpile = applyExtractionToStockpile(stockpile, overseasDelivered);
      }
      extractedPlayers.add(player.copyWith(stockpile: stockpile));
    }
    state = stateWithFleets.copyWith(players: extractedPlayers);
  }

  final richesPlayers = <Player>[];
  for (final player in state.players) {
    final riches = resolveRichesToTreasury(
      stockpile: player.stockpile,
      richesCashMultiplier: state.richesCashMultiplier,
    );
    richesPlayers.add(
      player.copyWith(
        stockpile: riches.stockpile,
        treasury: player.treasury + riches.treasuryDelta,
      ),
    );
  }
  state = state.copyWith(players: richesPlayers);

  final idleLabourByPlayerId = <String, WorkerIdleCounts>{};
  final consumptionPlayers = <Player>[];
  for (final player in state.players) {
    final regimentCounts = regimentTypeCountsForPlayer(
      state.worldState,
      player.id,
    );
    final shipCounts = shipTypeCountsForPlayer(state.worldState, player.id);
    final consumption = resolveConsumption(
      stockpile: player.stockpile,
      workers: player.workerPool,
      regimentCountsById: regimentCounts,
      shipCountsById: shipCounts,
    );
    idleLabourByPlayerId[player.id] = consumption.idleLabour;
    consumptionPlayers.add(
      player.copyWith(
        stockpile: consumption.stockpile,
        workerPool: consumption.workerPool,
      ),
    );
  }
  state = state.copyWith(players: consumptionPlayers);

  final productionPlayers = <Player>[];
  for (final player in state.players) {
    final production = resolveProduction(
      stockpile: player.stockpile,
      workers: player.workerPool,
      idleLabour: idleLabourByPlayerId[player.id] ?? WorkerIdleCounts.zero,
      assignments: assignmentsByPlayerId[player.id] ?? const <AssignedRecipe>[],
    );
    productionPlayers.add(
      player.copyWith(
        stockpile: production.stockpile,
        workerPool: production.workerPool,
      ),
    );
  }
  return state.copyWith(players: productionPlayers);
}

/// Returns stockpile net deltas for [playerId] after economy preview phases.
Map<String, int> previewStockpileNetDeltaByCommodityForPlayer({
  required Game game,
  required String playerId,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  Map<String, int> desiredOutputByRecipe = const {},
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
}) {
  final beforePlayer = game.playerById(playerId);
  if (beforePlayer == null) return const {};

  final assignmentsByPlayerId = <String, List<AssignedRecipe>>{
    for (final player in game.players) player.id: const <AssignedRecipe>[],
  };
  assignmentsByPlayerId[playerId] = assignedRecipesFromDesiredOutput(
    desiredOutputByRecipe,
  );

  final after = applyEconomyPhasesForPreview(
    game: game,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    extractedByPlayerId: extractedByPlayerId,
    assignmentsByPlayerId: assignmentsByPlayerId,
  );
  final afterPlayer = after.playerById(playerId);
  if (afterPlayer == null) return const {};

  final deltas = <String, int>{};
  for (final entry in afterPlayer.stockpile.quantities.entries) {
    final before = beforePlayer.stockpile.quantityOf(entry.key);
    final delta = entry.value - before;
    if (delta != 0) deltas[entry.key] = delta;
  }
  for (final entry in beforePlayer.stockpile.quantities.entries) {
    if (!afterPlayer.stockpile.quantities.containsKey(entry.key)) {
      deltas[entry.key] = -entry.value;
    }
  }
  return deltas;
}
