// Table-driven worker labour primitive scenarios (Refs #3939 phase 3 slice 21).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

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
  WorkerEconomyScenario(
    label: 'sums tier multipliers (1/4/6/8) over idle counts',
    run: () {
      const idle = WorkerIdleCounts(
        peasants: 1,
        apprentices: 1,
        journeymen: 1,
        masters: 1,
      );
      expect(effectiveLabourFromIdleCounts(idle), 19);
    },
  ),
  WorkerEconomyScenario(
    label: 'zero idle counts contribute no labour',
    run: () {
      expect(effectiveLabourFromIdleCounts(WorkerIdleCounts.zero), 0);
    },
  ),
];

/// Canonical scenarios for [effectiveLabourForWorkers].
List<WorkerEconomyScenario> workerEconomyLabourForWorkersScenarios() => [
  WorkerEconomyScenario(
    label: 'fed peasants contribute labour without luxury',
    run: () {
      final stockpile = const Stockpile().applyDelta(_grainId, 2);
      final labour = effectiveLabourForWorkers(
        workers: const WorkerPool(peasants: 2),
        stockpile: stockpile,
      );
      expect(labour, 2 * WorkerPool.labourPerPeasantTurn);
    },
  ),
  WorkerEconomyScenario(
    label: 'trained worker needs both food and luxury to count',
    run: () {
      final stockpile = const Stockpile()
          .applyDelta(_grainId, 2)
          .applyDelta(_furHatsId, 1);
      final labour = effectiveLabourForWorkers(
        workers: const WorkerPool(masters: 1),
        stockpile: stockpile,
      );
      expect(labour, WorkerPool.labourPerMasterTurn);
    },
  ),
  WorkerEconomyScenario(
    label: 'fed-but-unluxuried trained worker contributes no labour',
    run: () {
      final stockpile = const Stockpile().applyDelta(_grainId, 2);
      final labour = effectiveLabourForWorkers(
        workers: const WorkerPool(masters: 1),
        stockpile: stockpile,
      );
      expect(labour, 0);
    },
  ),
  WorkerEconomyScenario(
    label: 'no food leaves workers on strike (zero labour)',
    run: () {
      final labour = effectiveLabourForWorkers(
        workers: const WorkerPool(peasants: 3),
        stockpile: const Stockpile(),
      );
      expect(labour, 0);
    },
  ),
  WorkerEconomyScenario(
    label: 'military upkeep consumes food before workers',
    run: () {
      final stockpile = const Stockpile().applyDelta(_grainId, 2);
      final labour = effectiveLabourForWorkers(
        workers: const WorkerPool(peasants: 1),
        stockpile: stockpile,
        militaryUnits: 1,
      );
      expect(labour, 0);
    },
  ),
];
