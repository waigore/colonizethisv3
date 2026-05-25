import 'package:colonizethis_ai/src/planning/recipe_scoring.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('feasibleRuns', () {
    test('returns 0 when inputs are insufficient', () {
      final recipe = ProductionRecipesCatalog.fabricFromWool;
      const stockpile = Stockpile();
      expect(
        feasibleRuns(
          recipe: recipe,
          stockpile: stockpile,
          remainingLabour: 100,
        ),
        0,
      );
    });

    test('returns 0 when remaining labour cannot fund one run', () {
      final recipe = ProductionRecipesCatalog.fabricFromWool;
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.wool.id,
        100,
      );
      expect(
        feasibleRuns(recipe: recipe, stockpile: stockpile, remainingLabour: 1),
        0,
        reason: 'labourPerOutput is 2',
      );
    });

    test('is capped by labour when inputs are abundant', () {
      final recipe = ProductionRecipesCatalog.fabricFromWool;
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.wool.id,
        100,
      );
      expect(
        feasibleRuns(recipe: recipe, stockpile: stockpile, remainingLabour: 5),
        2,
        reason: '50 input-runs vs 5//2 labour-runs → 2',
      );
    });
  });

  group('scoreRecipe', () {
    test('scores higher when output stockpile is below shortage threshold', () {
      final recipe = ProductionRecipesCatalog.lumberFromTimber;
      const workers = WorkerPool(peasants: 1);
      final wellStocked = const Stockpile().applyDelta(
        CommodityCatalog.lumber.id,
        20,
      );
      const scarceOutput = Stockpile();
      final highHave = scoreRecipe(
        recipe: recipe,
        stockpile: wellStocked,
        workers: workers,
        agendaId: 'peacemaker',
      );
      final lowHave = scoreRecipe(
        recipe: recipe,
        stockpile: scarceOutput,
        workers: workers,
        agendaId: 'peacemaker',
      );
      expect(lowHave, greaterThan(highHave));
    });

    test('merchant agenda boosts fabric relative to peacemaker', () {
      final recipe = ProductionRecipesCatalog.fabricFromWool;
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.fabric.id,
        20,
      );
      const workers = WorkerPool(peasants: 1);
      final merchant = scoreRecipe(
        recipe: recipe,
        stockpile: stockpile,
        workers: workers,
        agendaId: 'merchant',
      );
      final peace = scoreRecipe(
        recipe: recipe,
        stockpile: stockpile,
        workers: workers,
        agendaId: 'peacemaker',
      );
      expect(merchant, greaterThan(peace));
    });
  });
}
