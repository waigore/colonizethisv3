/// Growth-stage category priority and feedstock helpers (AI core path).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../economy_resource_constants.dart';
import 'industry_counsel_constants.dart';

double industryCounselCategoryPriorityForFields(
  String outputId, {
  required double workerGrowthPriority,
  required double infrastructurePriority,
  required double resourceProductionPriority,
  required double militaryPriority,
}) {
  final fabricId = CommodityCatalog.fabric.id;
  final castIronId = CommodityCatalog.castIron.id;
  final lumberId = CommodityCatalog.lumber.id;

  double priority;
  if (outputId == fabricId) {
    priority = workerGrowthPriority > resourceProductionPriority
        ? workerGrowthPriority
        : resourceProductionPriority;
  } else if (outputId == castIronId || outputId == lumberId) {
    priority = infrastructurePriority > resourceProductionPriority
        ? infrastructurePriority
        : resourceProductionPriority;
  } else if (_isMilitaryOutput(outputId) || _isLuxuryOutput(outputId)) {
    priority = militaryPriority;
  } else {
    priority = _maxOfFour(
      workerGrowthPriority,
      infrastructurePriority,
      resourceProductionPriority,
      militaryPriority,
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
    if (!kIndustryCounselCriticalFeedstockResourceIds.contains(resourceId)) {
      continue;
    }
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

bool industryCounselPlayerIsAtWar(Game game, String playerId) {
  for (final rel in game.diplomacyRelations) {
    if (!rel.atWar) continue;
    if (rel.involvesNation(playerId)) return true;
  }
  return false;
}

double industryCounselMaxReserveShortfall(Stockpile stockpile) {
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

double industryCounselClamp01(double value) {
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
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

double _reserveShortfall(int quantity) {
  if (kIndustryCounselReserveTarget <= 0) return 0;
  final ratio = quantity / kIndustryCounselReserveTarget;
  final shortfall = 1.0 - ratio;
  return shortfall < 0 ? 0 : shortfall;
}

double _maxOfFour(double a, double b, double c, double d) {
  var max = a;
  if (b > max) max = b;
  if (c > max) max = c;
  if (d > max) max = d;
  return max;
}
