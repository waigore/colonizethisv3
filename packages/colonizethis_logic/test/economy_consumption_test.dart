import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Tests for economy_consumption.dart. SPEC/game/workers-and-population.md.
void main() {
  group('resolveConsumption', () {
    test('peasants consume 1 food each (grain or meat)', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 5)
          .applyDelta(CommodityCatalog.meat.id, 0);
      const workers = WorkerPool(peasants: 5, apprentices: 0, journeymen: 0, masters: 0);

      final result = resolveConsumption(stockpile: stockpile, workers: workers);

      expect(result.workerPool.peasants, 5);
      expect(result.stockpile.quantityOf(CommodityCatalog.grain.id), 0);
      expect(result.stockpile.quantityOf(CommodityCatalog.meat.id), 0);
    });

    test('trained tiers consume 2 food each (1 grain + 1 meat)', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 4)
          .applyDelta(CommodityCatalog.meat.id, 4);
      const workers = WorkerPool(
        peasants: 0,
        apprentices: 2,
        journeymen: 1,
        masters: 0,
      );

      final result = resolveConsumption(stockpile: stockpile, workers: workers);

      expect(result.workerPool.apprentices, 2);
      expect(result.workerPool.journeymen, 1);
      // 2*2 + 1*2 = 6 food consumed
      expect(
        result.stockpile.quantityOf(CommodityCatalog.grain.id) +
            result.stockpile.quantityOf(CommodityCatalog.meat.id),
        2,
      );
    });

    test('military consumes 2 food per regiment when militaryUnits set', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 10)
          .applyDelta(CommodityCatalog.meat.id, 10);
      const workers = WorkerPool(peasants: 0);

      final result = resolveConsumption(
        stockpile: stockpile,
        workers: workers,
        militaryUnits: 3,
      );

      expect(result.totalRegiments, 3);
      expect(result.fullyFedRegiments, 3);
      // 6 food for military; 14 left
      expect(
        result.stockpile.quantityOf(CommodityCatalog.grain.id) +
            result.stockpile.quantityOf(CommodityCatalog.meat.id),
        14,
      );
    });

    test('starvation removes peasants first', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 1)
          .applyDelta(CommodityCatalog.meat.id, 0);
      const workers = WorkerPool(peasants: 5, apprentices: 0, journeymen: 0, masters: 0);

      final result = resolveConsumption(stockpile: stockpile, workers: workers);

      expect(result.workerPool.peasants, 1);
      expect(result.workerPool.apprentices, 0);
      expect(result.stockpile.quantityOf(CommodityCatalog.grain.id), 0);
    });

    test('starvation removes apprentices then journeymen then masters when food insufficient', () {
      // 2 peasants (2 food) + 2 apprentices (4) + 1 journeyman (2) + 1 master (2) = 10 food needed.
      // Provide 5: feed 2 peasants (2), 1.5 apprentice rounds -> 1 apprentice fed (2), 1 food left -> 0 more.
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 3)
          .applyDelta(CommodityCatalog.meat.id, 2);
      const workers = WorkerPool(
        peasants: 2,
        apprentices: 2,
        journeymen: 1,
        masters: 1,
      );

      final result = resolveConsumption(stockpile: stockpile, workers: workers);

      expect(result.workerPool.peasants, 2);
      expect(result.workerPool.apprentices, 1);
      expect(result.workerPool.journeymen, 0);
      expect(result.workerPool.masters, 0);
    });

    test('all workers starve when no food', () {
      const stockpile = Stockpile();
      const workers = WorkerPool(peasants: 2, apprentices: 1, journeymen: 0, masters: 0);

      final result = resolveConsumption(stockpile: stockpile, workers: workers);

      expect(result.workerPool.peasants, 0);
      expect(result.workerPool.apprentices, 0);
      expect(result.workerPool.journeymen, 0);
      expect(result.workerPool.masters, 0);
    });

    test('grain used before meat when both available', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 2)
          .applyDelta(CommodityCatalog.meat.id, 10);
      const workers = WorkerPool(peasants: 0, apprentices: 2, journeymen: 0, masters: 0);

      final result = resolveConsumption(stockpile: stockpile, workers: workers);

      expect(result.workerPool.apprentices, 2);
      expect(result.stockpile.quantityOf(CommodityCatalog.grain.id), 0);
      expect(result.stockpile.quantityOf(CommodityCatalog.meat.id), 8);
    });

    test('zero workers and zero military leaves stockpile unchanged', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 5)
          .applyDelta(CommodityCatalog.meat.id, 5);
      const workers = WorkerPool(peasants: 0);

      final result = resolveConsumption(stockpile: stockpile, workers: workers);

      expect(result.stockpile.quantityOf(CommodityCatalog.grain.id), 5);
      expect(result.stockpile.quantityOf(CommodityCatalog.meat.id), 5);
      expect(result.totalRegiments, 0);
      expect(result.fullyFedRegiments, 0);
    });

    test('trained workers consume tier luxuries when available', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 10)
          .applyDelta(CommodityCatalog.meat.id, 10)
          .applyDelta(CommodityCatalog.refinedSugar.id, 2)
          .applyDelta(CommodityCatalog.cigars.id, 1)
          .applyDelta(CommodityCatalog.furHats.id, 1);
      const workers = WorkerPool(
        peasants: 0,
        apprentices: 2,
        journeymen: 1,
        masters: 1,
      );

      final result = resolveConsumption(stockpile: stockpile, workers: workers);

      // Food sufficient: no starvation.
      expect(result.workerPool.apprentices, 2);
      expect(result.workerPool.journeymen, 1);
      expect(result.workerPool.masters, 1);

      // Luxury consumption capped by worker count and stockpile.
      expect(result.stockpile.quantityOf(CommodityCatalog.refinedSugar.id), 0); // 2 apprentices → 2 refinedSugar used.
      expect(result.stockpile.quantityOf(CommodityCatalog.cigars.id), 0); // 1 journeyman → 1 cigars used.
      expect(result.stockpile.quantityOf(CommodityCatalog.furHats.id), 0); // 1 master → 1 furHats used.
    });
  });
}
