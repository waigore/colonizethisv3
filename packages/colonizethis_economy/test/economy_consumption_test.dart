import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Tests for economy_consumption.dart. SPEC/game/workers-and-population.md.
void main() {
  group('resolveConsumption', () {
    test('peasants consume 1 food each (grain or meat)', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 5)
          .applyDelta(CommodityCatalog.meat.id, 0);
      const workers = WorkerPool(
        peasants: 5,
        apprentices: 0,
        journeymen: 0,
        masters: 0,
      );

      final result = resolveConsumption(stockpile: stockpile, workers: workers);

      expect(result.workerPool.peasants, 5);
      expect(result.idleLabour.peasants, 5);
      expect(result.stockpile.quantityOf(CommodityCatalog.grain.id), 0);
      expect(result.stockpile.quantityOf(CommodityCatalog.meat.id), 0);
    });

    test('trained tiers consume 2 food each', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 4)
          .applyDelta(CommodityCatalog.meat.id, 4)
          .applyDelta(CommodityCatalog.refinedSugar.id, 2)
          .applyDelta(CommodityCatalog.cigars.id, 1);
      const workers = WorkerPool(
        peasants: 0,
        apprentices: 2,
        journeymen: 1,
        masters: 0,
      );

      final result = resolveConsumption(stockpile: stockpile, workers: workers);

      expect(result.workerPool.apprentices, 2);
      expect(result.workerPool.journeymen, 1);
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
      expect(
        result.stockpile.quantityOf(CommodityCatalog.grain.id) +
            result.stockpile.quantityOf(CommodityCatalog.meat.id),
        14,
      );
    });

    test('food strike: masters fed before peasants when food is tight', () {
      // 1 master (2 food + fur hat) + 5 peasants (5 food); 2 food only → master fed, peasants strike.
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 2)
          .applyDelta(CommodityCatalog.meat.id, 0)
          .applyDelta(CommodityCatalog.furHats.id, 1);
      const workers = WorkerPool(peasants: 5, masters: 1);

      final result = resolveConsumption(stockpile: stockpile, workers: workers);

      expect(result.workerPool.peasants, 5);
      expect(result.workerPool.masters, 1);
      expect(result.idleLabour.masters, 1);
      expect(result.idleLabour.peasants, 0);
      expect(result.stockpile.quantityOf(CommodityCatalog.grain.id), 0);
    });

    test('food strike: journeymen fed before apprentices and peasants', () {
      // Order: masters(0), journeymen(1)=2 food + cigar, apprentices(1)=2+sugar, peasants(1)=1.
      // 3 food: feed journeyman (2), 1 left → 0 apprentices (need 2), 1 peasant fed.
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 3)
          .applyDelta(CommodityCatalog.meat.id, 0)
          .applyDelta(CommodityCatalog.cigars.id, 1);
      const workers = WorkerPool(
        peasants: 1,
        apprentices: 1,
        journeymen: 1,
        masters: 0,
      );

      final result = resolveConsumption(stockpile: stockpile, workers: workers);

      expect(result.workerPool, workers);
      expect(result.idleLabour.journeymen, 1);
      expect(result.idleLabour.apprentices, 0);
      // Remaining food after journeyman is consumed by the apprentice pass (partial, no idle).
      expect(result.idleLabour.peasants, 0);
    });

    test('food strike: pool unchanged when no food', () {
      const stockpile = Stockpile();
      const workers = WorkerPool(
        peasants: 2,
        apprentices: 1,
        journeymen: 0,
        masters: 0,
      );

      final result = resolveConsumption(stockpile: stockpile, workers: workers);

      expect(result.workerPool, workers);
      expect(result.idleLabour, WorkerIdleCounts.zero);
    });

    test('grain used before meat when both available', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 2)
          .applyDelta(CommodityCatalog.meat.id, 10)
          .applyDelta(CommodityCatalog.refinedSugar.id, 2);
      const workers = WorkerPool(
        peasants: 0,
        apprentices: 2,
        journeymen: 0,
        masters: 0,
      );

      final result = resolveConsumption(stockpile: stockpile, workers: workers);

      expect(result.idleLabour.apprentices, 2);
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
      expect(result.totalShips, 0);
      expect(result.fullyFedShips, 0);
    });

    test('unknown ship type id throws ConsumptionUnknownShipTypeException', () {
      const stockpile = Stockpile();
      const workers = WorkerPool(peasants: 0);
      expect(
        () => resolveConsumption(
          stockpile: stockpile,
          workers: workers,
          shipCountsById: const {'not_a_real_ship': 1},
        ),
        throwsA(isA<ConsumptionUnknownShipTypeException>()),
      );
    });

    test('navy consumes food after land military and before workers', () {
      // 1 carrack = 2 food (navy), then 5 peasants need 5 food; 6 food total.
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 6)
          .applyDelta(CommodityCatalog.meat.id, 0);
      const workers = WorkerPool(peasants: 5);
      final result = resolveConsumption(
        stockpile: stockpile,
        workers: workers,
        shipCountsById: const {'carrack': 1},
      );
      expect(result.totalShips, 1);
      expect(result.fullyFedShips, 1);
      // Navy 2 + 4 peasants fed = 6 grain; peasants stay in pool (strike, not removal).
      expect(result.workerPool.peasants, 5);
      expect(result.idleLabour.peasants, 4);
      expect(result.stockpile.quantityOf(CommodityCatalog.grain.id), 0);
    });

    test('ships consume 2 food units each from catalog foodUpkeep', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 4)
          .applyDelta(CommodityCatalog.meat.id, 0);
      const workers = WorkerPool(peasants: 0);
      final result = resolveConsumption(
        stockpile: stockpile,
        workers: workers,
        shipCountsById: const {'carrack': 2},
      );
      expect(result.totalShips, 2);
      expect(result.fullyFedShips, 2);
      expect(result.stockpile.quantityOf(CommodityCatalog.grain.id), 0);
    });

    test(
      'luxury only for food-fed trained; no sugar deducted if apprentice on strike',
      () {
        var stockpile = const Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 1)
            .applyDelta(CommodityCatalog.meat.id, 0)
            .applyDelta(CommodityCatalog.refinedSugar.id, 5);
        const workers = WorkerPool(apprentices: 2, peasants: 0);

        final result = resolveConsumption(
          stockpile: stockpile,
          workers: workers,
        );

        expect(result.idleLabour.apprentices, 0);
        expect(
          result.stockpile.quantityOf(CommodityCatalog.refinedSugar.id),
          5,
        );
      },
    );

    test('trained workers consume tier luxuries when food-fed', () {
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

      expect(result.idleLabour.apprentices, 2);
      expect(result.idleLabour.journeymen, 1);
      expect(result.idleLabour.masters, 1);

      expect(result.stockpile.quantityOf(CommodityCatalog.refinedSugar.id), 0);
      expect(result.stockpile.quantityOf(CommodityCatalog.cigars.id), 0);
      expect(result.stockpile.quantityOf(CommodityCatalog.furHats.id), 0);
    });

    test(
      'luxury strike: food-fed but short luxury → idle capped, partial deduction',
      () {
        var stockpile = const Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 10)
            .applyDelta(CommodityCatalog.meat.id, 10)
            .applyDelta(CommodityCatalog.refinedSugar.id, 1);
        const workers = WorkerPool(apprentices: 3, peasants: 0);

        final result = resolveConsumption(
          stockpile: stockpile,
          workers: workers,
        );

        expect(result.idleLabour.apprentices, 1);
        expect(
          result.stockpile.quantityOf(CommodityCatalog.refinedSugar.id),
          0,
        );
      },
    );
  });
}
