/// Trade cargo capacity forecast for AI treasury planning (Refs #2924 F11).
///
/// World-market matching subtracts overseas extraction tonnage from home-fleet
/// cargo holds (`SPEC/game/world-market.md` § Cargo). The treasury planner must
/// use the same formula when sizing bids or emitted orders never clear.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart'
    show GamePlayerLookup, resolveConnectivity;
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

/// Computes per-player [ExtractionTotals] using the same connectivity and
/// tech-cap rules as [forecastOverseasShippedTonnageForPlayer], so callers
/// that drive multiple trade-cargo forecasts in one planning pass can build
/// the map **once** and reuse it (Refs #3517 Cluster 4 — avoids the duplicate
/// O(players × connected-tiles) [computeExtraction] scan the treasury planner
/// otherwise re-runs on every invocation; see
/// `colonizethis-turn-resolution-budget.mdc` § duplicate global scans).
///
/// Returns an empty map when [tileMapByRegion] is empty (the same condition
/// under which [forecastOverseasShippedTonnageForPlayer] forecasts `0`).
Map<String, ExtractionTotals> computeExtractionTotalsForTradeForecast({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
}) {
  if (tileMapByRegion.isEmpty) return const <String, ExtractionTotals>{};
  final connectivity = resolveConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  return computeExtraction(
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
}

/// Forecasts overseas shipped tonnage for [playerId] using the same extraction
/// and cargo-cap rules as [runExtractionPhase]. Returns `0` when tile maps are
/// unavailable.
///
/// When [extractionById] is supplied (a map produced by
/// [computeExtractionTotalsForTradeForecast] earlier in the same planning
/// pass), the per-call [computeExtraction] scan is skipped and the player's
/// overseas totals are read directly from the map (Refs #3517 Cluster 4).
/// When it is `null`, the extraction map is computed on demand, preserving the
/// previous behaviour for callers outside the AI planning pipeline.
int forecastOverseasShippedTonnageForPlayer({
  required Game game,
  required String playerId,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
  Map<String, Fleet>? fleetsById,
  Map<String, ExtractionTotals>? extractionById,
}) {
  if (tileMapByRegion.isEmpty) return 0;
  final extraction =
      extractionById ??
      computeExtractionTotalsForTradeForecast(
        game: game,
        tileMapByRegion: tileMapByRegion,
        topology: topology,
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
///
/// [extractionById] is forwarded to [forecastOverseasShippedTonnageForPlayer]
/// so a pre-computed extraction map (Refs #3517 Cluster 4) bypasses the
/// per-call [computeExtraction] scan.
int tradeCargoCapacityForGreatPower({
  required Game game,
  required String playerId,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
  Map<String, Fleet>? fleetsById,
  Map<String, ExtractionTotals>? extractionById,
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
    extractionById: extractionById,
  );
  final capacity = homeFleetHolds - shipped;
  return capacity > 0 ? capacity : 0;
}
