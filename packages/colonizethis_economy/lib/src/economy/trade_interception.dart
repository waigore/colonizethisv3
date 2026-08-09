import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';

import 'commodity_totals.dart';
import 'trade_interception_odds.dart';
import 'trade_interception_scan.dart';

export 'trade_interception_odds.dart';

/// Trade/transport interception during extraction auto-transport.
/// SPEC/program/naval-movement-resolution.md (P_cargo_intercept, P_ship_sunk);
/// SPEC/game/ships-and-naval.md § Trade and Transport Interception.
///
/// Only applies when an enemy (at war) has patrol/blockade fleets. Split out of
/// `sea_transport.dart` so cargo allocation and interception are separately
/// testable concerns (Refs #3427 step 7). Tuning constants live in
/// `trade_interception_constants.dart` and the fleet aggregation in
/// `trade_interception_scan.dart` (Refs #3615 Cluster 4 file decomposition).
/// Odds / cargo / ship-loss helpers extracted Refs #4014, #4299.

/// Result of applying trade interception: reduced delivered amounts and fleet updates.
class TradeInterceptionResult {
  const TradeInterceptionResult({
    required this.reducedDelivered,
    required this.updatedFleets,
  });

  final Map<CommodityId, int> reducedDelivered;
  final List<Fleet> updatedFleets;
}

void _logExtractionAutoTransportInterception(
  String playerId,
  Map<CommodityId, int> before,
  Map<CommodityId, int> after,
) {
  if (economyDebugLogSuppressed) return;
  final beforeUnits = sumValues(before.values);
  final afterUnits = sumValues(after.values);
  final ids = {...before.keys, ...after.keys};
  final deltas = <String>[];
  for (final id in ids) {
    final bv = before[id] ?? 0;
    final av = after[id] ?? 0;
    if (bv != av) deltas.add('$id $bv->$av');
  }
  final deltaStr = deltas.isEmpty ? 'none' : deltas.join(';');
  economyLog.d(
    'extraction auto_transport interception playerId=$playerId '
    'deliveredBeforeUnits=$beforeUnits deliveredAfterUnits=$afterUnits '
    'perCommodityDelta=$deltaStr',
  );
}

/// Apply trade interception: reduce delivered cargo and optionally remove merchant ships.
/// Only applies when at least one enemy (at war) has patrol/blockade fleets. Deterministic from [seed].
TradeInterceptionResult applyTradeInterception(
  Game game,
  String playerId,
  Map<CommodityId, int> overseasDelivered, {
  required int seed,
}) {
  if (overseasDelivered.isEmpty) {
    return TradeInterceptionResult(
      reducedDelivered: const {},
      updatedFleets: game.worldState.fleets,
    );
  }

  final enemies = enemiesOf(game, playerId);
  if (enemies.isEmpty) {
    final unchanged = Map<CommodityId, int>.from(overseasDelivered);
    _logExtractionAutoTransportInterception(
      playerId,
      overseasDelivered,
      unchanged,
    );
    return TradeInterceptionResult(
      reducedDelivered: unchanged,
      updatedFleets: game.worldState.fleets,
    );
  }

  final fleets = game.worldState.fleets;
  final privateeringEnemyIds = <String>{
    for (final enemyId in enemies)
      if (game.playerById(enemyId)?.techUnlocked?[kTechIdPrivateeringCompanies] ==
          true)
        enemyId,
  };
  final scan = scanTradeInterceptionInputs(
    fleets,
    enemies,
    playerId,
    privateeringEnemyIds,
  );

  if (scan.interceptScore <= 0) {
    final unchanged = Map<CommodityId, int>.from(overseasDelivered);
    _logExtractionAutoTransportInterception(
      playerId,
      overseasDelivered,
      unchanged,
    );
    return TradeInterceptionResult(
      reducedDelivered: unchanged,
      updatedFleets: game.worldState.fleets,
    );
  }

  final odds = computeTradeInterceptionOdds(scan);
  final reducedDelivered = reduceDeliveredForCargoIntercept(
    overseasDelivered,
    odds.pCargoEffective,
  );
  final shipsToRemove = countMerchantShipsLost(
    merchantShipCount: scan.playerMerchantShips,
    pShip: odds.pShip,
    seed: seed,
  );
  final updatedFleets = applyMerchantShipLoss(
    fleets: fleets,
    playerId: playerId,
    shipsToRemove: shipsToRemove,
  );

  _logExtractionAutoTransportInterception(
    playerId,
    overseasDelivered,
    reducedDelivered,
  );
  return TradeInterceptionResult(
    reducedDelivered: reducedDelivered,
    updatedFleets: updatedFleets,
  );
}
