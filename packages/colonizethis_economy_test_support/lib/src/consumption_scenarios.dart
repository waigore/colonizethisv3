// Table-driven resolveConsumption scenarios (Refs #3856).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'core_economy_test_support.dart';

/// One row in a resolveConsumption scenario table.
class ConsumptionScenario {
  const ConsumptionScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  final String label;
  final void Function() run;
  final String? refs;
}

/// Runs [scenario] (setup + assertions live in [ConsumptionScenario.run]).
void runConsumptionScenario(ConsumptionScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for [resolveConsumption].
List<ConsumptionScenario> resolveConsumptionScenarios() => [
  ..._resolveConsumptionWorkerFoodScenarios(),
  ..._resolveConsumptionMilitaryLuxuryScenarios(),
];

List<ConsumptionScenario> _resolveConsumptionWorkerFoodScenarios() => [
  ConsumptionScenario(
    label: 'peasants consume 1 food each (grain or meat)',
    run: () {
      final stockpile = stockpileWithDeltas({
        CommodityCatalog.grain.id: 5,
        CommodityCatalog.meat.id: 0,
      });
      final workers = coreWorkerPool(peasants: 5);

      final result = resolveConsumption(stockpile: stockpile, workers: workers);

      expect(result.workerPool.peasants, 5);
      expect(result.idleLabour.peasants, 5);
      expect(result.stockpile.quantityOf(CommodityCatalog.grain.id), 0);
      expect(result.stockpile.quantityOf(CommodityCatalog.meat.id), 0);
    },
  ),
  ConsumptionScenario(
    label: 'trained tiers consume 2 food each',
    run: () {
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
    },
  ),
  ConsumptionScenario(
    label: 'food strike: masters fed before peasants when food is tight',
    run: () {
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
    },
  ),
  ConsumptionScenario(
    label: 'food strike: journeymen fed before apprentices and peasants',
    run: () {
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
      expect(result.idleLabour.peasants, 0);
    },
  ),
  ConsumptionScenario(
    label: 'food strike: pool unchanged when no food',
    run: () {
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
    },
  ),
  ConsumptionScenario(
    label: 'grain used before meat when both available',
    run: () {
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
    },
  ),
  ConsumptionScenario(
    label: 'zero workers and zero military leaves stockpile unchanged',
    run: () {
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
    },
  ),
];

List<ConsumptionScenario> _resolveConsumptionMilitaryLuxuryScenarios() => [
  ConsumptionScenario(
    label: 'unknown ship type id throws ConsumptionUnknownShipTypeException',
    run: () {
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
    },
  ),
  ConsumptionScenario(
    label:
        'resolveConsumption wires military→navy→workers strike order and counts',
    run: () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 8)
          .applyDelta(CommodityCatalog.meat.id, 0);
      const workers = WorkerPool(peasants: 5);

      final result = resolveConsumption(
        stockpile: stockpile,
        workers: workers,
        militaryUnits: 2,
        shipCountsById: const {'carrack': 1},
      );

      expect(result.totalRegiments, 2);
      expect(result.fullyFedRegiments, 2);
      expect(result.totalShips, 1);
      expect(result.fullyFedShips, 1);
      expect(result.workerPool.peasants, 5);
      expect(result.idleLabour.peasants, 2);
      expect(result.stockpile.quantityOf(CommodityCatalog.grain.id), 0);
    },
  ),
  ConsumptionScenario(
    label:
        'luxury only for food-fed trained; no sugar deducted if apprentice on strike',
    run: () {
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
  ),
  ConsumptionScenario(
    label: 'trained workers consume tier luxuries when food-fed',
    run: () {
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
    },
  ),
  ConsumptionScenario(
    label:
        'luxury strike: food-fed but short luxury → idle capped, partial deduction',
    run: () {
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
  ),
];
