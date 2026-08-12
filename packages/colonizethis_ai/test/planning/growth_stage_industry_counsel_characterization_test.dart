// Growth-stage helpers delegate to shared industry counsel economy modules (Refs #4189).

import 'package:colonizethis_ai/src/planning/growth_stage.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../support/growth_stage_industry_counsel_test_support.dart';

void main() {
  group('growth stage industry counsel delegation', () {
    test('categoryPriorityForOutput matches industryCounselCategoryPriorityForOutput',
        () {
      const stage = GrowthStage(
        workerGrowthPriority: 0.8,
        infrastructurePriority: 0.4,
        resourceProductionPriority: 0.6,
        militaryPriority: 0.2,
      );
      const counselStage = IndustryCounselGrowthStage(
        workerGrowthPriority: 0.8,
        infrastructurePriority: 0.4,
        resourceProductionPriority: 0.6,
        militaryPriority: 0.2,
      );
      for (final outputId in [
        CommodityCatalog.fabric.id,
        CommodityCatalog.lumber.id,
        CommodityCatalog.steel.id,
        CommodityCatalog.grain.id,
      ]) {
        expect(
          categoryPriorityForOutput(outputId, stage),
          industryCounselCategoryPriorityForOutput(outputId, counselStage),
        );
      }
    });

    test('prospectedImprovedFeedstockTileCount matches economy helper', () {
      final game = growthStageIndustryCounselFeedstockTileGame();
      expect(
        prospectedImprovedFeedstockTileCount(game, 'gp1'),
        industryCounselProspectedImprovedFeedstockTileCount(game, 'gp1'),
      );
    });
  });
}
