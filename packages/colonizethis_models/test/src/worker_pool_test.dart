import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('WorkerPool', () {
    test('defaults to zero workers', () {
      const pool = WorkerPool();
      expect(pool.peasants, 0);
      expect(pool.apprentices, 0);
      expect(pool.journeymen, 0);
      expect(pool.masters, 0);
      expect(pool.totalWorkers, 0);
    });

    test('copyWith updates fields', () {
      const pool = WorkerPool(peasants: 1, apprentices: 2, journeymen: 3, masters: 4);
      final copy = pool.copyWith(peasants: 5, masters: 0);
      expect(copy.peasants, 5);
      expect(copy.apprentices, 2);
      expect(copy.journeymen, 3);
      expect(copy.masters, 0);
    });

    test('toJson/fromJson round-trip', () {
      const pool = WorkerPool(peasants: 1, apprentices: 2, journeymen: 3, masters: 4);
      final json = pool.toJson();
      final pool2 = WorkerPool.fromJson(json);
      expect(pool2, pool);
      expect(pool2.hashCode, pool.hashCode);
    });

    test('fromJson tolerates string numbers', () {
      final pool = WorkerPool.fromJson({
        'peasants': '1',
        'apprentices': '2',
        'journeymen': 'x',
        'masters': null,
      });
      expect(pool.peasants, 1);
      expect(pool.apprentices, 2);
      expect(pool.journeymen, 0);
      expect(pool.masters, 0);
    });

    test('labourSupplyPerTurn sums GDD tier labour (incl. masters)', () {
      const pool = WorkerPool(
        peasants: 1,
        apprentices: 1,
        journeymen: 1,
        masters: 1,
      );
      expect(
        pool.labourSupplyPerTurn,
        WorkerPool.labourPerPeasantTurn +
            WorkerPool.labourPerApprenticeTurn +
            WorkerPool.labourPerJourneymanTurn +
            WorkerPool.labourPerMasterTurn,
      );
      const mastersOnly = WorkerPool(masters: 2);
      expect(
        mastersOnly.labourSupplyPerTurn,
        2 * WorkerPool.labourPerMasterTurn,
      );
    });
  });
}

