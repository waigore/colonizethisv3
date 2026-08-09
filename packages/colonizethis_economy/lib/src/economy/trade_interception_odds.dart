import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_interception_constants.dart';
import 'trade_interception_scan.dart';

/// Pure odds bag for cargo intercept and merchant ship loss (Refs #4014).
class TradeInterceptionOdds {
  const TradeInterceptionOdds({
    required this.pCargoEffective,
    required this.pShip,
  });

  final double pCargoEffective;
  final double pShip;
}

/// Computes P_cargo_effective and P_ship from a fleet [scan] (GDD formulas).
TradeInterceptionOdds computeTradeInterceptionOdds(TradeInterceptionScan scan) {
  final total = scan.interceptScore + scan.evasionScore;
  final ratio = total > 0 ? scan.interceptScore / total : 1.0;

  // Escort protection: lossReduction = min(0.5, escortStrength/cargoStrength × 0.3). SPEC.
  final cargoStrength = scan.playerMerchantShips > 0
      ? scan.playerMerchantShips.toDouble()
      : 1.0;
  final escortFactor =
      (scan.escortStrength / cargoStrength * escortStrengthWeight).clamp(
        0.0,
        escortFactorMax,
      );

  // Base before escort: used for cargo (with escort) and for ship loss (escort applied once per GDD).
  double baseBeforeEscort = actionFactorPatrol * ratio * civilianTargetBonus;
  if (scan.hasBlockade) baseBeforeEscort *= blockadeBonusFactor;
  baseBeforeEscort = baseBeforeEscort.clamp(0.0, 1.0);

  final base = baseBeforeEscort * (1.0 - escortFactor);

  final pIntercept = (1.2 * base).clamp(0.1, 0.9);
  final raidEfficiency =
      raidEfficiencyMin + ratio * (raidEfficiencyMax - raidEfficiencyMin);
  final pCargoEffective = (pIntercept * raidEfficiency).clamp(0.0, 1.0);

  // GDD: shipLossChance = baseShipLoss × (1 - escortFactor) × civilianPenalty — escort applied once.
  final baseShipLoss = (0.4 * baseBeforeEscort).clamp(0.0, 1.0);
  final pShip = (baseShipLoss * (1.0 - escortFactor) * civilianShipLossPenalty)
      .clamp(0.02, 0.5);

  return TradeInterceptionOdds(
    pCargoEffective: pCargoEffective,
    pShip: pShip,
  );
}

/// Reduces each commodity quantity by (1 - [pCargoEffective]), dropping zeros.
Map<CommodityId, int> reduceDeliveredForCargoIntercept(
  Map<CommodityId, int> overseasDelivered,
  double pCargoEffective,
) {
  final reducedDelivered = <CommodityId, int>{};
  for (final entry in overseasDelivered.entries) {
    final qty = entry.value;
    final keep = (qty * (1.0 - pCargoEffective)).round();
    if (keep > 0) reducedDelivered[entry.key] = keep;
  }
  return reducedDelivered;
}

/// Deterministic LCG trial: how many of [merchantShipCount] ships are lost.
int countMerchantShipsLost({
  required int merchantShipCount,
  required double pShip,
  required int seed,
}) {
  var rng = seed;
  int nextInt(int max) {
    if (max <= 0) return 0;
    rng =
        (rng * kDeterministicLcgMultiplierGlibc +
            kDeterministicLcgIncrementGlibc) &
        kDeterministicLcg31Mask;
    return rng % max;
  }

  var shipsToRemove = 0;
  for (var i = 0; i < merchantShipCount; i++) {
    if (nextInt(100) < (pShip * 100)) shipsToRemove++;
  }
  return shipsToRemove;
}

/// Removes up to [shipsToRemove] merchant ships from [playerId]'s fleets.
List<Fleet> applyMerchantShipLoss({
  required List<Fleet> fleets,
  required String playerId,
  required int shipsToRemove,
}) {
  if (shipsToRemove <= 0) {
    return fleets;
  }
  var remainingToRemove = shipsToRemove;
  final updatedFleets = <Fleet>[];
  for (final f in fleets) {
    if (f.ownerId != playerId) {
      updatedFleets.add(f);
      continue;
    }
    final inst = List<ShipInstance>.from(f.ships);
    for (var i = inst.length - 1; i >= 0 && remainingToRemove > 0; i--) {
      if (kMerchantShipTypeIds.contains(inst[i].typeId)) {
        inst.removeAt(i);
        remainingToRemove--;
      }
    }
    if (inst.isNotEmpty) {
      updatedFleets.add(f.copyWith(ships: inst));
    }
  }
  return updatedFleets;
}
