// dart format off
// Table-driven consumption → production integration (Refs #4090 Slice A).
// Kept in economy/test (not economy_test_support) to preserve support LOC ceiling.

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

typedef _Scenario = ({
  String label,
  Map<String, int> stockpileDeltas,
  WorkerPool workers,
  List<AssignedRecipe> assignments,
  WorkerIdleCounts expectedIdleAfterConsumption,
  Map<String, int>? expectedStockpileAfterConsumption,
  Map<String, int> expectedProductionByRecipe,
  Map<String, int> expectedStockpileAfterProduction,
});

_Scenario _row({
  required String label,
  required Map<String, int> stockpileDeltas,
  required WorkerPool workers,
  required List<AssignedRecipe> assignments,
  required WorkerIdleCounts expectedIdleAfterConsumption,
  Map<String, int>? expectedStockpileAfterConsumption,
  required Map<String, int> expectedProductionByRecipe,
  required Map<String, int> expectedStockpileAfterProduction,
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
    );

void _run(_Scenario scenario) {
  final cons = resolveConsumption(stockpile: stockpileWithDeltas(scenario.stockpileDeltas), workers: scenario.workers);
  expect(cons.idleLabour, scenario.expectedIdleAfterConsumption);
  final afterCons = scenario.expectedStockpileAfterConsumption;
  if (afterCons != null) {
    for (final e in afterCons.entries) {
      expect(cons.stockpile.quantityOf(e.key), e.value);
    }
  }
  final prod = resolveProduction(
    stockpile: cons.stockpile,
    workers: cons.workerPool,
    idleLabour: cons.idleLabour,
    assignments: scenario.assignments,
  );
  for (final e in scenario.expectedProductionByRecipe.entries) {
    expect(prod.productionByRecipe[e.key] ?? 0, e.value);
  }
  for (final e in scenario.expectedStockpileAfterProduction.entries) {
    expect(prod.stockpile.quantityOf(e.key), e.value);
  }
}

List<_Scenario> _scenarios() => [
  _row(
    label: 'production uses post-consumption stockpile and idle labour only',
    stockpileDeltas: const {'grain': 20, 'meat': 20, 'timber': 10, 'refinedSugar': 1},
    workers: const WorkerPool(peasants: 0, apprentices: 2, journeymen: 0, masters: 0),
    assignments: const [AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 8)],
    expectedIdleAfterConsumption: WorkerIdleCounts(apprentices: 1),
    expectedStockpileAfterConsumption: const {'refinedSugar': 0},
    expectedProductionByRecipe: const {'lumber_from_timber': 2},
    expectedStockpileAfterProduction: const {'timber': 6},
  ),
  _row(
    label: 'peasants on food strike contribute no production labour',
    stockpileDeltas: const {'grain': 0, 'meat': 0, 'timber': 20},
    workers: const WorkerPool(peasants: 10),
    assignments: const [AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 100)],
    expectedIdleAfterConsumption: WorkerIdleCounts(peasants: 0),
    expectedProductionByRecipe: const {'lumber_from_timber': 0},
    expectedStockpileAfterProduction: const {'timber': 20},
  ),
  _row(
    label: 'master idle with food and luxury produces at master labour rate',
    stockpileDeltas: const {'grain': 5, 'meat': 5, 'timber': 30, 'furHats': 1},
    workers: const WorkerPool(masters: 1),
    assignments: const [AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 8)],
    expectedIdleAfterConsumption: WorkerIdleCounts(masters: 1),
    expectedProductionByRecipe: const {'lumber_from_timber': 4},
    expectedStockpileAfterProduction: const {},
  ),
  _row(
    label: 'journeyman on luxury strike after food: zero journeyman labour',
    stockpileDeltas: const {'grain': 10, 'meat': 10, 'timber': 20, 'cigars': 0},
    workers: const WorkerPool(journeymen: 1),
    assignments: const [AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 6)],
    expectedIdleAfterConsumption: WorkerIdleCounts(journeymen: 0),
    expectedProductionByRecipe: const {'lumber_from_timber': 0},
    expectedStockpileAfterProduction: const {},
  ),
];

/// Consumption → Production order and strike interaction.
/// SPEC/game/workers-and-population.md, SPEC/program/turn-resolution-phase-details.md.
void main() {
  group('consumption then production', () {
    runLabeledScenarios(_scenarios(), _run, labelOf: (s) => s.label);
  });
}
// dart format on
