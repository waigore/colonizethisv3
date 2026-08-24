import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'support/locked_topology_path_landmass.dart';

void main() {
  group('locked_topology_gates old-world', () {
    test(
      'oldWorldPartitionMatchesLockedProfile true for four path landmasses',
      () {
        final topo = lockedTopologyMerge([
          lockedTopologyPathLandmass(
            prefix: 'O1',
            size: 17,
            seaBoundProvinceCount: 1,
          ),
          lockedTopologyPathLandmass(
            prefix: 'O2',
            size: 17,
            seaBoundProvinceCount: 1,
          ),
          lockedTopologyPathLandmass(
            prefix: 'O3',
            size: 13,
            seaBoundProvinceCount: 1,
          ),
          lockedTopologyPathLandmass(
            prefix: 'O4',
            size: 13,
            seaBoundProvinceCount: 1,
          ),
        ]);
        expect(oldWorldPartitionMatchesLockedProfile(topo), true);
      },
    );

    test(
      'lockedOldWorldRoleFeasibilityHolds passes for four feasible landmasses',
      () {
        final parts = [
          lockedTopologyPathLandmass(
            prefix: 'A',
            size: 17,
            seaBoundProvinceCount: 2,
          ),
          lockedTopologyPathLandmass(
            prefix: 'B',
            size: 17,
            seaBoundProvinceCount: 2,
          ),
          lockedTopologyPathLandmass(
            prefix: 'C',
            size: 13,
            seaBoundProvinceCount: 1,
          ),
          lockedTopologyPathLandmass(
            prefix: 'D',
            size: 13,
            seaBoundProvinceCount: 1,
          ),
        ];
        final topo = lockedTopologyMerge(parts);
        final nbr = provincePpNeighbours(topo);
        expect(
          lockedOldWorldRoleFeasibilityHolds(topology: topo, neighbours: nbr),
          true,
        );
      },
    );

    test(
      'lockedOldWorldRoleFeasibilityHolds fails when not four landmasses',
      () {
        final topo = lockedTopologyMerge([
          lockedTopologyPathLandmass(
            prefix: 'A',
            size: 13,
            seaBoundProvinceCount: 1,
          ),
          lockedTopologyPathLandmass(
            prefix: 'B',
            size: 13,
            seaBoundProvinceCount: 1,
          ),
        ]);
        final nbr = provincePpNeighbours(topo);
        expect(
          lockedOldWorldRoleFeasibilityHolds(topology: topo, neighbours: nbr),
          false,
        );
      },
    );

    test(
      'lockedOldWorldRoleFeasibilityHolds fails when landmass too small',
      () {
        final topo = lockedTopologyMerge([
          lockedTopologyPathLandmass(
            prefix: 'A',
            size: 17,
            seaBoundProvinceCount: 2,
          ),
          lockedTopologyPathLandmass(
            prefix: 'B',
            size: 17,
            seaBoundProvinceCount: 2,
          ),
          lockedTopologyPathLandmass(
            prefix: 'C',
            size: 13,
            seaBoundProvinceCount: 1,
          ),
          lockedTopologyPathLandmass(
            prefix: 'D',
            size: 12,
            seaBoundProvinceCount: 1,
          ),
        ]);
        final nbr = provincePpNeighbours(topo);
        expect(
          lockedOldWorldRoleFeasibilityHolds(topology: topo, neighbours: nbr),
          false,
        );
      },
    );

    test(
      'lockedOldWorldRoleFeasibilityHolds fails when sea-bound count too low',
      () {
        final topo = lockedTopologyMerge([
          lockedTopologyPathLandmass(
            prefix: 'A',
            size: 17,
            seaBoundProvinceCount: 1,
          ),
          lockedTopologyPathLandmass(
            prefix: 'B',
            size: 17,
            seaBoundProvinceCount: 2,
          ),
          lockedTopologyPathLandmass(
            prefix: 'C',
            size: 13,
            seaBoundProvinceCount: 1,
          ),
          lockedTopologyPathLandmass(
            prefix: 'D',
            size: 13,
            seaBoundProvinceCount: 1,
          ),
        ]);
        final nbr = provincePpNeighbours(topo);
        expect(
          lockedOldWorldRoleFeasibilityHolds(topology: topo, neighbours: nbr),
          false,
        );
      },
    );
  });
}
