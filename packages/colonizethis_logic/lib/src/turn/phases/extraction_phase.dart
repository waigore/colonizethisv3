import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../../world/connectivity_resolver.dart';
import '../../economy/economy_extraction.dart';
import '../../economy/resource_extractor.dart';
import '../../economy/sea_transport.dart';
import '../../world/game_world_mutations.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolver_config.dart';
import '../turn_seed_constants.dart';

/// Extraction phase: connectivity, land/overseas extraction, interception.
Game runExtractionPhase(
  Game state,
  MapTopology topology,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId,
) {
  if (extractedByPlayerId.isNotEmpty) {
    return applyExtractionForPlayers(state, extractedByPlayerId);
  }
  if (tileMapByRegion == null || tileMapByRegion.isEmpty) {
    return state;
  }
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
  var currentState = state;
  // Not [Game.mapPlayers]: [currentState] (fleets) may change between players.
  final updatedPlayers = <Player>[];
  final fleetsByIdStartOfPhase = fleetsByIdForWorld(state.worldState);
  var extractionSeed =
      (state.globalGameSeed ?? 0) ^
      (state.worldState.turnState.turnNumber * kTurnResolutionSeedMix);
  for (final player in state.players) {
    var stockpile = player.stockpile;
    final tot = extraction[player.id];
    if (tot != null) {
      stockpile = applyExtractionToStockpile(stockpile, tot.land);
      logExtractionAutoTransportLand(player.id, tot.land);
      final cargoHolds = cargoHoldsForHomeFleet(
        state,
        player.id,
        fleetsById: fleetsByIdStartOfPhase,
      );
      var overseasDelivered = allocateOverseasToStockpile(
        tot.overseas,
        cargoHolds: cargoHolds,
      );
      logExtractionAutoTransportOverseasAllocation(
        playerId: player.id,
        cargoHolds: cargoHolds,
        overseasTotals: tot.overseas,
        allocatedToStockpile: overseasDelivered,
      );
      if (overseasDelivered.isNotEmpty) {
        extractionSeed =
            (extractionSeed * kTurnResolutionLcgMultiplier +
                kTurnResolutionLcgIncrement) &
            kTurnResolutionLcgMask;
        final interception = applyTradeInterception(
          currentState,
          player.id,
          overseasDelivered,
          seed: extractionSeed ^ player.id.hashCode,
        );
        overseasDelivered = interception.reducedDelivered;
        currentState = currentState.withFleets(interception.updatedFleets);
      }
      stockpile = applyExtractionToStockpile(stockpile, overseasDelivered);
    }
    updatedPlayers.add(player.copyWith(stockpile: stockpile));
  }
  return currentState.withPlayers(updatedPlayers);
}

TurnPhaseStepOutcome extractionTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) => TurnPhaseStepContinue(
  acc.copyWith(
    game: runExtractionPhase(
      acc.game,
      config.topology,
      config.tileMapByRegion,
      config.extractedByPlayerId,
    ),
  ),
);
