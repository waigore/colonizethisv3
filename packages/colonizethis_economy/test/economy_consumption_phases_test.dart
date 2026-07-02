import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// Dedicated unit tests for the per-phase consumption helpers extracted from
/// `economy_consumption.dart`. SPEC/game/workers-and-population.md.
void main() {
  final grainId = CommodityCatalog.grain.id;
  final meatId = CommodityCatalog.meat.id;
  final sugarId = CommodityCatalog.refinedSugar.id;

  group('consumeMilitaryFood', () {
    test('per-type foodUpkeep fully feeds regiments from catalog', () {
      // pikemen foodUpkeep = 2; 2 regiments => 4 food demand.
      final stockpile = const Stockpile().applyDelta(grainId, 10);

      final (next, total, fullyFed) = consumeMilitaryFood(
        stockpile: stockpile,
        regimentCountsById: const {'pikemen': 2},
      );

      expect(total, 2);
      expect(fullyFed, 2);
      expect(next.quantityOf(grainId), 6);
    });

    test('militaryUnits fallback consumes 2 food per regiment', () {
      final stockpile = const Stockpile().applyDelta(grainId, 10);

      final (next, total, fullyFed) = consumeMilitaryFood(
        stockpile: stockpile,
        militaryUnits: 3,
      );

      expect(total, 3);
      expect(fullyFed, 3);
      expect(next.quantityOf(grainId), 4);
    });

    test('insufficient food partially feeds regiments', () {
      // 3 pikemen => 6 food demand, only 2 available.
      final stockpile = const Stockpile().applyDelta(grainId, 2);

      final (next, total, fullyFed) = consumeMilitaryFood(
        stockpile: stockpile,
        regimentCountsById: const {'pikemen': 3},
      );

      expect(total, 3);
      expect(fullyFed, 1);
      expect(next.quantityOf(grainId), 0);
    });

    test('no regiments and no military leaves stockpile unchanged', () {
      final stockpile = const Stockpile().applyDelta(grainId, 5);

      final (next, total, fullyFed) = consumeMilitaryFood(stockpile: stockpile);

      expect(total, 0);
      expect(fullyFed, 0);
      expect(next.quantityOf(grainId), 5);
    });

    test('unknown regiment id contributes count but no food demand', () {
      final stockpile = const Stockpile().applyDelta(grainId, 5);

      final (next, total, fullyFed) = consumeMilitaryFood(
        stockpile: stockpile,
        regimentCountsById: const {'not_a_real_regiment': 2},
      );

      expect(total, 2);
      expect(fullyFed, 0);
      expect(next.quantityOf(grainId), 5);
    });
  });

  group('consumeNavyFood', () {
    test('feeds ships from catalog foodUpkeep', () {
      // carrack foodUpkeep = 2; 2 ships => 4 food demand.
      final stockpile = const Stockpile().applyDelta(grainId, 10);

      final (next, total, fullyFed) = consumeNavyFood(
        stockpile: stockpile,
        shipCountsById: const {'carrack': 2},
      );

      expect(total, 2);
      expect(fullyFed, 2);
      expect(next.quantityOf(grainId), 6);
    });

    test('insufficient food partially feeds ships', () {
      // 2 carracks => 4 food demand, only 2 available.
      final stockpile = const Stockpile().applyDelta(grainId, 2);

      final (next, total, fullyFed) = consumeNavyFood(
        stockpile: stockpile,
        shipCountsById: const {'carrack': 2},
      );

      expect(total, 2);
      expect(fullyFed, 1);
      expect(next.quantityOf(grainId), 0);
    });

    test('unknown ship id throws before any food is deducted', () {
      final stockpile = const Stockpile().applyDelta(grainId, 5);

      expect(
        () => consumeNavyFood(
          stockpile: stockpile,
          shipCountsById: const {'not_a_real_ship': 1},
        ),
        throwsA(isA<ConsumptionUnknownShipTypeException>()),
      );
    });

    test('empty fleet leaves stockpile unchanged', () {
      final stockpile = const Stockpile().applyDelta(grainId, 5);

      final (next, total, fullyFed) = consumeNavyFood(stockpile: stockpile);

      expect(total, 0);
      expect(fullyFed, 0);
      expect(next.quantityOf(grainId), 5);
    });
  });

  group('consumeWorkerFood', () {
    test('feeds trained tiers (2 food) and peasants (1 food)', () {
      final stockpile = const Stockpile().applyDelta(grainId, 100);
      const workers = WorkerPool(
        masters: 1,
        journeymen: 1,
        apprentices: 1,
        peasants: 2,
      );

      final fed = consumeWorkerFood(stockpile: stockpile, workers: workers);

      expect(fed.fedMasters, 1);
      expect(fed.fedJourneymen, 1);
      expect(fed.fedApprentices, 1);
      expect(fed.fedPeasants, 2);
      // 2 + 2 + 2 + 2 = 8 food consumed.
      expect(fed.stockpile.quantityOf(grainId), 92);
    });

    test('priority Masters→...→Peasants: masters fed before peasants', () {
      // 2 food only: master needs 2; peasants get nothing (strike).
      final stockpile = const Stockpile().applyDelta(grainId, 2);
      const workers = WorkerPool(masters: 1, peasants: 5);

      final fed = consumeWorkerFood(stockpile: stockpile, workers: workers);

      expect(fed.fedMasters, 1);
      expect(fed.fedPeasants, 0);
      expect(fed.stockpile.quantityOf(grainId), 0);
    });

    test('grain consumed before meat', () {
      final stockpile = const Stockpile()
          .applyDelta(grainId, 2)
          .applyDelta(meatId, 10);
      const workers = WorkerPool(apprentices: 2);

      final fed = consumeWorkerFood(stockpile: stockpile, workers: workers);

      expect(fed.fedApprentices, 2);
      expect(fed.stockpile.quantityOf(grainId), 0);
      expect(fed.stockpile.quantityOf(meatId), 8);
    });

    test('no food leaves all tiers on strike', () {
      const stockpile = Stockpile();
      const workers = WorkerPool(masters: 1, peasants: 2);

      final fed = consumeWorkerFood(stockpile: stockpile, workers: workers);

      expect(fed.fedMasters, 0);
      expect(fed.fedPeasants, 0);
    });
  });

  group('assignWorkerLuxury', () {
    test('assigns one luxury per food-fed worker when supply suffices', () {
      final stockpile = const Stockpile().applyDelta(sugarId, 5);

      final (next, withLuxury) = assignWorkerLuxury(
        stockpile: stockpile,
        foodFedCount: 3,
        luxuryId: sugarId,
      );

      expect(withLuxury, 3);
      expect(next.quantityOf(sugarId), 2);
    });

    test('luxury strike: short supply caps count and deducts what exists', () {
      final stockpile = const Stockpile().applyDelta(sugarId, 1);

      final (next, withLuxury) = assignWorkerLuxury(
        stockpile: stockpile,
        foodFedCount: 3,
        luxuryId: sugarId,
      );

      expect(withLuxury, 1);
      expect(next.quantityOf(sugarId), 0);
    });

    test('no food-fed workers deducts nothing', () {
      final stockpile = const Stockpile().applyDelta(sugarId, 5);

      final (next, withLuxury) = assignWorkerLuxury(
        stockpile: stockpile,
        foodFedCount: 0,
        luxuryId: sugarId,
      );

      expect(withLuxury, 0);
      expect(next.quantityOf(sugarId), 5);
    });

    test('no luxury available deducts nothing', () {
      const stockpile = Stockpile();

      final (next, withLuxury) = assignWorkerLuxury(
        stockpile: stockpile,
        foodFedCount: 3,
        luxuryId: sugarId,
      );

      expect(withLuxury, 0);
      expect(next.quantityOf(sugarId), 0);
    });
  });

  group('consumeFoodUnits', () {
    test('grain then meat, returns consumed amount', () {
      final stockpile = const Stockpile()
          .applyDelta(grainId, 3)
          .applyDelta(meatId, 5);

      final (next, consumed) = consumeFoodUnits(stockpile: stockpile, required: 6);

      expect(consumed, 6);
      expect(next.quantityOf(grainId), 0);
      expect(next.quantityOf(meatId), 2);
    });

    test('caps consumed at available when demand exceeds supply', () {
      final stockpile = const Stockpile().applyDelta(grainId, 2);

      final (next, consumed) = consumeFoodUnits(stockpile: stockpile, required: 9);

      expect(consumed, 2);
      expect(next.quantityOf(grainId), 0);
    });
  });
}
