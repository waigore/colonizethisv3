import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Tests for economy_production.dart. SPEC/game/stockpiles-and-production.md.
void main() {
  group('resolveProduction', () {
    test('consumes inputs and produces output per recipe', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.timber.id, 10)
          .applyDelta(CommodityCatalog.iron.id, 10)
          .applyDelta(CommodityCatalog.coal.id, 5);
      // 20 peasants → 20 labour (idle counts from post-consumption).
      const workers = WorkerPool(peasants: 20);

      final result = resolveProduction(
        stockpile: stockpile,
        workers: workers,
        idleLabour: WorkerIdleCounts(peasants: 20),
        assignments: const [
          AssignedRecipe(
            recipeId: 'castIron_from_timber_iron_coal',
            assignedLabour: 20,
          ),
        ],
      );

      expect(result.stockpile.quantityOf(CommodityCatalog.castIron.id), 4);
      expect(result.stockpile.quantityOf(CommodityCatalog.timber.id), 2);
      expect(result.stockpile.quantityOf(CommodityCatalog.iron.id), 2);
      // Cast iron no longer consumes coal; coal remains unchanged.
      expect(result.stockpile.quantityOf(CommodityCatalog.coal.id), 5);
    });

    test('limits runs by available inputs', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.timber.id, 4)
          .applyDelta(CommodityCatalog.iron.id, 20)
          .applyDelta(CommodityCatalog.coal.id, 20);
      // 20 peasants → 20 labour; inputs (timber) are the limiting factor.
      const workers = WorkerPool(peasants: 20);

      final result = resolveProduction(
        stockpile: stockpile,
        workers: workers,
        idleLabour: WorkerIdleCounts(peasants: 20),
        assignments: const [
          AssignedRecipe(
            recipeId: 'castIron_from_timber_iron_coal',
            assignedLabour: 100,
          ),
        ],
      );

      // 2 timber per run => max 2 runs by timber
      expect(result.stockpile.quantityOf(CommodityCatalog.castIron.id), 2);
      expect(result.stockpile.quantityOf(CommodityCatalog.timber.id), 0);
    });

    test('limits runs by assigned labour (labourPerOutput)', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.timber.id, 100)
          .applyDelta(CommodityCatalog.iron.id, 100)
          .applyDelta(CommodityCatalog.coal.id, 50);
      const workers = WorkerPool(peasants: 10);

      final result = resolveProduction(
        stockpile: stockpile,
        workers: workers,
        idleLabour: WorkerIdleCounts(peasants: 10),
        assignments: const [
          AssignedRecipe(
            recipeId: 'castIron_from_timber_iron_coal',
            assignedLabour: 7,
          ),
        ],
      );

      // labourPerOutput = 5; 7 ~/ 5 = 1 run
      expect(result.stockpile.quantityOf(CommodityCatalog.castIron.id), 1);
    });

    test('worker pool is unchanged', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.timber.id, 10)
          .applyDelta(CommodityCatalog.iron.id, 10)
          .applyDelta(CommodityCatalog.coal.id, 5);
      const workers = WorkerPool(peasants: 3, apprentices: 2);

      final result = resolveProduction(
        stockpile: stockpile,
        workers: workers,
        idleLabour: WorkerIdleCounts(peasants: 3, apprentices: 2),
        assignments: const [
          AssignedRecipe(
            recipeId: 'castIron_from_timber_iron_coal',
            assignedLabour: 20,
          ),
        ],
      );

      expect(result.workerPool.peasants, 3);
      expect(result.workerPool.apprentices, 2);
    });

    test('unknown recipe id is ignored', () {
      var stockpile = const Stockpile().applyDelta(
        CommodityCatalog.grain.id,
        10,
      );

      final result = resolveProduction(
        stockpile: stockpile,
        workers: const WorkerPool(peasants: 5),
        idleLabour: WorkerIdleCounts(peasants: 5),
        assignments: const [
          AssignedRecipe(recipeId: 'unknown_recipe', assignedLabour: 100),
        ],
      );

      expect(result.stockpile.quantityOf(CommodityCatalog.grain.id), 10);
    });

    test('zero assigned labour skips recipe', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.timber.id, 10)
          .applyDelta(CommodityCatalog.iron.id, 10)
          .applyDelta(CommodityCatalog.coal.id, 5);

      final result = resolveProduction(
        stockpile: stockpile,
        workers: const WorkerPool(peasants: 5),
        idleLabour: WorkerIdleCounts(peasants: 5),
        assignments: const [
          AssignedRecipe(
            recipeId: 'castIron_from_timber_iron_coal',
            assignedLabour: 0,
          ),
        ],
      );

      expect(result.stockpile.quantityOf(CommodityCatalog.castIron.id), 0);
      expect(result.stockpile.quantityOf(CommodityCatalog.timber.id), 10);
    });

    test('multiple assignments apply in order', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.timber.id, 20)
          .applyDelta(CommodityCatalog.iron.id, 20)
          .applyDelta(CommodityCatalog.coal.id, 10);
      // 25 peasants → 25 labour; first assignment uses 15, second can use remaining 10.
      const workers = WorkerPool(peasants: 25);

      final result = resolveProduction(
        stockpile: stockpile,
        workers: workers,
        idleLabour: WorkerIdleCounts(peasants: 25),
        assignments: const [
          AssignedRecipe(
            recipeId: 'castIron_from_timber_iron_coal',
            assignedLabour: 15,
          ),
          AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 10),
        ],
      );

      expect(result.stockpile.quantityOf(CommodityCatalog.castIron.id), 3);
      expect(result.stockpile.quantityOf(CommodityCatalog.lumber.id), 5);
    });

    test('empty assignments leave stockpile unchanged', () {
      var stockpile = const Stockpile().applyDelta(
        CommodityCatalog.grain.id,
        5,
      );

      final result = resolveProduction(
        stockpile: stockpile,
        workers: const WorkerPool(peasants: 5),
        idleLabour: WorkerIdleCounts(peasants: 5),
        assignments: const [],
      );

      expect(result.stockpile.quantityOf(CommodityCatalog.grain.id), 5);
    });
  });

  group('effectiveLabourForWorkers', () {
    test('peasants contribute 1 labour each when fed', () {
      const workers = WorkerPool(peasants: 10);
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.grain.id,
        10,
      );
      expect(
        effectiveLabourForWorkers(workers: workers, stockpile: stockpile),
        10,
      );
    });

    test('trained workers capped by luxury after food', () {
      const workers = WorkerPool(
        peasants: 2,
        apprentices: 3,
        journeymen: 0,
        masters: 0,
      );
      // Food: peasants first in consumption is last — masters→apprentices→peasants,
      // so apprentices fed before peasants. 3*2 + 2*1 = 8 food to feed all trained + peasants.
      final stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 8)
          .applyDelta(CommodityCatalog.refinedSugar.id, 1);
      expect(
        effectiveLabourForWorkers(workers: workers, stockpile: stockpile),
        2 + 4, // 2 peasants fed + 1 apprentice with luxury
      );
    });

    test('full luxury gives full trained labour when food sufficient', () {
      const workers = WorkerPool(
        peasants: 1,
        apprentices: 2,
        journeymen: 1,
        masters: 0,
      );
      // Food: journeyman 2, apprentices 4, peasant 1 = 7.
      final stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 7)
          .applyDelta(CommodityCatalog.refinedSugar.id, 5)
          .applyDelta(CommodityCatalog.cigars.id, 5);
      expect(
        effectiveLabourForWorkers(workers: workers, stockpile: stockpile),
        1 + 2 * 4 + 1 * 6, // 1 + 8 + 6 = 15
      );
    });
  });
}
