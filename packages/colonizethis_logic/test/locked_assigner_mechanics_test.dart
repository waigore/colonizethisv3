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
  group('locked assigner mechanics (#1830 AC-14 / AC-15)', () {
    test('AC-14 observes at least one backtrack on a crafted topology', () {
      final obs = LockedAssignerObservation();
      assignTerritoriesLockedOnLandmass(
        landmassProvinceIds: {'a', 'b', 'c', 'd'},
        neighbours: _ac14Neighbours,
        growthOrder: const ['A', 'B'],
        targetPerFaction: const {'A': 2, 'B': 2},
        seeds: const {'a': 'A', 'b': 'B'},
        backtrackLimitPerLandmass: 500,
        observation: obs,
      );
      expect(obs.backtracks, greaterThanOrEqualTo(1));
    });

    test('AC-15 deterministic completion without thrash on same topology', () {
      Map<String, String> runOnce(LockedAssignerObservation? obs) {
        return assignTerritoriesLockedOnLandmass(
          landmassProvinceIds: {'a', 'b', 'c', 'd'},
          neighbours: _ac14Neighbours,
          growthOrder: const ['A', 'B'],
          targetPerFaction: const {'A': 2, 'B': 2},
          seeds: const {'a': 'A', 'b': 'B'},
          backtrackLimitPerLandmass: 500,
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
