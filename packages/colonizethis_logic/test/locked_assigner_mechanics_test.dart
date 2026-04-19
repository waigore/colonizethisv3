import 'package:colonizethis_logic/src/setup/locked_province_assigner.dart';
import 'package:colonizethis_test/test.dart';

/// Five-province topology: only `m` from mandatory `a`; at depth 2 from `m`,
/// `d` ranks before `g` (higher P–P degree) but `d` first makes `B` infeasible,
/// so the assigner backtracks once then takes `g` (#1861 / SPEC).
const _ac14Neighbours = <String, Set<String>>{
  'a': {'m'},
  'm': {'a', 'd', 'g'},
  'd': {'m', 'w'},
  'g': {'m'},
  'w': {'d'},
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
        landmassProvinceIds: {'a', 'm', 'd', 'g', 'w'},
        neighbours: _ac14Neighbours,
        growthOrder: const ['A', 'B'],
        targetPerFaction: const {'A': 3, 'B': 2},
        mandatorySeedProvinceByFaction: const {'A': 'a'},
        backtrackLimitPerFaction: 500,
        observation: obs,
      );
      expect(m, const {'a': 'A', 'm': 'A', 'g': 'A', 'w': 'B', 'd': 'B'});
      expect(
        obs.backtracks,
        1,
        reason:
            'AC-14: exactly one undo/backtrack for this fixture (SPEC locked-province-assigner)',
      );
    });

    test('AC-15 deterministic completion without thrash on same topology', () {
      Map<String, String> runOnce(LockedAssignerObservation? obs) {
        return assignTerritoriesLockedOnLandmass(
          landmassProvinceIds: {'a', 'm', 'd', 'g', 'w'},
          neighbours: _ac14Neighbours,
          growthOrder: const ['A', 'B'],
          targetPerFaction: const {'A': 3, 'B': 2},
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
      expect(o1.capitalRestarts, o2.capitalRestarts);
      expect(o1.backtracks, 1, reason: 'same golden search cost as AC-14');
      expect(o1.capitalRestarts, 0);
      expect(o1.backtracks, lessThan(50), reason: 'anti-thrash guard');
    });
  });
}
