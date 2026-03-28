import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Consumption → Production order and strike interaction.
/// SPEC/game/workers-and-population.md, SPEC/program/turn-resolution-phase-details.md.
void main() {
  group('consumption then production', () {
    test('production uses post-consumption stockpile and idle labour only', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 20)
          .applyDelta(CommodityCatalog.meat.id, 20)
          .applyDelta(CommodityCatalog.timber.id, 10)
          .applyDelta(CommodityCatalog.refinedSugar.id, 1);
      const workers = WorkerPool(peasants: 0, apprentices: 2, journeymen: 0, masters: 0);

      final cons = resolveConsumption(stockpile: stockpile, workers: workers);

      // Both apprentices food-fed; only one gets sugar → one idle for labour.
      expect(cons.idleLabour.apprentices, 1);
      expect(cons.stockpile.quantityOf(CommodityCatalog.refinedSugar.id), 0);

      final prod = resolveProduction(
        stockpile: cons.stockpile,
        workers: cons.workerPool,
        idleLabour: cons.idleLabour,
        assignments: const [
          AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 8),
        ],
      );

      // labourPerOutput 2, effective labour 4 → 2 runs (not 4 runs if both apprentices counted).
      expect(prod.productionByRecipe['lumber_from_timber'], 2);
      expect(prod.stockpile.quantityOf(CommodityCatalog.timber.id), 6);
    });

    test('peasants on food strike contribute no production labour', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 0)
          .applyDelta(CommodityCatalog.meat.id, 0)
          .applyDelta(CommodityCatalog.timber.id, 20);
      const workers = WorkerPool(peasants: 10, apprentices: 0, journeymen: 0, masters: 0);

      final cons = resolveConsumption(stockpile: stockpile, workers: workers);
      expect(cons.idleLabour.peasants, 0);
      expect(cons.workerPool.peasants, 10);

      final prod = resolveProduction(
        stockpile: cons.stockpile,
        workers: cons.workerPool,
        idleLabour: cons.idleLabour,
        assignments: const [
          AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 100),
        ],
      );

      expect(prod.productionByRecipe['lumber_from_timber'] ?? 0, 0);
      expect(prod.stockpile.quantityOf(CommodityCatalog.timber.id), 20);
    });

    test('master idle with food and luxury produces at master labour rate', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 5)
          .applyDelta(CommodityCatalog.meat.id, 5)
          .applyDelta(CommodityCatalog.timber.id, 30)
          .applyDelta(CommodityCatalog.furHats.id, 1);
      const workers = WorkerPool(masters: 1, peasants: 0, apprentices: 0, journeymen: 0);

      final cons = resolveConsumption(stockpile: stockpile, workers: workers);
      expect(cons.idleLabour.masters, 1);
      expect(cons.idleLabour.effectiveLabour, 8);

      final prod = resolveProduction(
        stockpile: cons.stockpile,
        workers: cons.workerPool,
        idleLabour: cons.idleLabour,
        assignments: const [
          AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 8),
        ],
      );

      expect(prod.productionByRecipe['lumber_from_timber'], 4);
    });

    test('journeyman on luxury strike after food: zero journeyman labour', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 10)
          .applyDelta(CommodityCatalog.meat.id, 10)
          .applyDelta(CommodityCatalog.timber.id, 20)
          .applyDelta(CommodityCatalog.cigars.id, 0);
      const workers = WorkerPool(journeymen: 1, peasants: 0, apprentices: 0, masters: 0);

      final cons = resolveConsumption(stockpile: stockpile, workers: workers);
      expect(cons.idleLabour.journeymen, 0);

      final prod = resolveProduction(
        stockpile: cons.stockpile,
        workers: cons.workerPool,
        idleLabour: cons.idleLabour,
        assignments: const [
          AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 6),
        ],
      );

      expect(prod.productionByRecipe['lumber_from_timber'] ?? 0, 0);
    });
  });
}
