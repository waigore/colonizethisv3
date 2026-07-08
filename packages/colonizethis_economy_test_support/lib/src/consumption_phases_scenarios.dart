// Table-driven per-phase consumption helper scenarios (Refs #3856, #3939 slice 7).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'consumption_scenarios.dart';

/// Back-compat alias — phase tables share [ConsumptionScenario].
typedef ConsumptionPhaseScenario = ConsumptionScenario;

/// Back-compat runner for per-phase consumption scenario tables.
void runConsumptionPhaseScenario(ConsumptionPhaseScenario scenario) =>
    runConsumptionScenario(scenario);

final _grainId = CommodityCatalog.grain.id;
final _meatId = CommodityCatalog.meat.id;
final _sugarId = CommodityCatalog.refinedSugar.id;

/// Canonical scenarios for [consumeMilitaryFood].
List<ConsumptionPhaseScenario> consumeMilitaryFoodScenarios() => [
  ConsumptionScenario(
    label: 'per-type foodUpkeep fully feeds regiments from catalog',
    run: () {
      final stockpile = const Stockpile().applyDelta(_grainId, 10);

      final (next, total, fullyFed) = consumeMilitaryFood(
        stockpile: stockpile,
        regimentCountsById: const {'pikemen': 2},
      );

      expect(total, 2);
      expect(fullyFed, 2);
      expect(next.quantityOf(_grainId), 6);
    },
  ),
  ConsumptionScenario(
    label: 'militaryUnits fallback consumes 2 food per regiment',
    run: () {
      final stockpile = const Stockpile().applyDelta(_grainId, 10);

      final (next, total, fullyFed) = consumeMilitaryFood(
        stockpile: stockpile,
        militaryUnits: 3,
      );

      expect(total, 3);
      expect(fullyFed, 3);
      expect(next.quantityOf(_grainId), 4);
    },
  ),
  ConsumptionScenario(
    label: 'insufficient food partially feeds regiments',
    run: () {
      final stockpile = const Stockpile().applyDelta(_grainId, 2);

      final (next, total, fullyFed) = consumeMilitaryFood(
        stockpile: stockpile,
        regimentCountsById: const {'pikemen': 3},
      );

      expect(total, 3);
      expect(fullyFed, 1);
      expect(next.quantityOf(_grainId), 0);
    },
  ),
  ConsumptionScenario(
    label: 'no regiments and no military leaves stockpile unchanged',
    run: () {
      final stockpile = const Stockpile().applyDelta(_grainId, 5);

      final (next, total, fullyFed) = consumeMilitaryFood(stockpile: stockpile);

      expect(total, 0);
      expect(fullyFed, 0);
      expect(next.quantityOf(_grainId), 5);
    },
  ),
  ConsumptionScenario(
    label: 'unknown regiment id contributes count but no food demand',
    run: () {
      final stockpile = const Stockpile().applyDelta(_grainId, 5);

      final (next, total, fullyFed) = consumeMilitaryFood(
        stockpile: stockpile,
        regimentCountsById: const {'not_a_real_regiment': 2},
      );

      expect(total, 2);
      expect(fullyFed, 0);
      expect(next.quantityOf(_grainId), 5);
    },
  ),
];

/// Canonical scenarios for [consumeNavyFood].
List<ConsumptionPhaseScenario> consumeNavyFoodScenarios() => [
  ConsumptionScenario(
    label: 'feeds ships from catalog foodUpkeep',
    run: () {
      final stockpile = const Stockpile().applyDelta(_grainId, 10);

      final (next, total, fullyFed) = consumeNavyFood(
        stockpile: stockpile,
        shipCountsById: const {'carrack': 2},
      );

      expect(total, 2);
      expect(fullyFed, 2);
      expect(next.quantityOf(_grainId), 6);
    },
  ),
  ConsumptionScenario(
    label: 'insufficient food partially feeds ships',
    run: () {
      final stockpile = const Stockpile().applyDelta(_grainId, 2);

      final (next, total, fullyFed) = consumeNavyFood(
        stockpile: stockpile,
        shipCountsById: const {'carrack': 2},
      );

      expect(total, 2);
      expect(fullyFed, 1);
      expect(next.quantityOf(_grainId), 0);
    },
  ),
  ConsumptionScenario(
    label: 'unknown ship id throws before any food is deducted',
    run: () {
      final stockpile = const Stockpile().applyDelta(_grainId, 5);

      expect(
        () => consumeNavyFood(
          stockpile: stockpile,
          shipCountsById: const {'not_a_real_ship': 1},
        ),
        throwsA(isA<ConsumptionUnknownShipTypeException>()),
      );
    },
  ),
  ConsumptionScenario(
    label: 'empty fleet leaves stockpile unchanged',
    run: () {
      final stockpile = const Stockpile().applyDelta(_grainId, 5);

      final (next, total, fullyFed) = consumeNavyFood(stockpile: stockpile);

      expect(total, 0);
      expect(fullyFed, 0);
      expect(next.quantityOf(_grainId), 5);
    },
  ),
];

/// Canonical scenarios for [consumeWorkerFood].
List<ConsumptionPhaseScenario> consumeWorkerFoodScenarios() => [
  ConsumptionScenario(
    label: 'feeds trained tiers (2 food) and peasants (1 food)',
    run: () {
      final stockpile = const Stockpile().applyDelta(_grainId, 100);
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
      expect(fed.stockpile.quantityOf(_grainId), 92);
    },
  ),
  ConsumptionScenario(
    label: 'priority Masters→...→Peasants: masters fed before peasants',
    run: () {
      final stockpile = const Stockpile().applyDelta(_grainId, 2);
      const workers = WorkerPool(masters: 1, peasants: 5);

      final fed = consumeWorkerFood(stockpile: stockpile, workers: workers);

      expect(fed.fedMasters, 1);
      expect(fed.fedPeasants, 0);
      expect(fed.stockpile.quantityOf(_grainId), 0);
    },
  ),
  ConsumptionScenario(
    label: 'grain consumed before meat',
    run: () {
      final stockpile = const Stockpile()
          .applyDelta(_grainId, 2)
          .applyDelta(_meatId, 10);
      const workers = WorkerPool(apprentices: 2);

      final fed = consumeWorkerFood(stockpile: stockpile, workers: workers);

      expect(fed.fedApprentices, 2);
      expect(fed.stockpile.quantityOf(_grainId), 0);
      expect(fed.stockpile.quantityOf(_meatId), 8);
    },
  ),
  ConsumptionScenario(
    label: 'no food leaves all tiers on strike',
    run: () {
      const stockpile = Stockpile();
      const workers = WorkerPool(masters: 1, peasants: 2);

      final fed = consumeWorkerFood(stockpile: stockpile, workers: workers);

      expect(fed.fedMasters, 0);
      expect(fed.fedPeasants, 0);
    },
  ),
];

/// Canonical scenarios for [assignWorkerLuxury].
List<ConsumptionPhaseScenario> assignWorkerLuxuryScenarios() => [
  ConsumptionScenario(
    label: 'assigns one luxury per food-fed worker when supply suffices',
    run: () {
      final stockpile = const Stockpile().applyDelta(_sugarId, 5);

      final (next, withLuxury) = assignWorkerLuxury(
        stockpile: stockpile,
        foodFedCount: 3,
        luxuryId: _sugarId,
      );

      expect(withLuxury, 3);
      expect(next.quantityOf(_sugarId), 2);
    },
  ),
  ConsumptionScenario(
    label: 'luxury strike: short supply caps count and deducts what exists',
    run: () {
      final stockpile = const Stockpile().applyDelta(_sugarId, 1);

      final (next, withLuxury) = assignWorkerLuxury(
        stockpile: stockpile,
        foodFedCount: 3,
        luxuryId: _sugarId,
      );

      expect(withLuxury, 1);
      expect(next.quantityOf(_sugarId), 0);
    },
  ),
  ConsumptionScenario(
    label: 'no food-fed workers deducts nothing',
    run: () {
      final stockpile = const Stockpile().applyDelta(_sugarId, 5);

      final (next, withLuxury) = assignWorkerLuxury(
        stockpile: stockpile,
        foodFedCount: 0,
        luxuryId: _sugarId,
      );

      expect(withLuxury, 0);
      expect(next.quantityOf(_sugarId), 5);
    },
  ),
  ConsumptionScenario(
    label: 'no luxury available deducts nothing',
    run: () {
      const stockpile = Stockpile();

      final (next, withLuxury) = assignWorkerLuxury(
        stockpile: stockpile,
        foodFedCount: 3,
        luxuryId: _sugarId,
      );

      expect(withLuxury, 0);
      expect(next.quantityOf(_sugarId), 0);
    },
  ),
];

/// Canonical scenarios for [consumeFoodUnits].
List<ConsumptionPhaseScenario> consumeFoodUnitsScenarios() => [
  ConsumptionScenario(
    label: 'grain then meat, returns consumed amount',
    run: () {
      final stockpile = const Stockpile()
          .applyDelta(_grainId, 3)
          .applyDelta(_meatId, 5);

      final (next, consumed) = consumeFoodUnits(
        stockpile: stockpile,
        required: 6,
      );

      expect(consumed, 6);
      expect(next.quantityOf(_grainId), 0);
      expect(next.quantityOf(_meatId), 2);
    },
  ),
  ConsumptionScenario(
    label: 'caps consumed at available when demand exceeds supply',
    run: () {
      final stockpile = const Stockpile().applyDelta(_grainId, 2);

      final (next, consumed) = consumeFoodUnits(
        stockpile: stockpile,
        required: 9,
      );

      expect(consumed, 2);
      expect(next.quantityOf(_grainId), 0);
    },
  ),
];
