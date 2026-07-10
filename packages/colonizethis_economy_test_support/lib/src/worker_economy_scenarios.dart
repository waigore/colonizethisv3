// Table-driven worker labour primitive scenarios (Refs #3939 phase 3 slice 21).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'worker_economy_expectations.dart';

/// One row in a worker-economy labour scenario table.
class WorkerEconomyScenario {
  const WorkerEconomyScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  final String label;
  final void Function() run;
  final String? refs;
}

void runWorkerEconomyScenario(WorkerEconomyScenario scenario) {
  scenario.run();
}

final _grainId = CommodityCatalog.grain.id;
final _furHatsId = CommodityCatalog.furHats.id;

/// Canonical scenarios for [effectiveLabourFromIdleCounts].
List<WorkerEconomyScenario> workerEconomyLabourFromIdleCountsScenarios() => [
  idleLabourScenario(
    label: 'sums tier multipliers (1/4/6/8) over idle counts',
    pins: (
      idle: const WorkerIdleCounts(
        peasants: 1,
        apprentices: 1,
        journeymen: 1,
        masters: 1,
      ),
      expected: 19,
    ),
  ),
  idleLabourScenario(
    label: 'zero idle counts contribute no labour',
    pins: (idle: WorkerIdleCounts.zero, expected: 0),
  ),
];

/// Canonical scenarios for [effectiveLabourForWorkers].
List<WorkerEconomyScenario> workerEconomyLabourForWorkersScenarios() => [
  effectiveLabourScenario(
    label: 'fed peasants contribute labour without luxury',
    pins: (
      workers: const WorkerPool(peasants: 2),
      stockpile: const Stockpile().applyDelta(_grainId, 2),
      militaryUnits: 0,
      expected: 2 * WorkerPool.labourPerPeasantTurn,
    ),
  ),
  effectiveLabourScenario(
    label: 'trained worker needs both food and luxury to count',
    pins: (
      workers: const WorkerPool(masters: 1),
      stockpile: const Stockpile()
          .applyDelta(_grainId, 2)
          .applyDelta(_furHatsId, 1),
      militaryUnits: 0,
      expected: WorkerPool.labourPerMasterTurn,
    ),
  ),
  effectiveLabourScenario(
    label: 'fed-but-unluxuried trained worker contributes no labour',
    pins: (
      workers: const WorkerPool(masters: 1),
      stockpile: const Stockpile().applyDelta(_grainId, 2),
      militaryUnits: 0,
      expected: 0,
    ),
  ),
  effectiveLabourScenario(
    label: 'no food leaves workers on strike (zero labour)',
    pins: (
      workers: const WorkerPool(peasants: 3),
      stockpile: const Stockpile(),
      militaryUnits: 0,
      expected: 0,
    ),
  ),
  effectiveLabourScenario(
    label: 'military upkeep consumes food before workers',
    pins: (
      workers: const WorkerPool(peasants: 1),
      stockpile: const Stockpile().applyDelta(_grainId, 2),
      militaryUnits: 1,
      expected: 0,
    ),
  ),
];
