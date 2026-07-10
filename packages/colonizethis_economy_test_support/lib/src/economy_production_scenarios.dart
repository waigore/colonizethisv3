// Table-driven resolveProduction / effectiveLabourForWorkers scenarios (Refs #3856).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'core_economy_test_support.dart';
import 'economy_production_expectations.dart';

/// One row in an economy-production scenario table.
class EconomyProductionScenario {
  const EconomyProductionScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  final String label;
  final void Function() run;
  final String? refs;
}

/// Runs [scenario] (setup + assertions live in [EconomyProductionScenario.run]).
void runEconomyProductionScenario(EconomyProductionScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for [resolveProduction].
List<EconomyProductionScenario> resolveProductionScenarios() => [
      ..._resolveProductionRecipeScenarios(),
      ..._resolveProductionEdgeScenarios(),
    ];

/// Canonical scenarios for [effectiveLabourForWorkers].
List<EconomyProductionScenario> effectiveLabourForWorkersScenarios() => [
      ..._effectiveLabourForWorkersScenarios(),
    ];

List<EconomyProductionScenario> _resolveProductionRecipeScenarios() => [
      resolveProductionScenario(
        label: 'consumes inputs and produces output per recipe',
        pins: (
          stockpileDeltas: {
            CommodityCatalog.timber.id: 10,
            CommodityCatalog.iron.id: 10,
            CommodityCatalog.coal.id: 5,
          },
          workers: coreWorkerPool(peasants: 20),
          idleLabour: WorkerIdleCounts(peasants: 20),
          assignments: const [
            AssignedRecipe(
              recipeId: 'castIron_from_iron',
              assignedLabour: 20,
            ),
          ],
          expectedQuantities: {
            CommodityCatalog.castIron.id: 5,
            CommodityCatalog.timber.id: 10,
            CommodityCatalog.iron.id: 0,
            CommodityCatalog.coal.id: 5,
          },
          expectedWorkers: null,
        ),
      ),
      resolveProductionScenario(
        label: 'iron-only castIron recipe ignores timber (Refs #3858)',
        refs: '#3858',
        pins: (
          stockpileDeltas: {CommodityCatalog.iron.id: 4},
          workers: const WorkerPool(peasants: 10),
          idleLabour: WorkerIdleCounts(peasants: 10),
          assignments: const [
            AssignedRecipe(
              recipeId: 'castIron_from_iron',
              assignedLabour: 10,
            ),
          ],
          expectedQuantities: {
            CommodityCatalog.castIron.id: 2,
            CommodityCatalog.iron.id: 0,
            CommodityCatalog.timber.id: 0,
          },
          expectedWorkers: null,
        ),
      ),
      resolveProductionScenario(
        label: 'limits runs by available inputs',
        pins: (
          stockpileDeltas: {
            CommodityCatalog.timber.id: 4,
            CommodityCatalog.iron.id: 4,
            CommodityCatalog.coal.id: 20,
          },
          workers: const WorkerPool(peasants: 20),
          idleLabour: WorkerIdleCounts(peasants: 20),
          assignments: const [
            AssignedRecipe(
              recipeId: 'castIron_from_iron',
              assignedLabour: 100,
            ),
          ],
          expectedQuantities: {
            CommodityCatalog.castIron.id: 2,
            CommodityCatalog.iron.id: 0,
            CommodityCatalog.timber.id: 4,
          },
          expectedWorkers: null,
        ),
      ),
      resolveProductionScenario(
        label: 'limits runs by assigned labour (labourPerOutput)',
        pins: (
          stockpileDeltas: {
            CommodityCatalog.timber.id: 100,
            CommodityCatalog.iron.id: 100,
            CommodityCatalog.coal.id: 50,
          },
          workers: const WorkerPool(peasants: 10),
          idleLabour: WorkerIdleCounts(peasants: 10),
          assignments: const [
            AssignedRecipe(
              recipeId: 'castIron_from_iron',
              assignedLabour: 7,
            ),
          ],
          expectedQuantities: {
            CommodityCatalog.castIron.id: 3,
          },
          expectedWorkers: null,
        ),
      ),
      resolveProductionScenario(
        label: 'worker pool is unchanged',
        pins: (
          stockpileDeltas: {
            CommodityCatalog.timber.id: 10,
            CommodityCatalog.iron.id: 10,
            CommodityCatalog.coal.id: 5,
          },
          workers: const WorkerPool(peasants: 3, apprentices: 2),
          idleLabour: WorkerIdleCounts(peasants: 3, apprentices: 2),
          assignments: const [
            AssignedRecipe(
              recipeId: 'castIron_from_iron',
              assignedLabour: 20,
            ),
          ],
          expectedQuantities: {},
          expectedWorkers: const WorkerPool(peasants: 3, apprentices: 2),
        ),
      ),
      resolveProductionScenario(
        label: 'multiple assignments apply in order',
        pins: (
          stockpileDeltas: {
            CommodityCatalog.timber.id: 20,
            CommodityCatalog.iron.id: 20,
            CommodityCatalog.coal.id: 10,
          },
          workers: const WorkerPool(peasants: 25),
          idleLabour: WorkerIdleCounts(peasants: 25),
          assignments: const [
            AssignedRecipe(
              recipeId: 'castIron_from_iron',
              assignedLabour: 15,
            ),
            AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 10),
          ],
          expectedQuantities: {
            CommodityCatalog.castIron.id: 7,
            CommodityCatalog.lumber.id: 5,
          },
          expectedWorkers: null,
        ),
      ),
    ];

List<EconomyProductionScenario> _resolveProductionEdgeScenarios() => [
      resolveProductionScenario(
        label: 'unknown recipe id is ignored',
        pins: (
          stockpileDeltas: {CommodityCatalog.grain.id: 10},
          workers: const WorkerPool(peasants: 5),
          idleLabour: WorkerIdleCounts(peasants: 5),
          assignments: const [
            AssignedRecipe(recipeId: 'unknown_recipe', assignedLabour: 100),
          ],
          expectedQuantities: {CommodityCatalog.grain.id: 10},
          expectedWorkers: null,
        ),
      ),
      resolveProductionScenario(
        label: 'zero assigned labour skips recipe',
        pins: (
          stockpileDeltas: {
            CommodityCatalog.timber.id: 10,
            CommodityCatalog.iron.id: 10,
            CommodityCatalog.coal.id: 5,
          },
          workers: const WorkerPool(peasants: 5),
          idleLabour: WorkerIdleCounts(peasants: 5),
          assignments: const [
            AssignedRecipe(
              recipeId: 'castIron_from_iron',
              assignedLabour: 0,
            ),
          ],
          expectedQuantities: {
            CommodityCatalog.castIron.id: 0,
            CommodityCatalog.timber.id: 10,
          },
          expectedWorkers: null,
        ),
      ),
      resolveProductionScenario(
        label: 'empty assignments leave stockpile unchanged',
        pins: (
          stockpileDeltas: {CommodityCatalog.grain.id: 5},
          workers: const WorkerPool(peasants: 5),
          idleLabour: WorkerIdleCounts(peasants: 5),
          assignments: const [],
          expectedQuantities: {CommodityCatalog.grain.id: 5},
          expectedWorkers: null,
        ),
      ),
    ];

List<EconomyProductionScenario> _effectiveLabourForWorkersScenarios() => [
      effectiveLabourScenario(
        label: 'peasants contribute 1 labour each when fed',
        pins: (
          workers: const WorkerPool(peasants: 10),
          stockpileDeltas: {CommodityCatalog.grain.id: 10},
          expectedLabour: 10,
        ),
      ),
      effectiveLabourScenario(
        label: 'trained workers capped by luxury after food',
        pins: (
          workers: const WorkerPool(
            peasants: 2,
            apprentices: 3,
            journeymen: 0,
            masters: 0,
          ),
          stockpileDeltas: {
            CommodityCatalog.grain.id: 8,
            CommodityCatalog.refinedSugar.id: 1,
          },
          expectedLabour: 6,
        ),
      ),
      effectiveLabourScenario(
        label: 'full luxury gives full trained labour when food sufficient',
        pins: (
          workers: const WorkerPool(
            peasants: 1,
            apprentices: 2,
            journeymen: 1,
            masters: 0,
          ),
          stockpileDeltas: {
            CommodityCatalog.grain.id: 7,
            CommodityCatalog.refinedSugar.id: 5,
            CommodityCatalog.cigars.id: 5,
          },
          expectedLabour: 15,
        ),
      ),
    ];
