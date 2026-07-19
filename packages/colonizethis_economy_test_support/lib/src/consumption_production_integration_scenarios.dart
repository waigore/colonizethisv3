// dart format off
// Consumption → production order / strike interaction (ported from logic orphan; Refs #4090 Slice A).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'core_economy_test_support.dart';

/// One row for consumption-then-production integration tables.
typedef ConsumptionProductionIntegrationScenario = ({
  String label,
  Map<String, int> stockpileDeltas,
  WorkerPool workers,
  List<AssignedRecipe> assignments,
  WorkerIdleCounts expectedIdleAfterConsumption,
  Map<String, int>? expectedStockpileAfterConsumption,
  Map<String, int> expectedProductionByRecipe,
  Map<String, int> expectedStockpileAfterProduction,
  String? refs,
});

void runConsumptionProductionIntegrationScenario(
  ConsumptionProductionIntegrationScenario scenario,
) {
  final stockpile = stockpileWithDeltas(scenario.stockpileDeltas);
  final cons = resolveConsumption(
    stockpile: stockpile,
    workers: scenario.workers,
  );
  expect(cons.idleLabour, scenario.expectedIdleAfterConsumption);
  final afterCons = scenario.expectedStockpileAfterConsumption;
  if (afterCons != null) {
    for (final entry in afterCons.entries) {
      expect(cons.stockpile.quantityOf(entry.key), entry.value);
    }
  }
  final prod = resolveProduction(
    stockpile: cons.stockpile,
    workers: cons.workerPool,
    idleLabour: cons.idleLabour,
    assignments: scenario.assignments,
  );
  for (final entry in scenario.expectedProductionByRecipe.entries) {
    expect(prod.productionByRecipe[entry.key] ?? 0, entry.value);
  }
  for (final entry in scenario.expectedStockpileAfterProduction.entries) {
    expect(prod.stockpile.quantityOf(entry.key), entry.value);
  }
}

ConsumptionProductionIntegrationScenario consumptionProductionIntegrationScenario({
  required String label,
  required Map<String, int> stockpileDeltas,
  required WorkerPool workers,
  required List<AssignedRecipe> assignments,
  required WorkerIdleCounts expectedIdleAfterConsumption,
  Map<String, int>? expectedStockpileAfterConsumption,
  required Map<String, int> expectedProductionByRecipe,
  required Map<String, int> expectedStockpileAfterProduction,
  String? refs,
}) =>
    (
      label: label,
      stockpileDeltas: stockpileDeltas,
      workers: workers,
      assignments: assignments,
      expectedIdleAfterConsumption: expectedIdleAfterConsumption,
      expectedStockpileAfterConsumption: expectedStockpileAfterConsumption,
      expectedProductionByRecipe: expectedProductionByRecipe,
      expectedStockpileAfterProduction: expectedStockpileAfterProduction,
      refs: refs,
    );

/// Canonical scenarios for consumption → production ordering.
List<ConsumptionProductionIntegrationScenario>
    consumptionProductionIntegrationScenarios() => [
  consumptionProductionIntegrationScenario(
    label: 'production uses post-consumption stockpile and idle labour only',
    stockpileDeltas: {
      'grain': 20,
      'meat': 20,
      'timber': 10,
      'refinedSugar': 1,
    },
    workers: const WorkerPool(
      peasants: 0,
      apprentices: 2,
      journeymen: 0,
      masters: 0,
    ),
    assignments: const [
      AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 8),
    ],
    expectedIdleAfterConsumption: WorkerIdleCounts(apprentices: 1),
    expectedStockpileAfterConsumption: const {'refinedSugar': 0},
    expectedProductionByRecipe: const {'lumber_from_timber': 2},
    expectedStockpileAfterProduction: const {'timber': 6},
  ),
  consumptionProductionIntegrationScenario(
    label: 'peasants on food strike contribute no production labour',
    stockpileDeltas: {'grain': 0, 'meat': 0, 'timber': 20},
    workers: const WorkerPool(peasants: 10),
    assignments: const [
      AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 100),
    ],
    expectedIdleAfterConsumption: WorkerIdleCounts(peasants: 0),
    expectedProductionByRecipe: const {'lumber_from_timber': 0},
    expectedStockpileAfterProduction: const {'timber': 20},
  ),
  consumptionProductionIntegrationScenario(
    label: 'master idle with food and luxury produces at master labour rate',
    stockpileDeltas: {
      'grain': 5,
      'meat': 5,
      'timber': 30,
      'furHats': 1,
    },
    workers: const WorkerPool(masters: 1),
    assignments: const [
      AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 8),
    ],
    expectedIdleAfterConsumption: WorkerIdleCounts(masters: 1),
    expectedProductionByRecipe: const {'lumber_from_timber': 4},
    expectedStockpileAfterProduction: const {},
  ),
  consumptionProductionIntegrationScenario(
    label: 'journeyman on luxury strike after food: zero journeyman labour',
    stockpileDeltas: {
      'grain': 10,
      'meat': 10,
      'timber': 20,
      'cigars': 0,
    },
    workers: const WorkerPool(journeymen: 1),
    assignments: const [
      AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 6),
    ],
    expectedIdleAfterConsumption: WorkerIdleCounts(journeymen: 0),
    expectedProductionByRecipe: const {'lumber_from_timber': 0},
    expectedStockpileAfterProduction: const {},
  ),
];
// dart format on
