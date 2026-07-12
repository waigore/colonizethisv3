// dart format off
// Table-driven resolveProduction / effectiveLabourForWorkers scenarios (Refs #3856, #3979).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'core_economy_test_support.dart';
import 'economy_production_expectations.dart';

/// One row for [resolveProduction] tables (Refs #3979).
typedef ResolveProductionScenario = ({String label, ResolveProductionPins pins, String? refs});

void runResolveProductionScenario(ResolveProductionScenario scenario) {
  runResolveProductionExpectation(scenario.pins);
}

/// One row for production [effectiveLabourForWorkers] tables (Refs #3979).
typedef ProductionEffectiveLabourScenario = ({String label, ProductionEffectiveLabourPins pins, String? refs});

void runProductionEffectiveLabourScenario(ProductionEffectiveLabourScenario scenario) {
  runProductionEffectiveLabourExpectation(scenario.pins);
}

/// Canonical scenarios for [resolveProduction].
List<ResolveProductionScenario> resolveProductionScenarios() => [..._resolveProductionRecipeScenarios(), ..._resolveProductionEdgeScenarios()];

/// Canonical scenarios for [effectiveLabourForWorkers].
List<ProductionEffectiveLabourScenario> effectiveLabourForWorkersScenarios() => [..._effectiveLabourForWorkersScenarios()];

List<ResolveProductionScenario> _resolveProductionRecipeScenarios() => [
  resolveProductionScenario(
    label: 'consumes inputs and produces output per recipe',
    pins: (stockpileDeltas: {'timber': 10, 'iron': 10, 'coal': 5}, workers: coreWorkerPool(peasants: 20), idleLabour: WorkerIdleCounts(peasants: 20), assignments: const [AssignedRecipe(recipeId: 'castIron_from_iron', assignedLabour: 20)], expectedQuantities: {'castIron': 5, 'timber': 10, 'iron': 0, 'coal': 5}, expectedWorkers: null),
  ),
  resolveProductionScenario(
    label: 'iron-only castIron recipe ignores timber (Refs #3858)',
    refs: '#3858',
    pins: (stockpileDeltas: {'iron': 4}, workers: const WorkerPool(peasants: 10), idleLabour: WorkerIdleCounts(peasants: 10), assignments: const [AssignedRecipe(recipeId: 'castIron_from_iron', assignedLabour: 10)], expectedQuantities: {'castIron': 2, 'iron': 0, 'timber': 0}, expectedWorkers: null),
  ),
  resolveProductionScenario(
    label: 'limits runs by available inputs',
    pins: (stockpileDeltas: {'timber': 4, 'iron': 4, 'coal': 20}, workers: const WorkerPool(peasants: 20), idleLabour: WorkerIdleCounts(peasants: 20), assignments: const [AssignedRecipe(recipeId: 'castIron_from_iron', assignedLabour: 100)], expectedQuantities: {'castIron': 2, 'iron': 0, 'timber': 4}, expectedWorkers: null),
  ),
  resolveProductionScenario(
    label: 'limits runs by assigned labour (labourPerOutput)',
    pins: (stockpileDeltas: {'timber': 100, 'iron': 100, 'coal': 50}, workers: const WorkerPool(peasants: 10), idleLabour: WorkerIdleCounts(peasants: 10), assignments: const [AssignedRecipe(recipeId: 'castIron_from_iron', assignedLabour: 7)], expectedQuantities: {'castIron': 3}, expectedWorkers: null),
  ),
  resolveProductionScenario(
    label: 'worker pool is unchanged',
    pins: (stockpileDeltas: {'timber': 10, 'iron': 10, 'coal': 5}, workers: const WorkerPool(peasants: 3, apprentices: 2), idleLabour: WorkerIdleCounts(peasants: 3, apprentices: 2), assignments: const [AssignedRecipe(recipeId: 'castIron_from_iron', assignedLabour: 20)], expectedQuantities: {}, expectedWorkers: const WorkerPool(peasants: 3, apprentices: 2)),
  ),
  resolveProductionScenario(
    label: 'multiple assignments apply in order',
    pins: (
      stockpileDeltas: {'timber': 20, 'iron': 20, 'coal': 10},
      workers: const WorkerPool(peasants: 25),
      idleLabour: WorkerIdleCounts(peasants: 25),
      assignments: const [
        AssignedRecipe(recipeId: 'castIron_from_iron', assignedLabour: 15),
        AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 10),
      ],
      expectedQuantities: {'castIron': 7, 'lumber': 5},
      expectedWorkers: null,
    ),
  ),
];

List<ResolveProductionScenario> _resolveProductionEdgeScenarios() => [
  resolveProductionScenario(
    label: 'unknown recipe id is ignored',
    pins: (stockpileDeltas: {'grain': 10}, workers: const WorkerPool(peasants: 5), idleLabour: WorkerIdleCounts(peasants: 5), assignments: const [AssignedRecipe(recipeId: 'unknown_recipe', assignedLabour: 100)], expectedQuantities: {'grain': 10}, expectedWorkers: null),
  ),
  resolveProductionScenario(
    label: 'zero assigned labour skips recipe',
    pins: (stockpileDeltas: {'timber': 10, 'iron': 10, 'coal': 5}, workers: const WorkerPool(peasants: 5), idleLabour: WorkerIdleCounts(peasants: 5), assignments: const [AssignedRecipe(recipeId: 'castIron_from_iron', assignedLabour: 0)], expectedQuantities: {'castIron': 0, 'timber': 10}, expectedWorkers: null),
  ),
  resolveProductionScenario(label: 'empty assignments leave stockpile unchanged', pins: (stockpileDeltas: {'grain': 5}, workers: const WorkerPool(peasants: 5), idleLabour: WorkerIdleCounts(peasants: 5), assignments: const [], expectedQuantities: {'grain': 5}, expectedWorkers: null)),
];

List<ProductionEffectiveLabourScenario> _effectiveLabourForWorkersScenarios() => [
  productionEffectiveLabourScenario(label: 'peasants contribute 1 labour each when fed', pins: (workers: const WorkerPool(peasants: 10), stockpileDeltas: {'grain': 10}, expectedLabour: 10)),
  productionEffectiveLabourScenario(label: 'trained workers capped by luxury after food', pins: (workers: const WorkerPool(peasants: 2, apprentices: 3, journeymen: 0, masters: 0), stockpileDeltas: {'grain': 8, 'refinedSugar': 1}, expectedLabour: 6)),
  productionEffectiveLabourScenario(label: 'full luxury gives full trained labour when food sufficient', pins: (workers: const WorkerPool(peasants: 1, apprentices: 2, journeymen: 1, masters: 0), stockpileDeltas: {'grain': 7, 'refinedSugar': 5, 'cigars': 5}, expectedLabour: 15)),
];
// dart format on
