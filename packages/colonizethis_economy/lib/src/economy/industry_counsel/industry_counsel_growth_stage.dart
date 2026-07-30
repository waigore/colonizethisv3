/// Growth-stage priority vector for industry counsel (AI core path).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../economy_resource_constants.dart';
import '../worker_economy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'industry_counsel_constants.dart';

/// Additive bias so in-stage low-shortage recipes can win.
const double kIndustryCounselGrowthStagePriorityBias = 16.0;

const double kIndustryCounselMinCategoryFloor = 0.1;

const int kIndustryCounselTargetLabourForMaturity = 12;
const int kIndustryCounselTargetFeedstockTileCount = 6;
const int kIndustryCounselMinLabourForMilitary = 6;
const int kIndustryCounselLabourRangeForMilitary = 6;
const int kIndustryCounselReserveTarget = 20;
const double kIndustryCounselAtWarMilitaryFloor = 0.3;

const Set<String> _kCriticalFeedstockResourceIds = {
  'wool',
  'cotton',
  'timber',
  'iron',
  'coal',
};

/// Persistent growth-stage priorities derived from game state.
final class IndustryCounselGrowthStage {
  const IndustryCounselGrowthStage({
    required this.workerGrowthPriority,
    required this.infrastructurePriority,
    required this.resourceProductionPriority,
    required this.militaryPriority,
  });

  final double workerGrowthPriority;
  final double infrastructurePriority;
  final double resourceProductionPriority;
  final double militaryPriority;

  static IndustryCounselGrowthStage compute(Game game, String playerId) {
    final player = game.playerById(playerId);
    if (player == null) {
      return const IndustryCounselGrowthStage(
        workerGrowthPriority: 0,
        infrastructurePriority: 0,
        resourceProductionPriority: 0,
        militaryPriority: 0,
      );
    }

    final effectiveLabour = effectiveLabourForWorkers(
      workers: player.workerPool,
      stockpile: player.stockpile,
    );
    final stockpile = player.stockpile;

    var workerGrowth = _clamp01(
      1.0 - effectiveLabour / kIndustryCounselTargetLabourForMaturity,
    );
    if (stockpile.quantityOf(CommodityCatalog.fabric.id) >=
        kIndustryCounselReserveTarget) {
      workerGrowth *= 0.5;
    }

    var infrastructure = _clamp01(
      1.0 -
          industryCounselProspectedImprovedFeedstockTileCount(
            game,
            playerId,
          ) /
              kIndustryCounselTargetFeedstockTileCount,
    );
    if (stockpile.quantityOf(CommodityCatalog.castIron.id) >=
            kIndustryCounselReserveTarget &&
        stockpile.quantityOf(CommodityCatalog.lumber.id) >=
            kIndustryCounselReserveTarget) {
      infrastructure *= 0.5;
    }

    final maturityFactor = _clamp01(
      effectiveLabour / kIndustryCounselTargetLabourForMaturity,
    );
    final reserveShortfall = _maxReserveShortfall(stockpile);
    final resourceProduction = maturityFactor * reserveShortfall;

    final computedMilitary = _clamp01(
      (effectiveLabour - kIndustryCounselMinLabourForMilitary) /
          kIndustryCounselLabourRangeForMilitary,
    );
    final atWar = _isAtWar(game, playerId);
    final military = atWar
        ? computedMilitary < kIndustryCounselAtWarMilitaryFloor
              ? kIndustryCounselAtWarMilitaryFloor
              : computedMilitary
        : computedMilitary;

    return IndustryCounselGrowthStage(
      workerGrowthPriority: workerGrowth,
      infrastructurePriority: infrastructure,
      resourceProductionPriority: resourceProduction,
      militaryPriority: military,
    );
  }
}

double industryCounselCategoryPriorityForOutput(
  String outputId,
  IndustryCounselGrowthStage stage,
) {
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
  return priority < kIndustryCounselMinCategoryFloor
      ? kIndustryCounselMinCategoryFloor
      : priority;
}

int industryCounselProspectedImprovedFeedstockTileCount(
  Game game,
  String playerId,
) {
  final ws = game.worldState;
  final ownerCache = ProvinceOwnerCache.of(ws);
  final prospected = ws.playerProspectedTiles[playerId] ?? const <String>{};
  var count = 0;
  for (final entry in ws.resourceByTileKey.entries) {
    final resourceId = entry.value;
    if (!_kCriticalFeedstockResourceIds.contains(resourceId)) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null || ownerCache.ownerOf(provinceId) != playerId) {
      continue;
    }
    if (ws.tileState.improvementLevel(entry.key) < 1) continue;
    if (kMineralResourceIds.contains(resourceId) &&
        !prospected.contains(entry.key)) {
      continue;
    }
    count++;
  }
  return count;
}

bool _isAtWar(Game game, String playerId) {
  for (final rel in game.diplomacyRelations) {
    if (!rel.atWar) continue;
    if (rel.involvesNation(playerId)) return true;
  }
  return false;
}

double _maxReserveShortfall(Stockpile stockpile) {
  final fabric = _reserveShortfall(
    stockpile.quantityOf(CommodityCatalog.fabric.id),
  );
  final lumber = _reserveShortfall(
    stockpile.quantityOf(CommodityCatalog.lumber.id),
  );
  final castIron = _reserveShortfall(
    stockpile.quantityOf(CommodityCatalog.castIron.id),
  );
  return fabric > lumber
      ? (fabric > castIron ? fabric : castIron)
      : (lumber > castIron ? lumber : castIron);
}

double _reserveShortfall(int quantity) {
  if (kIndustryCounselReserveTarget <= 0) return 0;
  final ratio = quantity / kIndustryCounselReserveTarget;
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
