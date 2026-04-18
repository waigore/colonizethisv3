import 'package:colonizethis_logic/src/setup/locked_province_assigner.dart';
import 'package:colonizethis_test/test.dart';

/// Hand-tuned 4-node topology (brute-found) where the first ranked expansion
/// dead-ends and the assigner undoes at least one placement (#1830 AC-14).
const _ac14Neighbours = <String, Set<String>>{
  'a': {'c', 'd'},
  'b': {'c'},
  'c': {'a', 'b'},
  'd': {'a'},
};

void main() {
  group('islandResidualsFeasibleGreedy', () {
    test('returns true for empty residuals list', () {
      expect(
        islandResidualsFeasibleGreedy(
          unassignedOnLand: {'x'},
          neighbours: const {},
          land: const {'x'},
          residualsSortedDesc: const [],
        ),
        true,
      );
    });

    test('empty unassigned and all-zero residuals is feasible', () {
      expect(
        islandResidualsFeasibleGreedy(
          unassignedOnLand: {},
          neighbours: const {},
          land: const {'a'},
          residualsSortedDesc: const [0, 0],
        ),
        true,
      );
    });

    test('empty unassigned with positive residual is infeasible', () {
      expect(
        islandResidualsFeasibleGreedy(
          unassignedOnLand: {},
          neighbours: const {},
          land: const {'a', 'b'},
          residualsSortedDesc: const [1],
        ),
        false,
      );
    });
  });

  group('locked assigner mechanics (#1830 AC-14 / AC-15)', () {
    test('throws when mandatory seed province is not on the landmass', () {
      expect(
        () => assignTerritoriesLockedOnLandmass(
          landmassProvinceIds: {'a', 'b'},
          neighbours: const {
            'a': {'b'},
            'b': {'a'},
          },
          growthOrder: const ['A'],
          targetPerFaction: const {'A': 2},
          mandatorySeedProvinceByFaction: const {'A': 'x'},
          backtrackLimitPerFaction: 10,
          observation: null,
        ),
        throwsStateError,
      );
    });

    test('AC-14 completes AC-14 topology with phased seeding (A mandatory a)', () {
      final obs = LockedAssignerObservation();
      final m = assignTerritoriesLockedOnLandmass(
        landmassProvinceIds: {'a', 'b', 'c', 'd'},
        neighbours: _ac14Neighbours,
        growthOrder: const ['A', 'B'],
        targetPerFaction: const {'A': 2, 'B': 2},
        mandatorySeedProvinceByFaction: const {'A': 'a'},
        backtrackLimitPerFaction: 500,
        observation: obs,
      );
      expect(m, const {'a': 'A', 'd': 'A', 'b': 'B', 'c': 'B'});
    });

    test('AC-15 deterministic completion without thrash on same topology', () {
      Map<String, String> runOnce(LockedAssignerObservation? obs) {
        return assignTerritoriesLockedOnLandmass(
          landmassProvinceIds: {'a', 'b', 'c', 'd'},
          neighbours: _ac14Neighbours,
          growthOrder: const ['A', 'B'],
          targetPerFaction: const {'A': 2, 'B': 2},
          mandatorySeedProvinceByFaction: const {'A': 'a'},
          backtrackLimitPerFaction: 500,
          observation: obs,
        );
      }

      final o1 = LockedAssignerObservation();
      final o2 = LockedAssignerObservation();
      final m1 = runOnce(o1);
      final m2 = runOnce(o2);
      expect(m1, m2);
      expect(o1.backtracks, o2.backtracks);
      expect(o1.backtracks, lessThan(50), reason: 'anti-thrash guard');
    });
  });
}
