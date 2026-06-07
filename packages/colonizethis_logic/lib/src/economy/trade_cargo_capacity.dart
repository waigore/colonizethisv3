/// Trade cargo capacity forecast for AI treasury planning (Refs #2924 F11).
///
/// World-market matching subtracts overseas extraction tonnage from home-fleet
/// cargo holds (`SPEC/game/world-market.md` § Cargo). The treasury planner must
/// use the same formula when sizing bids or emitted orders never clear.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'package:colonizethis_world/src/world/connectivity_resolver.dart';
import 'resource_extractor.dart';
import 'sea_transport.dart';

/// Sum of overseas units committed to cargo this turn (pre-interception).
int overseasShippedTonnageFromExtractionTotals(
  Map<CommodityId, int> overseasTotals, {
  required int homeFleetCargoHolds,
}) {
  if (overseasTotals.isEmpty || homeFleetCargoHolds <= 0) {
    return 0;
  }
  final delivered = allocateOverseasToStockpile(
    overseasTotals,
    cargoHolds: homeFleetCargoHolds,
  );
  var shipped = 0;
  for (final quantity in delivered.values) {
    shipped += quantity;
  }
  return shipped;
}

/// Forecasts overseas shipped tonnage for [playerId] using the same extraction
/// and cargo-cap rules as [runExtractionPhase]. Returns `0` when tile maps are
/// unavailable.
int forecastOverseasShippedTonnageForPlayer({
  required Game game,
  required String playerId,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
  Map<String, Fleet>? fleetsById,
}) {
  if (tileMapByRegion.isEmpty) return 0;
  final connectivity = resolveConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  final extraction = computeExtraction(
    game: game,
    tileMapByRegion: tileMapByRegion,
    connectivityResult: connectivity,
    techCapForPlayerAndResource: (pid, resourceId) {
      final player = game.playerById(pid);
      return extractionCapForResourceForUnlocked(
        player?.techUnlocked,
        resourceId,
      );
    },
  );
  final totals = extraction[playerId];
  if (totals == null || totals.overseas.isEmpty) {
    return 0;
  }
  final homeFleetHolds = cargoHoldsForHomeFleet(
    game,
    playerId,
    fleetsById: fleetsById,
  );
  return overseasShippedTonnageFromExtractionTotals(
    totals.overseas,
    homeFleetCargoHolds: homeFleetHolds,
  );
}

/// `max(0, cargoHoldsForHomeFleet − forecast overseas shipped tonnage)`.
int tradeCargoCapacityForGreatPower({
  required Game game,
  required String playerId,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
  Map<String, Fleet>? fleetsById,
}) {
  final homeFleetHolds = cargoHoldsForHomeFleet(
    game,
    playerId,
    fleetsById: fleetsById,
  );
  if (homeFleetHolds <= 0) return 0;
  final shipped = forecastOverseasShippedTonnageForPlayer(
    game: game,
    playerId: playerId,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
    fleetsById: fleetsById,
  );
  final capacity = homeFleetHolds - shipped;
  return capacity > 0 ? capacity : 0;
}
