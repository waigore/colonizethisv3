import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

typedef _Scenario = ({
  String label,
  WorkerPool workers,
  Stockpile stockpile,
  MilitaryNavyFoodCounts foodCounts,
  void Function(LabourReadinessSnapshot snapshot) verify,
});

void _runScenario(_Scenario scenario) {
  final snapshot = computeLabourReadiness(
    workers: scenario.workers,
    stockpile: scenario.stockpile,
    foodCounts: scenario.foodCounts,
  );
  scenario.verify(snapshot);
}

Iterable<_Scenario> _scenarios() sync* {
  const fullWorkers = WorkerPool(
    peasants: 1,
    apprentices: 1,
    journeymen: 0,
    masters: 0,
  );
  yield (
    label: 'full capacity when all workers fed and luxuried',
    workers: fullWorkers,
    stockpile: const Stockpile()
        .applyDelta('grain', 10)
        .applyDelta('meat', 10)
        .applyDelta('refinedSugar', 1),
    foodCounts: const MilitaryNavyFoodCounts(),
    verify: (snapshot) {
      expect(snapshot.effectiveLabour, fullWorkers.labourSupplyPerTurn);
      expect(snapshot.isFullCapacity, isTrue);
      expect(snapshot.primaryCauseKind, isNull);
    },
  );

  yield (
    label: 'food shortfall is primary when labour loss is larger',
    workers: const WorkerPool(peasants: 4, masters: 0),
    stockpile: const Stockpile().applyDelta('grain', 2),
    foodCounts: const MilitaryNavyFoodCounts(),
    verify: (snapshot) {
      expect(snapshot.effectiveLabour, lessThan(snapshot.fullCapacity));
      expect(snapshot.primaryCauseKind, LabourReadinessCauseKind.food);
    },
  );

  yield (
    label: 'luxury shortfall is primary when only luxury blocks labour',
    workers: const WorkerPool(masters: 2),
    stockpile: const Stockpile()
        .applyDelta('grain', 10)
        .applyDelta('meat', 10),
    foodCounts: const MilitaryNavyFoodCounts(),
    verify: (snapshot) {
      expect(snapshot.effectiveLabour, 0);
      expect(snapshot.primaryCauseKind, LabourReadinessCauseKind.luxury);
      expect(snapshot.primaryLuxuryCommodityId, 'furHats');
      expect(snapshot.primaryLuxuryTier, WorkerTierKey.master);
    },
  );

  yield (
    label: 'tier breakdown matches working counts',
    workers: const WorkerPool(peasants: 3),
    stockpile: const Stockpile().applyDelta('grain', 2),
    foodCounts: const MilitaryNavyFoodCounts(),
    verify: (snapshot) {
      final peasants = snapshot.tierStatuses.firstWhere(
        (t) => t.tier == WorkerTierKey.peasant,
      );
      expect(peasants.poolCount, 3);
      expect(peasants.workingCount, 2);
      expect(peasants.notWorkingCount, 1);
    },
  );

  yield (
    label: 'military food draw flagged when armies consume before workers',
    workers: const WorkerPool(peasants: 2),
    stockpile: const Stockpile().applyDelta('grain', 2),
    foodCounts: const MilitaryNavyFoodCounts(militaryUnits: 1),
    verify: (snapshot) {
      expect(snapshot.militaryOrNavyConsumesFoodBeforeWorkers, isTrue);
      expect(snapshot.effectiveLabour, 0);
    },
  );
}

void main() {
  suppressLogsForTests();

  runLabeledScenarioGroup(
    'computeLabourReadiness',
    _scenarios(),
    _runScenario,
    labelOf: (scenario) => scenario.label,
  );
}
