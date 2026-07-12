// dart format off
// Table-driven worker labour primitive scenarios (Refs #3939 phase 3 slice 21, #3979).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'worker_economy_expectations.dart';

/// One row for [effectiveLabourFromIdleCounts] tables (Refs #3979).
typedef IdleLabourScenario = ({String label, IdleLabourPins pins, String? refs});

/// One row for [effectiveLabourForWorkers] tables (Refs #3979).
typedef EffectiveLabourScenario = ({String label, EffectiveLabourPins pins, String? refs});

void runIdleLabourScenario(IdleLabourScenario scenario) {
  runIdleLabourExpectation(scenario.pins);
}

void runEffectiveLabourScenario(EffectiveLabourScenario scenario) {
  runEffectiveLabourExpectation(scenario.pins);
}

final _grainId = 'grain';
final _furHatsId = 'furHats';

/// Canonical scenarios for [effectiveLabourFromIdleCounts].
List<IdleLabourScenario> workerEconomyLabourFromIdleCountsScenarios() => [idleLabourScenario(label: 'sums tier multipliers (1/4/6/8) over idle counts', pins: (idle: const WorkerIdleCounts(peasants: 1, apprentices: 1, journeymen: 1, masters: 1), expected: 19)), idleLabourScenario(label: 'zero idle counts contribute no labour', pins: (idle: WorkerIdleCounts.zero, expected: 0))];

/// Canonical scenarios for [effectiveLabourForWorkers].
List<EffectiveLabourScenario> workerEconomyLabourForWorkersScenarios() => [
  effectiveLabourScenario(label: 'fed peasants contribute labour without luxury', pins: (workers: const WorkerPool(peasants: 2), stockpile: const Stockpile().applyDelta(_grainId, 2), militaryUnits: 0, expected: 2 * WorkerPool.labourPerPeasantTurn)),
  effectiveLabourScenario(label: 'trained worker needs both food and luxury to count', pins: (workers: const WorkerPool(masters: 1), stockpile: const Stockpile().applyDelta(_grainId, 2).applyDelta(_furHatsId, 1), militaryUnits: 0, expected: WorkerPool.labourPerMasterTurn)),
  effectiveLabourScenario(label: 'fed-but-unluxuried trained worker contributes no labour', pins: (workers: const WorkerPool(masters: 1), stockpile: const Stockpile().applyDelta(_grainId, 2), militaryUnits: 0, expected: 0)),
  effectiveLabourScenario(label: 'no food leaves workers on strike (zero labour)', pins: (workers: const WorkerPool(peasants: 3), stockpile: const Stockpile(), militaryUnits: 0, expected: 0)),
  effectiveLabourScenario(label: 'military upkeep consumes food before workers', pins: (workers: const WorkerPool(peasants: 1), stockpile: const Stockpile().applyDelta(_grainId, 2), militaryUnits: 1, expected: 0)),
];
// dart format on
