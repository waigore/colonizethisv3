/// Single-pass fleet aggregation for trade/transport interception.
///
/// Extracted from `trade_interception.dart` so the fleet scan is independently
/// testable from the cargo-reduction apply path (Refs #3615 Cluster 4 file
/// decomposition). The scan is a pure function over the fleet list — no `Game`
/// access, no logger, no RNG — safe inside the 15-second next-turn-resolution
/// budget per `SPEC/program/turn-resolution-phases.md` § Determinism.
///
/// SPEC/program/naval-movement-resolution.md (P_cargo_intercept, P_ship_sunk);
/// SPEC/game/ships-and-naval.md § Trade and Transport Interception.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_interception_constants.dart';

/// Aggregated interception/evasion/escort/merchant counters produced by
/// [scanTradeInterceptionInputs].
class TradeInterceptionScan {
  const TradeInterceptionScan({
    required this.interceptScore,
    required this.hasBlockade,
    required this.evasionScore,
    required this.escortStrength,
    required this.playerMerchantShips,
  });

  final double interceptScore;
  final bool hasBlockade;
  final int evasionScore;
  final double escortStrength;
  final int playerMerchantShips;
}

/// Single-pass fleet aggregation for interception/evasion/escort/merchant
/// counters.
///
/// [privateeringEnemyIds] are enemy owner ids with `privateering_companies`
/// unlocked; their intercepting fleets' `interceptRating` contribution is
/// scaled by [kPrivateeringTradeRaidBonus] before aggregation (per-owner,
/// tech-gated).
TradeInterceptionScan scanTradeInterceptionInputs(
  List<Fleet> fleets,
  Set<String> enemyIds,
  String playerId,
  Set<String> privateeringEnemyIds,
) {
  var interceptScore = 0.0;
  var hasBlockade = false;
  var evasionScore = 0;
  var escortStrength = 0.0;
  var playerMerchantShips = 0;
  for (final f in fleets) {
    final isPlayerFleet = f.ownerId == playerId;
    final isEnemyFleet = enemyIds.contains(f.ownerId);
    final canEnemyIntercept =
        f.isAtSea &&
        (f.mission == FleetMission.patrol ||
            f.mission == FleetMission.blockade);
    final privateeringFactor = privateeringEnemyIds.contains(f.ownerId)
        ? kPrivateeringTradeRaidBonus
        : 1.0;

    for (final typeId in f.shipTypeIds) {
      final stats = NavalStatsCatalog.get(typeId);
      if (isEnemyFleet && canEnemyIntercept) {
        interceptScore += stats.interceptRating * privateeringFactor;
      }
      if (!isPlayerFleet) {
        continue;
      }
      evasionScore += stats.fleeRating;
      if (kMerchantShipTypeIds.contains(typeId)) {
        playerMerchantShips++;
        continue;
      }
      escortStrength += stats.fleeRating;
    }
    if (isEnemyFleet &&
        canEnemyIntercept &&
        f.mission == FleetMission.blockade) {
      hasBlockade = true;
    }
  }
  return TradeInterceptionScan(
    interceptScore: interceptScore,
    hasBlockade: hasBlockade,
    evasionScore: evasionScore,
    escortStrength: escortStrength,
    playerMerchantShips: playerMerchantShips,
  );
}
