// AI recipe scoring wrappers delegate to shared industry counsel economy modules
// (Refs #4189 AC1).

import 'package:colonizethis_ai/src/planning/growth_stage.dart';
import 'package:colonizethis_ai/src/planning/recipe_scoring.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('recipe scoring wrappers match industry counsel economy', () {
    final lumberRecipe = ProductionRecipesCatalog.byId['lumber_from_timber']!;
    final fabricRecipe = ProductionRecipesCatalog.byId['fabric_from_wool']!;

    test('feasibleRuns matches industryCounselFeasibleRuns', () {
      final stockpile = Stockpile().applyDelta(CommodityCatalog.timber.id, 10);
      for (final labour in [0, 1, 2, 5, 100]) {
        expect(
          feasibleRuns(
            recipe: lumberRecipe,
            stockpile: stockpile,
            remainingLabour: labour,
          ),
          industryCounselFeasibleRuns(
            recipe: lumberRecipe,
            stockpile: stockpile,
            remainingLabour: labour,
          ),
        );
      }
    });

    test('scoreRecipe matches industryCounselScoreRecipe for neutral agenda', () {
      final stockpile = Stockpile()
          .applyDelta(CommodityCatalog.timber.id, 5)
          .applyDelta(CommodityCatalog.lumber.id, 2);
      const workers = WorkerPool(peasants: 3, apprentices: 1);
      for (final recipe in [lumberRecipe, fabricRecipe]) {
        expect(
          scoreRecipe(
            recipe: recipe,
            stockpile: stockpile,
            workers: workers,
            agendaId: kIndustryCounselNeutralAgendaId,
          ),
          industryCounselScoreRecipe(
            recipe: recipe,
            stockpile: stockpile,
            workers: workers,
            agendaId: kIndustryCounselNeutralAgendaId,
          ),
        );
      }
    });

    test('stageScaledRecipeScore matches industryCounselStageScaledRecipeScore', () {
      const aiStage = GrowthStage(
        workerGrowthPriority: 0.7,
        infrastructurePriority: 0.3,
        resourceProductionPriority: 0.5,
        militaryPriority: 0.2,
      );
      const counselStage = IndustryCounselGrowthStage(
        workerGrowthPriority: 0.7,
        infrastructurePriority: 0.3,
        resourceProductionPriority: 0.5,
        militaryPriority: 0.2,
      );
      final stockpile = Stockpile().applyDelta(CommodityCatalog.wool.id, 8);
      const workers = WorkerPool(peasants: 4);

      expect(
        stageScaledRecipeScore(
          recipe: fabricRecipe,
          stockpile: stockpile,
          workers: workers,
          agendaId: kIndustryCounselNeutralAgendaId,
          stage: aiStage,
        ),
        industryCounselStageScaledRecipeScore(
          recipe: fabricRecipe,
          stockpile: stockpile,
          workers: workers,
          agendaId: kIndustryCounselNeutralAgendaId,
          stage: counselStage,
        ),
      );
    });
  });
}
