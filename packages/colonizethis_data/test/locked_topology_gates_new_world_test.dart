import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'support/locked_topology_path_landmass.dart';

void main() {
  group('locked_topology_gates new-world feasibility', () {
    test(
      'newWorldPartitionMatchesLockedProfile true for four path landmasses',
      () {
        final topo = lockedTopologyMerge([
          lockedTopologyPathLandmass(
            prefix: 'N1',
            size: 9,
            seaBoundProvinceCount: 1,
          ),
          lockedTopologyPathLandmass(
            prefix: 'N2',
            size: 9,
            seaBoundProvinceCount: 1,
          ),
          lockedTopologyPathLandmass(
            prefix: 'N3',
            size: 6,
            seaBoundProvinceCount: 1,
          ),
          lockedTopologyPathLandmass(
            prefix: 'N4',
            size: 6,
            seaBoundProvinceCount: 1,
          ),
        ]);
        expect(newWorldPartitionMatchesLockedProfile(topo), true);
      },
    );

    test(
      'lockedNewWorldRoleFeasibilityHolds passes for 9/9/6/6 with enough sea',
      () {
        final parts = [
          lockedTopologyPathLandmass(
            prefix: 'W',
            size: 9,
            seaBoundProvinceCount: 3,
          ),
          lockedTopologyPathLandmass(
            prefix: 'X',
            size: 9,
            seaBoundProvinceCount: 3,
          ),
          lockedTopologyPathLandmass(
            prefix: 'Y',
            size: 6,
            seaBoundProvinceCount: 2,
          ),
          lockedTopologyPathLandmass(
            prefix: 'Z',
            size: 6,
            seaBoundProvinceCount: 2,
          ),
        ];
        final topo = lockedTopologyMerge(parts);
        final nbr = provincePpNeighbours(topo);
        expect(
          lockedNewWorldRoleFeasibilityHolds(topology: topo, neighbours: nbr),
          true,
        );
      },
    );

    test(
      'lockedNewWorldRoleFeasibilityHolds fails on wrong component sizes',
      () {
        final topo = lockedTopologyMerge([
          lockedTopologyPathLandmass(
            prefix: 'W',
            size: 8,
            seaBoundProvinceCount: 2,
          ),
          lockedTopologyPathLandmass(
            prefix: 'X',
            size: 9,
            seaBoundProvinceCount: 3,
          ),
          lockedTopologyPathLandmass(
            prefix: 'Y',
            size: 6,
            seaBoundProvinceCount: 2,
          ),
          lockedTopologyPathLandmass(
            prefix: 'Z',
            size: 7,
            seaBoundProvinceCount: 2,
          ),
        ]);
        final nbr = provincePpNeighbours(topo);
        expect(
          lockedNewWorldRoleFeasibilityHolds(topology: topo, neighbours: nbr),
          false,
        );
      },
    );

    test(
      'lockedNewWorldRoleFeasibilityHolds fails when sea-bound tribes need unmet',
      () {
        final topo = lockedTopologyMerge([
          lockedTopologyPathLandmass(
            prefix: 'W',
            size: 9,
            seaBoundProvinceCount: 2,
          ),
          lockedTopologyPathLandmass(
            prefix: 'X',
            size: 9,
            seaBoundProvinceCount: 3,
          ),
          lockedTopologyPathLandmass(
            prefix: 'Y',
            size: 6,
            seaBoundProvinceCount: 2,
          ),
          lockedTopologyPathLandmass(
            prefix: 'Z',
            size: 6,
            seaBoundProvinceCount: 2,
          ),
        ]);
        final nbr = provincePpNeighbours(topo);
        expect(
          lockedNewWorldRoleFeasibilityHolds(topology: topo, neighbours: nbr),
          false,
        );
      },
    );
  });
}
