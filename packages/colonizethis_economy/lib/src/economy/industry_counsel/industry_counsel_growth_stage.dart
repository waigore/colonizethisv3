/// Growth-stage priority computation for industry counsel (AI core path).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../worker_economy.dart';
import 'industry_counsel_constants.dart';
import 'industry_counsel_growth_stage_category.dart';

export 'industry_counsel_growth_stage_category.dart';

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

    var workerGrowth = industryCounselClamp01(
      1.0 - effectiveLabour / kIndustryCounselTargetLabourForMaturity,
    );
    if (stockpile.quantityOf(CommodityCatalog.fabric.id) >=
        kIndustryCounselReserveTarget) {
      workerGrowth *= 0.5;
    }

    var infrastructure = industryCounselClamp01(
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

    final maturityFactor = industryCounselClamp01(
      effectiveLabour / kIndustryCounselTargetLabourForMaturity,
    );
    final reserveShortfall = industryCounselMaxReserveShortfall(stockpile);
    final resourceProduction = maturityFactor * reserveShortfall;

    final computedMilitary = industryCounselClamp01(
      (effectiveLabour - kIndustryCounselMinLabourForMilitary) /
          kIndustryCounselLabourRangeForMilitary,
    );
    final atWar = industryCounselPlayerIsAtWar(game, playerId);
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

/// Category priority for one recipe output given a growth-stage vector.
double industryCounselCategoryPriorityForOutput(
  String outputId,
  IndustryCounselGrowthStage stage,
) =>
    industryCounselCategoryPriorityForFields(
      outputId,
      workerGrowthPriority: stage.workerGrowthPriority,
      infrastructurePriority: stage.infrastructurePriority,
      resourceProductionPriority: stage.resourceProductionPriority,
      militaryPriority: stage.militaryPriority,
    );
