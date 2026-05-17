import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'test_fixtures.dart';

void main() {
  group('effectiveLabourForWorkers', () {
    test('masters with luxury capped by furHats after food', () {
      const workers = WorkerPool(peasants: 2, masters: 3);
      final stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 8)
          .applyDelta(CommodityCatalog.furHats.id, 1);
      final labour = effectiveLabourForWorkers(workers: workers, stockpile: stockpile);
      expect(labour, 2 * 1 + 1 * 8);
    });
  });

  group('applyExtractionToStockpile', () {
    test('adds extracted quantities', () {
      const stockpile = Stockpile();
      final extracted = {
        CommodityCatalog.grain.id: 5,
        CommodityCatalog.iron.id: 2,
      };
      final updated = applyExtractionToStockpile(stockpile, extracted);
      expect(updated.quantityOf(CommodityCatalog.grain.id), 5);
      expect(updated.quantityOf(CommodityCatalog.iron.id), 2);
    });
  });

  group('applyExtractionForPlayers', () {
    test('applies per-player extraction to stockpiles', () {
      final game = TestFixtures.minimalGame(
        id: 'g1',
        turnNumber: 0,
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
          Player(id: 'p2', displayName: 'B', isHuman: false),
        ],
      );

      final extracted = {
        'p1': {
          CommodityCatalog.grain.id: 3,
        },
        'p2': {
          CommodityCatalog.iron.id: 2,
        },
      };

      final updated = applyExtractionForPlayers(game, extracted);
      expect(
        updated.players[0].stockpile.quantityOf(CommodityCatalog.grain.id),
        3,
      );
      expect(
        updated.players[1].stockpile.quantityOf(CommodityCatalog.iron.id),
        2,
      );
    });
  });

  group('resolveProduction', () {
    test('consumes inputs and produces outputs', () {
      // Start with enough timber and iron; coal is present but not consumed.
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.timber.id, 10)
          .applyDelta(CommodityCatalog.iron.id, 10)
          .applyDelta(CommodityCatalog.coal.id, 5);
      const workers = WorkerPool(peasants: 10);

      final result = resolveProduction(
        stockpile: stockpile,
        workers: workers,
        idleLabour: WorkerIdleCounts(peasants: 10),
        assignments: const [
          AssignedRecipe(
            recipeId: 'castIron_from_timber_iron_coal',
            assignedLabour: 20,
          ),
        ],
      );

      // labourPerOutput = 5, assigned 20, but effective labour from 10 peasants
      // is 10 → max 2 runs.
      // Inputs per run: 2 timber, 2 iron (no coal).
      expect(result.stockpile.quantityOf(CommodityCatalog.castIron.id), 2);
      expect(result.stockpile.quantityOf(CommodityCatalog.timber.id), 10 - 2 * 2);
      expect(result.stockpile.quantityOf(CommodityCatalog.iron.id), 10 - 2 * 2);
      // Cast iron recipe no longer consumes coal; coal remains unchanged.
      expect(result.stockpile.quantityOf(CommodityCatalog.coal.id), 5);
    });

    test('effective labour counts only trained workers with luxury', () {
      // 1 apprentice, 0 peasants, 1 refinedSugar → effective labour = 4.
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.timber.id, 10)
          .applyDelta(CommodityCatalog.refinedSugar.id, 1);
      const workers = WorkerPool(
        peasants: 0,
        apprentices: 1,
        journeymen: 0,
        masters: 0,
      );

      final result = resolveProduction(
        stockpile: stockpile,
        workers: workers,
        idleLabour: const WorkerIdleCounts(apprentices: 1),
        assignments: const [
          AssignedRecipe(
            recipeId: 'lumber_from_timber',
            assignedLabour: 4,
          ),
        ],
      );

      // labourPerOutput = 2, effective labour 4 ⇒ 2 runs.
      expect(result.stockpile.quantityOf(CommodityCatalog.lumber.id), 2);
      expect(result.stockpile.quantityOf(CommodityCatalog.timber.id), 10 - 2 * 2);
    });

    test('trained workers without luxury contribute zero effective labour', () {
      // 1 apprentice, 0 peasants, 0 refinedSugar → effective labour = 0.
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.timber.id, 10);
      const workers = WorkerPool(
        peasants: 0,
        apprentices: 1,
        journeymen: 0,
        masters: 0,
      );

      final result = resolveProduction(
        stockpile: stockpile,
        workers: workers,
        idleLabour: WorkerIdleCounts.zero,
        assignments: const [
          AssignedRecipe(
            recipeId: 'lumber_from_timber',
            assignedLabour: 4,
          ),
        ],
      );

      // No idle trained labour → no runs, inputs unchanged.
      expect(result.stockpile.quantityOf(CommodityCatalog.lumber.id), 0);
      expect(result.stockpile.quantityOf(CommodityCatalog.timber.id), 10);
    });
  });

  group('resolveConsumption', () {
    test('workers consume food from stockpile without starving (no military)', () {
      // 3 peasants + 2 trained tiers => 3 * 1 + 2 * 2 = 7 food required + luxuries.
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 5)
          .applyDelta(CommodityCatalog.meat.id, 5)
          .applyDelta(CommodityCatalog.refinedSugar.id, 1)
          .applyDelta(CommodityCatalog.cigars.id, 1);
      const workers = WorkerPool(
        peasants: 3,
        apprentices: 1,
        journeymen: 1,
        masters: 0,
      );

      final result = resolveConsumption(
        stockpile: stockpile,
        workers: workers,
      );

      final totalFood =
          result.stockpile.quantityOf(CommodityCatalog.grain.id) +
              result.stockpile.quantityOf(CommodityCatalog.meat.id);

      // Started with 10 food, required 7, all workers should be fed.
      expect(totalFood, 3);
      expect(result.workerPool.peasants, 3);
      expect(result.workerPool.apprentices, 1);
      expect(result.workerPool.journeymen, 1);
      expect(result.workerPool.masters, 0);
      expect(result.idleLabour.peasants, 3);
      expect(result.idleLabour.apprentices, 1);
      expect(result.idleLabour.journeymen, 1);
    });

    test('food strike: journeyman before apprentice; peasants last', () {
      // 3 food: journeyman (2) fed first; remainder cannot complete apprentice (2); peasants may get none after grain/meat mix.
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 1)
          .applyDelta(CommodityCatalog.meat.id, 2)
          .applyDelta(CommodityCatalog.cigars.id, 1);
      const workers = WorkerPool(
        peasants: 3,
        apprentices: 1,
        journeymen: 1,
        masters: 0,
      );

      final result = resolveConsumption(
        stockpile: stockpile,
        workers: workers,
      );

      expect(result.workerPool, workers);
      expect(result.idleLabour.journeymen, 1);
      expect(result.idleLabour.apprentices, 0);
      expect(result.idleLabour.peasants, 0);
    });

    test('military consumes food from stockpile before workers when present', () {
      // 2 military units at 2 food each = 4 food (fallback path).
      // Workers then consume from remaining food.
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 5)
          .applyDelta(CommodityCatalog.meat.id, 5);
      const workers = WorkerPool(
        peasants: 3,
        apprentices: 0,
        journeymen: 0,
        masters: 0,
      );

      final result = resolveConsumption(
        stockpile: stockpile,
        workers: workers,
        militaryUnits: 2,
      );

      final totalFood =
          result.stockpile.quantityOf(CommodityCatalog.grain.id) +
              result.stockpile.quantityOf(CommodityCatalog.meat.id);

      // Started with 10 food, military should consume 4 first, then peasants
      // (up to 3 food). Some food may remain if not all required can be met.
      expect(totalFood, lessThanOrEqualTo(3));

      // Peasants may starve if insufficient food remains, but never increase.
      expect(result.workerPool.peasants, workers.peasants);
    });

    test('food strike priority: apprentices fed before peasants', () {
      // 3 food: apprentices (2 each) before peasants → one full apprentice (2 food); 1 food
      // goes to the apprentice pass as partial (no idle apprentice); peasants get nothing.
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 2)
          .applyDelta(CommodityCatalog.meat.id, 1)
          .applyDelta(CommodityCatalog.refinedSugar.id, 2);
      const workers = WorkerPool(
        peasants: 2,
        apprentices: 2,
        journeymen: 0,
        masters: 0,
      );
      final result = resolveConsumption(stockpile: stockpile, workers: workers);
      expect(result.workerPool, workers);
      expect(result.idleLabour.apprentices, 1);
      expect(result.idleLabour.peasants, 0);
    });
  });

  group('resolveRichesToTreasury', () {
    test('converts riches to treasury and removes them from stockpile', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.spices.id, 2)
          .applyDelta(CommodityCatalog.gold.id, 1);
      const treasuryStart = 100;

      final result = resolveRichesToTreasury(stockpile: stockpile);

      expect(result.stockpile.quantityOf(CommodityCatalog.spices.id), 0);
      expect(result.stockpile.quantityOf(CommodityCatalog.gold.id), 0);
      expect(result.treasuryDelta, 2 * 50 + 1 * richesBasePrice('gold'));
      expect(treasuryStart + result.treasuryDelta, 100 + 100 + 166); // 366
    });

    test('leaves non-riches commodities unchanged', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 10)
          .applyDelta(CommodityCatalog.spices.id, 1);

      final result = resolveRichesToTreasury(stockpile: stockpile);

      expect(result.stockpile.quantityOf(CommodityCatalog.grain.id), 10);
      expect(result.stockpile.quantityOf(CommodityCatalog.spices.id), 0);
      expect(result.treasuryDelta, 50);
    });
  });
}

