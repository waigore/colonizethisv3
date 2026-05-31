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
///
/// When [overseasShippedTonnageOut] is supplied, the function additionally
/// records the post-cargo-cap, pre-interception overseas tonnage actually
/// shipped per Great Power into the supplied map (keyed by player id). Those
/// holds are committed at departure regardless of any later trade
/// interception losses, so they consume ship capacity for the rest of the
/// turn. Callers that need the cargo-released-to-trade signal documented in
/// `SPEC/game/world-market.md` § Cargo (the *Cargo released by under-used
/// extraction* AC) pass a mutable map; legacy callers omit the parameter and
/// retain the existing behaviour (no tonnage accounting). The scripted
/// `extractedByPlayerId` fast path bypasses auto-transport entirely, so no
/// tonnage entries are recorded for that path.
Game runExtractionPhase(
  Game state,
  MapTopology topology,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId, {
  Map<String, int>? overseasShippedTonnageOut,
}) {
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
      // Record the cargo-holds actually committed to overseas trade this
      // turn before interception adjusts the delivered map. The holds are
      // used at departure, so this is the correct value to subtract from
      // the home-fleet cargo when computing trade cargo capacity in phase
      // 13 (see SPEC/game/world-market.md § Cargo).
      if (overseasShippedTonnageOut != null && overseasDelivered.isNotEmpty) {
        var shipped = 0;
        for (final v in overseasDelivered.values) {
          shipped += v;
        }
        if (shipped > 0) {
          overseasShippedTonnageOut[player.id] =
              (overseasShippedTonnageOut[player.id] ?? 0) + shipped;
        }
      }
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
) {
  // Capture per-player overseas tonnage actually shipped so the world
  // market phase (#2990, B2 follow-up) can subtract it from the
  // home-fleet cargo when computing trade cargo capacity. See
  // SPEC/game/world-market.md § Cargo — AC "Cargo released by under-used
  // extraction".
  final shippedTonnageByPlayerId = <String, int>{};
  final nextGame = runExtractionPhase(
    acc.game,
    config.topology,
    config.tileMapByRegion,
    config.extractedByPlayerId,
    overseasShippedTonnageOut: shippedTonnageByPlayerId,
  );
  return TurnPhaseStepContinue(
    acc.copyWith(
      game: nextGame,
      overseasExtractionShippedTonnageByPlayerId: shippedTonnageByPlayerId,
    ),
  );
}
