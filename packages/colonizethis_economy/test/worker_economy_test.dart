import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// Dedicated unit tests for the worker-economy labour primitives.
/// SPEC/program/economy-models.md, SPEC/game/workers-and-population.md.
void main() {
  final grainId = CommodityCatalog.grain.id;
  final furHatsId = CommodityCatalog.furHats.id;

  group('effectiveLabourFromIdleCounts', () {
    test('sums tier multipliers (1/4/6/8) over idle counts', () {
      const idle = WorkerIdleCounts(
        peasants: 1,
        apprentices: 1,
        journeymen: 1,
        masters: 1,
      );

      // 1*1 + 1*4 + 1*6 + 1*8 = 19.
      expect(effectiveLabourFromIdleCounts(idle), 19);
    });

    test('zero idle counts contribute no labour', () {
      expect(effectiveLabourFromIdleCounts(WorkerIdleCounts.zero), 0);
    });
  });

  group('effectiveLabourForWorkers', () {
    test('fed peasants contribute labour without luxury', () {
      // 2 peasants need 1 food each; no luxury required for peasants.
      final stockpile = const Stockpile().applyDelta(grainId, 2);

      final labour = effectiveLabourForWorkers(
        workers: const WorkerPool(peasants: 2),
        stockpile: stockpile,
      );

      expect(labour, 2 * WorkerPool.labourPerPeasantTurn);
    });

    test('trained worker needs both food and luxury to count', () {
      // Master needs 2 food + 1 fur hat luxury to be idle for labour.
      final stockpile = const Stockpile()
          .applyDelta(grainId, 2)
          .applyDelta(furHatsId, 1);

      final labour = effectiveLabourForWorkers(
        workers: const WorkerPool(masters: 1),
        stockpile: stockpile,
      );

      expect(labour, WorkerPool.labourPerMasterTurn);
    });

    test('fed-but-unluxuried trained worker contributes no labour', () {
      // Food present, but no fur hats: master is fed yet on luxury strike.
      final stockpile = const Stockpile().applyDelta(grainId, 2);

      final labour = effectiveLabourForWorkers(
        workers: const WorkerPool(masters: 1),
        stockpile: stockpile,
      );

      expect(labour, 0);
    });

    test('no food leaves workers on strike (zero labour)', () {
      final labour = effectiveLabourForWorkers(
        workers: const WorkerPool(peasants: 3),
        stockpile: const Stockpile(),
      );

      expect(labour, 0);
    });

    test('military upkeep consumes food before workers', () {
      // Only 2 grain; one regiment (2 food upkeep) eats it all, so the
      // peasant starves and contributes no labour.
      final stockpile = const Stockpile().applyDelta(grainId, 2);

      final labour = effectiveLabourForWorkers(
        workers: const WorkerPool(peasants: 1),
        stockpile: stockpile,
        militaryUnits: 1,
      );

      expect(labour, 0);
    });
  });
}
