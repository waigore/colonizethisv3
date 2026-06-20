// Growth-stage priority vector for economy planning. SPEC/ai/growth-stage-planner.md.

import '../perception/perception_snapshot.dart';
import 'planning_imports.dart';

/// When true, growth-stage scoring replaces H8 reactive boosts in the economy
/// planner. Default off until AC7 seed-42 calibration passes (Refs #3371).
const bool kGrowthStagePlannerEnabled = false;

/// Effective labour at which worker growth priority reaches ~0.
const int kTargetLabourForMaturity = 12;

/// Improved feedstock tiles at which infrastructure priority reaches ~0.
const int kTargetFeedstockTileCount = 6;

/// Effective labour below which computed military priority is 0.
const int kMinLabourForMilitary = 6;

/// Labour span over which military priority ramps 0→1.
const int kLabourRangeForMilitary = 6;

/// Per-commodity reserve target for stockpile damping.
const int kReserveTarget = 20;

/// Minimum military priority for an at-war GP.
const double kAtWarMilitaryFloor = 0.3;

/// Additive bias (≈ max shortage) so in-stage low-shortage recipes can win.
const double kStagePriorityBias = 16.0;

/// Minimum category priority so a critically short off-stage recipe is not zeroed.
const double kMinCategoryFloor = 0.1;

/// Minimum peasant-recruit score scaling for mature GPs.
const double kRecruitmentFloor = 0.25;

/// Military priority below which regiment/ship builds are suppressed.
const double kMilitaryBuildSuppressionThreshold = 0.2;

const Set<String> _kCriticalFeedstockResourceIds = {
  'wool',
  'cotton',
  'timber',
  'iron',
  'coal',
};

/// Persistent growth-stage priorities derived each turn from game state.
class GrowthStage {
  const GrowthStage({
    required this.workerGrowthPriority,
    required this.infrastructurePriority,
    required this.resourceProductionPriority,
    required this.militaryPriority,
  });

  final double workerGrowthPriority;
  final double infrastructurePriority;
  final double resourceProductionPriority;
  final double militaryPriority;

  /// Pure, deterministic priority vector for one GP (Refs #3371 AC10).
  static GrowthStage compute(
    Game game,
    String playerId, {
    AIWorldSnapshot? snapshot,
  }) {
    final player = game.playerById(playerId);
    if (player == null) {
      return const GrowthStage(
        workerGrowthPriority: 0,
        infrastructurePriority: 0,
        resourceProductionPriority: 0,
        militaryPriority: 0,
      );
    }

    final regimentCounts = regimentTypeCountsForPlayer(
      game.worldState,
      playerId,
    );
    final shipCounts = shipTypeCountsForPlayer(game.worldState, playerId);
    final effectiveLabour = effectiveLabourForWorkers(
      workers: player.workerPool,
      stockpile: player.stockpile,
      regimentCountsById: regimentCounts,
      shipCountsById: shipCounts,
    );
    final stockpile = player.stockpile;

    var workerGrowth = _clamp01(
      1.0 - effectiveLabour / kTargetLabourForMaturity,
    );
    if (stockpile.quantityOf(CommodityCatalog.fabric.id) >= kReserveTarget) {
      workerGrowth *= 0.5;
    }

    var infrastructure = _clamp01(
      1.0 -
          prospectedImprovedFeedstockTileCount(game, playerId) /
              kTargetFeedstockTileCount,
    );
    if (stockpile.quantityOf(CommodityCatalog.castIron.id) >= kReserveTarget &&
        stockpile.quantityOf(CommodityCatalog.lumber.id) >= kReserveTarget) {
      infrastructure *= 0.5;
    }

    final maturityFactor = _clamp01(
      effectiveLabour / kTargetLabourForMaturity,
    );
    final reserveShortfall = _maxReserveShortfall(stockpile);
    final resourceProduction = maturityFactor * reserveShortfall;

    final computedMilitary = _clamp01(
      (effectiveLabour - kMinLabourForMilitary) / kLabourRangeForMilitary,
    );
    final atWar = _isAtWar(game, playerId, snapshot: snapshot);
    final military = atWar
        ? computedMilitary < kAtWarMilitaryFloor
              ? kAtWarMilitaryFloor
              : computedMilitary
        : computedMilitary;

    return GrowthStage(
      workerGrowthPriority: workerGrowth,
      infrastructurePriority: infrastructure,
      resourceProductionPriority: resourceProduction,
      militaryPriority: military,
    );
  }
}

/// True when growth-stage military priority is below the build-suppression
/// threshold (Refs #3371 AC4).
bool growthStageSuppressesMilitaryBuilds(GrowthStage stage) {
  return stage.militaryPriority < kMilitaryBuildSuppressionThreshold;
}

/// Peasant-recruit action score scale (Refs #3371 AC12).
double peasantRecruitScoreScale(GrowthStage stage) {
  final scaled = stage.workerGrowthPriority;
  return scaled < kRecruitmentFloor ? kRecruitmentFloor : scaled;
}

/// True when a GP should reserve its scarce `fabric` to fund a regiment build
/// instead of spending it on the fabric-costing peasant-recruit worker action
/// (Refs #3371 AC13).
///
/// Targets the seed-42 gp3 failure mode: a below-quota GP at war with treasury
/// at or above the cheapest regiment cost and an invadable frontier holds the
/// treasury to rebuild but never sources the lone `fabric` build input because
/// the peasant-recruit action (`materialCosts: {fabric: 2}`) drains the same
/// scarce fabric first. Reservation is active only when:
///
/// - military builds are **not** suppressed (`militaryPriority >=
///   kMilitaryBuildSuppressionThreshold`), so a pure bootstrap GP keeps growing
///   workers;
/// - the GP can already afford the cheapest regiment
///   (`treasury >= cheapestRegimentTreasuryCost`); and
/// - `fabric` is scarce (`fabricHeld < kReserveTarget`) — a mature GP with full
///   fabric reserves keeps recruiting peasants.
///
/// Pure and deterministic given its inputs.
bool growthStageReservesFabricForMilitary({
  required GrowthStage stage,
  required int treasury,
  required int fabricHeld,
  required int cheapestRegimentTreasuryCost,
}) {
  if (stage.militaryPriority < kMilitaryBuildSuppressionThreshold) return false;
  if (treasury < cheapestRegimentTreasuryCost) return false;
  if (fabricHeld >= kReserveTarget) return false;
  return true;
}

/// Category priority for a recipe output under [stage].
double categoryPriorityForOutput(String outputId, GrowthStage stage) {
  final fabricId = CommodityCatalog.fabric.id;
  final castIronId = CommodityCatalog.castIron.id;
  final lumberId = CommodityCatalog.lumber.id;

  double priority;
  if (outputId == fabricId) {
    priority = stage.workerGrowthPriority > stage.resourceProductionPriority
        ? stage.workerGrowthPriority
        : stage.resourceProductionPriority;
  } else if (outputId == castIronId || outputId == lumberId) {
    priority = stage.infrastructurePriority > stage.resourceProductionPriority
        ? stage.infrastructurePriority
        : stage.resourceProductionPriority;
  } else if (_isMilitaryOutput(outputId) || _isLuxuryOutput(outputId)) {
    priority = stage.militaryPriority;
  } else {
    priority = _maxOfFour(
      stage.workerGrowthPriority,
      stage.infrastructurePriority,
      stage.resourceProductionPriority,
      stage.militaryPriority,
    );
  }
  return priority < kMinCategoryFloor ? kMinCategoryFloor : priority;
}

int prospectedImprovedFeedstockTileCount(Game game, String playerId) {
  final ws = game.worldState;
  final ownerByProvince = getProvinceOwnerMap(game);
  final prospected = ws.playerProspectedTiles[playerId] ?? const <String>{};
  var count = 0;
  for (final entry in ws.resourceByTileKey.entries) {
    final resourceId = entry.value;
    if (!_kCriticalFeedstockResourceIds.contains(resourceId)) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (ownerByProvince[provinceId] != playerId) continue;
    if (ws.tileState.improvementLevel(entry.key) < 1) continue;
    if (kMineralResourceIds.contains(resourceId) &&
        !prospected.contains(entry.key)) {
      continue;
    }
    count++;
  }
  return count;
}

bool _isAtWar(
  Game game,
  String playerId, {
  AIWorldSnapshot? snapshot,
}) {
  if (snapshot != null) {
    if (snapshot.threats.atWarWith.isNotEmpty) return true;
    if (snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty) return true;
    return false;
  }
  for (final rel in game.diplomacyRelations) {
    if (!rel.atWar) continue;
    if (rel.involvesNation(playerId)) return true;
  }
  return false;
}

double _maxReserveShortfall(Stockpile stockpile) {
  final fabricId = CommodityCatalog.fabric.id;
  final lumberId = CommodityCatalog.lumber.id;
  final castIronId = CommodityCatalog.castIron.id;
  final fabric = _reserveShortfall(
    stockpile.quantityOf(fabricId),
  );
  final lumber = _reserveShortfall(stockpile.quantityOf(lumberId));
  final castIron = _reserveShortfall(stockpile.quantityOf(castIronId));
  return fabric > lumber
      ? (fabric > castIron ? fabric : castIron)
      : (lumber > castIron ? lumber : castIron);
}

double _reserveShortfall(int quantity) {
  if (kReserveTarget <= 0) return 0;
  final ratio = quantity / kReserveTarget;
  final shortfall = 1.0 - ratio;
  return shortfall < 0 ? 0 : shortfall;
}

bool _isMilitaryOutput(String outputId) {
  return outputId == CommodityCatalog.steel.id ||
      outputId == CommodityCatalog.bronze.id;
}

bool _isLuxuryOutput(String outputId) {
  return outputId == CommodityCatalog.refinedSugar.id ||
      outputId == CommodityCatalog.cigars.id ||
      outputId == CommodityCatalog.furHats.id;
}

double _clamp01(double value) {
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}

double _maxOfFour(double a, double b, double c, double d) {
  var max = a;
  if (b > max) max = b;
  if (c > max) max = c;
  if (d > max) max = d;
  return max;
}
