import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:test/test.dart';

void main() {
  suppressLogsForTests();

  group('computeLabourReadiness', () {
    test('full capacity when all workers fed and luxuried', () {
      const workers = WorkerPool(
        peasants: 1,
        apprentices: 1,
        journeymen: 0,
        masters: 0,
      );
      final stockpile = const Stockpile()
          .applyDelta('grain', 10)
          .applyDelta('meat', 10)
          .applyDelta('refinedSugar', 1);
      final snapshot = computeLabourReadiness(
        workers: workers,
        stockpile: stockpile,
      );
      expect(snapshot.effectiveLabour, workers.labourSupplyPerTurn);
      expect(snapshot.isFullCapacity, isTrue);
      expect(snapshot.primaryCauseKind, isNull);
    });

    test('food shortfall is primary when labour loss is larger', () {
      const workers = WorkerPool(peasants: 4, masters: 0);
      final stockpile = const Stockpile().applyDelta('grain', 2);
      final snapshot = computeLabourReadiness(
        workers: workers,
        stockpile: stockpile,
      );
      expect(snapshot.effectiveLabour, lessThan(snapshot.fullCapacity));
      expect(snapshot.primaryCauseKind, LabourReadinessCauseKind.food);
    });

    test('luxury shortfall is primary when only luxury blocks labour', () {
      const workers = WorkerPool(masters: 2);
      final stockpile = const Stockpile()
          .applyDelta('grain', 10)
          .applyDelta('meat', 10);
      final snapshot = computeLabourReadiness(
        workers: workers,
        stockpile: stockpile,
      );
      expect(snapshot.effectiveLabour, 0);
      expect(snapshot.primaryCauseKind, LabourReadinessCauseKind.luxury);
      expect(snapshot.primaryLuxuryCommodityId, 'furHats');
      expect(snapshot.primaryLuxuryTier, WorkerTierKey.master);
    });

    test('tier breakdown matches working counts', () {
      const workers = WorkerPool(peasants: 3);
      final stockpile = const Stockpile().applyDelta('grain', 2);
      final snapshot = computeLabourReadiness(
        workers: workers,
        stockpile: stockpile,
      );
      final peasants = snapshot.tierStatuses.firstWhere(
        (t) => t.tier == WorkerTierKey.peasant,
      );
      expect(peasants.poolCount, 3);
      expect(peasants.workingCount, 2);
      expect(peasants.notWorkingCount, 1);
    });

    test('military food draw flagged when armies consume before workers', () {
      const workers = WorkerPool(peasants: 2);
      final stockpile = const Stockpile().applyDelta('grain', 2);
      final snapshot = computeLabourReadiness(
        workers: workers,
        stockpile: stockpile,
        foodCounts: const MilitaryNavyFoodCounts(militaryUnits: 1),
      );
      expect(snapshot.militaryOrNavyConsumesFoodBeforeWorkers, isTrue);
      expect(snapshot.effectiveLabour, 0);
    });
  });
}
