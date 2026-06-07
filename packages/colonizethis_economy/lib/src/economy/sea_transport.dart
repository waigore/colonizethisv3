import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import 'package:colonizethis_world/src/world/diplomatic_relation_lookup.dart';
import 'package:colonizethis_world/src/world/naval.dart';

/// Sea transport: allocate overseas extraction to stockpile by priority. SPEC/program/auto-transport.
/// Trade/transport interception: SPEC/program/naval-movement-resolution.md (P_cargo_intercept, P_ship_sunk).
///
/// Phase 2: cargo holds derived from home fleet (with stub fallback). Fill by priority until cap; rest left behind.

/// Default cargo holds per player when no ships or no cargoHold data.
/// Sensible default per SPEC/program/extraction-pipeline.md § Cargo holds (GDD convention-over-configuration).
const int defaultCargoHoldsStub = 24;

/// Priority order for filling cargo: food, raw materials, riches, then manufactured/advanced.
/// Note: CommodityCategory.luxury exists but no commodity currently has that category assigned,
/// so it's excluded from priority until luxury is defined in the commodity catalog.
final List<CommodityCategory> _seaPriorityOrder = [
  CommodityCategory.food,
  CommodityCategory.rawMaterial,
  CommodityCategory.riches,
  CommodityCategory.manufactured,
  CommodityCategory.advanced,
];

/// Allocates [overseasTotals] to delivered amounts, filling up to [cargoHolds] units total
/// by [priorityOrder] (default: food, raw, riches, manufactured, advanced).
/// Returns the map of commodity id → quantity to add to stockpile.
Map<CommodityId, int> allocateOverseasToStockpile(
  Map<CommodityId, int> overseasTotals, {
  int cargoHolds = defaultCargoHoldsStub,
  List<CommodityCategory>? priorityOrder,
}) {
  final order = priorityOrder ?? _seaPriorityOrder;
  final remaining = Map<CommodityId, int>.from(overseasTotals);
  var spaceLeft = cargoHolds;
  final delivered = <CommodityId, int>{};

  for (final category in order) {
    if (spaceLeft <= 0) break;
    for (final c in CommodityCatalog.all) {
      if (c.category != category) continue;
      final id = c.id;
      final available = remaining[id] ?? 0;
      if (available <= 0) continue;
      final take = available < spaceLeft ? available : spaceLeft;
      if (take <= 0) continue;
      delivered[id] = (delivered[id] ?? 0) + take;
      remaining[id] = available - take;
      spaceLeft -= take;
    }
  }

  return delivered;
}

/// Debug logging for overseas cargo-cap allocation during extraction auto-transport.
/// SPEC/program/auto-transport.md; grep token `extraction auto_transport overseas`.
void logExtractionAutoTransportOverseasAllocation({
  required String playerId,
  required int cargoHolds,
  required Map<CommodityId, int> overseasTotals,
  required Map<CommodityId, int> allocatedToStockpile,
}) {
  if (overseasTotals.isEmpty) return;
  if (Level.debug.value < Logger.level.value) return;
  final overseasTotalUnits = overseasTotals.values.fold<int>(
    0,
    (a, b) => a + b,
  );
  final allocatedUnits = allocatedToStockpile.values.fold<int>(
    0,
    (a, b) => a + b,
  );
  final detail = allocatedToStockpile.entries
      .map((e) => '${e.key}=${e.value}')
      .join(',');
  economyLog.d(
    'extraction auto_transport overseas cargo_cap playerId=$playerId '
    'cargoHolds=$cargoHolds overseasTotalUnits=$overseasTotalUnits '
    'allocatedUnits=$allocatedUnits allocatedDetail=$detail',
  );
}

void _logExtractionAutoTransportInterception(
  String playerId,
  Map<CommodityId, int> before,
  Map<CommodityId, int> after,
) {
  if (Level.debug.value < Logger.level.value) return;
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

/// Single-pass index of [WorldState.fleets] by fleet id for O(1) lookups (Refs #2394).
///
/// Callers that iterate all players should build once per stable [WorldState] snapshot
/// instead of rescanning [WorldState.fleets] per player.
Map<String, Fleet> fleetsByIdForWorld(WorldState world) {
  return {for (final f in world.fleets) f.id: f};
}

/// Total cargo holds for [playerId] based on ships in the home fleet at the capital port.
///
/// Home fleet convention: fleet id = `fleet_<playerId>`. Each ship's cargoHold is read from
/// NavalStatsCatalog; if no such fleet exists or the sum of cargoHold values is zero, this
/// falls back to [defaultCargoHoldsStub] per SPEC/program/extraction-pipeline.md § Cargo holds.
///
/// When [fleetsById] is supplied (typically from [fleetsByIdForWorld] built once per pass),
/// home-fleet resolution is O(1) instead of scanning [WorldState.fleets] per call.
int cargoHoldsForHomeFleet(
  Game game,
  String playerId, {
  Map<String, Fleet>? fleetsById,
}) {
  final homeFleetId = homeFleetIdFor(playerId);
  final Fleet? homeFleet;
  if (fleetsById != null) {
    final f = fleetsById[homeFleetId];
    homeFleet = (f != null && f.ownerId == playerId) ? f : null;
  } else {
    Fleet? found;
    for (final f in game.worldState.fleets) {
      if (f.id == homeFleetId && f.ownerId == playerId) {
        found = f;
        break;
      }
    }
    homeFleet = found;
  }
  if (homeFleet == null) {
    return defaultCargoHoldsStub;
  }
  var total = 0;
  for (final typeId in homeFleet.shipTypeIds) {
    total += NavalStatsCatalog.get(typeId).cargoHold;
  }
  // When a home fleet exists but has no cargo-capable ships, capacity is 0.
  return total;
}

// --- Trade/transport interception (Phase 6). Only when interceptor is at war with owner. ---
// SPEC/game/ships-and-naval.md § Trade and Transport Interception.

/// Civilian target bonus for cargo interception. SPEC: 1.25–1.5.
const double civilianTargetBonus = 1.25;

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

  final int interceptScore;
  final bool hasBlockade;
  final int evasionScore;
  final double escortStrength;
  final int playerMerchantShips;
}

/// Single-pass fleet aggregation for interception/evasion/escort/merchant counters.
_TradeInterceptionScan _scanTradeInterceptionInputs(
  List<Fleet> fleets,
  Set<String> enemyIds,
  String playerId,
) {
  var interceptScore = 0;
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

    for (final typeId in f.shipTypeIds) {
      final stats = NavalStatsCatalog.get(typeId);
      if (isEnemyFleet && canEnemyIntercept) {
        interceptScore += stats.interceptRating;
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

/// Merchant ship type ids (civilian); others count as escort/warship. SPEC/game/ships-and-naval.md.
const Set<String> _merchantShipTypes = {'fluyte', 'carrack'};

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
  final scan = _scanTradeInterceptionInputs(fleets, enemies, playerId);

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
