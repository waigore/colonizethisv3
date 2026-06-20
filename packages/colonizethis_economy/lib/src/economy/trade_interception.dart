import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';

/// Trade/transport interception during extraction auto-transport.
/// SPEC/program/naval-movement-resolution.md (P_cargo_intercept, P_ship_sunk);
/// SPEC/game/ships-and-naval.md § Trade and Transport Interception.
///
/// Only applies when an enemy (at war) has patrol/blockade fleets. Split out of
/// `sea_transport.dart` so cargo allocation and interception are separately
/// testable concerns (Refs #3427 step 7).

/// Civilian target bonus for cargo interception. SPEC: 1.25–1.5.
const double civilianTargetBonus = 1.25;

/// Privateering doctrine bonus to trade/transport raid effectiveness.
///
/// Applied as a single multiplicative factor to the `interceptRating`
/// contribution of intercepting enemy fleets whose owner has
/// `privateering_companies` unlocked, before the `ratio`/`base` terms and the
/// documented cargo/ship clamps. Deterministic, no ruleset lookup.
/// SPEC/program/naval-movement-resolution.md § Trade/Transport Interception.
const double kPrivateeringTradeRaidBonus = 1.25;

/// Action factor for patrol (baseline).
const double actionFactorPatrol = 0.5;

/// Blockade bonus multiplier when interceptor has Blockade mission (vs Patrol).
const double blockadeBonusFactor = 1.5;

/// Escort protection: max loss reduction from strong escorts. SPEC: 50%.
const double escortFactorMax = 0.5;

/// Escort strength weight in loss reduction formula. SPEC: escortStrength/cargoStrength × 0.3.
const double escortStrengthWeight = 0.3;

/// Civilian ships twice as vulnerable to ship loss. SPEC: civilianPenalty = 2.0.
const double civilianShipLossPenalty = 2.0;

/// Raid efficiency range (min–max) for cargo loss. SPEC: 0.3 to 0.7 depending on relative strength.
const double raidEfficiencyMin = 0.3;
const double raidEfficiencyMax = 0.7;

/// Merchant ship type ids (civilian); others count as escort/warship. SPEC/game/ships-and-naval.md.
const Set<String> _merchantShipTypes = {'fluyte', 'carrack'};

/// Result of applying trade interception: reduced delivered amounts and fleet updates.
class TradeInterceptionResult {
  const TradeInterceptionResult({
    required this.reducedDelivered,
    required this.updatedFleets,
  });

  final Map<CommodityId, int> reducedDelivered;
  final List<Fleet> updatedFleets;
}

class _TradeInterceptionScan {
  const _TradeInterceptionScan({
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

/// Single-pass fleet aggregation for interception/evasion/escort/merchant counters.
///
/// [privateeringEnemyIds] are enemy owner ids with `privateering_companies`
/// unlocked; their intercepting fleets' `interceptRating` contribution is scaled
/// by [kPrivateeringTradeRaidBonus] before aggregation (per-owner, tech-gated).
_TradeInterceptionScan _scanTradeInterceptionInputs(
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
      if (_merchantShipTypes.contains(typeId)) {
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
  return _TradeInterceptionScan(
    interceptScore: interceptScore,
    hasBlockade: hasBlockade,
    evasionScore: evasionScore,
    escortStrength: escortStrength,
    playerMerchantShips: playerMerchantShips,
  );
}

void _logExtractionAutoTransportInterception(
  String playerId,
  Map<CommodityId, int> before,
  Map<CommodityId, int> after,
) {
  if (economyDebugLogSuppressed) return;
  final beforeUnits = before.values.fold<int>(0, (s, v) => s + v);
  final afterUnits = after.values.fold<int>(0, (s, v) => s + v);
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
  final scan = _scanTradeInterceptionInputs(
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

  double base = baseBeforeEscort * (1.0 - escortFactor);

  final pIntercept = (1.2 * base).clamp(0.1, 0.9);
  final raidEfficiency =
      raidEfficiencyMin + ratio * (raidEfficiencyMax - raidEfficiencyMin);
  final pCargoEffective = (pIntercept * raidEfficiency).clamp(0.0, 1.0);

  // GDD: shipLossChance = baseShipLoss × (1 - escortFactor) × civilianPenalty — escort applied once.
  final baseShipLoss = (0.4 * baseBeforeEscort).clamp(0.0, 1.0);
  final pShip = (baseShipLoss * (1.0 - escortFactor) * civilianShipLossPenalty)
      .clamp(0.02, 0.5);

  final reducedDelivered = <CommodityId, int>{};
  for (final entry in overseasDelivered.entries) {
    final qty = entry.value;
    final keep = (qty * (1.0 - pCargoEffective)).round();
    if (keep > 0) reducedDelivered[entry.key] = keep;
  }

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
  for (var i = 0; i < scan.playerMerchantShips; i++) {
    if (nextInt(100) < (pShip * 100)) shipsToRemove++;
  }
  if (shipsToRemove <= 0) {
    _logExtractionAutoTransportInterception(
      playerId,
      overseasDelivered,
      reducedDelivered,
    );
    return TradeInterceptionResult(
      reducedDelivered: reducedDelivered,
      updatedFleets: game.worldState.fleets,
    );
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
      if (_merchantShipTypes.contains(inst[i].typeId)) {
        inst.removeAt(i);
        remainingToRemove--;
      }
    }
    if (inst.isNotEmpty) {
      updatedFleets.add(f.copyWith(ships: inst));
    }
  }

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
