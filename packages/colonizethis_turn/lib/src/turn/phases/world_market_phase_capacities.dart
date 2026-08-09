import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Bundles the start-of-phase per-GP market inputs computed in a single
/// player pass: trade cargo capacity, stockpile, raw settlement treasury, and
/// the per-buyer (non-negative) treasury budget. See
/// [computeStartOfPhaseCapacities].
typedef StartOfPhaseCapacities = ({
  Map<String, int> tradeCapacityByFactionId,
  Map<String, Stockpile> stockpileByFactionId,
  Map<String, int> treasuryByFactionId,
  Map<String, int> treasuryBudgetByBuyerFactionId,
});

/// Computes the start-of-phase trade cargo capacity, stockpile, raw treasury,
/// and per-buyer treasury budget for each GP in [gameForMarket] in a single
/// player pass (Refs #3565), then injects the lock-recovery minor synthetic
/// cargo/treasury budgets (Refs #2924 F15). Trade capacity per GP is
/// `max(0, cargoHoldsForHomeFleet − overseasExtractionShippedTonnage)` per
/// `SPEC/game/world-market.md` § Cargo; the buyer budget clamps negative
/// treasuries to `0` per `SPEC/program/world-market-resolution.md` § Step C.
StartOfPhaseCapacities computeStartOfPhaseCapacities({
  required Game gameForMarket,
  required Map<String, int> extractionTonnageByPlayerId,
  required Map<String, List<TradeOrder>> lockRecoveryMinorBidsByFactionId,
}) {
  final fleetsByIdStartOfPhase = fleetsByIdForWorld(gameForMarket.worldState);
  final tradeCapacityByFactionId = <String, int>{};
  final stockpileByFactionId = <String, Stockpile>{};
  final treasuryByFactionId = <String, int>{};
  final treasuryBudgetByBuyerFactionId = <String, int>{};
  for (final player in gameForMarket.players) {
    stockpileByFactionId[player.id] = player.stockpile;
    final homeFleetHolds = cargoHoldsForHomeFleet(
      gameForMarket,
      player.id,
      fleetsById: fleetsByIdStartOfPhase,
    );
    final shippedByExtraction = extractionTonnageByPlayerId[player.id] ?? 0;
    final tradeCapacity = homeFleetHolds - shippedByExtraction;
    tradeCapacityByFactionId[player.id] = tradeCapacity > 0 ? tradeCapacity : 0;
    treasuryBudgetByBuyerFactionId[player.id] = player.treasury > 0
        ? player.treasury
        : 0;
    treasuryByFactionId[player.id] = player.treasury;
  }
  for (final minorId in lockRecoveryMinorBidsByFactionId.keys) {
    tradeCapacityByFactionId[minorId] = kLockRecoveryMinorBidCargoCapacity;
    treasuryBudgetByBuyerFactionId[minorId] =
        kLockRecoveryMinorSyntheticTreasuryBudget;
  }
  return (
    tradeCapacityByFactionId: tradeCapacityByFactionId,
    stockpileByFactionId: stockpileByFactionId,
    treasuryByFactionId: treasuryByFactionId,
    treasuryBudgetByBuyerFactionId: treasuryBudgetByBuyerFactionId,
  );
}

/// Phase-13-only view that floors broke lock-recovery sellers' treasury to `0`
/// for matcher sort/budget (Refs #2924 F15 / #4039). Does not mutate persisted
/// [Player.treasury] on the original [game].
///
/// Returns the clamped view plus the seller-priority id set used by the matcher
/// and deal settlement.
({Game gameForMarket, Set<String> lockRecoverySellerPriorityIds})
applyLockRecoveryTreasuryViewForMarket(Game game) {
  final regimentBuildThreshold = cheapestRegimentBuildTreasuryCost();
  final lockRecoverySellerPriorityIds = <String>{
    for (final player in game.players)
      if (player.treasury < regimentBuildThreshold) player.id,
  };
  if (lockRecoverySellerPriorityIds.isEmpty) {
    return (
      gameForMarket: game,
      lockRecoverySellerPriorityIds: lockRecoverySellerPriorityIds,
    );
  }
  return (
    gameForMarket: game.copyWith(
      players: [
        for (final p in game.players)
          lockRecoverySellerPriorityIds.contains(p.id) && p.treasury < 0
              ? p.copyWith(treasury: 0)
              : p,
      ],
    ),
    lockRecoverySellerPriorityIds: lockRecoverySellerPriorityIds,
  );
}
